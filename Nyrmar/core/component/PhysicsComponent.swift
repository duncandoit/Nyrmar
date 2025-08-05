//
//  GravityForceComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

/// Component representing core physics state (velocity and mass)
class PhysicsComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: PhysicsComponent.self)
    var siblings: SiblingContainer?
    
    var velocity: CGVector = .zero
    var mass: CGFloat = 1.0
    
    init(mass: CGFloat = 1.0)
    {
        self.mass = mass
    }
}
