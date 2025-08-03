//
//  GameInputManager.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import UIKit

/// Singleton that provides input lookups for SKScene
class GameInputManager
{
    static let shared = GameInputManager()
    private init() {}

    /// Adds newly created Components needed for input system to the Entity
    func addComponentsForEntity(entity: Entity, forInput input: GameInput, atPoint pos: CGPoint)
    {
        let inputComp = GameInputComponent()
        inputComp.pressedInputs.insert(input)
        inputComp.touchLocation = pos

        let timestampComp = TimeComponent(interval: CACurrentMediaTime())

        EntityAdmin.shared.addComponents([inputComp, timestampComp], to: entity)
    }
}

/// Unified abstraction for inputs (wrapping UIKeyCommand + touch events)
enum GameInput: Hashable
{
    case leftArrow, rightArrow, upArrow, downArrow, space
    case touchDown, touchMoved, touchUp
    case custom(String)

    static func from(_ keyCommand: UIKeyCommand) -> GameInput?
    {
        switch keyCommand.input
        {
        case UIKeyCommand.inputLeftArrow:  return .leftArrow
        case UIKeyCommand.inputRightArrow: return .rightArrow
        case UIKeyCommand.inputUpArrow:    return .upArrow
        case UIKeyCommand.inputDownArrow:  return .downArrow
        case " ":                          return .space
        default:
            if let input = keyCommand.input { return .custom(input) }
            return nil
        }
    }
    
    static func from(_ touch: UITouch) -> GameInput?
    {
        switch touch.phase
        {
        case .began:     return .touchDown
        case .moved:     return .touchMoved
        case .ended:     return .touchUp
        case .cancelled: return .touchUp
        default:         return nil
        }
    }
}
