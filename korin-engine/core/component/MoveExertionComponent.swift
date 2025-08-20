//
//  MoveExertionComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

/// Declarative movement intents for one tick.
/// Used by MovementExertionSystem  PhysicsTermComponent
/// Finalized by MotionFinalizationSystem.
final class MoveExertionComponent: Component
{
    static let typeID = componentTypeID(for: MoveExertionComponent.self)
    var siblings: SiblingContainer?
    
    enum Intent
    {
        case none, seekTarget, moveInDirection, teleportTo
    }
    
    var intent: Intent = .none
    var target: CGPoint? = nil
    var acceleration: CGFloat = 12.0
    var dampening: CGFloat = 4.0
    
    /// Target cruise speed for moveInDirection.
    /// Falls back to stat defined move speed if available.
    var desiredSpeed: CGFloat? = nil

// MARK: Constraints
    
    // Arrival snap threshold (world units). Consider ≥ 1/PPU.
    var arriveEpsilon: CGFloat = 0.01
    
    // Tells the `MovementExertionSystem` to zero out velocity if true
    var killVelocity: Bool = false
}
