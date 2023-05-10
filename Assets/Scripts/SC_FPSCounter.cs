using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SC_FPSCounter : MonoBehaviour
{
  /* Assign this script to any object in the Scene to display frames per second */

  public float updateInterval = 0.5f; //How often should the number update

  float accum = 0.0f;
  int frames = 0;
  float timeleft;
  float fps;

  GUIStyle textStyle = new GUIStyle();

  // Use this for initialization
  void Start()
  {
    timeleft = updateInterval;

    textStyle.fontStyle = FontStyle.Bold;
    
    textStyle.fontSize = 40;
  }

  // Update is called once per frame
  void Update()
  {
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
    if(fps > 50)
      textStyle.normal.textColor = Color.green;
    
    if(fps > 30 && fps < 50)
      textStyle.normal.textColor = Color.yellow;
    
    if(fps < 30)
      textStyle.normal.textColor = Color.red;
  }

  void OnGUI()
  {
    //Display the fps and round to 2 decimals
    GUI.Label(new Rect(10, 10, 100, 50), fps.ToString("F2") + "FPS", textStyle);
  }
}