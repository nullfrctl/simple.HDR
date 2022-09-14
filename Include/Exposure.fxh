//=================================================================================================
//
//  Baking Lab
//  by MJP and David Neubelt
//  http://mynameismjp.wordpress.com/
//
//  All code licensed under the MIT license
//
//=================================================================================================

// The two functions below were based on code and explanations provided by Padraic Hennessy (@PadraicHennessy).
// See this for more info: https://placeholderart.wordpress.com/2014/11/21/implementing-a-physically-based-camera-manual-exposure/

// modes
#ifndef PRESET_MODE
    #define PRESET_MODE 1
#endif

uniform int ExposureMode <
    ui_items = "Manual (Simple)\0Manual (SBS)\0Manual (SOS)\0";
    ui_label = "Exposure Mode";
    ui_type = "combo";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 0;

uniform float ShutterSpeedInSeconds <
    ui_type = "drag";
    ui_step = 1.0;
    ui_label = "Shutter Speed (1/x)";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 125;

#if PRESET_MODE

uniform int ISO_number <
    ui_items = "ISO100\0ISO200\0ISO400\0ISO800\0";
    ui_label = "ISO";
    ui_type = "combo";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 0;

uniform int Aperture <
    ui_items = "f/1.8\0f/2.0\0f/2.2\0f/2.5\0f/2.8\0f/3.2\0f/3.5\0f/4.0\0f/4.5\0f/5.0\0f/5.6\0f/6.3\0f/7.1\0f/8.0\0f/9.0\0f/10.0\0f/11.0\0f/13.0\0f/14.0\0f/16.0\0f/18.0\0f/20.0\0f/22.0\0";
    ui_label = "Aperture";
    ui_type = "combo";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 19;

// define ISO table
static const float preset_iso[4] = {
    100.0,
    200.0,
    400.0,
    800.0
};

// define aperture table
static const float f_aperture[23] = {
    1.8,
    2.0,
    2.2,
    2.5,
    2.8,
    3.2,
    3.5,
    4.0,
    4.5,
    5.0,
    5.6,
    6.3,
    7.1,
    8.0,
    9.0,
    10.0,
    11.0,
    13.0,
    14.0,
    16.0,
    18.0,
    20.0,
    22.0
};

// use a hacky ass way to get pre-set aperture
#define ApertureFNumber f_aperture[Aperture]

// use, again, a hackky ass way to use pre-set iso
#define ISO preset_iso[ISO_number]

#else

uniform float ISO <
    ui_type = "drag";
    ui_label = "ISO";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 100;

uniform float ApertureFNumber <
    ui_type = "drag";
    ui_step = 0.1;
    ui_label = "Aperture";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 16.0;   

#endif

uniform float ManualExposure <
    ui_type = "drag";
    ui_label = "Manual Exposure";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = -16.0;

uniform float middleGrey <
    ui_type = "drag";
    ui_step = 0.01;
    ui_label = "Middle Grey";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 0.18;

#define ShutterSpeedValue 1 / ShutterSpeedInSeconds
static const float FP16Scale = 0.0009765625f;
// uniform float ShutterSpeedValue = ShutterSpeedInSeconds.x / ShutterSpeedInSeconds.y;
// static const float KeyValue = 0.115;
 
float SaturationBasedExposure()
{
    float maxLuminance = (7800.0f / 65.0f) * (ApertureFNumber * ApertureFNumber) / (ISO * ShutterSpeedValue);
    return log2(1.0f / maxLuminance);
}

float StandardOutputBasedExposure()
{
    float lAvg = (1000.0f / 65.0f) * (ApertureFNumber * ApertureFNumber) / (ISO * ShutterSpeedValue);
    return log2(middleGrey / lAvg);
}

float Log2Exposure()
{
    float exposure = 0.0f;

    if(ExposureMode == 1)
    {
        exposure = SaturationBasedExposure();
        exposure -= log2(FP16Scale);
    }
    else if(ExposureMode == 2)
    {
        exposure = StandardOutputBasedExposure();
        exposure -= log2(FP16Scale);
    }
    else
    {
        exposure = ManualExposure;
        exposure -= log2(FP16Scale);
    }

    return exposure;
}

float LinearExposure()
{
    return exp2(Log2Exposure());
}

// Determines the color based on exposure settings
float3 CalcExposedColor(in float3 color, in float offset)
{
    float exposure = Log2Exposure();
    // exposure += offset;
    return exp2(exposure) * color;
}