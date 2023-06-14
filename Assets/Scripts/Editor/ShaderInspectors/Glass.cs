using UnityEditor;
using UnityEngine;

namespace Game.Editor.ShaderInspectors
{
  public class Glass : Lit
  {
    private static readonly string InteriorCubemapArrayKey = "_INTERIOR_ATLAS_CUBE";
    private static readonly string GenerateDepth = "_INTERIOR_ATLAS_2D";

    private static readonly GUIContent Interior2DAtlasText = EditorGUIUtility.TrTextContent("Flat Interiors",
      "When set flat texture is used instead of cubemaps for interiors");

    private static readonly GUIContent InteriorCubemapArrayText =
      EditorGUIUtility.TrTextContent("Interior Cubemap Array",
        "When set cubemap array is used instead of flat texture. You can create cubemap arrays through Create menu");

    private MaterialProperty? _interior2DAtlas;
    private MaterialProperty? _atlasSize;
    private MaterialProperty? _interiorDepth;
    private MaterialProperty? _interiorCubemapArray;
    private MaterialProperty? _interiorColor;
    private MaterialProperty? _fakeDepthToggle;

    protected override void ValidateAdditionalProperties(Material material)
    {
      if (_interiorCubemapArray == null)
        return;

      var cubeArray = _interiorCubemapArray.textureValue != null;
      ToggleKeyword(material, cubeArray, InteriorCubemapArrayKey);

      if (_fakeDepthToggle != null)
        ToggleKeyword(material, _fakeDepthToggle.floatValue > 0.9f && !cubeArray, GenerateDepth);
    }

    protected override void FindAdditionalProperties(MaterialProperty[] properties)
    {
      _interior2DAtlas = FindProperty("_Interior2DAtlas", properties, false);
      _atlasSize = FindProperty("_AtlasSize", properties, false);
      _interiorDepth = FindProperty("_InteriorDepth", properties, false);
      _interiorCubemapArray = FindProperty("_InteriorCubemapArray", properties, false);
      _interiorColor = FindProperty("_InteriorColor", properties, false);
      _fakeDepthToggle = FindProperty("_FakeDepthToggle", properties, false);
    }

    protected override void DrawAdditionalProperties(Material material)
    {
      materialEditor.ColorProperty(_interiorColor, "Interior Color");
      materialEditor.TexturePropertySingleLine(InteriorCubemapArrayText, _interiorCubemapArray);
      materialEditor.TexturePropertySingleLine(Interior2DAtlasText, _interior2DAtlas, _atlasSize);
      materialEditor.ShaderProperty(_fakeDepthToggle, "Generate fake depth for 2d Atlas");
      materialEditor.FloatProperty(_interiorDepth, "Interior Depth");
    }
  }
}