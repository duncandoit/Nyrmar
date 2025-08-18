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

/// Declarative movement intents for one tick.
/// Used by MovementExertionSystem → PhysicsTermComponent
/// Finalized by MotionFinalizationSystem.
final class MoveExertionComponent: Component
{
    static let typeID = componentTypeID(for: MoveExertionComponent.self)
    var siblings: SiblingContainer?

// MARK: High-level goal: seek to a world-space target
    
    var seekTarget: CGPoint? = nil
    var killVelocity: Bool = false

// MARK: PD gains for seek (acceleration output)
    
    var seekKp: CGFloat = 12.0
    var seekKd: CGFloat = 4.0

// MARK: Clamp for the seek-produced acceleration (world units / s^2)
    
    var maxSeekAcceleration: CGFloat = 4000.0

// MARK: Arrival snap threshold (world units). Consider ≥ 1/PPU.
    
    var arriveEpsilon: CGFloat = 0.01

// MARK: One-shot transforms (consumed when applied)
    
    var teleportTo: CGPoint? = nil
    var deltaWorld: CGVector? = nil
}
