//
//  MetalUtil.swift
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

import Metal
import simd

struct SpriteVertex
{
    var pos: simd_float2; var uv: simd_float2; var col: simd_float4
}

struct TextureBatch
{
    let texture: any MTLTexture
    var verts: [SpriteVertex] = []
}
