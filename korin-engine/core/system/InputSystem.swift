//
//  InputSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/2/25.
//

import Foundation

/// Maps raw inputs in `Single_InputComponent` to `PlayerCommand`s using data from `Single_PlayerBindingsComponent`.
struct InputSystem: System
{
    func requiredComponent() -> ComponentTypeID
    {
        return Single_InputComponent.typeID
    }

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let inputComp = component as! Single_InputComponent
        let bindingsComp = admin.singleton(Single_PlayerBindingsComponent.self)
        let clockComp = admin.singleton(Single_ClockComponent.self)
        var commands = inputComp.commandQueue
        
        // snapshot edges
        let edges = inputComp.digitalEdges
        
        // First, emit onDown/onUp from edges AND update the held set.
        if !inputComp.digitalEdges.isEmpty
        {
            for e in inputComp.digitalEdges
            {
                if e.isDown
                {
                    inputComp.heldDigitalEdges.insert(e.input)
                }
                else
                {
                    inputComp.heldDigitalEdges.remove(e.input)
                }
            }
        }

        // Map one-shot digital edges (onDown/onUp)
        processDigitalEdges(edges: edges, input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)

        // Axis from held state (now up to date)
        processPointerEvents (input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)
        processAxis1D        (input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)
        processAxis2D        (input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)
        
        // Clear one-frame buffers
        inputComp.digitalEdges.removeAll(keepingCapacity: true)
        inputComp.pointerEvents.removeAll(keepingCapacity: true)
        inputComp.commandQueue = commands
    }

    // MARK: - Digital

    @inline(__always)
    private func processDigitalEdges(
        edges: [DigitalEdge],
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        guard !bindings.digital.isEmpty, !edges.isEmpty else
        {
            return
        }

        for edge in edges
        {
            for mapping in bindings.digital where mapping.inputs.contains(edge.input)
            {
                switch mapping.policy
                {
                case .onDown where edge.isDown:
                    
                    stamp(intent: mapping.intent, value: .isPressed(true), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
                    
                case .onUp where !edge.isDown:
                    
                    stamp(intent: mapping.intent, value: .isPressed(false), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
                    
                case .onHold where edge.isDown:
                    
                    stamp(intent: mapping.intent, value: .isPressed(true), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
                    
                case .repeatEvery:
                    
                    break // Repeats require state; handle in a dedicated repeat system if needed.
                    
                default:
                    break
                }
            }
        }
    }

    // MARK: - Pointer

    @inline(__always)
    private func processPointerEvents(
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        guard !bindings.pointer.isEmpty, !input.pointerEvents.isEmpty else
        {
            return
        }

        for event in input.pointerEvents
        {
            for mapping in bindings.pointer where mapping.phases.contains(event.phase)
            {
                stamp(
                    intent: mapping.intent,
                    value: .screenPosition(event.screenLocation),
                    controllerID: input.controllerID,
                    tickIndex: tickIndex,
                    out: &out
                )
            }
        }
    }

    // MARK: - Axis 1D

    @inline(__always)
    private func processAxis1D(
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        guard !bindings.axis1D.isEmpty else
        {
            return
        }

        for mapping in bindings.axis1D
        {
            guard var raw = input.analog1D[mapping.input] else
            {
                continue
            }

            if mapping.invert
            {
                raw = -raw
            }

            let dzValue = applyDeadZone(raw, deadZone: mapping.deadZone)
            let curved = applyCurve(dzValue, curve: mapping.curve)

            let previous = input.lastReported1DByInput[mapping.input]
            if shouldReport1D(previous: previous, newValue: curved, epsilon: mapping.reportEpsilon)
            {
                input.lastReported1DByInput[mapping.input] = curved
                stamp(intent: mapping.intent, value: .axis1D(curved), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
            }
        }
    }

    // MARK: - Axis 2D
    
    @inline(__always)
    private func processAxis2D(
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        // Accumulate contributions per intent
        var vectorByIntent: [PlayerCommandIntent: CGVector] = [:]
        var epsilonByIntent: [PlayerCommandIntent: CGFloat] = [:]

        // Digital keys are made into synthetic axes
        for digitalBinding in bindings.digitalAxis2D
        {
            var x: Float = 0
            var y: Float = 0
            if inputHeld(digitalBinding.right, onInput: input) { x += 1 }
            if inputHeld(digitalBinding.left,  onInput: input) { x -= 1 }
            if inputHeld(digitalBinding.up,    onInput: input) { y += 1 }
            if inputHeld(digitalBinding.down,  onInput: input) { y -= 1 }
            if digitalBinding.invertX { x = -x }
            if digitalBinding.invertY { y = -y }

            if x != 0 || y != 0
            {
                let vector = CGVector(dx: CGFloat(x), dy: CGFloat(y))
                vectorByIntent[digitalBinding.intent, default: .zero] = vectorByIntent[digitalBinding.intent, default: .zero] + vector
            }
            epsilonByIntent[digitalBinding.intent] = min(epsilonByIntent[digitalBinding.intent] ?? .greatestFiniteMagnitude, digitalBinding.reportEpsilon)
        }

        // Analog
        for analogBinding in bindings.axis2D
        {
            var x = input.analog1D[analogBinding.x] ?? 0
            var y = input.analog1D[analogBinding.y] ?? 0
            if analogBinding.invertX { x = -x }
            if analogBinding.invertY { y = -y }

            let xCurved = applyCurve(applyDeadZone(x, deadZone: analogBinding.deadZone), curve: analogBinding.curve)
            let yCurved = applyCurve(applyDeadZone(y, deadZone: analogBinding.deadZone), curve: analogBinding.curve)

            // circular DZ on magnitude
            let magnitude = hypot(Double(xCurved), Double(yCurved))
            let deadZone  = Double(analogBinding.deadZone)
            var outX: Double = 0
            var outY: Double = 0
            
            if magnitude > deadZone
            {
                let scale = (magnitude - deadZone) / (1 - deadZone)
                outX = Double(xCurved) * scale
                outY = Double(yCurved) * scale
            }
            
            let vector = CGVector(dx: outX, dy: outY)
            if vector.dx != 0 || vector.dy != 0
            {
                vectorByIntent[analogBinding.intent, default: .zero] = vectorByIntent[analogBinding.intent, default: .zero] + vector
            }
            epsilonByIntent[analogBinding.intent] = min(epsilonByIntent[analogBinding.intent] ?? .greatestFiniteMagnitude, analogBinding.reportEpsilon)
        }

        // Finalize per intent: clamp to unit circle, throttle, stamp once
        for (intent, vector) in vectorByIntent
        {
            // clamp to unit circle so diagonals aren’t faster
            let length = vector.length
            let clamped = (length > 1) ? vector * (1/length) : vector
            let pt = CGPoint(x: clamped.dx, y: clamped.dy)

            let prev = input.lastReported2DByIntent[intent]
            
            let epsilon: CGFloat = epsilonByIntent[intent] ?? 0
            if shouldReport2D(previous: prev, newValue: pt, epsilon: epsilon)
            {
                input.lastReported2DByIntent[intent] = pt
                stamp(intent: intent, value: .axis2D(pt), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
            }
        }

        // Also emit zeros when all inputs for an intent are released (to stop motion)
        let allIntents = Set(bindings.digitalAxis2D.map{$0.intent} + bindings.axis2D.map{$0.intent})
        for intent in allIntents where vectorByIntent[intent] == nil
        {
            if input.lastReported2DByIntent[intent] != .some(.zero)
            {
                input.lastReported2DByIntent[intent] = .zero
                stamp(intent: intent, value: .axis2D(.zero), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
            }
        }
    }
  
    // MARK: - Helpers

    @inline(__always)
    private func stamp(
        intent: PlayerCommandIntent,
        value: CommandValue,
        controllerID: ControllerID,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        out.append(PlayerCommand(controllerID: controllerID, intent: intent, value: value, tickIndex: tickIndex))
    }
    
    @inline(__always)
    private func inputHeld(_ inputs: Set<GenericInput>, onInput inputComp: Single_InputComponent) -> Bool
    {
        for input in inputs
        {
            if inputComp.heldDigitalEdges.contains(input)
            {
                return true
            }
        }
        
        return false
    }

    @inline(__always)
    private func applyDeadZone(_ value: Float, deadZone: Float) -> Float
    {
        guard deadZone > 0 else
        {
            return value
        }
        
        let magnitude = abs(value)
        if magnitude <= deadZone
        {
            return 0
        }
        let normalized = (magnitude - deadZone) / (1 - deadZone)
        
        return copysign(normalized, value)
    }

    @inline(__always)
    private func applyCurve(_ value: Float, curve: AxisCurve) -> Float
    {
        switch curve
        {
        case .linear:
            
            return value
            
        case .power(let exponent):
            
            return copysign(pow(abs(value), exponent), value)
            
        case .expo(let base):
            
            let b = max(base, 1.0001) // avoid divide-by-zero when base ~ 1
            return copysign((pow(b, abs(value)) - 1) / (b - 1), value)
        }
    }

    @inline(__always)
    private func inputKey(_ input: GenericInput) -> String
    {
        switch input
        {
        case .custom(let name):
            
            return "custom(\(name))"
            
        default:
            
            return String(describing: input)
        }
    }

    @inline(__always)
    private func pairKey(_ x: GenericInput, _ y: GenericInput) -> String
    {
        return "\(inputKey(x))|\(inputKey(y))"
    }

    @inline(__always)
    private func shouldReport1D(previous: Float?, newValue: Float, epsilon: Float) -> Bool
    {
        guard let prev = previous else
        {
            return true
        }
        return abs(prev - newValue) >= epsilon
    }

    @inline(__always)
    private func shouldReport2D(previous: CGPoint?, newValue: CGPoint, epsilon: CGFloat) -> Bool
    {
        guard previous != nil else
        {
            return abs(newValue.x) >= epsilon || abs(newValue.y) >= epsilon
        }
        return abs(newValue.x) >= epsilon || abs(newValue.y) >= epsilon
    }
}
