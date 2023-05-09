using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace RenderFeatures
{
  public class ReflectionRenderFeature : ScriptableRendererFeature
  {
    public enum ReflectionTextureSize
    {
      Full,
      Half,
      Quart,
      Octa
    }

    [SerializeField] public RenderPassEvent renderPassEvent;

    [SerializeField] public ReflectionTextureSize size;

    private RenderTargetHandle _reflectionTexture = RenderTargetHandle.CameraTarget;
    private ReflectionRenderPass _reflectionRenderPass;
    public bool ReflectionActive;

    public override void Create()
    {
      _reflectionTexture.Init("ReflectionRenderTarget");
      _reflectionRenderPass = new ReflectionRenderPass(_reflectionTexture) {renderPassEvent = renderPassEvent};
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
      if (!ReflectionActive)
        return;
      
      _reflectionRenderPass.CameraColorTexture = renderer.cameraColorTarget;
      _reflectionRenderPass.SizeShift = (int) size;
      renderer.EnqueuePass(_reflectionRenderPass);
    }
  }
}