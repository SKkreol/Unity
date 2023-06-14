using UnityEngine;

[ExecuteInEditMode]
public class Scanner : MonoBehaviour
{
    public Cubemap fog;
    private Matrix4x4 _projectionMatrix;
    private static readonly int ViewToWorldMatrixID = Shader.PropertyToID("VW_MATRIX");
    private static readonly int InverseProjectionMatrixID = Shader.PropertyToID("P_MATRIX");
    
    [SerializeField]
    private Camera _cameraMain;
    [SerializeField] private Transform Character;
    private static readonly int CharacterPos = Shader.PropertyToID("_Pos");
    [SerializeField, Min(0)]
    private float speed = 1.0f;
    [SerializeField]
    private float duration = 2.0f;

    [SerializeField, Range(0f, 1f)] private float time = 0.0f;
    [SerializeField] private float scanDistance = 100.0f;
    [SerializeField] private Transform sphere;
    [SerializeField] private AnimationCurve _curve;
    private Texture2D lutTex;
    [SerializeField] private Gradient _gradient = new Gradient();

    private float t = 0.0f;
    private bool _scan;
    private static readonly int ScanerSize = Shader.PropertyToID("_ScanerSize");
    private static readonly int ScanWidth = Shader.PropertyToID("_ScanWidth");
    private static readonly int LutTex = Shader.PropertyToID("_LutTex");
    private static readonly int FogMap = Shader.PropertyToID("_FogMap");

    [ContextMenu("Scan")]
    public void Scan()
    {
        _scan = true;
    }

    private void Awake()
    {
        Application.targetFrameRate = 60;
        Shader.SetGlobalTexture(FogMap, fog);
    }
    
    private Texture2D LutTexture(Gradient gradient, ref Texture2D texture)
    {
        if (texture == null)
        {
            texture = new Texture2D(256, 1, TextureFormat.RGBA32, false)
            {
                wrapMode = TextureWrapMode.Clamp,
                filterMode = FilterMode.Bilinear
            };
        }

        for (float x = 0; x < 256; x++)
        {
            Color color = gradient.Evaluate(x / (256 - 1));
            for (float y = 0; y < 1; y++)
            {
                texture.SetPixel(Mathf.CeilToInt(x), Mathf.CeilToInt(y), color);
            }
        }

        texture.Apply();
        return texture;
    }

    private void Update()
    {
            LutTexture(_gradient, ref lutTex);

        Shader.SetGlobalTexture(LutTex, lutTex);
        // _projectionMatrix = GL.GetGPUProjectionMatrix(_cameraMain.projectionMatrix, false);
        // Shader.SetGlobalMatrix(InverseProjectionMatrixID, _projectionMatrix.inverse);
        // Shader.SetGlobalMatrix(ViewToWorldMatrixID, _cameraMain.cameraToWorldMatrix);
        // if (_scan)
        // {
            Shader.SetGlobalVector(CharacterPos, Character.position);

            t += Time.unscaledDeltaTime * speed;
            if (t >= 1.0f)
                t = 0.0f;

            var e = _curve.Evaluate(t);

            var w = Mathf.Lerp(0.5f, 20.5f, t);

            Shader.SetGlobalFloat(ScanerSize, e*scanDistance);
            Shader.SetGlobalFloat(ScanWidth, w);
        //}

    }
}