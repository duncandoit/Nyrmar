//
//  PhysicsSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import Foundation


/// System that updates entities with a PhysicsComponent (velocity-driven)
class PhysicsSystem: System
{
    let requiredComponent: ComponentTypeID = PhysicsComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let physComp = component as! PhysicsComponent
        guard let transformComp = physComp.sibling(TransformComponent.self) else
        {
            return
        }

        transformComp.position.x += physComp.velocity.dx * CGFloat(deltaTime)
        transformComp.position.y += physComp.velocity.dy * CGFloat(deltaTime)
    }
}
