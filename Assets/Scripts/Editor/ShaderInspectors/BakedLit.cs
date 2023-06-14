using System;
using UnityEditor;
using UnityEngine;

namespace Game.Editor.ShaderInspectors
{
  public class BakedLit : BaseShaderGUI
  {
    public static readonly GUIContent AlphaMaskText = EditorGUIUtility.TrTextContent("Use Alpha as Color Mask",
      "When enabled, Alpha Channel of Albedo Texture will be used as a mask for Color property.");

    private MaterialProperty? _useAlphaAsColorMaskProperty;

    public override void ValidateMaterial(Material material) => SetMaterialKeywords(material);

    public override void FindProperties(MaterialProperty[] properties)
    {
      _useAlphaAsColorMaskProperty = FindProperty("_UseAlphaAsColorMask", properties, false);
      base.FindProperties(properties);
    }

    public override void DrawSurfaceOptions(Material material)
    {
      if (material == null)
        throw new ArgumentNullException(nameof(material));

      // Use default labelWidth
      EditorGUIUtility.labelWidth = 0f;

      base.DrawSurfaceOptions(material);
    }

    public override void DrawSurfaceInputs(Material material)
    {
      base.DrawSurfaceInputs(material);
      DrawTileOffset(materialEditor, baseMapProp);
      DrawFloatToggleProperty(AlphaMaskText, _useAlphaAsColorMaskProperty);
    }

    // Internal method copied from BaseShaderGUI.
    public static void DrawFloatToggleProperty(
      GUIContent styles,
      MaterialProperty? prop,
      int indentLevel = 0,
      bool isDisabled = false)
    {
      if (prop == null)
        return;

      EditorGUI.BeginDisabledGroup(isDisabled);
      EditorGUI.indentLevel += indentLevel;
      EditorGUI.BeginChangeCheck();
     // MaterialEditor.BeginProperty(prop);
      var newValue = EditorGUILayout.Toggle(styles, Math.Abs(prop.floatValue - 1) < 0.01f);
      if (EditorGUI.EndChangeCheck())
        prop.floatValue = newValue ? 1.0f : 0.0f;

      //MaterialEditor.EndProperty();
      EditorGUI.indentLevel -= indentLevel;
      EditorGUI.EndDisabledGroup();
    }
  }
}