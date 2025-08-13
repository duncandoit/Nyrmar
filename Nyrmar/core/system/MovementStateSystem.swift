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

    func update(deltaTime dt: TimeInterval, component: any Component)
    {
        let moveStateComp = component as! MoveStateComponent
        guard let moverComp = moveStateComp.sibling(MoveExertionComponent.self) else
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

        let deltaTime = CGFloat(max(dt, 0))
        var position = transformComp.position
        moveStateComp.lastAppliedDelta = .zero

        // Teleport (one-shot; highest precedence)
        if let point = moverComp.teleportTo
        {
            position = point
            moveStateComp.velocity = .zero
            moveStateComp.acceleration = .zero
            moveStateComp.isSeeking = false
            moveStateComp.currentSeekTarget = nil
            moveStateComp.remainingDistance = 0
            moverComp.teleportTo = nil
        }

        // One-shot delta
        if let delta = moverComp.deltaWorld
        {
            position.x += delta.dx
            position.y += delta.dy
            moveStateComp.lastAppliedDelta = delta
            moverComp.deltaWorld = nil
        }

        // Velocity integration
        if moveStateComp.velocity.length > 0 && deltaTime > 0
        {
            let dv = moveStateComp.velocity * deltaTime
            position.x += dv.dx
            position.y += dv.dy
            moveStateComp.lastAppliedDelta = moveStateComp.lastAppliedDelta + dv
        }

        // Seek arrival check (snap & clear when close)
        if let targetPosition = moverComp.seekTarget
        {
            let dx = targetPosition.x - position.x
            let dy = targetPosition.y - position.y
            let dist = sqrt(dx*dx + dy*dy)
            moveStateComp.remainingDistance = dist
            if dist <= moverComp.arriveEpsilon
            {
                position = targetPosition
                moverComp.seekTarget = nil
                moveStateComp.isSeeking = false
                moveStateComp.currentSeekTarget = nil
                // Optionally zero velocity at arrival:
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
        if let rect = moverComp.clampRect
        {
            position.x = min(max(position.x, rect.minX), rect.maxX)
            position.y = min(max(position.y, rect.minY), rect.maxY)
        }
        if let grid = moverComp.snapToGrid, grid > 0
        {
            position.x = (position.x / grid).rounded() * grid
            position.y = (position.y / grid).rounded() * grid
        }

        // Commit
        transformComp.position = position
        moveStateComp.isSettled = moveStateComp.isSettled && moveStateComp.velocity.length < 0.001 && moverComp.seekTarget == nil
    }
}
