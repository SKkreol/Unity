Shader "AlienProject/Scanner"
{
	Properties
	{
		[HideInInspector]_MainTex ("", 2D) = "white" {}	
	}
	
	SubShader
	{
		Cull Off 
		ZWrite Off 
		ZTest Always 

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
									
			TEXTURE2D(_MainTex);            
			SAMPLER(sampler_MainTex);
			
			TEXTURE2D(_FadeTex);            
			SAMPLER(sampler_FadeTex);
			
            TEXTURE2D(_CameraDepthTexture);            
            SAMPLER(sampler_CameraDepthTexture);
			
			float4x4 P_MATRIX; 
			float4x4 VW_MATRIX;
			float4 _ScoutCompasPos;
			float _RadarAnim;
			
			struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert (Attributes v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_P, float4(v.positionOS, 1.0));
				o.uv = v.uv;
				return o;
			}

            float SampleRawDepth(float2 uv)
            {
            	return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
            }
			
			float3 screenSpaceWorldPos(float2 uv, float depth)
			{
				float4 result = mul(P_MATRIX, float4(uv * 2.0 - 1.0, depth, 1.0));
				float3 viewPos = result.xyz / result.w;
				float3 worldPos = mul(VW_MATRIX, float4(viewPos, 1.0)).xyz;
				return worldPos;
			}
			
			float4 frag (v2f i) : SV_Target
			{
                float4 original = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				float rawDepth = SampleRawDepth(i.uv);
				float depthLinear = Linear01Depth(rawDepth, _ZBufferParams);
                float3 worldScreenPos = screenSpaceWorldPos(i.uv, depthLinear);
				
				float dist = distance(worldScreenPos, _ScoutCompasPos);
				
				float fallOff = 1-depthLinear;
				float4 c = SAMPLE_TEXTURE2D(_FadeTex, sampler_FadeTex, float2(dist, 0.5) - float2(_RadarAnim * fallOff, 0));
				
				float fadeMask = smoothstep(0.8, 1, fallOff);
 				
				return lerp(original, c, c.a * fadeMask);
			}
			ENDHLSL
		}
	}
}