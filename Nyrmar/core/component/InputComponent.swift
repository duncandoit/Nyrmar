//
//  InputComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import UIKit

/// Component for tracking player input state
class InputComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: InputComponent.self)
    var siblings: SiblingContainer?

    var commandBuffer = CommandBuffer()
    var touchDownLocation: CGPoint? = nil
    var touchMoveLocation: CGPoint? = nil
    var touchUpLocation: CGPoint? = nil
}
