Shader "Hidden/MobileShadowReplacement/DrawShadows"
{
	SubShader
	{
		Tags 
		{
			"RenderPipeline" = "UniversalPipeline" 
			"RenderType" = "Opaque"  
		}
		ZWrite On
		Cull Back
			
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
    
            CBUFFER_START(UnityPerMaterial)
            CBUFFER_END
    
            struct appdata
            {
                float3 vertex : POSITION;
            };
    
            struct v2f
            {
                float4 vertex : SV_POSITION;
            };
            
            v2f vert (appdata v)
            {
                v2f o;
                float3 worldPos = mul(UNITY_MATRIX_M, float4(v.vertex, 1.0)).xyz;
                o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                return unity_DynamicLightmapST;
            }
			ENDHLSL
		}
	}
}