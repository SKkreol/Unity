using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class BloomPass : ScriptableRenderPass
{
  public Material Material;

  private Mesh _quads;
  private static int _xCount;
  private static int _yCount;
  private static readonly string ProfilerTag = "BloomPass";
  private static readonly int QuadsOffSetID = Shader.PropertyToID("_NumberOfQuads");

  private static Color[] RandomQuadColor()
  {
    var r = Random.Range(0.0f, 1.0f);
    var g = Random.Range(0.0f, 1.0f);
    var b = Random.Range(0.0f, 1.0f);

    var colors = new Color[4];
    colors[0] = new Color(r, g, b);
    colors[1] = new Color(r, g, b);
    colors[2] = new Color(r, g, b);
    colors[3] = new Color(r, g, b);
    return colors;
  }

  private static Mesh FullScreenQuads()
  {
    var width = Screen.width;
    var height = Screen.height;

    var dw = (1.0f / width) * 2.0f;
    var dh = (1.0f / height) * 2.0f;

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
    var p1 = new Vector3(-1f, -1.0f + ySize, 0f);
    var p2 = new Vector3(0f, -1.0f + ySize, 0f);
    var p3 = new Vector3(0f, -1f, 0f);

    var count = 0;

    for (var y = 0; y < _yCount; y++)
    {
      for (var x = 0; x < _xCount; x++)
      {
        p2.x = p1.x + xSize;
        p3.x = p0.x + xSize;

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
          colors = RandomQuadColor(),
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
    if (_quads == null)
      _quads = FullScreenQuads();
    Material.SetVector(QuadsOffSetID, new Vector4(0.5f / _xCount, 0.5f / _yCount, 1.0f / _xCount, 1.0f / _yCount));
  }

  public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
  {
    var cmd = CommandBufferPool.Get(ProfilerTag);
    cmd.DrawMesh(_quads, Matrix4x4.identity, Material, 0, 0);
    context.ExecuteCommandBuffer(cmd);
    CommandBufferPool.Release(cmd);
  }
}