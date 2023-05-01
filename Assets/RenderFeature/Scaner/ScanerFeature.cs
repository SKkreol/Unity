using UnityEngine;
using UnityEngine.Rendering.Universal;

class ScanerFeature : ScriptableRendererFeature
{
	[SerializeField]
	private Material material;
	private ScanerPass _renderPass = null;

	public override void Create()
	{
		_renderPass = new ScanerPass(material);
	}
	
	public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
	{
		if (renderingData.cameraData.cameraType != CameraType.Game || _renderPass == null || material == null)
			return;

		_renderPass.ConfigureInput(ScriptableRenderPassInput.Color);
		_renderPass.SetTarget(renderer.cameraColorTarget, renderingData.cameraData.camera);
		renderer.EnqueuePass(_renderPass);
	}
}