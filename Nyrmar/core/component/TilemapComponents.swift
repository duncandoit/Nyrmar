//
//  TilemapComponents.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Foundation
import Metal
import simd

/// Consumed by the `TilemapSpawnSystem` to be replaced with a `TilemapRenderComponent`
final class TilemapPrefabComponent: Component
{
    static let typeID = componentTypeID(for: TilemapPrefabComponent.self)
    var siblings: SiblingContainer?
    
    var tilesetTexture: String
    var tileSize: CGSize
    var gridSize: (w: Int, h: Int)
    var indices: [Int] // w*h
    
    init(tilesetTexture: String, tileSize: CGSize, gridSize: (Int,Int), indices: [Int])
    {
        self.tilesetTexture = tilesetTexture
        self.tileSize = tileSize
        self.gridSize = gridSize
        self.indices = indices
    }
}

/// Mutated by the `RenderSystem`
final class TilemapRenderComponent: Component
{
    static let typeID = componentTypeID(for: TilemapRenderComponent.self)
    var siblings: SiblingContainer?
    
    weak var texture: MTLTexture?
    var tileSize: CGSize = .zero
    var gridSize: (w: Int, h: Int) = (0,0)
    var uvLUT: [simd_float4] = [] // per tile index uv
}
