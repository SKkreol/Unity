using System;
using UnityEngine;
using RenderFeatures.RenderPasses;
using UnityEngine.Rendering.Universal;

namespace RenderFeatures
{
  [Serializable]
  public enum Multipliers
  {
    Half = 512,
    Full = 1024,
    Double = 2048,
  }

  public class ShadowMobileFeature : ScriptableRendererFeature
  {
    public Multipliers textureSize = Multipliers.Full;
    public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
    [Range(0.1f, 1.5f)] public float blurSize = 1.0f;
    public Texture2D fadeTexture;
    public LayerMask layerMask;
    public Color shadowColor = Color.gray;
    public float distance = 70.0f;
    public float farPlane = 12.0f;
    public float nearPlane = -0.6f;
    public Material drawMaterial;
    public Material blurMaterial;
    
    private ShadowMobilePass _shadowMobilePass;
    private ShadowBlurRenderPass _shadowBlurPass;
    private RenderTargetHandle _mobileShadowTexture;

    public override void Create()
    {
      _mobileShadowTexture.Init("_MobileShadowTexture");
      _shadowMobilePass = new ShadowMobilePass(drawMaterial, renderPassEvent);
      _shadowBlurPass = new ShadowBlurRenderPass(_mobileShadowTexture, renderPassEvent)
      {
        BlurMaterial = blurMaterial
      };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
      if (drawMaterial == null || blurMaterial == null)
        return;

      _shadowMobilePass.ShadowHandle = _mobileShadowTexture;
      _shadowMobilePass.ShadowColor = shadowColor;
      _shadowMobilePass.Distance = distance;
      _shadowMobilePass.FarPlane = farPlane;
      _shadowMobilePass.NearPlane = nearPlane;
      _shadowMobilePass.LayerMask = layerMask;
      _shadowMobilePass.Resolution = (int)textureSize;

      _shadowBlurPass.FadeTexture = fadeTexture;
      _shadowBlurPass.BlurSize = blurSize;
      _shadowBlurPass.Resolution = (int)textureSize;

      renderer.EnqueuePass(_shadowMobilePass);
      renderer.EnqueuePass(_shadowBlurPass);
    }
  }
}