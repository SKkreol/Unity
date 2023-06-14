using System;
using UnityEditor;
using UnityEngine;

namespace Game.Editor.ShaderInspectors
{
  public class TextureMix : BaseShaderGUI
  {
    private static readonly GUIContent SecondMap = EditorGUIUtility.TrTextContent("Second Map",
      "Specifies the second texture mixed in this shader. This texture corresponds to a Green(G) channel of Splat Map (or vertex color)");

    private static readonly GUIContent ThirdMap = EditorGUIUtility.TrTextContent("Third Map",
      "Specifies the third texture mixed in this shader. This texture corresponds to a Blue(B) channel of Splat Map (or vertex color)");

    private static readonly GUIContent SplatMap = EditorGUIUtility.TrTextContent("Splat Map",
      "Specifies a mask for texture mixing. If nothing is selected then vertex color will be used as a mask. Slider controls blending sharpness");

    private MaterialProperty? _secondMapProperty;
    private MaterialProperty? _thirdMapProperty;
    private MaterialProperty? _splatMapProperty;
    private MaterialProperty? _depthProperty;
    private MaterialProperty? _secondColorProperty;
    private MaterialProperty? _thirdColorProperty;


    public override void ValidateMaterial(Material material)
    {
      SetMaterialKeywords(material);

      if (_splatMapProperty == null)
        return;

      if (_splatMapProperty.textureValue != null)
        material.EnableKeyword("SPLATMAP");
      else
        material.DisableKeyword("SPLATMAP");

      if (_secondMapProperty == null || _thirdMapProperty == null)
        return;

      if (_secondMapProperty.textureValue != null && baseMapProp.textureValue == null)
      {
        baseMapProp.textureValue = _secondMapProperty.textureValue;
        _secondMapProperty.textureValue = null;
      }

      if (_thirdMapProperty.textureValue != null && _secondMapProperty.textureValue == null)
      {
        _secondMapProperty.textureValue = _thirdMapProperty.textureValue;
        _thirdMapProperty.textureValue = null;
      }

      if (_thirdMapProperty.textureValue != null)
      {
        material.EnableKeyword("THREE_TEXTURES");
        material.DisableKeyword("TWO_TEXTURES");
        return;
      }

      if (_secondMapProperty.textureValue != null)
      {
        material.EnableKeyword("TWO_TEXTURES");
        material.DisableKeyword("THREE_TEXTURES");
        return;
      }

      material.DisableKeyword("TWO_TEXTURES");
      material.DisableKeyword("THREE_TEXTURES");
      material.DisableKeyword("SPLATMAP");
    }

    public override void FindProperties(MaterialProperty[] properties)
    {
      _secondMapProperty = FindProperty("_SecondMap", properties, false);
      _thirdMapProperty = FindProperty("_ThirdMap", properties, false);
      _splatMapProperty = FindProperty("_SplatMap", properties, false);
      _depthProperty = FindProperty("_Depth", properties, false);
      _secondColorProperty =  FindProperty("_SecondColor", properties, false);
      _thirdColorProperty =  FindProperty("_ThirdColor", properties, false);
      base.FindProperties(properties);
    }

    public override void DrawSurfaceOptions(Material material)
    {
      if (material == null)
        throw new ArgumentNullException(nameof(material));

      // Use default labelWidth.
      EditorGUIUtility.labelWidth = 0f;

      base.DrawSurfaceOptions(material);
    }

    public override void DrawSurfaceInputs(Material material)
    {
      base.DrawSurfaceInputs(material);
      DrawTileOffset(materialEditor, baseMapProp);

      if (baseMapProp.textureValue != null)
      {
        materialEditor.TexturePropertySingleLine(SecondMap, _secondMapProperty, _secondColorProperty);

        if (_secondMapProperty != null && _secondMapProperty.textureValue != null)
          materialEditor.TexturePropertySingleLine(ThirdMap, _thirdMapProperty, _thirdColorProperty);
      }

      if (_splatMapProperty == null)
        return;

      materialEditor.TexturePropertySingleLine(SplatMap, _splatMapProperty, _depthProperty);
      DrawTileOffset(materialEditor, _splatMapProperty);
    }
  }
}