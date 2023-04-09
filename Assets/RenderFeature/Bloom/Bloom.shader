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
            #pragma target 2.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma shader_feature_local _MASK_DEBUG_ON

            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);            
            TEXTURE2D(_BlurTexture);
            SAMPLER(sampler_BlurTexture);
            half4 _NumberOfQuads;
            half4 _BrightTex_TexelSize;

            struct Attributes
            {
                float2 positionOS : POSITION;
                float3 color : COLOR;
                float2 texcoord1 : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                half2 uv : TEXCOORD0;
                float2 texcoord1 : TEXCOORD1;
                float2 posLocal : TEXCOORD2;
                float3 color : COLOR;
            };

            Varyings Vertex(Attributes i)
            {
                Varyings o;
                o.uv = i.positionOS * half2(0.5, 0.5) + half2(0.5, 0.5);

               
                float2 sampleMiddle = _NumberOfQuads.xy + i.texcoord1;
                
                float2 sampleLowLeft = i.texcoord1;
                
                float2 sampleLowRight = float2(_NumberOfQuads.z,0) + i.texcoord1;
                
                float2 sampleUpLeft = float2(0.0f, _NumberOfQuads.w) + i.texcoord1;
                
                float2 sampleUpRight = _NumberOfQuads.zw + i.texcoord1;

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

                o.texcoord1 = i.texcoord1;
                o.color = i.color;
                o.posLocal = i.positionOS;
                return o;
            }

            half4 Fragment(Varyings i) : SV_Target
            {
            
                float4 color = 0;
                
                #if defined(_MASK_DEBUG_ON)
                    color = float4(i.color.rgb,1);
               #else
                    color = SAMPLE_TEXTURE2D(_BlurTexture, sampler_BlurTexture, i.uv);
               #endif


               return color;
            }
            ENDHLSL
        }
    }
}