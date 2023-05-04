Shader "Hidden/AddBloom"
{   
    SubShader
    {
        Pass
        {
            Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
            Blend OneMinusDstColor One
            ZTest Always
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma target 3.0
            #pragma warning(disable : 4008)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma shader_feature_local _MASK_DEBUG_ON

            TEXTURE2D(_BlurTexture);
            SAMPLER(sampler_BlurTexture);
            
            float4 _NumberOfQuads;

            struct Attributes
            {
                float2 positionOS : POSITION;
                #if defined(_MASK_DEBUG_ON)
                    half3 color : COLOR;
                #endif
                float2 quadPosition : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                
                #if defined(_MASK_DEBUG_ON)
                    half3 color : COLOR;
                #endif
            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                o.uv = i.positionOS * float2(0.5, 0.5) + float2(0.5, 0.5);
               
                float2 sampleMiddle = _NumberOfQuads.xy + i.quadPosition;
                
                float2 sampleLowLeft = i.quadPosition;
                
                float2 sampleLowRight = float2(_NumberOfQuads.z,0) + i.quadPosition;
                
                float2 sampleUpLeft = float2(0.0f, _NumberOfQuads.w) + i.quadPosition;
                
                float2 sampleUpRight = _NumberOfQuads.zw + i.quadPosition;

                float4 texSample = SAMPLE_TEXTURE2D_LOD(_BlurTexture, sampler_BlurTexture, sampleMiddle, 0.0f);
                texSample += SAMPLE_TEXTURE2D_LOD(_BlurTexture,sampler_BlurTexture, sampleLowLeft, 0.0f);
                texSample += SAMPLE_TEXTURE2D_LOD(_BlurTexture,sampler_BlurTexture, sampleLowRight, 0.0f);
                texSample += SAMPLE_TEXTURE2D_LOD(_BlurTexture,sampler_BlurTexture, sampleUpLeft, 0.0f);
                texSample += SAMPLE_TEXTURE2D_LOD(_BlurTexture,sampler_BlurTexture, sampleUpRight, 0.0f);
                
                o.positionCS = float4(i.positionOS, 0, 1);

                #if UNITY_UV_STARTS_AT_TOP
			        o.positionCS.y *= -1;
		        #endif

                 if(texSample.r + texSample.g + texSample.b < 0.0001)
                     o.positionCS.w = 0.0/0.0;
                
                #if defined(_MASK_DEBUG_ON)
                    o.color = i.color;
                #endif
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
                half4 color = 0;
                
                #if defined(_MASK_DEBUG_ON)
                    color = half4(i.color.rgb,1);
                #else
                    color = SAMPLE_TEXTURE2D(_BlurTexture, sampler_BlurTexture, i.uv);
                #endif

               return color;
            }
            ENDHLSL
        }
    }
}