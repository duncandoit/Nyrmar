//
//  Sprite2D.metal
//  Nyrmar
//
//  Created by Zachary Duncan on 8/12/25.
//

#include <metal_stdlib>
using namespace metal;

struct SpriteVertext
{
    float2 position; float2 uv; float4 color;
};

struct SpriteVertextOut
{
    float4 position [[position]]; float2 uv; float4 color;
};

vertex SpriteVertextOut vs_sprite2D(uint vid [[vertex_id]], const device SpriteVertext* v [[buffer(0)]])
{
    SpriteVertextOut o;
    o.position=float4(v[vid].position,0,1);
    o.uv=v[vid].uv;
    o.color=v[vid].color;
    
    return o;
}

fragment float4 fs_sprite2D(SpriteVertextOut in [[stage_in]], texture2d<float> tex [[texture(0)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float4 c = tex.sample(s, in.uv) * in.color;
    
    return c;
}
