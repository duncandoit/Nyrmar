//
//  ForceAccumulatorComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

/// Component for accumulating forces: gravity and external
class ForceAccumulatorComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: ForceAccumulatorComponent.self)
    var siblings: SiblingContainer?
    
    /// Downward gravitational acceleration
    var gravityStrength: CGFloat
    
    /// Other applied forces
    var impulse: CGVector = .zero
    
    init(gravityStrength: CGFloat = 9.8)
    {
        self.gravityStrength = gravityStrength
    }
}
