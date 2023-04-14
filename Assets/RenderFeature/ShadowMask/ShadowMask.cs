using UnityEngine;
using Unity.Mathematics;

public class ShadowMask : MonoBehaviour
{
  [SerializeField] 
  private float4 shadowMask = float4.zero;
  private Renderer _rend;

  void Awake()
  {
    _rend = gameObject.GetComponent<Renderer>();
    _rend.realtimeLightmapIndex = 0;
    _rend.realtimeLightmapScaleOffset = shadowMask;
  }
}