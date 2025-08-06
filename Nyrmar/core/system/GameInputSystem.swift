//
//  GameInputSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import CoreFoundation
import Foundation

class GameInputSystem: System
{
    let requiredComponent: ComponentTypeID = ThrallComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let thrallComp = component as! ThrallComponent
        guard let inputComp = thrallComp.sibling(GameInputComponent.self) else
        {
            //print("[" + #fileID + "]: " + #function + " -> No input given to controlled Entity.")
            return
        }
        
        guard let movementComp = inputComp.sibling(MovementComponent.self) else
        {
            print("[" + #fileID + "]: " + #function + " -> Controllable Entity does not have a MovementComponent.")
            return
        }
        
        if EntityAdmin.shared.getLocalPlayerControllerID() == thrallComp.controllerID && thrallComp.controllerID != nil
        {
            // Set target for movement
            movementComp.destination = inputComp.touchLocation
        }
        else
        {
            // Start of debug testing
            if inputComp.pressedInputs.contains(.touchDown)
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
            // End of debug testing
        }
    }
}
