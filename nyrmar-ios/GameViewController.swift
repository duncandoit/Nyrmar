//
//  GameViewController.swift
//  Nyrmar iOS
//
//  Created by Zachary Duncan on 8/19/25.
//

import UIKit
import MetalKit

class GameViewController: UIViewController
{
    private let m_Engine = EngineLoop()
    private let m_MetalLayer = CAMetalLayer()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.layer.isGeometryFlipped = true

        m_MetalLayer.pixelFormat = .bgra8Unorm
        m_MetalLayer.contentsScale = UIScreen.main.scale   // view.window is nil here
        m_MetalLayer.frame = view.layer.bounds
        view.layer.addSublayer(m_MetalLayer)

        // Ensure the viewport entity (singleton surface + camera)
        m_Engine.admin().initializeMetalViewport(layer: m_MetalLayer, pixelsPerUnit: 100)
        
        let bindingsComp = m_Engine.admin().playerBindingsComponent()
        bindingsComp.pointer.append(contentsOf: [
            PointerMapping(intent: .moveToLocation, phases: [.up]),
            //PointerMapping(intent: .jump, phases: [.down]),
            PointerMapping(intent: .cameraMove, phases: [.dragged])
        ])
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        m_MetalLayer.frame = view.layer.bounds
        m_MetalLayer.contentsScale = UIScreen.main.scale
        m_MetalLayer.drawableSize = CGSize(
            width: m_MetalLayer.bounds.width * m_MetalLayer.contentsScale,
            height: m_MetalLayer.bounds.height * m_MetalLayer.contentsScale
        )
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        m_Engine.start()
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        m_Engine.stop()
    }
    
    func touch(at screenSpacePoint: CGPoint, phase: PointerPhase)
    {
        let pointerData = PointerData(
            id:             1,
            type:           .touch,
            phase:          phase,
            screenLocation: screenSpacePoint
        )
        
        m_Engine.admin().inputComponent().pointerEvents.append(pointerData)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let t = touches.first { touch(at: t.location(in: view), phase: .down) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let t = touches.first { touch(at: t.location(in: view), phase: .dragged) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let t = touches.first { touch(at: t.location(in: view), phase: .up) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let t = touches.first { touch(at: t.location(in: view), phase: .up) }
    }
}
