#ifndef GPUP_PARTICLE_CORE_INCLUDED
#define GPUP_PARTICLE_CORE_INCLUDED

// ============================================================================
// Input/Output Structures
// ============================================================================
struct particle_appdata
{
    float4 vertex : POSITION;    // xyz = random seed (baked in mesh)
    float2 uv : TEXCOORD0;       // x = particle_id / 1048576
    float2 uv2 : TEXCOORD1;      // quad corner (0,0)-(1,1)
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct particle_v2f
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    nointerpolation uint2 packed : TEXCOORD1;  // colorMul(16) + age(16) + speed_t(16) + reserved(16)
    UNITY_VERTEX_OUTPUT_STEREO
};

// ============================================================================
// Particle Data Structure (Simplified - No Root, World Only)
// ============================================================================

// Bit-packed flags layout:
// bit 0: looping
// bits 1-3: distribution (0-5: Sphere, Cube, Hemisphere, Circle, Cone, Donut)
// bits 4-5: arc_mode (0-3)
// bit 6: force_randomize
// bit 7: multiply_by_size
// bit 8: multiply_by_velocity
// bits 9-10: noise_octaves - 1 (0-3 representing 1-4)
#define GPUP_GET_LOOPING(f)            ((f) & 0x001u)
#define GPUP_GET_DISTRIBUTION(f)       (((f) >> 1) & 0x7u)
#define GPUP_GET_ARC_MODE(f)           (((f) >> 4) & 0x3u)
#define GPUP_GET_FORCE_RANDOMIZE(f)    ((f) & 0x040u)
#define GPUP_GET_MULTIPLY_BY_SIZE(f)   ((f) & 0x080u)
#define GPUP_GET_MULTIPLY_BY_VELOCITY(f) ((f) & 0x100u)
#define GPUP_GET_NOISE_OCTAVES(f)      ((((f) >> 9) & 0x3u) + 1)

#define GPUP_PACK_FLAGS(looping, dist, arc_mode, force_rand, mul_size, mul_vel, octaves) \
    (((looping) & 0x1u) | (((dist) & 0x7u) << 1) | (((arc_mode) & 0x3u) << 4) | \
     (((force_rand) & 0x1u) << 6) | (((mul_size) & 0x1u) << 7) | (((mul_vel) & 0x1u) << 8) | \
     ((((octaves) - 1) & 0x3u) << 9))

// Vertex culling macro - moves vertex outside clip space
#define GPUP_CULL_VERTEX(o) { o.vertex = float4(0,0,-1,1); o.uv = 0; o.packed = 0; return o; }

struct ParticleData
{
    int use;
    int max_particles;
    uint flags;             // bit-packed: looping, distribution, arc_mode, force_randomize, multiply_by_size/velocity, noise_octaves
    float duration;
    float manual_time;      // used when looping=0
    float emission_rate;
    // Shape
    float radius_thickness;
    float arc;
    float arc_speed;
    float arc_spread;
    float cone_tan;         // tan(cone_angle * DEG2_RAD) - 事前計算済み
    float cone_length;
    float donut_radius;
    float3 shape_position;
    float3 shape_scale;
    float3x3 shape_rot_matrix;  // pre-computed rotation matrix (CPU or vertex)
    // Main
    float lifetime;
    float start_speed;
    float2 start_size;
    float3 start_rotation;
    float flip_rotation;
    int random_seed;
    float4 start_color;
    float gravity_modifier;
    float speed;            // simulation speed
    // Motion
    float4 spin;            // angular velocity
    // Velocity
    float3 linear_velocity;
    float3 orbital;
    float3 offset;
    float radial;
    float speed_modifier;
    // Force
    float3 force;
    // Velocity Limit
    float3 speed_limit;
    float dampen;
    float drag;
    // Noise
    float noise_strength;
    float noise_frequency;
    float noise_scroll_speed;
    float noise_octave_multiplier;
    float noise_octave_scale;
    float noise_position_amount;
    float noise_rotation_amount;
    float noise_size_amount;
    // Size over Lifetime
    float2 size_over_lifetime;
    // Color by Speed
    float2 color_by_speed_range;
    // Size by Speed
    float2 size_by_speed;
    float2 size_by_speed_range;
    // Rotation by Speed
    float3 rotation_by_speed;
    float2 rotation_by_speed_range;
};

// ============================================================================
// Random Utilities
// ============================================================================
void rand8(float2 seed, out float r0, out float r1, out float r2, out float r3,
           out float r4, out float r5, out float r6, out float r7)
{
    uint h = pcg_hash(asuint(seed.x) ^ (asuint(seed.y) * 747796405u));
    const float inv = 1.0 / 4294967296.0;
    r0 = float(h) * inv;
    h ^= h >> 17; h *= 0xed5ad4bbu;
    r1 = float(h) * inv;
    h ^= h >> 11; h *= 0xac4c1b51u;
    r2 = float(h) * inv;
    h ^= h >> 15; h *= 0x31848babu;
    r3 = float(h) * inv;
    h ^= h >> 14; h *= 0xed5ad4bbu;
    r4 = float(h) * inv;
    h ^= h >> 11; h *= 0xac4c1b51u;
    r5 = float(h) * inv;
    h ^= h >> 15; h *= 0x31848babu;
    r6 = float(h) * inv;
    h ^= h >> 14; h *= 0xed5ad4bbu;
    r7 = float(h) * inv;
}

// ============================================================================
// Arc Mode Helper
// ============================================================================
float compute_arc_theta(float r0, float arc_frac, int arc_mode, float arc_speed, float arc_spread,
                        float time, int particle_id, int max_particles)
{
    [branch]
    if (arc_mode == 0) // Random
    {
        // Apply spread: discrete positions within arc
        if (arc_spread > 0.0001)
        {
            float num_positions = max(1.0, floor(1.0 / arc_spread));
            float pos_idx = floor(r0 * num_positions);
            return (pos_idx / num_positions) * TWO_PI * arc_frac;
        }
        return r0 * TWO_PI * arc_frac;
    }
    else if (arc_mode == 1) // Loop
    {
        float loop_t = frac(time * arc_speed);
        return loop_t * TWO_PI * arc_frac;
    }
    else if (arc_mode == 2) // PingPong
    {
        float pp_t = abs(frac(time * arc_speed * 0.5) * 2.0 - 1.0);
        return pp_t * TWO_PI * arc_frac;
    }
    else // BurstSpread (3)
    {
        float spread_t = (float)particle_id / max((float)max_particles, 1.0);
        return spread_t * TWO_PI * arc_frac;
    }
}

// Approximate cube root via IEEE 754 bit trick (~5% error, sufficient for distribution)
inline float approx_cbrt(float x)
{
    return asfloat(asint(x) / 3 + 0x2A555556);
}

// ============================================================================
// Distribution
// ============================================================================
void distribution_position(float r0, float r1, float r2, float t, int distribution,
                           float radius_thickness, float arc, int arc_mode, float arc_speed, float arc_spread,
                           float cone_tan, float cone_length, float donut_radius,
                           int particle_id, int max_particles,
                           out float3 out_pos)
{
    float3 base_pos;
    float arc_frac = (arc > 0.0001) ? (arc * 0.002777778) : 1.0;  // 1/360 = 0.002777778
    float theta = compute_arc_theta(r0, arc_frac, arc_mode, arc_speed, arc_spread, t, particle_id, max_particles);

    [branch]
    if (distribution == 0)  // Sphere
    {
        float u = r1 * 2.0 - 1.0;
        float s_th, c_th;
        sincos(theta, s_th, c_th);
        float su = sqrt(1.0 - u * u);
        float radius = lerp(1.0, approx_cbrt(r2), radius_thickness);
        base_pos = float3(su * c_th, u, su * s_th) * radius;
    }
    else if (distribution == 1)  // Cube
    {
        base_pos = float3(r0, r1, r2) * 2.0 - 1.0;
    }
    else if (distribution == 2)  // Hemisphere
    {
        float u = r1;
        float s_th, c_th;
        sincos(theta, s_th, c_th);
        float su = sqrt(1.0 - u * u);
        float radius = lerp(1.0, approx_cbrt(r2), radius_thickness);
        base_pos = float3(su * c_th, u, su * s_th) * radius;
    }
    else if (distribution == 3)  // Circle
    {
        float s_th, c_th;
        sincos(theta, s_th, c_th);
        float radius = lerp(1.0, sqrt(r1), radius_thickness);
        base_pos = float3(c_th * radius, 0.0, s_th * radius);
    }
    else if (distribution == 4)  // Cone
    {
        float h = r1;
        float s_th, c_th;
        sincos(theta, s_th, c_th);
        float cone_r = cone_tan * h * cone_length;
        cone_r *= lerp(1.0, sqrt(r2), radius_thickness);
        base_pos = float3(c_th * cone_r, h * cone_length, s_th * cone_r);
    }
    else // Donut (5)
    {
        float phi = r1 * TWO_PI;
        float s_th, c_th, s_ph, c_ph;
        sincos(theta, s_th, c_th);
        sincos(phi, s_ph, c_ph);
        // Donut: main radius = 1, tube radius = donut_radius
        float tube_r = donut_radius * lerp(1.0, sqrt(r2), radius_thickness);
        float x = (1.0 + tube_r * c_ph) * c_th;
        float y = tube_r * s_ph;
        float z = (1.0 + tube_r * c_ph) * s_th;
        base_pos = float3(x, y, z);
    }
    out_pos = base_pos;
}

// Stateless particle age calculation
void calc_particle_age(float time, float spawn_time, float lifetime,
                       out float out_age, out bool out_culled, out float out_cycle, out float out_elapsed)
{
    out_culled = false;
    out_age = 0;
    out_cycle = 0;

    float elapsed = time - spawn_time;
    out_elapsed = elapsed;

    // Not yet spawned
    if (elapsed < 0)
    {
        out_culled = true;
        return;
    }

    float lifetime_inv = 1.0 / lifetime;
    float elapsed_norm = elapsed * lifetime_inv;
    out_cycle = floor(elapsed_norm);
    out_age = elapsed_norm - out_cycle;  // fmod不要
}

void rise_effect(float r3, float r4, float t, float lifetime, float3 direction,
                 float spawn_delay, bool looping,
                 out float3 out_offset, out float out_color_mul, out float out_size, out float out_age,
                 out bool out_culled)
{
    float cycle, elapsed;
    calc_particle_age(t, spawn_delay, lifetime, out_age, out_culled, cycle, elapsed);

    // Non-looping: cull after first lifetime
    if (!looping && elapsed >= lifetime)
        out_culled = true;

    if (out_culled)
    {
        out_offset = float3(0, 0, 0);
        out_color_mul = 0;
        out_size = 0;
        return;
    }

    // Cycle-based randomization
    uint cycle_hash = pcg_hash(asuint(cycle) ^ asuint(r4 * 1000.0));
    float3 spawn_offset = float3(
        (cycle_hash & 0xFFu) / 255.0 - 0.5,
        ((cycle_hash >> 8) & 0xFFu) / 255.0 - 0.5,
        ((cycle_hash >> 16) & 0xFFu) / 255.0 - 0.5
    ) * 0.3;

    out_offset = spawn_offset + out_age * direction * 0.3;

    float fade_in = saturate(out_age * 5.0);
    float fade_out = saturate((1.0 - out_age) * 5.0);
    out_color_mul = fade_in * fade_out;

    out_size = 2.0 + sin(r3 * TWO_PI + t * 0.3 * (1.0 + r3));
}

// ============================================================================
// Velocity Functions
// ============================================================================
float3 apply_orbital_velocity(float3 pos, float3 orbital, float3 offset, float age)
{
    float3 angles = orbital * DEG2_RAD * age;
    float3 relative = pos - offset;
    return mul(rotation_matrix(angles), relative) + offset;
}

float3 apply_radial_velocity(float3 pos, float radial, float age)
{
    float len = length(pos);
    if (len < 0.0001) return pos;
    float3 dir = pos / len;
    return pos + dir * radial * age;
}

float3 apply_velocity_limit(float3 velocity, float3 limit, float dampen, float drag, float age,
                            bool multiply_by_size, float particle_size,
                            bool multiply_by_velocity)
{
    // Adjust dampen based on size and velocity (branchless)
    float adjusted_dampen = dampen;
    adjusted_dampen *= lerp(1.0, particle_size, (float)multiply_by_size);
    adjusted_dampen *= lerp(1.0, length(velocity), (float)multiply_by_velocity);

    // Padé [1,1] approximation: exp(-x) ≈ (1 - 0.5x) / (1 + 0.5x)
    float t = adjusted_dampen * age;
    velocity *= (1.0 - 0.5 * t) / (1.0 + 0.5 * t);
    velocity *= 1.0 / (1.0 + drag * age);

    // Per-axis limit (branchless)
    float3 limit_active = step(float3(0.0001, 0.0001, 0.0001), limit);
    float3 clamped = clamp(velocity, -limit, limit);
    velocity = lerp(velocity, clamped, limit_active);

    return velocity;
}

// ============================================================================
// Noise Functions (with FBM support)
// ============================================================================
float3 apply_particle_noise_position(float3 pos, float3 seed, float time,
                                      float strength, float freq, float scroll,
                                      int octaves, float octave_mult, float octave_scale)
{
    float3 noise_input = pos * freq + seed;
    noise_input.z += time * scroll;
    float3 noise_offset;
    [branch]
    if (octaves > 1)
        noise_offset = fbm3d_vec3(noise_input, octaves, octave_mult, octave_scale);
    else
        noise_offset = simplex3d_vec3(noise_input);
    return pos + noise_offset * strength;
}

float3 apply_particle_noise_rotation(float3 seed, float time,
                                      float strength, float freq, float scroll)
{
    if (abs(strength) < 0.0001)
        return float3(0, 0, 0);
    return simplex3d_vec3(float3(seed.xy, time * scroll + 300.0)) * strength * DEG2_RAD;
}

float apply_particle_noise_size(float3 seed, float time,
                                 float strength, float freq, float scroll)
{
    if (abs(strength) < 0.0001)
        return 1.0;
    float t = time * scroll;
    float noise_size = simplex3d(float3(seed.xy * freq, t + 600.0));
    return 1.0 + noise_size * strength;
}

float3 apply_force_randomize(float3 force, float3 seed, float time, float randomize)
{
    return force + simplex3d_vec3(float3(seed.xy, time * 2.0)) * randomize;
}

// ============================================================================
// Billboard
// ============================================================================
float3 billboard_vertex(float3 center, float3 right, float3 up, float2 quad_size,
                        float3 rotation, bool has_rot, float2 corner)
{
    [branch]
    if (has_rot)
    {
        [branch]
        if (rotation.x == 0 && rotation.y == 0)
        {
            // Z-axis only fast path: sincos x1 instead of x3
            float s, c;
            sincos(rotation.z, s, c);
            float3 r0 = right * c + up * s;
            up = up * c - right * s;
            right = r0;
        }
        else
        {
            float3x3 rot = rotation_matrix(rotation);
            right = mul(rot, right);
            up = mul(rot, up);
        }
    }
    right *= quad_size.x;
    up *= quad_size.y;

    float2 offset = corner * 2.0 - 1.0;
    return center + right * offset.x + up * offset.y;
}


// ============================================================================
// Main Particle Processing
// ============================================================================
particle_v2f process_particle_vs(particle_appdata v, ParticleData p)
{
    particle_v2f o;
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    // Initialize for culling (GPUP_CULL_VERTEX uses these defaults)
    o.vertex = float4(0, 0, -1, 1);
    o.uv = 0;
    o.packed = 0;

    if (p.use <= 0)
        GPUP_CULL_VERTEX(o);

    int particle_id = (int)(v.uv.x * 1048576.0);
    float3 rnd_seed = v.vertex.xyz;

    if (particle_id >= p.max_particles)
        GPUP_CULL_VERTEX(o);

    // Unpack flags once
    uint flags = p.flags;
    bool looping = GPUP_GET_LOOPING(flags);
    int distribution = GPUP_GET_DISTRIBUTION(flags);
    int arc_mode = GPUP_GET_ARC_MODE(flags);
    bool force_randomize = GPUP_GET_FORCE_RANDOMIZE(flags);
    bool multiply_by_size = GPUP_GET_MULTIPLY_BY_SIZE(flags);
    bool multiply_by_velocity = GPUP_GET_MULTIPLY_BY_VELOCITY(flags);
    int noise_octaves = GPUP_GET_NOISE_OCTAVES(flags);

    float2 corner = v.uv2;

    // Generate random values (with seed offset)
    float seed_offset = (float)p.random_seed * 0.001;
    float2 seed = float2(rnd_seed.x * 1000.0 + seed_offset, rnd_seed.y * 1000.0 + particle_id * 0.001 + seed_offset);
    float r0, r1, r2, r3, r4, r5, r6, r7;
    rand8(seed, r0, r1, r2, r3, r4, r5, r6, r7);

    // Use constant values
    float lifetime = p.lifetime;
    float start_speed = p.start_speed;
    float2 start_size = p.start_size;
    float3 start_rotation = p.start_rotation;

    // Flip rotation (probability based)
    float rotation_sign = (r7 < p.flip_rotation) ? -1.0 : 1.0;

    // Cache camera position (used multiple times)
    float3 cam_pos = get_camera_position();

    float base_time = looping ? _Time.y : p.manual_time;
    float t = base_time * p.speed;
    bool has_spin = any(p.spin.xyz != 0) || any(abs(start_rotation) > 0.0001);
    bool has_noise = p.noise_strength > 0.0001;

    float3 pos;
    distribution_position(r0, r1, r2, t, distribution, p.radius_thickness,
                          p.arc, arc_mode, p.arc_speed, p.arc_spread,
                          p.cone_tan, p.cone_length, p.donut_radius,
                          particle_id, p.max_particles, pos);

    // Apply shape transform (Scale → Rotate → Translate)
    pos *= p.shape_scale;
    pos = mul(p.shape_rot_matrix, pos);
    pos += p.shape_position;

    // Calculate spawn_delay in simulation time units (must match 't')
    // Emission: emission_rate is particles per REAL second
    // spawn_delay (sim) = (particle_id / emission_rate) * speed
    float spawn_time_real = (p.emission_rate > 0.001)
        ? (float)particle_id / p.emission_rate
        : 0.0;
    float spawn_delay = spawn_time_real * p.speed;

    float3 rise_off;
    float color_mul, psize, p_age;
    bool rise_culled;
    rise_effect(r3, r4, t, lifetime, p.linear_velocity,
                spawn_delay, looping,
                rise_off, color_mul, psize, p_age, rise_culled);

    if (rise_culled)
        GPUP_CULL_VERTEX(o);

    // Duration: stop spawning new particles after duration (but let existing ones live)
    if (p.duration > 0.0001 && spawn_time_real > p.duration)
        GPUP_CULL_VERTEX(o);

    // Apply linear velocity (World space)
    rise_off *= start_speed;
    pos += rise_off;

    if (any(p.orbital != 0))
        pos = apply_orbital_velocity(pos, p.orbital, p.offset, p_age);

    if (abs(p.radial) > 0.0001)
        pos = apply_radial_velocity(pos, p.radial, p_age);

    float age_time = p_age * lifetime;

    // Apply force (World space)
    float3 applied_force = p.force;

    if (force_randomize)
        applied_force = apply_force_randomize(applied_force, rnd_seed, t, 1.0);

    float age_time_sq = age_time * age_time;
    float3 force_offset = applied_force * (age_time_sq * 0.5);

    // Apply gravity (Y-down, branchless)
    force_offset.y -= p.gravity_modifier * 4.905 * age_time_sq;

    float avg_size = (start_size.x + start_size.y) * 0.5;
    force_offset = apply_velocity_limit(force_offset, p.speed_limit, p.dampen, p.drag, p_age,
                                        multiply_by_size, avg_size,
                                        multiply_by_velocity);
    pos += force_offset;

    // Speed modifier (branchless - multiplying by 1.0 when inactive is free)
    pos *= p.speed_modifier;

    [branch]
    if (has_noise && p.noise_position_amount > 0.0001)
    {
        pos = apply_particle_noise_position(pos, rnd_seed, t,
            p.noise_strength * p.noise_position_amount, p.noise_frequency, p.noise_scroll_speed,
            noise_octaves, p.noise_octave_multiplier, p.noise_octave_scale);
    }

    // Size: start_size * size_over_lifetime
    float2 final_size = start_size * p.size_over_lifetime;

    [branch]
    if (has_noise && p.noise_size_amount > 0.0001)
    {
        float size_noise = apply_particle_noise_size(rnd_seed, t,
            p.noise_strength * p.noise_size_amount, p.noise_frequency, p.noise_scroll_speed);
        final_size *= size_noise;
    }
    final_size *= psize;

    // World position (Transform handles position/rotation/scale)
    float3 world_center = mul(unity_ObjectToWorld, float4(pos, 1.0)).xyz;
    float2 quad_size = 0.01 * final_size;

    // Calculate speed for by-speed modules
    float current_speed = length(rise_off + force_offset);

    // Size by Speed (branchless)
    {
        float range_active = step(p.size_by_speed_range.x + 0.0001, p.size_by_speed_range.y);
        float speed_t = saturate((current_speed - p.size_by_speed_range.x) /
                                  max(p.size_by_speed_range.y - p.size_by_speed_range.x, 0.001));
        quad_size *= lerp(float2(1, 1), p.size_by_speed, speed_t * range_active);
    }

    // Near-camera fillrate optimization: rsqrt shared with billboard forward
    float3 to_cam = cam_pos - world_center;
    float cam_dist_sq = dot(to_cam, to_cam);
    float cam_dist_inv = rsqrt(cam_dist_sq);
    float cam_dist = cam_dist_sq * cam_dist_inv;
    quad_size *= saturate(cam_dist);  // 0-1m: shrink, 1m+: full size

    // Frustum culling (pre-compute clip coords for reuse)
    float cull_size = max(quad_size.x, quad_size.y) * 2.0;
    float4 clip_center = mul(UNITY_MATRIX_VP, float4(world_center, 1.0));
    if (frustum_cull_clip(clip_center, cull_size))
        GPUP_CULL_VERTEX(o);

    // Billboard rotation with flip
    float3 spin_dir = float3(r5, r6, r7) - 0.5;
    spin_dir *= rotation_sign;
    float3 initial_rot = start_rotation * DEG2_RAD;
    float3 spin = initial_rot + spin_dir * t * p.spin.xyz;

    // Rotation by Speed (branchless)
    {
        float range_active = step(p.rotation_by_speed_range.x + 0.0001, p.rotation_by_speed_range.y);
        float speed_t = saturate((current_speed - p.rotation_by_speed_range.x) /
                                  max(p.rotation_by_speed_range.y - p.rotation_by_speed_range.x, 0.001));
        spin += p.rotation_by_speed * DEG2_RAD * speed_t * range_active * p_age;
        has_spin = has_spin || (range_active > 0.5);
    }

    [branch]
    if (has_noise && p.noise_rotation_amount > 0.0001)
    {
        float3 noise_rot = apply_particle_noise_rotation(rnd_seed, t,
            p.noise_strength * p.noise_rotation_amount * 45.0, p.noise_frequency, p.noise_scroll_speed);
        spin += noise_rot;
        has_spin = true;
    }

    // Facing billboard (camera-facing, reuse rsqrt from cam_dist)
    float3 forward = to_cam * cam_dist_inv;
    float3 bb_right = normalize(cross(float3(0, 1, 0), forward));
    float3 bb_up = cross(forward, bb_right);
    float3 world_pos = billboard_vertex(world_center, bb_right, bb_up, quad_size, spin, has_spin, corner);

    // Reuse clip_center + billboard offset (avoids redundant VP multiply of world_center)
    o.vertex = clip_center + mul(UNITY_MATRIX_VP, float4(world_pos - world_center, 0.0));

    o.uv = corner;

    // Pack colorMul (16bit) and speed_t for Color by Speed (16bit, branchless)
    float color_range_active = step(p.color_by_speed_range.x + 0.0001, p.color_by_speed_range.y);
    float speed_t = saturate((current_speed - p.color_by_speed_range.x) /
                             max(p.color_by_speed_range.y - p.color_by_speed_range.x, 0.001)) * color_range_active;
    uint colorMul_bits = ((uint)(saturate(color_mul) * 65535.0)) & 0xFFFFu;
    o.packed.x = colorMul_bits;
    o.packed.y = f32tof16(p_age) | (f32tof16(speed_t) << 16);

    return o;
}

#endif // GPUP_PARTICLE_CORE_INCLUDED
