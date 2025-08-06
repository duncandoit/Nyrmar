//
//  ControllerComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/5/25.
//

import Foundation

class ControllerComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: ControllerComponent.self)
    var siblings: SiblingContainer?

    var controllerID: UUID
    
    init(controllerID: UUID = UUID())
    {
        self.controllerID = controllerID
    }
}
