//
//  Sprite2D.metal
//  Korin
//
//  Created by Zachary Duncan on 8/12/25.
//

#include <metal_stdlib>
using namespace metal;

struct SpriteVertextIn
{
    float2 position;
    float2 uv;
    float4 color;
};

struct SpriteVertextOut
{
    float4 position [[position]];
    float2 uv;
    float4 color;
};

vertex SpriteVertextOut vs_sprite2D(uint vid [[vertex_id]], const device SpriteVertextIn* inV [[buffer(0)]])
{
    SpriteVertextOut o;
    SpriteVertextIn v = inV[vid];
    o.position = float4(inV[vid].position,0,1);
    o.uv = float2(v.uv.x, 1.0 - v.uv.y);
    o.color = inV[vid].color;
    
    return o;
}

fragment float4 fs_sprite2D(SpriteVertextOut in [[stage_in]], texture2d<float> tex [[texture(0)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 c = tex.sample(s, in.uv) * in.color;
    
    return c;
}
