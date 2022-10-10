/*

simple.HDR | user interface file
________________________________________________________________________________

*/

// Include only once
#pragma once

/* Includes */

// Import ReShade UI library
#include "ReShadeUI.fxh"

/* UI */

uniform float ACESMix
<
    ui_label = "ACES mix";
    ui_tooltip = "simple.HDR | aces mix\n"
                 "This determines the mix between the ACES result and the original color.\n"
                 "\n"
                 "At  1.0, the output will be the ACES tonemap.\n"
                 "At  0.0, the output will be the original colors.\n"
                 "At -1.0, the output will be the inverse ACES tonemap.\n";
    ui_type = "slider";
    ui_min = -1.0f;
    ui_max = 1.0f;
    ui_step = 0.1f;
> = 1.0f;

uniform int PreprocHelp
<
    ui_text = "\nsimple.HDR | preprocessor definitions guide\n"
              "\n"
              "SIMPLE_HDR_SRGB: \n"
              "\tControls wether simple.HDR converts the sRGB backbuffer to \n"
              "\tlinear sRGB.\n"
              "\n"
              "\tThis is automatically set to 0 when using 10-bit backbuffer\n"
              "\tand vice-versa.\n"
              "\n"
              "] OPEN \"Preprocessor definitions\" BELOW\n"
              "\n"
              "_______________________________________________________________";
    ui_label = " ";
    ui_type = "radio";
>;