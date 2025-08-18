//
//  MovementStateSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/10/25.
//

import Foundation

/// Applies one-shots, integrates velocity with dt, enforces clamps, updates Transform
final class MovementStateSystem: System
{
    let requiredComponent: ComponentTypeID = MoveStateComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let moveStateComp = component as! MoveStateComponent
        guard let exertionComp = moveStateComp.sibling(MoveExertionComponent.self) else
        {
            return
        }
        guard let transformComp = moveStateComp.sibling(TransformComponent.self) else
        {
            return
        }
        guard let baseStatsComp = moveStateComp.sibling(BaseStatsComponent.self) else
        {
            return
        }
        
        transformComp.prevPosition = transformComp.position
        transformComp.prevRotation = transformComp.rotation
        transformComp.prevScale    = transformComp.scale

        var position = transformComp.position
        moveStateComp.lastAppliedDelta = .zero

        // Teleport
        if let targetPosition = exertionComp.teleportTo
        {
            position = targetPosition
            moveStateComp.velocity = .zero
            moveStateComp.acceleration = .zero
            moveStateComp.isSeeking = false
            moveStateComp.currentSeekTarget = nil
            moveStateComp.remainingDistance = 0
            exertionComp.teleportTo = nil
        }

        // One-shot delta
        if let deltaWorld = exertionComp.deltaWorld
        {
            position.x += deltaWorld.dx
            position.y += deltaWorld.dy
            moveStateComp.lastAppliedDelta = deltaWorld
            exertionComp.deltaWorld = nil
        }

        // Velocity integration
        let prevPosition = position
        if moveStateComp.velocity.length > 0 && deltaTime > 0
        {
            let deltaVelocity = moveStateComp.velocity * deltaTime
            position.x += deltaVelocity.dx
            position.y += deltaVelocity.dy
            moveStateComp.lastAppliedDelta = moveStateComp.lastAppliedDelta + deltaVelocity
        }

        // Seek arrival check (snap & clear when close)
        if let targetPosition = exertionComp.seekTarget
        {
            // crossed target?
            let vPrev = CGVector(dx: targetPosition.x - prevPosition.x, dy: targetPosition.y - prevPosition.y)
            let vNow  = CGVector(dx: targetPosition.x - position.x, dy: targetPosition.y - position.y)
            let crossed = (vPrev.dx * vNow.dx + vPrev.dy * vNow.dy) <= 0

            let dx = targetPosition.x - position.x, dy = targetPosition.y - position.y
            let distance = sqrt(dx*dx + dy*dy)
            moveStateComp.remainingDistance = distance

            if crossed || distance <= exertionComp.arriveEpsilon
            {
                position = targetPosition
                exertionComp.seekTarget = nil
                moveStateComp.isSeeking = false
                moveStateComp.currentSeekTarget = nil
                moveStateComp.velocity = .zero
                moveStateComp.acceleration = .zero
            }
            else
            {
                moveStateComp.isSeeking = true
                moveStateComp.currentSeekTarget = targetPosition
            }
        }
        else
        {
            moveStateComp.isSeeking = false
            moveStateComp.currentSeekTarget = nil
            moveStateComp.remainingDistance = 0
        }

        // Constraints
        if let maxVelocity = baseStatsComp.moveSpeedMax, maxVelocity > 0
        {
            moveStateComp.velocity = moveStateComp.velocity.clampedMagnitude(maxVelocity)
        }
        if let clampRect = exertionComp.clampRect
        {
            position.x = min(max(position.x, clampRect.minX), clampRect.maxX)
            position.y = min(max(position.y, clampRect.minY), clampRect.maxY)
        }
        if let grid = exertionComp.snapToGrid, grid > 0
        {
            position.x = (position.x / grid).rounded() * grid
            position.y = (position.y / grid).rounded() * grid
        }

        // Commit
        transformComp.position = position
        moveStateComp.isSettled = moveStateComp.isSettled && moveStateComp.velocity.length < 0.001 && exertionComp.seekTarget == nil
    }
}
