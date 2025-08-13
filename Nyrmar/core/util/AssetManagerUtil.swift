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
    
    private let loader: MTKTextureLoader
    private var textures: [String: MTLTexture] = [:]
    private var spriteMaps: [String: SpriteMap] = [:]
    
    private init()
    {
        loader = MTKTextureLoader(device: MTLCreateSystemDefaultDevice()!)
    }
    
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
        
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else
        {
            return nil
        }
        
        let t = try? MTKTextureLoader(device: device).newTexture(URL: url, options: [
            MTKTextureLoader.Option.SRGB: false
        ])
        
        if let t = t
        {
            textures[name] = t
        }
        
        return t
    }

    func spriteMap(named name: String) -> SpriteMap?
    {
        if let m = spriteMaps[name]
        {
            return m
        }
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode(SpriteMap.self, from: data) else
        {
            return nil
        }
        
        spriteMaps[name] = map
        return map
    }
}
