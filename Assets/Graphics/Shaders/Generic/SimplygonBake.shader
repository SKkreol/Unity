Shader "Plarium/SimplygonBake" {
Properties {
    _MainTex ("Base (RGB)", 2D) = "white" {}
    _SecondTex ("Second (RGB)", 2D) = "white" {}
    _Color("Color", Color) = (1,1,1,1)
}

SubShader {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Pass {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _SecondTex;

#define LIGHTMAP_RGBM_MAX_GAMMA     (5.0)       // NB: Must match value in RGBMRanges.h
#define LIGHTMAP_RGBM_MAX_LINEAR    (34.493242) // LIGHTMAP_RGBM_MAX_GAMMA ^ 2.2

#ifdef UNITY_LIGHTMAP_RGBM_ENCODING
#ifdef UNITY_COLORSPACE_GAMMA
#define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_GAMMA
#define LIGHTMAP_HDR_EXPONENT   (1.0)   // Not used in gamma color space
#else
#define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_LINEAR
#define LIGHTMAP_HDR_EXPONENT   (2.2)
#endif
#elif defined(UNITY_LIGHTMAP_DLDR_ENCODING)
#ifdef UNITY_COLORSPACE_GAMMA
#define LIGHTMAP_HDR_MULTIPLIER (2.0)
#else
#define LIGHTMAP_HDR_MULTIPLIER (4.59) // 2.0 ^ 2.2
#endif
#define LIGHTMAP_HDR_EXPONENT (0.0)
#else // (UNITY_LIGHTMAP_FULL_HDR)
#define LIGHTMAP_HDR_MULTIPLIER (1.0)
#define LIGHTMAP_HDR_EXPONENT (1.0)
#endif

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.texcoord);
                fixed4 lm = tex2D(_SecondTex, i.texcoord);
                fixed3 res = lm.rgb * (pow(lm.a, LIGHTMAP_HDR_EXPONENT)* LIGHTMAP_RGBM_MAX_LINEAR);
                return fixed4(res, 1.0);
                //return lm;
            }
        ENDCG
    }
}

}