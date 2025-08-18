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
    
    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let surfaceComp = component as! Single_MetalSurfaceComponent
        let clockComp = admin.clockComponent()
        
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
        let cameraComp = admin.camera2DComponent()
        let interpolationAlpha = clockComp.interpolationAlpha
        let pixelsPerUnit = Float(cameraComp.pixelsPerUnit)
        let cameraCenterWorld = simd_float2(Float(cameraComp.center.x), Float(cameraComp.center.y))
        let worldHalfExtents = simd_float2(viewportPixelSize.x/pixelsPerUnit/2, viewportPixelSize.y/pixelsPerUnit/2)
        let invWorldHalfExtents = SIMD2<Float>(1.0 / worldHalfExtents.x, 1.0 / worldHalfExtents.y)
        
        // Build render pass
        // Always clear + present even if we have to wait for the pipeline to be ready to draw.
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture     = drawable.texture
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
            let renderComps: [SpriteRenderComponent] = admin.getComponents(ofType: SpriteRenderComponent.self) ?? []
            if !renderComps.isEmpty
            {
                // Batch by texture identity
                var batches: [ObjectIdentifier: TextureBatch] = [:]
                batches.reserveCapacity(16) // small, grows geometrically as needed
                
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
                    
                    // Interpolated pose
                    let lerpedPosition = lerpPoint(transformComp.prevPosition, transformComp.position, interpolationAlpha)
                    let lerpedScale    = lerpSize(transformComp.prevScale, transformComp.scale, interpolationAlpha)
                    let lerpedAngle    = lerpAngleShortest(
                        Float(transformComp.prevRotation),
                        Float(transformComp.rotation),
                        interpolationAlpha
                    )

                    // Size in world units and camera-space center
                    let componentWidth    = Float(renderComp.size.width  * lerpedScale.width)
                    let componentHeight   = Float(renderComp.size.height * lerpedScale.height)
                    let halfSize          = simd_float2(componentWidth * 0.5, componentHeight * 0.5)
                    let cameraSpaceCenter = simd_float2(lerpedPosition.x, lerpedPosition.y) - cameraCenterWorld

                    // Rotation matrix
                    let cosA = cos(lerpedAngle)
                    let sinA = sin(lerpedAngle)
                    let r00  = cosA
                    let r01 = -sinA
                    let r10  = sinA
                    let r11 =  cosA

                    // Local corners (centered)
                    let pBL = simd_float2(-halfSize.x, -halfSize.y)
                    let pBR = simd_float2( halfSize.x, -halfSize.y)
                    let pTR = simd_float2( halfSize.x,  halfSize.y)
                    let pTL = simd_float2(-halfSize.x,  halfSize.y)

                    // Rotate then translate to camera space
                    let bl = simd_float2(r00*pBL.x + r01*pBL.y, r10*pBL.x + r11*pBL.y) + cameraSpaceCenter
                    let br = simd_float2(r00*pBR.x + r01*pBR.y, r10*pBR.x + r11*pBR.y) + cameraSpaceCenter
                    let tr = simd_float2(r00*pTR.x + r01*pTR.y, r10*pTR.x + r11*pTR.y) + cameraSpaceCenter
                    let tl = simd_float2(r00*pTL.x + r01*pTL.y, r10*pTL.x + r11*pTL.y) + cameraSpaceCenter

                    // UVs + color
                    let uv = renderComp.uv
                    let u0 = uv.x
                    let v0 = uv.y
                    let u1 = uv.z
                    let v1 = uv.w
                    let col = renderComp.tint

                    // Build six vertices (two triangles), NDC transform at write
                    let v0s = SpriteVertex(position: toNDC(bl, invHalf: invWorldHalfExtents), uv: simd_float2(u0, v0), color: col)
                    let v1s = SpriteVertex(position: toNDC(br, invHalf: invWorldHalfExtents), uv: simd_float2(u1, v0), color: col)
                    let v2s = SpriteVertex(position: toNDC(tr, invHalf: invWorldHalfExtents), uv: simd_float2(u1, v1), color: col)
                    let v3s = SpriteVertex(position: toNDC(tl, invHalf: invWorldHalfExtents), uv: simd_float2(u0, v1), color: col)

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
    
    @inline(__always)
    private func toNDC(_ p: simd_float2, invHalf: simd_float2) -> simd_float2
    {
        let n = p * invHalf
        return simd_float2(n.x, -n.y) // flip Y exactly once
    }
    
    @inline(__always)
    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float
    {
        a + (b - a) * t
    }
    
    @inline(__always)
    private func lerpPoint(_ a: CGPoint, _ b: CGPoint, _ t: Float) -> simd_float2
    {
        simd_float2(lerp(Float(a.x), Float(b.x), t), lerp(Float(a.y), Float(b.y), t))
    }
    
    @inline(__always)
    private func lerpSize(_ a: CGSize, _ b: CGSize, _ t: Float) -> CGSize
    {
        CGSize(
            width:  CGFloat(lerp(Float(a.width),  Float(b.width),  t)),
            height: CGFloat(lerp(Float(a.height), Float(b.height), t))
        )
    }
    
    @inline(__always)
    private func lerpAngleShortest(_ a: Float, _ b: Float, _ t: Float) -> Float
    {
        var d = fmodf(b - a, Float.pi * 2)
        if d >  Float.pi
        {
            d -= 2 * Float.pi
        }
        
        if d < -Float.pi
        {
            d += 2 * Float.pi
        }
        return a + d * t
    }
}
