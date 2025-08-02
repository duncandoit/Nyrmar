//
//  Avatar.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit

class Avatar: SKSpriteNode
{
    let owningEntity: Entity
        
    init(
        textureName: String,
        owningEntity: Entity,
        size: CGSize? = nil,
        position: CGPoint = .zero,
        zPosition: CGFloat = 0
    ){
        self.owningEntity = owningEntity
        let texture = SKTexture(imageNamed: textureName)
        let entitySize = size ?? texture.size()
        super.init(texture: texture, color: .clear, size: entitySize)
        self.position = position
        self.zPosition = zPosition
        configurePhysics()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.owningEntity = Entity()
        super.init(coder: aDecoder)
    }
    
    private func configurePhysics()
    {
        self.physicsBody = SKPhysicsBody(texture: self.texture!, size: self.size)
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
    }
}
