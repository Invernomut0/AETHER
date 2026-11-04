#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float life;
    float size;
};

kernel void aether_update_particles(
    device Particle* particles [[buffer(0)]],
    constant float& deltaTime [[buffer(1)]],
    constant float2& gravity [[buffer(2)]],
    uint id [[thread_position_in_grid]]
) {
    Particle p = particles[id];
    if (p.life <= 0.0) return;
    p.velocity += gravity * deltaTime;
    p.position += p.velocity * deltaTime;
    p.life = max(0.0, p.life - deltaTime);
    particles[id] = p;
}
