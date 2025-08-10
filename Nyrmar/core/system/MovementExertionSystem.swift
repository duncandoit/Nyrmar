//
//  MovementSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreGraphics
import Foundation

/// MovementExertionSystem: intent/policy → desired kinematics. Writes to MovementState, never to transformComp.
final class MovementExertionSystem: System
{
    let requiredComponent: ComponentTypeID = MoveExertionComponent.typeID

    func update(deltaTime dt: TimeInterval, component: any Component, world: GameWorld)
    {
        let moverComp = component as! MoveExertionComponent
        guard let moveStateComp = moverComp.sibling(MoveStateComponent.self) else
        {
            return
        }
        guard let transformComp = moverComp.sibling(TransformComponent.self) else
        {
            return
        }
        guard let baseStatsComp = moveStateComp.sibling(BaseStatsComponent.self) else
        {
            return
        }

        let deltaTime = CGFloat(max(dt, 0))
        var targetVelocity = CGVector.zero
        var wantVelocity = false

        // Teleport/delta handled by MovementStateSystem
        // Do not generate velocity for them
        // Seek -> desired velocity toward target
        if let target = moverComp.seekTarget
        {
            let to = CGVector(
                dx: target.x - transformComp.position.x,
                dy: target.y - transformComp.position.y
            )
            let dist = to.length
            moveStateComp.isSeeking = true
            moveStateComp.currentSeekTarget = target
            moveStateComp.remainingDistance = dist
            let speed = moverComp.seekSpeed ?? baseStatsComp.moveSpeed
            targetVelocity = dist > 0 ? to.normalized() * speed : .zero
            wantVelocity = true
        }

        // Direct desired continuous velocity
        if let target = moverComp.velocityDesired
        {
            targetVelocity = target
            wantVelocity = true
        }

        // Accelerate current velocity toward destination
        if wantVelocity
        {
            let currentVelocity = moveStateComp.velocity
            var aMax = moverComp.maxAcceleration ?? .greatestFiniteMagnitude
            if deltaTime == 0
            {
                // snap if no time
                aMax = .greatestFiniteMagnitude
            }
            let deltaVelocity = targetVelocity - currentVelocity
            let step = deltaVelocity.clampedMagnitude(aMax * deltaTime)
            var next = currentVelocity + step
            if let vmax = baseStatsComp.moveSpeedMax
            {
                next = next.clampedMagnitude(vmax)
            }
            
            moveStateComp.acceleration = deltaTime > 0 ? (next - currentVelocity) * (1.0 / deltaTime) : .zero
            moveStateComp.velocity = next
            moveStateComp.isSettled = next.length < 0.001 && moverComp.seekTarget == nil && moverComp.velocityDesired == nil
        }
        else
        {
            // No velocity intent -> decay toward rest under acceleration cap
            let currentVelocity = moveStateComp.velocity
            if currentVelocity.length > 0, let aMax = moverComp.maxAcceleration, deltaTime > 0
            {
                let dec = (currentVelocity * -1).clampedMagnitude(aMax * deltaTime)
                let next = currentVelocity + dec
                moveStateComp.acceleration = (next - currentVelocity) * (1.0 / deltaTime)
                moveStateComp.velocity = next
                moveStateComp.isSettled = next.length < 0.001
            }
            else
            {
                moveStateComp.acceleration = .zero
                
                // keep current velocity (e.g., external systems may manage it)
                moveStateComp.isSettled = moveStateComp.velocity.length < 0.001
            }
        }
    }
}
