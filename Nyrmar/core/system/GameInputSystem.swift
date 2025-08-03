//
//  InputSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/2/25.
//


/// System that polls input events (keyboard + touch) and updates InputComponents
class GameInputSystem: System
{
    let requiredComponent: ComponentTypeID = InputComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let inputComp = component as! InputComponent

        // Handle keyboard input
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        if inputComp.pressedKeys.contains(.leftArrow) { dx -= 1 }
        if inputComp.pressedKeys.contains(.rightArrow) { dx += 1 }
        if inputComp.pressedKeys.contains(.upArrow) { dy += 1 }
        if inputComp.pressedKeys.contains(.downArrow) { dy -= 1 }

        inputComp.movement = CGVector(dx: dx, dy: dy)
        inputComp.isAttacking = inputComp.pressedKeys.contains(.space)

        // Handle touch input
        if let scene = world.scene, let touch = inputComp.activeTouches.first
        {
            inputComp.touchLocation = touch.location(in: scene)
        }
        else
        {
            inputComp.touchLocation = nil
        }
    }
}
