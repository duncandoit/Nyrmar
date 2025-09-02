//
//  EngineLoop.swift
//  Korin
//
//  Created by Zachary Duncan on 8/13/25.
//

#if os(iOS) || os(tvOS)
import QuartzCore

final class EngineLoop
{
    private let m_Admin = EntityAdmin()
    private var m_DisplayLink: CADisplayLink?
    private var m_LastTime: CFTimeInterval = 0
    
    private(set) var isRunning = false
    
    func admin() -> EntityAdmin
    {
        return m_Admin
    }

    func start()
    {
        guard !isRunning else
        {
            return
        }
        m_LastTime = 0
        let displayLink = CADisplayLink(target: self, selector: #selector(step(_:)))
        
        // Prefer .common to keep ticking during UI interactions
        displayLink.add(to: .main, forMode: .common)
        m_DisplayLink = displayLink
        isRunning = true
    }

    func stop()
    {
        guard isRunning else
        {
            return
        }
        m_DisplayLink?.invalidate()
        m_DisplayLink = nil
        isRunning = false
    }

    @objc private func step(_ displayLink: CADisplayLink)
    {
        if m_LastTime == 0
        {
            m_LastTime = displayLink.timestamp
        }
        let deltaTime = displayLink.timestamp - m_LastTime
        m_LastTime = displayLink.timestamp

        m_Admin.fixedUpdate(rawDeltaTime: deltaTime)
    }
}
#endif

#if os(macOS)
import AppKit

final class EngineLoop
{
    private let m_Admin = EntityAdmin()
    private var m_DisplayLink: CADisplayLink?
    private var m_LastTime: CFTimeInterval = 0
    private let m_View: NSView
    
    private(set) var isRunning = false

    init(view: NSView)
    {
        m_View = view
    }
    
    func admin() -> EntityAdmin
    {
        return m_Admin
    }

    func start()
    {
        guard !isRunning else
        {
            return
        }
        m_LastTime = 0
        let displayLink = m_View.displayLink(target: self, selector: #selector(step(_:)))
        
        // Prefer .common to keep ticking during UI interactions
        displayLink.add(to: .main, forMode: .common)
        m_DisplayLink = displayLink
        isRunning = true
    }

    func stop()
    {
        guard isRunning else
        {
            return
        }
        m_DisplayLink?.invalidate()
        m_DisplayLink = nil
        isRunning = false
    }

    @objc private func step(_ displayLink: CADisplayLink)
    {
        if m_LastTime == 0
        {
            m_LastTime = displayLink.timestamp
        }
        let deltaTime = displayLink.timestamp - m_LastTime
        m_LastTime = displayLink.timestamp

        m_Admin.fixedUpdate(rawDeltaTime: deltaTime)
    }
}

//final class EnglineLoopOld
//{
//    static let shared = EnglineLoopOld()
//    
//    private let m_Admin = EntityAdmin()
//    private var m_DisplayLink: CVDisplayLink?
//    private var m_LastTime: CFTimeInterval = 0
//    private(set) var isRunning = false
//
//    private init()
//    {
//        var visitorDisplayLink: CVDisplayLink?
//        CVDisplayLinkCreateWithActiveCGDisplays(&visitorDisplayLink)
//        m_DisplayLink = visitorDisplayLink
//        
//        if let displayLink = m_DisplayLink
//        {
//            CVDisplayLinkSetOutputCallback(
//                displayLink,
//                
//                { (_, now, _, _, _, ctx) -> CVReturn in
//                    let me = Unmanaged<DisplayProxy>.fromOpaque(ctx!).takeUnretainedValue()
//                    let ts = now.pointee.videoTime != 0
//                        ? CFTimeInterval(now.pointee.videoTime) / CFTimeInterval(now.pointee.videoTimeScale)
//                        : CFTimeInterval(CFAbsoluteTimeGetCurrent())
//                    me.frame(ts: ts)
//                    return kCVReturnSuccess
//                },
//                
//                Unmanaged.passUnretained(self).toOpaque()
//            )
//        }
//    }
//
//    func start()
//    {
//        guard !isRunning, let displayLink = m_DisplayLink else
//        {
//            return
//        }
//        m_LastTime = 0
//        CVDisplayLinkStart(displayLink)
//        isRunning = true
//    }
//
//    func stop()
//    {
//        guard isRunning, let displayLink = m_DisplayLink else
//        {
//            return
//        }
//        CVDisplayLinkStop(displayLink)
//        isRunning = false
//    }
//
//    private func frame(timeStep: CFTimeInterval)
//    {
//        if m_LastTime == 0
//        {
//            m_LastTime = timeStep
//        }
//        let deltaTime = timeStep - m_LastTime
//        m_LastTime = timeStep
//        
//        // If rendering touches UI state, hop to main.
//        DispatchQueue.main.async
//        {
//            m_Admin.fixedUpdate(rawDeltaTime: deltaTime)
//        }
//    }
//}
#endif

