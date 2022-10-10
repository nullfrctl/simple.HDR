/*

simple.HDR | main file
________________________________________________________________________________

*/

/* Includes */

// Include ReShade library
#include "ReShade.fxh"

// Turn off full ACES support for now, opting for BakingLab's approx.
// DON'T TOUCH THIS, FULL ACES SUPPORT IS NOT IMPLEMENTED
#ifndef _SIMPLE_HDR_ACES_APPROX
    #define _SIMPLE_HDR_ACES_APPROX 1
#endif

// Include ACES (thx to Unity FPSSample & BakingLab by MJP)
#include "ACES.fxh"

// Include UI file.
#include "simple.HDR.UI.fxh"

/* HDR */

#ifndef SIMPLE_HDR_SRGB
#   if (BUFFER_BIT_COLOR_DEPTH < 10)
#       define SIMPLE_HDR_SRGB 1
#   else
#       define SIMPLE_HDR_SRGB 0
#   endif
#endif

sampler2D BackBuffer
{
    // Set our backbuffer to be ReShade's supply.
    Texture = ReShade::BackBufferTex;

    // We don't need scaling, so set to POINT to ensure SGSSAA compatibility.
    MagFilter = POINT;
    MinFilter = POINT;
    MipFilter = POINT;

    // Convert sRGB backbuffer to linear sRGB
    SRGBTexture = SIMPLE_HDR_SRGB;
};

float3 HDRPS
(
    in float4 vpos     : SV_POSITION, 
    in float2 texcoord : TEXCOORD0
) : SV_TARGET
{
	// Don't process if ACES mix is zero.
	if (ACESMix == 0.0) discard;

    // Sample backbuffer texture
    float3 res = tex2D(BackBuffer, texcoord.xy).rgb;

    // Copy backbuffer texture
    float3 color = res;

    // Convert linear sRGB to RRT
    color = mul(ACESInputMat, color);

    // Convert RRT to ODT
    color = RRTAndODTFit(color);

    // Convert ODT back to linear sRGB
    color = mul(ACESOutputMat, color);

    // Clamp to [0, 1]
    color = saturate(color);

    // Apply multiplier to color to correct exposure
    color *= 1.8f;

    // Copy back color to backbuffer
    res = lerp(res, color, ACESMix);

    // Output result
    return res;
}

technique simpleHDR < ui_label = "simple.HDR"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = HDRPS;

        // Convert linear texture to sRGB
        SRGBWriteEnable = SIMPLE_HDR_SRGB;
    }
}