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

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let inputComp = component as! Single_InputComponent
        let actionMaps = EntityAdmin.shared.getPlayerBindingsComponent().mappings
        let clockComp = EntityAdmin.shared.getSimClock()
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
            let lastInputValue = inputComp.lastReported1D[axis] ?? 0
            let inDZ = abs(actionValue) < actionMap.deadZone
            let wasInDZ = abs(lastInputValue) < actionMap.deadZone
            if inDZ != wasInDZ || abs(actionValue - lastInputValue) >= 0.02
            {
                inputComp.commandQueue.append(PlayerCommand(
                    controllerID: controllerID,
                    intent: actionMap.intent,
                    value: .axis1D(inDZ ? 0 : actionValue),
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
            let point = CGPoint(x: CGFloat(actionValueX), y: CGFloat(actionValueY))
            let key = "\(xA)+\(yA)"
            let lastInputValue = inputComp.lastReported2D[key] ?? .zero
            let mag = hypot(point.x, point.y)
            let lastMag = hypot(lastInputValue.x, lastInputValue.y)
            let inDZ = mag < CGFloat(actionMap.deadZone)
            let wasInDZ = lastMag < CGFloat(actionMap.deadZone)
            let movedEnough = hypot(point.x - lastInputValue.x, point.y - lastInputValue.y) >= 0.02
            if inDZ != wasInDZ || movedEnough
            {
                inputComp.commandQueue.append(PlayerCommand(
                    controllerID: controllerID,
                    intent: actionMap.intent,
                    value: .axis2D(inDZ ? .zero : point),
                    timestamp: quantizedTime
                ))
                inputComp.lastReported2D[key] = point
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
                    let worldSpacePoint = pointerData.worldLocation
                    
                    inputComp.commandQueue.append(PlayerCommand(
                        controllerID: controllerID,
                        intent: actionMap.intent,
                        value: .axis2D(worldSpacePoint),
                        timestamp: quantizedTime
                    ))
                }
            }
            inputComp.pointerEvents.removeAll(keepingCapacity: true)
        }
    }
}
