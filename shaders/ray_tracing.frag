#version 460 core

#include <flutter/runtime_effect.glsl>

const int SHAPE_STRIDE = 14;
const int MAX_SHAPES = 5;

uniform sampler2D uTexture;
uniform vec2 resolution;

struct Shape {
    vec2 position; // x, y coordinates of the center of the shape
    vec3 size; // width, height, elevation
    float elevation;
    float sideRadius;
    float topRadius;
    vec3 sideColor;
    float metallic;
    float roughness;
    float reflectance;
};

const Shape defaultShape = Shape(
    vec2(0.0, 0.0),
    vec3(0.0, 0.0, 0.0),
    0.0,
    0.0,
    0.0,
    vec3(0.0, 0.0, 0.0),
    0.0,
    0.0,
    0.0
);

uniform float shapesInput[MAX_SHAPES * SHAPE_STRIDE];
Shape[MAX_SHAPES] shapes;

out vec4 fragColor;

const int MAX_STEPS = 60;
const float MAX_DIST = 100.0;
const float EPSILON = 0.001;

// Light properties
const vec3 lightPos = vec3(2.0, 2.0, 3.0);
const vec3 lightColor = vec3(1.0, 1.0, 1.0);
const float ambientStrength = 0.2;
const float specularStrength = 0.4;
const float shininess = 32.0;
const vec3 skyColor = vec3(0.9, 0.1, 1.0);

// Function to construct a Shape struct from the flat array
void constructShapes() {
    float lesserResolution = min(resolution.x, resolution.y);

    for(int i = 0; i < MAX_SHAPES; i++) {
        Shape shape;

        shape.position = vec2(shapesInput[i * SHAPE_STRIDE], shapesInput[i * SHAPE_STRIDE + 1]) / resolution;
        shape.size = vec3(shapesInput[i * SHAPE_STRIDE + 2], shapesInput[i * SHAPE_STRIDE + 3], shapesInput[i * SHAPE_STRIDE + 4]) / vec3(resolution, lesserResolution);
        shape.sideRadius = shapesInput[i * SHAPE_STRIDE + 5] / lesserResolution;
        shape.topRadius = shapesInput[i * SHAPE_STRIDE + 6] / lesserResolution;
        shape.sideColor = vec3(shapesInput[i * SHAPE_STRIDE + 7], shapesInput[i * SHAPE_STRIDE + 8], shapesInput[i * SHAPE_STRIDE + 9]);

        shapes[i] = shape;
    }
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xy),p.z)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdShape(vec3 p, vec3 dimensions, float sideR, float topR) {
    vec3 adjustedDimensions = dimensions / 2 - vec3(sideR, sideR, 0) - vec3(0, 0, topR);
    vec3 pAfterElongation = p - vec3(clamp(p.x, -adjustedDimensions.x, adjustedDimensions.x), clamp(p.y, -adjustedDimensions.y, adjustedDimensions.y), 0);
    return sdCappedCylinder(pAfterElongation, adjustedDimensions.z, sideR - topR) - topR;
}

struct SdfResult {
    float dist;
    Shape shape;
};

// Scene SDF
SdfResult sceneSDF(vec3 p) {
    Shape resultShape = defaultShape;
    float dist = p.z;

    for(int i = 0; i < MAX_SHAPES; i++) {
        Shape shape = shapes[i];
        if(shape.size.x < EPSILON) continue;
        float shapeDist = sdShape(p - vec3(shape.position, 0), shape.size, shape.sideRadius, shape.topRadius);

        if(shapeDist < dist) {
            dist = shapeDist;
            resultShape = shape;
        }
    }

    return SdfResult(dist, resultShape);
}

float lengthSquared( vec3 x)
{
    return dot(x, x);
}

vec3 calcShapeNormal(vec3 p, vec3 dimensions, float sideR, float topR) {
    vec3 adjustedDimensions = dimensions / 2 - vec3(sideR, sideR, topR);
    
    vec3 offset = abs(p) - adjustedDimensions;

    if(offset.z + EPSILON > 0.0) {
        offset.x = offset.x > 0 ? max(offset.x - (sideR - topR), 0.0) : offset.x;
        offset.y = offset.y > 0 ? max(offset.y - (sideR - topR), 0.0) : offset.y;
    }

    vec3 offsetNonNegative = max(offset, 0.0);

    // If we're completely inside, find closest faces
    if(lengthSquared(offsetNonNegative) <= EPSILON) {
        vec3 closest = vec3(0.0, 0.0, 0.0);
        if(offset.z + EPSILON*2 >= offset.x && offset.z + EPSILON > offset.y) {
            closest.z = sign(p.z);
        } else if(offset.y + EPSILON >= offset.x) {
            closest.y = sign(p.y);
        } else {
            closest.x = sign(p.x);
        }
        return closest;
    }
    
    // Apply signs to the normalized offset
    vec3 normal;
    float len = length(offsetNonNegative);
    normal.x = (offsetNonNegative.x / len) * sign(p.x);
    normal.y = (offsetNonNegative.y / len) * sign(p.y);
    normal.z = (offsetNonNegative.z / len) * sign(p.z);
    return normal;
}

// Calculate normal using central differences
vec3 calcNormal(vec3 p, Shape shape) {
    if (shape.size.x < EPSILON) {
        return vec3(0.0, 0.0, 1.0);
    }

    return calcShapeNormal(p - vec3(shape.position, 0), shape.size, shape.sideRadius, shape.topRadius);
}

// Ray marching function
SdfResult rayMarch(vec3 ro, vec3 rd) {
    float dist = 0.0;
    
    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dist;
        SdfResult result = sceneSDF(p);
        
        if(result.dist < EPSILON) return SdfResult(dist, result.shape);
        if(dist > MAX_DIST) break;
        
        dist += result.dist;
    }
    
    return SdfResult(dist, defaultShape);
}

// Calculate Phong lighting
vec3 calcPhong(vec3 p, vec3 normal, vec3 viewDir, Shape shape) {
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
    
    vec3 color = abs(normal.z) < EPSILON && shape.size.x > EPSILON
        ? shape.sideColor
        // : vec3(p.x < 0.0 ? 0.5 : p.x, p.y < 0.0 ? 0.5 : p.y, 0.0);
        : texture(uTexture, vec2(clamp(p.x, 0.0 + EPSILON, 1.0 - EPSILON), clamp(p.y, 0.0 + EPSILON, 1.0 - EPSILON))).rgb;

    return (ambient + diffuse + specular) * color;
}

float[5] array;


void main() {
    vec2 uv = FlutterFragCoord().xy / resolution.xy;
    constructShapes();
    
    // Camera setup
    vec3 ro = vec3(uv + vec2(0.2, 0.2), 1);  // Ray origin (camera position)
    vec3 rd = normalize(vec3(-0.2, -0.2, -1.0));  // Ray direction

    // Ray march
    SdfResult result = rayMarch(ro, rd);
    
    if(result.dist < MAX_DIST) {
        // Hit point
        vec3 p = ro + rd * result.dist;
        
        // Calculate normal and view direction
        vec3 normal = calcNormal(p, result.shape);
        vec3 viewDir = normalize(ro - p);
        
        // Calculate lighting
        vec3 color = calcPhong(p, normal, viewDir, result.shape);
        
        fragColor = vec4(color, 1.0);
    } else {
        // Background color
        fragColor = vec4(skyColor, 1.0);
    }
}