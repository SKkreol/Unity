using UnityEngine;
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
      _triangle = FullScreenTriangle();
   }
   
   public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
   {
      var cmd = CommandBufferPool.Get(ProfilerTag);
      cmd.DrawMesh(_triangle, Matrix4x4.identity, Material, 0, 0);
      context.ExecuteCommandBuffer(cmd);
      CommandBufferPool.Release(cmd);
   }

   private static Mesh FullScreenTriangle()
   {
      var fullScreenTriangle = new Mesh 
      {
         name = "Full screen triangle",
         vertices = new[] 
         {
            new Vector3(-1f, -1f, 0f),
            new Vector3(-1f,  3f, 0f),
            new Vector3( 3f, -1f, 0f)
         },
         triangles = new[] { 2, 1, 0 },
      };
      fullScreenTriangle.UploadMeshData(true);
      return fullScreenTriangle;
   }
}