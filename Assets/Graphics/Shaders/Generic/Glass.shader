Shader "Plarium/Glass"
{
    Properties
    {
        [MainColor] _Color("Color", Color) = (1,1,1,1)
        [MainTexture] _MainTex("Albedo", 2D) = "white" {}
        [NoScaleOffset] _MetallicGlossMap("Mask", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 1.0
        _Metallic("Metallic", Range(0.0, 1.0)) = 1.0

        [NoScaleOffset] _Interior2DAtlas("Interior atlas", 2D) = "white" {}
        [Toggle] _FakeDepthToggle("Fake Depth Toggle", Float) = 0
        _AtlasSize("Atlas size", Vector) = (1, 1, 1, 1)
        _InteriorDepth("Interior depth", Float) = 0
        [NoScaleOffset] _InteriorCubemapArray ("Interior Cubemap array (HDR)", CubeArray) = "grey" {}
        _InteriorColor("Interior color", Color) = (1,1,1,1)

        [NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        // BlendMode
        _Surface("__surface", Float) = 0.0
        _Blend("__mode", Float) = 0.0
        _Cull("__cull", Float) = 2.0
        [ToggleUI] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _BlendOp("__blendop", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _SrcBlendAlpha("__srcA", Float) = 1.0
        [HideInInspector] _DstBlendAlpha("__dstA", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _AlphaToMask("__alphaToMask", Float) = 0.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"
        }
        LOD 300

        Blend [_SrcBlend][_DstBlend], [_SrcBlendAlpha][_DstBlendAlpha]
        ZWrite [_ZWrite]
        Cull [_Cull]

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fog

            #pragma multi_compile _ METALLICGLOSSMAP
            #pragma multi_compile _ BUMPMAP
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma multi_compile_fragment _ _INTERIOR_ATLAS_2D _INTERIOR_ATLAS_CUBE

            #define MAIN_LIGHT_CALCULATE_SHADOWS
            #define SHADOWS_SHADOWMASK

            #if defined LIGHTMAP_ON
            #define LIGHTMAP_SHADOW_MIXING
            #endif


            #pragma vertex PBRPassVertex
            #pragma fragment PBRPassFragment



            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumRealtimeLighting.hlsl"
            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumGlobalIllumination.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            TEXTURE2D(_MetallicGlossMap);
            SAMPLER(sampler_MetallicGlossMap);
            TEXTURECUBE_ARRAY(_InteriorCubemapArray);
            TEXTURE2D(_Interior2DAtlas);

            SAMPLER(SamplerState_Linear_Repeat);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color;
            half _Smoothness;
            half _Metallic;
            half _Surface;
            half _Cutoff;
            float4 _AtlasSize;
            float _InteriorDepth;
            half4 _InteriorColor;
            CBUFFER_END

            struct VertexAttributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
            };

            struct FragmentVaryings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : NORMAL;

                half4 vertexSH_fogFactor : TEXCOORD3;
                float2 staticLightmapUV : TEXCOORD6;

                #ifdef BUMPMAP
                    half4 tangentWS                 : TEXCOORD4;    // xyz: tangent, w: sign
                #endif
                float3 tangentViewDir : TANGENT;
                half3 vertexLighting : TEXCOORD5;
            };

            float Hash1(uint n)
            {
                // Integer hash copied from Hugo Elias.
                n = (n << 13U) ^ n;
                n = n * (n * n * 15731U + 789221U) + 1376312589U;
                return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
            }

            float3 TextureCoord2InteriorCube(float2 uv, float3 viewDirection, float depth)
            {
                uv = frac(uv);
                uv = uv * 2.0 - 1.0;

                half3 cubeUV = half3(uv.x, uv.y, -depth);
                half3 id = rcp(viewDirection);
                half3 absID = abs(id);

                half3 k = absID - cubeUV * id;
                half kMin = min(min(k.x, k.y), k.z);
                half3 kMinTangent = kMin.xxx * viewDirection;

                half3 pos = cubeUV + kMinTangent;
                return pos;
            }

            float2 TextureCoord2Interior2dAtlas(float2 uv, float3 viewDirection, float depth)
            {
                depth = clamp(depth, 0.01, 0.99);
                float depthScale = rcp(depth) - 1.0;

                float3 viewRayStartPosBoxSpace = float3(uv * 2.0 - 1.0, -1.0);
                float3 viewRayDirBoxSpace = viewDirection * float3(1.0, 1.0, -depthScale);

                float3 viewRayDirBoxSpaceRcp = rcp(viewRayDirBoxSpace);

                float3 hitRayLengthForSeperatedAxis = abs(viewRayDirBoxSpaceRcp) - viewRayStartPosBoxSpace *
                    viewRayDirBoxSpaceRcp;
                float shortestHitRayLength = min(min(hitRayLengthForSeperatedAxis.x, hitRayLengthForSeperatedAxis.y),
                                                 hitRayLengthForSeperatedAxis.z);
                float3 hitPosBoxSpace = viewRayStartPosBoxSpace + shortestHitRayLength * viewRayDirBoxSpace;

                float interp = hitPosBoxSpace.z * 0.5 + 0.5;

                float realZ = saturate(interp) / depthScale + 1;
                interp = 1.0 - (1.0 / realZ);
                interp *= depthScale + 1.0;
                float2 interiorUV = hitPosBoxSpace.xy * lerp(1.0, 1.0 - depth, interp);

                return interiorUV * 0.5 + 0.5;
            }

            FragmentVaryings PBRPassVertex(VertexAttributes input)
            {
                FragmentVaryings output = (FragmentVaryings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = normalInput.normalWS;
                output.positionWS = vertexInput.positionWS;

                #ifdef BUMPMAP
                    real sign = input.tangentOS.w * GetOddNegativeScale();
                    half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                    output.tangentWS = tangentWS;
                #endif

                output.vertexSH_fogFactor.xyz = SampleSH(output.normalWS.xyz);
                output.vertexSH_fogFactor.w = ComputeFogFactor(vertexInput.positionCS.z);

                float tangentSign = input.tangentOS.w * unity_WorldTransformParams.w;
                float3 bitangent = cross(input.normalOS, input.tangentOS.xyz) * tangentSign;
                float3x3 tbn = float3x3(input.tangentOS.xyz, bitangent, input.normalOS);
                float3 camPosObjectSpace = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
                float3 viewDirObjectSpace = normalize(input.positionOS.xyz - camPosObjectSpace);
                output.tangentViewDir = mul(tbn, viewDirObjectSpace);

                #if defined LIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
                #endif

                #ifdef _ADDITIONAL_LIGHTS
                    output.vertexLighting = GetVertexLighting(vertexInput.positionWS, normalInput.normalWS);
                #else
                    output.vertexLighting = half3(0.0h, 0.0h, 0.0h);
                #endif

                return output;
            }

            inline half3 TransformTextureNormalsToWorld(half4 normalsColors, half3 normalsWS, half4 tangentWS)
            {
                half3 normalTS = UnpackNormal(normalsColors);
                float sgn = tangentWS.w; // should be either +1 or -1
                float3 bitangent = sgn * cross(normalsWS.xyz, tangentWS.xyz);
                half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangent.xyz, normalsWS.xyz);
                half3 normals = TransformTangentToWorld(normalTS, tangentToWorld);
                normals = NormalizeNormalPerPixel(normals);
                return normals;
            }

            half Alpha(half albedoAlpha, half4 color, half cutoff)
            {
                half alpha = albedoAlpha * color.a;
                alpha = AlphaDiscard(alpha, cutoff);

                return alpha;
            }

            half4 PBRPassFragment(FragmentVaryings input): SV_Target0
            {
                PBRMaterialData materialData;

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _Color;
                half4 interior = _InteriorColor;

                #if _INTERIOR_ATLAS_2D
                    half indx = floor(input.uv.x);
                    float2 interiorUV = TextureCoord2Interior2dAtlas(frac(input.uv), input.tangentViewDir, _InteriorDepth);
                    half2 tileScale = rcp(_AtlasSize.xy);
                    interiorUV *= tileScale;
                    half tilex = floor(indx % _AtlasSize.x);
                    half tiley = floor(indx / _AtlasSize.y);
                    interiorUV += float2(tileScale.x, tileScale.y) * float2(tilex, tiley);
                    interior = SAMPLE_TEXTURE2D(_Interior2DAtlas,  SamplerState_Linear_Repeat, interiorUV.xy) * _InteriorColor;
                #elif _INTERIOR_ATLAS_CUBE
                    half tileId = Hash1(0) * _AtlasSize.x * _AtlasSize.y;
                    float3 interiorUV = TextureCoord2InteriorCube(frac(input.uv), input.tangentViewDir, _InteriorDepth * -1);
                    interior = SAMPLE_TEXTURECUBE_ARRAY(_InteriorCubemapArray, SamplerState_Linear_Repeat, interiorUV, tileId) * _InteriorColor;
                #else
                    interior *= SAMPLE_TEXTURE2D(_Interior2DAtlas, SamplerState_Linear_Repeat, input.uv / clamp(_AtlasSize.xy, 0.001, 64));
                #endif


                materialData.albedo = lerp(interior, albedo.rgb, albedo.a);

                #ifdef METALLICGLOSSMAP
                    half4 mrao = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv);
                    materialData.metallic = mrao.r * _Metallic;
                    materialData.smoothness = mrao.g * _Smoothness;
                    materialData.occlusion = mrao.b;
                #else
                    materialData.metallic = _Metallic;
                    materialData.smoothness = _Smoothness;
                    materialData.occlusion = 1.0;
                #endif

                #ifdef BUMPMAP
                    half3 normals = TransformTextureNormalsToWorld(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv),
                                                                    input.normalWS.xyz, input.tangentWS);
                    materialData.normalWS = normals;
                #else
                    materialData.normalWS = input.normalWS.xyz;
                #endif

                materialData.positionWS = input.positionWS.xyz;
                materialData.bakedGI = input.vertexSH_fogFactor.xyz;
                half4 shadowParams = GetMainLightShadowParams();

                #if defined LIGHTMAP_ON
                    materialData.bakedGI = SampleLightmapWithoutNormal(input.staticLightmapUV);
                #endif

                half4 shadowCoord = TransformWorldToShadowCoord(materialData.positionWS);
                half4 shadowMask = half4(1,1,1,1);
                #if defined LIGHTMAP_ON
                    shadowMask = SAMPLE_SHADOWMASK(input.staticLightmapUV);
                #endif
                Light mainLight = GetMainLight(shadowCoord, materialData.positionWS, shadowMask);
                materialData.additionalLightColor = input.vertexLighting;

                half4 color = GetPBRLighting(materialData, mainLight);

                color.rgb = MixFog(color.rgb, input.vertexSH_fogFactor.w);
                half alpha = Alpha(albedo.a, _Color, _Cutoff);
                color.a = OutputAlpha(alpha, IsSurfaceTypeTransparent(_Surface));

                return color;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // Default Shadow Pass
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            // Shadow Casting Light geometric parameters. These variables are used when applying the shadow Normal Bias and are set by UnityEngine.Rendering.Universal.ShadowUtils.SetupShadowCasterConstantBuffer in com.unity.render-pipelines.universal/Runtime/ShadowUtils.cs
            // For Directional lights, _LightDirection is used when applying shadow Normal Bias.
            // For Spot lights and Point lights, _LightPosition is used to compute the actual light direction because it is different at each shadow caster geometry vertex.
            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDirectionWS = normalize(_LightPosition - positionWS);
                #else
                float3 lightDirectionWS = _LightDirection;
                #endif

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

                #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 ShadowPassFragment() : SV_TARGET { return 0; }
            ENDHLSL
        }
    }
    CustomEditor "Game.Editor.ShaderInspectors.Glass"
}