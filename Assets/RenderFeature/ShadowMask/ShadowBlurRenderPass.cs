using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace RenderFeatures.RenderPasses
{
  internal class ShadowBlurRenderPass : ScriptableRenderPass
  {
    public Texture2D FadeTexture;
    public Material BlurMaterial;
    public float BlurSize;
    public int Resolution;

    private RenderTargetIdentifier _verticalPassRT;
    private RenderTargetIdentifier _blurShadow;
    private const string ProfilerTag = "BlurShadow Pass";
    private RenderTargetHandle _shadowMapHandle;
    private static readonly int FadeTexID = Shader.PropertyToID("_FadeTex");
    private static readonly int SizeID = Shader.PropertyToID("_MobileShadowBlur");
    private static readonly int VerticalPassTexID = Shader.PropertyToID("_VerticalPassTex");
    private static readonly int FinalBlurID = Shader.PropertyToID("_BlurShadow");

    public ShadowBlurRenderPass(RenderTargetHandle shadowMap, RenderPassEvent passEvent)
    {
      renderPassEvent = passEvent;
      _shadowMapHandle = shadowMap;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
      BlurMaterial.SetTexture(FadeTexID, FadeTexture);

      cmd.GetTemporaryRT(VerticalPassTexID, Resolution, Resolution, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
      _verticalPassRT = new RenderTargetIdentifier(VerticalPassTexID);

      cmd.GetTemporaryRT(FinalBlurID, Resolution, Resolution, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);
      _blurShadow = new RenderTargetIdentifier(FinalBlurID);

      ConfigureTarget(_verticalPassRT);
      ConfigureTarget(_blurShadow);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      var cmd = CommandBufferPool.Get(ProfilerTag);

      // TO DO rewrite blit to custom blit with fullScreenTriangle
      cmd.SetGlobalFloat(SizeID, BlurSize);
      cmd.Blit(_shadowMapHandle.Identifier(), _verticalPassRT, BlurMaterial, 0);
      cmd.SetGlobalTexture(VerticalPassTexID, _verticalPassRT);
      cmd.Blit(_verticalPassRT, _blurShadow, BlurMaterial, 1);

      cmd.SetGlobalTexture(FinalBlurID, _blurShadow);

      context.Submit();
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();

      CommandBufferPool.Release(cmd);
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
      cmd.ReleaseTemporaryRT(VerticalPassTexID);
      cmd.ReleaseTemporaryRT(FinalBlurID);
    }
  }
}