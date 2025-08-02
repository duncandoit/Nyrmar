//
//  SpawnSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/1/25.
//

import Foundation

/// System that ensures entities with a TransformComponent + SKNodeComponent are added to the scene
class NodeSpawnSystem: System
{
    let requiredComponent: ComponentTypeID = AvatarComponent.typeID
    private var spawned: Set<UUID> = []

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let avatarComp = component as! AvatarComponent
        guard let transformComp = avatarComp.sibling(TransformComponent.self) else
        {
            print(#function, "Could not find TransformComponent for \(avatarComp.owningEntity)")
            return
        }
        
        EntityAdmin.shared.addAvatar(avatarComp, atTransform: transformComp, with: avatarComp.owningEntity)
    }
}
