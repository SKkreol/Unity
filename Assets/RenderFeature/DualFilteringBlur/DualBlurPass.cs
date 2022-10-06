using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal; 

class DualBlurPass : ScriptableRenderPass
{
    public Material blurMaterial;
    public int passes;
    public int downsample;
    public bool copyToFramebuffer;
    public string targetName;
    public RenderTarget target;
    public int globalTexID;
    string profilerTag;

    private int MaxIterations = 4;

    private RenderTexture[] _blurBuffer1 = new RenderTexture[5];
    private RenderTexture[] _blurBuffer2 = new RenderTexture[5];
        
    private RenderTargetIdentifier source { get; set; }

    public void Setup(RenderTargetIdentifier source) 
    {
        this.source = source;
    }

    public DualBlurPass(string profilerTag)
    {
        this.profilerTag = profilerTag;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {

    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get(profilerTag);

        MaxIterations = downsample;

        var width = renderingData.cameraData.cameraTargetDescriptor.width;
        var height = renderingData.cameraData.cameraTargetDescriptor.height;

        var prefilterRend = RenderTexture.GetTemporary(width >> 1, height >> 1, 0, RenderTextureFormat.Default);
        prefilterRend.filterMode = FilterMode.Bilinear;
        cmd.Blit(source, prefilterRend, blurMaterial, 0);
        var last = prefilterRend;

        for (var level = 0; level < MaxIterations; level++)
        {
            _blurBuffer1[level] = RenderTexture.GetTemporary(last.width >> 1, last.height >> 1, 0, RenderTextureFormat.Default);
            _blurBuffer1[level].filterMode = FilterMode.Bilinear;
            cmd.Blit(last, _blurBuffer1[level], blurMaterial, 0);
            last = _blurBuffer1[level];
        }

        for (var level = MaxIterations - 1; level >= 0; level--)
        {
            _blurBuffer2[level] = RenderTexture.GetTemporary(last.width << 1, last.height << 1, 0, RenderTextureFormat.Default);
            _blurBuffer2[level].filterMode = FilterMode.Bilinear;
            cmd.Blit(last, _blurBuffer2[level], blurMaterial, 1);
            last = _blurBuffer2[level];
        }

        switch (target)
        {
            case RenderTarget.frameBuffer:
                cmd.Blit(last, renderingData.cameraData.renderer.cameraColorTarget);
            break;
            case RenderTarget.glabalTexture:
                cmd.SetGlobalTexture(globalTexID, last);
            break;
            default:
                cmd.Blit(last, renderingData.cameraData.renderer.cameraColorTarget);
                break;
        }

        RenderTexture.ReleaseTemporary(prefilterRend);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
        for (var i = 0; i < MaxIterations; i++)
        {
            if (_blurBuffer1[i] != null)
            {
                RenderTexture.ReleaseTemporary(_blurBuffer1[i]);
                _blurBuffer1[i] = null;
            }
            if (_blurBuffer2[i] != null)
            {
                RenderTexture.ReleaseTemporary(_blurBuffer2[i]);
                _blurBuffer2[i] = null;
            }
        }
    }

    public override void OnCameraCleanup(CommandBuffer cmd)
    {
    }
}