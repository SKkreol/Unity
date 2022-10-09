using UnityEngine;

namespace RenderFeature
{
    public static class GraphicUtils
    {
        public static Mesh FullScreenTriangle()
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
                triangles = new[] { 0, 1, 2 },
            };
            fullScreenTriangle.UploadMeshData(true);
            return fullScreenTriangle;
        }
    }
}