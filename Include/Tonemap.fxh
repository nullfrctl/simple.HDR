#pragma once
#include "Common.fxh"

namespace ACES
{
    #include "ACES.fxh"

    float3 Fitted(in float3 color)
    {
        color = ACESFitted(color);
        color = ApplyCurve(color * 1.8);
        return color;
    }

    float3 Filmic(in float3 color)
    {
        color = ACESFilmRec2020(color);
        color = ApplyCurve(color);
        return color;
    }
}

namespace Filmic
{
    float3 ALU(in float3 color)
    {
        color = max(0, color - 0.004f);
        color = (color * (6.2f * color + 0.5f)) / (color * (6.2f * color + 1.7f)+ 0.06f);
        return color;
    }
}

namespace Hejl
{

    uniform float Hejl_Whitepoint <
        ui_type = "drag";
        ui_label = "Hejl 2015 Whitepoint";
        ui_category = "Hejl 2015";
        ui_category_closed = true;
> = 1.0;

    float3 Hejl2015(in float3 hdr)
    {
        float4 vh = float4(hdr, Hejl_Whitepoint);
        float4 va = (1.435f * vh) + 0.05;
        float4 vf = ((vh * va + 0.004f) / ((vh * (va + 0.55f) + 0.0491f))) - 0.0821f;
        return ApplyCurve(vf.xyz / vf.www);
    }
}

namespace Hable
{
    
    uniform float Hable_Whitepoint <
        ui_type = "drag";
        ui_label = "Hable Whitepoint";
        ui_category = "Hable Filmic";
        ui_category_closed = true;
    > = 6.0;
    
    uniform float Hable_ShoulderStrength <
        ui_type = "drag";
        ui_label = "Shoulder Strength";
        ui_category = "Hable Filmic";
        ui_category_closed = true;
    > = 4.0f;
    
    uniform float Hable_LinearStrength <
        ui_type = "drag";
        ui_label = "Linear Strength";
        ui_category = "Hable Filmic";
        ui_category_closed = true;
    > = 5.0f;
    
    uniform float Hable_LinearAngle <
        ui_type = "drag";
        ui_label = "Linear Angle";
        ui_category = "Hable Filmic";
        ui_category_closed = true;
    > = 0.12f;
    
    uniform float Hable_ToeStrength <
        ui_type = "drag";
        ui_label = "Toe Strength";
        ui_category = "Hable Filmic";
        ui_category_closed = true;
    > = 12.0f;
    
    float3 HableFunction(in float3 x) {
        const float A = Hable_ShoulderStrength;
        const float B = Hable_LinearStrength;
        const float C = Hable_LinearAngle;
        const float D = Hable_ToeStrength;
    
        // Not exposed as settings
        const float E = 0.01f;
        const float F = 0.3f;
    
        return ((x * (A * x + C * B)+ D * E) / (x * (A * x + B) + D * F)) - E / F;
    }
    
    float3 Filmic(in float3 color) {
        float3 numerator = HableFunction(color);
        float3 denominator = HableFunction(Hable_Whitepoint);
    
        return ApplyCurve(numerator / denominator);
    }
}