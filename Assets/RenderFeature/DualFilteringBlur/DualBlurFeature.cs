using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Serialization;


public enum RenderTarget
{
    frameBuffer,
    globalTexture
}

public class DualBlurFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class DualBlurSettings
    {
        public RenderTarget renderTarget = RenderTarget.frameBuffer;
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material blurMaterial = null;
        [Range(0, 5)]
        public int downsample = 1;
        public string globalTextureName = "_BlurTexture";
    }

    public DualBlurSettings settings = new DualBlurSettings();
        
    DualBlurPass pass;

    public override void Create()
    {
        pass = new DualBlurPass("DualBlur")
        {
            blurMaterial = settings.blurMaterial,
            downsample = settings.downsample,
            renderPassEvent = settings.renderPassEvent,
            target = settings.renderTarget,
            globalTexID = Shader.PropertyToID(settings.globalTextureName)
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.downsample == 0) return;
        var src = renderer.cameraColorTarget;
        pass.Setup(src);
        renderer.EnqueuePass(pass);
    }
}


