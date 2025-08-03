//
//  InputComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import UIKit

/// Component for tracking player input state
class GameInputComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: GameInputComponent.self)
    var siblings: [ComponentTypeID: WeakComponentRef]?

    var movement: CGVector = .zero
    var isAttacking: Bool = false
    var touchLocation: CGPoint? = nil
    var pressedInputs: Set<GameInput> = []
    var activeTouches: Set<UITouch> = []
}
