//
//  MovementComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/4/25.
//

import CoreFoundation

/// Component for direct target-based movement
class MovementComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: MovementComponent.self)
    var siblings: SiblingContainer?
    
    var destination: CGPoint?
    var moveSpeed: CGFloat
    
    init(moveSpeed: CGFloat = 200.0, destination: CGPoint? = nil)
    {
        self.moveSpeed = moveSpeed
        self.destination = destination
    }
}
