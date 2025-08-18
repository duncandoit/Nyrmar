//
//  InputSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import CoreFoundation
import Foundation

import CoreGraphics
import QuartzCore

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

        processDigitalEdges(input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)
        processPointerEvents(input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)
        processAxis1D(input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)
        processAxis2D(input: inputComp, bindings: bindingsComp, tickIndex: clockComp.tickIndex, out: &commands)

        inputComp.commandQueue = commands

        // one-frame buffers are cleared after mapping
        inputComp.digitalEdges.removeAll(keepingCapacity: true)
        inputComp.pointerEvents.removeAll(keepingCapacity: true)
    }

    // MARK: - Digital

    @inline(__always)
    private func processDigitalEdges(
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        guard !bindings.digital.isEmpty, !input.digitalEdges.isEmpty else
        {
            return
        }

        for edge in input.digitalEdges
        {
            for mapping in bindings.digital where mapping.inputs.contains(edge.input)
            {
                switch mapping.policy
                {
                case .onDown where edge.isDown:
                    
                    stamp(intent: mapping.intent, value: .isPressed(true), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
                    
                case .onUp where !edge.isDown:
                    
                    stamp(intent: mapping.intent, value: .isPressed(false), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
                    
                case .onHold:
                    
                    // Stateless mapping layer: emit press on down; duration enforcement belongs in a separate system.
                    if edge.isDown
                    {
                        stamp(intent: mapping.intent, value: .isPressed(true), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
                    }
                    
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
    private func processAxis2D(
        input: Single_InputComponent,
        bindings: Single_PlayerBindingsComponent,
        tickIndex: UInt64,
        out: inout [PlayerCommand]
    ){
        guard !bindings.axis2D.isEmpty else
        {
            return
        }

        for mapping in bindings.axis2D
        {
            var xSample = input.analog1D[mapping.x] ?? 0
            var ySample = input.analog1D[mapping.y] ?? 0

            if mapping.invertX
            {
                xSample = -xSample
            }
            if mapping.invertY
            {
                ySample = -ySample
            }

            let xCurved = applyCurve(applyDeadZone(xSample, deadZone: mapping.deadZone), curve: mapping.curve)
            let yCurved = applyCurve(applyDeadZone(ySample, deadZone: mapping.deadZone), curve: mapping.curve)

            // Circular dead zone based on magnitude
            let magnitude = hypot(Double(xCurved), Double(yCurved))
            let dead = Double(mapping.deadZone)

            var outputPoint = CGPoint.zero
            if magnitude > dead
            {
                let scale = (magnitude - dead) / (1 - dead)
                outputPoint = CGPoint(x: Double(xCurved) * scale, y: Double(yCurved) * scale)
            }

            let key = pairKey(mapping.x, mapping.y)
            let previous = input.lastReported2D[key]
            if shouldReport2D(previous: previous, newValue: outputPoint, epsilon: mapping.reportEpsilon)
            {
                input.lastReported2D[key] = outputPoint
                stamp(intent: mapping.intent, value: .axis2D(outputPoint), controllerID: input.controllerID, tickIndex: tickIndex, out: &out)
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
            return true
        }
        return hypot(newValue.x - prev.x, newValue.y - prev.y) >= epsilon
    }
}
