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
    private var lastUpdateTime : TimeInterval = 0
    
    override func sceneDidLoad()
    {
        lastUpdateTime = 0
        EntityManager.shared.initializeScene(self)
    }
    
    func touchDown(atPoint pos : CGPoint)
    {
        // Send to input manager
        GameInputManager.shared.addComponentsForEntity(entity: <#T##Entity#>, forInput: <#T##GameInput#>, atPoint: <#T##CGPoint#>)(.touchDown, atPoint: pos)
    }
    
    func touchMoved(toPoint pos : CGPoint)
    {
        // Send to input manager
    }
    
    func touchUp(atPoint pos : CGPoint)
    {
        // Send to input manager
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
        if (lastUpdateTime == 0)
        {
            lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - lastUpdateTime
        EntityManager.shared.tick(deltaTime: dt)
        lastUpdateTime = currentTime
    }
}
