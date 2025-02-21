#version 460 core

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 resolution;

out vec4 fragColor;

void main() {
    vec2 st = FlutterFragCoord().xy / resolution.xy;
    vec4 color = texture(uTexture, st);
    // Make the color slightly lighter by adding a small value
    fragColor = vec4(color.rgb + 0.5, color.a);
}