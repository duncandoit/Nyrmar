//
//  AvatarSyncSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/1/25.
//

import Foundation

class AvatarSyncSystem: System
{
    let requiredComponent: ComponentTypeID = AvatarComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
    {
        let avatarComp = component as! AvatarComponent
        guard let transformComp = avatarComp.sibling(TransformComponent.self) else
        {
            print("[" + #fileID + "]: " + #function, "Could not find TransformComponent for AvatarComponent")
            return
        }
        
        guard let avatar = avatarComp.avatar else
        {
            print("[" + #fileID + "]: " + #function, "Could not find Avatar reference in AvatarComponent")
            return
        }
        
        avatar.position = transformComp.position
        avatar.zPosition = transformComp.zPosition
    }
}
