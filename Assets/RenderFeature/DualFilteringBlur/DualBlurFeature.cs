using UnityEngine;
using UnityEngine.Rendering.Universal;

public class DualBlurFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class KawaseBlurSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material blurMaterial = null;
        [Range(0, 5)]
        public int downsample = 1;
    }

    public KawaseBlurSettings settings = new KawaseBlurSettings();
        
    DualBlurPass pass;

    public override void Create()
    {
        pass = new DualBlurPass("DualBlur");
        pass.blurMaterial = settings.blurMaterial;
        pass.downsample = settings.downsample;
        pass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.downsample == 0) return;
        var src = renderer.cameraColorTarget;
        pass.Setup(src);
        renderer.EnqueuePass(pass);
    }
}


