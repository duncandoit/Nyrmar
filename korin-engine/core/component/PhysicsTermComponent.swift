//
//  PhysicsTermComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/4/25.
//

import Foundation

/// Additional force terms to be applied to the entity in the `PhysicsSystem`.
final class PhysicsTermComponent: Component
{
    static let typeID = componentTypeID(for: PhysicsTermComponent.self)
    var siblings: SiblingContainer?

    enum Space
    {
        case world, local
    }
    
    enum Quantity
    {
        case force(CGVector), acceleration(CGVector)
    }
    
    enum Decay
    {
        case infinite
        case linear(duration: TimeInterval)            // scales to 0 over duration
        case exponential(halfLife: TimeInterval)       // a *= 0.5^(dt/halfLife)
    }

    struct Term
    {
        var id: UUID = UUID()
        var quantity: Quantity
        var space: Space = .world
        var decay: Decay = .infinite
        var remaining: TimeInterval = .infinity        // used for linear/exponential
        var enabled: Bool = true
    }

    /// Continuous fields (gravity, wind, thrusters, buffs, debuffs…)
    var terms: [Term] = []

    /// One-shot impulses (units of impulse; Δv = impulse / mass)
    var impulses: [CGVector] = []
}
