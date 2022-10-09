Shader "Hidden/CustomBlit"
{
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
			
			struct Attributes
			{
				float2 position    : POSITION;
				float2 uv          : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS  : SV_POSITION;
				float2 uv          : TEXCOORD0;
			};

			Varyings vert(Attributes i)
			{
				Varyings output;

		        output.positionCS = float4(i.position, 0, 1);
		        output.uv = i.position * half2(0.5, 0.5) + half2(0.5, 0.5);

				#if UNITY_UV_STARTS_AT_TOP
					output.positionCS.y *= -1;
				#endif

				return output;
			}

			float4 frag(Varyings i) : SV_Target
			{
				float4 color = 1-SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv);
				return  color;
			}
			ENDHLSL
		}
	}
}