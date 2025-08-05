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
        
        var totalForce: CGVector = forceComp.impulse
        
        if forceComp.gravityEnabled
        {
            totalForce.dy -= forceComp.gravityStrength
        }
        
        // Net acceleration = externalForce + potential gravity
        totalForce.dx /= physicsComp.mass
        totalForce.dy /=  physicsComp.mass

        physicsComp.velocity.dx += totalForce.dx * CGFloat(deltaTime)
        physicsComp.velocity.dy += totalForce.dy * CGFloat(deltaTime)
        
        forceComp.impulse = .zero
    }
}
