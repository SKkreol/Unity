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
    
#if UNITY_2022_1_OR_NEWER
        private readonly static FieldInfo depthTextureFieldInfo = typeof(UniversalRenderer).GetField("m_DepthTexture", BindingFlags.NonPublic | BindingFlags.Instance);
#endif
    
    public BrightPass(RenderTargetHandle destination, int layerMask)
    {
        _destination = destination;
        _filteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask);
        _renderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cmd = CommandBufferPool.Get("EmissionPass");
        var sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
        var drawingSettings = CreateDrawingSettings(_shaderTagIdList, ref renderingData, sortingCriteria);
        cmd.GetTemporaryRT(_destination.id, renderingData.cameraData.cameraTargetDescriptor);

#if UNITY_2022_1_OR_NEWER
			// URP 13 (Unity 2022.1+) has non-documented breaking changes related to _CameraDepthTexture. Reflection is used here to retrieve _CameraDepthTexture's underlying depth texture, as suggested by the "How to set _CameraDepthTexture as render target in URP 13?" forum, see https://forum.unity.com/threads/how-to-set-_cameradepthtexture-as-render-target-in-urp-13.1279934/#post-8272821
        var depthTextureHandle = depthTextureFieldInfo.GetValue(camData.renderer) as RTHandle;
#else
        var depthTexture = new RenderTargetIdentifier("_CameraDepthTexture");
#endif
      
        cmd.SetRenderTarget(_destination.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, depthTexture, RenderBufferLoadAction.Load, RenderBufferStoreAction.DontCare);
        cmd.ClearRenderTarget(false, true, Color.clear);
        cmd.SetGlobalTexture(_destination.id, _destination.Identifier());
        context.ExecuteCommandBuffer(cmd);
        context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _filteringSettings, ref _renderStateBlock);

        cmd.Clear();
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }
}