//
//  ForceAccumulatorComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

final class ForceAccumulatorComponent: Component
{
    static let typeID = componentTypeID(for: ForceAccumulatorComponent.self)
    var siblings: SiblingContainer?

    /// Continuous world-space force
    var force: CGVector = .zero
    
    /// Exponential decay of force
    var forceDecayPerSecond: CGFloat = 0.0
    
    /// One-frame impulses that are cleared after use
    var impulses: [CGVector] = []
}
