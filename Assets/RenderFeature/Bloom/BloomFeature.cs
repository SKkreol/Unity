using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace RenderFeature.Bloom
{
  public class BloomFeature : ScriptableRendererFeature
  {
    [SerializeField] private bool debug;
    [SerializeField] 
    private RenderPassEvent passEvent = RenderPassEvent.AfterRenderingTransparents;
    public LayerMask GlowLayers;
    public string _renderTextureName = "_BrightTex";
    public RenderTarget renderTarget = RenderTarget.frameBuffer;
    public Material blurMaterial = null;
    [Range(0, 5)]
    public int downsample = 1;
    public string globalTextureName = "_BlurTexture";
  
    private BrightPass _brightPass;
    private DualBlurPass _blurPass;
    private BloomPass _bloomPass;
  
    private Material _material;
    private RenderTargetHandle _renderTexture;
  
    private const string ShaderName = "Hidden/AddBloom";
    private const string MaskDebugFeature = "_MASK_DEBUG_ON";
    public override void Create()
    {
      _renderTexture.Init(_renderTextureName);

      _brightPass = new BrightPass(_renderTexture, GlowLayers);
      
      _blurPass = new DualBlurPass("DualBlur")
      {
        blurMaterial = blurMaterial,
        downsample = downsample,
        renderPassEvent = passEvent,
        target = renderTarget,
        globalTexID = Shader.PropertyToID(globalTextureName)
      };
      
      _bloomPass = new BloomPass(passEvent);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
      if (_material == null)
      {
        var shader = Shader.Find(ShaderName);
        _material = new Material(shader);
      }
      _brightPass.renderPassEvent = passEvent;

      if (debug)
        _material.EnableKeyword(MaskDebugFeature);
      else
        _material.DisableKeyword(MaskDebugFeature);
    
      _bloomPass.Material = _material;
      _bloomPass.renderPassEvent = passEvent;
    
      _blurPass.Setup(_renderTexture.Identifier());
      _blurPass.renderPassEvent = passEvent;

    
      renderer.EnqueuePass(_bloomPass);
      renderer.EnqueuePass(_brightPass); 
      renderer.EnqueuePass(_blurPass);
    }
  }
}