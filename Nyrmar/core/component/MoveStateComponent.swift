//
//  MoveStateComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/10/25.
//

import CoreFoundation

/// Current data on the status of the entity's movement.
/// Mutated by both the `MovementStateSystem` and `MovementExertionSystem`.
final class MoveStateComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: MoveStateComponent.self)
    var siblings: SiblingContainer?

// MARK: instantaneous state
    
    var velocity: CGVector = .zero        // pts/s
    var acceleration: CGVector = .zero    // pts/s^2

// MARK: diagnostics / book-keeping
    
    var lastAppliedDelta: CGVector = .zero
    var isSeeking: Bool = false
    var currentSeekTarget: CGPoint? = nil
    var remainingDistance: CGFloat = 0
    var isSettled: Bool = true
    let settledEpsilon = 0.5
    var isGrounded: Bool = false
    var groundNormal: CGVector = .init(dx: 0, dy: 1)
    var airControl: CGFloat = 0.5        // 0 = no control in air, 1 = full control
}
