Shader "Unlit/DualBlurForBloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
         ZTest Always ZWrite Off Cull Off

        //Down sample
        Pass
        {
            HLSLPROGRAM

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float4 vertex : SV_POSITION;
            };

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);            
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _MainTex_TexelSize;
            CBUFFER_END


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);

                o.vertex = vertexInput.positionCS;

                float4 offset = _MainTex_TexelSize.xyxy*float4(-1,-1,1,1);
                o.uv0 = v.uv;
                o.uv1 = v.uv + offset.xy;
                o.uv2 = v.uv + offset.xw;
                o.uv3 = v.uv + offset.zy;
                o.uv4 = v.uv + offset.zw;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 o = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0) * 4;
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv1);
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv2);
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv3);
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv4);
                return o * 0.2;
            }
            ENDHLSL
        }

        //Up sample
        Pass
        {
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);            
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _MainTex_TexelSize;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float2 uv5 : TEXCOORD5;
                float2 uv6 : TEXCOORD6;
                float2 uv7 : TEXCOORD7;
                float4 vertex : SV_POSITION;
            };


            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.vertex = vertexInput.positionCS;

                float4 offset = _MainTex_TexelSize.xyxy*float4(-1,-1,1,1);
                o.uv0 = v.uv + float2(offset.x, 0);
                o.uv1 = v.uv + float2(offset.z, 0);
                o.uv2 = v.uv + float2(0, offset.y);
                o.uv3 = v.uv + float2(0, offset.w);
                o.uv4 = v.uv + offset.xy * 0.5;
                o.uv5 = v.uv + offset.xw * 0.5;
                o.uv6 = v.uv + offset.zy * 0.5;
                o.uv7 = v.uv + offset.zw * 0.5;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 o = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv1);
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv2);
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv3);
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv4) * 2;
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv5) * 2;
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv6) * 2;
                o += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv7) * 2;
                return o * 0.125;
            }
            ENDHLSL
        }
    }
}
