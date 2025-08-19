//
//  GameViewController.swift
//  Nyrmar macOS
//
//  Created by Zachary Duncan on 8/19/25.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController
{
    private let m_MetalLayer = CAMetalLayer()
    private var m_Engine: EngineLoop!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        m_Engine = EngineLoop(view: view)
            
        m_MetalLayer.isGeometryFlipped = true

        m_MetalLayer.pixelFormat = MTLPixelFormat.bgra8Unorm
        m_MetalLayer.contentsScale = NSScreen.main!.backingScaleFactor   // view.window is nil here
        m_MetalLayer.frame = view.layer!.bounds
        view.layer!.addSublayer(m_MetalLayer)

        // Ensure the viewport entity (singleton surface + camera)
        m_Engine.admin().initializeMetalViewport(layer: m_MetalLayer, pixelsPerUnit: 100)
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            if self.onKeyDown(with: $0)
            {
                return nil
            }
            else
            {
                return $0
            }
        }
    }
    
    override func viewDidLayout()
    {
        super.viewDidLayout()
        
        m_MetalLayer.frame = view.layer!.bounds
        m_MetalLayer.contentsScale = NSScreen.main!.backingScaleFactor
        m_MetalLayer.drawableSize = CGSize(
            width: m_MetalLayer.bounds.width * m_MetalLayer.contentsScale,
            height: m_MetalLayer.bounds.height * m_MetalLayer.contentsScale
        )
    }
    
    override func viewDidAppear()
    {
        super.viewDidAppear()
        
        m_Engine.start()
    }
    
    override func viewWillDisappear()
    {
        super.viewWillDisappear()
        
        m_Engine.stop()
    }
    
    override var acceptsFirstResponder: Bool
    {
        return true
    }
    
    func onKeyDown(with event: NSEvent) -> Bool
    {
        let inputComp = m_Engine.admin().inputComponent()

        if let specialKey = event.specialKey
        {
            
            switch specialKey
            {
            case .leftArrow:
                
                inputComp.digitalEdges.append(
                    DigitalEdge(input: .leftArrow, isDown: true, t: event.timestamp)
                )
                
            case .rightArrow:
                
                inputComp.digitalEdges.append(
                    DigitalEdge(input: .rightArrow, isDown: true, t: event.timestamp)
                )
                
            case .upArrow:
                
                inputComp.digitalEdges.append(
                    DigitalEdge(input: .upArrow, isDown: true, t: event.timestamp)
                )
                
            case .downArrow:
                
                inputComp.digitalEdges.append(
                    DigitalEdge(input: .downArrow, isDown: true, t: event.timestamp)
                )
                
            default:
                
                break
            }
        }
        
        if let keys = event.charactersIgnoringModifiers
        {
            for key in keys
            {
                inputComp.digitalEdges.append(
                    DigitalEdge(input: .custom(String(key)), isDown: true, t: event.timestamp)
                )
            }
        }
        
        return true
    }
    
    private func onMouseEvent(at screenSpacePoint: CGPoint, phase: PointerPhase)
    {
        let pointerData = PointerData(
            id:             1,
            type:           .touch,
            phase:          phase,
            screenLocation: screenSpacePoint
        )
        
        m_Engine.admin().inputComponent().pointerEvents.append(pointerData)
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        onMouseEvent(at: event.locationInWindow, phase: .down)
    }
    
    override func mouseUp(with event: NSEvent)
    {
        super.mouseUp(with: event)
        onMouseEvent(at: event.locationInWindow, phase: .up)
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        super.mouseDragged(with: event)
        onMouseEvent(at: event.locationInWindow, phase: .dragged)
    }
    
    override func mouseMoved(with event: NSEvent)
    {
        super.mouseMoved(with: event)
        onMouseEvent(at: event.locationInWindow, phase: .hover)
    }
    
    override func mouseExited(with event: NSEvent)
    {
        super.mouseExited(with: event)
        onMouseEvent(at: event.locationInWindow, phase: .down)
    }
    
    override func mouseEntered(with event: NSEvent)
    {
        super.mouseEntered(with: event)
        onMouseEvent(at: event.locationInWindow, phase: .hover)
    }
}
