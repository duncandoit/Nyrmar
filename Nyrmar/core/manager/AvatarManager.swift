//
//  AvatarManager.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/3/25.
//

import Foundation

class AvatarManager
{
    static let shared = AvatarManager()
    private init() {}
    
    // TODO: Move avatar collection here for finer tracking
    private var m_Avatars: [Entity: Avatar] = [:]
    
    // TODO: Add the createAvatar() here rather than EntityManager for better division of responsibility
    func createAvatar(_ avatar: AvatarComponent, atTransform transformComp: TransformComponent, with owningEntity: Entity = Entity()) -> Avatar?
    {
        guard m_Avatars[owningEntity] == nil else
        {
            print(#function + ": Avatar already exists for Entity: \(owningEntity).")
            return nil
        }
        let avatar = Avatar(
            textureName: "Avatar",
            owningEntity: owningEntity,
            size: CGSize(width: 10, height: 10),
            position: transformComp.position,
            zPosition: transformComp.zPosition
        )
        
        m_Avatars[owningEntity] = avatar
        print(#function + ": Spawned Avatar for Entity: \(owningEntity).")
    }
    
    func avatar(for entity: Entity) -> Avatar?
    {
        return m_Avatars[entity]
    }
}
