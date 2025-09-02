//
//  Single_MetalTextureCacheComponent.swift
//  Korin
//
//  Created by Zachary Duncan on 8/13/25.
//

import MetalKit

/// Singleton Component: Should have only one instance per `EntityAdmin`
/// Caches `SpriteMap` and `MTLTexture` for the GPU
final class Single_MetalTextureCacheComponent: SingletonComponent
{
    static let typeID = componentTypeID(for: Single_MetalTextureCacheComponent.self)
    var siblings: SiblingContainer?
    
    struct SpriteMap: Decodable
    {
        struct Frame: Decodable
        {
            let u0: Float, v0: Float, u1: Float, v1: Float
        }
        
        let texture: String
        let frames: [String: Frame]
    }
    
    var spriteMaps: [String: SpriteMap] = [:]
    var textures: [String: MTLTexture] = [:]
    
    var textureLoader: MTKTextureLoader?
    var loaderDeviceID: ObjectIdentifier?
}
