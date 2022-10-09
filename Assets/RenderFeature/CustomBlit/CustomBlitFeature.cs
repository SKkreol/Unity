using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

class CustomBlitFeature : ScriptableRendererFeature
{
	private Material _material;
	private CustomBlitPass _renderPass = null;

	public override void Create()
	{
		var shader = Shader.Find("Hidden/CustomBlit");
		if (shader == null)
			return;
		_material = new Material(shader);
		_renderPass = new CustomBlitPass(_material);
	}
	
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		if (renderingData.cameraData.cameraType != CameraType.Game || _renderPass == null || _material == null)
			return;

		_renderPass.ConfigureInput(ScriptableRenderPassInput.Color);
		_renderPass.SetTarget(renderer.cameraColorTarget);
		renderer.EnqueuePass(_renderPass);
	}

	protected override void Dispose(bool disposing)
	{
		CoreUtils.Destroy(_material);
	}
}