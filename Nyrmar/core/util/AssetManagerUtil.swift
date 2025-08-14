//
//  AssetManagerUtil.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/3/25.
//

import MetalKit

enum AssetLoaderUtil
{
    @inline(__always)
    static func loadTexture(name: String, loader: MTKTextureLoader, bundle: Bundle = .main) -> MTLTexture?
    {
        // Asset catalog
        if let texture = try? loader.newTexture(
            name: name,
            scaleFactor: 1.0,
            bundle: bundle,
            options: [
                .SRGB: true as NSNumber,
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
            ])
        {
            return texture
        }
        
        // Bundle subdir fallback
        let textureExts = ["ktx2","png","jpg","jpeg"]
        for ext in textureExts
        {
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "assets/texture"),
               let texture = try? loader.newTexture(
                URL: url,
                options: [
                    .SRGB: true as NSNumber,
                    .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                    .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
               ])
            {
                return texture
            }
        }
        return nil
    }

    @inline(__always)
    static func loadSpriteMap(name: String, bundle: Bundle = .main) -> Single_MetalTextureCacheComponent.SpriteMap?
    {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "assets/spritemap") else
        {
            print("[" + #fileID + "]: " + #function + " -> Failed: Could not find file.")
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else
        {
            print("[" + #fileID + "]: " + #function + " -> Failed: Could not read file.")
            return nil
        }
        
        guard let map = try? JSONDecoder().decode(Single_MetalTextureCacheComponent.SpriteMap.self, from: data) else
        {
            print("[" + #fileID + "]: " + #function + " -> Failed: Could not decode file.")
            return nil
        }
        
        return map
    }

    @inline(__always)
    static func makeGridUVLUT(for texture: MTLTexture, tileSize: CGSize) -> [SIMD4<Float>]?
    {
        let tileWidth = Int(tileSize.width)
        let tileHeight = Int(tileSize.height)
        guard tileWidth > 0, tileHeight > 0, texture.width >= tileWidth, texture.height >= tileHeight else
        {
            return nil
        }
        
        let columns = texture.width / tileWidth
        let rows = texture.height / tileHeight
        let totalSections = max(1, columns * rows)
        var out = [SIMD4<Float>](repeating: .zero, count: totalSections)
        let fWidth = Float(texture.width)
        let fHeight = Float(texture.height)
        
        for i in 0 ..< totalSections
        {
            let column = i % columns
            let row = i / columns
            let u0 = Float(column * tileWidth) / fWidth
            let v0 = Float(row * tileHeight) / fHeight
            let u1 = Float((column + 1) * tileWidth) / fWidth
            let v1 = Float((row + 1) * tileHeight) / fHeight
            out[i] = SIMD4<Float>(u0, v0, u1, v1)
        }
        return out
    }
}
