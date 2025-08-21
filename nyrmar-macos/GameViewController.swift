//
//  GameViewController.swift
//  Nyrmar macOS
//
//  Created by Zachary Duncan on 8/19/25.
//

import Cocoa
import MetalKit

class GameViewController: NSViewController
{
    private let m_MetalLayer = CAMetalLayer()
    private var m_Engine: EngineLoop!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        m_Engine = EngineLoop(view: view)
        
        m_MetalLayer.isGeometryFlipped = false
        m_MetalLayer.pixelFormat = MTLPixelFormat.bgra8Unorm
        m_MetalLayer.contentsScale = NSScreen.main!.backingScaleFactor   // view.window is nil here
        m_MetalLayer.frame = view.layer!.bounds
        view.layer!.addSublayer(m_MetalLayer)

        // Ensure the viewport entity (singleton surface + camera)
        m_Engine.admin().initializeMetalViewport(layer: m_MetalLayer, pixelsPerUnit: 100)
        
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { [weak self] event in
            guard let self = self else
            {
                return event
            }
            
            if event.isARepeat
            {
                // Let event pass through
                return nil
            }
            
            if self.handleKey(event)
            {
                // Consume event
                return nil
            }
            
            return event
        }
        
        let bindingsComp = m_Engine.admin().playerBindingsComponent()
        bindingsComp.pointer.append(contentsOf: [
            PointerMapping(intent: .moveToLocation, phases: [.down])
        ])
        bindingsComp.digital.append(contentsOf: [
            DigitalMapping(intent: .jump, inputs: [.space], policy: .onDown),
        ])
        bindingsComp.digitalAxis2D.append(contentsOf: [
            DigitalAxis2DMapping(
                intent: .cameraMove,
                left:   [.custom("a")],
                right:  [.custom("d")],
                down:   [.custom("s")],
                up:     [.custom("w")],
            )
        ])
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
    
    @discardableResult
    private func handleKey(_ event: NSEvent) -> Bool
    {
        let inputComp = m_Engine.admin().inputComponent()
        let isDown = (event.type == .keyDown)
        var input: GenericInput?

        if let specialKey = event.specialKey
        {
            switch specialKey
            {
            case .leftArrow:
                
                input = .leftArrow
                
            case .rightArrow:
                
                input = .rightArrow
                
            case .upArrow:
                
                input = .upArrow
                
            case .downArrow:
                
                input = .downArrow
                
            default: break
            }
            
            if let input = input
            {
                inputComp.digitalEdges.append(DigitalEdge(input: input, isDown: isDown))
                return true
            }
        }
        
        if let keys = event.charactersIgnoringModifiers
        {
            for key in keys
            {
                input = (key == " ") ? .space : .custom(key.lowercased())
                inputComp.digitalEdges.append(DigitalEdge(input: input!, isDown: isDown))
            }
            
            return true
        }
        
        return false
    }
    
    private func handleMouseEvent(at screenSpacePoint: CGPoint, phase: PointerPhase)
    {
        let viewSpacePoint = view.convert(screenSpacePoint, from: nil)
        let pointerData = PointerData(
            id:             1,
            type:           .touch,
            phase:          phase,
            screenLocation: viewSpacePoint
        )
        
        m_Engine.admin().inputComponent().pointerEvents.append(pointerData)
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        handleMouseEvent(at: event.locationInWindow, phase: .down)
    }
    
    override func mouseUp(with event: NSEvent)
    {
        super.mouseUp(with: event)
        handleMouseEvent(at: event.locationInWindow, phase: .up)
    }
    
    override func mouseDragged(with event: NSEvent)
    {
        super.mouseDragged(with: event)
        handleMouseEvent(at: event.locationInWindow, phase: .dragged)
    }
    
    override func mouseMoved(with event: NSEvent)
    {
        super.mouseMoved(with: event)
        handleMouseEvent(at: event.locationInWindow, phase: .hover)
    }
    
    override func mouseExited(with event: NSEvent)
    {
        super.mouseExited(with: event)
        handleMouseEvent(at: event.locationInWindow, phase: .down)
    }
    
    override func mouseEntered(with event: NSEvent)
    {
        super.mouseEntered(with: event)
        handleMouseEvent(at: event.locationInWindow, phase: .hover)
    }
}
