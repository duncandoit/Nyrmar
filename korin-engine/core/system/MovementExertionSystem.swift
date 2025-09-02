//
//  MovementSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreGraphics
import Foundation

/// Reads MoveExertionComponent intents and writes acceleration *desired acceleration*
/// into MoveStateComponent.acceleration via acceleration PD controller (seek).
struct MovementExertionSystem: System
{
    func requiredComponent() -> ComponentTypeID
    {
        return MoveExertionComponent.typeID
    }

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let exertionComp = component as! MoveExertionComponent

        guard let stateComp = exertionComp.sibling(MoveStateComponent.self) else
        {
            return
        }
        guard let transformComp = exertionComp.sibling(TransformComponent.self) else
        {
            return
        }
        guard let target = exertionComp.target else
        {
            resetMovementState(stateComp)
            return
        }
        
        stateComp.isSettled = false
        
        if exertionComp.killVelocity
        {
            stateComp.velocity = .zero
//            stateComp.isSettled = true
            exertionComp.killVelocity = false
        }

        switch exertionComp.intent
        {
        case .moveInDirection:
            
            // Interpret target as acceleration world-space vector (dx,dy)
            let dir = CGVector(dx: target.x, dy: target.y)
            let mag = max(0, min(1, dir.length))
            if mag < 0.001
            {
                stateComp.acceleration = .zero
                stateComp.isSeeking = false
                stateComp.currentSeekTarget = nil
                return
            }
            let desiredSpeed = exertionComp.desiredSpeed ?? 0.0 //?? stats.moveSpeed
            let vDesired = dir.normalized() * desiredSpeed * mag
            let vCur = stateComp.velocity

            // “Velocity PD”: accelerate toward desired velocity, damp by current velocity.
            var acceleration = (vDesired - vCur) * exertionComp.acceleration - vCur * exertionComp.dampening
            acceleration = acceleration.clampedMagnitude(stateComp.maxLinearAcceleration)

            // Optional ground/air gating
            if stateComp.isGrounded
            {
                // remove component pushing into ground normal
                let n = stateComp.groundNormal.normalized()
                let dot = acceleration.dx*n.dx + acceleration.dy*n.dy
                acceleration = CGVector(dx: acceleration.dx - dot*n.dx, dy: acceleration.dy - dot*n.dy)
            }
            else
            {
                acceleration = acceleration * max(0, min(1, stateComp.airControl))
            }

            stateComp.acceleration = acceleration
            stateComp.isSeeking = false
            stateComp.currentSeekTarget = nil

        case .seekTarget:
            
            // PD on position error
            let to = CGVector(
                dx: target.x - transformComp.position.x,
                dy: target.y - transformComp.position.y
            )
            let distance = to.length
            stateComp.remainingDistance = distance	
            stateComp.isSeeking = true
            stateComp.currentSeekTarget = target

            // PD: acceleration = P*posError - D*vel
            var acceleration = to * exertionComp.acceleration - stateComp.velocity * exertionComp.dampening
            acceleration = acceleration.clampedMagnitude(stateComp.maxLinearAcceleration)

            if stateComp.isGrounded
            {
                let n = stateComp.groundNormal.normalized()
                let dot = acceleration.dx*n.dx + acceleration.dy*n.dy
                acceleration = CGVector(dx: acceleration.dx - dot*n.dx, dy: acceleration.dy - dot*n.dy)
            }
            else
            {
                acceleration = acceleration * max(0, min(1, stateComp.airControl))
            }

            stateComp.acceleration = acceleration

        case .teleportTo:
            
            // One-shots are applied in MovementStateSystem
            // No authored acceleration this tick.
            stateComp.acceleration = .zero

        case .none:
            
            resetMovementState(stateComp)
        }
    }
    
    private func resetMovementState(_ stateComp: MoveStateComponent)
    {
        stateComp.acceleration = .zero
        stateComp.isSeeking = false
        stateComp.currentSeekTarget = nil
        stateComp.remainingDistance = 0
        stateComp.isSettled = stateComp.velocity.length < stateComp.settledEpsilon
    }
}
