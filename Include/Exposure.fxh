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

uniform int ExposureMode <
    ui_items = "Manual (Simple)\0Manual (SBS)\0Manual (SOS)\0";
    ui_label = "Exposure Mode";
    ui_type = "combo";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 0;

uniform float2 ShutterSpeedInSeconds <
    ui_type = "drag";
    ui_step = 1.0;
    ui_label = "Shutter Speed";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = float2(1, 125);

uniform float ISO <
    ui_type = "drag";
    ui_label = "ISO";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 100;

// uniform int Aperture <
//     ui_items = "f/1.8\0f/2.0\0f/2.2\0f/2.5\0f/2.8\0f/3.2\0f/3.5\0f/4.0\0f/4.5\0f/5.0\0f/5.6\0f/6.3\0f/7.1\0f/8.0\0f/9.0\0f/10.0\0f/11.0\0f/13.0\0f/14.0\0f/16.0\0f/18.0\0f/20.0\0f/22.0\0";
//     ui_label = "Aperture";
//     ui_type = "combo";
// > = 19;

uniform float ApertureFNumber <
    ui_type = "drag";
    ui_step = 0.1;
    ui_label = "Aperture F-Number";
    ui_category = "Physically-Based Exposure";
    ui_category_closed = true;
> = 16.0;   

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

#define ShutterSpeedValue ShutterSpeedInSeconds.x / ShutterSpeedInSeconds.y
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