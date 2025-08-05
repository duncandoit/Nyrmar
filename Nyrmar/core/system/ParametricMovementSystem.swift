//
//  ParametricMovementSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/1/25.
//

import Foundation

/// System that updates entities with a ParametricMovementComponent
class ParametricMovementSystem: System
{
    let requiredComponent = ParametricMovementComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let movementComp = component as! ParametricMovementComponent
        guard let transformComp = movementComp.sibling(TransformComponent.self) else
        {
            print("[" + #fileID + "]: " + #function + " -> Missing TransformComponent for \(String(describing: movementComp))")
            return
        }

        // Advance elapsed time
        movementComp.elapsedTime += deltaTime
        let t = CGFloat(movementComp.elapsedTime)

        // Compute parametric offset (sinusoidal motion)
        let offsetX = movementComp.amplitude.dx * sin(movementComp.frequency * t + movementComp.phase)
        let offsetY = movementComp.amplitude.dy * cos(movementComp.frequency * t + movementComp.phase)
        let movementOffset = CGVector(dx: offsetX, dy: offsetY)

        // Update transform by combining both offsets
        transformComp.position.x += movementOffset.dx
        transformComp.position.y += movementOffset.dy
    }
}





