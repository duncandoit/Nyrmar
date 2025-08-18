//
//  GravityForceComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

/// Adds the entity to the `PhysicsSystem` with these characteristics.
final class PhysicsMaterialComponent: Component
{
    static let typeID = componentTypeID(for: PhysicsMaterialComponent.self)
    var siblings: SiblingContainer?
    
    /// If true the `PhysicsSystem` is skipped for this entity.
    var ignorePhysics = false

    /// <= 0 is immovable/kinematic
    var mass: CGFloat = 1.0
    
    /// Per-second exponential damping
    var linearDamping: CGFloat = 0.0
    
    /// 0 = none, 1 = full, −1 = inverted
    var gravityScale: CGFloat = 1.0
    
    /// force proportionality to velocity
    var linearDrag: CGFloat = 0.0
    
    /// Material-level speed cap
    var maxSpeed: CGFloat? = nil
}
