using System;
using UnityEditor;
using UnityEngine;

namespace Game.Editor.ShaderInspectors
{
  public class Lit : BaseShaderGUI
  {
    private static readonly string MainTexKey = "MAINTEX";
    private static readonly string MetallicGlossMapKey = "METALLICGLOSSMAP";
    private static readonly string BumpMapKey = "BUMPMAP";

    private static readonly GUIContent AlphaMaskText = EditorGUIUtility.TrTextContent("Use Alpha as Color Mask",
      "When enabled, Alpha Channel of Albedo Texture will be used as a mask for Color property.");

    private static readonly GUIContent MainTexGUI = EditorGUIUtility.TrTextContent("Albedo", "Albedo Texture");

    private static readonly GUIContent MetallicGlossGUI =
      EditorGUIUtility.TrTextContent("Mask", "Metallic(R), AO(G), Smoothness(B)");

    private static readonly GUIContent BumpGUI = EditorGUIUtility.TrTextContent("Normal Map", "Normal Map Texture");

    private static readonly GUIContent SwapBandG = EditorGUIUtility.TrTextContent("Swap B and G channels",
      "When enabled, channels of Mask are set as follows: Metallic(R), Smoothness(G), AO(B)");

    private MaterialProperty? _colorProperty;
    private MaterialProperty? _mainTex;
    private MaterialProperty? _metallicGlossMap;
    private MaterialProperty? _metallicSlider;
    private MaterialProperty? _smoothnessSlider;
    private MaterialProperty? _bumpMap;
    private MaterialProperty? _swapBandG;
    private MaterialProperty? _useAlphaAsColorMaskProperty;

    public override void ValidateMaterial(Material material)
    {
      ValidateMainLitProperties(material);
      ValidateAdditionalProperties(material);
    }

    private void ValidateMainLitProperties(Material material)
    {
      if (_mainTex != null)
        ToggleKeyword(material, _mainTex.textureValue != null, MainTexKey);

      if (_metallicGlossMap != null)
        ToggleKeyword(material, _metallicGlossMap.textureValue != null, MetallicGlossMapKey);

      if (_bumpMap != null)
        ToggleKeyword(material, _bumpMap.textureValue != null, BumpMapKey);

      SetupMaterialBlendMode(material);
    }

    protected virtual void ValidateAdditionalProperties(Material material) { }

    public override void FindProperties(MaterialProperty[] properties)
    {
      FindMainLitProperties(properties);
      FindAdditionalProperties(properties);
      FindBlendModeProperties(properties);
    }

    private void FindMainLitProperties(MaterialProperty[] properties)
    {
      _colorProperty = FindProperty("_Color", properties, false);
      _mainTex = FindProperty("_MainTex", properties, false);
      _metallicGlossMap = FindProperty("_MetallicGlossMap", properties, false);
      _metallicSlider = FindProperty("_Metallic", properties, false);
      _smoothnessSlider = FindProperty("_Smoothness", properties, false);
      _bumpMap = FindProperty("_BumpMap", properties, false);
      _swapBandG = FindProperty("_SwapBandG", properties, false);
      _useAlphaAsColorMaskProperty = FindProperty("_UseAlphaAsColorMask", properties, false);
    }

    private void FindBlendModeProperties(MaterialProperty[] properties)
    {
      surfaceTypeProp = FindProperty("_Surface", properties, false);
      blendModeProp = FindProperty("_Blend", properties, false);
      cullingProp = FindProperty("_Cull", properties, false);
      zwriteProp = FindProperty("_ZWriteControl", properties, false);
      ztestProp = FindProperty("_ZTest", properties, false);
      alphaClipProp = FindProperty("_AlphaClip", properties, false);
      alphaCutoffProp = FindProperty("_Cutoff", properties, false);
    }

    public override void DrawSurfaceOptions(Material material)
    {
      if (material == null)
        throw new ArgumentNullException(nameof(material));

      // Use default labelWidth
      EditorGUIUtility.labelWidth = 0f;

      base.DrawSurfaceOptions(material);
    }

    protected virtual void FindAdditionalProperties(MaterialProperty[] properties) { }

    public override void DrawSurfaceInputs(Material material)
    {
      DrawMainLitProperties(material);
      DrawAdditionalProperties(material);
      EditorGUILayout.Space(5);
      materialEditor.RenderQueueField();
    }

    private void DrawMainLitProperties(Material material)
    {
      if (_mainTex != null && _colorProperty != null)
      {
        materialEditor.TexturePropertySingleLine(MainTexGUI, _mainTex, _colorProperty);
        materialEditor.TextureScaleOffsetProperty(_mainTex);
        BakedLit.DrawFloatToggleProperty(AlphaMaskText, _useAlphaAsColorMaskProperty);
        EditorGUILayout.Space(5);
      }

      if (_metallicGlossMap != null && _smoothnessSlider != null)
      {
        materialEditor.TexturePropertySingleLine(MetallicGlossGUI, _metallicGlossMap, _smoothnessSlider);
      }

      if (_swapBandG != null)
        BakedLit.DrawFloatToggleProperty(SwapBandG, _swapBandG);

      DrawSlider(_metallicSlider);

      if (_bumpMap != null)
      {
        materialEditor.TexturePropertySingleLine(BumpGUI, _bumpMap);
      }
    }

    protected virtual void DrawAdditionalProperties(Material material) { }

    protected void DrawSlider(MaterialProperty? sliderProp)
    {
      if (sliderProp == null)
        return;

      EditorGUI.BeginChangeCheck();
      var value = EditorGUILayout.Slider(sliderProp.displayName, sliderProp.floatValue, 0, 1);

      if (EditorGUI.EndChangeCheck())
        sliderProp.floatValue = value;
    }

    protected static void ToggleKeyword(Material mat, bool value, string keyword)
    {
      if (value)
      {
        mat.EnableKeyword(keyword);
        return;
      }

      mat.DisableKeyword(keyword);
    }
  }
}