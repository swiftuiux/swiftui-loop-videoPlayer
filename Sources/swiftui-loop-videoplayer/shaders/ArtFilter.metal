//
//  ArtFilter.metal
//  swiftui-loop-videoplayer-example
//
//  Created by Igor Shelopaev on 21.08.25.
//


#include <metal_stdlib>
#include <CoreImage/CoreImage.h>
using namespace metal;

extern "C" { namespace coreimage {

float4 artEffect(sampler src, float t, destination dest) {
    float2 d  = dest.coord();
    float2 uv = samplerTransform(src, d);
    float2 sz = samplerSize(src);

    const float a      = 0.01;
    const float lambda = 48.0;
    const float k      = 6.28318530718 / lambda;
    const float w      = 1.0;

    float yOff = a * sin(d.x * k - w * t);
    float2 uv2 = float2(uv.x, clamp(uv.y + yOff, 0.0, sz.y - 1.0));

    return src.sample(uv2);
}

} }
