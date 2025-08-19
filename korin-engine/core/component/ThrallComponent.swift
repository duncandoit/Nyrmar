//
//  ThrallComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/3/25.
//

import Foundation

/// Binds an entity to the `PlayerCommand` authored by the `ControllerID`
class ThrallComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: ThrallComponent.self)
    var siblings: SiblingContainer?

    var controllerID: ControllerID?
    
    init(controllerID: ControllerID)
    {
        self.controllerID = controllerID
    }
}
