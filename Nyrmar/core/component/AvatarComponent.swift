//
//  SKNodeRenderComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit

//class AvatarComponent: Component
//{
//    static let typeID: ComponentTypeID = componentTypeID(for: AvatarComponent.self)
//    var siblings: [ComponentTypeID : WeakComponentRef]?
//    
//    var wantsToSpawn: Bool = false
//    var wantsToBeDestroyed: Bool = false
//    var owningEntity: Entity
//    
//    init(entity: Entity)
//    {
//        owningEntity = entity
//    }
//}

/// Component linking an entity to its SKNode
class AvatarComponent: Component
{
    static let typeID: ComponentTypeID = componentTypeID(for: AvatarComponent.self)
    var siblings: [ComponentTypeID: WeakComponentRef]?
    
    weak var avatar: Avatar?
    var owningEntity: Entity
    var wantsToSpawn = false
    var wantsToBeDestroyed = false

    init(avatar: Avatar, owningEntity: Entity)
    {
        self.avatar = avatar
        self.owningEntity = owningEntity
    }
}
