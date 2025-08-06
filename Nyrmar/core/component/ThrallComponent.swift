//
//  ThrallComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/3/25.
//

import Foundation

class ThrallComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: ThrallComponent.self)
    var siblings: SiblingContainer?

    var controllerID: UUID?
    
    init(controllerID: UUID? = nil)
    {
        self.controllerID = controllerID
    }
}
