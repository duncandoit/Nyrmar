//
//  SpriteSpawnSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal

final class SpriteSpawnSystem: System
{
    let requiredComponent = SpritePrefabComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component)
    {
        let prefabComp = component as! SpritePrefabComponent
        guard let cacheComp = EntityAdmin.shared.metalTextureCacheComponent(),
            let transformComp: TransformComponent = prefabComp.sibling(TransformComponent.self),
            let loader = cacheComp.textureLoader
        else
        {
            return
        }

        func fetchTexture(_ name: String) -> MTLTexture?
        {
            if let cachedTexture = cacheComp.textures[name]
            {
                return cachedTexture
            }
            guard let loadedTexture = AssetLoaderUtil.loadTexture(name: name, loader: loader) else
            {
                return nil
            }
            cacheComp.textures[name] = loadedTexture
            return loadedTexture
        }
        
        func fetchMap(_ name: String) -> Single_MetalTextureCacheComponent.SpriteMap?
        {
            if let cachedSpriteMap = cacheComp.spriteMaps[name]
            {
                return cachedSpriteMap
            }
            guard let loadedSpriteMap = AssetLoaderUtil.loadSpriteMap(name: name) else
            {
                return nil
            }
            cacheComp.spriteMaps[name] = loadedSpriteMap
            return loadedSpriteMap
        }

        let renderComp = SpriteRenderComponent()
        renderComp.tint = prefabComp.tint

        switch prefabComp.source
        {
            
        case .texture(let name):
            
            guard let texture = fetchTexture(name) else
            {
                return
            }
            renderComp.texture = texture
            renderComp.uv = SIMD4<Float>(0, 0, 1, 1)
            renderComp.size = prefabComp.size ?? transformComp.scale
            
        case .atlas(let map, let frame):
            
            guard let spriteMap = fetchMap(map),
                  let texture = fetchTexture(spriteMap.texture),
                  let spriteFrame = spriteMap.frames[frame]
            else
            {
                return
            }
            renderComp.texture = texture
            renderComp.uv = SIMD4(spriteFrame.u0, spriteFrame.v0, spriteFrame.u1, spriteFrame.v1)
            renderComp.size = prefabComp.size ?? transformComp.scale
        }

        EntityAdmin.shared.addSibling(renderComp, to: prefabComp)
        EntityAdmin.shared.removeComponent(prefabComp)
    }
}
