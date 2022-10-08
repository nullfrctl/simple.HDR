// Include ReShade libraries.
#include "ReShade.fxh"
#include "ReShadeUI.fxh"

/* ACES functions -- courtesy of Baking Lab */

// sRGB => XYZ => D65_2_D60 => AP1 => RRT_SAT
static const float3x3 ACESInputMat = float3x3(
    0.59719, 0.35458, 0.04823,
    0.07600, 0.90834, 0.01566,
    0.02840, 0.13383, 0.83777
);

// ODT_SAT => XYZ => D60_2_D65 => sRGB
static const float3x3 ACESOutputMat = float3x3(
     1.60475, -0.53108, -0.07367,
    -0.10208,  1.10813, -0.00605,
    -0.00327, -0.07276,  1.07602
);

// RRT => ODT
float3 RRTAndODTFit(float3 v)
{
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

/* UI */

uniform int PreprocHelp
<
    ui_text = "simple.HDR | preprocessor definitions guide\n"
              "\n"
              "SIMPLE_HDR_SRGB: \n"
              "\tControls wether simple.HDR converts the sRGB backbuffer to linear sRGB.\n"
              "\tThis is automatically set to 0 when using 10-bit backbuffer and vice-versa.\n"
              "\n"
              "OPEN \"Preprocessor definitions\" BELOW\n"
              "\n"
              "____________________________________________________________________________________";
    ui_label = " ";
    ui_type = "radio";
>;

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

void HDRPS(in float4 vpos : SV_POSITION, in float2 texcoord : TEXCOORD0, out float4 o : SV_TARGET0)
{

    // Sample backbuffer texture
    o = tex2D(BackBuffer, texcoord.xy);

    // Copy backbuffer texture
    float3 color = o.rgb;

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
    o.rgb = color;
    o.a = 1.0f;
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