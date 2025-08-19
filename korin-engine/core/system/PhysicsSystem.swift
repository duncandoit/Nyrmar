//
//  PhysicsSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation
import Foundation

final class PhysicsSystem: System
{
    let requiredComponent: ComponentTypeID = PhysicsStateComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let physicsComp = component as! PhysicsStateComponent
        guard !physicsComp.ignorePhysics else
        {
            return
        }
        guard let physicsTermComp = physicsComp.sibling(PhysicsTermComponent.self) else
        {
            return
        }
        guard let moveStateComp = physicsComp.sibling(MoveStateComponent.self) else
        {
            return
        }
        guard deltaTime > 0 else
        {
            return
        }
        
        var keptTerms: [PhysicsTermComponent.Term] = []

        // Kinematic / immovable: consume impulses; decay terms magnitudes; no kinematics
        if physicsComp.mass <= 0
        {
            // decay continuous terms (no motion)
            keptTerms.reserveCapacity(physicsTermComp.terms.count)
            
            for var term in physicsTermComp.terms where term.enabled
            {
                switch term.decay
                {
                case .infinite:
                    
                    ()
                    
                case .linear(_):
                    
                    term.remaining -= deltaTime
                    if term.remaining <= 0
                    {
                        continue
                    }
                    
                case .exponential(_):
                    
                    term.remaining -= deltaTime
                    if term.remaining <= 0
                    {
                        continue
                    }
                }
                
                keptTerms.append(term)
            }
            
            physicsTermComp.terms = keptTerms
            physicsTermComp.impulses.removeAll(keepingCapacity: true)
            
            moveStateComp.acceleration = .zero
            return
        }
        
        let invertedMass: CGFloat = 1.0 / physicsComp.mass

        // Start with intent acceleration produced by MovementExertionSystem
        var acceleration = moveStateComp.acceleration

        // Sum continuous external terms (fields), applying decay and space transforms
        keptTerms = []
        keptTerms.reserveCapacity(physicsTermComp.terms.count)

        // rotation for local-space vectors
        let rotation: (CGVector) -> CGVector = {
            if let transformComp: TransformComponent = moveStateComp.sibling(TransformComponent.self)
            {
                let cosine = cos(transformComp.rotation)
                let sine = sin(transformComp.rotation)
                
                return { vector in
                    CGVector(dx: cosine*vector.dx - sine*vector.dy, dy: sine*vector.dx + cosine*vector.dy)
                }
            }
            else
            {
                return { $0 }
            }
        }()

        for var term in physicsTermComp.terms where term.enabled
        {
            // decay bookkeeping
            var scale: CGFloat = 1
            switch term.decay
            {
            case .infinite:
                
                ()
                
            case .linear(let dur):
                
                term.remaining -= deltaTime
                if term.remaining <= 0
                {
                    continue
                }
                
                let t = max(0, min(1, CGFloat(1 - term.remaining / max(dur, 1e-6))))
                scale = 1 - t
                
            case .exponential(let half):
                
                term.remaining -= deltaTime
                if term.remaining <= 0
                {
                    continue
                }
                
                scale = pow(0.5, CGFloat(deltaTime) / CGFloat(max(half, 1e-6)))
            }

            // quantity → acceleration contribution
            let vector: CGVector = {
                switch term.quantity
                {
                case .acceleration(let acc):
                    
                    return acc
                    
                case .force(let F):
                    
                    return F * invertedMass
                }
            }()

            let worldVec = (term.space == .local) ? rotation(vector) : vector
            acceleration += worldVec * scale
            keptTerms.append(term)
        }
        
        physicsTermComp.terms = keptTerms

        // One-shot impulses: Δv = Σ(J) / m
        if !physicsTermComp.impulses.isEmpty
        {
            var dv = CGVector.zero
            for J in physicsTermComp.impulses
            {
                dv += J * invertedMass
            }
            
            moveStateComp.velocity += dv
            physicsTermComp.impulses.removeAll(keepingCapacity: true)
        }

        // Linear drag: a_drag = -(c/m) * v   (proportional to velocity)
        if physicsComp.linearDrag > 0
        {
            acceleration -= moveStateComp.velocity * (physicsComp.linearDrag * invertedMass)
        }

        // Integrate velocity (semi-implicit Euler)
        moveStateComp.velocity += acceleration * deltaTime

        // Exponential damping (frame-rate independent)
        if physicsComp.linearDamping > 0
        {
            let k: Double = exp(-physicsComp.linearDamping * deltaTime)
            moveStateComp.velocity *= k
        }

        // Speed caps: material then base stats
        if let maxVelocity = physicsComp.maxSpeed
        {
            moveStateComp.velocity = moveStateComp.velocity.clampedMagnitude(maxVelocity)
        }
        
        if let maxVelocity = moveStateComp.sibling(BaseStatsComponent.self)?.moveSpeedMax
        {
            moveStateComp.velocity = moveStateComp.velocity.clampedMagnitude(maxVelocity)
        }

        // Clear per-tick acceleration (it was a result of arbitration this tick)
        moveStateComp.acceleration = .zero
    }
}
