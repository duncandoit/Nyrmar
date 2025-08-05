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
        
        guard let movementComp = inputComp.sibling(MovementComponent.self) else
        {
            print("[" + #fileID + "]: " + #function + " -> Controllable Entity does not have a MovementComponent.")
            return
        }
        
        movementComp.destination = inputComp.touchLocation
        
        if inputComp.pressedInputs.contains(.touchUp)
        {
            guard let forceComp = movementComp.sibling(ForceAccumulatorComponent.self) else { return }
            
            guard let transformComp = forceComp.sibling(TransformComponent.self) else { return }
            
            // Get the current position and the target position:
            let currentPos = transformComp.position
            guard let targetPos = movementComp.destination else { return }

            // Compute the raw vector pointing from target → entity:
            let rawX = currentPos.x - targetPos.x
            let rawY = currentPos.y - targetPos.y
            let distance = hypot(rawX, rawY)

            // Normalize (guard against zero-distance):
            guard distance > 0 else { return }
            let dirX = rawX / distance
            let dirY = rawY / distance

            // Choose your impulse strength (units: force)
            let impulseStrength: CGFloat = 800.0

            // Build the impulse vector “away” from the target:
            let impulse = CGVector(dx: dirX * impulseStrength, dy: dirY * impulseStrength)

            // Apply it to the ForceAccumulatorComponent
            forceComp.impulse.dx += impulse.dx
            forceComp.impulse.dy += impulse.dy
        }
    }
}
