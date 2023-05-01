using System.Collections;
using UnityEngine;

public class ScannerController : MonoBehaviour
{
    // [SerializeField]
    // private Blit scannerEffect;

    [SerializeField]
    private Transform scoutCompasPos;

    [SerializeField]
    private AnimationCurve AnimationCurve;

    [SerializeField]
    private Gradient edgeColor = new Gradient();

    private bool isStart = false;
    private float radarAnim = -0.5f;
    private Texture2D lutTex;
    private float timer;
    private float duration = 1.5f;

    static readonly int scoutCompasPosID = Shader.PropertyToID("_ScoutCompasPos");
    static readonly int radarAnimID = Shader.PropertyToID("_RadarAnim");
    static readonly int fadeTexID = Shader.PropertyToID("_FadeTex");


    [ContextMenu("Enable")]
    public void EnableScanner()
    {
        // if (scannerEffect)
        // {
        //     isStart = true;
        //     radarAnim = -0.5f;
        //     scoutCompasPos.gameObject.SetActive(true);
        //     scannerEffect.SetActive(scannerEffect.isEnable = true);
        //     StartCoroutine(ScaneerAnimation());
        // }
    }

    public void DisableScanner()
    {
        // if (scannerEffect)
        // {
        //     isStart = false;
        //     scoutCompasPos.gameObject.SetActive(false);
        //     radarAnim = -0.5f;
        //     timer = 0.0f;
        //     scannerEffect.SetActive(scannerEffect.isEnable = false);
        //     StopCoroutine(ScaneerAnimation());
        // }   
    }

    //void ScaneerAnimation()
    //{
    //    timer += Time.deltaTime;
    //    radarAnim = Mathf.Lerp(-0.5f, 3.0f, AnimationCurve.Evaluate(timer));

    //    if (timer > duration)
    //    {
    //        timer = 0.0f;
    //    }

    //    Shader.SetGlobalFloat(radarAnimID, radarAnim);
    //    Shader.SetGlobalVector(scoutCompasPosID, scoutCompasPos.position);

    //    //LutTexture(edgeColor, ref lutTex); uncomment for setup
    //    //Shader.SetGlobalTexture(fadeTexID, lutTex);
    //}

    private IEnumerator ScaneerAnimation()
    {
        while(isStart)
        {
            timer += Time.deltaTime;
            radarAnim = Mathf.Lerp(-0.5f, 3.0f, AnimationCurve.Evaluate(timer));

            if (timer > duration)
            {
                timer = 0.0f;
            }
            //LutTexture(edgeColor, ref lutTex); uncomment for setup
            //Shader.SetGlobalTexture(fadeTexID, lutTex);

            Shader.SetGlobalFloat(radarAnimID, radarAnim);
            Shader.SetGlobalVector(scoutCompasPosID, scoutCompasPos.position);
            yield return null;
        }
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

    private void Start()
    {
        //scannerEffect.isEnable = false;
        duration = AnimationCurve.keys[AnimationCurve.keys.Length - 1].time;

        LutTexture(edgeColor, ref lutTex);
        Shader.SetGlobalTexture(fadeTexID, lutTex);

        Shader.SetGlobalFloat(radarAnimID, radarAnim);
        radarAnim = -0.5f;
        Shader.SetGlobalVector(scoutCompasPosID, scoutCompasPos.position);
    }

    //void Update()
    //{
    //    if (scoutCompasPos)
    //    {

    //        if (Input.GetKeyDown(KeyCode.T))
    //        {
    //            EnableScanner();

    //        }

    //        if (Input.GetKeyDown(KeyCode.Y))
    //        {
    //            DisableScanner();
    //        }

    //        //Scanner animation
    //        if (isStart)
    //        {
    //            ScaneerAnimation();
    //        }
    //    } 
    //}
}