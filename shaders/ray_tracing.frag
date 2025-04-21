#version 460 core

#include <flutter/runtime_effect.glsl>

const int SHAPE_STRIDE = 13;
const int MAX_SHAPES = 5;

uniform sampler2D uTexture;
uniform vec2 resolution;

struct Shape {
    vec2 position; // x, y coordinates of the center of the shape
    vec3 size; // width, height, elevation
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
    vec3(0.0, 0.0, 0.0),
    0.0,
    0.0,
    0.0
);

uniform float shapesInput[MAX_SHAPES * SHAPE_STRIDE];
Shape[MAX_SHAPES] shapes;

out vec4 fragColor;

const int MAX_STEPS = 60;
const float MAX_DIST = 10000.0;
const float EPSILON = 0.1;

// Light properties
const vec3 lightPos = vec3(1000, -1000, 1000);
const vec3 lightColor = vec3(1.0, 1.0, 1.0);
const float ambientStrength = 0.2;
const float specularStrength = 0.4;
const float shininess = 32.0;
const vec3 skyColor = vec3(0.9, 0.1, 1.0);
const vec3 backgroundColor = vec3(0.0, 0.0, 0.0);

// Function to construct a Shape struct from the flat array
void constructShapes() {
    for(int i = 0; i < MAX_SHAPES; i++) {
        Shape shape;

        shape.position = vec2(shapesInput[i * SHAPE_STRIDE], shapesInput[i * SHAPE_STRIDE + 1]);
        shape.size = vec3(shapesInput[i * SHAPE_STRIDE + 2], shapesInput[i * SHAPE_STRIDE + 3], shapesInput[i * SHAPE_STRIDE + 4]);
        shape.sideRadius = shapesInput[i * SHAPE_STRIDE + 5];
        shape.topRadius = shapesInput[i * SHAPE_STRIDE + 6];
        shape.sideColor = vec3(shapesInput[i * SHAPE_STRIDE + 7], shapesInput[i * SHAPE_STRIDE + 8], shapesInput[i * SHAPE_STRIDE + 9]);
        shape.metallic = shapesInput[i * SHAPE_STRIDE + 10];
        shape.roughness = shapesInput[i * SHAPE_STRIDE + 11]; 
        shape.reflectance = shapesInput[i * SHAPE_STRIDE + 12];

        shapes[i] = shape;
    }
}

vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

float plaIntersect( in vec3 ro, in vec3 rd, in vec4 p )
{
    return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

struct SdfResult {
    float dist;
    Shape shape;
};

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

// This function calculates the intersection of a ray with a rounded box
// Parameters:
// - rayOrigin: ray origin (vec3)
// - rayDirection: ray direction (vec3)
// - boxHalfSize: half-dimensions of the box before rounding (vec3)
// - sideRadius: radius of the rounded corners/edges
// Returns: distance to intersection or -1 if no intersection
float roundedboxIntersect(in vec3 rayOrigin, in vec3 rayDirection, in vec3 boxHalfSize, in float sideRadius, in float topRadius) {
    // Calculate values for a fast AABB intersection test (bounding box)
    // inverseDirection = inverse of ray direction, used for slab method ray-box intersection
    vec3 inverseDirection = 1.0/rayDirection;
    // scaledOrigin = ray origin multiplied by inverse direction
    vec3 scaledOrigin = inverseDirection * rayOrigin;
    // boundaryDistance = absolute distance from origin to box boundaries (including rounded part)
    vec3 boundaryDistance = abs(inverseDirection) * (boxHalfSize + vec3(sideRadius, sideRadius, topRadius));
    
    // nearIntersections and farIntersections are the near and far intersections for each dimension
    vec3 nearIntersections = -scaledOrigin - boundaryDistance;
    vec3 farIntersections = -scaledOrigin + boundaryDistance;
    
    // furthestNearDist = furthest near intersection (enter point)
    float furthestNearDist = max(max(nearIntersections.x, nearIntersections.y), nearIntersections.z);
    // closestFarDist = closest far intersection (exit point)
    float closestFarDist = min(min(farIntersections.x, farIntersections.y), farIntersections.z);
    
    // Early exit if ray misses the bounding box or box is behind ray
    if(furthestNearDist > closestFarDist || closestFarDist < 0.0) return -1.0;
    
    // intersectionDist is our initial intersection with the bounding box
    float intersectionDist = furthestNearDist;
    
    // Calculate the intersection point
    vec3 intersectionPoint = rayOrigin + intersectionDist * rayDirection;
    
    // Get the sign of each component to transform everything to first octant
    // (This simplifies the calculations by handling all symmetrical cases at once)
    vec3 componentSigns = sign(intersectionPoint);
    
    // Transform ray and position to first octant using component-wise multiplication
    rayOrigin *= componentSigns;
    rayDirection *= componentSigns;
    intersectionPoint *= componentSigns;
    float intersectionDistFormer = intersectionDist;
    
    // Adjust position relative to the box surface
    intersectionPoint -= boxHalfSize;
    
    if((intersectionPoint.x < 0 && intersectionPoint.y < sideRadius - topRadius)) {
        return intersectionDist;
    }

    if (intersectionPoint.y < 0 && intersectionPoint.x < sideRadius - topRadius) {
        return intersectionDist;
    }

    // Check if we're closer to an edge/corner or a face
    // This swaps dimensions to simplify logic (yzx swizzle)
    intersectionPoint = max(intersectionPoint.xyz, intersectionPoint.yzx);
    
    // If any dimension is negative, we hit a face directly (not an edge/corner)
    if(min(min(intersectionPoint.x, intersectionPoint.y), intersectionPoint.z) < 0.0) return intersectionDist;
    
    // Precompute values for the more complex rounded edge/corner intersections
    vec3 originToCorner = rayOrigin - boxHalfSize - vec3(sideRadius - topRadius, sideRadius - topRadius, 0.0);           // Vector from ray origin to box corner
    vec3 originToCornerZ = rayOrigin - boxHalfSize;
    vec3 cornerDistSquaredZ = originToCornerZ * originToCornerZ; // Squared distance from ray origin to box corner
    vec3 originCornerDotDirZ = originToCornerZ * rayDirection;  // Dot products between corner-to-origin and ray dir
    vec3 directionSquared = rayDirection * rayDirection;     // Squared ray direction components
    vec3 cornerDistSquared = originToCorner * originToCorner; // Squared corner-to-origin components
    vec3 originCornerDotDir = originToCorner * rayDirection;  // Dot products between corner-to-origin and ray dir
    float topRadiusSquared = topRadius * topRadius;        // Squared radius
    float sideRadiusSquared = sideRadius * sideRadius;  // Squared corner radius
    intersectionDist = 1e20;                                  // Reset intersectionDist to a very large value
    
    // // Check for intersection with rounded corner (sphere)
    // {
    //     float sphereB = originCornerDotDir.x + originCornerDotDir.y + originCornerDotDir.z;
    //     float sphereC = cornerDistSquared.x + cornerDistSquared.y + cornerDistSquared.z - radiusSquared;
    //     float discriminant = sphereB * sphereB - sphereC;
    //     if(discriminant > 0.0) intersectionDist = -sphereB - sqrt(discriminant);  // Quadratic formula solution
    // }

    // Check for intersection with rounded edge along Z axis (inner smaller but taller cylinder)
    {
        float t = (boxHalfSize.z - rayOrigin.z) / rayDirection.z;
        vec3 p = rayOrigin + t * rayDirection - boxHalfSize;
        float r = sideRadius - topRadius;
        if (p.x * p.x + p.y * p.y < r*r) {
            intersectionDist = intersectionDistFormer;
        }
    }
    
    // Check for intersection with rounded edge along X axis (cylinder)
    {
        float cylA = directionSquared.y + directionSquared.z;
        float cylB = originCornerDotDir.y + originCornerDotDir.z;
        float cylC = cornerDistSquared.y + cornerDistSquared.z - topRadiusSquared;
        float discriminant = cylB * cylB - cylA * cylC;
        if(discriminant > 0.0) {
            float solution = (-cylB - sqrt(discriminant)) / cylA;
            // Only accept if hit point is within box bounds and closer than any previous hit
            if(solution > 0.0 && solution < intersectionDist && 
               abs(rayOrigin.x + rayDirection.x * solution) < boxHalfSize.x) {
                intersectionDist = solution;
            }
        }
    }
    
    // Check for intersection with rounded edge along Y axis (cylinder)
    {
        float cylA = directionSquared.z + directionSquared.x;
        float cylB = originCornerDotDir.z + originCornerDotDir.x;
        float cylC = cornerDistSquared.z + cornerDistSquared.x - topRadiusSquared;
        float discriminant = cylB * cylB - cylA * cylC;
        if(discriminant > 0.0) {
            float solution = (-cylB - sqrt(discriminant)) / cylA;
            if(solution > 0.0 && solution < intersectionDist && 
               abs(rayOrigin.y + rayDirection.y * solution) < boxHalfSize.y) {
                intersectionDist = solution;
            }
        }
    }
    
    // Check for intersection with rounded edge along Z axis (outer larger but shorter cylinder)
    {
        float cylA = directionSquared.x + directionSquared.y;
        float cylB = originCornerDotDirZ.x + originCornerDotDirZ.y;
        float cylC = cornerDistSquaredZ.x + cornerDistSquaredZ.y - sideRadiusSquared;
        float discriminant = cylB * cylB - cylA * cylC;
        if(discriminant > 0.0) {
            float solution = (-cylB - sqrt(discriminant)) / cylA;
            if(solution > 0.0 && solution < intersectionDist && 
               abs(rayOrigin.z + rayDirection.z * solution) < boxHalfSize.z) {
                intersectionDist = solution;
            }
        }
    }


    // {
    //     float cylA = directionSquared.x + directionSquared.y;
    //     float cylB = originCornerDotDirZ.x + originCornerDotDirZ.y;
    //     float cylC = cornerDistSquaredZ.x + cornerDistSquaredZ.y - sideRadiusSquared;
    //     float discriminant = cylB * cylB - cylA * cylC;
    //     if(discriminant > 0.0) {
    //         float solution = (-cylB - sqrt(discriminant)) / cylA;
    //         if(solution > 0.0 && solution < intersectionDist && 
    //            abs(rayOrigin.z + rayDirection.z * solution) < boxHalfSize.z) {
    //             intersectionDist = solution;
    //         }
    //     }
    // }
    
    // If no valid intersection was found, return -1
    if(intersectionDist > 1e19) intersectionDist = -1.0;
    
    return intersectionDist;  // Return the intersection distance
}

// Ray marching function
SdfResult rayTrace(vec3 ro, vec3 rd) {    
    Shape resultShape = defaultShape;

    float dist = plaIntersect(ro, rd, vec4(0.0, 0.0, 1.0, 0.0));
    if(dist < 0)
        dist = MAX_DIST;

    for(int i = 0; i < MAX_SHAPES; i++) {
        Shape shape = shapes[i];
        if(shape.size.x < EPSILON) continue;
        float intersect = roundedboxIntersect(ro - vec3(shape.position, 0.0), rd, shape.size / 2.0 - vec3(shape.topRadius, shape.sideRadius, shape.topRadius), shape.sideRadius, shape.topRadius);
        if(intersect > 0.0 && intersect.x < dist) {
            dist = intersect.x;
            resultShape = shape;
        }
    }

    return SdfResult(dist, resultShape);    
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
    
    float textureSamplingEpsilon = 2.0;

    if (normal.z < EPSILON * 10 && shape.size.x > EPSILON) {
        p -= normal * textureSamplingEpsilon;
    }
    else
     if (shape.size.x > EPSILON) {
        vec2 shifted = p.xy - shape.position;
        vec2 difference = (abs(shifted) - shape.size.xy / 2.0);

        if (abs(difference.x) < textureSamplingEpsilon) {
            p.x -= textureSamplingEpsilon * sign(shifted.x);
        }
        if (abs(difference.y) < textureSamplingEpsilon) {
            p.y -= textureSamplingEpsilon * sign(shifted.y);
        }
    }

    vec2 textureUv = vec2(p.x, p.y) / resolution;

    vec3 color = backgroundColor;
    if (textureUv.x < EPSILON || textureUv.x > 1.0 - EPSILON || textureUv.y < EPSILON || textureUv.y > 1.0 - EPSILON)
        color = backgroundColor;
    else if (normal.z < EPSILON && shape.size.x > EPSILON)
        color = shape.sideColor;
    else
        color = texture(uTexture, textureUv).rgb;

    return (ambient + diffuse + specular) * color;
}

float[5] array;


void main() {
    vec2 uv = FlutterFragCoord().xy;
    constructShapes();
    
    // Camera setup
    vec3 ro = vec3(uv, 500);  // Ray origin (camera position)
    vec3 rd = normalize(vec3(0.1, 0.1, -1.0));  // Ray direction

    // Ray march
    SdfResult result = rayTrace(ro, rd);
    
    if(result.dist < MAX_DIST) {
        // Hit point
        vec3 p = ro + rd * result.dist;
        
        // Calculate normal and view direction
        vec3 normal = calcNormal(p, result.shape);  
        vec3 viewDir = normalize(ro - p);
        
        // Calculate lighting
        vec3 color = calcPhong(p, normal, viewDir, result.shape);
        color = vec3(p.z) / 100;
        
        fragColor = vec4(color, 1.0);
    } else {
        // Background color
        fragColor = vec4(skyColor, 1.0);
    }
}