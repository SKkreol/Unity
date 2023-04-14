using UnityEngine;
using RenderFeature;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

class CustomBlitPass : ScriptableRenderPass
{
	private ProfilingSampler _profilingSampler = new ProfilingSampler("CustomBlit");
	private readonly Material _material;
	private RenderTargetIdentifier _cameraColorTarget;
	private readonly Mesh _triangle;

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

	private void Blit(CommandBuffer cmd, RenderTargetIdentifier target, Material material, int pass)
	{
		// For default processing _CameraOpaqueTexture.
		// For custom texture set in material.SetTexture("_MainTex", sourceTexture).

		cmd.DrawMesh(_triangle, Matrix4x4.identity, material, 0, pass);
		cmd.SetRenderTarget(target);
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