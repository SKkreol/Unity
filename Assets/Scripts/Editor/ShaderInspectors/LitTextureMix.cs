using UnityEditor;
using UnityEngine;

namespace Game.Editor.ShaderInspectors
{
  public sealed class LitTextureMix: Lit
  {
    private static readonly GUIContent SecondMap = EditorGUIUtility.TrTextContent("Second Map",
      "Specifies the second texture mixed in this shader. This texture corresponds to a Green(G) channel of Splat Map (or vertex color)");

    private static readonly GUIContent ThirdMap = EditorGUIUtility.TrTextContent("Third Map",
      "Specifies the third texture mixed in this shader. This texture corresponds to a Blue(B) channel of Splat Map (or vertex color)");

    private static readonly GUIContent SplatMap = EditorGUIUtility.TrTextContent("Splat Map",
      "Specifies a mask for texture mixing. If nothing is selected then vertex color will be used as a mask. Slider controls blending sharpness");

    private static readonly GUIContent SecondNormalMap = EditorGUIUtility.TrTextContent("Second Normal Map", "Only Mixed if Base NormalMap is present");

    private MaterialProperty? _mainMapProperty;

    private MaterialProperty? _splatMapProperty;
    private MaterialProperty? _depthProperty;

    private MaterialProperty? _secondColorProperty;
    private MaterialProperty? _secondMapProperty;
    private MaterialProperty? _secondSmoothnessProperty;
    private MaterialProperty? _secondMetallicProperty;
    private MaterialProperty? _secondNormalMapProperty;

    private MaterialProperty? _thirdColorProperty;
    private MaterialProperty? _thirdMapProperty;
    private MaterialProperty? _thirdSmoothnessProperty;
    private MaterialProperty? _thirdMetallicProperty;

    protected override void ValidateAdditionalProperties(Material material)
    {
      if (_secondMapProperty == null || _thirdMapProperty == null)
        return;

      var noMainTexture = _mainMapProperty != null && _mainMapProperty.textureValue == null;

      // No Texture Values
      if (noMainTexture || _secondMapProperty.textureValue == null && _thirdMapProperty.textureValue == null)
      {
        ToggleKeyword(material, false, "SPLATMAP");
        ToggleKeyword(material, false, "TEXTURE_MIX");
        ToggleKeyword(material, false, "THREE_TEXTURES");
        ToggleKeyword(material, false, "SECOND_BUMP");
        return;
      }

      if (_splatMapProperty != null)
        ToggleKeyword(material, _splatMapProperty.textureValue != null, "SPLATMAP");

      var useSecondNormal = false;
      if (_secondNormalMapProperty != null)
        useSecondNormal = _secondNormalMapProperty.textureValue != null;

      var hasSecondMap = _secondMapProperty.textureValue != null;
      ToggleKeyword(material, hasSecondMap, "TEXTURE_MIX");
      ToggleKeyword(material, hasSecondMap && useSecondNormal, "SECOND_BUMP");

      var hasThirdMap = _thirdMapProperty.textureValue != null;
      ToggleKeyword(material, hasSecondMap && hasThirdMap, "THREE_TEXTURES");
    }

    protected override void FindAdditionalProperties(MaterialProperty[] properties)
    {
      _mainMapProperty = FindProperty("_MainTex", properties, false);

      _splatMapProperty = FindProperty("_SplatMap", properties, false);
      _depthProperty = FindProperty("_Depth", properties, false);

      _secondColorProperty =  FindProperty("_SecondColor", properties, false);
      _secondMapProperty = FindProperty("_SecondMap", properties, false);
      _secondSmoothnessProperty = FindProperty("_SecondSmoothness", properties, false);
      _secondMetallicProperty = FindProperty("_SecondMetallic", properties, false);
      _secondNormalMapProperty = FindProperty("_SecondMapNormal", properties, false);

      _thirdColorProperty =  FindProperty("_ThirdColor", properties, false);
      _thirdMapProperty = FindProperty("_ThirdMap", properties, false);
      _thirdSmoothnessProperty = FindProperty("_ThirdSmoothness", properties, false);
      _thirdMetallicProperty = FindProperty("_ThirdMetallic", properties, false);
    }

    protected override void DrawAdditionalProperties(Material material)
    {
      EditorGUILayout.Space(25);
      materialEditor.TexturePropertySingleLine(SecondMap, _secondMapProperty, _secondColorProperty);
      if (_secondMapProperty == null || _secondMapProperty.textureValue == null)
        return;

      DrawSlider(_secondSmoothnessProperty);
      DrawSlider(_secondMetallicProperty);
      materialEditor.TexturePropertySingleLine(SecondNormalMap, _secondNormalMapProperty);
      DrawTileOffset(materialEditor, _secondMapProperty);

      if (_thirdMapProperty != null)
      {
        EditorGUILayout.Space(25);
        materialEditor.TexturePropertySingleLine(ThirdMap, _thirdMapProperty, _thirdColorProperty);
        if (_thirdMapProperty.textureValue != null)
        {
          DrawSlider(_thirdSmoothnessProperty);
          DrawSlider(_thirdMetallicProperty);
          DrawTileOffset(materialEditor, _thirdMapProperty);
        }
      }

      if (_splatMapProperty == null)
        return;
      EditorGUILayout.Space(25);
      materialEditor.TexturePropertySingleLine(SplatMap, _splatMapProperty, _depthProperty);
      DrawTileOffset(materialEditor, _splatMapProperty);
    }
  }
}