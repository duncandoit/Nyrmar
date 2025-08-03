//
//  GameInputManager.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import Foundation

/// Singleton that provides input lookups for SKScene
class GameInputManager
{
    static let shared = GameInputManager()
    private init() {}

    /// Return a dict of a newly created entity with GameInputComponent and TimestampComponent
    func entityForInput(_ input: GameInput, atPoint pos: CGPoint) -> [Entity: [Component]]
    {
        let entity = Entity()
        let inputComp = InputComponent()
        inputComp.pressedInputs.insert(input)
        inputComp.touchLocation = pos

        let timestampComp = TimestampComponent(lastUpdated: CACurrentMediaTime())

        return [entity: [inputComp, timestampComp]]
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
        case UIKeyCommand.inputLeftArrow: return .leftArrow
        case UIKeyCommand.inputRightArrow: return .rightArrow
        case UIKeyCommand.inputUpArrow: return .upArrow
        case UIKeyCommand.inputDownArrow: return .downArrow
        case " ": return .space
        default:
            if let input = keyCommand.input { return .custom(input) }
            return nil
        }
    }

    /// Factory to produce a map of entities to their Input and Timestamp components
    static func captureInputs(world: GameWorld) -> [UUID: (GameInputComponent, TimestampComponent)]
    {
        var results: [UUID: (GameInputComponent, TimestampComponent)] = [:]

        for (entityId, comps) in world.allEntities()
        {
            if let inputComp = comps[GameInputComponent.typeID] as? GameInputComponent,
               let timestampComp = comps[TimestampComponent.typeID] as? TimestampComponent
            {
                results[entityId] = (inputComp, timestampComp)
            }
        }

        return results
    }
}
