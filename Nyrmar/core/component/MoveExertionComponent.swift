//
//  MoveExertionComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

/// Source that authored the move intent 
enum MovementLayer: UInt8
{
    case player, ai, script, physics
}

/// Declarative intents + policy constraints
/// `MovementExertionSystem` reads intent fields (seekTarget, velocityDesired, etc.) and policy (maxAcceleration, priorities).
/// It arbitrates multiple writers (player, AI, etc), resolves conflicts, and outputs desired kinematics.
final class MoveExertionComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: MoveExertionComponent.self)
    var siblings: SiblingContainer?

    // One-frame intents (systems clear after applying)
    var teleportTo: CGPoint?              // hard snap; overrides everything for the frame
    var deltaWorld: CGVector?             // absolute world delta to add this frame
    var velocityDesired: CGVector?        // instantaneous desired velocity (pts/s)
    var seekTarget: CGPoint?              // world target; keep until reached
    var seekSpeed: CGFloat?               // pts/s (fallback to moveSpeed if nil)
    var faceTarget: CGPoint?              // world point to face (if you rotate elsewhere)
    var faceAngularSpeed: CGFloat?        // rad/s (nil => snap)

    // Persistent constraints / policy
    var maxAcceleration: CGFloat? = nil
    var clampRect: CGRect? = nil          // keep position within bounds
    var snapToGrid: CGFloat? = nil        // e.g., 1.0 for pixel-perfect
    var arriveEpsilon: CGFloat = 0.5      // "close enough" for seek
    var layer: MovementLayer = .player
    var priority: Int16 = 0               // higher wins if intents conflict
}
