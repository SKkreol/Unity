Shader "Plarium/HealthBar"
{
    Properties
    {
        _Slider ("_Slider", Range(0,1)) = 1
        _SliderHighlight ("_SliderHighlight", Range(0,1)) = 1
        _FrameSize ("_FrameSize", Range(0,1)) = 1
        _Alpha ("_Alpha", Range(0,1)) = 1
        _ColorFull("_ColorFull", Color) = (1, 1, 1, 1)
        _ColorDamage("_ColorDamage", Color) = (1, 1, 1, 1)
        _ColorEmpty("_ColorEmpty", Color) = (0, 0, 0, 1)
        _ColorFrame("_ColorFrame", Color) = (0, 0, 0, 1)

        [Space(20)]
        [Enum(UnityEngine.Rendering.CullMode)] HARDWARE_CullMode("Cull faces", Float) = 2
		[Enum(On, 1, Off, 0)] HARDWARE_ZWrite("Depth write", Float) = 1
		[Enum(UnityEngine.Rendering.CompareFunction)] HARDWARE_ZTest("Depth test", Float) = 4
    }
    SubShader
    {
        Tags
    		{
    			"RenderType" = "Opaque"
    			"RenderPipeline" = "UniversalPipeline"
    			"IgnoreProjector" = "True"
    			"ShaderModel"="4.5"
    		}
        LOD 300
        Pass
        {
            Name "EntityLit"
            Tags{"LightMode" = "UniversalForward"}
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite[HARDWARE_ZWrite]
            ZTest[HARDWARE_ZTest]
            Cull[HARDWARE_CullMode]

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x gles
            #pragma target 4.5
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fog
            #pragma multi_compile_instancing

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

			CBUFFER_START(UnityPerMaterial)
                half4 _ColorFull;
                half4 _ColorDamage;
                half4 _ColorEmpty;
                half4 _ColorFrame;
                half _Slider;
                half _SliderHighlight;
                half _FrameSize;
                half _Alpha;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float2 scale : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                float3 worldPos = UNITY_MATRIX_M._m03_m13_m23;
                o.scale = float2(length(UNITY_MATRIX_M._m00_m10_m20), length(UNITY_MATRIX_M._m01_m11_m21));
                float4 viewPos = mul(UNITY_MATRIX_V, float4(worldPos, 1.0));
                float2 vertex = v.vertex.xy * o.scale;

				// Calculate bar size depend on distance.
                vertex *= min(max(viewPos.z * viewPos.z * 0.04, 15), 40);
                viewPos.xy += vertex;

                o.pos = mul(UNITY_MATRIX_P, viewPos);
                o.uv = v.uv;
                return o;
            }

            real4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                real mask = 1-saturate((i.uv.x - _Slider) * 100);
                real maskHighlight = 1-saturate((i.uv.x - _SliderHighlight) * 100);

                real frameSizeX = _FrameSize / i.scale.x * 0.01;
                real frameSizeY = _FrameSize / i.scale.y * 0.01;

                real frameLeft = saturate((i.uv.x - frameSizeX) * 200);
                real frameRight = saturate(((1-i.uv.x) - frameSizeX) * 200);

                real frameUp = saturate((i.uv.y - frameSizeY) * 100);
                real frameDown = saturate(((1-i.uv.y) - frameSizeY) * 100);
                real frame = min(min(min(frameLeft, frameRight), frameUp), frameDown);
                real3 col = lerp(_ColorFrame.rgb, lerp(lerp(_ColorEmpty.rgb, _ColorDamage.rgb, maskHighlight), _ColorFull.rgb, mask), frame);
                return real4(col , _Alpha);
            }
            ENDHLSL
        }
    }
}