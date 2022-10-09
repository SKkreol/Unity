using UnityEngine;
using RenderFeature;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FullScreenTrianglePass : ScriptableRenderPass
{
   private const string ProfilerTag = "FullScreenTrianglePass";
   public Material Material;

   private Mesh _triangle;

   public FullScreenTrianglePass(RenderPassEvent renderEvent)
   {
      renderPassEvent = renderEvent;
   }

   public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
   {
      _triangle = GraphicUtils.FullScreenTriangle();
   }
   
   public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
   {
      var cmd = CommandBufferPool.Get(ProfilerTag);
      cmd.DrawMesh(_triangle, Matrix4x4.identity, Material, 0, 0);
      context.ExecuteCommandBuffer(cmd);
      CommandBufferPool.Release(cmd);
   }
}