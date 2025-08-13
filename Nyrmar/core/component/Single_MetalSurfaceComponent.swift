//
//  Single_MetalSurfaceComponent.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import QuartzCore

final class Single_MetalSurfaceComponent: Component
{
    static let typeID = componentTypeID(for: Single_MetalSurfaceComponent.self)
    var siblings: SiblingContainer?
    
    weak var layer: CAMetalLayer?
    var device: MTLDevice?
    var queue: MTLCommandQueue?
    var library: MTLLibrary?
    var pipeline: MTLRenderPipelineState?
    var vbuf: MTLBuffer?
    
    init(layer: CAMetalLayer?)
    {
        self.layer = layer
    }
}
