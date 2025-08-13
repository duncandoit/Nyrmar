//
//  AssetCacheSyncSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/13/25.
//

import MetalKit

final class ViewportSystem: System
{
    let requiredComponent: ComponentTypeID = Single_MetalSurfaceComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component)
    {
        let surf = component as! Single_MetalSurfaceComponent
        
        // Ensure a device exists
        if surf.device == nil
        {
            let dev = MTLCreateSystemDefaultDevice()
            surf.device = dev
            surf.queue  = dev?.makeCommandQueue()
        }

        guard let dev = surf.device else
        {
            print("[" + #fileID + "]: " + #function + " -> Failed to create default Metal device.")
            return
        }

        // Test whether device has changed
        let id = ObjectIdentifier(dev)
        if surf.deviceID != id
        {
            surf.deviceID = id
            
            // GPU resources tied to old device must rebuild lazily later
            surf.pipeline = nil
            surf.vbuf = nil
            surf.library = nil
        }

        // Bind device to layer and keep size in sync
        if let layer = surf.layer
        {
            if layer.device !== dev
            {
                layer.device = dev
            }
            
            layer.pixelFormat = surf.pixelFormat
            layer.framebufferOnly = false
            let scale = layer.contentsScale
            let sz = layer.bounds.size
            layer.drawableSize = .init(width: sz.width * scale, height: sz.height * scale)
        }
        
        // Sync the device with the lazy created texture cache
        guard let cache = EntityAdmin.shared.metalTextureCacheComponent() else
        {
            return
        }
        
        let needsSync = cache.loaderDeviceID != ObjectIdentifier(dev)
        if needsSync
        {
            cache.textureLoader = MTKTextureLoader(device: dev)
            cache.loaderDeviceID = id

            // Device-bound resources are invalid
            cache.textures.removeAll()
        }
    }
}
