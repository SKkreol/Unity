using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BrightPass : ScriptableRenderPass
{
    private RenderTargetHandle _destination;
    private readonly List<ShaderTagId> _shaderTagIdList = new() { new ShaderTagId("EmissionPass") };
    private FilteringSettings _filteringSettings;
    private RenderStateBlock _renderStateBlock;
    
    public BrightPass(RenderTargetHandle destination, int layerMask)
    {
        _destination = destination;
        _filteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask);
        _renderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get("DDDD");
        var sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
        var drawingSettings = CreateDrawingSettings(_shaderTagIdList, ref renderingData, sortingCriteria);
        cmd.GetTemporaryRT(_destination.id, renderingData.cameraData.cameraTargetDescriptor);

        var depthTexture = new RenderTargetIdentifier("_CameraDepthTexture");

        cmd.SetRenderTarget(_destination.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, depthTexture, RenderBufferLoadAction.Load, RenderBufferStoreAction.DontCare);
        //cmd.SetRenderTarget(_destination.id);
        //cmd.SetRenderTarget(_destination.Identifier(), depthTexture);
        cmd.ClearRenderTarget(false, true, Color.clear);
        cmd.SetGlobalTexture(_destination.id, _destination.Identifier());
        context.ExecuteCommandBuffer(cmd);
        context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filteringSettings, ref _renderStateBlock);

        cmd.Clear();
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}