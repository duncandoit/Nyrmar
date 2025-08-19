//
//  CollisionComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation

enum CollisionShape
{
    case aabb(CGSize), circle(CGFloat)
}

final class CollisionComponent: Component
{
    static let typeID = componentTypeID(for: CollisionComponent.self)
    var siblings: SiblingContainer?
    
    var shape: CollisionShape
    var isStatic: Bool = false
    var categoryBits: UInt32 = 0x1
    var maskBits: UInt32 = 0xFFFF_FFFF
    var isTrigger: Bool = false
    
    init(shape: CollisionShape)
    {
        self.shape = shape
    }
}
