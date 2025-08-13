//
//  SpriteSpawnSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal

//final class SpriteSpawnSystem: System
//{
//    let requiredComponent: ComponentTypeID = SpritePrefabComponent.typeID
//    
//    func update(deltaTime: TimeInterval, component: any Component)
//    {
//        let prefabComp = component as! SpritePrefabComponent
//        guard let transformComp = prefabComp.sibling(TransformComponent.self) else
//        {
//            return
//        }
//
//        // Surface/device for texture loading
//        let surfaceComp = EntityAdmin.shared.metalSurfaceComponent()
//        guard let device = surfaceComp.device ?? MTLCreateSystemDefaultDevice() else
//        {
//            return
//        }
//
//        let renderComp = SpriteRenderComponent()
//        renderComp.tint = prefabComp.tint
//
//        switch prefabComp.source
//        {
//        case .texture(let name):
//            guard let tex = AssetManagerUtil.shared.texture(named: name, device: device) else
//            {
//                return
//            }
//            
//            renderComp.texture = tex
//            renderComp.uv = .init(0,0,1,1)
//            renderComp.size = prefabComp.size ?? transformComp.scale   // simple default
//            
//        case .atlas(let mapName, let frameName):
//            
//            guard let map = AssetManagerUtil.shared.spriteMap(named: mapName),
//                  let tex = AssetManagerUtil.shared.texture(named: map.texture, device: device),
//                  let f = map.frames[frameName] else
//            {
//                return
//            }
//            
//            renderComp.texture = tex
//            renderComp.uv = .init(f.u0, f.v0, f.u1, f.v1)
//            renderComp.size = prefabComp.size ?? transformComp.scale
//        }
//
//        EntityAdmin.shared.addSibling(renderComp, to: prefabComp)
//        EntityAdmin.shared.removeComponent(prefabComp)
//    }
//}

//final class SpriteSpawnSystem: System
//{
//    let requiredComponent: ComponentTypeID = SpritePrefabComponent.typeID
//
//    func update(deltaTime: TimeInterval, component: any Component)
//    {
//        let prefabComp = component as! SpritePrefabComponent
//        guard let transformComp: TransformComponent = prefabComp.sibling(TransformComponent.self) else
//        {
//            return
//        }
//
//        guard let device = EntityAdmin.shared.metalSurfaceComponent().device else
//        {
//            return
//        }
//
//        let cacheComp = EntityAdmin.shared.metalTextureCacheComponent()
//
//        func loadTexture(named name: String) -> MTLTexture?
//        {
//            if let tilesetTexture = cacheComp.textures[name]
//            {
//                return tilesetTexture
//            }
//            
//            guard let loader = cacheComp.textureLoader else
//            {
//                return nil
//            }
//
//            // Check asset catalog
//            if let tilesetTexture = try? loader.newTexture(
//                name: name,
//                scaleFactor: 1.0,
//                bundle: .main,
//                options: [
//                    .SRGB: true as NSNumber,
//                    .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
//                    .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
//                ])
//            {
//                cacheComp.textures[name] = tilesetTexture
//                return tilesetTexture
//            }
//            
//            // Check Bundle subdir fallback
//            for ext in ["ktx2","png","jpg","jpeg"]
//            {
//                guard let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "assets/texture") else
//                {
//                    continue
//                }
//                
//                guard let tilesetTexture = try? loader.newTexture(
//                    URL: url,
//                    options: [
//                        .SRGB: true as NSNumber,
//                        .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
//                        .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
//                   ])
//                else
//                {
//                    continue
//                }
//                
//                cacheComp.textures[name] = tilesetTexture
//                return tilesetTexture
//            }
//            
//            return nil
//        }
//
//        func loadSpriteMap(named name: String) -> Single_MetalTextureCacheComponent.SpriteMap?
//        {
//            if let map = cacheComp.spriteMaps[name]
//            {
//                return map
//            }
//            
//            guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "assets/spritemap") else
//            {
//                return nil
//            }
//            guard let data = try? Data(contentsOf: url) else
//            {
//                return nil
//            }
//            guard let map = try? JSONDecoder().decode(Single_MetalTextureCacheComponent.SpriteMap.self, from: data) else
//            {
//                return nil
//            }
//            
//            cacheComp.spriteMaps[name] = map
//            return map
//        }
//
//        let renderComp = SpriteRenderComponent()
//        renderComp.tint = prefabComp.tint
//
//        switch prefabComp.source
//        {
//        case .texture(let name):
//            
//            guard let tex = loadTexture(named: name) else
//            {
//                return
//            }
//            renderComp.texture = tex
//            renderComp.uv = .init(0,0,1,1)
//            renderComp.size = prefabComp.size ?? transformComp.scale
//
//        case .atlas(let mapName, let frameName):
//            
//            guard let map = loadSpriteMap(named: mapName),
//                  let tex = loadTexture(named: map.texture),
//                  let f = map.frames[frameName]
//            else
//            {
//                return
//            }
//            renderComp.texture = tex
//            renderComp.uv = .init(f.u0, f.v0, f.u1, f.v1)
//            renderComp.size = prefabComp.size ?? transformComp.scale
//        }
//
//        // Retire the prefabComp
//        EntityAdmin.shared.addSibling(renderComp, to: prefabComp)
//        EntityAdmin.shared.removeComponent(prefabComp)
//    }
//}
