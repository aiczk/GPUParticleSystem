#ifndef GPUP_CORE_INCLUDED
#define GPUP_CORE_INCLUDED

#include "Noise.hlsl"

// ============================================================================
// Numeric Constants
// ============================================================================
#define EPSILON         1e-6
#define DEG2_RAD        0.017453292519943295
#define TWO_PI          6.283185307179586
#define CM_TO_METER     0.01
static const float3x3 IDENTITY_MATRIX3 = float3x3(1,0,0, 0,1,0, 0,0,1);

// ============================================================================
// Transform Functions
// ============================================================================

float3x3 rotation_matrix(float3 rotation)
{
    float sx, cx, sy, cy, sz, cz;
    sincos(rotation.x, sx, cx);
    sincos(rotation.y, sy, cy);
    sincos(rotation.z, sz, cz);
    return float3x3(
        cy * cz + sy * sx * sz,  -cy * sz + sy * sx * cz, sy * cx,
        cx * sz,                  cx * cz,                -sx,
        -sy * cz + cy * sx * sz,  sy * sz + cy * sx * cz, cy * cx
    );
}

inline bool has_rotation(float3 rotation_vector)
{
    return dot(rotation_vector, rotation_vector) > EPSILON;
}

// ============================================================================
// Camera Helpers
// ============================================================================

inline float3 get_camera_position()
{
    #if UNITY_SINGLE_PASS_STEREO
        return (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * 0.5;
    #else
        return _WorldSpaceCameraPos;
    #endif
}

// ============================================================================
// Frustum Culling (World Space Only)
// ============================================================================

inline bool frustum_cull_world(float3 world_pos, float margin)
{
    float4 clip = mul(UNITY_MATRIX_VP, float4(world_pos, 1.0));
    float w = clip.w + margin;
    return clip.x < -w || clip.x > w || clip.y < -w || clip.y > w
        || clip.z < -margin || clip.z > w;
}

// Frustum cull from pre-computed clip coordinates (avoids redundant VP multiply)
inline bool frustum_cull_clip(float4 clip, float margin)
{
    float w = clip.w + margin;
    return clip.x < -w || clip.x > w || clip.y < -w || clip.y > w
        || clip.z < -margin || clip.z > w;
}

#endif // GPUP_CORE_INCLUDED
