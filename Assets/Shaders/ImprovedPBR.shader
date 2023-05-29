Shader "ImprovedPBR"
{
    Properties
    {
        [Hdr]_EmissionColor ("Emission Color", Color) = (1,1,1,1)
        _IrradianceMap("Irradiance Map", Cube) = "white" {}
        _MRAO ("MRAO", 2D) = "white" {}
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)

        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5

        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0

        [ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1.0

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
        
        _ReceiveShadowMap("Receive shadow map", 2D) = "white" {}
    }

    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            //#pragma exclude_renderers gles gles3 glcore
            #pragma target 2.0

            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fog

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _EmissionColor;
                half _Smoothness;
                half _Metallic;
                half _BumpScale;
            CBUFFER_END
                            
            TEXTURE2D(_MRAO);       SAMPLER(sampler_MRAO); 
            TEXTURECUBE(_IrradianceMap);               SAMPLER(sampler_IrradianceMap);      
            TEXTURE2D(_ReceiveShadowMap);               SAMPLER(sampler_ReceiveShadowMap);      

            struct Attributes
            {
                float3 positionOS   : POSITION;
                half3 normalOS     : NORMAL;
                half4 tangentOS    : TANGENT;
                half2 uv            : TEXCOORD0;
            };
            
            struct Varyings
            {
                half2 uv                        : TEXCOORD0;
                float3 positionWS               : TEXCOORD1;
                half3 normalWS                  : TEXCOORD2;
                half3 tangentWS                 : TEXCOORD3;
                half3 biTangentWS               : TEXCOORD6;
                half fogFactor                  : TEXCOORD5;     
                float4 positionCS               : SV_POSITION;
            };
            
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
    
                output.uv = input.uv;
                output.normalWS = normalize(mul(input.normalOS, (float3x3)GetWorldToObjectMatrix()));
                half sign = input.tangentOS.w * GetOddNegativeScale();
                half3 tangentWS = normalize(mul(input.tangentOS.xyz, (float3x3)GetWorldToObjectMatrix()));

                output.tangentWS = tangentWS;  
                
                half3 bitangent = sign * cross(output.normalWS, tangentWS);    
                output.biTangentWS = bitangent;          
                output.positionWS = mul(UNITY_MATRIX_M, float4(input.positionOS, 1)).xyz;
                output.positionCS = mul(UNITY_MATRIX_VP, float4(output.positionWS, 1));
                output.fogFactor = ComputeFogFactor(output.positionCS.z);
                return output;
            }
            
            
            // Computes the scalar specular term for Minimalist CookTorrance BRDF
            // NOTE: needs to be multiplied with reflectance f0, i.e. specular color to complete
            half CookTorrance(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
            {
                float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
                float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));
            
                float NoH = saturate(dot(float3(normalWS), halfDir));
                half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));
            
                // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
                // BRDFspec = (D * V * F) / 4.0
                // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
                // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
                // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
                // https://community.arm.com/events/1155
            
                // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
                // We further optimize a few light invariant terms
                // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
                float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
                half d2 = half(d * d);
            
                half LoH2 = LoH * LoH;
                half specularTerm = brdfData.roughness2 / (d2 * max(half(0.1), LoH2) * brdfData.normalizationTerm);
            
                // On platforms where half actually means something, the denominator has a risk of overflow
                // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
                // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
            #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
                specularTerm = specularTerm - HALF_MIN;
                specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
            #endif
            
            return specularTerm;
            }
            
            // Computes the scalar specular term for Minimalist CookTorrance BRDF
            // NOTE: needs to be multiplied with reflectance f0, i.e. specular color to complete
            half CookTorrance2(half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, float roughness2MinusOne, float roughness2, float normalizationTerm)
            {
                float3 lightDirectionWSFloat3 = float3(lightDirectionWS);
                float3 halfDir = SafeNormalize(lightDirectionWSFloat3 + float3(viewDirectionWS));
            
                float NoH = saturate(dot(float3(normalWS), halfDir));
                half LoH = half(saturate(dot(lightDirectionWSFloat3, halfDir)));
            
                // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
                // BRDFspec = (D * V * F) / 4.0
                // D = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2
                // V * F = 1.0 / ( LoH^2 * (roughness + 0.5) )
                // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
                // https://community.arm.com/events/1155
            
                // Final BRDFspec = roughness^2 / ( NoH^2 * (roughness^2 - 1) + 1 )^2 * (LoH^2 * (roughness + 0.5) * 4.0)
                // We further optimize a few light invariant terms
                // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
                float d = NoH * NoH * roughness2MinusOne + 1.00001f;
                half d2 = half(d * d);
            
                half LoH2 = LoH * LoH;
                half specularTerm = roughness2 / (d2 * max(half(0.1), LoH2) * normalizationTerm);
            
                // On platforms where half actually means something, the denominator has a risk of overflow
                // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
                // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
            #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
                specularTerm = specularTerm - HALF_MIN;
                specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
            #endif
            
            return specularTerm;
            }
            
            float3 CustomBoxProjection(float3 ViewDirWS, float3 NormalWS, float3 PositionWS, float LOD)
            {
                float3 viewDirWS = ViewDirWS;
                float3 normalWS = NormalWS;
                float3 reflDir = normalize(reflect(-viewDirWS, normalWS));
                float3 factors = ((reflDir > 0 ? unity_SpecCube0_BoxMax.xyz : unity_SpecCube0_BoxMin.xyz) - PositionWS) / reflDir;
                float scalar = min(min(factors.x, factors.y), factors.z);
                float3 uvw = reflDir * scalar + (PositionWS - unity_SpecCube0_ProbePosition.xyz);
                float4 sampleRefl = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, uvw, LOD);
            
                #if defined(UNITY_USE_NATIVE_HDR)
                    float3 irradiance = encodedIrradiance.rgb;
                #else
                    float3 irradiance = DecodeHDREnvironment(sampleRefl, unity_SpecCube0_HDR);
                #endif
            
                return irradiance;
            }
            
            float3 CustomBoxProjection2(float3 ViewDirWS, float3 NormalWS, float3 PositionWS, float LOD)
            {
                float3 viewDirWS = ViewDirWS;
                float3 normalWS = NormalWS;
                float3 reflDir = normalize(reflect(-viewDirWS, normalWS));
                float3 factors = ((reflDir > 0 ? unity_SpecCube0_BoxMax.xyz : unity_SpecCube0_BoxMin.xyz) - PositionWS) / reflDir;
                float scalar = min(min(factors.x, factors.y), factors.z);
                float3 uvw = reflDir * scalar + (PositionWS - unity_SpecCube0_ProbePosition.xyz);
                float4 sampleRefl = SAMPLE_TEXTURECUBE_LOD(_IrradianceMap, sampler_IrradianceMap, uvw, LOD);
            
                #if defined(UNITY_USE_NATIVE_HDR)
                    float3 irradiance = encodedIrradiance.rgb;
                #else
                    float3 irradiance = DecodeHDREnvironment(sampleRefl, unity_SpecCube0_HDR);
                #endif
            
                return irradiance;
            }
            
            half3 GlossyEnvironmentReflection2(half3 reflectVector, float3 positionWS, half perceptualRoughness, half occlusion)
            {
                #if !defined(_ENVIRONMENTREFLECTIONS_OFF)
                    half3 irradiance;
                
                #ifdef _REFLECTION_PROBE_BLENDING
                    irradiance = CalculateIrradianceFromReflectionProbes(reflectVector, positionWS, perceptualRoughness);
                #else
                half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
                half4 encodedIrradiance = half4(SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip));
                
                #if defined(UNITY_USE_NATIVE_HDR)
                    irradiance = encodedIrradiance.rgb;
                #else
                    irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
                #endif // UNITY_USE_NATIVE_HDR
                
                #endif // _REFLECTION_PROBE_BLENDING
                    return irradiance * occlusion;
                #else
                    return _GlossyEnvironmentColor.rgb * occlusion;
                #endif // _ENVIRONMENTREFLECTIONS_OFF
            }
            
            half Pow5(half x)
            {
                half x2 = x*x;
                half x4 = x2*x2;
                return x4 * x;
            }
            
            half3 SampleSH2(half3 normalWS)
            {
                // LPPV is not supported in Ligthweight Pipeline
                real4 SHCoefficients[7];
                SHCoefficients[0] = unity_SHAr;
                SHCoefficients[1] = unity_SHAg;
                SHCoefficients[2] = unity_SHAb;
                SHCoefficients[3] = unity_SHBr;
                SHCoefficients[4] = unity_SHBg;
                SHCoefficients[5] = unity_SHBb;
                SHCoefficients[6] = unity_SHC;
            
                return max(half3(0, 0, 0), SampleSH9(SHCoefficients, normalWS));
            }
            
            half4 LitPassFragment(Varyings input) : SV_Target
            {                                     
                half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb;
//                 float2 uvShadow = (input.positionWS.xz - float2(4.15, 13.5))/75.0f + 0.5;
//                 half4 receiveShadowMap = SAMPLE_TEXTURE2D(_ReceiveShadowMap, sampler_ReceiveShadowMap, uvShadow);
//                 half receiveShadow = dot(receiveShadowMap.xyz, float3(0.3, 0.59, 0.11)) + 0.25;

                albedo.rgb = albedo.rgb * _BaseColor.rgb;
                half4 mrao = SAMPLE_TEXTURE2D(_MRAO, sampler_MRAO, input.uv);
                half metallic = mrao.r;
                half smoothness = mrao.g *_Smoothness;
                half ao = mrao.b;
                half emissionMask = mrao.a;
                half3 normalTS = SampleNormal(input.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                half3x3 TBN = half3x3(input.tangentWS.xyz, input.biTangentWS.xyz, input.normalWS.xyz);               
                half3 normals = TransformTangentToWorld(normalTS, TBN);
                half3 normalWS = NormalizeNormalPerPixel(normals);
                half3 bakedGI = SampleSH2(normalWS);
               
                half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
                half reflectivity = half(1.0) - oneMinusReflectivity;
                half3 brdfDiffuse = albedo.rgb * oneMinusReflectivity;

                half3 F0 = lerp(kDieletricSpec.rgb, albedo.rgb, metallic);

                half perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
                half roughness           = max(perceptualRoughness * perceptualRoughness, HALF_MIN_SQRT);
                half roughness2          = max(roughness * roughness, HALF_MIN);
                half normalizationTerm   = roughness * half(4.0) + half(2.0);              
                half roughness2MinusOne = roughness2 - half(1.0);
                  
                // IndirectLight part
                half3 reflectVector = reflect(-viewDirWS, normalWS);
                half NoV = abs(dot(normalWS, viewDirWS));
                half3 halfDir = normalize(_MainLightPosition.xyz + viewDirWS);
                half LoH = saturate(dot(_MainLightPosition.xyz, halfDir));
                half VoH = saturate(dot(viewDirWS, halfDir));
                half VoL = saturate(dot(viewDirWS, _MainLightPosition.xyz));
                
                // Do like in UE4 VoH instead of NoV
                half fresnelTerm = Pow5(1.0 - VoH);
                float LOD = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness) * 6;
                //half3 indirectDiffuse = bakedGI;
                half3 indirectDiffuse = SAMPLE_TEXTURECUBE(_IrradianceMap, sampler_IrradianceMap, normalWS);
                //half3 indirectDiffuse = CustomBoxProjection2(viewDirWS, normalWS, input.positionWS, LOD);
                //return float4(indirectDiffuse, 1);

                half3 indirectSpecular = GlossyEnvironmentReflection2(reflectVector, input.positionWS, perceptualRoughness, ao);

                //float LOD = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness) * 6;
                //half3 indirectSpecular = CustomBoxProjection(viewDirWS, normalWS, input.positionWS, LOD)*ao;

                half3 color = indirectDiffuse * brdfDiffuse;

                float surfaceReduction = 1.0 / (roughness2+ 1.0);
                half3 F = lerp(F0, max(smoothness, F0), fresnelTerm);;
                half3 EnvironmentBRDFSpecular = half3(surfaceReduction * F);
                color += indirectSpecular * EnvironmentBRDFSpecular;
                half3 giColor = color * ao;                
                
                // DirectLight part
                half NdotL = saturate(dot(normalWS, half3(_MainLightPosition.xyz)));
                half3 radiance = _MainLightColor.rgb * NdotL;
                half3 brdf = brdfDiffuse + F0 * CookTorrance2(normalWS, half3(_MainLightPosition.xyz), viewDirWS, roughness2MinusOne, roughness2, normalizationTerm);                                   
                half3 mainLightColor = brdf * radiance;                       
                half3 fColor = (giColor + mainLightColor );
                fColor = lerp(fColor, _EmissionColor.rgb, emissionMask.rrr);
                half3 colorFog = MixFog(fColor, input.fogFactor);
                return half4(colorFog, 1);
            }

            ENDHLSL
        }
        
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            //ColorMask 0
            Cull Back

            HLSLPROGRAM
            //#pragma exclude_renderers gles gles3 glcore
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
        
        Pass
        {
            Name "EmissionPass"
            Tags{"LightMode" = "EmissionPass"}

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                half4 _EmissionColor;
            CBUFFER_END  
            
            TEXTURE2D(_MRAO);       SAMPLER(sampler_MRAO); 

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv     : TEXCOORD0;
            };
            
            struct Varyings
            {
                float2 uv                       : TEXCOORD0;      
                float4 positionCS               : SV_POSITION;
            };
            
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.uv = input.uv;
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            
            half4 LitPassFragment(Varyings input) : SV_Target
            {                                     
                half mrao = SAMPLE_TEXTURE2D(_MRAO, sampler_MRAO, input.uv).a;
                return mrao * _EmissionColor;
            }

            ENDHLSL
        }
        
        Pass
        {
            Name "ReflectionPass"
            Tags{"LightMode" = "ReflectionPass"}

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END  

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv     : TEXCOORD0;
            };
            
            struct Varyings
            {
                float2 uv                       : TEXCOORD0;      
                float worldPos                 : TEXCOORD1;      
                float4 positionCS               : SV_POSITION;
            };
            
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.uv = input.uv;
                output.worldPos = vertexInput.positionWS.y;
                output.positionCS = vertexInput.positionCS;
                return output;
            }

            
            half4 LitPassFragment(Varyings input) : SV_Target
            {                                     
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) *0.3;
                // Hardcoded calculation mask, for blend static and realtime reflection.
                albedo.a = half(1-saturate(input.worldPos*0.7692));
                return albedo;
            }

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
