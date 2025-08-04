//
//  GameInputComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import UIKit

/// Component for tracking player input state
class GameInputComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: GameInputComponent.self)
    var siblings: SiblingContainer?

    var touchLocation: CGPoint? = nil
    var pressedInputs: Set<GameInput> = []
}
