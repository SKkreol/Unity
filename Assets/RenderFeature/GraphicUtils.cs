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
        
        public static Mesh FullScreenRaycastQuad(Camera camera)
        {
            
            float camFar = camera.farClipPlane;
            float camFov = camera.fieldOfView;
            float camAspect = camera.aspect;

            float fovWHalf = camFov * 0.5f;

            Transform cameraTransform = camera.transform;
            
            Vector3 toRight = cameraTransform.right * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * camAspect;
            Vector3 toTop = cameraTransform.up * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

            var cameraForward = cameraTransform.forward;
            
            Vector3 topLeft = (cameraForward - toRight + toTop);
            float camScale = topLeft.magnitude * camFar;

            topLeft.Normalize();
            topLeft *= camScale;

            Vector3 topRight = (cameraForward + toRight + toTop);
            topRight.Normalize();
            topRight *= camScale;

            Vector3 bottomRight = (cameraForward + toRight - toTop);
            bottomRight.Normalize();
            bottomRight *= camScale;

            Vector3 bottomLeft = (cameraForward - toRight - toTop);
            bottomLeft.Normalize();
            bottomLeft *= camScale;

            
            var quad = new Mesh 
            {
                name = "Quad",
                vertices = new[] 
                {
                    new Vector3(-1f, -1f, 0f),
                    new Vector3(-1f,  1f, 0f),
                    new Vector3( 1f, 1f, 0f),
                    new Vector3( 1f, -1f, 0f)
                },
                triangles = new[] { 0, 1, 2, 0, 2, 3 },
            };
            var raysDir = new[]{bottomLeft, topLeft, topRight, bottomRight};
            quad.SetUVs(0, raysDir);
            quad.UploadMeshData(true);
            return quad;
        }
    }
}