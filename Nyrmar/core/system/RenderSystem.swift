//
//  RenderSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import MetalKit
import simd

struct SpriteVertex
{
    var position: simd_float2; var uv: simd_float2; var color: simd_float4
}

struct TextureBatch
{
    let texture: any MTLTexture
    var verts: [SpriteVertex] = []
}

/// Batches all sprites by texture and renders them into the singleton Metal surfaceComp component.
/// All GPU objects live on `Single_MetalSurfaceComponent`.
final class RenderSystem: System
{
    let requiredComponent: ComponentTypeID = Single_MetalSurfaceComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component)
    {
        let surfaceComp = component as! Single_MetalSurfaceComponent
        guard let layer = surfaceComp.layer,
              let device = surfaceComp.device,
              let queue  = surfaceComp.queue,
              let drawable = layer.nextDrawable()
        else
        {
            return
        }
        
        // Lazily create shader library / pipeline but don't bail on rendering if it's not ready yet.
        if surfaceComp.library == nil
        {
            surfaceComp.library = try? device.makeDefaultLibrary(bundle: .main)
        }
        if surfaceComp.pipeline == nil, let lib = surfaceComp.library
        {
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction   = lib.makeFunction(name: "vs_sprite2D")
            desc.fragmentFunction = lib.makeFunction(name: "fs_sprite2D")
            desc.colorAttachments[0].pixelFormat = layer.pixelFormat
            
            // Alpha blending for sprites
            let colorAttachments = desc.colorAttachments[0]
            colorAttachments?.isBlendingEnabled = true
            colorAttachments?.rgbBlendOperation = .add
            colorAttachments?.alphaBlendOperation = .add
            colorAttachments?.sourceRGBBlendFactor = .sourceAlpha
            colorAttachments?.destinationRGBBlendFactor = .oneMinusSourceAlpha
            colorAttachments?.sourceAlphaBlendFactor = .sourceAlpha
            colorAttachments?.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
            surfaceComp.pipeline = try? device.makeRenderPipelineState(descriptor: desc)
        }
        
        // Keep drawable size in sync with the view.
        let scale = layer.contentsScale
        let bounds = layer.bounds.size
        layer.drawableSize = .init(width: bounds.width*scale, height: bounds.height*scale)
        let viewportPixelSize = simd_float2(Float(layer.drawableSize.width), Float(layer.drawableSize.height))
        
        // camera
        let cameraComp = EntityAdmin.shared.camera2DComponent()
        let pixelsPerUnit = Float(cameraComp.pixelsPerUnit)
        let cameraCenterWorld = simd_float2(Float(cameraComp.center.x), Float(cameraComp.center.y))
        let worldHalfExtents = simd_float2(viewportPixelSize.x/pixelsPerUnit/2, viewportPixelSize.y/pixelsPerUnit/2)
        let invWorldHalfExtents = SIMD2<Float>(1.0 / worldHalfExtents.x, 1.0 / worldHalfExtents.y)
        
        // Build render pass
        // Always clear + present even if we have to wait for the pipeline to be ready to draw.
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction  = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor  = surfaceComp.clearColor
        
        guard let commandBuffer = queue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)
        else
        {
            return
        }
        
        if let pipeline = surfaceComp.pipeline
        {
            commandEncoder.setRenderPipelineState(pipeline)
            
            // Gather renderable sprites (skip if none).
            let renderComps: [SpriteRenderComponent] = EntityAdmin.shared.getComponents(ofType: SpriteRenderComponent.self) ?? []
            if !renderComps.isEmpty
            {
                // Batch by texture identity
                var batches: [ObjectIdentifier: TextureBatch] = [:]
                batches.reserveCapacity(16) // small, grows geometrically as needed
                
                // Inline, branchless NDC helper (flip Y once).
                @inline(__always)
                func toNDC(_ p: SIMD2<Float>) -> SIMD2<Float>
                {
                    let n = p * invWorldHalfExtents
                    return SIMD2<Float>(n.x, -n.y)
                }
                
                for renderComp in renderComps where !renderComp.hidden
                {
                    guard let transformComp: TransformComponent = renderComp.sibling(TransformComponent.self),
                          let texture = renderComp.texture
                    else
                    {
                        continue
                    }
                    
                    let key = ObjectIdentifier(texture as AnyObject)
                    if batches[key] == nil
                    {
                        batches[key] = TextureBatch(texture: texture)
                    }

                    // size and center in camera space
                    let componentWidth  = Float(renderComp.size.width  * transformComp.scale.width)
                    let componentHeight = Float(renderComp.size.height * transformComp.scale.height)
                    let componentHalf   = SIMD2<Float>(componentWidth * 0.5, componentHeight * 0.5)

                    let worldCenter    = SIMD2<Float>(Float(transformComp.position.x), Float(transformComp.position.y))
                    let cameraSpaceCenter = worldCenter - cameraCenterWorld

                    // rotation matrix about center in radians
                    let angle = Float(transformComp.zRotation)
                    let cosA  = cos(angle)
                    let sinA  = sin(angle)
                    let r00 = cosA,  r01 = -sinA
                    let r10 = sinA,  r11 =  cosA

                    // local corners (centered)
                    let pBL = SIMD2<Float>(-componentHalf.x, -componentHalf.y)
                    let pBR = SIMD2<Float>( componentHalf.x, -componentHalf.y)
                    let pTR = SIMD2<Float>( componentHalf.x,  componentHalf.y)
                    let pTL = SIMD2<Float>(-componentHalf.x,  componentHalf.y)

                    // rotate then translate to camera space (no nested funcs)
                    let bl = SIMD2<Float>(r00 * pBL.x + r01 * pBL.y, r10 * pBL.x + r11 * pBL.y) + cameraSpaceCenter
                    let br = SIMD2<Float>(r00 * pBR.x + r01 * pBR.y, r10 * pBR.x + r11 * pBR.y) + cameraSpaceCenter
                    let tr = SIMD2<Float>(r00 * pTR.x + r01 * pTR.y, r10 * pTR.x + r11 * pTR.y) + cameraSpaceCenter
                    let tl = SIMD2<Float>(r00 * pTL.x + r01 * pTL.y, r10 * pTL.x + r11 * pTL.y) + cameraSpaceCenter

                    // UVs + color
                    let uv = renderComp.uv
                    let u0 = uv.x, v0 = uv.y, u1 = uv.z, v1 = uv.w
                    let color = renderComp.tint

                    // toNDC(_:) should take SIMD2<Float> and flip Y once
                    let v0s = SpriteVertex(position: toNDC(bl), uv: SIMD2<Float>(u0, v0), color: color)
                    let v1s = SpriteVertex(position: toNDC(br), uv: SIMD2<Float>(u1, v0), color: color)
                    let v2s = SpriteVertex(position: toNDC(tr), uv: SIMD2<Float>(u1, v1), color: color)
                    let v3s = SpriteVertex(position: toNDC(tl), uv: SIMD2<Float>(u0, v1), color: color)

                    // CCW triangles
                    batches[key]!.verts.append(contentsOf: [v0s, v1s, v2s, v0s, v2s, v3s])
                }

                // Encode draws (one draw per texture).
                for batch in batches.values where !batch.verts.isEmpty
                {
                    let verts = batch.verts
                    let byteCount = verts.count * MemoryLayout<SpriteVertex>.stride
                    
                    // Grow the shared dynamic buffer geometrically to reduce reallocations.
                    if surfaceComp.vbuf == nil || surfaceComp.vbuf!.length < byteCount
                    {
                        let old = surfaceComp.vbuf?.length ?? 0
                        let newLen = max(byteCount, max(64 * 1024, old * 2))
                        surfaceComp.vbuf = device.makeBuffer(length: newLen, options: .storageModeShared)
                    }
                    
                    verts.withUnsafeBytes { raw in
                        guard let src = raw.baseAddress else
                        {
                            return
                        }
                        memcpy(surfaceComp.vbuf!.contents(), src, byteCount)
                    }
                    
                    commandEncoder.setVertexBuffer(surfaceComp.vbuf, offset: 0, index: 0)
                    commandEncoder.setFragmentTexture(batch.texture, index: 0)
                    commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verts.count)
                }
            }
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
