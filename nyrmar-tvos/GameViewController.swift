//
//  GameViewController.swift
//  Nyrmar tvOS
//
//  Created by Zachary Duncan on 8/19/25.
//

import UIKit
import MetalKit

// Our tvOS specific view controller
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
}
