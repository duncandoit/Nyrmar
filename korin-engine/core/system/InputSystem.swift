//
//  InputSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/2/25.
//

import Foundation

/// Maps raw inputs in `Single_InputComponent` to `PlayerCommand`s using data from `Single_PlayerBindingsComponent`.
final class InputSystem: System
{
    let requiredComponent: ComponentTypeID = Single_InputComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let inputComp = component as! Single_InputComponent
        let bindingsComp = admin.playerBindingsComponent()
        let clockComp = admin.clockComponent()
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
        processAxis2DDigital (input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)
        processAxis2DAnalog  (input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)

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

            let previous = input.lastReported1D[mapping.input]
            if shouldReport1D(previous: previous, newValue: curved, epsilon: mapping.reportEpsilon)
            {
                input.lastReported1D[mapping.input] = curved
                stamp(intent: mapping.intent, value: .axis1D(curved), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
            }
        }
    }

    // MARK: - Axis 2D
    
    @inline(__always)
    private func processAxis2DDigital(
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        guard !bindings.digitalAxis2D.isEmpty else
        {
            return
        }

        @inline(__always)
        func isPressed(_ set: Set<GenericInput>) -> Bool
        {
            for k in set
            {
                if input.heldDigitalEdges.contains(k)
                {
                    return true
                }
            }
            return false
        }

        for m in bindings.digitalAxis2D
        {
            var x: Float = 0
            var y: Float = 0
            if isPressed(m.right) { x += 1 }
            if isPressed(m.left)  { x -= 1 }
            if isPressed(m.up)    { y += 1 }
            if isPressed(m.down)  { y -= 1 }

            // invert flags
            if m.invertX { x = -x }
            if m.invertY { y = -y }

            // normalize to unit circle
            let mag = sqrt(x*x + y*y)
            if mag > 1e-6
            {
                let s: Float = (mag > 1) ? (1 / mag) : 1
                x *= s
                y *= s
            }

            let pt = CGPoint(x: Double(x), y: Double(y))
            let key = "D:\(m.id.uuidString)"

            let previous = input.lastReported2D[key]
            if shouldReport2D(previous: previous, newValue: pt, epsilon: m.reportEpsilon)
            {
                input.lastReported2D[key] = pt
                stamp(
                    intent: m.intent,
                    value: .axis2D(pt),
                    controllerID: input.controllerID,
                    tickIndex: tickIndex,
                    out: &out
                )
            }
            
            // Also emit when returning to zero so movement stops deterministically
            else if previous != nil && previous! != .zero && pt == .zero
            {
                input.lastReported2D[key] = pt
                stamp(
                    intent: m.intent,
                    value: .axis2D(pt),
                    controllerID: input.controllerID,
                    tickIndex: tickIndex,
                    out: &out
                )
            }
        }
    }
    
    @inline(__always)
    private func processAxis2DAnalog(
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        guard !bindings.axis2D.isEmpty else
        {
            return
        }

        for m in bindings.axis2D
        {
            let x = input.analog1D[m.x] ?? 0
            let y = input.analog1D[m.y] ?? 0
            let key = "A:\(m.x)|\(m.y)" // namespace to avoid clashing with digital cache
            
            var xs = m.invertX ? -x : x
            var ys = m.invertY ? -y : y
            
            // clamp to unit circle -> diagonals not faster
            let len = sqrt(xs*xs + ys*ys)
            if len > 1
            {
                xs /= len; ys /= len
            }

            let xCurved = applyCurve(applyDeadZone(xs, deadZone: m.deadZone), curve: m.curve)
            let yCurved = applyCurve(applyDeadZone(ys, deadZone: m.deadZone), curve: m.curve)

            // circular DZ on magnitude
            let mag = hypot(Double(xCurved), Double(yCurved))
            let dz  = Double(m.deadZone)

            var pt = CGPoint.zero
            if mag > dz
            {
                let scale = (mag - dz) / (1 - dz)
                pt = CGPoint(x: Double(xCurved) * scale, y: Double(yCurved) * scale)
            }

            let previous = input.lastReported2D[key]
            if shouldReport2D(previous: previous, newValue: pt, epsilon: m.reportEpsilon)
            {
                input.lastReported2D[key] = pt
                stamp(
                    intent: m.intent,
                    value: .axis2D(pt),
                    controllerID: input.controllerID,
                    tickIndex: tickIndex,
                    out: &out
                )
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
        guard let prev = previous else
        {
            return newValue.x >= epsilon || newValue.y >= epsilon
        }
        return abs(newValue.x - prev.x) >= epsilon || abs(newValue.y - prev.y) >= epsilon
    }
}
