//
//  ControlledByComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/3/25.
//

import Foundation

class ControlledByComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: ControlledByComponent.self)
    var siblings: [ComponentTypeID: WeakComponentRef]?

    var controllerID: UUID
    
    init(controllerID: UUID)
    {
        self.controllerID = controllerID
    }
}
