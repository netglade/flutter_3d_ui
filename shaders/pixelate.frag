#version 460 core

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 resolution;

out vec4 fragColor;

void main() {
    vec3 normal = normalize(vec3(0.4, 0.8, 1.0));

    vec2 st = FlutterFragCoord().xy / resolution.xy - 0.5;
    vec2 stAdjusted = st / normal.xy + 0.5;

    vec4 color = texture(uTexture, stAdjusted);
    fragColor = color;

    // vec2 st = FlutterFragCoord().xy;

    // // Calculate texel coordinates
    // vec2 texCoord = st - 0.5;

    // // Get the four nearest texel coordinates
    // vec2 i_texCoord = floor(texCoord);
    // vec2 f_texCoord = fract(texCoord);

    // // Sample the four nearest texels
    // vec4 tl = texture(uTexture, (i_texCoord + vec2(0.0, 0.0)) / resolution.xy);
    // vec4 tr = texture(uTexture, (i_texCoord + vec2(1.0, 0.0)) / resolution.xy);
    // vec4 bl = texture(uTexture, (i_texCoord + vec2(0.0, 1.0)) / resolution.xy);
    // vec4 br = texture(uTexture, (i_texCoord + vec2(1.0, 1.0)) / resolution.xy);

    // // Interpolate between the samples
    // vec4 top = mix(tl, tr, f_texCoord.x);
    // vec4 bottom = mix(bl, br, f_texCoord.x);
    // fragColor = mix(top, bottom, f_texCoord.y);

    // const float PIXEL_SIZE = 1.0;

    // vec2 fragCoord = FlutterFragCoord().xy;
    // vec2 blocks = floor(fragCoord / PIXEL_SIZE);
    // vec2 pixelated_st = (blocks * PIXEL_SIZE + (PIXEL_SIZE / 2.0)) / resolution.xy;
    // vec2 original_st = fragCoord / resolution.xy;

    // vec4 pixelatedColor = texture(uTexture, pixelated_st);
    // vec4 color = texture(uTexture, original_st);

    // fragColor = color.a == 0.0 && pixelatedColor.a == 0 ? color : pixelatedColor;
}