//
//  SpriteComponents.swift
//  Korin
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal
import simd

enum SpriteSource
{
    case texture(name: String)
    case atlas(map: String, frame: String)
}

/// Consumed by the `SpriteSpawnSystem` to be replaced with a `SpriteRenderComponent`
final class SpritePrefabComponent: Component
{
    static let typeID = componentTypeID(for: SpritePrefabComponent.self)
    var siblings: SiblingContainer?
    
    var source: SpriteSource
    var size: CGSize? = nil // world units (optional override)
    var tint: simd_float4 = .init(1,1,1,1)
    
    init(source: SpriteSource)
    {
        self.source = source
    }
}

/// Mutated by the `RenderSystem`
final class SpriteRenderComponent: Component
{
    static let typeID = componentTypeID(for: SpriteRenderComponent.self)
    var siblings: SiblingContainer?
    
    weak var texture: MTLTexture?
    var uv: simd_float4 = .init(0,0,1,1)          // u0,v0,u1,v1 (normalized)
    var size: CGSize = .init(width: 1, height: 1) // world units
    var tint: simd_float4 = .init(1,1,1,1)
    var hidden: Bool = false
}
