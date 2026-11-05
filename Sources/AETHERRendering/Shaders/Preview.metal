#include <metal_stdlib>
using namespace metal;

struct PreviewVertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex PreviewVertexOut aether_preview_vertex(uint vertexID [[vertex_id]]) {
    constexpr float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    constexpr float2 uvs[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    PreviewVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = uvs[vertexID];
    return out;
}

fragment float4 aether_preview_fragment(
    PreviewVertexOut in [[stage_in]],
    texture2d<float> source [[texture(0)]],
    sampler sourceSampler [[sampler(0)]]
) {
    return source.sample(sourceSampler, in.uv);
}

struct EffectVertex {
    float2 position;
    float2 textureCoordinate;
};

vertex PreviewVertexOut aether_effect_vertex(
    uint vertexID [[vertex_id]],
    const device EffectVertex* vertices [[buffer(0)]]
) {
    PreviewVertexOut out;
    out.position = float4(vertices[vertexID].position, 0.0, 1.0);
    out.uv = vertices[vertexID].textureCoordinate;
    return out;
}

// Local deterministic cell hash: no noise texture, imported shader or assets.
static float aether_dissolve_threshold(float2 uv) {
    uint2 cell = uint2(floor(uv * float2(96.0, 72.0)));
    uint bits = (cell.x + 17u) * 1597334677u;
    bits ^= (cell.y + 31u) * 3812015801u;
    bits ^= bits >> 13;
    bits *= 2246822519u;
    bits ^= bits >> 16;
    return 0.04 + 0.92 * (float(bits & 0x00ffffffu) / 16777215.0);
}

fragment float4 aether_effect_fragment(
    PreviewVertexOut in [[stage_in]],
    texture2d<float> source [[texture(0)]],
    sampler sourceSampler [[sampler(0)]],
    constant float2& parameters [[buffer(0)]]
) {
    float progress = parameters.y;
    float visibility;
    if (progress <= 0.0) {
        visibility = 1.0;
    } else if (progress >= 1.0) {
        visibility = 0.0;
    } else {
        float threshold = aether_dissolve_threshold(in.uv);
        visibility = 1.0 - smoothstep(threshold - 0.035, threshold + 0.035, progress);
    }
    // The BGRA snapshot is already premultiplied. Scale RGB AND alpha once;
    // blending uses one/oneMinusSourceAlpha, never a second alpha multiplication.
    return source.sample(sourceSampler, in.uv) * (parameters.x * visibility);
}