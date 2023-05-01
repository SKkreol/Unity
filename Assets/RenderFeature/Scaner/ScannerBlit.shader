Shader "AlienProject/ScannerBlit"
{
    Properties
    {
        _OffSet("_OffSet", float) = (0,0,0,0)
        //_ScanerSize ("ScanerSize", float) = 0
        [HDR]_Color ("_Color", Color) = (1,1,1,1)
        _MainTex ("", 2D) = "white" {}	
    }
    
	SubShader
	{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
            TEXTURE2D_X(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
            
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);            
            TEXTURE2D(_LutTex);
            SAMPLER(sampler_LutTex);
            
            float4x4 P_MATRIX; 
            float4x4 VW_MATRIX;

            
            float4 _OffSet;
            float4 _Pos;
            float4 _Color;
            float _ScanerSize;
            float _ScanWidth;
			
			struct Attributes
			{
				float2 position    : POSITION;
				float3 ray          : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS  : SV_POSITION;
				float2 uv          : TEXCOORD0;
				float3 interpolatedRay          : TEXCOORD1;
			};

			Varyings vert(Attributes i)
			{
				Varyings output;

		        output.positionCS = float4(i.position, 0, 1);
		        output.uv = i.position * half2(0.5, 0.5) + half2(0.5, 0.5);
		        output.interpolatedRay = i.ray;

				#if UNITY_UV_STARTS_AT_TOP
					output.positionCS.y *= -1;
				#endif

				return output;
			}
			
            float SampleNonLinearDepth(float2 uv)
            {
                return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
            }
            
            float3 screenSpaceWorldPos(float2 xy, float z)
            {
                float4 viewPos = mul(P_MATRIX, float4(xy * 2.0 - 1.0, z, 1.0));
                float3 viewPosNormalized = viewPos.xyz / viewPos.w;
                float3 worldPos = mul(VW_MATRIX, float4(viewPosNormalized, 1.0)).xyz;
                return worldPos;
            }

			float4 frag(Varyings i) : SV_Target
			{
                float z = SampleNonLinearDepth(i.uv);
                float zLinear = Linear01Depth(z, _ZBufferParams);
                float3 worldScreenPos = i.interpolatedRay * zLinear + _WorldSpaceCameraPos;
                float4 color = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv);
                
                float dist = distance(worldScreenPos, _Pos.xyz);
                float4 tile = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv*_OffSet.x) + 0.1;

                float diff = (_ScanerSize - dist) / (_ScanWidth);
                float4 c = SAMPLE_TEXTURE2D(_LutTex, sampler_LutTex, float2(diff, 0.5));
                return lerp(color, c, c.a*tile.r);
			}
			ENDHLSL
		}
	}
}