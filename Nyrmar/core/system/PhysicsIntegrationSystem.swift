//
//  PhysicsIntegrationSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation
import Foundation

/// System integrating velocity into position
class PhysicsIntegrationSystem: System
{
    let requiredComponent: ComponentTypeID = PhysicsComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let physicsComp = component as! PhysicsComponent
        guard let transformComp = physicsComp.sibling(TransformComponent.self) else
        {
            return
        }
        
        // Apply linear decay (drag): v *= max(0, 1 - decay * dt)
        if physicsComp.decay > 0
        {
            let factor = max(0, 1 - physicsComp.decay * CGFloat(deltaTime))
            physicsComp.velocity.dx *= factor
            physicsComp.velocity.dy *= factor
        }

        transformComp.position.x += physicsComp.velocity.dx * CGFloat(deltaTime)
        transformComp.position.y += physicsComp.velocity.dy * CGFloat(deltaTime)
    }
}
