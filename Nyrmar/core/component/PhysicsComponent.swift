//
//  PhysicsComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

class PhysicsComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: PhysicsComponent.self)
    var siblings: SiblingContainer?
    
    var velocity: CGVector
    
    init(velocity: CGVector)
    {
        self.velocity = velocity
    }
}
