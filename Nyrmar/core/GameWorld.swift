//
//  GameWorld.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import SpriteKit
import GameplayKit
import MetalKit

class GameWorld: SKScene
{
    private var m_LastUpdateTime : TimeInterval = 0
    
    override func sceneDidLoad()
    {
        super.sceneDidLoad()
        print("[" + #fileID + "]: " + #function)
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

class DummyViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view = DummyView()
        
        view.layer.isGeometryFlipped = true
        let metalLayer = CAMetalLayer()
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.contentsScale = view.window?.screen.scale ?? UIScreen.main.scale
        metalLayer.frame = view.layer.bounds
        view.layer.addSublayer(metalLayer)

        EntityAdmin.shared.initializeMetalViewport(layer: metalLayer, pixelsPerUnit: 100)
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        let layer = EntityAdmin.shared.getMetalSurfaceComponent().layer!
        layer.frame = view.layer.bounds
        layer.contentsScale = view.window?.screen.scale ?? UIScreen.main.scale
        layer.drawableSize = CGSize(width: layer.bounds.width * layer.contentsScale,
                                    height: layer.bounds.height * layer.contentsScale)
    }
}

class DummyView: UIView
{
    var lastUpdateTime: CFTimeInterval = 0
    
    override func draw(_ rect: CGRect) {
        let now = CACurrentMediaTime()
        let deltaTime: CFTimeInterval = now - lastUpdateTime
        lastUpdateTime = now
        EntityAdmin.shared.tick(deltaTime: deltaTime)
    }
}
