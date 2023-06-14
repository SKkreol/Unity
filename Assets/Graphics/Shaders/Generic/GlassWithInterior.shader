Shader "Plarium/GlassWithInterior"
{
    Properties
    {
        [NoScaleOffset] _Mask ("Mask", 2D) = "black" {}
        _Normal ("Normalmap", 2D) = "bump" {}
        [NoScaleOffset] _Environment ("Environment cubemap", Cube) = "black" {}
        [NoScaleOffset] _Interior2DAtlas("Interior atlas", 2D) = "white" {}
        _AtlasParam ("Interior param(X count, Y count, Z tile id, W - tile depth)", vector) = (1,1,0,0.5)

        [NoScaleOffset]_InteriorCubemapArray ("Interior Cubemap array (HDR)", CubeArray) = "grey" {}
        [NoScaleOffset]_Dirt ("Dirt Texture", 2D) = "black" {}
        _DirtIntensity ("Dirt Intensity", Range(0, 1)) = 1
        _Angle ("Angle", Range(0, 360)) = 1
        _Transparency ("Transparency", Range(0, 1)) = 1
        _Roughness ("Roughness", Range(0, 1)) = 1
        _FresnelFalloff ("FresnelFalloff", Range(0, 1)) = 1

        [KeywordEnum(None, Atlas_2d, Atlas_Cube)] _Interior ("Interior mode", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        Cull Back
        // Blend One Zero
        ZTest LEqual
        ZWrite On

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #pragma multi_compile_fog

            #pragma multi_compile _INTERIOR_NONE _INTERIOR_ATLAS_2D _INTERIOR_ATLAS_CUBE

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"


            #include "Assets/Graphics/Shaders/PlariumShaderLibrary/PlariumGlobalIllumination.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float4 _AtlasParam; // x,y - tiles count widht, height, z - tile id
            float _DirtIntensity; // x,y - tiles count widht, height, z - tile id
            float _Transparency;
            float _Roughness; // for simplygon error supression
            float _FresnelFalloff; // for simplygon error supression
            CBUFFER_END

            // Object and Global properties
            SAMPLER(SamplerState_Linear_Repeat);

            TEXTURE2D(_Interior2DAtlas);
            TEXTURE2D(_Mask);
            TEXTURE2D(_Normal);
            float4 _Normal_ST;
            TEXTURE2D(_Dirt);
            TEXTURECUBE(_Environment);
            TEXTURECUBE_ARRAY(_InteriorCubemapArray);

            struct app2vert
            {
                float4 position : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                #if UNITY_ANY_INSTANCING_ENABLED
                    uint instanceID         : INSTANCEID_SEMANTIC;
                #endif
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3x3 tbn : TBASIS;
                float3 positionWS : TEXCOORD0;
                float3 positionOS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 tangentViewDir : TEXCOORD3;
                float4 uv0 : TEXCOORD4; // uv + ligtmap uv
                float4 uv1 : TEXCOORD5; // shuffled uv's
            };

            float hash1(uint n)
            {
                // Integer hash copied from Hugo Elias.
                n = (n << 13U) ^ n;
                n = n * (n * n * 15731U + 789221U) + 1376312589U;
                return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
            }

            float3 TextureCoord2InteriorCube(float2 uv, float3 viewDirection, float depth)
            {
                uv = frac(uv);
                uv = uv * 2.0 - 1.0;

                half3 cubeUV = half3(uv.x, uv.y, -depth);
                half3 id = rcp(viewDirection);
                half3 absID = abs(id);

                half3 k = absID - cubeUV * id;
                half kMin = min(min(k.x, k.y), k.z);
                half3 kMinTangent = kMin.xxx * viewDirection;

                half3 pos = cubeUV + kMinTangent;
                return pos;
            }

            float2 TextureCoord2Interior2dAtlas(float2 uv, float3 viewDirection, float depth, out float z)
            {
                depth = clamp(depth, 0.01, 0.99);
                float depthScale = rcp(depth) - 1.0;

                float3 viewRayStartPosBoxSpace = float3(uv * 2.0 - 1.0, -1.0);
                float3 viewRayDirBoxSpace = viewDirection * float3(1.0, 1.0, -depthScale);

                float3 viewRayDirBoxSpaceRcp = rcp(viewRayDirBoxSpace);

                float3 hitRayLengthForSeperatedAxis = abs(viewRayDirBoxSpaceRcp) - viewRayStartPosBoxSpace *
                    viewRayDirBoxSpaceRcp;
                float shortestHitRayLength = min(min(hitRayLengthForSeperatedAxis.x, hitRayLengthForSeperatedAxis.y),
                                                 hitRayLengthForSeperatedAxis.z);
                float3 hitPosBoxSpace = viewRayStartPosBoxSpace + shortestHitRayLength * viewRayDirBoxSpace;

                float interp = hitPosBoxSpace.z * 0.5 + 0.5;

                float realZ = saturate(interp) / depthScale + 1;
                interp = 1.0 - (1.0 / realZ);
                interp *= depthScale + 1.0;
                z = interp;
                float2 interiorUV = hitPosBoxSpace.xy * lerp(1.0, 1.0 - depth, interp);

                return interiorUV * 0.5 + 0.5;
            }

            float3 fresnelSchlick(float3 F0, float cosTheta)
            {
                return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5);
            }

            float ndfGGX(float cosLh, float roughness)
            {
                float alpha = roughness * roughness;
                float alphaSq = alpha * alpha;

                float denom = (cosLh * cosLh) * (alphaSq - 1.0) + 1.0;
                return alphaSq / (PI * denom * denom);
            }

            float gaSchlickG1(float cosTheta, float k)
            {
                return cosTheta / (cosTheta * (1.0 - k) + k);
            }

            float gaSchlickGGX(float cosLi, float cosLo, float roughness)
            {
                float r = roughness + 1.0;
                float k = (r * r) / 8.0; // Epic suggests using this roughness remapping for analytic lights.
                return gaSchlickG1(cosLi, k) * gaSchlickG1(cosLo, k);
            }


            v2f vert(app2vert v)
            {
                v2f o = (v2f)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                float4x4 modelMatrix = unity_ObjectToWorld;
                float4x4 modelMatrixInverse = unity_WorldToObject;

                float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
                float3 bitangent = cross(v.normal, v.tangent.xyz) * tangentSign;
                float3x3 tbn = float3x3(v.tangent.xyz, bitangent, v.normal.xyz);
                o.tbn = mul((float3x3)modelMatrix, transpose(tbn));

                o.positionWS = TransformObjectToWorld(v.position.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.positionOS = v.position.xyz;
                o.viewDirWS = -(mul(modelMatrix, v.position).xyz - _WorldSpaceCameraPos);

                // interrior mapping for 2d texture atlas
                float3 camPosObjectSpace = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
                float3 viewDirObjectSpace = normalize(v.position.xyz - camPosObjectSpace);
                o.tangentViewDir = mul(tbn, viewDirObjectSpace);

                float3 baseWorldPos = unity_ObjectToWorld._m03_m13_m23;

                float2 lightmapUv = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
                o.uv0 = float4(v.uv0, lightmapUv);
                o.uv1.xyz = frac(baseWorldPos) * 10;
                o.uv1.w = fmod(baseWorldPos.y, 16);

                return o;
            }


            half4 frag(v2f i) : SV_Target
            {
                half2 uv0 = i.uv0.xy;
                half2 lightmapUV = i.uv0.zw;
                half3 interiorUV = float3(i.uv1.xy, 0.0);

                half3 lightmapColor = SampleLightmapWithoutNormal(lightmapUV);
                half2 normalUV = TRANSFORM_TEX(uv0, _Normal);
                half4 normal = SAMPLE_TEXTURE2D(_Normal, SamplerState_Linear_Repeat, normalUV);
                normal.rgb = UnpackNormal(normal);
                normal.rgb = normalize(mul(i.tbn, normal));

                half4 interior = 0.5;
                half interriorPixelDepth = 0.0;
                half tileDepth = _AtlasParam.w;
                half tileId = hash1(i.uv1.w) * _AtlasParam.x * _AtlasParam.y;

                #if _INTERIOR_ATLAS_2D
                    half indx = floor(i.uv0.x);
                    tileId = indx;
                    interiorUV.xy = TextureCoord2Interior2dAtlas(frac(i.uv0.xy), i.tangentViewDir, tileDepth, interriorPixelDepth);
                    half2 tileScale = rcp(_AtlasParam.xy);
                    interiorUV.xy *= tileScale;
                    half tilex = floor(tileId % _AtlasParam.x);
                    half tiley = floor(tileId / _AtlasParam.y);
                    interiorUV.xy += float2(tileScale.x, tileScale.y) * float2(tilex, tiley);
                    interior = SAMPLE_TEXTURE2D(_Interior2DAtlas,  SamplerState_Linear_Repeat, interiorUV.xy);
                #elif _INTERIOR_ATLAS_CUBE
                    interiorUV = TextureCoord2InteriorCube(frac(i.uv0.xy), i.tangentViewDir, tileDepth);
                    interior = SAMPLE_TEXTURECUBE_ARRAY(_InteriorCubemapArray, SamplerState_Linear_Repeat, interiorUV, tileId);
                #elif _INTERIOR_NONE
                    interior = SAMPLE_TEXTURE2D(_Interior2DAtlas, SamplerState_Linear_Repeat, i.uv0.xy * 0.25);
                #endif

                half3 mask = SAMPLE_TEXTURE2D(_Mask, SamplerState_Linear_Repeat, uv0).rgb * lightmapColor;
                half4 dirt = SAMPLE_TEXTURE2D(_Dirt, SamplerState_Linear_Repeat, uv0).rrrr * _DirtIntensity;

                half3 Lo = normalize(i.viewDirWS.xyz);
                half3 N = normal;

                Light mainLight = GetMainLight(0, i.positionWS, 0);
                half cosLo = max(0.01, dot(N, Lo));
                half3 Li = mainLight.direction;
                half3 Lh = normalize(Li + Lo);
                half fresnel = _FresnelFalloff + (1.0f - _FresnelFalloff) * pow(abs(1.0f - dot(N, Lo)), 5);

                // Direct specular from pbr shading.
                half roughness = max(0.05, dirt.r);
                half metalness = _Roughness;
                // Glass albedo.
                half3 albedo = 1;
                // Environment reflection.
                half4 envRefl = 0;
                half3 specular = 0;
                half3 F0 = lerp(0.75, albedo, metalness);

                half cosLi = max(0.01, dot(N, Li));
                {
                    half cosLh = max(0.01, dot(N, Lh));
                    half3 F = fresnelSchlick(F0, cosLo);
                    half D = ndfGGX(cosLh, roughness);
                    half G = gaSchlickGGX(cosLi, cosLo, roughness);
                    specular = (F * D * G) / max(0.001, 4.0 * cosLi * cosLo);

                    half3 reflectView = reflect(-Lo, normal);
                    half dr = lerp(0, _Roughness * 4, roughness);
                    half maxLod = 8;
                    envRefl = SAMPLE_TEXTURECUBE_LOD(_Environment, SamplerState_Linear_Repeat, reflectView,
                                                     dr * maxLod);
                }

                // Fade interior by depth and NdotL.
                interior.rgb = lerp(interior.rgb, envRefl.rgb, fresnel);
                // TODO: Remove when geometry is separated.
                half m = step(0.05, Luminance(mask.rgb));
                half3 color = (interior.rgb + specular);
                // Apply mask.
                color = lerp(color, mask.rgb, m);

                half4 fogColor;
                float fogDensity;
                SHADERGRAPH_FOG(i.positionOS, fogColor, fogDensity);
                color = lerp(color, fogColor.xyz, fogDensity);
                return half4(color, 1);
            }
            ENDHLSL
        }
    }
}