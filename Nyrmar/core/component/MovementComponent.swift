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
    
    var controllerID: ControllerID?
    var destination: CGPoint?
    let destinationThreshold: CGFloat = 1.0
    var direction: CGVector?
}
