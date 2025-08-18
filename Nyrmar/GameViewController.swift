//
//  GameViewController.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 7/31/25.
//

import MetalKit

class GameViewController: UIViewController
{
    private let metalLayer = CAMetalLayer()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.layer.isGeometryFlipped = true

        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.contentsScale = UIScreen.main.scale   // view.window is nil here
        metalLayer.frame = view.layer.bounds
        view.layer.addSublayer(metalLayer)

        // Ensure the viewport entity (singleton surface + camera)
        EngineLoop.shared.admin().initializeMetalViewport(layer: metalLayer, pixelsPerUnit: 100)
    }

    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        metalLayer.frame = view.layer.bounds
        metalLayer.contentsScale = UIScreen.main.scale
        metalLayer.drawableSize = CGSize(width: metalLayer.bounds.width * metalLayer.contentsScale,
                                         height: metalLayer.bounds.height * metalLayer.contentsScale)
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        EngineLoop.shared.start()
    }

    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        EngineLoop.shared.stop()
    }
    
    func touch(at screenSpacePoint: CGPoint, phase: PointerPhase)
    {
        let pointerData = PointerData(
            id:             1,
            type:           .touch,
            phase:          phase,
            screenLocation:  screenSpacePoint
        )
        
        EngineLoop.shared.admin().inputComponent().pointerEvents.append(pointerData)
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
