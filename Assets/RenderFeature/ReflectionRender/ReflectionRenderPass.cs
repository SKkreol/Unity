using System.Collections.Generic;
using Unity.Collections.LowLevel.Unsafe;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace RenderFeatures
{
    public class ReflectionRenderPass : ScriptableRenderPass
    {
        public float ClipPlaneOffset;
        private static readonly int ReflectionTexId = Shader.PropertyToID("_ReflectionTex");
    
        private ProfilingSampler _profilingSampler = new ProfilingSampler("ReflectionRenderPass");
    
        private RenderTargetHandle _destination;
    
        public RenderTargetIdentifier CameraColorTexture;
        public int SizeShift = 1;

        private readonly List<ShaderTagId> _shaderTagIdList = new List<ShaderTagId>()
        {
            new ShaderTagId("ReflectionPass"),
        };
        private FilteringSettings _filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        private RenderStateBlock _renderState = new RenderStateBlock(RenderStateMask.Raster);
    
    
        public ReflectionRenderPass(RenderTargetHandle destination)
        {
            _destination = destination;
        
            _renderState.rasterState = new RasterState(CullMode.Off);
        }

        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            var w = cameraTextureDescriptor.width >> SizeShift;
            var h = cameraTextureDescriptor.height >> SizeShift;
            var desc = new RenderTextureDescriptor(w, h, GraphicsFormat.B8G8R8A8_SRGB, 16)
            {
                useMipMap = true,
                autoGenerateMips = true
            };

            cmd.GetTemporaryRT(_destination.id, desc, FilterMode.Trilinear);

            ConfigureTarget(_destination.Identifier());
            ConfigureClear(ClearFlag.All, Color.clear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("Plane Reflection");
            //   using (new ProfilingScope(cmd, _profilingSampler))
            {
                var cameraData = renderingData.cameraData;

                var pos = new Vector3(0.0f, -0.01f, 0.0f);
                var normal = Vector3.up;

                // Reflect camera around reflection plane
                var d = -Vector3.Dot(normal, pos) - ClipPlaneOffset;
                var reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);

                var reflection = Matrix4x4.zero;
                CalculateReflectionMatrix(ref reflection, reflectionPlane);

                var tcamTransform = cameraData.camera.transform;
                var view = Matrix4x4.TRS(tcamTransform.position, tcamTransform.rotation, new Vector3(1, 1, -1));
                var reflectionViewMatrix = view.inverse * reflection;

                var clipPlane = CameraSpacePlane(reflectionViewMatrix, pos, normal, 1.0f);
                var reflectionProjMatrix = cameraData.camera.CalculateObliqueMatrix(clipPlane);

                cmd.SetViewProjectionMatrices(reflectionViewMatrix, reflectionProjMatrix);
                //cmd.EnableShaderKeyword("REFLECTION_PASS");
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
            
                var sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawingSettings = CreateDrawingSettings(_shaderTagIdList, ref renderingData, sortingCriteria);

                // update culling matrix                           
                var cullMatrix = reflectionProjMatrix * reflectionViewMatrix;
                var cullResult = GetCulling(context, ref renderingData, ref cullMatrix);

                var oldfog = RenderSettings.fog;
                RenderSettings.fog = true;
                
                context.DrawRenderers(cullResult, ref drawingSettings, ref _filteringSettings, ref _renderState);
                //context.DrawSkybox(cameraData.camera);
                context.Submit();
                
                RenderSettings.fog = oldfog;

                cmd.SetRenderTarget(CameraColorTexture);
                //cmd.DisableShaderKeyword("REFLECTION_PASS");
                cmd.SetGlobalTexture(ReflectionTexId, _destination.Identifier());
            
                context.ExecuteCommandBuffer(cmd);
                context.SetupCameraProperties(renderingData.cameraData.camera);
                context.Submit();
            }

            CommandBufferPool.Release(cmd);
        }

        public static CullingResults GetCulling(ScriptableRenderContext context, ref RenderingData renderingData, ref Matrix4x4 cullMatrix)
        {
            var planes = GeometryUtility.CalculateFrustumPlanes(cullMatrix);
        
            renderingData.cameraData.camera.TryGetCullingParameters(out var cullParam);
            cullParam.cullingMatrix = cullMatrix;

            for (var i = 0; i < 6; ++i)
                cullParam.SetCullingPlane(i, planes[i]);
        
            return context.Cull(ref cullParam);
        }
    

        // Given position/normal of the plane, calculates plane in camera space.
        private Vector4 CameraSpacePlane(Matrix4x4 viewmat, Vector3 pos, Vector3 normal, float sideSign)
        {
            var offsetPos = pos + normal * ClipPlaneOffset;
            var cpos = viewmat.MultiplyPoint(offsetPos);
            var cnormal = viewmat.MultiplyVector(normal).normalized * sideSign;
            return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
        }

        // Calculates reflection matrix around the given plane
        private static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
        {
            reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
            reflectionMat.m01 = (-2F * plane[0] * plane[1]);
            reflectionMat.m02 = (-2F * plane[0] * plane[2]);
            reflectionMat.m03 = (-2F * plane[3] * plane[0]);

            reflectionMat.m10 = (-2F * plane[1] * plane[0]);
            reflectionMat.m11 = ( 1F - 2F * plane[1] * plane[1]);
            reflectionMat.m12 = (-2F * plane[1] * plane[2]);
            reflectionMat.m13 = (-2F * plane[3] * plane[1]);

            reflectionMat.m20 = (-2F * plane[2] * plane[0]);
            reflectionMat.m21 = (-2F * plane[2] * plane[1]);
            reflectionMat.m22 = ( 1F - 2F * plane[2] * plane[2]);
            reflectionMat.m23 = (-2F * plane[3] * plane[2]);

            reflectionMat.m30 = 0F;
            reflectionMat.m31 = 0F;
            reflectionMat.m32 = 0F;
            reflectionMat.m33 = 1F;
        }
    }
}
