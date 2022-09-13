#pragma once

texture TextureColor : COLOR;
sampler SamplerColor { Texture = TextureColor; };

float3 RemoveCurve( float3 x )
{
    return x < 0.04045 ? x / 12.92 : -7.43605 * x - 31.24297 * sqrt(-0.53792 * x + 1.279924) + 35.34864;
}

float3 ApplyCurve( float3 x )
{
    return x < 0.0031308 ? 12.92 * x : 1.13005 * sqrt(x - 0.00228) - 0.13448 * x + 0.005719;
}

void VS(in uint id : SV_VERTEXID, out float4 position : SV_POSITION, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

void PS(in float4 vpos : SV_POSITION, in float2 texcoord : TEXCOORD0, out float4 o : SV_TARGET0)
{
    o = tex2D(SamplerColor, texcoord.xy);
}
