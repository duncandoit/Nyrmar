//
//  AvatarUpdateSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

//import Foundation
//
//class AvatarUpdateSystem: System
//{
//    let requiredComponent: ComponentTypeID = AvatarComponent.typeID
//
//    func update(deltaTime: TimeInterval, component: any Component, world: GameWorld)
//    {
//        // Spawn new avatars
//        let avatarComp = component as! AvatarComponent
//        if avatarComp.wantsToSpawn
//        {
//            let transformComp = TransformComponent()
//            EntityAdmin.shared.addComponent(transformComp, to: avatarComp.owningEntity)
//            
//            let avatar = Avatar(
//                textureName: "defaultTexture",
//                owningEntity: avatarComp.owningEntity,
//                position: transformComp.position,
//                zPosition: transformComp.zPosition
//            )
//            
//            EntityAdmin.shared.addAvatar(avatar, with: avatarComp.owningEntity)
//            
//            avatarComp.wantsToSpawn = false
//        }
//
//        // Despawn avatars
//        if avatarComp.wantsToBeDestroyed
//        {
//            EntityAdmin.shared.removeAvatar(with: avatarComp.owningEntity)
//            EntityAdmin.shared.removeEntity(avatarComp.owningEntity)
//            
//            return
//        }
//        
//        // Update transform
//        guard let avatar = EntityAdmin.shared.getAvatar(with: avatarComp.owningEntity) else
//        {
//            print(#function + ": Missing Avatar for Entity: \(avatarComp.owningEntity).")
//            return
//        }
//        
//        guard let transformComp = component.sibling(TransformComponent.self) else
//        {
//            print(#function + ": Missing TransformComponent for Entity: \(avatarComp.owningEntity).")
//            return
//        }
//        
//        avatar.position = transformComp.position
//        avatar.zPosition = transformComp.zPosition
//    }
//}
