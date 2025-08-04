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
    let requiredComponent: ComponentTypeID = ControlledByComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let controlledByComp = component as! ControlledByComponent
        guard controlledByComp.controllerID == world.getLocalPlayerID() else
        {
            print(#function + " - Not controlled by local player")
            return
        }
        
        guard let inputComp = controlledByComp.sibling(GameInputComponent.self) else
        {
            print(#function + " - No input given to controlled Entity.")
            return
        }
        
        guard let transformComp = inputComp.sibling(TransformComponent.self) else
        {
            print(#function + " - Controllable Entity does not have a TransformComponent.")
            return
        }

        // Handle keyboard input
//        var dx: CGFloat = 0
//        var dy: CGFloat = 0
//        if inputComp.pressedInputs.contains(.leftArrow) { dx -= 1 }
//        if inputComp.pressedInputs.contains(.rightArrow) { dx += 1 }
//        if inputComp.pressedInputs.contains(.upArrow) { dy += 1 }
//        if inputComp.pressedInputs.contains(.downArrow) { dy -= 1 }

        // Modify the transform of the entity with this inputComp
        guard let pos = inputComp.touchLocation else
        {
            print(#function + " - GameInputComponent had a nil touch event")
            return
        }
        
        transformComp.position = pos
    }
}
