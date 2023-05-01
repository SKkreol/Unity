using UnityEngine;
using UnityEngine.Rendering.Universal;

class CustomBlitFeature : ScriptableRendererFeature
{
	[SerializeField]
	private Material material;
	private CustomBlitPass _renderPass = null;

	public override void Create()
	{
		if (material == null)
		{
			var shader = Shader.Find("Hidden/CustomBlit");
			if (shader == null)
				return;
			material = new Material(shader);
		}
		_renderPass = new CustomBlitPass(material);
	}
	
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		if (renderingData.cameraData.cameraType != CameraType.Game || _renderPass == null || material == null)
			return;

		_renderPass.ConfigureInput(ScriptableRenderPassInput.Color);
		_renderPass.SetTarget(renderer.cameraColorTarget);
		renderer.EnqueuePass(_renderPass);
	}
}