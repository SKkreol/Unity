using UnityEditor;
using UnityEngine;

namespace Game.Editor.ShaderInspectors
{
  public class Roads: BaseShaderGUI
  {
    private static readonly float HeaderSpacing = 15;
    private static readonly float Spacing = 5;
    private static readonly string GroupStyle = "box";

    // Main.
    private static readonly GUIContent MainTexGUI = EditorGUIUtility.TrTextContent("Albedo", "Albedo Texture");
    private static readonly GUIContent MetallicGlossGUI =
      EditorGUIUtility.TrTextContent("Mask", "Metallic(R), AO(G), Smoothness(B)");
    private static readonly GUIContent BumpGUI = EditorGUIUtility.TrTextContent("Normal Map", "Normal Map Texture");
    private static readonly GUIContent UseWorldUVGUI = EditorGUIUtility.TrTextContent("Use World UV", "Use World UV");
    private MaterialProperty? _mainTex, _colorProperty;
    private MaterialProperty? _metallicGlossMap, _smoothnessSlider;
    private MaterialProperty? _bumpMap;
    private MaterialProperty? _useWorldUV, _mainTile;

    // Surface Masks.
    private static readonly GUIContent GroundSplatMaskGUI = EditorGUIUtility.TrTextContent("Ground Splat Mask UV4",
      "Dirt Mask(R), Leaves Piles(G), Puddles(B), Leaves Scattered(A)");
    private static readonly GUIContent GroundSurfaceMaskGUI = EditorGUIUtility.TrTextContent("Ground Surface Mask",
      "Decals Variation(R), Dirt(G), Car Trails(B)");
    private MaterialProperty? _groundSDFMask;
    private MaterialProperty? _groundSurfaceMask;

    // Decals.
    private static readonly GUIContent DecalsAlbedoGUI = EditorGUIUtility.TrTextContent("Decals Albedo",
      "Texture Color (RGB), Decals Mask (A)");
    private static readonly GUIContent DecalsNormalGUI = EditorGUIUtility.TrTextContent("Decals Normal Map",
      "Decals Normal Map");
    private MaterialProperty? _decalsAlbedo, _decalColor;
    private MaterialProperty? _decalsSmoothness;
    private MaterialProperty? _decalsNormal;
    private MaterialProperty? _decalsMaskTile, _decalsMaskAmount, _decalsMaskSoftness;

    // Leaves.
    private static readonly GUIContent LeavesAlbedoGUI = EditorGUIUtility.TrTextContent("Leaves Albedo",
      "Texture Color (RGB), A (Height)");
    private static readonly GUIContent LeavesNormalGUI = EditorGUIUtility.TrTextContent("Leaves Normal",
      "Leaves Normal Map Texture");
    private MaterialProperty? _leavesAlbedo;
    private MaterialProperty? _leavesTint;
    private MaterialProperty? _leavesNormal;
    private MaterialProperty? _leavesSmoothness;
    private MaterialProperty? _leavesTile;
    private MaterialProperty? _leavesTintInPuddles;
    private MaterialProperty? _leavesSmoothnessInPuddles;
    private MaterialProperty? _leavesGreenMinMax;
    private MaterialProperty? _leavesAlphaMinMax;

    // Dirt.
    private MaterialProperty? _dirtColor, _dirtSmoothness;
    private MaterialProperty? _dirtEdgeOffset, _dirtMaskMultiplier;
    private MaterialProperty? _dirtTile;

    // Puddles.
    private MaterialProperty? _puddlesWaterColor, _puddlesDryColor;
    private MaterialProperty? _puddlesDrySmoothnessMultiplier;
    private MaterialProperty? _puddlesDryArea;
    private MaterialProperty? _puddlesDistortion, _puddlesScale;
    private MaterialProperty? _carTrailsColor, _carTrailsSmoothness;

    public override void ValidateMaterial(Material material)
    {
      if (_useWorldUV == null)
        return;

      var isWorldUV = _useWorldUV.floatValue >= 0.5;
      if (isWorldUV)
      {
        material.EnableKeyword("USE_WORLD_UV");
        return;
      }

      material.DisableKeyword("USE_WORLD_UV");
    }

    public override void FindProperties(MaterialProperty[] properties)
    {
      _colorProperty = FindProperty("_Tint", properties, false);
      _mainTex = FindProperty("_Albedo", properties, false);
      _metallicGlossMap = FindProperty("_MetallicGlossMap", properties, false);
      _smoothnessSlider = FindProperty("_Smoothness", properties, false);
      _bumpMap = FindProperty("_Normal", properties, false);
      _useWorldUV = FindProperty("_UseWorldUV", properties, false);
      _mainTile = FindProperty("_Tile", properties, false);

      _groundSDFMask = FindProperty("_GroundSDFMask", properties, false);
      _groundSurfaceMask = FindProperty("_GroundSurfaceMask", properties, false);

      _leavesAlbedo = FindProperty("_Variation_Albedo", properties, false);
      _leavesTint = FindProperty("_VariationTint", properties, false);
      _leavesNormal = FindProperty("_Variation_Normal", properties, false);
      _leavesSmoothness = FindProperty("_Variation_Smoothness", properties, false);
      _leavesTile = FindProperty("_Variation_Tile", properties, false);
      _leavesTintInPuddles = FindProperty("_VariationTintInPuddles", properties, false);
      _leavesSmoothnessInPuddles = FindProperty("_VariationSmoothnessInPuddles", properties, false);
      _leavesGreenMinMax = FindProperty("_VariationMinMax", properties, false);
      _leavesAlphaMinMax = FindProperty("_SDFAlpha_MinMax", properties, false);

      _dirtEdgeOffset = FindProperty("_DirtEdgeOffset", properties, false);
      _dirtMaskMultiplier = FindProperty("_DirtMultiplier", properties, false);
      _dirtColor = FindProperty("_DirtColor", properties, false);
      _dirtSmoothness = FindProperty("_DirtSmoothness", properties, false);
      _dirtTile = FindProperty("_DirtTile", properties, false);

      _puddlesWaterColor = FindProperty("_Puddles_Water_Color", properties, false);
      _puddlesDistortion = FindProperty("_PuddlesDistortion", properties, false);
      _puddlesScale = FindProperty("_Puddles_Scale", properties, false);
      _puddlesDryColor = FindProperty("_PuddlesDryColor", properties, false);
      _puddlesDryArea = FindProperty("_PuddlesDryArea", properties, false);
      _puddlesDrySmoothnessMultiplier = FindProperty("_PuddlesDrySmoothnessMultiplier", properties, false);
      _carTrailsColor = FindProperty("_CarTrailsColor", properties, false);
      _carTrailsSmoothness = FindProperty("_CarTrailsSmoothness", properties, false);

      _decalColor = FindProperty("_DecalColor", properties, false);
      _decalsAlbedo = FindProperty("_Decals_Albedo", properties, false);
      _decalsSmoothness = FindProperty("_Decals_Smoothness", properties, false);
      _decalsNormal = FindProperty("_Decals_Normal", properties, false);
      _decalsMaskTile = FindProperty("_Decals_Mask_Tile", properties, false);
      _decalsMaskAmount = FindProperty("_Decals_Mask_Amount", properties, false);
      _decalsMaskSoftness = FindProperty("_Decals_Mask_Softness", properties, false);
    }

    public override void DrawSurfaceInputs(Material material)
    {
      DrawMainMaterialProperties();
      DrawSurfaceMasksProperties();
      DrawDecalsProperties();
      DrawLayersProperties();
      materialEditor.RenderQueueField();
    }

    private void DrawMainMaterialProperties()
    {
      GUILayout.BeginVertical("Main", GroupStyle);
      EditorGUILayout.Space(HeaderSpacing);
      if(_mainTex != null && _colorProperty != null)
        TextureColorProps(materialEditor, MainTexGUI, _mainTex, _colorProperty);

      if (_mainTile != null)
        materialEditor.FloatProperty(_mainTile, _mainTile.displayName);

      if (_useWorldUV != null)
        BakedLit.DrawFloatToggleProperty(UseWorldUVGUI, _useWorldUV);

      DrawTexturePropertyIfNotNull(MetallicGlossGUI, _metallicGlossMap, _smoothnessSlider);
      DrawTexturePropertyIfNotNull(BumpGUI, _bumpMap);
      GUILayout.EndVertical();
      EditorGUILayout.Space(Spacing);
    }

    private void DrawSurfaceMasksProperties()
    {
        GUILayout.BeginVertical("Surface Masks", GroupStyle);
        EditorGUILayout.Space(HeaderSpacing);
        DrawTexturePropertyIfNotNull(GroundSplatMaskGUI, _groundSDFMask);
        DrawTexturePropertyIfNotNull(GroundSurfaceMaskGUI, _groundSurfaceMask);
        GUILayout.EndVertical();
        EditorGUILayout.Space(Spacing);
    }

    private void DrawDecalsProperties()
    {
      GUILayout.BeginVertical("Decals UV3", GroupStyle);
      EditorGUILayout.Space(HeaderSpacing);
      if(_decalsAlbedo != null && _decalColor != null)
        TextureColorProps(materialEditor, DecalsAlbedoGUI, _decalsAlbedo, _decalColor);
      if(_decalsAlbedo?.textureValue == null)
      {
        GUILayout.EndVertical();
        EditorGUILayout.Space(Spacing);
        return;
      }

      DrawSlider(_decalsSmoothness);
      DrawTexturePropertyIfNotNull(DecalsNormalGUI, _decalsNormal);

      if (_decalsMaskTile != null && _decalsMaskSoftness != null)
      {
        var title = EditorGUIUtility.TrTextContent("Mask:", "");
        var firstLabel = EditorGUIUtility.TrTextContent("Tile", "");
        var secondLabel = EditorGUIUtility.TrTextContent("Softness", "");
        TwoFloatSingleLine(title, _decalsMaskTile, firstLabel, _decalsMaskSoftness, secondLabel, materialEditor);
      }
      DrawSlider(_decalsMaskAmount);
      GUILayout.EndVertical();
      EditorGUILayout.Space(Spacing);
    }

    private void DrawLayersProperties()
    {
      if(_groundSDFMask?.textureValue == null)
        return;

      DrawLeavesLayer();
      DrawPuddlesLayer();
      DrawDirtLayer();
    }

    private void DrawPuddlesLayer()
    {
      GUILayout.BeginVertical("Puddles Layer", GroupStyle);
      EditorGUILayout.Space(HeaderSpacing);
      if (_puddlesWaterColor != null)
        materialEditor.ColorProperty(_puddlesWaterColor, _puddlesWaterColor.displayName);
      if (_puddlesDryColor != null)
        materialEditor.ColorProperty(_puddlesDryColor, _puddlesDryColor.displayName);

      DrawSlider(_puddlesDrySmoothnessMultiplier,2);
      DrawSlider(_puddlesDryArea);

      if (_puddlesScale != null && _puddlesDistortion != null)
      {
        var title = EditorGUIUtility.TrTextContent("Noise:", "");
        var firstLabel = EditorGUIUtility.TrTextContent("Tile", "");
        var secondLabel = EditorGUIUtility.TrTextContent("Amount", "");
        TwoFloatSingleLine(title, _puddlesScale, firstLabel, _puddlesDistortion, secondLabel, materialEditor);
      }

      if (_carTrailsColor != null)
        materialEditor.ColorProperty(_carTrailsColor, _carTrailsColor.displayName);
      DrawSlider(_carTrailsSmoothness);

      GUILayout.EndVertical();
      EditorGUILayout.Space(Spacing);
    }

    private void DrawLeavesLayer()
    {
      GUILayout.BeginVertical("Leaves Layer", GroupStyle);
      EditorGUILayout.Space(HeaderSpacing);
      if(_leavesAlbedo != null && _leavesTint != null)
        TextureColorProps(materialEditor, LeavesAlbedoGUI, _leavesAlbedo, _leavesTint);

      if (_leavesAlbedo?.textureValue == null)
      {
        GUILayout.EndVertical();
        EditorGUILayout.Space(Spacing);
        return;
      }

      if (_leavesTintInPuddles != null)
        materialEditor.ColorProperty(_leavesTintInPuddles, "In Puddles");

      DrawSlider(_leavesTile);

      if (_leavesSmoothness != null && _leavesSmoothnessInPuddles != null)
      {
        var title = EditorGUIUtility.TrTextContent("Smoothness", "");
        var firstLabel = EditorGUIUtility.TrTextContent("Base", "");
        var secondLabel = EditorGUIUtility.TrTextContent("In Puddles", "");
        TwoFloatSingleLine(title, _leavesSmoothness, firstLabel, _leavesSmoothnessInPuddles, secondLabel, materialEditor);
      }

      DrawTexturePropertyIfNotNull(LeavesNormalGUI, _leavesNormal);

      if(_leavesGreenMinMax != null)
        materialEditor.VectorProperty(_leavesGreenMinMax, "(G) Mask Levels");
      if(_leavesAlphaMinMax != null)
        materialEditor.VectorProperty(_leavesAlphaMinMax, "(A) Mask Levels");

      GUILayout.EndVertical();
      EditorGUILayout.Space(Spacing);
    }

    private void DrawDirtLayer()
    {
      GUILayout.BeginVertical("Dirt Layer", GroupStyle);
      EditorGUILayout.Space(HeaderSpacing);
      if (_dirtColor != null)
        materialEditor.ColorProperty(_dirtColor, _dirtColor.displayName);

      if (_dirtEdgeOffset != null && _dirtMaskMultiplier != null)
      {
        var title = EditorGUIUtility.TrTextContent("Mask Settings:", "");
        var firstLabel = EditorGUIUtility.TrTextContent("Offset", "");
        var secondLabel = EditorGUIUtility.TrTextContent("Multiplier", "");
        TwoFloatSingleLine(title, _dirtEdgeOffset, firstLabel, _dirtMaskMultiplier, secondLabel, materialEditor);
      }

      DrawSlider(_dirtSmoothness);
      DrawSlider(_dirtTile);

      GUILayout.EndVertical();
      EditorGUILayout.Space(Spacing);
    }

    private void DrawTexturePropertyIfNotNull(GUIContent label, MaterialProperty? property, MaterialProperty? secondProperty = null)
    {
      if (property != null)
        materialEditor.TexturePropertySingleLine(label, property, secondProperty);
    }

    private void DrawSlider(MaterialProperty? sliderProp, float max = 1)
    {
      if (sliderProp == null)
        return;

      EditorGUI.BeginChangeCheck();
      var value = EditorGUILayout.Slider(sliderProp.displayName, sliderProp.floatValue, 0, max);

      if (EditorGUI.EndChangeCheck())
        sliderProp.floatValue = value;
    }
  }
}