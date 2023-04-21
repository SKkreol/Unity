Shader "AlienProject/Environment"
{   
    Properties
    {
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        _Color ("Color", Color ) = (1,1,1,1)
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

            float4x4 _MobileShadowMatrix;
            
            CBUFFER_START(UnityPerMaterial)
                half4 _MobileShadowColor;
                half4 _BaseMap_ST;
                half4 _Color;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                half2 uv : TEXCOORD0;
                half2 lightmapUV : TEXCOORD1;
                half3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                float2 shadowCoord : TEXCOORD1;
                half fogFactor  : TEXCOORD2;
                half2 lightmapUV  : TEXCOORD3;
                half3 normalWS : NORMAL;
            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                float3 worldPos = mul(UNITY_MATRIX_M, float4(i.positionOS, 1.0)).xyz;

		        o.shadowCoord = mul(_MobileShadowMatrix, float4(worldPos,1)).xy;
                o.uv = i.uv*_BaseMap_ST.xy + _BaseMap_ST.zw;

                o.positionCS = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                o.fogFactor = ComputeFogFactor(o.positionCS.z);
                o.normalWS = TransformObjectToWorldNormal(i.normal);
                 OUTPUT_LIGHTMAP_UV(i.lightmapUV, unity_LightmapST, o.lightmapUV);
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
                half NdL = saturate(dot(i.normalWS, _MainLightPosition.xyz));
                
                half3 bakedGI = SampleLightmap(i.lightmapUV, 0, i.normalWS);
            
                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half4 shadowsSmooth = SAMPLE_TEXTURE2D(_BlurShadow, sampler_BlurShadow, i.shadowCoord);
                half shadowIntensity = shadowsSmooth.r*_MobileShadowColor.a * NdL * bakedGI;
                half3 shadow = lerp(half(1), _MobileShadowColor.rgb, shadowIntensity);
                

                half3 color = shadow * albedo.rgb * _Color.rgb * bakedGI;
                half3 colorFog = MixFog(color, i.fogFactor);
                return half4(colorFog, 1);
            }
            
            ENDHLSL
        }
    }
}