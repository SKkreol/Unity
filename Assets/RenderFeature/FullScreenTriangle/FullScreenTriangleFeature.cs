using UnityEngine;
using UnityEngine.Rendering.Universal;

public class FullScreenTriangleFeature : ScriptableRendererFeature
{
  [SerializeField] 
  private Texture2D texture;
  [SerializeField] 
  private RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
  private FullScreenTrianglePass _pass;
  private Material _material;
  private static readonly int TexID = Shader.PropertyToID("_Tex");
  private const string ShaderName = "Hidden/FullScreenTriangle";

 public override void Create()
 {
   _pass = new FullScreenTrianglePass(passEvent);
 }

 public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
 {
  if (_material == null)
  {
    var shader = Shader.Find(ShaderName);
    _material = new Material(shader);
  }
  _material.SetTexture(TexID, texture);
  _pass.Material = _material;
  renderer.EnqueuePass(_pass);
 }
}