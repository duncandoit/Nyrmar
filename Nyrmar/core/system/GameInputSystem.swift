//
//  GameInputSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import CoreFoundation
import Foundation


/// System that polls input events (keyboard + touch) and updates InputComponents
//class GameInputSystem: System
//{
//    let requiredComponent: ComponentTypeID = ControlledByComponent.typeID
//
//    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
//    {
//        let controlledByComp = component as! ControlledByComponent
//        guard controlledByComp.controllerID == EntityAdmin.shared.getLocalPlayerID() else
//        {
//            print("[" + #fileID + "]: " + #function + " -> Not controlled by local player")
//            return
//        }
//        
//        guard let inputComp = controlledByComp.sibling(GameInputComponent.self) else
//        {
//            //print("[" + #fileID + "]: " + #function + " -> No input given to controlled Entity.")
//            return
//        }
//        
//        guard let transformComp = inputComp.sibling(TransformComponent.self) else
//        {
//            print("[" + #fileID + "]: " + #function + " -> Controllable Entity does not have a TransformComponent.")
//            return
//        }
//        
//        guard let movementComp - inputComp.sibling(ParametricMovementComponent.self) else
//        {
//            print("[" + #fileID + "]: " + #function + " -> Controllable Entity does not have a ParametricMovementComponent.")
//            return
//        }
//
//        guard let targetLocation = inputComp.touchLocation else
//        {
//            print("[" + #fileID + "]: " + #function + " -> GameInputComponent had a nil touch event")
//            return
//        }
//        
//        transformComp.position = targetLocation
//    }
//}

class GameInputSystem: System
{
    let requiredComponent: ComponentTypeID = ControlledByComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let controlledByComp = component as! ControlledByComponent
        guard controlledByComp.controllerID == EntityAdmin.shared.getLocalPlayerID() else
        {
            print("[" + #fileID + "]: " + #function + " -> Not controlled by local player")
            return
        }
        
        guard let inputComp = controlledByComp.sibling(GameInputComponent.self) else
        {
            //print("[" + #fileID + "]: " + #function + " -> No input given to controlled Entity.")
            return
        }
        
        guard let transformComp = inputComp.sibling(TransformComponent.self) else
        {
            print("[" + #fileID + "]: " + #function + " -> Controllable Entity does not have a TransformComponent.")
            return
        }
        
        guard let movementComp = inputComp.sibling(ParametricMovementComponent.self) else
        {
            print("[" + #fileID + "]: " + #function + " -> Controllable Entity does not have a ParametricMovementComponent.")
            return
        }

        guard let targetLocation = inputComp.touchLocation else
        {
            print("[" + #fileID + "]: " + #function + " -> GameInputComponent had a nil touch event")
            return
        }

        // Direction calculation
        let currentPos = transformComp.position
        let dx = targetLocation.x - currentPos.x
        let dy = targetLocation.y - currentPos.y
        let distance = hypot(dx, dy)
        guard distance > 0.1 else { return }
        
        let direction = CGVector(dx: dx / distance, dy: dy / distance)

        // Use moveSpeed from component
        let movementVector = CGVector(
            dx: direction.dx * movementComp.moveSpeed * CGFloat(deltaTime),
            dy: direction.dy * movementComp.moveSpeed * CGFloat(deltaTime)
        )

        // Configure movement component
        movementComp.amplitude = movementVector
        movementComp.frequency = 1.0
        movementComp.phase = 0.0
        movementComp.elapsedTime = 0.0
    }
}
