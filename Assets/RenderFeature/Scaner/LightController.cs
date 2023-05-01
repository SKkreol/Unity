using UnityEngine;
using UnityEditor;
using UnityEngine.UI;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;
using UnityEngine.Rendering.Universal;
//using UnityEngine.Rendering.PostProcessing;
//using VolumetricFogAndMist2;

public class LightController : MonoBehaviour
{
    // [SerializeField]
    // private DayNightChangeSettings settings;
    // [SerializeField]
    // private LightSettings VendigoSettings;

    [SerializeField]
    private Transform sun;

    [SerializeField]
    private float moonOffSet = 165.0f;

    [SerializeField, Range(0.4f, 0.6f)]
    private float switchToMoon = 0.45f;
    
    [SerializeField]
    private Transform moon;

    //tmp val
    public float val1 = 0.000001f;
    public float val2 = 0.0000001f;

    [HideInInspector]
    public float dayProgress = 1.0f;

    // [SerializeField]
    // private Blit vendigoView;
    //
    // [SerializeField]
    // private VendigoVisionBuffFeature vendigoPass;
    //
    // [SerializeField]
    // private Volume volume;
    // [SerializeField]
    // private HeightFogGlobal HeightFogVolume;
    // [SerializeField]
    // private VolumetricFogAndMist2.VolumetricFog mistFogVolume;

    [SerializeField]
    private Vector3 worldOffSet;

    static readonly int cameraForwardID = Shader.PropertyToID("_CameraForward");
    static readonly int lookIntensityID = Shader.PropertyToID("_LookIntensity");
    static readonly int sunViewSpaceID = Shader.PropertyToID("_SunViewSpace");
    static readonly int viewToWorldMatrixID = Shader.PropertyToID("VW_MATRIX");
    static readonly int inverseProjectionMatrixID = Shader.PropertyToID("P_MATRIX");
    static readonly int globalShadowColorID = Shader.PropertyToID("_GlobalShadowColor");
    static readonly int worldSpaceMoonPosID = Shader.PropertyToID("_WorldSpaceMoonPos");

    static readonly int initDecayID = Shader.PropertyToID("_InitDecay");
    static readonly int distDecayID = Shader.PropertyToID("_DistDecay");
    static readonly int maxDeltaLenID = Shader.PropertyToID("_MaxDeltaLen");
    static readonly int rayPowerID = Shader.PropertyToID("_RayPower");
    static readonly int rayColorID = Shader.PropertyToID("_RayColor");

    static readonly int сharacterPosID = Shader.PropertyToID("_CharacterPos");
    static readonly int worldSunDirOffSetID = Shader.PropertyToID("_WorldSunDirOffSet");
    static readonly int sunHaloSizeID = Shader.PropertyToID("_SunHaloSize");

    private Transform viewer;
    private Camera cameraMain;
    private float startGrassFogIntensity;
    private float startGeneralFogIntensity;
    const int width = 512;

    private Vector3 startDir;

    private Texture2D distanceFogTex;
    private Texture2D sunHaloGradientTex;

    private Texture2D sunTex, sunGlowTex;
    private Texture2D moonTex, moonGlowTex;

    private Light sunLight;
    private Light moonLight;
    private UnityEngine.Rendering.Universal.Bloom b;
    private float lookIntensity;
    private float dirtLensVal;
    private Transform character;
    private Matrix4x4 projectionMatrix;

    private Vector3 tmpSundDir;
    private Vector3 distantLightPosition;
    private Vector3 dirToSun;
    private Vector3 chPos;

    private Vector3 lightDirForward;

    float transitionNormalVendigo;
    bool wendigoOn = false;
    bool wendigoOff = false;

    private void Start()
    {
        dayProgress = 0.0f;
        // VolumeProfile profile = volume.sharedProfile;
        // profile.TryGet<UnityEngine.Rendering.Universal.Bloom>(out b);
        // dirtLensVal = b.dirtIntensity.value;
        //
        // //crutch
        // mistFogVolume.gameObject.SetActive(true);
        // mistFogVolume.gameObject.SetActive(false);
        // HeightFogVolume.gameObject.SetActive(true);
        // HeightFogVolume.gameObject.SetActive(false);
        //
        // startGrassFogIntensity = settings.intensity.Evaluate(dayProgress);
        // startGeneralFogIntensity = settings.density.Evaluate(dayProgress);
        // startDir = sun.localEulerAngles;
        //
        // vendigoView.SetActive(vendigoView.isEnable = false);
        // vendigoPass.SetActive(false);

        moon.gameObject.SetActive(false);
    }

    Vector3 GetDistantLightPosition()
    {
        return sun.forward * -100000.0f;
    }

    float GetLookIntensity(Vector3 dirSun, Vector3 dirForward)
    {
        float d = Mathf.Clamp01(Vector3.Dot(dirSun, dirForward));
        return Mathf.Pow(d, 3);
    }

    public void EnableStartGameFog ()
    {
        // if(settings!=null)
        // {
        //     mistFogVolume.profile.density = settings.startFogDensity;
        //     HeightFogVolume.fogIntensity = settings.startFogIntensity;
        //     HeightFogVolume.fogHeightEnd = settings.FogHeightEnd;
        //     mistFogVolume.gameObject.transform.position = new Vector3
        //     (
        //         mistFogVolume.gameObject.transform.position.x,
        //         settings.startPos,
        //         mistFogVolume.gameObject.transform.position.z
        //     );
        //
        //     mistFogVolume.gameObject.transform.localScale = new Vector3
        //     (
        //         mistFogVolume.gameObject.transform.localScale.x,
        //         settings.startScale,
        //         mistFogVolume.gameObject.transform.localScale.z
        //     );
        //     HeightFogVolume.gameObject.SetActive(true);
        //     mistFogVolume.gameObject.SetActive(true);
        // }
    }

    public void DisableFogIntensity()
    {
        // HeightFogVolume.fogIntensity = 0f;
        // HeightFogVolume.gameObject.SetActive(false);
        // mistFogVolume.gameObject.SetActive(false);  
    }

    public void ResetFogIntensity()
    {
        // HeightFogVolume.fogIntensity = startGrassFogIntensity;
        // mistFogVolume.profile.density = startGeneralFogIntensity;
        // HeightFogVolume.gameObject.SetActive(true);
        // mistFogVolume.gameObject.SetActive(true);
    }

    void OnEnable()
    {
        SceneManager.sceneLoaded += OnSceneLoaded;
    }

    void OnSceneLoaded(Scene scene, LoadSceneMode mode)
    {
        InitLight();
    }

    void OnDisable()
    {
        SceneManager.sceneLoaded -= OnSceneLoaded;
    }

    void dayChange()
    {
        // Shader.SetGlobalFloat(sunHaloSizeID, Mathf.Lerp(val1, val2,settings.sunSize.Evaluate(dayProgress)));//sun size
        //
        // //Sky box
        // Shader.SetGlobalColor("_TopSkyBoxColor", settings.topSkyBoxColor.Evaluate(dayProgress));
        // Shader.SetGlobalColor("_BottomSkyBoxColor", settings.bottomSkyBoxColor.Evaluate(dayProgress));
        // Shader.SetGlobalFloat("_HorizontHeight", settings.horizontHeight.Evaluate(dayProgress));
        //
        // //not include in vendigo
        //
        // //Sun sky box var
        // Shader.SetGlobalFloat("_SunRadius", settings.sunSkySize.Evaluate(dayProgress));
        // Shader.SetGlobalFloat("_SunGlowRadius", settings.sunGlowSkySize.Evaluate(dayProgress));
        // Shader.SetGlobalFloat("_sunBlend", settings.sunBlend.Evaluate(dayProgress));
        //
        // //Sun sky box tex
        // //PakedLutTexture(ref sunTex, settings.sunColor, width);
        // sunTex = sunTex.PakedLutTexture(settings.sunColor, width);
        // Shader.SetGlobalTexture("_sunTex", sunTex);
        //
        // //PakedLutTexture(ref sunGlowTex, settings.sunGlowColor, width);
        // sunGlowTex = sunGlowTex.PakedLutTexture(settings.sunGlowColor, width);
        // Shader.SetGlobalTexture("_sunGlowTex", sunGlowTex);
        //
        // //Moon sky box var
        // Shader.SetGlobalFloat("_MoonRadius", settings.moonSkySize.Evaluate(dayProgress));
        // Shader.SetGlobalFloat("_MoonGlowRadius", settings.moonGlowSkySize.Evaluate(dayProgress));
        // Shader.SetGlobalFloat("_moonBlend", settings.moonBlend.Evaluate(dayProgress));
        //
        // //Moon sky box tex
        // //PakedLutTexture(ref moonGlowTex, settings.moonColor, width);
        // moonGlowTex = moonGlowTex.PakedLutTexture(settings.moonColor, width);
        // Shader.SetGlobalTexture("_moonGlowTex", moonGlowTex);
        //
        // //PakedLutTexture(ref moonTex, settings.moonColor, width);
        // moonTex = moonTex.PakedLutTexture(settings.moonColor, width);
        // Shader.SetGlobalTexture("_moonTex", moonTex);
        //
        // RenderSettings.skybox = settings.skyBoxMaterial;
        //
        // //light settings
        // sunLight.color = settings.mainLightColor.Evaluate(dayProgress);
        //
        // sunLight.intensity = settings.mainLightIntensity.Evaluate(dayProgress);
        //
        // Shader.SetGlobalColor(globalShadowColorID, settings.globalShadowColor.Evaluate(dayProgress));
        //
        // sunLight.shadowStrength = settings.shadowStrength.Evaluate(dayProgress);
        //
        // //General fog
        // mistFogVolume.profile.albedo = settings.generalFogColor.Evaluate(dayProgress);
        // mistFogVolume.gameObject.transform.position = new Vector3
        // (
        //     mistFogVolume.gameObject.transform.position.x,
        //     settings.generalPos.Evaluate(dayProgress),
        //     mistFogVolume.gameObject.transform.position.z
        // );
        // mistFogVolume.gameObject.transform.localScale = new Vector3
        // (
        //     mistFogVolume.gameObject.transform.localScale.x,
        //     settings.generalScale.Evaluate(dayProgress),
        //     mistFogVolume.gameObject.transform.localScale.z
        // );
        //
        // mistFogVolume.profile.density = settings.density.Evaluate(dayProgress);
        // mistFogVolume.profile.windDirection = settings.windSpeed;
        //
        // var AOGlobalColor = settings.AOGlobalColor.Evaluate(dayProgress);
        // //RenderSettings.ambientLight = AOGlobalColor;
        //
        // //Grassfog
        // HeightFogVolume.noiseScale = settings.noiseScale.Evaluate(dayProgress);
        // HeightFogVolume.noiseSpeed = settings.noiseSpeed;
        // HeightFogVolume.fogIntensity = settings.intensity.Evaluate(dayProgress);
        // HeightFogVolume.fogColor = settings.grassFogColor.Evaluate(dayProgress);
        //
        // //colored fog settings
        // //RenderSettings.fogColor = settings.standartfogColor.Evaluate(dayProgress);
        // var settingsData = settings.fogRendererFeature.settings;
        // settingsData.near = settings.near.Evaluate(dayProgress);
        // settingsData.far = settings.far.Evaluate(dayProgress);
        // //PakedLutTexture(ref distanceFogTex, settings.fogDistanceGradient, width);
        // distanceFogTex = distanceFogTex.PakedLutTexture(settings.fogDistanceGradient, width);
        // Shader.SetGlobalTexture("_FogDistanceGradientTex", distanceFogTex);
        // var blendDistance = settings.blendFogDistanceGradient.Evaluate(dayProgress);
        // Shader.SetGlobalFloat("_BlendDistance", blendDistance);
        //
        // //PakedLutTexture(ref sunHaloGradientTex, settings.sunHaloGradient, width);
        // sunHaloGradientTex = sunHaloGradientTex.PakedLutTexture(settings.sunHaloGradient, width);
        // Shader.SetGlobalTexture("_SunHaloGradientTex", sunHaloGradientTex);
        // var sunHaloGradient = settings.blendSunHaloGradient.Evaluate(dayProgress);
        // Shader.SetGlobalFloat("_BlendSunHalo", sunHaloGradient);
        //
        // //God ray settings
        // settings.godRayFeature.blitMaterial.SetFloat(initDecayID, settings.initDecay.Evaluate(dayProgress));
        // settings.godRayFeature.blitMaterial.SetFloat(distDecayID, Mathf.Lerp(1.0f, 3.0f, settings.distDecay.Evaluate(dayProgress)));
        // settings.godRayFeature.blitMaterial.SetFloat(maxDeltaLenID, Mathf.Lerp(0.0025f, 0.0055f, settings.maxDeltaLen.Evaluate(dayProgress)));
        // settings.godRayFeature.blitMaterial.SetFloat(rayPowerID, Mathf.Lerp(0.0f, 0.05f, settings.rayPower.Evaluate(dayProgress)) * lookIntensity);
        // settings.godRayFeature.blitMaterial.SetColor(rayColorID, settings.rayColor.Evaluate(dayProgress));
    }


    static Color ColorLerp (Color a, Color b, float t)
    {
        Color color;
        color.r = Mathf.Lerp(a.r, b.r, t);
        color.g = Mathf.Lerp(a.g, b.g, t);
        color.b = Mathf.Lerp(a.b, b.b, t);
        color.a = Mathf.Lerp(a.a, b.a, t);
        return color;
    }

    void WendigoTime(float d)
    {
       //  float t = Mathf.Clamp01(d);
       //  var sunSize = Mathf.Lerp(Mathf.Lerp(val1, val2, settings.sunSize.Evaluate(dayProgress)), VendigoSettings.sunSize, t);
       //
       //  Shader.SetGlobalFloat(sunHaloSizeID, sunSize);//sun size
       //
       //  //Sky box
       //  var topSkyBoxColor = ColorLerp(settings.topSkyBoxColor.Evaluate(dayProgress), VendigoSettings.topSkyBoxColor, t);
       //  Shader.SetGlobalColor("_TopSkyBoxColor", topSkyBoxColor);
       //  var bottomSkyBoxColor = ColorLerp(settings.bottomSkyBoxColor.Evaluate(dayProgress), VendigoSettings.bottomSkyBoxColor, t);
       //  Shader.SetGlobalColor("_BottomSkyBoxColor", bottomSkyBoxColor);
       //  var horizontHeight = Mathf.Lerp(settings.horizontHeight.Evaluate(dayProgress), VendigoSettings.horizontHeight, t);
       //  Shader.SetGlobalFloat("_HorizontHeight", horizontHeight);
       //
       //  //light settings
       //  var mainLightColor = ColorLerp(settings.mainLightColor.Evaluate(dayProgress), VendigoSettings.lightColor, t);
       //  sunLight.color = mainLightColor;
       //
       //  var mainLightIntensity = Mathf.Lerp(settings.mainLightIntensity.Evaluate(dayProgress), VendigoSettings.lightIntensity, t);
       //  sunLight.intensity = mainLightIntensity;
       //
       //  var globalShadowColor = ColorLerp(settings.globalShadowColor.Evaluate(dayProgress), VendigoSettings.globalShadowColor, t);
       //  Shader.SetGlobalColor(globalShadowColorID, globalShadowColor);
       //
       //  var shadowStrength = Mathf.Lerp(settings.shadowStrength.Evaluate(dayProgress), VendigoSettings.shadowStrength, t);
       //  sunLight.shadowStrength = shadowStrength;
       //
       //  var AOGlobalColor = ColorLerp(settings.AOGlobalColor.Evaluate(dayProgress), VendigoSettings.AOGlobalColor, t);
       // // RenderSettings.ambientLight = AOGlobalColor;
       //
       //  //General fog
       //  var generalFogColor = ColorLerp(settings.generalFogColor.Evaluate(dayProgress), VendigoSettings.generalFogColor, t);
       //  mistFogVolume.profile.albedo = generalFogColor;
       //
       //  var generalPos = Mathf.Lerp(settings.generalPos.Evaluate(dayProgress), VendigoSettings.generalPos, t);
       //  mistFogVolume.gameObject.transform.position = new Vector3
       //  (
       //      mistFogVolume.gameObject.transform.position.x,
       //      generalPos,
       //      mistFogVolume.gameObject.transform.position.z
       //  );
       //
       //  var generalScale = Mathf.Lerp(settings.generalScale.Evaluate(dayProgress), VendigoSettings.generalScale, t);
       //  mistFogVolume.gameObject.transform.localScale = new Vector3
       //  (
       //      mistFogVolume.gameObject.transform.localScale.x,
       //      generalScale,
       //      mistFogVolume.gameObject.transform.localScale.z
       //  );
       //
       //  var density = Mathf.Lerp(settings.density.Evaluate(dayProgress), VendigoSettings.density, t);
       //
       //  mistFogVolume.profile.density = density;
       //  mistFogVolume.profile.windDirection = settings.windSpeed;
       //
       //  //Grassfog
       //  var noiseScale = Mathf.Lerp(settings.noiseScale.Evaluate(dayProgress), VendigoSettings.noiseScale, t);
       //  HeightFogVolume.noiseScale = noiseScale;
       //  HeightFogVolume.noiseSpeed = settings.noiseSpeed;
       //
       //  var intensity = Mathf.Lerp(settings.intensity.Evaluate(dayProgress), VendigoSettings.initDecay, t);
       //  HeightFogVolume.fogIntensity = intensity;
       //
       //  var grassFogColor = ColorLerp(settings.grassFogColor.Evaluate(dayProgress), VendigoSettings.grassFogColor, t);
       //  HeightFogVolume.fogColor = grassFogColor;
       //
       //
       //  //colored fog settings
       //  var settingsData = settings.fogRendererFeature.settings;
       //  var near = Mathf.Lerp(settings.near.Evaluate(dayProgress), VendigoSettings.near, t);
       //  settingsData.near = near;
       //  var far = Mathf.Lerp(settings.far.Evaluate(dayProgress), VendigoSettings.far, t);
       //  settingsData.far = far;
       //
       //  //PakedLutTexture(ref distanceFogTex, settings.fogDistanceGradient, width);
       //
       //  distanceFogTex = distanceFogTex.PakedLutTexture(settings.fogDistanceGradient, width);
       //  Shader.SetGlobalTexture("_FogDistanceGradientTex", distanceFogTex);
       //  var blendDistance = settings.blendFogDistanceGradient.Evaluate(dayProgress);
       //  Shader.SetGlobalFloat("_BlendDistance", blendDistance);
       //  //PakedLutTexture(ref sunHaloGradientTex, settings.sunHaloGradient, width);
       //
       //  sunHaloGradientTex = sunHaloGradientTex.PakedLutTexture(settings.sunHaloGradient, width);
       //  Shader.SetGlobalTexture("_SunHaloGradientTex", sunHaloGradientTex);
       //  var sunHaloGradient = settings.blendSunHaloGradient.Evaluate(dayProgress);
       //  Shader.SetGlobalFloat("_BlendSunHalo", sunHaloGradient);
       //
       //  //God ray settings
       //  var initDecay = Mathf.Lerp(settings.initDecay.Evaluate(dayProgress), VendigoSettings.initDecay, t);
       //  settings.godRayFeature.blitMaterial.SetFloat(initDecayID, initDecay);
       //  var distDecay = Mathf.Lerp(Mathf.Lerp(1.0f, 3.0f, settings.distDecay.Evaluate(dayProgress)), Mathf.Lerp(1.0f, 3.0f, VendigoSettings.initDecay), t);
       //  settings.godRayFeature.blitMaterial.SetFloat(distDecayID, distDecay);
       //  var maxDeltaLen = Mathf.Lerp(Mathf.Lerp(0.0025f, 0.0055f, settings.maxDeltaLen.Evaluate(dayProgress)), Mathf.Lerp(0.0025f, 0.0055f, VendigoSettings.maxDeltaLen), t);
       //  settings.godRayFeature.blitMaterial.SetFloat(maxDeltaLenID, maxDeltaLen);
       //  var rayPower = Mathf.Lerp(Mathf.Lerp(0.0f, 0.05f, settings.rayPower.Evaluate(dayProgress)), Mathf.Lerp(0.0f, 0.05f, VendigoSettings.rayPower), t);
       //  settings.godRayFeature.blitMaterial.SetFloat(rayPowerID, rayPower * lookIntensity);
       //  var rayColor = ColorLerp(settings.rayColor.Evaluate(dayProgress), VendigoSettings.rayColor, t);
       //  settings.godRayFeature.blitMaterial.SetColor(rayColorID, rayColor);
    }

    public void EnableWendigoBuff()
    {
        wendigoOn = true;
        wendigoOff = false;
        transitionNormalVendigo = 0;

        //vendigoView.SetActive(vendigoView.isEnable = true);
        //vendigoPass.SetActive(true);
    }

    public void DisableWendigoBuff()
    {
        wendigoOff = true;
        wendigoOn = false;
        transitionNormalVendigo = 1.0f;
        //vendigoView.SetActive(vendigoView.isEnable = false);
        //vendigoPass.SetActive(false);
    }

    private void Update()
    {
        // if (settings == null)
        //     return;

        if(dayProgress >= switchToMoon)
        {
            moon.gameObject.SetActive(true);
            // moonLight.intensity = settings.mainLightIntensity.Evaluate(dayProgress);
            // moonLight.color = settings.mainLightColor.Evaluate(dayProgress);
            sun.gameObject.SetActive(false);
        }
        else
        {
            sun.gameObject.SetActive(true);
            moon.gameObject.SetActive(false);
        }

        tmpSundDir.x = -60.0f * dayProgress + 30.0f;
        tmpSundDir.y = startDir.y;
        tmpSundDir.z = startDir.z;

        Vector3 moonDir = new Vector3(tmpSundDir.x + moonOffSet, tmpSundDir.y, tmpSundDir.z);
        moon.localEulerAngles = moonDir;

        Shader.SetGlobalVector(worldSpaceMoonPosID, moon.rotation * Vector3.forward);
        sun.localEulerAngles = tmpSundDir;

        // sun animation 
        if (character)
        {

            //Character pos
            chPos = character.position;
            //Light world dir
            lightDirForward = -sun.forward;
            //world light offset
            Shader.SetGlobalVector(worldSunDirOffSetID, chPos + Vector3.Scale(worldOffSet, lightDirForward));
            Shader.SetGlobalVector(сharacterPosID, character.position - worldOffSet);
        }
        
        projectionMatrix = GL.GetGPUProjectionMatrix(cameraMain.projectionMatrix, false);
        Shader.SetGlobalMatrix(inverseProjectionMatrixID, projectionMatrix.inverse);
        Shader.SetGlobalMatrix(viewToWorldMatrixID, cameraMain.cameraToWorldMatrix);

        // if (NetworkManager.Instance.me != null && GameManager.Instance.SessionInTrainingAndPreparation)
        // {
        //     character = NetworkManager.Instance.me.transform;
        // }
        //
        // if(settings.fogRendererFeature)
        // {
        //     if(Application.isPlaying)
        //     {
        //         settings.fogRendererFeature.SetActive(settings.useCustomFog == true ? true : false);
        //         settings.godRayFeature.SetActive(settings.useRay == true ? true : false);
        //     }
        //     else
        //     {
        //         settings.fogRendererFeature.SetActive(false);
        //         settings.godRayFeature.SetActive(false);
        //     }         
        // }
        Shader.SetGlobalVector(cameraForwardID, viewer.forward);

        if (sun)
        {
            distantLightPosition = GetDistantLightPosition();
            dirToSun = (distantLightPosition - viewer.position).normalized;
            lookIntensity = GetLookIntensity(dirToSun, viewer.forward);
            Shader.SetGlobalFloat(lookIntensityID, lookIntensity);

            if(b)
            {
                b.dirtIntensity.value = lookIntensity * 7.0f;
            }
        }

        if(cameraMain && sun)
        {
            Shader.SetGlobalVector(sunViewSpaceID, cameraMain.WorldToViewportPoint(GetDistantLightPosition()));
        }

        // if (GameManager.Instance.SessionInTrainingAndPreparation)
        //     return;
        dayChange();

        if (wendigoOn)
        {
            transitionNormalVendigo += Time.deltaTime * 0.66f;
            WendigoTime(transitionNormalVendigo);
            moon.gameObject.SetActive(true);
            sun.gameObject.SetActive(false);
        }

        if (wendigoOff)
        {
            transitionNormalVendigo -= Time.deltaTime * 0.66f;
            WendigoTime(transitionNormalVendigo);
            moon.gameObject.SetActive(false);
            sun.gameObject.SetActive(true);
        }
    }

    void SetGrassFogSettings()
    {
        // if (settings.useGrassFog && HeightFogVolume != null)
        // {
        //     HeightFogVolume.fogColor = settings.grassFogColor.Evaluate(dayProgress);
        //     HeightFogVolume.noiseScale = settings.noiseScale.Evaluate(dayProgress);
        //     HeightFogVolume.noiseSpeed = settings.noiseSpeed;
        //     HeightFogVolume.fogIntensity = settings.intensity.Evaluate(dayProgress);
        //     HeightFogVolume.gameObject.SetActive(true);
        // }
        //
        // if (!settings.useGrassFog && HeightFogVolume != null)
        // {
        //     HeightFogVolume.gameObject.SetActive(false);
        // }
    }

    void InitLight()
    {
        cameraMain = Camera.main;
        viewer = cameraMain.transform;

        if (sun == null)
        {
            sun = GameObject.Find("Sun Light").transform;
            sunLight = sun.GetComponent<Light>();
        }
        else
        {
            sunLight = sun.GetComponent<Light>();
        }

        if (moon == null)
        {
            moon = GameObject.Find("Moon Light").transform;
            moonLight = moon.GetComponent<Light>();
        }
        else
        {
            moonLight = moon.GetComponent<Light>();
        }

        // if (volume == null)
        // {
        //     volume = GameObject.FindObjectOfType<Volume>();
        // }
        //
        // if (HeightFogVolume == null)
        // {
        //     HeightFogVolume = GameObject.FindObjectOfType<HeightFogGlobal>();
        // }
        //
        // if (mistFogVolume == null)
        // {
        //     mistFogVolume = GameObject.FindObjectOfType<VolumetricFogAndMist2.VolumetricFog>();
        // }
        dayProgress = 0.0f;
        dayChange();
    }
}