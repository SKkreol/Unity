using UnityEngine;
using RenderFeature;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

class ScanerPass : ScriptableRenderPass
{
	private ProfilingSampler _profilingSampler = new ProfilingSampler("ScanerPass");
	private readonly Material _material;
	private RenderTargetIdentifier _cameraColorTarget;
	private Mesh _quad;

	public ScanerPass(Material material)
	{
		_material = material;
		renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

	}

	public void SetTarget(RenderTargetIdentifier cameraColorTarget, Camera camera)
	{
		_cameraColorTarget = cameraColorTarget;
		_quad = GraphicUtils.FullScreenRaycastQuad(camera);
	}

	private void Blit(CommandBuffer cmd, RenderTargetIdentifier target, Material material, int pass)
	{
		// For default processing _CameraOpaqueTexture.
		// For custom texture set in material.SetTexture("_MainTex", sourceTexture).

		cmd.DrawMesh(_quad, Matrix4x4.identity, material, 0, pass);
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