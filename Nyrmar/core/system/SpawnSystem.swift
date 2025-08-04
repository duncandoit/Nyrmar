//
//  SpawnSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/1/25.
//

import Foundation

/// System that ensures entities with AvatarComponents marked as wanting to spawn are added to the game world
class SpawnSystem: System
{
    let requiredComponent: ComponentTypeID = AvatarComponent.typeID
    private var spawned: Set<UUID> = []

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let avatarComp = component as! AvatarComponent
        guard avatarComp.wantsToSpawn else
        {
            print(#function + ": Avatar does not want to spawn.")
            return
        }
        
        guard let transformComp = avatarComp.sibling(TransformComponent.self) else
        {
            print(#function, ": Could not find TransformComponent for \(avatarComp.owningEntity).")
            return
        }
        
        guard let avatar = AvatarManager.shared.createAvatar(atTransform: transformComp, with: avatarComp.owningEntity) else
        {
            print(#function + ": Avatar could not be made for Entity:\(avatarComp.owningEntity).")
            return
        }
        
        world.addChild(avatar)
    }
}
