#include <metal_stdlib>
using namespace metal;

struct DistortionUniforms {
    float progress;
    float amplitude;
    float frequency;
    float time;
};

kernel void aether_ripple(
    texture2d<float, access::read> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    constant DistortionUniforms& u [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) return;
    float2 size = float2(outputTexture.get_width(), outputTexture.get_height());
    float2 uv = (float2(gid) + 0.5) / size;
    float2 center = float2(0.5);
    float2 delta = uv - center;
    float distance = length(delta);
    float wave = sin(distance * u.frequency - u.time * 8.0) * u.amplitude * (1.0 - u.progress);
    float2 displaced = uv + normalize(delta + 1e-5) * wave;
    uint2 samplePoint = uint2(clamp(displaced * size, float2(0.0), size - 1.0));
    outputTexture.write(inputTexture.read(samplePoint), gid);
}
