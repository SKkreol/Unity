using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace RenderFeatures.RenderPasses
{
  public class ShadowMobilePass : ScriptableRenderPass
  {
    public RenderTargetHandle ShadowHandle { get; set; }
    public float Distance;
    public LayerMask LayerMask;

    public Color ShadowColor;
    public float FarPlane;
    public float NearPlane;
    public int Resolution;

    private readonly Material _shadowMobileMaterial;
    private FilteringSettings _mFilteringSettings;
    private const string ProfilerTag = "ShadowMobile Prepass";
    // TO DO create custom pass with custom tag for draw shadows
    private readonly ShaderTagId _mShaderTagId = new ShaderTagId("DepthOnly");
    private RenderStateBlock _renderState = new RenderStateBlock(RenderStateMask.Raster);
    private readonly Vector3 _scale = new Vector3(1, 1, 1);
    private readonly Vector3[] _frustumToLightView = new Vector3[8];

    private static readonly Matrix4x4 ShadowSpaceMatrix = new()
    {
      m00 = 0.5f, m01 = 0.0f, m02 = 0.0f, m03 = 0.5f,
      m10 = 0.0f, m11 = 0.5f, m12 = 0.0f, m13 = 0.5f,
      m20 = 0.0f, m21 = 0.0f, m22 = 0.5f, m23 = 0.5f,
      m30 = 0.0f, m31 = 0.0f, m32 = 0.0f, m33 = 1.0f
    };

    private static readonly int ShadowMatrixId = Shader.PropertyToID("_MobileShadowMatrix");
    private static readonly int ShadowTextureId = Shader.PropertyToID("_MobileShadowTexture");
    private static readonly int ShadowColorId = Shader.PropertyToID("_MobileShadowColor");

    public ShadowMobilePass(Material material, RenderPassEvent passEvent)
    {
      renderPassEvent = passEvent;
      _mFilteringSettings = new FilteringSettings(RenderQueueRange.opaque, 0);
      _shadowMobileMaterial = material;
    }

    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
    {
      var descriptor = cameraTextureDescriptor;
      descriptor.colorFormat = RenderTextureFormat.RGB565;
      descriptor.depthBufferBits = 0;
      descriptor.width = Resolution;
      descriptor.height = Resolution;
      cmd.GetTemporaryRT(ShadowHandle.id, descriptor, FilterMode.Bilinear);
      ConfigureTarget(ShadowHandle.Identifier());
      ConfigureClear(ClearFlag.All, Color.black);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
      var cmd = CommandBufferPool.Get(ProfilerTag);

      var projMatrix = Matrix4x4.identity;
      var viewMatrix = Matrix4x4.identity;

      CalculateViewProjectionShadowMatrix(renderingData, ref viewMatrix, ref projMatrix);

      cmd.SetViewProjectionMatrices(viewMatrix, projMatrix);

      // Set shadow camera parameter
      var sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
      var drawingSettings = CreateDrawingSettings(_mShaderTagId, ref renderingData, sortingCriteria);
      var cullMatrix = ShadowSpaceMatrix * (projMatrix * viewMatrix);
      cmd.SetGlobalMatrix(ShadowMatrixId, cullMatrix);
      var cullResult = GetCulling(context, ref renderingData, ref cullMatrix);
      drawingSettings.perObjectData = PerObjectData.Lightmaps;
      drawingSettings.overrideMaterial = _shadowMobileMaterial;
      context.ExecuteCommandBuffer(cmd);
      cmd.Clear();
      
      _mFilteringSettings.layerMask = LayerMask;
      context.DrawRenderers(cullResult, ref drawingSettings, ref _mFilteringSettings, ref _renderState);

      cmd.SetGlobalTexture(ShadowTextureId, ShadowHandle.id);
      cmd.SetGlobalColor(ShadowColorId, ShadowColor);

      //Revert to normal view rendering
      context.SetupCameraProperties(renderingData.cameraData.camera);
      context.Submit();
      context.ExecuteCommandBuffer(cmd);

      CommandBufferPool.Release(cmd);
    }

    private static CullingResults GetCulling(ScriptableRenderContext context, ref RenderingData renderingData,
      ref Matrix4x4 cullMatrix)
    {
      var planes = GeometryUtility.CalculateFrustumPlanes(cullMatrix);

      renderingData.cameraData.camera.TryGetCullingParameters(out var cullParam);
      cullParam.cullingMatrix = cullMatrix;

      for (var i = 0; i < 6; ++i)
        cullParam.SetCullingPlane(i, planes[i]);

      return context.Cull(ref cullParam);
    }

    private void CalculateViewProjectionShadowMatrix(RenderingData renderingData, ref Matrix4x4 view,
      ref Matrix4x4 projection)
    {
      var shadowLightIndex = renderingData.lightData.mainLightIndex;
      if (shadowLightIndex == -1)
        return;
      
      var shadowLight = renderingData.lightData.visibleLights[shadowLightIndex];
      var lightTransform = shadowLight.light.transform;
      var viewCamera = renderingData.cameraData.camera;
      var viewCameraTransform = viewCamera.transform;

      var aspect = viewCamera.aspect;
      var halfFovRadians = Mathf.Deg2Rad * viewCamera.fieldOfView * 0.5f;
      var nearDist = NearPlane;
      var farDist = FarPlane;

      var hNear = Mathf.Tan(halfFovRadians) * nearDist;
      var wNear = hNear * aspect;

      var hFar = Mathf.Tan(halfFovRadians) * farDist;
      var wFar = hFar * aspect;

      var viewPos = viewCameraTransform.position;
      var viewDir = viewCameraTransform.forward;

      var viewUp = viewCameraTransform.up;
      var viewRight = viewCameraTransform.right;

      // Far plane in world space
      var centerFar = viewPos + viewDir * farDist;
      var viewUpHFar = viewUp * hFar;
      var viewRightWFar = viewRight * wFar;
      var topLeftFar = centerFar + viewUpHFar - viewRightWFar;
      var topRightFar = centerFar + viewUpHFar + viewRightWFar;
      var bottomLeftFar = centerFar - viewUpHFar - viewRightWFar;
      var bottomRightFar = centerFar - viewUpHFar + viewRightWFar;

      // Near plane in world space
      var centerNear = viewPos + viewDir * nearDist;
      var viewUpHNear = viewUp * hNear;
      var viewRightWNear = viewRight * wNear;
      var topLeftNear = centerNear + viewUpHNear - viewRightWNear;
      var topRightNear = centerNear + viewUpHNear + viewRightWNear;
      var bottomRightNear = centerNear - viewUpHNear + viewRightWNear;
      var bottomLeftNear = centerNear - viewUpHNear - viewRightWNear;

      var frustumCenter = (centerFar + centerNear) * 0.5f;
      var shadowCameraPos = frustumCenter - lightTransform.forward * Distance;
      view = Matrix4x4.TRS(shadowCameraPos, lightTransform.rotation, Vector3.one);
      view = view.inverse;

      _frustumToLightView[0] = view.MultiplyPoint3x4(topLeftNear);
      _frustumToLightView[1] = view.MultiplyPoint3x4(topRightNear);
      _frustumToLightView[2] = view.MultiplyPoint3x4(bottomLeftNear);
      _frustumToLightView[3] = view.MultiplyPoint3x4(bottomRightNear);
      _frustumToLightView[4] = view.MultiplyPoint3x4(topLeftFar);
      _frustumToLightView[5] = view.MultiplyPoint3x4(topRightFar);
      _frustumToLightView[6] = view.MultiplyPoint3x4(bottomLeftFar);
      _frustumToLightView[7] = view.MultiplyPoint3x4(bottomRightFar);

      // find max and min points to define a ortho matrix around
      var min = Vector3.positiveInfinity;
      var max = Vector3.negativeInfinity;

      for (var i = 0; i < _frustumToLightView.Length; i++)
      {
        if (_frustumToLightView[i].x < min.x)
          min.x = _frustumToLightView[i].x;
        if (_frustumToLightView[i].y < min.y)
          min.y = _frustumToLightView[i].y;
        if (_frustumToLightView[i].z < min.z)
          min.z = _frustumToLightView[i].z;

        if (_frustumToLightView[i].x > max.x)
          max.x = _frustumToLightView[i].x;
        if (_frustumToLightView[i].y > max.y)
          max.y = _frustumToLightView[i].y;
        if (_frustumToLightView[i].z > max.z)
          max.z = _frustumToLightView[i].z;
      }

      var l = min.x;
      var r = max.x;
      var b = min.y;
      var t = max.y;
      // Because max.z is positive and in NDC the positive z axis is 
      // towards us so need to set it as the near plane flipped
      var n = -max.z;
      var f = min.z;

      projection = Matrix4x4.Ortho(l, r, b, t, n, f);
    }

    public override void FrameCleanup(CommandBuffer cmd)
    {
      if (ShadowHandle != RenderTargetHandle.CameraTarget)
      {
        cmd.ReleaseTemporaryRT(ShadowHandle.id);
        ShadowHandle = RenderTargetHandle.CameraTarget;
      }
    }
  }
}