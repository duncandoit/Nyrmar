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
    
    func touch(at worldSpacePoint: CGPoint, phase: PointerPhase)
    {
        let pointerData = PointerData(
            id:             1,
            type:           .touch,
            phase:          phase,
            worldLocation:  worldSpacePoint
        )
        
        EntityAdmin.shared.getInputComponent().pointerEvents.append(pointerData)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { touch(at: t.location(in: self), phase: .down) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { touch(at: t.location(in: self), phase: .dragged) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { touch(at: t.location(in: self), phase: .up) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for t in touches { touch(at: t.location(in: self), phase: .up) }
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
