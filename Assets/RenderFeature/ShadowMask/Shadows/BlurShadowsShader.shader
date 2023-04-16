Shader "Hidden/BlurShadowsShader"
{
  Properties
  {
     [HideInInspector]_MainTex ("", 2D) = "white" {}
  }
  SubShader
  {
    Tags{   
          "RenderType" = "Opaque" 
          "RenderPipeline" = "UniversalPipeline" 
          "IgnoreProjector" = "True"
          "LightMode" = "UniversalForward"
        }
    ZTest Off Cull Off ZWrite Off Blend Off
    Pass
    {      
        HLSLPROGRAM
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 2.0                      
                 
        #pragma vertex vert
        #pragma fragment frag
          
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
         struct appdata
        {
            float4 vertex : POSITION;
        };
        
        struct v2f
        {
            float4 vertex : SV_POSITION;
            half2 uv0 : TEXCOORD0;
            half2 uv1 : TEXCOORD1;
            half2 uv2 : TEXCOORD2;
            half2 uv3 : TEXCOORD3;
            half2 uv4 : TEXCOORD4;
        };

        sampler2D _MobileShadowTexture;
        half _MobileShadowBlur;
        half2 _MobileShadowTexture_TexelSize;
        
        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = mul(UNITY_MATRIX_P, v.vertex);
            o.uv0 = v.vertex.xy;
            _MobileShadowTexture_TexelSize.y *= _MobileShadowBlur;
            o.uv1 = v.vertex.xy + half2(0, _MobileShadowTexture_TexelSize.y * 1.407333);
            o.uv2 = v.vertex.xy - half2(0, _MobileShadowTexture_TexelSize.y * 1.407333);
            o.uv3 = v.vertex.xy + half2(0, _MobileShadowTexture_TexelSize.y * 3.294215);
            o.uv4 = v.vertex.xy - half2(0, _MobileShadowTexture_TexelSize.y * 3.294215);
            return o;
        }

        half4 frag (v2f input) : SV_Target
        {
            half4 col = 0;
            col += tex2D(_MobileShadowTexture, input.uv0) * 0.204164;
            col += tex2D(_MobileShadowTexture, input.uv1) * 0.304005;
            col += tex2D(_MobileShadowTexture, input.uv2) * 0.304005;
            col += tex2D(_MobileShadowTexture, input.uv3) * 0.093913;
            col += tex2D(_MobileShadowTexture, input.uv4) * 0.093913;
            return col;
        }
        ENDHLSL
    }
    
     Pass
    {

        HLSLPROGRAM
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 2.0                      
                 
        #pragma vertex vert
        #pragma fragment frag
          
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        struct appdata
        {
            float4 vertex : POSITION;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            half2 uv0 : TEXCOORD0;
            half2 uv1 : TEXCOORD1;
            half2 uv2 : TEXCOORD2;
            half2 uv3 : TEXCOORD3;
            half2 uv4 : TEXCOORD4;
        };

        sampler2D _VerticalPassTex;
        sampler2D _FadeTex;
        half _MobileShadowBlur;
        half2 _VerticalPassTex_TexelSize;
        
        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = mul(UNITY_MATRIX_P, v.vertex);
            o.uv0 = v.vertex.xy;
            _VerticalPassTex_TexelSize.x *= _MobileShadowBlur;
            o.uv1 = v.vertex.xy + half2(_VerticalPassTex_TexelSize.x * 1.407333, 0);
            o.uv2 = v.vertex.xy - half2(_VerticalPassTex_TexelSize.x * 1.407333, 0);
            o.uv3 = v.vertex.xy + half2(_VerticalPassTex_TexelSize.x * 3.294215, 0);
            o.uv4 = v.vertex.xy - half2(_VerticalPassTex_TexelSize.x * 3.294215, 0);
            return o;
        }

        half4 frag (v2f input) : SV_Target
        {
            half4 col = 0;
            col += tex2D(_VerticalPassTex, input.uv0) * 0.204164;
            col += tex2D(_VerticalPassTex, input.uv1) * 0.304005;
            col += tex2D(_VerticalPassTex, input.uv2) * 0.304005;
            col += tex2D(_VerticalPassTex, input.uv3) * 0.093913;
            col += tex2D(_VerticalPassTex, input.uv4) * 0.093913;
            half fade = tex2D(_FadeTex, input.uv0).r;
            return col * fade;
        }
        ENDHLSL
    }
  }
}