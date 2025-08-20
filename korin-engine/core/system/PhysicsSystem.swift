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
        guard let moveStateComp = physicsComp.sibling(MoveStateComponent.self) else
        {
            return
        }
        guard deltaTime > 0 else
        {
            return
        }
        
        // Start with intent acceleration produced by MovementExertionSystem
        var acceleration = moveStateComp.acceleration
        let invertedMass: CGFloat = 1.0 / physicsComp.mass
        
        if let physicsTermComp = physicsComp.sibling(PhysicsTermComponent.self)
        {
            
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
                
                // quantity's acceleration contribution
                let vector: CGVector = {
                    switch term.quantity
                    {
                    case .acceleration(let acceleration):
                        
                        return acceleration
                        
                    case .force(let force):
                        
                        return force * invertedMass
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

        // Caps the speed at the movement state's max, which is bounded by the physics' own max.
        // The movement state's max is potentially influenced by character stats.
        if let maxVelocity = moveStateComp.maxVelocity
        {
            moveStateComp.velocity = moveStateComp.velocity.clampedMagnitude(maxVelocity < physicsComp.maxVelocity ? maxVelocity : physicsComp.maxVelocity)
        }
        else
        {
            moveStateComp.velocity = moveStateComp.velocity.clampedMagnitude(physicsComp.maxVelocity)
        }

        // Clear per-tick acceleration (it was a result of arbitration this tick)
        moveStateComp.acceleration = .zero
    }
}
