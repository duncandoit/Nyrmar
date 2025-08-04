//
//  ParametricMovementSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/1/25.
//

import Foundation

/// System that updates entities with a ParametricMovementComponent
class ParametricMovementSystem: System
{
    let requiredComponent = ParametricMovementComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let moveComp = component as! ParametricMovementComponent
        guard let transformComp = moveComp.sibling(TransformComponent.self) else
        {
            print(#function + " - Missing TransformComponent for \(moveComp)")
            return
        }

        moveComp.elapsedTime += deltaTime
        let t = CGFloat(moveComp.elapsedTime)

        let dx = moveComp.amplitude.dx * sin(moveComp.frequency * t + moveComp.phase)
        let dy = moveComp.amplitude.dy * cos(moveComp.frequency * t + moveComp.phase)

        transformComp.position.x += dx
        transformComp.position.y += dy
    }
}
