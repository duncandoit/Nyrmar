//
//  PhysicsStateComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

/// Adds the entity to the `PhysicsSystem` with these characteristics.
final class PhysicsStateComponent: Component
{
    static let typeID = componentTypeID(for: PhysicsStateComponent.self)
    var siblings: SiblingContainer?
    
    /// If true this entity will not be run in the PhysicsSystem.
    var ignorePhysics: Bool = false
    
// MARK: Inertial properties
    
    /// <= 0 => kinematic/immovable
    var mass: CGFloat = 1.0
    
    /// Hard speed cap (world units / s).
    let maxVelocity: CGFloat = 5000.0
    
// MARK: Damping & drag
    
    /// Exponential velocity damping (frame-rate independent). [0-1] per second.
    var linearDamping: CGFloat = 0.0

    /// viscous drag coefficient (a_drag = -(c/m)*v)
    var linearDrag: CGFloat = 0.0
    
    /// Linear air drag (extra damping) applied always. [0-1] per second.
    var airDrag: CGFloat = 0.0
    
// MARK: Fields / grounding

    /// Scales persistent fields (e.g. gravity) if you want lighter/heavier entities.
    var gravityScale: CGFloat = 1.0

    /// Ground tangential friction decel (world units / s²) applied when grounded.
    var groundFriction: CGFloat = 0.0
}
