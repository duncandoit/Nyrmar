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
    
    override func sceneDidLoad()
    {
        super.sceneDidLoad()
        print("[" + #fileID + "]: " + #function)
        
        m_LastUpdateTime = 0
        
        registerEntityAdmin()
    }
    
    func registerEntityAdmin()
    {
        EntityAdmin.shared.initializeScene(self)
    }
    
    func touchDown(atPoint pos : CGPoint)
    {
        // Send to input manager
        GameInputManager.shared.addComponentsForEntity(entity: EntityAdmin.shared.getControlledAvatarEntity(), forInput: .touchDown, atPoint: pos)
    }
    
    func touchMoved(toPoint pos : CGPoint)
    {
        // Send to input manager
        GameInputManager.shared.addComponentsForEntity(entity: EntityAdmin.shared.getControlledAvatarEntity(), forInput: .touchMoved, atPoint: pos)
    }
    
    func touchUp(atPoint pos : CGPoint)
    {
        // Send to input manager
        GameInputManager.shared.addComponentsForEntity(entity: EntityAdmin.shared.getControlledAvatarEntity(), forInput: .touchUp, atPoint: pos)
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
        EntityAdmin.shared.tick(deltaTime: dt)
        m_LastUpdateTime = currentTime
    }
}
