//
//  RenderSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal
import simd

final class RenderSystem: System
{
    let requiredComponent: ComponentTypeID = Single_MetalSurfaceComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component)
    {
        let surf = component as! Single_MetalSurfaceComponent
        guard let layer = surf.layer else
        {
            return
        }

        if surf.device == nil
        {
            surf.device = MTLCreateSystemDefaultDevice()
            surf.queue  = surf.device?.makeCommandQueue()
            surf.library = try? surf.device?.makeDefaultLibrary(bundle: .main)
            if let lib = surf.library
            {
                let desc = MTLRenderPipelineDescriptor()
                desc.vertexFunction   = lib.makeFunction(name: "vs_sprite2D")
                desc.fragmentFunction = lib.makeFunction(name: "fs_sprite2D")
                desc.colorAttachments[0].pixelFormat = .bgra8Unorm
                surf.pipeline = try? surf.device?.makeRenderPipelineState(descriptor: desc)
            }
            layer.device = surf.device
            layer.pixelFormat = .bgra8Unorm
            layer.framebufferOnly = false
        }

        guard let device = surf.device,
              let queue  = surf.queue,
              let pipeline = surf.pipeline,
              let drawable = layer.nextDrawable() else
        {
            return
        }

        // viewport size
        let scale = layer.contentsScale
        let sz = layer.bounds.size
        layer.drawableSize = .init(width: sz.width*scale, height: sz.height*scale)
        let vpPx = simd_float2(Float(layer.drawableSize.width), Float(layer.drawableSize.height))

        // camera
        let cam = EntityAdmin.shared.getCamera2DComponent()
        let ppu = Float(cam.pixelsPerUnit)
        let camCenter = simd_float2(Float(cam.center.x), Float(cam.center.y))
        let halfWorld = simd_float2(vpPx.x/ppu/2, vpPx.y/ppu/2)

        
        guard let spriteComponents = EntityAdmin.shared.getComponents(ofType: SpriteRenderComponent.self) else
        {
            return
        }
        
        // group by texture
        var buckets: [ObjectIdentifier: TextureBatch] = [:]
        for sprite in spriteComponents
        {
            if sprite.hidden
            {
                continue
            }
            
            guard let t: TransformComponent = sprite.sibling(TransformComponent.self),
                  let tex = sprite.texture else
            {
                continue
            }
            
            let key = ObjectIdentifier(tex as AnyObject)
            if buckets[key] == nil
            {
                buckets[key] = TextureBatch(texture: tex)
            }
            
            let w = Float(sprite.size.width * t.scale.width)
            let h = Float(sprite.size.height * t.scale.height)
            let half = simd_float2(w*0.5, h*0.5)
            let wpos = simd_float2(Float(t.position.x), Float(t.position.y))
            let cpos = wpos - camCenter

            let min = cpos - half
            let max = cpos + half
            
            func ndc(_ p: simd_float2) -> simd_float2
            {
                let n = p / halfWorld
                return simd_float2(n.x, n.y)
            }

            let u0 = sprite.uv.x, v0 = sprite.uv.y, u1 = sprite.uv.z, v1 = sprite.uv.w
            let c = sprite.tint

            let v0s = SpriteVertex(pos: ndc(simd_float2(min.x, min.y)), uv: simd_float2(u0,v0), col: c)
            let v1s = SpriteVertex(pos: ndc(simd_float2(max.x, min.y)), uv: simd_float2(u1,v0), col: c)
            let v2s = SpriteVertex(pos: ndc(simd_float2(max.x, max.y)), uv: simd_float2(u1,v1), col: c)
            let v3s = SpriteVertex(pos: ndc(simd_float2(min.x, max.y)), uv: simd_float2(u0,v1), col: c)

            buckets[key]!.verts.append(contentsOf: [v0s, v1s, v2s, v0s, v2s, v3s])
        }

        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = drawable.texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0.10,0.10,0.11,1.0)

        guard let cmd = queue.makeCommandBuffer(),
              let enc = cmd.makeRenderCommandEncoder(descriptor: pass) else
        {
            return
        }

        enc.setRenderPipelineState(pipeline)

        for batch in buckets.values where !batch.verts.isEmpty
        {
            let verts = batch.verts
            let bytes = verts.count * MemoryLayout<SpriteVertex>.stride
            
            if surf.vbuf == nil || surf.vbuf!.length < bytes
            {
                surf.vbuf = device.makeBuffer(length: max(bytes, 64*1024), options: .storageModeShared)
            }
            
            memcpy(surf.vbuf!.contents(), verts, bytes)
            enc.setVertexBuffer(surf.vbuf, offset: 0, index: 0)
            enc.setFragmentTexture(batch.texture, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: verts.count)
        }

        enc.endEncoding()
        cmd.present(drawable)
        cmd.commit()
    }
}
