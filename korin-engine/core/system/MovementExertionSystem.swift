//
//  MovementSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreGraphics
import Foundation

/// Reads MoveExertionComponent intents and writes a *desired acceleration*
/// into MoveStateComponent.acceleration via a PD controller (seek).
final class MovementExertionSystem: System
{
    let requiredComponent: ComponentTypeID = MoveExertionComponent.typeID

    func update(deltaTime dt: TimeInterval, component: any Component, admin: EntityAdmin)
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

        // Clear per–tick output (we’ll author it below if there is intent).
        stateComp.acceleration = .zero
        stateComp.lastAppliedDelta = .zero
        
        if exertionComp.killVelocity
        {
            stateComp.velocity = .zero
            exertionComp.killVelocity = false
        }

        // High-level seek intent: PD acceleration
        if let target = exertionComp.seekTarget
        {
            // Position error
            let toTarget = CGVector(
                dx: target.x - transformComp.position.x,
                dy: target.y - transformComp.position.y
            )
            
            let distance = toTarget.length
            stateComp.isSeeking = true
            stateComp.currentSeekTarget = target
            stateComp.remainingDistance = distance

            // PD: a = Kp * e - Kd * v
            let Kp = exertionComp.seekKp
            let Kd = exertionComp.seekKd
            var a   = toTarget * Kp - stateComp.velocity * Kd

            // Ground interaction / air control
            if stateComp.isGrounded
            {
                // Remove acceleration component into the ground (keep tangential)
                let n = stateComp.groundNormal.normalized()
                let dot = a.dx * n.dx + a.dy * n.dy
                a = CGVector(dx: a.dx - dot * n.dx, dy: a.dy - dot * n.dy)
            }
            else
            {
                // Throttle control while airborne
                a = a * max(0, min(1, stateComp.airControl))
            }

            // Clamp seek acceleration
            a = a.clampedMagnitude(exertionComp.maxSeekAcceleration)
            stateComp.acceleration = a

            // Arrival snap hysteresis
            //if distance <= max(exertionComp.arriveEpsilon, 1.0 /  CGFloat(admin.camera2DComponent().pixelsPerUnit))
            //{
            //    // Let MovementStateSystem handle the final snap & clearing.
            //}
        }
        else
        {
            stateComp.isSeeking = false
            stateComp.currentSeekTarget = nil
            stateComp.remainingDistance = 0
        }
    }
}
