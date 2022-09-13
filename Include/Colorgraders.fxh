uniform int CG_Enabled <
    ui_type = "slider";
    ui_label = "Quick Switch";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 1;

uniform int color_curve <
    ui_type = "combo";
    ui_items = "Mode 1\0Mode 2\0Mode 3\0";
    ui_label = "Colorgrading Curve";
    ui_category = "Colorgrading";
    ui_category_closed = true;
    ui_spacing = 5;
> = 0;

uniform float color_contrast <
    ui_type = "drag";
    ui_label = "Contrast";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float color_saturation <
    ui_type = "drag";
    ui_label = "Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float saturation_r <
    ui_spacing = 5;
    ui_type = "drag";
    ui_label = "Red Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float saturation_y <
    ui_type = "drag";
    ui_label = "Yellow Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float saturation_g <
    ui_type = "drag";
    ui_label = "Green Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float saturation_a <
    ui_type = "drag";
    ui_label = "Aqua Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float saturation_b <
    ui_type = "drag";
    ui_label = "Blue Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float saturation_p <
    ui_type = "drag";
    ui_label = "Purple Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

uniform float saturation_m <
    ui_type = "drag";
    ui_label = "Magenta Saturation";
    ui_category = "Colorgrading";
    ui_category_closed = true;
> = 0.0;

float3 RGBToHCV( in float3 RGB )
{
    // Based on work by Sam Hocevar and Emil Persson
    float4 P         = ( RGB.g < RGB.b ) ? float4( RGB.bg, -1.0f, 2.0f/3.0f ) : float4( RGB.gb, 0.0f, -1.0f/3.0f );
    float4 Q1        = ( RGB.r < P.x ) ? float4( P.xyw, RGB.r ) : float4( RGB.r, P.yzx );
    float C          = Q1.x - min( Q1.w, Q1.y );
    float H          = abs(( Q1.w - Q1.y ) / ( 6.0f * C + 0.000001f ) + Q1.z );
    return float3( H, C, Q1.x );
}

float3 RGBToHSL( in float3 RGB )
{
    RGB.xyz          = max( RGB.xyz, 0.000001f );
    float3 HCV       = RGBToHCV(RGB);
    float L          = HCV.z - HCV.y * 0.5f;
    float S          = HCV.y / ( 1.0f - abs( L * 2.0f - 1.0f ) + 0.000001f);
    return float3( HCV.x, S, L );
}

static const float PI = 3.1415927;

float curve( float x )
{
    switch (color_curve)
    {
        case 0: 
			x = sin(PI * 0.5 * x); // Sin - 721 amd fps, +vign 536 nv
			x *= x;
            break;
        case 1:
			x = x - 0.5;
			x = (x / (0.5 + abs(x))) + 0.5;
            break;
        case 2:
            x = x*x*(3.0 - 2.0*x); //faster smoothstep alternative - 776 amd fps, +vign 536 nv
            break;
    }

    return x;
}

float calculate_weight(float hue, float weight)
{
    return curve(max(1.0-abs((hue - weight) * 6.0), 0.0));
}

float3 contrast(float3 color)
{
    float luma = dot(color, float3(0.212656, 0.715158, 0.072186));
    float3 chroma = color - luma;

    float x = curve(luma);
    luma = lerp(luma, x, color_contrast);

    return luma + chroma;
}

float3 saturation(float3 color, float saturation)
{
    float luma = dot(color, float3( 0.212656, 0.715158, 0.072186 ));

    return lerp(luma, color, saturation);
}

float3 channelsat(float3 col, float sat[7], float hue)
{
    float desat = dot(col, float3( 0.212656, 0.715158, 0.072186 ));

    // Red         : 0.0
    // Orange      : 0.083
    // Yellow      : 0.167
    // Green       : 0.333
    // Cyan/Aqua   : 0.5
    // Blue        : 0.667
    // Purple      : 0.75
    // Magenta     : 0.833

    float weight_r = curve(max(1.0f - abs((hue - 0.0f     ) * 6.0f), 0.0f))+
                     curve(max(1.0f - abs((hue - 1.0f     ) * 6.0f), 0.0f));
    float weight_y = curve(max(1.0f - abs((hue - 0.166667f) * 6.0f), 0.0f));
    float weight_g = curve(max(1.0f - abs((hue - 0.333333f) * 6.0f), 0.0f));
    float weight_a = curve(max(1.0f - abs((hue - 0.5f     ) * 6.0f), 0.0f));
    float weight_b = curve(max(1.0f - abs((hue - 0.666667f) * 6.0f), 0.0f));
    float weight_p = curve(max(1.0f - abs((hue - 0.75f    ) * 6.0f), 0.0f));
    float weight_m = curve(max(1.0f - abs((hue - 0.833333f) * 6.0f), 0.0f));

    float weights[7] = {weight_r, weight_y, weight_g, weight_a, weight_b, weight_p, weight_m};

    col.xyz = saturation(col.xyz, clamp(1.0f + sat[0] * weight_r, 0.0f, 2.0f));
    col.xyz = saturation(col.xyz, clamp(1.0f + sat[1] * weight_y, 0.0f, 2.0f));
    col.xyz = saturation(col.xyz, clamp(1.0f + sat[2] * weight_g, 0.0f, 2.0f));
    col.xyz = saturation(col.xyz, clamp(1.0f + sat[3] * weight_a, 0.0f, 2.0f));
    col.xyz = saturation(col.xyz, clamp(1.0f + sat[4] * weight_b, 0.0f, 2.0f));
    col.xyz = saturation(col.xyz, clamp(1.0f + sat[5] * weight_p, 0.0f, 2.0f));
    col.xyz = saturation(col.xyz, clamp(1.0f + sat[6] * weight_m, 0.0f, 2.0f));

    return saturate( col.xyz );
}