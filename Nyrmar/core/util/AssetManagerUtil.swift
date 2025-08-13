//
//  AssetManagerUtil.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/3/25.
//

import MetalKit

final class AssetManagerUtil
{
    static let shared = AssetManagerUtil()
    private var textures: [String: MTLTexture] = [:]
    private var spriteMaps: [String: SpriteMap] = [:]
    
    private init() {}

    struct SpriteMap: Decodable
    {
        struct Frame: Decodable
        {
            let u0: Float, v0: Float, u1: Float, v1: Float
        }
        
        let texture: String
        let frames: [String: Frame]
    }

    func texture(named name: String, device: MTLDevice) -> MTLTexture?
    {
        if let t = textures[name]
        {
            return t
        }
        
        let loader = MTKTextureLoader(device: device)

        // Asset catalog (name without extension)
        if let tex = try? loader.newTexture(
            name: name,
            scaleFactor: 1.0,
            bundle: .main,
            options: [
                .SRGB: true as NSNumber,
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
            ])
        {
            textures[name] = tex
            return tex
        }

        // Bundle subdirectories (assets/texture) with common extensions
        for ext in ["ktx2","png","jpg","jpeg"]
        {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "assets/texture"),
               let tex = try? loader.newTexture(URL: url, options: [
                    .SRGB: true as NSNumber,
                    .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                    .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
               ])
            {
                textures[name] = tex
                return tex
            }
        }
        
        return nil
    }

    func spriteMap(named name: String) -> SpriteMap?
    {
        if let m = spriteMaps[name]
        {
            return m
        }
        
        // Prefer bundle subdirectory if you organized them there
        if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "assets/spritemap"),
           let data = try? Data(contentsOf: url),
           let map = try? JSONDecoder().decode(SpriteMap.self, from: data)
        {
            spriteMaps[name] = map; return map
        }
        
        // Fallback: bundle root
        if let url = Bundle.main.url(forResource: name, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let map = try? JSONDecoder().decode(SpriteMap.self, from: data)
        {
            spriteMaps[name] = map; return map
        }
        
        return nil
    }
}
