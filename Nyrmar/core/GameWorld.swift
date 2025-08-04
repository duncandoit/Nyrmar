//
//  GameWorld.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit
import GameplayKit

class GameWorld: SKScene
{
    private var m_LastUpdateTime : TimeInterval = 0
    private var m_LocalPlayerControllerEntity: Entity!
    private let m_LocalPlayerControllerID = UUID()
    private var m_AvatarEntity: Entity!
    
    override func sceneDidLoad()
    {
        m_LastUpdateTime = 0
        EntityManager.shared.initializeScene(self)
        
        registerLocalPlayer()
        registerControlledAvatar()
        
        print(#function)
    }
    
    func registerLocalPlayer()
    {
        m_LocalPlayerControllerEntity = EntityManager.shared.addEntity()
        
        let inputComp = GameInputComponent()
        EntityManager.shared.addComponent(inputComp, to: m_LocalPlayerControllerEntity)

        let timestamp = TimeComponent(interval: CACurrentMediaTime())
        EntityManager.shared.addComponent(timestamp, to: m_LocalPlayerControllerEntity)
    }

    func registerControlledAvatar()
    {
        m_AvatarEntity = EntityManager.shared.addEntity()
        
        let avatar = AvatarManager.shared.createAvatar(atTransform: TransformComponent(), with: m_AvatarEntity)
        guard let avatar = avatar else
        {
            print(#function + ": avatar wasn't created.")
            return
        }
        
        let controlledByComp = ControlledByComponent(controllerID: m_LocalPlayerControllerID)
        EntityManager.shared.addComponent(controlledByComp, to: m_AvatarEntity)
        
//        addChild(avatar)
    }
    
    func getLocalPlayerID() -> UUID
    {
        return m_LocalPlayerControllerID
    }
    
    func getControlledAvatarEntity() -> Entity
    {
        return m_AvatarEntity
    }
    
    func touchDown(atPoint pos : CGPoint)
    {
        // Send to input manager
        GameInputManager.shared.addComponentsForEntity(entity: m_AvatarEntity, forInput: .touchDown, atPoint: pos)
    }
    
    func touchMoved(toPoint pos : CGPoint)
    {
        // Send to input manager
        GameInputManager.shared.addComponentsForEntity(entity: m_AvatarEntity, forInput: .touchMoved, atPoint: pos)
    }
    
    func touchUp(atPoint pos : CGPoint)
    {
        // Send to input manager
        GameInputManager.shared.addComponentsForEntity(entity: m_AvatarEntity, forInput: .touchUp, atPoint: pos)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func update(_ currentTime: TimeInterval)
    {
        if (m_LastUpdateTime == 0)
        {
            m_LastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - m_LastUpdateTime
        EntityManager.shared.tick(deltaTime: dt)
        m_LastUpdateTime = currentTime
    }
}
