//
//  PhysicsSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation
import Foundation

final class PhysicsSystem: System
{
    let requiredComponent: ComponentTypeID = MoveStateComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component)
    {
        let moveStateComp = component as! MoveStateComponent
        guard let physicsComp: PhysicsMaterialComponent = moveStateComp.sibling(PhysicsMaterialComponent.self) else
        {
            return
        }
        guard let baseStatsComp = moveStateComp.sibling(BaseStatsComponent.self) else
        {
            return
        }

        // Kinematic / immovable entities: consume impulses, no physics adjustments.
        if physicsComp.mass <= 0
        {
            if let forceAccumulator = moveStateComp.sibling(ForceAccumulatorComponent.self)
            {
                forceAccumulator.impulses.removeAll(keepingCapacity: true)
                if forceAccumulator.forceDecayPerSecond > 0
                {
                    let dampingMultiplier = exp(-physicsComp.linearDamping * CGFloat(max(deltaTime, 0)))
                    forceAccumulator.force = forceAccumulator.force * dampingMultiplier
                }
            }
            moveStateComp.acceleration = .zero
            return
        }

        let deltaTimeScalar = CGFloat(max(deltaTime, 0))
        let inverseMass: CGFloat = 1.0 / physicsComp.mass

        // Accumulate accelerations from Exertion
        var accumulatedAcceleration = moveStateComp.acceleration

        // Gravity (example world units: points/s^2)
        if physicsComp.gravityScale != 0
        {
            let gravityAcceleration = CGVector(dx: 0, dy: -980) * physicsComp.gravityScale
            accumulatedAcceleration = accumulatedAcceleration + gravityAcceleration
        }

        // External forces & impulses
        if let forceAccumulator: ForceAccumulatorComponent = moveStateComp.sibling(ForceAccumulatorComponent.self)
        {
            if forceAccumulator.force.lengthSquared > 0
            {
                accumulatedAcceleration = accumulatedAcceleration + (forceAccumulator.force * inverseMass)

                if forceAccumulator.forceDecayPerSecond > 0, deltaTimeScalar > 0
                {
                    let decayMultiplier = exp(-forceAccumulator.forceDecayPerSecond * deltaTimeScalar)
                    forceAccumulator.force = forceAccumulator.force * decayMultiplier
                    if forceAccumulator.force.length < 0.0001
                    {
                        forceAccumulator.force = .zero
                    }
                }
            }

            if !forceAccumulator.impulses.isEmpty
            {
                var deltaVelocityFromImpulses = CGVector.zero
                for impulse in forceAccumulator.impulses
                {
                    deltaVelocityFromImpulses = deltaVelocityFromImpulses + (impulse * inverseMass)
                }
                moveStateComp.velocity = moveStateComp.velocity + deltaVelocityFromImpulses
                forceAccumulator.impulses.removeAll(keepingCapacity: true)
            }
        }

        // Linear drag: a_drag = -(c/m) * v
        if physicsComp.linearDrag > 0
        {
            let dragAcceleration = moveStateComp.velocity * (physicsComp.linearDrag * inverseMass)
            accumulatedAcceleration = accumulatedAcceleration - dragAcceleration
        }

        // Integrate velocity (semi-implicit Euler for v)
        if deltaTimeScalar > 0
        {
            moveStateComp.velocity = moveStateComp.velocity + (accumulatedAcceleration * deltaTimeScalar)
        }

        // Exponential damping (framerate independent)
        if physicsComp.linearDamping > 0, deltaTimeScalar > 0
        {
            let dampingMultiplier = exp(-physicsComp.linearDamping * deltaTimeScalar)
            moveStateComp.velocity = moveStateComp.velocity * dampingMultiplier
        }

        // Speed caps: material then mover policy
        if let maxVelocity = physicsComp.maxSpeed
        {
            moveStateComp.velocity = moveStateComp.velocity.clampedMagnitude(maxVelocity)
        }
        if let maxVelocityFromThrall = baseStatsComp.moveSpeedMax
        {
            moveStateComp.velocity = moveStateComp.velocity.clampedMagnitude(maxVelocityFromThrall)
        }

        // Acceleration is a per-tick result; clear after use.
        moveStateComp.acceleration = .zero
        // MovementStateSystem will apply: position += velocity * dt.
    }
}
