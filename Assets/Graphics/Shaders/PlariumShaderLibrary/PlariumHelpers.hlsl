#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"


half3 BlendTwo(half4 texture1, half4 texture2, half2 mask, half depth)
{
    half ma = max(texture1.a + mask.x, texture2.a + mask.y) - depth;
    half b1 = max(texture1.a + mask.x - ma, 0);
    half b2 = max(texture2.a + mask.y - ma, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
}

half BlendHeight2(half2 h, half2 mask, half depth)
{
    half ma = max(h.x + mask.x, h.y + mask.y) - depth;
    return ma;
}

half BlendHeight3(half3 h, half3 mask, half depth)
{
    half ma = max(max(h.x + mask.r, h.y + mask.g), h.z + mask.b) - depth;
    return ma;
}

half3 BlendThree(half4 texture1, half4 texture2, half4 texture3, half3 mask, half depth)
{
    half a1 = mask.r;
    half a2 = mask.g;
    half a3 = mask.b;

    half ma = max(max(texture1.a + a1, texture2.a + a2), texture3.a + a3) - depth;
    half b1 = max(texture1.a + a1 - ma, 0);
    half b2 = max(texture2.a + a2 - ma, 0);
    half b3 = max(texture3.a + a3 - ma, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2 + texture3.rgb * b3) / (b1 + b2 + b3);
}

half3 BlendTwoByHeight(half4 texture1, half4 texture2, half2 mask, half height)
{
    half b1 = max(texture1.a + mask.x - height, 0);
    half b2 = max(texture2.a + mask.y - height, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2) / (b1 + b2);
}

half3 BlendThreeByHeight(half4 texture1, half4 texture2, half4 texture3, half3 mask, half height)
{
    half a1 = mask.r;
    half a2 = mask.g;
    half a3 = mask.b;

    half b1 = max(texture1.a + a1 - height, 0);
    half b2 = max(texture2.a + a2 - height, 0);
    half b3 = max(texture3.a + a3 - height, 0);

    return (texture1.rgb * b1 + texture2.rgb * b2 + texture3.rgb * b3) / (b1 + b2 + b3);
}

// Transform Normal Map Coords
half3 TransformTextureNormalsToWorld(half4 normalsColors, half3 normalsWS, half4 tangentWS)
{
    half3 normalTS = UnpackNormal(normalsColors);
    float sgn = tangentWS.w;  // should be either +1 or -1
    float3 bitangent = sgn * cross(normalsWS.xyz, tangentWS.xyz);
    half3x3 tangentToWorld = half3x3(tangentWS.xyz, bitangent.xyz, normalsWS.xyz);
    half3 normals = TransformTangentToWorld(normalTS, tangentToWorld);
    normals = SafeNormalize(normals);
    return normals;
}

// Simple Normals Blending
half3 BlendNormalMaps(half3 baseNormal, half3 detailNormal)
{
    half3 mixedNormal = half3(0, 0, baseNormal.b);
    mixedNormal.r = baseNormal.r + detailNormal.r;
    mixedNormal.g = baseNormal.g + detailNormal.g;
    return normalize(mixedNormal);
}

// Complex Normals Blending
half3 BlendNormalReorient(half3 baseNormal, half3 detailNormal)
{
    half3 t = baseNormal.xyz + half3(0.0, 0.0, 1.0);
    half3 u = detailNormal.xyz * half3(-1.0, -1.0, 1.0);
    return (t / t.z) * dot(t, u) - u;
}

half ColorToGrayscale(half3 color)
{
    return (0.299 * color.r) + (0.587 * color.g) + (0.114 * color.b);
}
