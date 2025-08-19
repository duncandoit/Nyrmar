//
//  AssetCacheSyncSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/13/25.
//

import MetalKit

final class ViewportSystem: System
{
    let requiredComponent: ComponentTypeID = Single_MetalSurfaceComponent.typeID

    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let surfaceComp = component as! Single_MetalSurfaceComponent
        
        // Ensure a device exists
        if surfaceComp.device == nil
        {
            let device = MTLCreateSystemDefaultDevice()
            surfaceComp.device = device
            surfaceComp.queue  = device?.makeCommandQueue()
        }

        guard let device = surfaceComp.device else
        {
            print("[" + #fileID + "]: " + #function + " -> Failed to create default Metal device.")
            return
        }

        // Test whether device has changed
        let id = ObjectIdentifier(device)
        if surfaceComp.deviceID != id
        {
            surfaceComp.deviceID = id
            
            // GPU resources tied to old device must rebuild lazily later
            surfaceComp.pipeline = nil
            surfaceComp.vbuf = nil
            surfaceComp.library = nil
        }

        // Bind device to layer and keep size in sync
        if let layer = surfaceComp.layer
        {
            if layer.device !== device
            {
                layer.device = device
            }
            
            layer.pixelFormat = surfaceComp.pixelFormat
            layer.framebufferOnly = false
            let scale = layer.contentsScale
            let bounds = layer.bounds.size
            layer.drawableSize = .init(width: bounds.width * scale, height: bounds.height * scale)
        }
        
        // Sync the device with the lazy created texture cache
        guard let cacheComp = admin.metalTextureCacheComponent() else
        {
            return
        }
        
        let needsSync = cacheComp.loaderDeviceID != ObjectIdentifier(device)
        if needsSync
        {
            cacheComp.textureLoader = MTKTextureLoader(device: device)
            cacheComp.loaderDeviceID = id

            // Device-bound resources are invalid
            cacheComp.textures.removeAll()
        }
    }
}
