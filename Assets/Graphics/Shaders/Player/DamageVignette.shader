Shader "Plarium/UI/DamageVignette"
{
    Properties
    {
        [HideInInspector]
        [PerRendererData] _MainTex("Main Tex", 2D) = "" {}

        [Header(Main Settings)]
        _ExpansionAmount("Expansion Amount", Range(0,1)) = 0
        _OpacityMultiplier("Opacity Multiplier", Range(0, 5)) = 1

        [Header(Vignette)]
        _ExpansionPower("Expansion Power", float) = 0.1
        _BoxDimension("Size(x,y), Roundness(z), Hardness(w)", Vector) = (0, 0, 0.05, 0)
        _GradientRange("Gradient Range", Vector) = (0, 1, 0.0025, 0.25)

        [Header(Outline)]
        _ScreenOutline("Screen Outline", Vector) = (0.0025, 0.25, 0.05, 0)

        [Header(Animations)]
        _Noise("Noise Tex", 2D) = "black" {}
        _NoiseDimension("Noise Gradient Dimension", Vector) = (0, 0, 0.05, 0)
        _NoisePower("Noise Power", Vector) = (0.05, 0.36, 0.025, 0)
        _NoisePanner("Noise Panner", Vector) = (0.0025, -0.0025, 0, 0)

        [Space(20)]
        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
    }
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        ColorMask RGB

        Pass
        {
            Name "UI_Vignette"

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"

            struct appdata
            {
                half3 vertex : POSITION;
                fixed4 color : COLOR0;
                half2 uv: TEXCOORD0;
            };

            struct v2f
            {
                half4 vertex : SV_POSITION;
                fixed4 color : COLOR0;
                half3 centerCoord : TEXCOORD0;
                half4 uv: TEXCOORD1;
                half4 animation_vignetteDimension: TEXCOORD2;
            };

            fixed _ExpansionAmount;

            fixed _ExpansionPower;
            fixed _OpacityMultiplier;

            fixed4 _GradientRange;
            fixed4 _BoxDimension;
            fixed4 _ScreenOutline;

            sampler2D _Noise;
            fixed4 _Noise_ST;
            fixed4 _NoiseDimension;
            fixed4 _NoisePower;
            fixed2 _NoisePanner;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.uv;
                o.uv.zw = TRANSFORM_TEX(v.uv, _Noise);

                // Correct tiling
                o.uv.z *= _ScreenParams.x/_ScreenParams.y;

                o.centerCoord.xy = v.uv - 0.5;
                o.color = v.color;

                o.animation_vignetteDimension.xy = v.uv + _Time.w * _NoisePanner;
                fixed expansion = max(0.0001, pow(_ExpansionAmount, _ExpansionPower));
                o.animation_vignetteDimension.zw = _BoxDimension.xy / expansion;
                return o;
            }

            fixed sdfRoundBox(fixed2 coords, fixed2 dimensions, fixed r, fixed p)
            {
                fixed2 d = abs(coords) - dimensions;
                fixed roundBox = saturate(length(max(d,0.0)) + min(max(d.x,d.y),0.0) - r);
                return saturate(pow(roundBox, p));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 coords = i.centerCoord.xy;

                // Vignette.
                fixed roundBox = sdfRoundBox(coords, i.animation_vignetteDimension.zw, _BoxDimension.z, _BoxDimension.w);
                fixed vignette = smoothstep(_GradientRange.x, _GradientRange.y, roundBox);

                // Outline.
                fixed outline = sdfRoundBox(coords, _ScreenOutline.xy, _ScreenOutline.z, _ScreenOutline.w);
                outline = smoothstep(0, 1, outline);

                // Noise.
                fixed noiseBox = sdfRoundBox(coords, _NoiseDimension.xy, _NoiseDimension.z, _NoiseDimension.w);
                fixed2 noiseUV = i.uv.zw;
                noiseUV.x += tex2D(_Noise, i.animation_vignetteDimension.xy).r * _NoisePower.x;
                fixed noiseOpacity = smoothstep(0, 1, saturate(noiseBox * _NoisePower.y)) * _NoisePower.z;
                fixed noise = tex2D(_Noise, noiseUV).r * noiseOpacity;

                vignette = vignette + outline;
                vignette = saturate(vignette * _OpacityMultiplier - noise);

                fixed3 finalColor = i.color.rgb * vignette;
                return fixed4(finalColor, vignette);
            }
            ENDCG
        }
    }
}
