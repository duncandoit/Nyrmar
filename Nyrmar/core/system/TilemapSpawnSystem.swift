//
//  TilemapSpawnSystem.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal

// TilemapSpawnSystem.swift (excerpt)
final class TilemapSpawnSystem: System
{
    let requiredComponent = TilemapPrefabComponent.typeID
    
    func update(deltaTime: TimeInterval, component: any Component)
    {
        let prefabComp = component as! TilemapPrefabComponent
        guard let cache = EntityAdmin.shared.metalTextureCacheComponent() else
        {
            return
        }
        guard let loader = cache.textureLoader else { return }

        func fetchTexture(_ name: String) -> MTLTexture? {
            if let t = cache.textures[name] { return t }
            guard let t = AssetLoaderUtil.loadTexture(name: name, loader: loader) else { return nil }
            cache.textures[name] = t; return t
        }

        guard let tileset = fetchTexture(prefabComp.tilesetTexture),
              let lut = AssetLoaderUtil.makeGridUVLUT(for: tileset, tileSize: prefabComp.tileSize) else { return }

        let renderComp = TilemapRenderComponent()
        renderComp.texture  = tileset
        renderComp.tileSize = prefabComp.tileSize
        renderComp.gridSize = prefabComp.gridSize
        renderComp.uvLUT    = lut

        EntityAdmin.shared.addSibling(renderComp, to: prefabComp)
        EntityAdmin.shared.removeComponent(prefabComp)
    }
}

// SpriteSpawnSystem.swift (excerpt)
final class SpriteSpawnSystem: System {
    let requiredComponent = SpritePrefabComponent.typeID
    func update(deltaTime: TimeInterval, component: any Component) {
        let prefabComp = component as! SpritePrefabComponent
        guard let cache = EntityAdmin.shared.metalTextureCacheComponent() else
        {
            return
        }
        guard let xform: TransformComponent = prefabComp.sibling(TransformComponent.self),
              let loader = cache.textureLoader else { return }

        func fetchTexture(_ name: String) -> MTLTexture? {
            if let t = cache.textures[name] { return t }
            guard let t = AssetLoaderUtil.loadTexture(name: name, loader: loader) else { return nil }
            cache.textures[name] = t; return t
        }
        func fetchMap(_ name: String) -> Single_MetalTextureCacheComponent.SpriteMap? {
            if let m = cache.spriteMaps[name] { return m }
            guard let m = AssetLoaderUtil.loadSpriteMap(name: name) else { return nil }
            cache.spriteMaps[name] = m; return m
        }

        let renderComp = SpriteRenderComponent()
        renderComp.tint = prefabComp.tint

        switch prefabComp.source {
        case .texture(let n):
            guard let tex = fetchTexture(n) else { return }
            renderComp.texture = tex; renderComp.uv = .init(0,0,1,1)
            renderComp.size = prefabComp.size ?? xform.scale
        case .atlas(let map, let frame):
            guard let sm = fetchMap(map),
                  let tex = fetchTexture(sm.texture),
                  let f = sm.frames[frame] else { return }
            renderComp.texture = tex; renderComp.uv = .init(f.u0,f.v0,f.u1,f.v1)
            renderComp.size = prefabComp.size ?? xform.scale
        }

        EntityAdmin.shared.addSibling(renderComp, to: prefabComp)
        EntityAdmin.shared.removeComponent(prefabComp)
    }
}
