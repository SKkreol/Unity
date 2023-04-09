using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BloomPass : ScriptableRenderPass
{
  private const string ProfilerTag = "BloomPass";
  public Material Material;
  private static readonly int QuadsOffSetHash = Shader.PropertyToID("_NumberOfQuads");
  private Mesh _quads;
  private static int _xCount;
  private static int _yCount = 32;
  
  private static Mesh CreateQuad(int quadCountX, int quadCountY, int x, int y)
  {
      var dx = (1.0f / quadCountX) * 2;
      var dy = (1.0f / quadCountY) * 2;
      var offset = new Vector3(dx * x, dy * y, 0f) - new Vector3(1.0f, 1.0f, 0f);

      var vert = new Vector3[4];
      vert[0] = new Vector3(0.0f, 0.0f, 0f) + offset;
      vert[1] = new Vector3(0.0f, dy, 0f) + offset;
      vert[2] = new Vector3(dx, dy, 0f) + offset;
      vert[3] = new Vector3(dx, 0.0f, 0f) + offset;

      var uvOffset = new Vector2((1f / quadCountX) * x, (1f / quadCountY) * y);

      var r = Random.Range(0.0f, 1.0f);
      var g = Random.Range(0.0f, 1.0f);
      var b = Random.Range(0.0f, 1.0f);
      var colors = new Color[4];
      colors[0] = new Color(r, g, b);
      colors[1] = new Color(r, g, b);
      colors[2] = new Color(r, g, b);
      colors[3] = new Color(r, g, b);
      
      var quadMesh = new Mesh
      {
          vertices = vert,
          triangles = new[] { 0, 1, 2, 0, 2, 3 },

          uv = new[]
          {
              Vector2.zero + uvOffset,
              Vector2.up / quadCountY + uvOffset,
              Vector2.right / quadCountX + uvOffset,
              new Vector2(1.0f / quadCountX, 1.0f / quadCountY) + uvOffset
          },
          uv2 = new[]
          {
              uvOffset,
              uvOffset,
              uvOffset,
              uvOffset
          },
          colors = colors
      };

      return quadMesh;
  }
  
    private static Mesh FullScreenQuads2()
  {
      var width = Screen.width;
      var height = Screen.height;
      
      var maxSide = Mathf.Max(width, height);
      var minSide = Mathf.Min(width, height);
      var ratio = (float)maxSide / minSide;

      _yCount = Mathf.RoundToInt(Mathf.Sqrt(minSide));
      _xCount = Mathf.RoundToInt(_yCount * ratio);
      _yCount = 32;
      _xCount = 32;
      
      
      var combine = new CombineInstance[_xCount * _yCount*4];
      var count = 0;
      
      for (var j = 0; j < _yCount; j++)
      {
          for (var i = 0; i < _xCount; i++)
          {
              combine[count].mesh = CreateQuad(_xCount, _yCount, i, j);
              combine[count].transform = Matrix4x4.identity;
              count++;
          }
      }
      var m = new Mesh();
      m.indexFormat = IndexFormat.UInt16;
      m.CombineMeshes(combine, true, false);
      m.UploadMeshData(true);
      return m;
  }
  
  private static Mesh FullScreenQuads()
  {
      var width = Screen.width;
      var height = Screen.height;
      
      var dw = (1.0f / width)*2.0f;
      var dh = (1.0f / height)*2.0f;
      
      var maxSide = Mathf.Max(width, height);
      var minSide = Mathf.Min(width, height);
      var ratio = (float)maxSide / minSide;

      _yCount = Mathf.RoundToInt(Mathf.Sqrt(minSide));
      _xCount = Mathf.RoundToInt(_yCount * ratio);
      var ySize = ((float)height / _yCount) * dh;
      
      var xSize = ((float)width / _xCount) * dw;
      
      var tris = new[] { 0, 1, 2, 0, 2, 3 };
      
      var combine = new CombineInstance[_xCount * _yCount];

      var p0 = new Vector3(-1f, -1f, 0f);
      var p1 = new Vector3(-1f,  -1.0f + ySize, 0f);
      var p2 = new Vector3( 0f, -1.0f + ySize, 0f);
      var p3 = new Vector3(0f, -1f, 0f);

      var count = 0;
      
      for (var y = 0; y < _yCount; y++)
      {
          for (var x = 0; x < _xCount; x++)
          {
              p2.x = p1.x + xSize;
              p3.x = p0.x + xSize;

              var r = Random.Range(0.0f, 1.0f);
              var g = Random.Range(0.0f, 1.0f);
              var b = Random.Range(0.0f, 1.0f);

              var colors = new Color[4];
              colors[0] = new Color(r, g, b);
              colors[1] = new Color(r, g, b);
              colors[2] = new Color(r, g, b);
              colors[3] = new Color(r, g, b);
              
              var uvOffset = new Vector2((1f / _xCount) * x, (1f / _yCount) * y);
              var quad = new Mesh
              {
                  vertices = new[]
                  {
                      p0,
                      p1,
                      p2,
                      p3,
                  },
                  uv = new[]
                  {
                      uvOffset,
                      uvOffset,
                      uvOffset,
                      uvOffset
                  },

                  triangles = tris,
                  colors = colors,
              };
              p1.x += xSize;
              p0.x += xSize;

              combine[count].mesh = quad;
              combine[count].transform = Matrix4x4.identity;
              count++;
          }
          p0.y += ySize;
          p0.x = -1f;
          
          p1.y += ySize;
          p1.x = -1f;
          
          p2.y += ySize;
          p2.x = 0;
          
          p3.y += ySize;
          p3.x = 0;
      }
      var m = new Mesh();
      m.indexFormat = IndexFormat.UInt16;
      m.CombineMeshes(combine, true, false);
      m.UploadMeshData(true);
      return m;
  }
  
  public BloomPass(RenderPassEvent renderEvent)
  {
    renderPassEvent = renderEvent;
  }

  public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
  {
      if(_quads == null)
        _quads = FullScreenQuads();
      Material.SetVector(QuadsOffSetHash, new Vector4(0.5f/_xCount, 0.5f/_yCount, 1.0f/_xCount,1.0f/_yCount));
  }
   
  public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
  {
    var cmd = CommandBufferPool.Get(ProfilerTag);
    cmd.DrawMesh(_quads, Matrix4x4.identity, Material, 0, 0);
    context.ExecuteCommandBuffer(cmd);
    CommandBufferPool.Release(cmd);
  }
}