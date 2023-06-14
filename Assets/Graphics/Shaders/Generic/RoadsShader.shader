Shader "Plarium/Roads"
{
    Properties
    {
        [Header(Main Surface)]
        _Tint("Tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_Albedo("Albedo", 2D) = "white" {}
        [Normal][NoScaleOffset]_Normal("Normal", 2D) = "bump" {}
        [NoScaleOffset]_MetallicGlossMap("MRAO", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
        [Toggle(USE_WORLD_UV)] _UseWorldUV("Use World UV", float) = 0
        _Tile("Tile", Float) = 1

        [Space(40)]
        [NoScaleOffset]_GroundSDFMask ("Ground SDF Mask", 2D) = "black" {}
        [NoScaleOffset]_GroundSurfaceMask("Ground Surface Masks", 2D) = "white" {}

        [Space(40)]
        [Header(Leaves Layer)]
        _VariationTint("Leaves Tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_Variation_Albedo("Leaves Albedo", 2D) = "black" {}
        [Normal][NoScaleOffset]_Variation_Normal("Leaves Normal", 2D) = "bump" {}
        _Variation_Tile("Leaves Tile", Float) = 0
        _Variation_Smoothness("Leaves Smoothness", Range(0, 1)) = 0.25
        _VariationTintInPuddles("Leaves In Puddles Tint", Color) = (0.7, 0.7, 0.7, 1)
        _VariationSmoothnessInPuddles("Leaves In Puddles Smoothness", Range(0, 1)) = 0.5
        _VariationMinMax("Leaves Green Min Max", Vector) = (0, 1, 1, 0)
        _SDFAlpha_MinMax("Leaves Alpha Min Max", Vector) = (0, 1, 1, 1)

        [Space(40)]
        [Header(SDF Dirt Layer)]
        _DirtEdgeOffset("Dirt Edge Offset", Range(0, 0.9)) = 0.8
        _DirtMultiplier("Dirt Multiplier", Range(1, 5)) = 1
        _DirtColor("Dirt Color", Color) = (1,1,1,1)
        _DirtSmoothness("Dirt Smoothness", Range(0, 1)) = 0.25
        _DirtTile("Dirt Tile", float) = 1

        [Space(40)]
        [Header(Decals)]
        _DecalColor("Decals Color", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_Decals_Albedo("Decals Albedo", 2D) = "black" {}
        _Decals_Smoothness("Decals Smoothness", Range(0, 1)) = 0.5
        [Normal][NoScaleOffset]_Decals_Normal("Decals Normal", 2D) = "bump" {}
        _Decals_Mask_Tile("Decals Mask Tile", Range(0, 1)) = 0.5
        _Decals_Mask_Amount("Decals Mask Amount", Range(0, 1)) = 0.5
        _Decals_Mask_Softness("Decals Mask Softness", Range(0, 1)) = 0

        [Space(40)]
        [Header(Puddles)]
        _Puddles_Water_Color ("Puddles Color", Color) = (0, 0.1226415, 0.04342584, 0.9019608)
        _PuddlesDistortion("Puddles Distortion", Range(0,1)) = 0
        _Puddles_Scale("Puddles Distortion Scale", Float) = 0.256
        _PuddlesDryColor("Puddles Dry Color", Color) = (0, 0.1226415, 0.04342584, 0.9019608)
        _PuddlesDryArea("Puddles Dry Offset", Range(0,1)) = 0
        _PuddlesDrySmoothnessMultiplier("Puddles Dry Smoothness Multiplier", Range(0, 2)) = 0.5
        _CarTrailsColor("Car Trails Tint", Color) = (0, 0, 0, 0)
        _CarTrailsSmoothness("Car Trails Smoothness", Range(0, 1)) = 0.7

        [HideInInspector]_QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector]_QueueControl("_QueueControl", Float) = -1
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "UniversalMaterialType" = "Lit"
            "IgnoreProjector" = "True"
            "ShaderModel"="4.5"
        }
        LOD 300

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

            #define SHADOWS_SHADOWMASK
            #define LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON

            #pragma multi_compile _ USE_WORLD_UV

            #pragma vertex PBRPassVertex
            #pragma fragment PBRPassFragment

            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumRealtimeLighting.hlsl"
            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumGlobalIllumination.hlsl"

            // Main.
            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
            TEXTURE2D(_MetallicGlossMap); SAMPLER(sampler_MetallicGlossMap);

            // Variation.
            TEXTURE2D(_Variation_Albedo); SAMPLER(sampler_Variation_Albedo);
            TEXTURE2D(_Variation_Normal); SAMPLER(sampler_Variation_Normal);

            // Decals.
            TEXTURE2D(_Decals_Normal); SAMPLER(sampler_Decals_Normal);
            TEXTURE2D(_Decals_Albedo); SAMPLER(sampler_Decals_Albedo);

            // Masks.
            TEXTURE2D(_GroundSurfaceMask); SAMPLER(sampler_GroundSurfaceMask);
            TEXTURE2D(_GroundSDFMask); SAMPLER(sampler_GroundSDFMask);

            CBUFFER_START(UnityPerMaterial)
                // Main.
                half4  _Tint;
                half   _Smoothness;
                half   _Tile;

                // Decals.
                half   _Decals_Mask_Softness;
                half   _Decals_Mask_Tile;
                float4  _DecalColor;
                half   _Decals_Mask_Amount;
                half   _Decals_Smoothness;

                // Puddles.
                half4  _Puddles_Water_Color;
                half   _Puddles_Scale;
                half   _PuddlesSmoothness;
                half _PuddlesDistortion;

                half  _PuddlesDryArea;
                half4 _PuddlesDryColor;
                half  _PuddlesDrySmoothnessMultiplier;

                // Roads Cars Trails.
                half4  _CarTrailsColor;
                half   _CarTrailsSmoothness;

                // Leaves.
                half4 _VariationTint;
                half   _Variation_Tile;
                half   _Variation_Smoothness;
                half3 _VariationMinMax;
                half4 _VariationTintInPuddles;
                half _VariationSmoothnessInPuddles;
                half4 _SDFAlpha_MinMax;

                // Dirt.
                half4 _DirtColor;
                half _DirtSmoothness;
                half _DirtEdgeOffset;
                half _DirtMultiplier;
                half _DirtTile;
            CBUFFER_END

            struct VertexAttributes
            {
                float4 positionOS           : POSITION;
                float3 normalOS             : NORMAL;
                float4 tangentOS            : TANGENT;
                float2 uv                   : TEXCOORD0;
                float2 staticLightmapUV     : TEXCOORD1;
                float2 uv2                  : TEXCOORD2;
                float2 uv3                  : TEXCOORD3;
                half4 color                : COLOR;
            };

            struct FragmentVaryings
            {
                float4 positionCS           : SV_POSITION;
                float4 uv_staticLightmapUV   : TEXCOORD0;
                float4 decalUV_splatUV       : TEXCOORD1;

                float3 positionWS           : TEXCOORD2;
                float3 normalWS             : TEXCOORD3;
                float4 tangentWS            : TEXCOORD4;

                half4 color_fogFactor       : COLOR;
            };

            FragmentVaryings PBRPassVertex(VertexAttributes input)
            {
                FragmentVaryings output = (FragmentVaryings)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.normalWS = normalInput.normalWS;
                output.uv_staticLightmapUV.xy = input.uv;
                output.decalUV_splatUV.xy = input.uv2;
                output.decalUV_splatUV.zw = input.uv3;
                output.color_fogFactor.rgb = input.color;

                float sign = input.tangentOS.w * GetOddNegativeScale();
                half4 tangentWS = half4(normalInput.tangentWS.xyz, sign);
                output.tangentWS = tangentWS;

                output.color_fogFactor.w = ComputeFogFactor(vertexInput.positionCS.z);

                #if defined LIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.uv_staticLightmapUV.zw);
                #endif

                return output;
            }

            inline float3 TransformTextureNormalsToWorld(float3 normalMapColor, float3 normalsWS, float4 tangentWS)
            {
                float sgn = tangentWS.w; // should be either +1 or -1
                float3 bitangent = sgn * cross(normalsWS.xyz, tangentWS.xyz);
                float3x3 tangentToWorld = float3x3(tangentWS.xyz, bitangent.xyz, normalsWS.xyz);
                float3 normals = TransformTangentToWorld(normalMapColor, tangentToWorld);
                normals = NormalizeNormalPerPixel(normals);
                return normals;
            }

            half4 PBRPassFragment(FragmentVaryings input): SV_Target0
            {
                half3 vertexColor = input.color_fogFactor.rgb;
                float2 worldPos = input.positionWS.xz;

                float2 mainSurfaceUV;
                #if USE_WORLD_UV
                    mainSurfaceUV = worldPos * _Tile;
                #else
                    mainSurfaceUV = input.uv_staticLightmapUV.xy * _Tile;
                #endif

                half4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, mainSurfaceUV) * _Tint;

                // Decals
                half4 decalsAlbedoColor = SAMPLE_TEXTURE2D(_Decals_Albedo, sampler_Decals_Albedo, input.decalUV_splatUV.xy) * _DecalColor;
                float edge1 = _Decals_Mask_Amount - _Decals_Mask_Softness;
                float edge2 = _Decals_Mask_Amount + _Decals_Mask_Softness;
                float decalsFadeMask = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, _Decals_Mask_Tile.xx * worldPos).r;
                float decal = smoothstep(edge1, edge2, decalsFadeMask);
                float decalAlpha = decal * decalsAlbedoColor.a;

                half4 decalsWithSurfaceColor = lerp(albedo, decalsAlbedoColor, decalAlpha);

                // Read Main SDF Texture
                float4 sdfMask = SAMPLE_TEXTURE2D(_GroundSDFMask, sampler_GroundSDFMask, input.decalUV_splatUV.zw);

                float2 variationUv = worldPos * _Variation_Tile.xx;
                float4 variationColor = SAMPLE_TEXTURE2D(_Variation_Albedo, sampler_Variation_Albedo, variationUv) * _VariationTint;
                float variationMask = saturate(smoothstep(_VariationMinMax.x, _VariationMinMax.y, variationColor.a * sdfMask.g));

                float sdfAlphaVariation = smoothstep(_SDFAlpha_MinMax.x, _SDFAlpha_MinMax.y, variationColor.a);
                sdfAlphaVariation *= smoothstep(_SDFAlpha_MinMax.z, _SDFAlpha_MinMax.w, sdfMask.a);
                variationMask = saturate(variationMask + sdfAlphaVariation);

                // Dirt Layer
                float dirtTexMask = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, worldPos * _DirtTile).g;
                float dirtSdf = smoothstep(_DirtEdgeOffset, 1, sdfMask.r);

                float dirtMask = saturate(dirtTexMask * dirtSdf * _DirtMultiplier) * _DirtColor.a;
                half4 withDirtColor = lerp(decalsWithSurfaceColor, _DirtColor, dirtMask);

                // Car Trail Mask.
                float carTrail  = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, input.uv_staticLightmapUV.xy).b;
                float  carTrailMask  = carTrail * vertexColor.b;
                half4 baseWithCarTrailColor = lerp(withDirtColor, withDirtColor * _CarTrailsColor, carTrailMask);

                // Puddles Mask.
                float puddleDistortion = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, worldPos * _Puddles_Scale).a;
                float2 puddleUV    = input.decalUV_splatUV.zw + puddleDistortion * _PuddlesDistortion;
                float puddleMaskTexture = SAMPLE_TEXTURE2D(_GroundSDFMask, sampler_GroundSDFMask, puddleUV).b;
                float puddleMask = smoothstep(0, _PuddlesDryArea, puddleMaskTexture) * puddleMaskTexture;

                // Select Puddles masks from single channels.
                float puddleBorderMask = saturate(clamp(puddleMask, 0.0, 0.2) * 4);
                float puddleWaterMask = saturate((clamp(puddleMask, 0.4, 1) - 0.4) * 2.4);

                half4 borderPuddleColor = lerp(baseWithCarTrailColor, baseWithCarTrailColor * _PuddlesDryColor, puddleBorderMask * _PuddlesDryColor.a);
                half4 finalColor = lerp(borderPuddleColor,  _Puddles_Water_Color, puddleWaterMask * _Puddles_Water_Color.a);

                // Apply Leaves on top of everything
                finalColor = lerp(finalColor, variationColor, variationMask);
                finalColor = lerp(finalColor, variationColor * _VariationTintInPuddles, variationMask * puddleWaterMask);

                // Normal combining
                float4 mainNormal   = SAMPLE_TEXTURE2D(_Normal, sampler_Normal, mainSurfaceUV );
                mainNormal.rgb      = UnpackNormal(mainNormal);

                float4 normalVar    = SAMPLE_TEXTURE2D(_Variation_Normal, sampler_Variation_Normal, variationUv);
                normalVar.rgb       = UnpackNormal(normalVar);

                float4 decalNormal  = SAMPLE_TEXTURE2D(_Decals_Normal, sampler_Decals_Normal, input.decalUV_splatUV.xy);
                decalNormal.xyz     = UnpackNormal(decalNormal);

                mainNormal.xyz      = lerp(mainNormal.xyz, decalNormal.xyz, decalAlpha);
                float3 normal       = lerp(mainNormal.xyz, float3(0,0,1), puddleWaterMask);

                // Apply Leaves normal on top;
                normal = lerp(normal.xyz, normalVar.xyz, variationMask);

                normal = TransformTextureNormalsToWorld(normal, input.normalWS.xyz, input.tangentWS);

                // Mix Main Smoothness
                half4 mrao = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, mainSurfaceUV);
                half mainSmoothness  = mrao.g * _Smoothness;
                half decalMainSmoothness = lerp(mainSmoothness, _Decals_Smoothness, decalAlpha);
                half withDirtSmoothness = lerp(decalMainSmoothness, _DirtSmoothness, dirtMask);
                half wetSmoothness = lerp(withDirtSmoothness, _CarTrailsSmoothness, carTrailMask);

                wetSmoothness = lerp(wetSmoothness, wetSmoothness * _PuddlesDrySmoothnessMultiplier, puddleBorderMask);

                half withVariationSmoothness   = lerp(wetSmoothness, _Variation_Smoothness, variationMask);
                half finalSmoothness = lerp(withVariationSmoothness, 1.0, puddleWaterMask);
                finalSmoothness = lerp(finalSmoothness, _VariationSmoothnessInPuddles, puddleWaterMask * variationMask);

                PBRMaterialData materialData = (PBRMaterialData)0;
                materialData.albedo = finalColor.rgb;
                materialData.metallic = 0.0;
                materialData.smoothness = finalSmoothness;
                materialData.occlusion = saturate(mrao.b + variationMask);
                materialData.normalWS = normal;
                materialData.positionWS = input.positionWS.xyz;
                materialData.bakedGI = 1.0;
                materialData.additionalLightColor = half3(0.0, 0.0, 0.0);

                #if defined LIGHTMAP_ON
                    materialData.bakedGI = SampleLightmapWithoutNormal(input.uv_staticLightmapUV.zw);
                #endif

                half4 shadowCoord = TransformWorldToShadowCoord(materialData.positionWS);
                half4 shadowMask = half4(1,1,1,1);

                #if defined LIGHTMAP_ON
                    shadowMask = SAMPLE_SHADOWMASK(input.uv_staticLightmapUV.zw);
                #endif
                Light mainLight = GetMainLight(shadowCoord, materialData.positionWS, shadowMask);

                half4 color = GetPBRLighting(materialData, mainLight);
                color.rgb = MixFog(color.rgb, input.color_fogFactor.w);
                return color;
            }
            ENDHLSL
        }

         //This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            Cull Off

            HLSLPROGRAM
            #pragma target 2.0
            #pragma shader_feature EDITOR_VISUALIZATION
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaLit

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            TEXTURE2D(_Albedo); SAMPLER(sampler_Albedo);
            TEXTURE2D(_MetallicGlossMap); SAMPLER(sampler_MetallicGlossMap);
            TEXTURE2D(_Variation_Albedo); SAMPLER(sampler_Variation_Albedo);
            TEXTURE2D(_Decals_Albedo); SAMPLER(sampler_Decals_Albedo);
            TEXTURE2D(_GroundSurfaceMask); SAMPLER(sampler_GroundSurfaceMask);
            TEXTURE2D(_GroundSDFMask); SAMPLER(sampler_GroundSDFMask);

            CBUFFER_START(UnityPerMaterial)
                // Main.
                half4  _Tint;
                half   _Smoothness;
                half   _Tile;

                // Decals.
                half   _Decals_Mask_Softness;
                half   _Decals_Mask_Tile;
                float4  _DecalColor;
                half   _Decals_Mask_Amount;
                half   _Decals_Smoothness;

                // Puddles.
                half4  _Puddles_Water_Color;
                half   _Puddles_Scale;
                half   _PuddlesSmoothness;
                half _PuddlesDistortion;

                half  _PuddlesDryArea;
                half4 _PuddlesDryColor;
                half  _PuddlesDrySmoothnessMultiplier;

                // Roads Cars Trails.
                half4  _CarTrailsColor;
                half   _CarTrailsSmoothness;

                // Leaves.
                half4 _VariationTint;
                half   _Variation_Tile;
                half   _Variation_Smoothness;
                half3 _VariationMinMax;
                half4 _VariationTintInPuddles;
                half _VariationSmoothnessInPuddles;
                half4 _SDFAlpha_MinMax;

                // Dirt.
                half4 _DirtColor;
                half _DirtSmoothness;
                half _DirtEdgeOffset;
                half _DirtMultiplier;
                half _DirtTile;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS            : TANGENT;
                float2 uv                   : TEXCOORD0;
                float2 staticLightmapUV     : TEXCOORD1;
                float2 decalUV2             : TEXCOORD2;
                float2 splatUV3             : TEXCOORD3;
                half4 color                : COLOR;
                float2 vizUV : TEXCOORD4;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float2 uv           : TEXCOORD0;

                float4 decalUV_splatUV       : TEXCOORD1;
                float3 positionWS           : TEXCOORD2;

                #ifdef EDITOR_VISUALIZATION
                    float2 VizUV        : TEXCOORD3;
                    float4 LightCoord   : TEXCOORD4;
                #endif

                half3 color : COLOR0;
            };

            Varyings UniversalVertexMeta(Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = UnityMetaVertexPosition(input.positionOS.xyz, input.staticLightmapUV, input.vizUV);
                output.uv = input.uv;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

                output.positionWS = vertexInput.positionWS;
                output.decalUV_splatUV.xy = input.decalUV2;
                output.decalUV_splatUV.zw = input.splatUV3;
                output.color = input.color;

                #ifdef EDITOR_VISUALIZATION
                    UnityEditorVizData(input.positionOS.xyz, input.uv, input.staticLightmapUV, input.vizUV, output.VizUV, output.LightCoord);
                #endif
                return output;
            }

            half4 UniversalFragmentMeta(Varyings fragIn, MetaInput metaInput)
            {
                #ifdef EDITOR_VISUALIZATION
                    metaInput.VizUV = fragIn.VizUV;
                    metaInput.LightCoord = fragIn.LightCoord;
                #endif

                return UnityMetaFragment(metaInput);
            }

            half4 UniversalFragmentMetaLit(Varyings input) : SV_Target
            {
                half3 vertexColor = input.color.rgb;
                float2 worldPos = input.positionWS.xz;

                float2 mainSurfaceUV = mainSurfaceUV = input.uv.xy * _Tile;

                half4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, mainSurfaceUV) * _Tint;

                // Decals
                half4 decalsAlbedoColor = SAMPLE_TEXTURE2D(_Decals_Albedo, sampler_Decals_Albedo, input.decalUV_splatUV.xy) * _DecalColor;
                float edge1 = _Decals_Mask_Amount - _Decals_Mask_Softness;
                float edge2 = _Decals_Mask_Amount + _Decals_Mask_Softness;
                float decalsFadeMask = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, _Decals_Mask_Tile.xx * worldPos).r;
                float decal = smoothstep(edge1, edge2, decalsFadeMask);
                float decalAlpha = decal * decalsAlbedoColor.a;

                half4 decalsWithSurfaceColor = lerp(albedo, decalsAlbedoColor, decalAlpha);

                // Read Main SDF Texture
                float4 sdfMask = SAMPLE_TEXTURE2D(_GroundSDFMask, sampler_GroundSDFMask, input.decalUV_splatUV.zw);

                float2 variationUv = worldPos * _Variation_Tile.xx;
                float4 variationColor = SAMPLE_TEXTURE2D(_Variation_Albedo, sampler_Variation_Albedo, variationUv) * _VariationTint;
                float variationMask = saturate(smoothstep(_VariationMinMax.x, _VariationMinMax.y, variationColor.a * sdfMask.g));

                float sdfAlphaVariation = smoothstep(_SDFAlpha_MinMax.x, _SDFAlpha_MinMax.y, variationColor.a);
                sdfAlphaVariation *= smoothstep(_SDFAlpha_MinMax.z, _SDFAlpha_MinMax.w, sdfMask.a);
                variationMask = saturate(variationMask + sdfAlphaVariation);

                // Dirt Layer
                float dirtTexMask = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, worldPos * _DirtTile).g;
                float dirtSdf = smoothstep(_DirtEdgeOffset, 1, sdfMask.r);

                float dirtMask = saturate(dirtTexMask * dirtSdf * _DirtMultiplier) * _DirtColor.a;
                half4 withDirtColor = lerp(decalsWithSurfaceColor, _DirtColor, dirtMask);

                // Car Trail Mask.
                float carTrail  = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, input.uv.xy).b;
                float  carTrailMask  = carTrail * vertexColor.b;
                half4 baseWithCarTrailColor = lerp(withDirtColor, withDirtColor * _CarTrailsColor, carTrailMask);

                // Puddles Mask.
                float puddleDistortion = SAMPLE_TEXTURE2D(_GroundSurfaceMask, sampler_GroundSurfaceMask, worldPos * _Puddles_Scale).a;
                float2 puddleUV    = input.decalUV_splatUV.zw + puddleDistortion * _PuddlesDistortion;
                float puddleMaskTexture = SAMPLE_TEXTURE2D(_GroundSDFMask, sampler_GroundSDFMask, puddleUV).b;
                float puddleMask = smoothstep(0, _PuddlesDryArea, puddleMaskTexture) * puddleMaskTexture;

                // Select Puddles masks from single channels.
                float puddleBorderMask = saturate(clamp(puddleMask, 0.0, 0.2) * 4);
                float puddleWaterMask = saturate((clamp(puddleMask, 0.4, 1) - 0.4) * 2.4);

                half4 borderPuddleColor = lerp(baseWithCarTrailColor, baseWithCarTrailColor * _PuddlesDryColor, puddleBorderMask * _PuddlesDryColor.a);
                half4 finalColor = lerp(borderPuddleColor,  _Puddles_Water_Color, puddleWaterMask * _Puddles_Water_Color.a);

                // Apply Leaves on top of everything
                finalColor = lerp(finalColor, variationColor, variationMask);
                finalColor = lerp(finalColor, variationColor * _VariationTintInPuddles, variationMask * puddleWaterMask);

                // Mix Main Smoothness
                half4 mrao = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, mainSurfaceUV);
                half mainSmoothness  = mrao.g * _Smoothness;
                half decalMainSmoothness = lerp(mainSmoothness, _Decals_Smoothness, decalAlpha);
                half withDirtSmoothness = lerp(decalMainSmoothness, _DirtSmoothness, dirtMask);
                half wetSmoothness = lerp(withDirtSmoothness, _CarTrailsSmoothness, carTrailMask);

                wetSmoothness = lerp(wetSmoothness, wetSmoothness * _PuddlesDrySmoothnessMultiplier, puddleBorderMask);

                half withVariationSmoothness   = lerp(wetSmoothness, _Variation_Smoothness, variationMask);
                half finalSmoothness = lerp(withVariationSmoothness, 1.0, puddleWaterMask);
                finalSmoothness = lerp(finalSmoothness, _VariationSmoothnessInPuddles, puddleWaterMask * variationMask);

                BRDFData brdfData;
                half alpha = 1;
                half3 spec = 1;
                half metallic = 0.0;
                InitializeBRDFData(finalColor, metallic, spec, finalSmoothness, alpha, brdfData);

                MetaInput metaInput;
                metaInput.Albedo = brdfData.diffuse + brdfData.specular * brdfData.roughness * 0.5;
                metaInput.Emission = 0;
                return UniversalFragmentMeta(input, metaInput);
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
    CustomEditor "Game.Editor.ShaderInspectors.Roads"
}