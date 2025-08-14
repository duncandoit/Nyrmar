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

    func update(deltaTime dt: TimeInterval, component: any Component)
    {
        let exertionComp = component as! MoveExertionComponent
        guard let moveStateComp = exertionComp.sibling(MoveStateComponent.self) else
        {
            return
        }
        guard let transformComp = exertionComp.sibling(TransformComponent.self) else
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
        if let target = exertionComp.seekTarget
        {
            let targetVector = CGVector(
                dx: target.x - transformComp.position.x,
                dy: target.y - transformComp.position.y
            )
            let deltaDistance = targetVector.length
            moveStateComp.isSeeking = true
            moveStateComp.currentSeekTarget = target
            moveStateComp.remainingDistance = deltaDistance
            let speed = exertionComp.seekSpeed ?? baseStatsComp.moveSpeed
            targetVelocity = deltaDistance > 0 ? targetVector.normalized() * speed : .zero
            wantVelocity = true
        }

        // Direct desired continuous velocity
        if let velocityDesired = exertionComp.velocityDesired
        {
            targetVelocity = velocityDesired
            wantVelocity = true
        }

        // Accelerate current velocity toward destination
        if wantVelocity
        {
            let currentVelocity = moveStateComp.velocity
            var maxVelocity = exertionComp.maxAcceleration ?? .greatestFiniteMagnitude
            if deltaTime == 0
            {
                // snap if no time
                maxVelocity = .greatestFiniteMagnitude
            }
            let deltaVelocity = targetVelocity - currentVelocity
            let velocityStep = deltaVelocity.clampedMagnitude(maxVelocity * deltaTime)
            var nextVelocity = currentVelocity + velocityStep
            if let maxSpeed = baseStatsComp.moveSpeedMax
            {
                nextVelocity = nextVelocity.clampedMagnitude(maxSpeed)
            }
            
            moveStateComp.acceleration = deltaTime > 0 ? (nextVelocity - currentVelocity) * (1.0 / deltaTime) : .zero
            moveStateComp.velocity = nextVelocity
            moveStateComp.isSettled = nextVelocity.length < 0.001 && exertionComp.seekTarget == nil && exertionComp.velocityDesired == nil
        }
        else
        {
            // No velocity intent -> decay toward rest under acceleration cap
            let currentVelocity = moveStateComp.velocity
            if currentVelocity.length > 0, let maxVelocity = exertionComp.maxAcceleration, deltaTime > 0
            {
                let deceleration = (currentVelocity * -1).clampedMagnitude(maxVelocity * deltaTime)
                let nextVelocity = currentVelocity + deceleration
                moveStateComp.acceleration = (nextVelocity - currentVelocity) * (1.0 / deltaTime)
                moveStateComp.velocity = nextVelocity
                moveStateComp.isSettled = nextVelocity.length < 0.001
            }
            else
            {
                moveStateComp.acceleration = .zero
                
                // keep current velocity (external systems may manage it)
                moveStateComp.isSettled = moveStateComp.velocity.length < 0.001
            }
        }
    }
}
