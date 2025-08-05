//
//  GameInputCleanupSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/3/25.
//

import Foundation

class GameInputCleanupSystem: System
{
    let requiredComponent: ComponentTypeID = GameInputComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        EntityAdmin.shared.removeComponent(ofType: GameInputComponent.typeID, from: EntityAdmin.shared.getControlledAvatarEntity())
    }
}
