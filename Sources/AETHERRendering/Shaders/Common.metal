#include <metal_stdlib>
using namespace metal;

struct AetherVertex {
    float2 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct AetherUniforms {
    float4x4 transform;
    float progress;
    float time;
    float2 resolution;
};

struct AetherVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex AetherVertexOut aether_vertex(
    AetherVertex in [[stage_in]],
    constant AetherUniforms& uniforms [[buffer(1)]]
) {
    AetherVertexOut out;
    out.position = uniforms.transform * float4(in.position, 0.0, 1.0);
    out.uv = in.uv;
    return out;
}

fragment float4 aether_texture_fragment(
    AetherVertexOut in [[stage_in]],
    texture2d<float> source [[texture(0)]],
    sampler sourceSampler [[sampler(0)]]
) {
    return source.sample(sourceSampler, in.uv);
}
