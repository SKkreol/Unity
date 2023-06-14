Shader "AlienProject/Environment"
{   
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _BumpMap("_BumpMap", 2D) = "bump" {}
        _Color ("Color", Color ) = (1,1,1,1)
        _FogMap ("Fog", Cube) =  "white" {}
        _FogStart ("_FogStart", float) = 2
        _FogEnd ("_FogEnd", float) = 1
        _Div ("_Div", float) = 1
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
        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma multi_compile_fog
            #pragma multi_compile _ LIGHTMAP_ON

            TEXTURE2D(_BlurShadow);
            SAMPLER(sampler_BlurShadow);      
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);    
            
            TEXTURECUBE(_FogMap);               SAMPLER(sampler_FogMap);     

            float4x4 _MobileShadowMatrix;
            
            CBUFFER_START(UnityPerMaterial)
                half4 _MobileShadowColor;
                half4 _BaseMap_ST;
                half4 _Color;
                half _FogStart;
                half _FogEnd;
                half _Div;
                half _Dist;
                half3 _Pos;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                half2 uv : TEXCOORD0;
                half2 lightmapUV : TEXCOORD1;
                half3 normal : NORMAL;
                half4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                float2 shadowCoord : TEXCOORD1;
                half fogFactor  : TEXCOORD2;
                half2 lightmapUV  : TEXCOORD3;
                half3 viewDir  : TEXCOORD4;
                half3 wp  : TEXCOORD5;
                half ff  : TEXCOORD6;
                half4  normalWS_px              : TEXCOORD7;
                half4  tangentWS_py             : TEXCOORD8;
                half4  biTangentWS_pz           : COLOR;
                half3 normalWS : NORMAL;
            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                float3 worldPos = mul(UNITY_MATRIX_M, float4(i.positionOS, 1.0)).xyz;
                
                o.normalWS_px.xyz = normalize(mul(i.normal, (half3x3)UNITY_MATRIX_I_M));
                half sign = i.tangentOS.w * unity_WorldTransformParams.w;
                o.tangentWS_py.xyz = normalize(mul(i.tangentOS.xyz, (half3x3)UNITY_MATRIX_I_M)); 
                o.biTangentWS_pz.xyz = sign * cross(o.normalWS_px.xyz, o.tangentWS_py.xyz);          
         

		        o.shadowCoord = mul(_MobileShadowMatrix, float4(worldPos,1)).xy;
                o.uv = i.uv*_BaseMap_ST.xy + _BaseMap_ST.zw;

                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                o.normalWS = TransformObjectToWorldNormal(i.normal);
                OUTPUT_LIGHTMAP_UV(i.lightmapUV, unity_LightmapST, o.lightmapUV);
                
                //fog
                
                float fogz = mul(UNITY_MATRIX_V, float4(worldPos, 1)).z;
                o.fogFactor = fogz;
                o.wp = worldPos;
                o.viewDir = (_WorldSpaceCameraPos.xyz - worldPos);
                o.ff = -mul( UNITY_MATRIX_MV, float4(i.positionOS, 1.0) ).z * _ProjectionParams.w;
                
                return o;
            }
            
            half3 MixFogColor2(half3 fragColor, half3 fogColor, half fogFactor)
            {
            #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
            #if defined(FOG_EXP)
                // factor = exp(-density*z)
                // fogFactor = density*z compute at vertex
                fogFactor = saturate(exp2(-fogFactor));
            #elif defined(FOG_EXP2)
                // factor = exp(-(density*z)^2)
                // fogFactor = density*z compute at vertex
                fogFactor = saturate(exp2(-fogFactor*fogFactor));
            #endif
                fragColor = lerp(fogColor, fragColor, fogFactor);
            #endif
            
                return fragColor;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
            
                half4 n = SAMPLE_TEXTURE2D(_BumpMap, sampler_BaseMap, i.uv);
                half3 normalTS = UnpackNormal(n);
            
                half3x3 TBN = half3x3(i.tangentWS_py.xyz, i.biTangentWS_pz.xyz, i.normalWS_px.xyz);               
                half3 normals =  mul(normalTS, TBN);
                half3 normalWS = normalize(normals);
                
                half NdL = saturate(dot(normalWS, _MainLightPosition.xyz));
                
                half3 bakedGI = SampleLightmap(i.lightmapUV, 0, i.normalWS);
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half4 shadowsSmooth = SAMPLE_TEXTURE2D(_BlurShadow, sampler_BlurShadow, i.shadowCoord);
                half shadowIntensity = shadowsSmooth.r*_MobileShadowColor.a * bakedGI;
                half3 shadow = lerp(half(1), _MobileShadowColor.rgb, shadowIntensity);
                

                half4 fogCube = SAMPLE_TEXTURECUBE(_FogMap, sampler_FogMap, -normalize(i.viewDir));

                half3 color = shadow * albedo.rgb * _Color.rgb * NdL * bakedGI + 0.005;
                half t = dot(i.wp.xz -_Pos.xz, i.wp.xz -_Pos.xz);
                half z = saturate((t + _FogStart) / (_FogStart - _FogEnd));
                half3 colorFog = lerp(color, fogCube, z);
                half fc = smoothstep(0.03, 0.2, i.ff);
                return half4(MixFogColor2(color, fogCube, 1-fc),1);
            }
            
            ENDHLSL
        }
    }
}