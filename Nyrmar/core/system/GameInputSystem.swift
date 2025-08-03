//
//  GameInputSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//

import CoreFoundation
import Foundation


/// System that polls input events (keyboard + touch) and updates InputComponents
class GameInputSystem: System
{
    let requiredComponent: ComponentTypeID = GameInputComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let inputComp = component as! GameInputComponent

        // Handle keyboard input
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        if inputComp.pressedInputs.contains(.leftArrow) { dx -= 1 }
        if inputComp.pressedInputs.contains(.rightArrow) { dx += 1 }
        if inputComp.pressedInputs.contains(.upArrow) { dy += 1 }
        if inputComp.pressedInputs.contains(.downArrow) { dy -= 1 }

        // Modify the transform of the entity with this inputComp
        guard let transformComp = inputComp.sibling(TransformComponent.self) else
        {
            print(#function + ": No TransformComponent found for entity with inputComp.")
            return
        }
    }
}
