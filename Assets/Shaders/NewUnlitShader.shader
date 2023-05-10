Shader "WetRoadsShader"
{
    Properties
    {
        _Tint("Tint", Color) = (1, 1, 1, 1)
        [NoScaleOffset]_Albedo("Albedo", 2D) = "white" {}
        [Normal][NoScaleOffset]_Normal("Normal", 2D) = "bump" {}
        [NoScaleOffset]_MRAO("MRAO", 2D) = "black" {}
        _Smoothness_Multiplier("Smoothness Multiplier", Range(0, 1)) = 1
        _Tile("Tile", Float) = 1
        [NoScaleOffset]_Variation_Albedo("Variation Albedo", 2D) = "black" {}
        [Normal][NoScaleOffset]_Variation_Normal("Variation Normal", 2D) = "bump" {}
        _Variation_Tile("Variation Tile", Float) = 0
        _Variation_Smoothness("Variation Smoothness", Range(0, 1)) = 0.5
        [NoScaleOffset]_Puddle("Puddle", 2D) = "white" {}
        _Puddles_Depth("Puddles Depth", Range(0, 1)) = 0.8
        _Puddles_Scale("Puddles Scale", Float) = 1
        _Puddles_Water_Color("Puddles Water Color", Color) = (0, 0.1226415, 0.04342584, 0.9019608)
        _Puddles_Wet_Surface_Smoothness("Puddles Wet Surface Smoothness", Range(0, 1)) = 0.7
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
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Opaque"
            "UniversalMaterialType" = "Lit"
            "Queue"="Geometry"
            "ShaderGraphShader"="true"
            "ShaderGraphTargetId"="UniversalLitSubTarget"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
        
            Cull Back
            Blend One Zero
            ZTest LEqual
            ZWrite On
 
        HLSLPROGRAM

        #pragma target 2.0
        //#pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag

        // Keywords
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
        #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
        #pragma multi_compile_fragment _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
        #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
        #pragma multi_compile_fragment _ _LIGHT_LAYERS
        #pragma multi_compile_fragment _ DEBUG_DISPLAY
        #pragma multi_compile_fragment _ _LIGHT_COOKIES
        // GraphKeywords: <None>
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_VIEWDIRECTION_WS
        #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
        #define VARYINGS_NEED_SHADOW_COORD
        #define FEATURES_GRAPH_VERTEX
        #define SHADERPASS SHADERPASS_FORWARD
        #define _FOG_FRAGMENT 1
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        float4x4 _MobileShadowMatrix;
        
        CBUFFER_START(UnityPerMaterial)
            float4 _Variation_Normal_TexelSize;
            float4 _MobileShadowColor;
            float _Puddles_Wet_Surface_Smoothness;
            float _Smoothness_Multiplier;
            float4 _Tint;
            float4 _Normal_TexelSize;
            float4 _MRAO_TexelSize;
            float4 _Albedo_TexelSize;
            float _Tile;
            float _Puddles_Scale;
            float4 _Puddles_Water_Color;
            float4 _Puddle_TexelSize;
            float4 _Variation_Albedo_TexelSize;
            float _Variation_Tile;
            float _Variation_Smoothness;
            float _Puddles_Depth;
        CBUFFER_END
        
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Variation_Normal);
        SAMPLER(sampler_Variation_Normal);
        TEXTURE2D(_Normal);
        SAMPLER(sampler_Normal);
        TEXTURE2D(_MRAO);
        SAMPLER(sampler_MRAO);
        TEXTURE2D(_Albedo);
        SAMPLER(sampler_Albedo);
        TEXTURE2D(_Puddle);
        SAMPLER(sampler_Puddle);
        TEXTURE2D(_Variation_Albedo);
        SAMPLER(sampler_Variation_Albedo);
        TEXTURE2D(_BlurShadow);       
        SAMPLER(sampler_BlurShadow);
        TEXTURE2D(_ReflectionTex);       
        SAMPLER(sampler_ReflectionTex); 
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;
        };
        
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS : TEXCOORD0;
             float3 normalWS : TEXCOORD1;
             float4 tangentWS : TEXCOORD2;
             float4 texCoord0 : TEXCOORD3;
             float3 viewDirectionWS : TEXCOORD4;
             
            #if defined(LIGHTMAP_ON)
                float2 staticLightmapUV : TEXCOORD5;
            #endif
            
            float4 fogFactorAndVertexLight : TEXCOORD6;
             
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                float4 shadowCoord : TEXCOORD7;
            #endif
            
            float4 reflectionUV : TEXCOORD8;
        };
        
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
        };
        
        inline half4 ComputeReflectionUV(half4 pos)
        {
            half4 o = pos * 0.5f;
            o.xy = half2(o.x, o.y * _ProjectionParams.x) + o.w;
            o.zw = pos.zw;
            return o;
        }

        Varyings vert(Attributes input)
        {
            Varyings output = (Varyings)0;
            VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
            float3 positionWS = TransformObjectToWorld(input.positionOS);
            float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            float4 tangentWS = float4(TransformObjectToWorldDir(input.tangentOS.xyz), input.tangentOS.w);
                        
            output.positionWS = positionWS;
            output.normalWS = normalWS;         // normalized in TransformObjectToWorldNormal()
            output.tangentWS = tangentWS;       // normalized in TransformObjectToWorldDir()
            output.positionCS = TransformWorldToHClip(positionWS);
            output.texCoord0 = input.uv0;
            // Need the unnormalized direction here as otherwise interpolation is incorrect.
            // It is normalized after interpolation in the fragment shader.
            output.viewDirectionWS = GetWorldSpaceViewDir(positionWS);
            
            #if (SHADERPASS == SHADERPASS_FORWARD) || (SHADERPASS == SHADERPASS_GBUFFER)
                OUTPUT_LIGHTMAP_UV(input.uv1, unity_LightmapST, output.staticLightmapUV);
            #endif
            
            #ifdef VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
                half fogFactor = 0;
            #if !defined(_FOG_FRAGMENT)
                    fogFactor = ComputeFogFactor(output.positionCS.z);
            #endif
                half3 vertexLight = VertexLighting(positionWS, normalWS);
                output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
            #endif
            
            #if defined(VARYINGS_NEED_SHADOW_COORD) && defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                output.shadowCoord = GetShadowCoord(vertexInput);
            #endif
            
            output.reflectionUV = ComputeReflectionUV(output.positionCS);

            return output;
        }
        
        
        half4 UniversalFragmentPBR2(InputData inputData, SurfaceData surfaceData)
        {
            bool specularHighlightsOff = false;

            BRDFData brdfData;
        
            // NOTE: can modify "surfaceData"...
            InitializeBRDFData(surfaceData, brdfData);
        
            // Clear-coat calculation...
            BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
            half4 shadowMask = CalculateShadowMask(inputData);
            AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
            uint meshRenderingLayers = GetMeshRenderingLightLayer();
            Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);
        
            // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
            MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);
        
            LightingData lightingData = CreateLightingData(inputData, surfaceData);
        
            lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                                      inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                                      inputData.normalWS, inputData.viewDirectionWS);
        
            if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
            {
                lightingData.mainLightColor = LightingPhysicallyBased(brdfData, brdfDataClearCoat,
                                                                      mainLight,
                                                                      inputData.normalWS, inputData.viewDirectionWS,
                                                                      surfaceData.clearCoatMask, specularHighlightsOff);
            }
        
            lightingData.vertexLightingColor = 0;
        
            return CalculateFinalColor(lightingData, surfaceData.alpha);
        }
        
        
        half4 frag(Varyings unpacked) : SV_TARGET
        {                  
            SurfaceDescription surfaceDescription = (SurfaceDescription)0;
            float2 uv = unpacked.texCoord0.xy * _Tile;
            float4 albedo = SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, uv) * _Tint;
            float2 worldUV = unpacked.positionWS.xz * _Variation_Tile.xx;
            float4 variationMap = SAMPLE_TEXTURE2D(_Variation_Albedo, sampler_Variation_Albedo, worldUV);
            float variationMask = variationMap.a;
            float4 blendAlbedo = lerp(albedo, variationMap, variationMask.xxxx);
            float4 wetAlbedo = blendAlbedo * _Puddles_Water_Color;
            float2 puddlesUV = unpacked.positionWS.xz * _Puddles_Scale;
            float4 puddlesMap = SAMPLE_TEXTURE2D(_Puddle, sampler_Puddle, puddlesUV);
            float puddlesDepth = lerp(_Puddles_Water_Color[3] * 0.66, _Puddles_Water_Color[3], _Puddles_Depth * puddlesMap.a);
            float puddlesMask = puddlesMap.r * puddlesDepth;
            float4 finalColor = lerp(blendAlbedo, wetAlbedo, puddlesMask.xxxx);
            float4 mainNormal = UnpackNormal(SAMPLE_TEXTURE2D(_Normal,sampler_Normal,uv)).xyzz;
            float4 variationNormal = UnpackNormal(SAMPLE_TEXTURE2D(_Variation_Normal, sampler_Variation_Normal, worldUV)).xyzz;
            float4 blendNormal = lerp(mainNormal, variationNormal, variationMask.xxxx);
            float3 finalNormal = lerp(blendNormal.xyz, float3(0.0f, 0.0f, 1.0f), puddlesMap.xxx);
            float4 mrao = SAMPLE_TEXTURE2D(_MRAO, sampler_MRAO, uv);
            float smoothness = mrao.g * _Smoothness_Multiplier;
            float _Lerp_b3a5b75c32c04d04a251eb6516ca9208_Out_3 = lerp(smoothness, _Variation_Smoothness, variationMask);
            float _Lerp_6a60af84af884b5dbbb32fb98c7ac6ff_Out_3 = lerp(_Lerp_b3a5b75c32c04d04a251eb6516ca9208_Out_3, _Puddles_Wet_Surface_Smoothness, puddlesMap.g);
            float _Lerp_fc739f31a04341d881ae43b4903e2ff0_Out_3 = lerp(_Lerp_6a60af84af884b5dbbb32fb98c7ac6ff_Out_3, 1, puddlesMap.r);
            
            surfaceDescription.NormalTS = finalNormal;

            InputData inputData = (InputData)0;
        
            inputData.positionWS = unpacked.positionWS;
        
            #ifdef _NORMALMAP
                // IMPORTANT! If we ever support Flip on double sided materials ensure bitangent and tangent are NOT flipped.
                float crossSign = (unpacked.tangentWS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                float3 bitangent = crossSign * cross(unpacked.normalWS.xyz, unpacked.tangentWS.xyz);
        
                inputData.tangentToWorld = half3x3(unpacked.tangentWS.xyz, bitangent.xyz, unpacked.normalWS.xyz);
                #if _NORMAL_DROPOFF_TS
                    inputData.normalWS = TransformTangentToWorld(surfaceDescription.NormalTS, inputData.tangentToWorld);
                #elif _NORMAL_DROPOFF_OS
                    inputData.normalWS = TransformObjectToWorldNormal(surfaceDescription.NormalOS);
                #elif _NORMAL_DROPOFF_WS
                    inputData.normalWS = surfaceDescription.NormalWS;
                #endif
            #else
                inputData.normalWS = unpacked.normalWS;
            #endif
            inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
            inputData.viewDirectionWS = SafeNormalize(unpacked.viewDirectionWS);
        
            #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                inputData.shadowCoord = unpacked.shadowCoord;
            #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
            #else
                inputData.shadowCoord = float4(0, 0, 0, 0);
            #endif
        
            inputData.fogCoord = InitializeInputDataFog(float4(unpacked.positionWS, 1.0), unpacked.fogFactorAndVertexLight.x);
            inputData.vertexLighting = unpacked.fogFactorAndVertexLight.yzw;

            inputData.bakedGI = SAMPLE_GI(unpacked.staticLightmapUV, float3(0,0,0), inputData.normalWS);
        
            inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(unpacked.positionCS);
            inputData.shadowMask = SAMPLE_SHADOWMASK(unpacked.staticLightmapUV);
             
            SurfaceData surface;
            surface.albedo              = finalColor.xyz;
            surface.metallic            = 0;
            surface.specular            = 0;
            surface.smoothness          = _Lerp_fc739f31a04341d881ae43b4903e2ff0_Out_3,
            surface.occlusion           = mrao.b,
            surface.emission            = float3(0, 0, 0),
            surface.alpha               = 1;
            surface.normalTS            = finalNormal;
            surface.clearCoatMask       = 0;
            surface.clearCoatSmoothness = 1;
            
            float2 uvShadow = mul(_MobileShadowMatrix, float4(inputData.positionWS,1)).xy;
            
            half4 shadowsSmooth = SAMPLE_TEXTURE2D(_BlurShadow, sampler_BlurShadow, uvShadow);
            half shadowIntensity = shadowsSmooth.r * _MobileShadowColor.a;
            half3 shadow = lerp(half(1), _MobileShadowColor.rgb, shadowIntensity);    
        
            half2 reflection_uv = unpacked.reflectionUV.xy / unpacked.reflectionUV.w;
            half4 reflection = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, reflection_uv);
                    
            half4 color = UniversalFragmentPBR2(inputData, surface) * shadow.rgbb;
            color.rgb = lerp(color.rgb, reflection.rgb, reflection.a*puddlesMask);
        
            color.rgb = MixFog(color.rgb, inputData.fogCoord);
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
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define VARYINGS_NEED_NORMAL_WS
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_SHADOWCASTER
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;

        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 normalWS;
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.normalWS;
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.normalWS = input.interp0.xyz;

            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Variation_Normal_TexelSize;
        float _Puddles_Wet_Surface_Smoothness;
        float _Smoothness_Multiplier;
        float4 _Tint;
        float4 _Normal_TexelSize;
        float4 _MRAO_TexelSize;
        float4 _Albedo_TexelSize;
        float _Tile;
        float _Puddles_Scale;
        float4 _Puddles_Water_Color;
        float4 _Puddle_TexelSize;
        float4 _Variation_Albedo_TexelSize;
        float _Variation_Tile;
        float _Variation_Smoothness;
        float _Puddles_Depth;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Variation_Normal);
        SAMPLER(sampler_Variation_Normal);
        TEXTURE2D(_Normal);
        SAMPLER(sampler_Normal);
        TEXTURE2D(_MRAO);
        SAMPLER(sampler_MRAO);
        TEXTURE2D(_Albedo);
        SAMPLER(sampler_Albedo);
        TEXTURE2D(_Puddle);
        SAMPLER(sampler_Puddle);
        TEXTURE2D(_Variation_Albedo);
        SAMPLER(sampler_Variation_Albedo);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
        
        
        
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        ColorMask 0
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHONLY
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;

        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
        };
        struct SurfaceDescriptionInputs
        {
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Variation_Normal_TexelSize;
        float _Puddles_Wet_Surface_Smoothness;
        float _Smoothness_Multiplier;
        float4 _Tint;
        float4 _Normal_TexelSize;
        float4 _MRAO_TexelSize;
        float4 _Albedo_TexelSize;
        float _Tile;
        float _Puddles_Scale;
        float4 _Puddles_Water_Color;
        float4 _Puddle_TexelSize;
        float4 _Variation_Albedo_TexelSize;
        float _Variation_Tile;
        float _Variation_Smoothness;
        float _Puddles_Depth;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Variation_Normal);
        SAMPLER(sampler_Variation_Normal);
        TEXTURE2D(_Normal);
        SAMPLER(sampler_Normal);
        TEXTURE2D(_MRAO);
        SAMPLER(sampler_MRAO);
        TEXTURE2D(_Albedo);
        SAMPLER(sampler_Albedo);
        TEXTURE2D(_Puddle);
        SAMPLER(sampler_Puddle);
        TEXTURE2D(_Variation_Albedo);
        SAMPLER(sampler_Variation_Albedo);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        // GraphFunctions: <None>
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
        
        // Render State
        Cull Back
        ZTest LEqual
        ZWrite On
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        // PassKeywords: <None>
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_NORMAL_WS
        #define VARYINGS_NEED_TANGENT_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_DEPTHNORMALS
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;

        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float3 normalWS;
             float4 tangentWS;
             float4 texCoord0;
        };
        struct SurfaceDescriptionInputs
        {
             float3 TangentSpaceNormal;
             float3 WorldSpacePosition;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float3 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyzw =  input.texCoord0;
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.texCoord0 = input.interp3.xyzw;
            return output;
        }
        
        
        // --------------------------------------------------
        // Graph
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
        float4 _Variation_Normal_TexelSize;
        float _Puddles_Wet_Surface_Smoothness;
        float _Smoothness_Multiplier;
        float4 _Tint;
        float4 _Normal_TexelSize;
        float4 _MRAO_TexelSize;
        float4 _Albedo_TexelSize;
        float _Tile;
        float _Puddles_Scale;
        float4 _Puddles_Water_Color;
        float4 _Puddle_TexelSize;
        float4 _Variation_Albedo_TexelSize;
        float _Variation_Tile;
        float _Variation_Smoothness;
        float _Puddles_Depth;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Variation_Normal);
        SAMPLER(sampler_Variation_Normal);
        TEXTURE2D(_Normal);
        SAMPLER(sampler_Normal);
        TEXTURE2D(_MRAO);
        SAMPLER(sampler_MRAO);
        TEXTURE2D(_Albedo);
        SAMPLER(sampler_Albedo);
        TEXTURE2D(_Puddle);
        SAMPLER(sampler_Puddle);
        TEXTURE2D(_Variation_Albedo);
        SAMPLER(sampler_Variation_Albedo);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Lerp_float3(float3 A, float3 B, float3 T, out float3 Out)
        {
            Out = lerp(A, B, T);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 NormalTS;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            UnityTexture2D _Property_f50a905a1c824b308f39babc59a365cd_Out_0 = UnityBuildTexture2DStructNoScale(_Normal);
            float _Property_944bcee9e62544e99d28383ac97bec78_Out_0 = _Tile;
            float2 _TilingAndOffset_943c02de2e66437fb8e43b72e0213555_Out_3;
            Unity_TilingAndOffset_float(IN.uv0.xy, (_Property_944bcee9e62544e99d28383ac97bec78_Out_0.xx), float2 (0, 0), _TilingAndOffset_943c02de2e66437fb8e43b72e0213555_Out_3);
            float4 _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0 = SAMPLE_TEXTURE2D(_Property_f50a905a1c824b308f39babc59a365cd_Out_0.tex, _Property_f50a905a1c824b308f39babc59a365cd_Out_0.samplerstate, _Property_f50a905a1c824b308f39babc59a365cd_Out_0.GetTransformedUV(_TilingAndOffset_943c02de2e66437fb8e43b72e0213555_Out_3));
            _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0);
            float _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_R_4 = _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0.r;
            float _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_G_5 = _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0.g;
            float _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_B_6 = _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0.b;
            float _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_A_7 = _SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0.a;
            UnityTexture2D _Property_b4c62ef506684205ab0e7a2a7bfacd3b_Out_0 = UnityBuildTexture2DStructNoScale(_Variation_Normal);
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_R_1 = IN.WorldSpacePosition[0];
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_G_2 = IN.WorldSpacePosition[1];
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_B_3 = IN.WorldSpacePosition[2];
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_A_4 = 0;
            float2 _Vector2_a026fa279bc944bbb04aa01375c3f789_Out_0 = float2(_Split_d1fbeaf504504002b0c5bcc739a3480e_R_1, _Split_d1fbeaf504504002b0c5bcc739a3480e_B_3);
            float _Property_1d34955c16fa4bcc8e989ac70def90e2_Out_0 = _Variation_Tile;
            float2 _TilingAndOffset_c320896fac484e00bc5d286b9b04b9f5_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a026fa279bc944bbb04aa01375c3f789_Out_0, (_Property_1d34955c16fa4bcc8e989ac70def90e2_Out_0.xx), float2 (0, 0), _TilingAndOffset_c320896fac484e00bc5d286b9b04b9f5_Out_3);
            float4 _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0 = SAMPLE_TEXTURE2D(_Property_b4c62ef506684205ab0e7a2a7bfacd3b_Out_0.tex, _Property_b4c62ef506684205ab0e7a2a7bfacd3b_Out_0.samplerstate, _Property_b4c62ef506684205ab0e7a2a7bfacd3b_Out_0.GetTransformedUV(_TilingAndOffset_c320896fac484e00bc5d286b9b04b9f5_Out_3));
            _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0.rgb = UnpackNormal(_SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0);
            float _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_R_4 = _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0.r;
            float _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_G_5 = _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0.g;
            float _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_B_6 = _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0.b;
            float _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_A_7 = _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0.a;
            UnityTexture2D _Property_0be2bdae416640719811e2309ab4c544_Out_0 = UnityBuildTexture2DStructNoScale(_Variation_Albedo);
            float4 _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0be2bdae416640719811e2309ab4c544_Out_0.tex, _Property_0be2bdae416640719811e2309ab4c544_Out_0.samplerstate, _Property_0be2bdae416640719811e2309ab4c544_Out_0.GetTransformedUV(_TilingAndOffset_c320896fac484e00bc5d286b9b04b9f5_Out_3));
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_R_4 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.r;
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_G_5 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.g;
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_B_6 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.b;
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_A_7 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.a;
            float4 _Lerp_7233ad76c4094ad0a0d266f672515735_Out_3;
            Unity_Lerp_float4(_SampleTexture2D_7e216f1c96b64b39bca92682375e15b4_RGBA_0, _SampleTexture2D_de48be367a904c3bbab213ec9b2731bb_RGBA_0, (_SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_A_7.xxxx), _Lerp_7233ad76c4094ad0a0d266f672515735_Out_3);
            UnityTexture2D _Property_02920be1d8054dc0b3b2294215245899_Out_0 = UnityBuildTexture2DStructNoScale(_Puddle);
            float _Split_afe4c34948c9429b93046604f74dc746_R_1 = IN.WorldSpacePosition[0];
            float _Split_afe4c34948c9429b93046604f74dc746_G_2 = IN.WorldSpacePosition[1];
            float _Split_afe4c34948c9429b93046604f74dc746_B_3 = IN.WorldSpacePosition[2];
            float _Split_afe4c34948c9429b93046604f74dc746_A_4 = 0;
            float2 _Vector2_bfee811b0b3a4420998259071b59d11f_Out_0 = float2(_Split_afe4c34948c9429b93046604f74dc746_R_1, _Split_afe4c34948c9429b93046604f74dc746_B_3);
            float _Property_8db3c77962a24563ba7a7fc1ba7316c9_Out_0 = _Puddles_Scale;
            float2 _TilingAndOffset_31e036c88acc4b3faa7a7f56384f37df_Out_3;
            Unity_TilingAndOffset_float(_Vector2_bfee811b0b3a4420998259071b59d11f_Out_0, (_Property_8db3c77962a24563ba7a7fc1ba7316c9_Out_0.xx), float2 (0, 0), _TilingAndOffset_31e036c88acc4b3faa7a7f56384f37df_Out_3);
            float4 _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_02920be1d8054dc0b3b2294215245899_Out_0.tex, _Property_02920be1d8054dc0b3b2294215245899_Out_0.samplerstate, _Property_02920be1d8054dc0b3b2294215245899_Out_0.GetTransformedUV(_TilingAndOffset_31e036c88acc4b3faa7a7f56384f37df_Out_3));
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_R_4 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.r;
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_G_5 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.g;
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_B_6 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.b;
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_A_7 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.a;
            float3 _Lerp_5da39c199f4942b58cd71ce23bdc3255_Out_3;
            Unity_Lerp_float3((_Lerp_7233ad76c4094ad0a0d266f672515735_Out_3.xyz), IN.TangentSpaceNormal, (_SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_R_4.xxx), _Lerp_5da39c199f4942b58cd71ce23bdc3255_Out_3);
            surface.NormalTS = _Lerp_5da39c199f4942b58cd71ce23bdc3255_Out_3;
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);
        
        #ifdef HAVE_VFX_MODIFICATION
            // FragInputs from VFX come from two places: Interpolator or CBuffer.
            /* WARNING: $splice Could not find named fragment 'VFXSetFragInputs' */
        
        #endif
        
            
        
        
        
            output.TangentSpaceNormal = float3(0.0f, 0.0f, 1.0f);
        
        
            output.WorldSpacePosition = input.positionWS;
            output.uv0 = input.texCoord0;
       
                return output;
        }
        
        // --------------------------------------------------
        // Main
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"
        
        // --------------------------------------------------
        // Visual Effect Vertex Invocations
        #ifdef HAVE_VFX_MODIFICATION
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/VisualEffectVertex.hlsl"
        #endif
        
        ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }
        
        // Render State
        Cull Off
        
        // Debug
        // <None>
        
        // --------------------------------------------------
        // Pass
        
        HLSLPROGRAM
        
        // Pragmas
        #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag
        
        // DotsInstancingOptions: <None>
        // HybridV1InjectedBuiltinProperties: <None>
        
        // Keywords
        #pragma shader_feature _ EDITOR_VISUALIZATION
        // GraphKeywords: <None>
        
        // Defines
        
        #define _NORMALMAP 1
        #define _NORMAL_DROPOFF_TS 1
        #define ATTRIBUTES_NEED_NORMAL
        #define ATTRIBUTES_NEED_TANGENT
        #define ATTRIBUTES_NEED_TEXCOORD0
        #define ATTRIBUTES_NEED_TEXCOORD1
        #define ATTRIBUTES_NEED_TEXCOORD2
        #define VARYINGS_NEED_POSITION_WS
        #define VARYINGS_NEED_TEXCOORD0
        #define VARYINGS_NEED_TEXCOORD1
        #define VARYINGS_NEED_TEXCOORD2
        #define FEATURES_GRAPH_VERTEX
        /* WARNING: $splice Could not find named fragment 'PassInstancing' */
        #define SHADERPASS SHADERPASS_META
        #define _FOG_FRAGMENT 1
        /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */
        
        
        // custom interpolator pre-include
        /* WARNING: $splice Could not find named fragment 'sgci_CustomInterpolatorPreInclude' */
        
        // Includes
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        
        // --------------------------------------------------
        // Structs and Packing
        
        // custom interpolators pre packing
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPrePacking' */
        
        struct Attributes
        {
             float3 positionOS : POSITION;
             float3 normalOS : NORMAL;
             float4 tangentOS : TANGENT;
             float4 uv0 : TEXCOORD0;
             float4 uv1 : TEXCOORD1;
             float4 uv2 : TEXCOORD2;

        };
        struct Varyings
        {
             float4 positionCS : SV_POSITION;
             float3 positionWS;
             float4 texCoord0;
             float4 texCoord1;
             float4 texCoord2;
        };
        struct SurfaceDescriptionInputs
        {
             float3 WorldSpacePosition;
             float4 uv0;
        };
        struct VertexDescriptionInputs
        {
             float3 ObjectSpaceNormal;
             float3 ObjectSpaceTangent;
             float3 ObjectSpacePosition;
        };
        struct PackedVaryings
        {
             float4 positionCS : SV_POSITION;
             float3 interp0 : INTERP0;
             float4 interp1 : INTERP1;
             float4 interp2 : INTERP2;
             float4 interp3 : INTERP3;
        };
        
        PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            ZERO_INITIALIZE(PackedVaryings, output);
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyzw =  input.texCoord0;
            output.interp2.xyzw =  input.texCoord1;
            output.interp3.xyzw =  input.texCoord2;
            return output;
        }
        
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.texCoord0 = input.interp1.xyzw;
            output.texCoord1 = input.interp2.xyzw;
            output.texCoord2 = input.interp3.xyzw;
            return output;
        }
        
        // Graph Properties
        CBUFFER_START(UnityPerMaterial)
            float4 _Variation_Normal_TexelSize;
            float _Puddles_Wet_Surface_Smoothness;
            float _Smoothness_Multiplier;
            float4 _Tint;
            float4 _Normal_TexelSize;
            float4 _MRAO_TexelSize;
            float4 _Albedo_TexelSize;
            float _Tile;
            float _Puddles_Scale;
            float4 _Puddles_Water_Color;
            float4 _Puddle_TexelSize;
            float4 _Variation_Albedo_TexelSize;
            float _Variation_Tile;
            float _Variation_Smoothness;
            float _Puddles_Depth;
        CBUFFER_END
        
        // Object and Global properties
        SAMPLER(SamplerState_Linear_Repeat);
        TEXTURE2D(_Variation_Normal);
        SAMPLER(sampler_Variation_Normal);
        TEXTURE2D(_Normal);
        SAMPLER(sampler_Normal);
        TEXTURE2D(_MRAO);
        SAMPLER(sampler_MRAO);
        TEXTURE2D(_Albedo);
        SAMPLER(sampler_Albedo);
        TEXTURE2D(_Puddle);
        SAMPLER(sampler_Puddle);
        TEXTURE2D(_Variation_Albedo);
        SAMPLER(sampler_Variation_Albedo);
        
        // Graph Includes
        // GraphIncludes: <None>
        
        // -- Property used by ScenePickingPass
        #ifdef SCENEPICKINGPASS
        float4 _SelectionID;
        #endif
        
        // -- Properties used by SceneSelectionPass
        #ifdef SCENESELECTIONPASS
        int _ObjectId;
        int _PassValue;
        #endif
        
        // Graph Functions
        
        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }
        
        void Unity_Multiply_float4_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }
        
        void Unity_Multiply_float_float(float A, float B, out float Out)
        {
            Out = A * B;
        }
        
        void Unity_Lerp_float(float A, float B, float T, out float Out)
        {
            Out = lerp(A, B, T);
        }
        
        // Custom interpolators pre vertex
        /* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */
        
        // Graph Vertex
        struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };
        
        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            description.Position = IN.ObjectSpacePosition;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }
        
        // Custom interpolators, pre surface
        #ifdef FEATURES_GRAPH_VERTEX
        Varyings CustomInterpolatorPassThroughFunc(inout Varyings output, VertexDescription input)
        {
        return output;
        }
        #define CUSTOMINTERPOLATOR_VARYPASSTHROUGH_FUNC
        #endif
        
        // Graph Pixel
        struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
        };
        
        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_30a1798db0aa4297b3aa18cff136a476_Out_0 = _Tint;
            UnityTexture2D _Property_56d88a19967c4b7697f7c6f197ed6563_Out_0 = UnityBuildTexture2DStructNoScale(_Albedo);
            float _Property_944bcee9e62544e99d28383ac97bec78_Out_0 = _Tile;
            float2 _TilingAndOffset_943c02de2e66437fb8e43b72e0213555_Out_3;
            Unity_TilingAndOffset_float(IN.uv0.xy, (_Property_944bcee9e62544e99d28383ac97bec78_Out_0.xx), float2 (0, 0), _TilingAndOffset_943c02de2e66437fb8e43b72e0213555_Out_3);
            float4 _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_RGBA_0 = SAMPLE_TEXTURE2D(_Property_56d88a19967c4b7697f7c6f197ed6563_Out_0.tex, _Property_56d88a19967c4b7697f7c6f197ed6563_Out_0.samplerstate, _Property_56d88a19967c4b7697f7c6f197ed6563_Out_0.GetTransformedUV(_TilingAndOffset_943c02de2e66437fb8e43b72e0213555_Out_3));
            float _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_R_4 = _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_RGBA_0.r;
            float _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_G_5 = _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_RGBA_0.g;
            float _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_B_6 = _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_RGBA_0.b;
            float _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_A_7 = _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_RGBA_0.a;
            float4 _Multiply_29520c18d1b04685a885a0c63fa5421c_Out_2;
            Unity_Multiply_float4_float4(_Property_30a1798db0aa4297b3aa18cff136a476_Out_0, _SampleTexture2D_7720a8b6af434e608b8887c50adf9099_RGBA_0, _Multiply_29520c18d1b04685a885a0c63fa5421c_Out_2);
            UnityTexture2D _Property_0be2bdae416640719811e2309ab4c544_Out_0 = UnityBuildTexture2DStructNoScale(_Variation_Albedo);
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_R_1 = IN.WorldSpacePosition[0];
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_G_2 = IN.WorldSpacePosition[1];
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_B_3 = IN.WorldSpacePosition[2];
            float _Split_d1fbeaf504504002b0c5bcc739a3480e_A_4 = 0;
            float2 _Vector2_a026fa279bc944bbb04aa01375c3f789_Out_0 = float2(_Split_d1fbeaf504504002b0c5bcc739a3480e_R_1, _Split_d1fbeaf504504002b0c5bcc739a3480e_B_3);
            float _Property_1d34955c16fa4bcc8e989ac70def90e2_Out_0 = _Variation_Tile;
            float2 _TilingAndOffset_c320896fac484e00bc5d286b9b04b9f5_Out_3;
            Unity_TilingAndOffset_float(_Vector2_a026fa279bc944bbb04aa01375c3f789_Out_0, (_Property_1d34955c16fa4bcc8e989ac70def90e2_Out_0.xx), float2 (0, 0), _TilingAndOffset_c320896fac484e00bc5d286b9b04b9f5_Out_3);
            float4 _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0 = SAMPLE_TEXTURE2D(_Property_0be2bdae416640719811e2309ab4c544_Out_0.tex, _Property_0be2bdae416640719811e2309ab4c544_Out_0.samplerstate, _Property_0be2bdae416640719811e2309ab4c544_Out_0.GetTransformedUV(_TilingAndOffset_c320896fac484e00bc5d286b9b04b9f5_Out_3));
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_R_4 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.r;
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_G_5 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.g;
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_B_6 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.b;
            float _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_A_7 = _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0.a;
            float4 _Lerp_3f1c9d88276d4c509884e059773b0cd7_Out_3;
            Unity_Lerp_float4(_Multiply_29520c18d1b04685a885a0c63fa5421c_Out_2, _SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_RGBA_0, (_SampleTexture2D_11a67c22852f48fdb2ac74a6271a7fcb_A_7.xxxx), _Lerp_3f1c9d88276d4c509884e059773b0cd7_Out_3);
            float4 _Property_5c41f0a4cb634c2cb82ef269db2846bf_Out_0 = _Puddles_Water_Color;
            float4 _Multiply_801c5584bd6e44d5b27d1cc10a80ec13_Out_2;
            Unity_Multiply_float4_float4(_Lerp_3f1c9d88276d4c509884e059773b0cd7_Out_3, _Property_5c41f0a4cb634c2cb82ef269db2846bf_Out_0, _Multiply_801c5584bd6e44d5b27d1cc10a80ec13_Out_2);
            UnityTexture2D _Property_02920be1d8054dc0b3b2294215245899_Out_0 = UnityBuildTexture2DStructNoScale(_Puddle);
            float _Split_afe4c34948c9429b93046604f74dc746_R_1 = IN.WorldSpacePosition[0];
            float _Split_afe4c34948c9429b93046604f74dc746_G_2 = IN.WorldSpacePosition[1];
            float _Split_afe4c34948c9429b93046604f74dc746_B_3 = IN.WorldSpacePosition[2];
            float _Split_afe4c34948c9429b93046604f74dc746_A_4 = 0;
            float2 _Vector2_bfee811b0b3a4420998259071b59d11f_Out_0 = float2(_Split_afe4c34948c9429b93046604f74dc746_R_1, _Split_afe4c34948c9429b93046604f74dc746_B_3);
            float _Property_8db3c77962a24563ba7a7fc1ba7316c9_Out_0 = _Puddles_Scale;
            float2 _TilingAndOffset_31e036c88acc4b3faa7a7f56384f37df_Out_3;
            Unity_TilingAndOffset_float(_Vector2_bfee811b0b3a4420998259071b59d11f_Out_0, (_Property_8db3c77962a24563ba7a7fc1ba7316c9_Out_0.xx), float2 (0, 0), _TilingAndOffset_31e036c88acc4b3faa7a7f56384f37df_Out_3);
            float4 _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0 = SAMPLE_TEXTURE2D(_Property_02920be1d8054dc0b3b2294215245899_Out_0.tex, _Property_02920be1d8054dc0b3b2294215245899_Out_0.samplerstate, _Property_02920be1d8054dc0b3b2294215245899_Out_0.GetTransformedUV(_TilingAndOffset_31e036c88acc4b3faa7a7f56384f37df_Out_3));
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_R_4 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.r;
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_G_5 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.g;
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_B_6 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.b;
            float _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_A_7 = _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_RGBA_0.a;
            float _Split_4a67d42a8b9d4977ba6f4cac1a12f281_R_1 = _Property_5c41f0a4cb634c2cb82ef269db2846bf_Out_0[0];
            float _Split_4a67d42a8b9d4977ba6f4cac1a12f281_G_2 = _Property_5c41f0a4cb634c2cb82ef269db2846bf_Out_0[1];
            float _Split_4a67d42a8b9d4977ba6f4cac1a12f281_B_3 = _Property_5c41f0a4cb634c2cb82ef269db2846bf_Out_0[2];
            float _Split_4a67d42a8b9d4977ba6f4cac1a12f281_A_4 = _Property_5c41f0a4cb634c2cb82ef269db2846bf_Out_0[3];
            float _Multiply_dfed34232b914e0b81daa1fe3800f81b_Out_2;
            Unity_Multiply_float_float(_Split_4a67d42a8b9d4977ba6f4cac1a12f281_A_4, 0.66, _Multiply_dfed34232b914e0b81daa1fe3800f81b_Out_2);
            float _Property_4d51f953259346eea7bc3f2213046b7b_Out_0 = _Puddles_Depth;
            float _Multiply_ce07b3b1fd274afc9dd8918a85c61699_Out_2;
            Unity_Multiply_float_float(_Property_4d51f953259346eea7bc3f2213046b7b_Out_0, _SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_A_7, _Multiply_ce07b3b1fd274afc9dd8918a85c61699_Out_2);
            float _Lerp_a088d3074bb440bfb5f3f4c9544a325e_Out_3;
            Unity_Lerp_float(_Multiply_dfed34232b914e0b81daa1fe3800f81b_Out_2, _Split_4a67d42a8b9d4977ba6f4cac1a12f281_A_4, _Multiply_ce07b3b1fd274afc9dd8918a85c61699_Out_2, _Lerp_a088d3074bb440bfb5f3f4c9544a325e_Out_3);
            float _Multiply_b62a67d20a95496a9b5f4fde94eec651_Out_2;
            Unity_Multiply_float_float(_SampleTexture2D_cee2ee89f67b454f9c063d9e51c48f6e_R_4, _Lerp_a088d3074bb440bfb5f3f4c9544a325e_Out_3, _Multiply_b62a67d20a95496a9b5f4fde94eec651_Out_2);
            float4 _Lerp_d54298f5e9c34a56bb8340940fe119f2_Out_3;
            Unity_Lerp_float4(_Lerp_3f1c9d88276d4c509884e059773b0cd7_Out_3, _Multiply_801c5584bd6e44d5b27d1cc10a80ec13_Out_2, (_Multiply_b62a67d20a95496a9b5f4fde94eec651_Out_2.xxxx), _Lerp_d54298f5e9c34a56bb8340940fe119f2_Out_3);
            surface.BaseColor = (_Lerp_d54298f5e9c34a56bb8340940fe119f2_Out_3.xyz);
            surface.Emission = float3(0, 0, 0);
            return surface;
        }
        
        // --------------------------------------------------
        // Build Graph Inputs
        #ifdef HAVE_VFX_MODIFICATION
        #define VFX_SRP_ATTRIBUTES Attributes
        #define VFX_SRP_VARYINGS Varyings
        #define VFX_SRP_SURFACE_INPUTS SurfaceDescriptionInputs
        #endif
        VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);
        
            output.ObjectSpaceNormal =                          input.normalOS;
            output.ObjectSpaceTangent =                         input.tangentOS.xyz;
            output.ObjectSpacePosition =                        input.positionOS;
        
            return output;
        }
        SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

            output.WorldSpacePosition = input.positionWS;
            output.uv0 = input.texCoord0;
        
            return output;
        }
        
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"
        
        ENDHLSL
        }
    }
    CustomEditorForRenderPipeline "UnityEditor.ShaderGraphLitGUI" "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset"
    CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}