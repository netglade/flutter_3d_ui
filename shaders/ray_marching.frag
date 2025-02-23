#version 460 core

#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 resolution;

out vec4 fragColor;

const int MAX_STEPS = 100;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001;

// Light properties
const vec3 lightPos = vec3(2.0, 2.0, -3.0);
const vec3 lightColor = vec3(1.0, 1.0, 1.0);
const float ambientStrength = 0.1;
const float specularStrength = 0.5;
const float shininess = 32.0;

// Material properties
const vec3 objectColor = vec3(0.7, 0.2, 0.2);

// Signed Distance Function for a sphere
float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}

// Scene SDF
float sceneSDF(vec3 p) {
    // Animate sphere position with time
    return sdSphere(p , 1.0);
}

// Calculate normal using central differences
vec3 calcNormal(vec3 p) {
    vec2 e = vec2(EPSILON, 0.0);
    return normalize(vec3(
        sceneSDF(p + e.xyy) - sceneSDF(p - e.xyy),
        sceneSDF(p + e.yxy) - sceneSDF(p - e.yxy),
        sceneSDF(p + e.yyx) - sceneSDF(p - e.yyx)
    ));
}

// Ray marching function
float rayMarch(vec3 ro, vec3 rd) {
    float dist = 0.0;
    
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dist;
        float step = sceneSDF(p);
        
        if(step < EPSILON) return dist;
        if(dist > MAX_DIST) break;
        
        dist += step;
    }
    
    return MAX_DIST;
}

// Calculate Phong lighting
vec3 calcPhong(vec3 p, vec3 normal, vec3 viewDir) {
    // Ambient
    vec3 ambient = ambientStrength * lightColor;
    
    // Diffuse
    vec3 lightDir = normalize(lightPos - p);
    float diff = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diff * lightColor;
    
    // Specular
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
    vec3 specular = specularStrength * spec * lightColor;
    
    return (ambient + diffuse + specular) * objectColor;
}


void main() {
    vec2 uv = FlutterFragCoord().xy / resolution.xy - 0.5;
    
    // Camera setup
    vec3 ro = vec3(0.0, 0.0, -3.0);  // Ray origin (camera position)
    vec3 rd = normalize(vec3(uv, 1.0));  // Ray direction

    // Ray march
    float dist = rayMarch(ro, rd);
    
    if(dist < MAX_DIST) {
        // Hit point
        vec3 p = ro + rd * dist;
        
        // Calculate normal and view direction
        vec3 normal = calcNormal(p);
        vec3 viewDir = normalize(ro - p);
        
        // Calculate lighting
        vec3 color = calcPhong(p, normal, viewDir);
        
        fragColor = vec4(color, 1.0);
    } else {
        // Background color
        fragColor = vec4(0.1, 0.1, 0.1, 1.0);
    }
}