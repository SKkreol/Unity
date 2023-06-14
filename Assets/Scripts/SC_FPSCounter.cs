using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SC_FPSCounter : MonoBehaviour
{

  /* Assign this script to any object in the Scene to display frames per second */

  public float updateInterval = 0.5f; //How often should the number update
  public TextMeshProUGUI FPSText;
  public TextMeshProUGUI resolutionText;
  float accum = 0.0f;
  int frames = 0;
  float timeleft;
  float fps;
  private string res;
  private float w, h;

  GUIStyle textStyle = new GUIStyle();

  private void Awake()
  {
  }

  // Use this for initialization
  void Start()
  {
    timeleft = updateInterval;
    var resolutions = Screen.resolutions;
    foreach (var resolution in resolutions)
    {
      Debug.LogError(5);
    }
    var r = resolutions[^3];

    resolutionText.text = r.width.ToString() + "x" + r.height.ToString();
    // textStyle.fontStyle = FontStyle.Bold;
    //
    // textStyle.fontSize = 40;
  }

  // Update is called once per frame
  void Update()
  {
    Screen.SetResolution(1280, 720, true);
    timeleft -= Time.deltaTime;
    accum += Time.timeScale / Time.deltaTime;
    ++frames;

    // Interval ended - update GUI text and start new interval
    if (timeleft <= 0.0)
    {
      // display two fractional digits (f2 format)
      fps = (accum / frames);
      timeleft = updateInterval;
      accum = 0.0f;
      frames = 0;
    }

    FPSText.text = fps.ToString();
    if(fps > 50)
      FPSText.color = Color.green;
    
    if(fps > 30 && fps < 50)
      FPSText.color = Color.yellow;
    
    if(fps < 30)
       FPSText.color = Color.red;



    
  }

  void OnGUI()
  {
    
    var resolutions = Screen.resolutions;
    var i = 0;
    foreach (var resolution in resolutions)
    {
      GUI.Label(new Rect(10, 10+i, 200, 100), resolution.width.ToString() + resolution.height.ToString(), textStyle);
      i += 50;
    }
    //Display the fps and round to 2 decimals
   // GUI.Label(new Rect(10, 10, 100, 50), fps.ToString("F2") + "FPS", textStyle);
    //GUI.Label(new Rect(10, 50, 100, 50), w + "x" + h, textStyle);
    //GUI.Label(new Rect(10, 100, 100, 50), res, textStyle);
  }
}