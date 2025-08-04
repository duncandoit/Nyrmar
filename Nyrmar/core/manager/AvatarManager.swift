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
    
    private var m_Avatars: [Entity: Avatar] = [:]
    
    private init() {}
    
    func createAvatar(atTransform transformComp: TransformComponent, with owningEntity: Entity = Entity(), controlledBy controllerID: UUID? = nil) -> Avatar?
    {
        guard m_Avatars[owningEntity] == nil else
        {
            print("[" + #fileID + "]: " + #function + " -> Avatar already exists for Entity: \(owningEntity).")
            return nil
        }
        let avatar = Avatar(
            textureName: "finalfall-logo",
            owningEntity: owningEntity,
            size: CGSize(width: 10, height: 10),
            position: transformComp.position,
            zPosition: transformComp.zPosition
        )
        
        m_Avatars[owningEntity] = avatar
        print("[" + #fileID + "]: " + #function + " -> Spawned Avatar for Entity: \(owningEntity).")
        return avatar
    }
    
    func addAvatar(_ avatar: Avatar)
    {
        m_Avatars[avatar.owningEntity] = avatar
    }
    
    func avatar(for entity: Entity) -> Avatar?
    {
        return m_Avatars[entity]
    }
    
    func allAvatars() -> [Avatar]
    {
        return Array(m_Avatars.values)
    }
    
    func removeAll()
    {
        m_Avatars.removeAll()
    }
}
