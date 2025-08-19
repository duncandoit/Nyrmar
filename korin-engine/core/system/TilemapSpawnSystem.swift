//
//  TilemapSpawnSystem.swift
//  Korin
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal

final class TilemapSpawnSystem: System
{
    let requiredComponent = TilemapPrefabComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component, admin: EntityAdmin)
    {
        let prefabComp = component as! TilemapPrefabComponent
        guard let cacheComp = admin.metalTextureCacheComponent() else
        {
            return
        }
        
        guard let loader = cacheComp.textureLoader else
        {
            return
        }
        
        var texture: any MTLTexture
        if let cachedTexture = cacheComp.textures[prefabComp.tilesetTexture]
        {
            texture = cachedTexture
        }
        else
        {
            if let loadedTexture = AssetLoaderUtil.loadTexture(name: prefabComp.tilesetTexture, loader: loader)
            {
                texture = loadedTexture
            }
            else
            {
                return
            }
        }
        
        cacheComp.textures[prefabComp.tilesetTexture] = texture
        guard let lut = AssetLoaderUtil.makeGridUVLUT(for: texture, tileSize: prefabComp.tileSize) else
        {
            return
        }

        let renderComp = TilemapRenderComponent()
        renderComp.texture  = texture
        renderComp.tileSize = prefabComp.tileSize
        renderComp.gridSize = prefabComp.gridSize
        renderComp.uvLUT    = lut

        admin.addSibling(renderComp, to: prefabComp)
        admin.removeComponent(prefabComp)
    }
}
