Shader "GekikaraStore/GPUParticleSystem"
{
    Properties
    {
        [HideInInspector] shader_is_using_thry_editor("", Float) = 0
        [HideInInspector] shader_master_label("GPU Particle System", Float) = 0
        [ThryShaderOptimizerLockButton] _ShaderOptimizerEnabled ("", Int) = 0

        // ============================================================================
        // Main Module
        // ============================================================================
        _Duration ("Duration", Float) = 0
        [Toggle] _Looping ("Looping", Int) = 1
        _ManualTime ("Manual Time --{condition_showS:(_Looping==0)}", Float) = 0
        _StartLifetime ("Start Lifetime", Float) = 1.0
        _StartSpeed ("Start Speed", Float) = 1.0
        [Toggle] _3DStartSize ("3D Start Size", Int) = 0
        _StartSize ("Start Size --{condition_showS:(_3DStartSize==0)}", Float) = 1.0
        [VectorLabel(X, Y)] _StartSize3D ("Start Size --{condition_showS:(_3DStartSize==1)}", Vector) = (1, 1, 0, 0)
        [Toggle] _3DStartRotation ("3D Start Rotation", Int) = 0
        _StartRotation ("Start Rotation --{condition_showS:(_3DStartRotation==0)}", Float) = 0
        [Vector3] _StartRotation3D ("Start Rotation --{condition_showS:(_3DStartRotation==1)}", Vector) = (0, 0, 0, 0)
        _FlipRotation ("Flip Rotation", Range(0, 1)) = 0
        _StartColor ("Start Color", Color) = (1, 1, 1, 1)
        _GravityModifier ("Gravity Modifier", Float) = 0
        _SimulationSpeed ("Simulation Speed", Float) = 0.2
        _MaxParticles ("Max Particles", Int) = 256
        _RandomSeed ("Random Seed", Int) = 0

        // ============================================================================
        // Emission
        // ============================================================================
        [HideInInspector] m_start_emission ("Emission", Float) = 0
            _EmissionRate ("Rate over Time", Float) = 0
        [HideInInspector] m_end_emission ("", Float) = 0

        // ============================================================================
        // Shape
        // ============================================================================
        [HideInInspector] m_start_shape ("Shape", Float) = 0
            [Enum(Sphere,0,Cube,1,Hemisphere,2,Circle,3,Cone,4,Donut,5)] _Distribution ("Shape", Int) = 0
            _RadiusThickness ("Radius Thickness --{condition_showS:(_Distribution!=1)}", Range(0, 1)) = 1
            _Arc ("Arc --{condition_showS:(_Distribution!=1)}", Range(0, 360)) = 0
            [Enum(Random,0,Loop,1,PingPong,2,BurstSpread,3)] _ArcMode ("Arc Mode --{condition_showS:(_Arc>0&&_Distribution!=1)}", Int) = 0
            _ArcSpeed ("Arc Speed --{condition_showS:(_Arc>0&&_ArcMode!=0&&_Distribution!=1)}", Float) = 1
            _ArcSpread ("Arc Spread --{condition_showS:(_Arc>0&&_Distribution!=1)}", Range(0, 1)) = 0
            _ConeAngle ("Angle --{condition_showS:(_Distribution==4)}", Range(0, 90)) = 25
            _ConeLength ("Length --{condition_showS:(_Distribution==4)}", Float) = 1
            _DonutRadius ("Donut Radius --{condition_showS:(_Distribution==5)}", Range(0, 1)) = 0.5
            [Vector3] _ShapePosition ("Position", Vector) = (0, 0, 0, 0)
            [Vector3] _ShapeRotation ("Rotation", Vector) = (0, 0, 0, 0)
            [Vector3] _ShapeScale ("Scale", Vector) = (1, 1, 1, 0)
            [HideInInspector] _ShapeRotMatrix0 ("", Vector) = (1, 0, 0, 0)
            [HideInInspector] _ShapeRotMatrix1 ("", Vector) = (0, 1, 0, 0)
            [HideInInspector] _ShapeRotMatrix2 ("", Vector) = (0, 0, 1, 0)
        [HideInInspector] m_end_shape ("", Float) = 0

        // ============================================================================
        // Velocity over Lifetime
        // ============================================================================
        [HideInInspector] m_start_velocity ("Velocity over Lifetime", Float) = 0
            [Vector3] _LinearVelocity ("Linear", Vector) = (0, 0, 0, 0)
            [Vector3] _OrbitalVelocity ("Orbital", Vector) = (0, 0, 0, 0)
            [Vector3] _OrbitalOffset ("Offset", Vector) = (0, 0, 0, 0)
            _RadialVelocity ("Radial", Float) = 0
            _SpeedModifier ("Speed Modifier", Float) = 1
        [HideInInspector] m_end_velocity ("", Float) = 0

        // ============================================================================
        // Limit Velocity over Lifetime
        // ============================================================================
        [HideInInspector] m_start_limit ("Limit Velocity over Lifetime", Float) = 0
            [Vector3] _SpeedLimit ("Speed", Vector) = (0, 0, 0, 0)
            _Dampen ("Dampen", Float) = 0
            _Drag ("Drag", Float) = 0
            [Toggle] _MultiplyBySize ("Multiply by Size", Int) = 0
            [Toggle] _MultiplyByVelocity ("Multiply by Velocity", Int) = 0
        [HideInInspector] m_end_limit ("", Float) = 0

        // ============================================================================
        // Force over Lifetime
        // ============================================================================
        [HideInInspector] m_start_force ("Force over Lifetime", Float) = 0
            [Vector3] _Force ("Force", Vector) = (0, 0, 0, 0)
            [Toggle] _ForceRandomize ("Randomize", Int) = 0
        [HideInInspector] m_end_force ("", Float) = 0

        // ============================================================================
        // Color over Lifetime
        // ============================================================================
        [HideInInspector] m_start_color ("Color over Lifetime", Float) = 0
            [Gradient] _ColorGradient ("Color", 2D) = "white" {}
            [HideInInspector] _ColorGradientSettings ("TPS", Vector) = (0, 0, 0, 0)
        [HideInInspector] m_end_color ("", Float) = 0
        
        // ============================================================================
        // Color by Speed
        // ============================================================================
        [HideInInspector] m_start_colorspeed ("Color by Speed", Float) = 0
            [Gradient] _ColorBySpeedGradient ("Color", 2D) = "white" {}
            [VectorLabel(Min, Max)] _ColorBySpeedRange ("Speed Range", Vector) = (0, 0, 0, 0)
        [HideInInspector] m_end_colorspeed ("", Float) = 0

        // ============================================================================
        // Size over Lifetime
        // ============================================================================
        [HideInInspector] m_start_size ("Size over Lifetime", Float) = 0
            [VectorLabel(Start, End)] _SizeOverLifetime ("Size", Vector) = (1, 1, 0, 0)
        [HideInInspector] m_end_size ("", Float) = 0
        
        // ============================================================================
        // Size by Speed
        // ============================================================================
        [HideInInspector] m_start_sizespeed ("Size by Speed", Float) = 0
            [VectorLabel(X, Y)] _SizeBySpeed ("Size", Vector) = (1, 1, 0, 0)
            [VectorLabel(Min, Max)] _SizeBySpeedRange ("Speed Range", Vector) = (0, 0, 0, 0)
        [HideInInspector] m_end_sizespeed ("", Float) = 0

        // ============================================================================
        // Rotation over Lifetime
        // ============================================================================
        [HideInInspector] m_start_rotation ("Rotation over Lifetime", Float) = 0
            [Vector3] _AngularVelocity ("Angular Velocity", Vector) = (0, 0, 0, 0)
        [HideInInspector] m_end_rotation ("", Float) = 0
        
        // ============================================================================
        // Rotation by Speed
        // ============================================================================
        [HideInInspector] m_start_rotspeed ("Rotation by Speed", Float) = 0
            [Vector3] _RotationBySpeed ("Angular Velocity", Vector) = (0, 0, 0, 0)
            [VectorLabel(Min, Max)] _RotationBySpeedRange ("Speed Range", Vector) = (0, 0, 0, 0)
        [HideInInspector] m_end_rotspeed ("", Float) = 0
        
        // ============================================================================
        // Noise
        // ============================================================================
        [HideInInspector] m_start_noise ("Noise", Float) = 0
            [Enum(Lite, 0, Rich, 1)] _NoiseQuality ("Quality", Int) = 1
            _NoiseStrength ("Strength", Float) = 0
            _NoiseFrequency ("Frequency", Float) = 1
            _NoiseScrollSpeed ("Scroll Speed", Float) = 1
            [IntRange] _NoiseOctaves ("Octaves", Range(1, 4)) = 1
            _NoiseOctaveMultiplier ("Octave Multiplier --{condition_showS:(_NoiseOctaves>1)}", Range(0, 1)) = 0.5
            _NoiseOctaveScale ("Octave Scale --{condition_showS:(_NoiseOctaves>1)}", Range(1, 4)) = 2
            _NoisePositionAmount ("Position Amount", Float) = 1
            _NoiseRotationAmount ("Rotation Amount", Float) = 0
            _NoiseSizeAmount ("Size Amount", Float) = 0
        [HideInInspector] m_end_noise ("", Float) = 0

        // ============================================================================
        // Renderer
        // ============================================================================
        [HideInInspector] m_start_renderer ("Renderer", Float) = 0
            [StylizedLargeTexture] _MainTex ("Texture", 2D) = "white" {}
        [HideInInspector] m_end_renderer ("", Float) = 0

        // ============================================================================
        // Blending & Stencil
        // ============================================================================
        [HideInInspector] m_start_advanced ("Advanced", Float) = 0
            [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Blend", Float) = 5
            [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dest Blend", Float) = 1
            [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Float) = 0
            [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Float) = 4
            [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 1
            [HideInInspector] m_start_stencil ("Stencil", Float) = 0
                [IntRange] _StencilRef ("Reference", Range(0, 255)) = 0
                [IntRange] _StencilReadMask ("Read Mask", Range(0, 255)) = 255
                [IntRange] _StencilWriteMask ("Write Mask", Range(0, 255)) = 255
                [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Compare", Float) = 8
                [Enum(UnityEngine.Rendering.StencilOp)] _StencilPass ("Pass", Float) = 0
                [Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Fail", Float) = 0
                [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("ZFail", Float) = 0
            [HideInInspector] m_end_stencil ("", Float) = 0
        [HideInInspector] m_end_advanced ("", Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True" }

        Pass
        {
            Name "Particle"
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull [_Cull]

            Stencil
            {
                Ref [_StencilRef]
                ReadMask [_StencilReadMask]
                WriteMask [_StencilWriteMask]
                Comp [_StencilComp]
                Pass [_StencilPass]
                Fail [_StencilFail]
                ZFail [_StencilZFail]
            }

            CGPROGRAM
            #pragma vertex particle_vert
            #pragma fragment particle_frag
            #pragma target 4.5
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            // ============================================================================
            // Property Declarations
            // ============================================================================

            // Main
            float _Duration;
            int _Looping;
            float _ManualTime;
            float _StartLifetime;
            float _StartSpeed;
            int _3DStartSize;
            float _StartSize;
            float4 _StartSize3D;
            int _3DStartRotation;
            float _StartRotation;
            float4 _StartRotation3D;
            float _FlipRotation;
            float4 _StartColor;
            float _GravityModifier;
            float _SimulationSpeed;
            int _MaxParticles;
            int _RandomSeed;

            // Emission
            float _EmissionRate;

            // Shape
            int _Distribution;
            float _RadiusThickness;
            float _Arc;
            int _ArcMode;
            float _ArcSpeed;
            float _ArcSpread;
            float _ConeAngle;
            float _ConeLength;
            float _DonutRadius;
            float4 _ShapePosition;
            float4 _ShapeRotation;
            float4 _ShapeScale;
            float4 _ShapeRotMatrix0;
            float4 _ShapeRotMatrix1;
            float4 _ShapeRotMatrix2;

            // Velocity
            float4 _LinearVelocity;
            float4 _OrbitalVelocity;
            float4 _OrbitalOffset;
            float _RadialVelocity;
            float _SpeedModifier;

            // Limit
            float4 _SpeedLimit;
            float _Dampen;
            float _Drag;
            int _MultiplyBySize;
            int _MultiplyByVelocity;

            // Force
            float4 _Force;
            int _ForceRandomize;

            // Noise
            float _NoiseQuality;
            float _NoiseStrength;
            float _NoiseFrequency;
            float _NoiseOctaveMultiplier;
            float _NoiseOctaveScale;
            float _NoiseScrollSpeed;
            int _NoiseOctaves;
            float _NoisePositionAmount;
            float _NoiseRotationAmount;
            float _NoiseSizeAmount;

            // Color (point sampling for 1D gradient lookup)
            Texture2D _ColorGradient;
            SamplerState sampler_ColorGradient;

            // Size over Lifetime
            float4 _SizeOverLifetime;

            // Rotation
            float4 _AngularVelocity;

            // Color by Speed (point sampling for 1D gradient lookup)
            Texture2D _ColorBySpeedGradient;
            SamplerState sampler_ColorBySpeedGradient;
            float4 _ColorBySpeedRange;

            // Size by Speed
            float4 _SizeBySpeed;
            float4 _SizeBySpeedRange;

            // Rotation by Speed
            float4 _RotationBySpeed;
            float4 _RotationBySpeedRange;

            // Renderer
            sampler2D _MainTex;

            #include "Include/Core.hlsl"
            #include "Include/GPUParticleCore.hlsl"

            // ============================================================================
            // Vertex Shader
            // ============================================================================
            particle_v2f particle_vert(particle_appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);

                particle_v2f o;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = float4(0, 0, -1, 1);
                o.uv = 0;
                o.packed = 0;

                // Early out for non-particle mesh vertices
                if (!any(v.vertex.xyz != 0)) GPUP_CULL_VERTEX(o);

                // Load particle data from properties
                ParticleData p = (ParticleData)0;
                p.use = 1;
                p.max_particles = _MaxParticles;
                // Pack flags: looping, distribution, arc_mode, force_randomize, multiply_by_size/velocity, noise_octaves
                p.flags = GPUP_PACK_FLAGS(_Looping, _Distribution, _ArcMode, _ForceRandomize,
                                          _MultiplyBySize, _MultiplyByVelocity, _NoiseOctaves);
                p.duration = _Duration;
                p.manual_time = _ManualTime;
                p.emission_rate = _EmissionRate;
                // Shape
                p.radius_thickness = _RadiusThickness;
                p.arc = _Arc;
                p.arc_speed = _ArcSpeed;
                p.arc_spread = _ArcSpread;
                p.cone_tan = tan(_ConeAngle * 0.01745329);  // DEG2_RAD = PI/180
                p.cone_length = _ConeLength;
                p.donut_radius = _DonutRadius;
                p.shape_position = _ShapePosition.xyz;
                p.shape_scale = _ShapeScale.xyz;
                p.shape_rot_matrix = float3x3(
                    _ShapeRotMatrix0.xyz,
                    _ShapeRotMatrix1.xyz,
                    _ShapeRotMatrix2.xyz
                );

                // Noise FBM
                p.noise_octave_multiplier = _NoiseOctaveMultiplier;
                p.noise_octave_scale = _NoiseOctaveScale;

                // By Speed modules
                p.color_by_speed_range = _ColorBySpeedRange.xy;
                p.size_by_speed = _SizeBySpeed.xy;
                p.size_by_speed_range = _SizeBySpeedRange.xy;
                p.rotation_by_speed = _RotationBySpeed.xyz;
                p.rotation_by_speed_range = _RotationBySpeedRange.xy;


                // Size over Lifetime
                p.size_over_lifetime = _SizeOverLifetime.xy;

                // Main
                p.lifetime = _StartLifetime;
                p.start_speed = _StartSpeed;
                p.start_size = _3DStartSize ? _StartSize3D.xy : float2(_StartSize, _StartSize);
                p.start_rotation = _3DStartRotation ? _StartRotation3D.xyz : float3(0, 0, _StartRotation);
                p.flip_rotation = _FlipRotation;
                p.random_seed = _RandomSeed;
                p.start_color = _StartColor;
                p.gravity_modifier = _GravityModifier;

                // Motion
                p.spin = _AngularVelocity;
                p.speed = _SimulationSpeed;

                // Velocity
                p.linear_velocity = _LinearVelocity.xyz;
                p.orbital = _OrbitalVelocity.xyz;
                p.offset = _OrbitalOffset.xyz;
                p.radial = _RadialVelocity;
                p.speed_modifier = _SpeedModifier;

                // Force
                p.force = _Force.xyz;

                // Velocity Limit
                p.speed_limit = _SpeedLimit.xyz;
                p.dampen = _Dampen;
                p.drag = _Drag;

                // Noise
                p.noise_strength = _NoiseStrength;
                p.noise_frequency = _NoiseFrequency;
                p.noise_scroll_speed = _NoiseScrollSpeed;
                p.noise_position_amount = _NoisePositionAmount;
                p.noise_rotation_amount = _NoiseRotationAmount;
                p.noise_size_amount = _NoiseSizeAmount;

                return process_particle_vs(v, p);
            }

            // ============================================================================
            // Fragment Shader
            // ============================================================================
            half4 particle_frag(particle_v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // Unpack colorMul, age, and speed_t
                half colorMul = (half)(i.packed.x & 0xFFFFu) * (half)(1.0 / 65535.0);
                half age = (half)f16tof32(i.packed.y & 0xFFFFu);
                half speed_t = (half)f16tof32(i.packed.y >> 16);

                // Sample texture
                half4 tex = tex2D(_MainTex, i.uv);

                // Color over lifetime (sample gradient texture with linear filtering)
                half4 tint = _ColorGradient.Sample(sampler_ColorGradient, float2(age, 0.5));

                // Color by Speed (active when speed range is set)
                if (_ColorBySpeedRange.y > _ColorBySpeedRange.x)
                {
                    half4 speed_color = _ColorBySpeedGradient.Sample(sampler_ColorBySpeedGradient, float2(speed_t, 0.5));
                    tint *= speed_color;
                }

                // Final color (apply Start Color)
                half4 color = tex * tint * _StartColor;
                color.rgb *= colorMul;
                color.a *= colorMul;

                return color;
            }
            ENDCG
        }
    }

    CustomEditor "Thry.ShaderEditor"
}
