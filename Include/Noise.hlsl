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

float2 hash22(float2 p)
{
    uint2 q = pcg2d(asuint(p));
    return float2(q) * (1.0 / 4294967296.0);
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
    w = w * w * w * w;

    float4 d = float4(
        dot(x, hash22(s.xy + s.z * 31.0).xyy * 2.0 - 1.0),
        dot(x1, hash22(s.xy + i1.xy + (s.z + i1.z) * 31.0).xyy * 2.0 - 1.0),
        dot(x2, hash22(s.xy + i2.xy + (s.z + i2.z) * 31.0).xyy * 2.0 - 1.0),
        dot(x3, hash22(s.xy + 1.0 + (s.z + 1.0) * 31.0).xyy * 2.0 - 1.0)
    );

    return dot(d, w) * 52.0;
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

    for (int i = 0; i < octaves; i++)
    {
        value += amplitude * simplex3d(p * frequency);
        total_amplitude += amplitude;
        amplitude *= multiplier;
        frequency *= scale;
    }

    return value / total_amplitude;
}

#endif // GPUP_NOISE_INCLUDED
