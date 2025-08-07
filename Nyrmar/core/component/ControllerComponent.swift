//
//  ControllerComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/5/25.
//

import Foundation

typealias ControllerID = UUID

class ControllerComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: ControllerComponent.self)
    var siblings: SiblingContainer?

    var controllerID: ControllerID
    
    init(controllerID: ControllerID = ControllerID())
    {
        self.controllerID = controllerID
    }
}
