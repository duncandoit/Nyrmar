//
//  ForceAccumulatorSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import Foundation


/// System accumulating forces into velocity
class ForceAccumulatorSystem: System
{
    let requiredComponent: ComponentTypeID = ForceAccumulatorComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let forceComp = component as! ForceAccumulatorComponent
        guard let physicsComp = forceComp.sibling(PhysicsComponent.self) else
        {
            return
        }

        // Net acceleration = externalForce + gravity
        let totalAX = forceComp.impulse.dx / physicsComp.mass
        let totalAY = (forceComp.impulse.dy - forceComp.gravityStrength) / physicsComp.mass

        physicsComp.velocity.dx += totalAX * CGFloat(deltaTime)
        physicsComp.velocity.dy += totalAY * CGFloat(deltaTime)
        
        forceComp.impulse = .zero
    }
}
