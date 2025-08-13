//
//  AssetManagerUtil.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/3/25.
//

import MetalKit

enum AssetLoaderUtil {
    static let textureExts = ["ktx2","png","jpg","jpeg"]

    @inline(__always)
    static func loadTexture(name: String, loader: MTKTextureLoader, bundle: Bundle = .main) -> MTLTexture?
    {
        // 1) Asset catalog
        if let t = try? loader.newTexture(
            name: name,
            scaleFactor: 1.0,
            bundle: bundle,
            options: [
                .SRGB: true as NSNumber,
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
            ])
        {
            return t
        }
        
        // 2) Bundle subdir fallback
        for ext in textureExts
        {
            if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "assets/texture"),
               let t = try? loader.newTexture(
                URL: url,
                options: [
                    .SRGB: true as NSNumber,
                    .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                    .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
               ])
            {
                return t
            }
        }
        return nil
    }

    @inline(__always)
    static func loadSpriteMap(name: String, bundle: Bundle = .main) -> Single_MetalTextureCacheComponent.SpriteMap?
    {
        guard let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "assets/spritemap"),
              let data = try? Data(contentsOf: url),
              let map = try? JSONDecoder().decode(Single_MetalTextureCacheComponent.SpriteMap.self, from: data)
        else
        {
            return nil
        }
        return map
    }

    @inline(__always)
    static func makeGridUVLUT(for texture: MTLTexture, tileSize: CGSize) -> [SIMD4<Float>]?
    {
        let tw = Int(tileSize.width), th = Int(tileSize.height)
        guard tw > 0, th > 0, texture.width >= tw, texture.height >= th else
        {
            return nil
        }
        
        let cols = texture.width / tw, rows = texture.height / th
        let total = max(1, cols * rows)
        var out = [SIMD4<Float>](repeating: .zero, count: total)
        let W = Float(texture.width), H = Float(texture.height)
        
        for i in 0..<total
        {
            let c = i % cols
            let r = i / cols
            let u0 = Float(c * tw) / W, v0 = Float(r * th) / H
            let u1 = Float((c + 1) * tw) / W, v1 = Float((r + 1) * th) / H
            out[i] = SIMD4<Float>(u0, v0, u1, v1)
        }
        return out
    }
}
