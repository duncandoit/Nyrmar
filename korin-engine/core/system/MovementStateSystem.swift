//
//  MovementStateSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/10/25.
//

import Foundation

/// Applies one-shots (teleport/delta), integrates position using current velocity,
/// performs seek arrival snap, constraints, and settles small motion.
struct MovementStateSystem: System
{
    func requiredComponent() -> ComponentTypeID
    {
        return MoveStateComponent.typeID
    }

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let stateComp = component as! MoveStateComponent
        guard let exertionComp = stateComp.sibling(MoveExertionComponent.self) else
        {
            return
        }
        guard let transformComp = stateComp.sibling(TransformComponent.self) else
        {
            return
        }
        
        transformComp.prevPosition = transformComp.position
        transformComp.prevRotation = transformComp.rotation
        transformComp.prevScale    = transformComp.scale

        var position = transformComp.position
        stateComp.lastAppliedDelta = .zero
        
        // Velocity integration (semi-implicit Euler was done in PhysicsSystem for v
        // here we integrate x using the current velocity)
        if deltaTime > 0, stateComp.velocity.lengthSquared > 0
        {
            let deltaVelocity = stateComp.velocity * deltaTime
            position.x += deltaVelocity.dx
            position.y += deltaVelocity.dy
            stateComp.lastAppliedDelta += deltaVelocity
        }

        switch exertionComp.intent
        {
            
        case .seekTarget:
            
            guard let target = exertionComp.target else
            {
                break
            }
            
            let lastVector = CGVector(
                dx: target.x - transformComp.position.x,
                dy: target.y - transformComp.position.y
            )
            
            let currentVector   = CGVector(dx: target.x - position.x, dy: target.y - position.y)
            let crossed = (lastVector.dx * currentVector.dx + lastVector.dy * currentVector.dy) <= 0

            let dx = target.x - position.x
            let dy = target.y - position.y
            let distance = sqrt(dx*dx + dy*dy)
            stateComp.remainingDistance = distance

            let arriveEpsilon = max(
                exertionComp.arriveEpsilon,
                1.0 / CGFloat(admin.singleton(Single_MetalSurfaceComponent.self).pixelsPerUnit)
            )

            if crossed || distance <= arriveEpsilon
            {
                position = target
                settleMoveState(stateComp, andExertion: exertionComp)
            }
            else
            {
                stateComp.isSeeking = true
                stateComp.currentSeekTarget = target
            }
            
        case .teleportTo:
            
            guard let target = exertionComp.target else
            {
                break
            }
            
            position = target
            settleMoveState(stateComp, andExertion: exertionComp)
            
        default:
            
            // .moveInDirection, etc
            stateComp.isSeeking = false
            stateComp.currentSeekTarget = nil
        }

        // Clamp speed by stat based caps
        if let maxVelocity = stateComp.sibling(BaseStatsComponent.self)?.moveSpeedMax, maxVelocity > 0
        {
            stateComp.velocity = stateComp.velocity.clampedMagnitude(maxVelocity)
        }

        // Commit
        transformComp.position = position
        stateComp.isSettled = stateComp.isSettled && stateComp.velocity.length < stateComp.settledEpsilon && exertionComp.intent == .none
    }
    
    @inline(__always)
    private func settleMoveState(_ stateComp: MoveStateComponent, andExertion exertionComp: MoveExertionComponent? = nil)
    {
        stateComp.velocity = .zero
        stateComp.acceleration = .zero
        stateComp.isSeeking = false
        stateComp.currentSeekTarget = nil
        stateComp.remainingDistance = 0
        exertionComp?.target = nil
        exertionComp?.intent = .none
    }
}
