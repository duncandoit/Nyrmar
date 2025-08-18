//
//  MovementStateSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/10/25.
//

import Foundation

/// Applies one-shots (teleport/delta), integrates position using current velocity,
/// performs seek arrival snap, constraints, and settles small motion.
final class MovementStateSystem: System
{
    let requiredComponent: ComponentTypeID = MoveStateComponent.typeID

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

        var targetPosition = transformComp.position
        stateComp.lastAppliedDelta = .zero

        // One-shot: teleport
        if let position = exertionComp.teleportTo
        {
            targetPosition = position
            stateComp.velocity     = .zero
            stateComp.acceleration = .zero
            stateComp.isSeeking    = false
            stateComp.currentSeekTarget = nil
            stateComp.remainingDistance = 0
            exertionComp.teleportTo = nil
        }

        // One-shot: absolute world delta
        if let deltaPosition = exertionComp.deltaWorld
        {
            targetPosition.x += deltaPosition.dx
            targetPosition.y += deltaPosition.dy
            stateComp.lastAppliedDelta += deltaPosition
            exertionComp.deltaWorld = nil
        }

        // Velocity integration (semi-implicit Euler was done in PhysicsSystem for v
        // here we integrate x using the current velocity)
        if deltaTime > 0, stateComp.velocity.lengthSquared > 0
        {
            let deltaVelocity = stateComp.velocity * deltaTime
            targetPosition.x += deltaVelocity.dx
            targetPosition.y += deltaVelocity.dy
            stateComp.lastAppliedDelta += deltaVelocity
        }

        // Seek arrival snap (and crossing protection)
        if let target = exertionComp.seekTarget
        {
            let prevTo = CGVector(
                dx: target.x - transformComp.position.x,
                dy: target.y - transformComp.position.y
            )
            
            let nowTo   = CGVector(dx: target.x - targetPosition.x, dy: target.y - targetPosition.y)
            let crossed = (prevTo.dx * nowTo.dx + prevTo.dy * nowTo.dy) <= 0

            let dx = target.x - targetPosition.x
            let dy = target.y - targetPosition.y
            let distance = sqrt(dx*dx + dy*dy)
            stateComp.remainingDistance = distance

            let arriveEpsilon = max(
                exertionComp.arriveEpsilon,
                1.0 / CGFloat(admin.camera2DComponent().pixelsPerUnit)
            )

            if crossed || distance <= arriveEpsilon
            {
                targetPosition = target
                exertionComp.seekTarget = nil
                stateComp.isSeeking = false
                stateComp.currentSeekTarget = nil
                stateComp.velocity = .zero      // stop precisely at target
                stateComp.acceleration = .zero
            }
            else
            {
                stateComp.isSeeking = true
                stateComp.currentSeekTarget = target
            }
        }
        else
        {
            stateComp.isSeeking = false
            stateComp.currentSeekTarget = nil
            stateComp.remainingDistance = 0
        }

        // Commit & settle
        transformComp.position = targetPosition
        stateComp.isSettled = stateComp.velocity.length < stateComp.settledEpsilon && exertionComp.seekTarget == nil
    }
}
