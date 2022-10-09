using UnityEngine;
using RenderFeature;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

class CustomBlitPass : ScriptableRenderPass
{
	private ProfilingSampler _profilingSampler = new ProfilingSampler("CustomBlit");
	private Material _material;
	private RenderTargetIdentifier _cameraColorTarget;
	private Mesh _triangle;

	public CustomBlitPass(Material material)
	{
		_material = material;
		renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
		_triangle = GraphicUtils.FullScreenTriangle();
	}

	public void SetTarget(RenderTargetIdentifier cameraColorTarget)
	{
		_cameraColorTarget = cameraColorTarget;
	}

	public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
	{
		var saturationDescriptor = renderingData.cameraData.cameraTargetDescriptor;
		saturationDescriptor.depthBufferBits = 0;
	}

	private void Blit(CommandBuffer cmd,RenderTargetIdentifier target, Material material, int pass)
	{
		cmd.SetRenderTarget(target);
		cmd.DrawMesh(_triangle, Matrix4x4.identity, material, 0, pass);
	}

	public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
	{
		var cmd = CommandBufferPool.Get();

		using (new ProfilingScope(cmd, _profilingSampler))
		{
			Blit(cmd, _cameraColorTarget, _material, 0);
		}
		context.ExecuteCommandBuffer(cmd);
		CommandBufferPool.Release(cmd);
	}
}