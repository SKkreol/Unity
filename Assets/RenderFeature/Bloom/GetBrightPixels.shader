Shader "Hidden/GetBrightPixels"
{   
    SubShader
	{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
		Cull Back ZWrite Off ZTest Always

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
			
			struct Varyings
			{
				float4 positionCS  : SV_POSITION;
				half2 uv          : TEXCOORD0;
			};

			Varyings vert(float2 position : POSITION)
			{
				Varyings o;

		        o.positionCS = float4(position, 0, 1);
		        o.uv = position * half2(0.5, 0.5) + half2(0.5, 0.5);

				#if UNITY_UV_STARTS_AT_TOP
					o.positionCS.y *= -1;
				#endif

				return o;
			}

			half4 frag(Varyings i) : SV_Target
			{
				half4 color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv);
				half b = max(max(color.b, color.g), color.r);
				return  lerp(0, color, step(2, b));
			}
			ENDHLSL
		}
	}
}