//
//  InputSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import CoreFoundation
import Foundation

final class InputSystem: System
{
    let requiredComponent: ComponentTypeID = Single_InputComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component)
    {
        let inputComp = component as! Single_InputComponent
        let actionMaps = EntityAdmin.shared.playerBindingsComponent().mappings
        let clockComp = EntityAdmin.shared.simClockComponent()
        let quantizedTime = clockComp.quantizedNow
        let controllerID = inputComp.controllerID

        // DIGITAL
        if !inputComp.digitalEdges.isEmpty
        {
            for actionMap in actionMaps
            {
                guard case let .digital(keys) = actionMap.raw else
                {
                    continue
                }
                
                for e in inputComp.digitalEdges where keys.contains(e.input)
                {
                    inputComp.commandQueue.append(PlayerCommand(
                        controllerID: controllerID,
                        intent: actionMap.intent,
                        value: .isPressed(e.isDown),
                        timestamp: quantizedTime
                    ))
                }
            }
            inputComp.digitalEdges.removeAll(keepingCapacity: true)
        }

        // ANALOG 1D
        for actionMap in actionMaps
        {
            guard case let .analog1D(axis) = actionMap.raw else
            {
                continue
            }
            guard let rawInputValue = inputComp.analog1D[axis] else
            {
                continue
            }
            
            let actionValue = actionMap.transform(rawInputValue)
            let lastActionValue = inputComp.lastReported1D[axis] ?? 0
            let inDeadZone = abs(actionValue) < actionMap.deadZone
            let wasInDeadZone = abs(lastActionValue) < actionMap.deadZone
            if inDeadZone != wasInDeadZone || abs(actionValue - lastActionValue) >= 0.02
            {
                inputComp.commandQueue.append(PlayerCommand(
                    controllerID: controllerID,
                    intent: actionMap.intent,
                    value: .axis1D(inDeadZone ? 0 : actionValue),
                    timestamp: quantizedTime
                ))
                inputComp.lastReported1D[axis] = actionValue
            }
        }

        // ANALOG 2D
        for actionMap in actionMaps
        {
            guard case let .analog2D(xA, yA) = actionMap.raw else
            {
                continue
            }
            
            let actionValueX = actionMap.transform(inputComp.analog1D[xA] ?? 0)
            let actionValueY = actionMap.transform(inputComp.analog1D[yA] ?? 0)
            let actionValue = CGPoint(x: CGFloat(actionValueX), y: CGFloat(actionValueY))
            let key = "\(xA)+\(yA)"
            let lastActionValue = inputComp.lastReported2D[key] ?? .zero
            let magnitute = hypot(actionValue.x, actionValue.y)
            let lastMagnitute = hypot(lastActionValue.x, lastActionValue.y)
            let inDeadZone = magnitute < CGFloat(actionMap.deadZone)
            let wasInDeadZone = lastMagnitute < CGFloat(actionMap.deadZone)
            let movedEnough = hypot(actionValue.x - lastActionValue.x, actionValue.y - lastActionValue.y) >= 0.02
            if inDeadZone != wasInDeadZone || movedEnough
            {
                inputComp.commandQueue.append(PlayerCommand(
                    controllerID: controllerID,
                    intent: actionMap.intent,
                    value: .axis2D(inDeadZone ? .zero : actionValue),
                    timestamp: quantizedTime
                ))
                inputComp.lastReported2D[key] = actionValue
            }
        }

        // POINTER
        if !inputComp.pointerEvents.isEmpty
        {
            for actionMap in actionMaps
            {
                guard case .pointer = actionMap.raw else
                {
                    continue
                }
                
                for pointerData in inputComp.pointerEvents
                {
                    let screenSpacePoint = pointerData.screenLocation
                    
                    inputComp.commandQueue.append(PlayerCommand(
                        controllerID: controllerID,
                        intent: actionMap.intent,
                        value: .screenPosition(screenSpacePoint),
                        timestamp: quantizedTime
                    ))
                }
            }
            inputComp.pointerEvents.removeAll(keepingCapacity: true)
        }
    }
}
