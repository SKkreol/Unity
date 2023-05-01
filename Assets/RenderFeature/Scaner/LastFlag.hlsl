#ifndef LAST_FLAG_INCLUDED
#define LAST_FLAG_INCLUDED


TEXTURE2D(_CameraDepthTexture);            
SAMPLER(sampler_CameraDepthTexture);

float SampleRawDepth(float2 uv)
{
	return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
}

#endif