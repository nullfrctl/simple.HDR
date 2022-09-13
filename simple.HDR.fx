uniform int HDR_Mode <
    ui_type = "combo";
    ui_items = "Linear\0Film Stock\0ACES\0Hejl\0Hable\0";
    ui_label = "HDR Mode";
> = 0;

uniform int ACES_Mode <
    ui_items = "Normal\0Filmic\0";
    ui_type = "combo";
    ui_label = "ACES Mode";
    ui_category = "ACES (Krzysztof Narkowicz)";
    ui_category_closed = true;
> = 0;

#include "Common.fxh"
#include "Tonemap.fxh"
#include "Exposure.fxh"
#include "Colorgraders.fxh"
//#include "DrawText.fxh"

uniform float timer < source = "Timer"; >;

void HDRPS(in float4 vpos : SV_POSITION, in float2 texcoord : TEXCOORD0, out float4 o : SV_TARGET0)
{
    // Sample backbuffer texture
    o = tex2D(SamplerColor, texcoord.xy);

    // Copy backbuffer into an original
    float4 orig = o;

    // Convert color to linear
    //o.rgb = RemoveCurve(o.rgb);
    o.rgb = CalcExposedColor(o.rgb, 1.0);

    switch (HDR_Mode)
    {
        case 0: o.rgb = ApplyCurve(o.rgb); break;
        case 1: o.rgb = Filmic::ALU(o.rgb); break;
        case 2: o.rgb = ACES_Mode ? ACES::Filmic(o.rgb) : ACES::Fitted(o.rgb); break;
        case 3: o.rgb = Hejl::Hejl2015(o.rgb); break;
        case 4: o.rgb = Hable::Filmic(o.rgb); break;
    }

    if (CG_Enabled)
    {
        // Define per-color saturation and apply.
        float per_channel_sat[7] = {saturation_r, saturation_y, saturation_g, saturation_a, saturation_b, saturation_p, saturation_m};
        o.rgb = channelsat(o.rgb, per_channel_sat, RGBToHSL(o.rgb).x);
        
        // Apply global saturation.
        o.rgb = saturation(o.rgb, color_saturation + 1.0);
    
        // Apply contrast
        o.rgb = contrast(o.rgb);
    }
}

technique simpleHDR < ui_label = "simple.HDR"; >
{
    pass
    {
        VertexShader = VS;
        PixelShader = HDRPS;
    }
}