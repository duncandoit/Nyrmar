//
//  GameViewController.swift
//  Nyrmar tvOS
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

        m_MetalLayer.isGeometryFlipped = false
        m_MetalLayer.pixelFormat = .bgra8Unorm
        m_MetalLayer.contentsScale = UIScreen.main.scale   // view.window is nil here
        m_MetalLayer.frame = view.layer.bounds
        view.layer.addSublayer(m_MetalLayer)

        // Ensure the viewport entity (singleton surface + camera)
        m_Engine.admin().makeMetalViewport(layer: m_MetalLayer, pixelsPerUnit: 100)
        
        let bindingsComp = m_Engine.admin().singleton(Single_PlayerBindingsComponent.self)
        bindingsComp.pointer.append(contentsOf: [

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
}
