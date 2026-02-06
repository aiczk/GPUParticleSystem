#ifndef GPUP_NOISE_INCLUDED
#define GPUP_NOISE_INCLUDED

// ============================================================================
// Hash Functions
// ============================================================================

// PCG Hash (Jarzynski & Olano, JCGT 2020)
inline uint pcg_hash(uint input)
{
    uint state = input * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

// PCG 2D hash
inline uint2 pcg2d(uint2 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    v.x += v.y * 1664525u;
    v.y += v.x * 1664525u;
    v = v ^ (v >> 16u);
    return v;
}

// PCG 3D hash (Jarzynski & Olano)
inline uint3 pcg3d(uint3 v)
{
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    v = v ^ (v >> 16u);
    v.x += v.y * v.z;
    v.y += v.z * v.x;
    v.z += v.x * v.y;
    return v;
}

float2 hash22(float2 p)
{
    uint2 q = pcg2d(asuint(p));
    return float2(q) * (1.0 / 4294967296.0);
}

// Cheap arithmetic hash for noise gradients (Dave Hoskins)
float3 hash33(float3 p)
{
    p = frac(p * float3(.1031, .1030, .0973));
    p += dot(p, p.yxz + 33.33);
    return frac((p.xxy + p.yxx) * p.zyx);
}

// ============================================================================
// Simplex Noise
// ============================================================================

float simplex3d(float3 p)
{
    const float F3 = 0.333333333;
    const float G3 = 0.166666667;

    float3 s = floor(p + dot(p, float3(F3, F3, F3)));
    float3 x = p - s + dot(s, float3(G3, G3, G3));

    float3 e = step(float3(0.0, 0.0, 0.0), x - x.yzx);
    float3 i1 = e * (1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy * (1.0 - e);

    float3 x1 = x - i1 + G3;
    float3 x2 = x - i2 + 2.0 * G3;
    float3 x3 = x - 1.0 + 3.0 * G3;

    float4 w = max(0.6 - float4(dot(x,x), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    w *= w; w *= w;

    float4 d = float4(
        dot(x, hash33(s) * 2.0 - 1.0),
        dot(x1, hash33(s + i1) * 2.0 - 1.0),
        dot(x2, hash33(s + i2) * 2.0 - 1.0),
        dot(x3, hash33(s + 1.0) * 2.0 - 1.0)
    );

    return dot(d, w) * 52.0;
}

// ============================================================================
// 3-Channel Simplex Noise (shared grid + hash, permuted gradients)
// ============================================================================
float3 simplex3d_vec3(float3 p)
{
    const float F3 = 0.333333333;
    const float G3 = 0.166666667;

    float3 s = floor(p + dot(p, float3(F3, F3, F3)));
    float3 x = p - s + dot(s, float3(G3, G3, G3));

    float3 e = step(float3(0.0, 0.0, 0.0), x - x.yzx);
    float3 i1 = e * (1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy * (1.0 - e);

    float3 x1 = x - i1 + G3;
    float3 x2 = x - i2 + 2.0 * G3;
    float3 x3 = x - 1.0 + 3.0 * G3;

    float4 w = max(0.6 - float4(dot(x,x), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    w *= w; w *= w;

    // 4 hash lookups shared across 3 output channels
    float3 g0 = hash33(s) * 2.0 - 1.0;
    float3 g1 = hash33(s + i1) * 2.0 - 1.0;
    float3 g2 = hash33(s + i2) * 2.0 - 1.0;
    float3 g3 = hash33(s + 1.0) * 2.0 - 1.0;

    float4 d0 = float4(dot(x, g0),     dot(x1, g1),     dot(x2, g2),     dot(x3, g3));
    float4 d1 = float4(dot(x, g0.yzx), dot(x1, g1.yzx), dot(x2, g2.yzx), dot(x3, g3.yzx));
    float4 d2 = float4(dot(x, g0.zxy), dot(x1, g1.zxy), dot(x2, g2.zxy), dot(x3, g3.zxy));

    return float3(dot(d0, w), dot(d1, w), dot(d2, w)) * 52.0;
}

// ============================================================================
// Fractal Brownian Motion (FBM)
// ============================================================================
float fbm3d(float3 p, int octaves, float multiplier, float scale)
{
    float value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float total_amplitude = 0.0;

    [unroll(4)]
    for (int i = 0; i < octaves; i++)
    {
        value += amplitude * simplex3d(p * frequency);
        total_amplitude += amplitude;
        amplitude *= multiplier;
        frequency *= scale;
    }

    return value / total_amplitude;
}

float3 fbm3d_vec3(float3 p, int octaves, float multiplier, float scale)
{
    float3 value = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float total_amplitude = 0.0;

    [unroll(4)]
    for (int i = 0; i < octaves; i++)
    {
        value += amplitude * simplex3d_vec3(p * frequency);
        total_amplitude += amplitude;
        amplitude *= multiplier;
        frequency *= scale;
    }

    return value / total_amplitude;
}

#endif // GPUP_NOISE_INCLUDED
