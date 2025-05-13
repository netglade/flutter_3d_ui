#version 310 es

#include <flutter/runtime_effect.glsl>

const int SHAPE_STRIDE = 13;
const int MAX_SHAPES = 5;

uniform sampler2D uTexture;
uniform vec2 resolution;

// Light and camera uniforms
uniform vec3 lightColor;
uniform float lightIntensity;
uniform vec3 skyColor;
uniform vec3 backgroundColor;
uniform vec3 lightDirection;
uniform float cameraHeight;
uniform vec3 rayDirectionParameter;
uniform float indirectLightCoefficient;
uniform float backgroundRoughness;
uniform float backgroundMetallic;
uniform float backgroundReflectance;

// Shape uniforms - 5 shapes with 13 properties each
// Shape 1
uniform vec2 shape1Position;
uniform vec3 shape1Size;
uniform float shape1SideRadius;
uniform float shape1TopRadius;
uniform vec3 shape1SideColor;
uniform float shape1Metallic;
uniform float shape1Roughness;
uniform float shape1Reflectance;

// Shape 2
uniform vec2 shape2Position;
uniform vec3 shape2Size;
uniform float shape2SideRadius;
uniform float shape2TopRadius;
uniform vec3 shape2SideColor;
uniform float shape2Metallic;
uniform float shape2Roughness;
uniform float shape2Reflectance;

// Shape 3
uniform vec2 shape3Position;
uniform vec3 shape3Size;
uniform float shape3SideRadius;
uniform float shape3TopRadius;
uniform vec3 shape3SideColor;
uniform float shape3Metallic;
uniform float shape3Roughness;
uniform float shape3Reflectance;

// Shape 4
uniform vec2 shape4Position;
uniform vec3 shape4Size;
uniform float shape4SideRadius;
uniform float shape4TopRadius;
uniform vec3 shape4SideColor;
uniform float shape4Metallic;
uniform float shape4Roughness;
uniform float shape4Reflectance;

// Shape 5
uniform vec2 shape5Position;
uniform vec3 shape5Size;
uniform float shape5SideRadius;
uniform float shape5TopRadius;
uniform vec3 shape5SideColor;
uniform float shape5Metallic;
uniform float shape5Roughness;
uniform float shape5Reflectance;

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

Shape[MAX_SHAPES] shapes;

out vec4 fragColor;

const int MAX_STEPS = 60;
const float MAX_DIST = 10000.0;
const float EPSILON = 0.1;
const float textureSamplingEpsilon = 2.0;

// Light properties
const float ambientStrength = 0.2;
const float specularStrength = 0.4;
const float shininess = 32.0;

// Color space conversion functions
vec3 linearToSRGB(vec3 color) {
    return pow(color, vec3(1.0/2.2));
}

vec3 sRGBToLinear(vec3 color) {
    return pow(color, vec3(2.2));
}

/**
 * Calculates the intersection of a ray with a torus
 * 
 * @param rayOrigin Origin point of the ray
 * @param rayDirection Direction vector of the ray
 * @param torusRadii Vector where x = major radius (distance from center to tube center),
 *                  y = minor radius (radius of the tube itself)
 * 
 * @return Distance to intersection point, or -1 if no intersection exists
 */
float torusIntersection(in vec3 rayOrigin, in vec3 rayDirection, in vec2 torusRadii)
{
    // Flag indicating which form of the polynomial solution to use
    float polynomialForm = 1.0;
    
    // Square of the torus radii for more efficient calculations
    float majorRadiusSquared = torusRadii.x * torusRadii.x;
    float minorRadiusSquared = torusRadii.y * torusRadii.y;
    
    // Precompute dot products needed for the quartic equation
    float rayOriginDotProduct = dot(rayOrigin, rayOrigin);
    float rayOriginDirectionDotProduct = dot(rayOrigin, rayDirection);
    
    // Compute coefficients for the quartic equation
    float constTerm = (rayOriginDotProduct + majorRadiusSquared - minorRadiusSquared) / 2.0;
    float cubicCoeff = rayOriginDirectionDotProduct;
    float quadraticCoeff = rayOriginDirectionDotProduct * rayOriginDirectionDotProduct - 
                          majorRadiusSquared * dot(rayDirection.xy, rayDirection.xy) + constTerm;
    float linearCoeff = rayOriginDirectionDotProduct * constTerm - 
                        majorRadiusSquared * dot(rayDirection.xy, rayOrigin.xy);
    float quarticCoeff = constTerm * constTerm - 
                         majorRadiusSquared * dot(rayOrigin.xy, rayOrigin.xy);
    
    // Check if we need to switch to inverse form of the polynomial for numerical stability
    if (abs(cubicCoeff * (cubicCoeff * cubicCoeff - quadraticCoeff) + linearCoeff) < 0.01)
    {
        polynomialForm = -1.0;
        
        // Swap coefficients for inverse polynomial form
        float tmp = linearCoeff; linearCoeff = cubicCoeff; cubicCoeff = tmp;
        
        // Invert and normalize all coefficients
        quarticCoeff = 1.0 / quarticCoeff;
        linearCoeff = linearCoeff * quarticCoeff;
        quadraticCoeff = quadraticCoeff * quarticCoeff;
        cubicCoeff = cubicCoeff * quarticCoeff;
    }
    
    // Ferrari's method for solving quartic equation by reducing to cubic
    // Compute coefficients for the resolvent cubic equation
    float derivedQuadCoeff = quadraticCoeff * 2.0 - 3.0 * cubicCoeff * cubicCoeff;
    float derivedLinearCoeff = cubicCoeff * (cubicCoeff * cubicCoeff - quadraticCoeff) + linearCoeff;
    float derivedConstCoeff = cubicCoeff * (cubicCoeff * (derivedQuadCoeff + 2.0 * quadraticCoeff) - 
                              8.0 * linearCoeff) + 4.0 * quarticCoeff;
    
    // Normalize coefficients
    derivedQuadCoeff /= 3.0;
    derivedLinearCoeff *= 2.0;
    derivedConstCoeff /= 3.0;
    
    // Compute discriminants for the cubic formula
    float discriminantQ = derivedQuadCoeff * derivedQuadCoeff + derivedConstCoeff;
    float discriminantR = derivedQuadCoeff * derivedQuadCoeff * derivedQuadCoeff - 
                         3.0 * derivedQuadCoeff * derivedConstCoeff + 
                         derivedLinearCoeff * derivedLinearCoeff;
    float discriminantH = discriminantR * discriminantR - discriminantQ * discriminantQ * discriminantQ;
    
    // Case 1: Cubic has one real root and two complex conjugate roots
    if (discriminantH >= 0.0)  
    {
        discriminantH = sqrt(discriminantH);
        
        // Calculate cube roots for the real root
        float cubeRootRPlusH = sign(discriminantR + discriminantH) * 
                              pow(abs(discriminantR + discriminantH), 1.0/3.0);
        float cubeRootRMinusH = sign(discriminantR - discriminantH) * 
                               pow(abs(discriminantR - discriminantH), 1.0/3.0);
        
        // Compute the real root of the cubic
        vec2 solutionVector = vec2((cubeRootRPlusH + cubeRootRMinusH) + 4.0 * derivedQuadCoeff, 
                                  (cubeRootRPlusH - cubeRootRMinusH) * sqrt(3.0));
        float solutionY = sqrt(0.5 * (length(solutionVector) + solutionVector.x));
        float solutionX = 0.5 * solutionVector.y / solutionY;
        
        // Use the real root to find roots of the quartic
        float correctionTerm = 2.0 * derivedLinearCoeff / (solutionX * solutionX + solutionY * solutionY);
        
        // Calculate possible intersection distances
        float intersectionDist1 = solutionX - correctionTerm - cubicCoeff;
        intersectionDist1 = (polynomialForm < 0.0) ? 2.0 / intersectionDist1 : intersectionDist1;
        
        float intersectionDist2 = -solutionX - correctionTerm - cubicCoeff;
        intersectionDist2 = (polynomialForm < 0.0) ? 2.0 / intersectionDist2 : intersectionDist2;
        
        // Find the closest positive intersection
        float closestIntersection = 1e20; // Initialize to a large value
        if (intersectionDist1 > 0.0) closestIntersection = intersectionDist1;
        if (intersectionDist2 > 0.0) closestIntersection = min(closestIntersection, intersectionDist2);
        
        return closestIntersection;
    }
    
    // Case 2: Cubic has three real roots
    float sqrtDiscriminantQ = sqrt(discriminantQ);
    
    // Use trigonometric solution for the cubic equation
    float trigSolution = sqrtDiscriminantQ * 
                        cos(acos(-discriminantR / (sqrtDiscriminantQ * discriminantQ)) / 3.0);
    
    // Compute variables needed for the quartic roots
    float discriminantD2 = -(trigSolution + derivedQuadCoeff);
    
    // If discriminant is negative, no real roots exist (no intersection)
    if (discriminantD2 < 0.0) return -1.0;
    
    float sqrtDiscriminantD2 = sqrt(discriminantD2);
    
    // Calculate radicals for the quartic formula
    float solutionRadicalH1 = sqrt(trigSolution - 2.0 * derivedQuadCoeff + 
                                  derivedLinearCoeff / sqrtDiscriminantD2);
    float solutionRadicalH2 = sqrt(trigSolution - 2.0 * derivedQuadCoeff - 
                                  derivedLinearCoeff / sqrtDiscriminantD2);
    
    // Calculate all four possible intersection distances
    float intersectionDist1 = -sqrtDiscriminantD2 - solutionRadicalH1 - cubicCoeff;
    intersectionDist1 = (polynomialForm < 0.0) ? 2.0 / intersectionDist1 : intersectionDist1;
    
    float intersectionDist2 = -sqrtDiscriminantD2 + solutionRadicalH1 - cubicCoeff;
    intersectionDist2 = (polynomialForm < 0.0) ? 2.0 / intersectionDist2 : intersectionDist2;
    
    float intersectionDist3 = sqrtDiscriminantD2 - solutionRadicalH2 - cubicCoeff;
    intersectionDist3 = (polynomialForm < 0.0) ? 2.0 / intersectionDist3 : intersectionDist3;
    
    float intersectionDist4 = sqrtDiscriminantD2 + solutionRadicalH2 - cubicCoeff;
    intersectionDist4 = (polynomialForm < 0.0) ? 2.0 / intersectionDist4 : intersectionDist4;
    
    // Find the closest positive intersection
    float closestIntersection = 1e20; // Initialize to a large value
    if (intersectionDist1 > 0.0) closestIntersection = intersectionDist1;
    if (intersectionDist2 > 0.0) closestIntersection = min(closestIntersection, intersectionDist2);
    if (intersectionDist3 > 0.0) closestIntersection = min(closestIntersection, intersectionDist3);
    if (intersectionDist4 > 0.0) closestIntersection = min(closestIntersection, intersectionDist4);
    
    return closestIntersection;
}

// Function to construct a Shape struct from the individual uniforms
void constructShapes() {
    // Shape 1
    shapes[0] = Shape(
        shape1Position,
        shape1Size,
        shape1SideRadius,
        shape1TopRadius,
        sRGBToLinear(shape1SideColor),
        shape1Metallic,
        shape1Roughness,
        shape1Reflectance
    );

    // Shape 2
    shapes[1] = Shape(
        shape2Position,
        shape2Size,
        shape2SideRadius,
        shape2TopRadius,
        sRGBToLinear(shape2SideColor),
        shape2Metallic,
        shape2Roughness,
        shape2Reflectance
    );

    // Shape 3
    shapes[2] = Shape(
        shape3Position,
        shape3Size,
        shape3SideRadius,
        shape3TopRadius,
        sRGBToLinear(shape3SideColor),
        shape3Metallic,
        shape3Roughness,
        shape3Reflectance
    );

    // Shape 4
    shapes[3] = Shape(
        shape4Position,
        shape4Size,
        shape4SideRadius,
        shape4TopRadius,
        sRGBToLinear(shape4SideColor),
        shape4Metallic,
        shape4Roughness,
        shape4Reflectance
    );

    // Shape 5
    shapes[4] = Shape(
        shape5Position,
        shape5Size,
        shape5SideRadius,
        shape5TopRadius,
        sRGBToLinear(shape5SideColor),
        shape5Metallic,
        shape5Roughness,
        shape5Reflectance
    );
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
    vec3 adjustedDimensions = dimensions / 2.0 - vec3(sideR, sideR, topR);
    
    vec3 offset = abs(p) - adjustedDimensions;

    if(offset.z + EPSILON > 0.0) {
        vec3 offsetFlat = max(vec3(offset.x, offset.y, 0.0), 0.0);
        if (lengthSquared(offsetFlat) > (sideR - topR) * (sideR - topR)) {
            offsetFlat = (sideR-topR) * normalize(offsetFlat);
        }
        offset = offset - offsetFlat;

        // offset.x = max(offset.x - (sideR - topR), 0.0);
        // offset.y = max(offset.y - (sideR - topR), 0.0);
    }

    vec3 offsetNonNegative = max(offset, 0.0);

    // If we're completely inside, find closest faces
    if(lengthSquared(offsetNonNegative) <= EPSILON) {
        vec3 closest = vec3(0.0, 0.0, 0.0);
        if(offset.z + EPSILON*2.0 >= offset.x && offset.z + EPSILON > offset.y) {
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

vec3 calcShapeShiftNormal(vec3 p, vec3 dimensions, float sideR, float topR) {
    vec3 adjustedDimensions = dimensions / 2.0 - vec3(sideR, sideR, 0.0)
        - vec3(textureSamplingEpsilon, textureSamplingEpsilon, 0.0);
    
    vec3 offset = abs(p) - adjustedDimensions;
    vec3 offsetNonNegative = max(offset, 0.0);
    if (offsetNonNegative.x*offsetNonNegative.x + offsetNonNegative.y*offsetNonNegative.y > sideR*sideR) {
        vec3 normal;
        offsetNonNegative.z = 0.0;
        float len = length(offsetNonNegative);
        normal.x = (offsetNonNegative.x / len) * sign(p.x);
        normal.y = (offsetNonNegative.y / len) * sign(p.y);
        normal.z = 0.0;
        return normal;
    } else {
        return vec3(0.0, 0.0, 1.0);
    }


    // // If we're completely inside, find closest faces
    // if(lengthSquared(offsetNonNegative) <= EPSILON) {
    //     vec3 closest = vec3(0.0, 0.0, 0.0);
    //     if(offset.z + EPSILON*2 >= offset.x && offset.z + EPSILON > offset.y) {
    //         closest.z = sign(p.z);
    //     } else if(offset.y + EPSILON >= offset.x) {
    //         closest.y = sign(p.y);
    //     } else {
    //         closest.x = sign(p.x);
    //     }
    //     return closest;
    // }
    
    // // Apply signs to the normalized offset
    // vec3 normal;
    // float len = length(offsetNonNegative);
    // normal.x = (offsetNonNegative.x / len) * sign(p.x);
    // normal.y = (offsetNonNegative.y / len) * sign(p.y);
    // normal.z = (offsetNonNegative.z / len) * sign(p.z);
    // return normal;
}


vec3 calcShiftNormal(vec3 p, Shape shape) {
    if (shape.size.x < EPSILON) {
        return vec3(0.0, 0.0, 1.0);
    }

    return calcShapeShiftNormal(p - vec3(shape.position, 0), shape.size, shape.sideRadius, shape.topRadius);
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
    
    if((intersectionPoint.x < 0.0 && intersectionPoint.y < sideRadius - topRadius)) {
        return intersectionDist;
    }

    if (intersectionPoint.y < 0.0 && intersectionPoint.x < sideRadius - topRadius) {
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

    // check for torus intersection
    {
        float solution = torusIntersection(originToCornerZ, rayDirection, vec2(sideRadius - topRadius, topRadius));
        if(solution > 0.0 && solution < intersectionDist) {
            intersectionDist = solution;
        }
    }
    
    // If no valid intersection was found, return -1
    if(intersectionDist > 1e19) intersectionDist = -1.0;
    
    return intersectionDist;  // Return the intersection distance
}

// Ray marching function
SdfResult rayTrace(vec3 ro, vec3 rd) {    
    Shape resultShape = defaultShape;

    float dist = plaIntersect(ro, rd, vec4(0.0, 0.0, 1.0, 0.0));
    if(dist < 0.0)
        dist = MAX_DIST;

    for(int i = 0; i < MAX_SHAPES; i++) {
        Shape shape = shapes[i];
        if(shape.size.x < EPSILON) continue;
        float intersect = roundedboxIntersect(ro - vec3(shape.position, 0.0), rd, shape.size / 2.0 - vec3(shape.sideRadius, shape.sideRadius, shape.topRadius), shape.sideRadius, shape.topRadius);
        if(intersect > 0.0 && intersect < dist) {
            dist = intersect;
            resultShape = shape;
        }
    }

    return SdfResult(dist, resultShape);    
}

const float PI = 3.14159265359;

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

vec3 tonemap(vec3 color) {
    // Reinhard tonemapping
    return color / (color + vec3(1.0));
}

// Calculate PBR lighting
vec3 calcPBR(vec3 p, vec3 normal, vec3 shiftNormal, vec3 viewDir, vec3 normalizedLightDir, Shape shape) {
    vec3 N = normal;
    vec3 V = viewDir;
    vec3 L = -normalizedLightDir;
    vec3 H = normalize(V + L);

    float textureSamplingEpsilonAdjusted = textureSamplingEpsilon * 1.2;

    if (shape.size.x > EPSILON && shiftNormal.z < EPSILON) {
        p.x -= textureSamplingEpsilonAdjusted * shiftNormal.x;
        p.y -= textureSamplingEpsilonAdjusted * shiftNormal.y;
    }

    vec2 textureUv = vec2(p.x, p.y) / resolution;

    vec3 albedo = sRGBToLinear(backgroundColor);
    if (textureUv.x < EPSILON || textureUv.x > 1.0 - EPSILON || textureUv.y < EPSILON || textureUv.y > 1.0 - EPSILON)
        albedo = sRGBToLinear(backgroundColor);
    else if (normal.z < EPSILON && shape.size.x > EPSILON)
        albedo = shape.sideColor;
    else
        albedo = sRGBToLinear(texture(uTexture, vec2(textureUv.x, 1.0 - textureUv.y)).rgb);

    // Calculate base F0 using reflectance
    vec3 F0 = vec3(0.16 * shape.reflectance * shape.reflectance);
    F0 = mix(F0, albedo, shape.metallic);

    // Calculate actual roughness (roughness squared)
    float actualRoughness = shape.roughness * shape.roughness;

    // Cook-Torrance BRDF
    float NDF = DistributionGGX(N, H, actualRoughness);
    float G = GeometrySmith(N, V, L, actualRoughness);
    vec3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);

    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= 1.0 - shape.metallic;

    vec3 numerator = NDF * G * F;
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
    vec3 specular = numerator / denominator;

    float NdotL = max(dot(N, L), 0.0);
    vec3 radiance = sRGBToLinear(lightColor) * lightIntensity;

    // Calculate shadows
    float shadow = 1.0;
    vec3 shadowRayOrigin = p + N * EPSILON; // Offset from surface to prevent self-shadowing
    SdfResult shadowResult = rayTrace(shadowRayOrigin, L);
    if (shadowResult.dist < MAX_DIST) {
        shadow = 0.0; // Point is in shadow
    }

    vec3 Lo = (kD * albedo / PI + specular) * radiance * NdotL * shadow;
    vec3 ambient = vec3(indirectLightCoefficient) * albedo;

    return ambient + Lo;
}

// Function to trace a reflection ray and return the color
vec3 traceReflectionRay(vec3 rayOrigin, vec3 rayDirection, vec3 normal) {
    // Offset the ray origin slightly to prevent self-intersection
    vec3 rayDirectionToNormal = normal * dot(rayDirection, normal);

    vec3 offsetOrigin = rayOrigin + rayDirection * EPSILON - (rayDirection - rayDirectionToNormal) * EPSILON * 2.0;
    
    // Trace the reflection ray
    SdfResult reflectionResult = rayTrace(offsetOrigin, rayDirection);
    
    if(reflectionResult.dist < MAX_DIST) {
        // Hit point
        vec3 p = offsetOrigin + rayDirection * reflectionResult.dist;
        
        // Calculate normal and view direction for the reflection
        vec3 normal = calcNormal(p, reflectionResult.shape);
        vec3 shiftNormal = calcShiftNormal(p, reflectionResult.shape);
        vec3 viewDir = normalize(offsetOrigin - p);
        
        // Create background shape if needed
        Shape finalShape = reflectionResult.shape;
        if (reflectionResult.shape.size.x <= EPSILON) {
            finalShape = Shape(
                vec2(0.0, 0.0),
                vec3(0.0, 0.0, 0.0),
                0.0,
                0.0,
                sRGBToLinear(backgroundColor),
                backgroundMetallic,
                backgroundRoughness,
                backgroundReflectance
            );
        }
        
        // Calculate lighting for the reflection
        return calcPBR(p, normal, shiftNormal, viewDir, -normalize(lightDirection), finalShape);
    }
    
    // If no intersection, return sky color
    return sRGBToLinear(skyColor);
}

// Function to calculate reflection contribution
vec3 calculateReflection(vec3 p, vec3 normal, vec3 viewDir, vec3 F0, float roughness) {
    vec3 reflectionDir = reflect(-viewDir, normal);
    vec3 reflectionColor = traceReflectionRay(p, reflectionDir, normal);
    
    // Calculate Fresnel factor for view direction
    vec3 viewFresnel = fresnelSchlick(max(dot(normal, viewDir), 0.0), F0);
    
    // Calculate reflection contribution
    // Attenuate by roughness for rough surfaces
    // todo: * viewFresnel
    return reflectionColor * (1.0 - roughness) * viewFresnel;
}

void main() {
    vec2 uv = FlutterFragCoord().xy;
    constructShapes();
    
    // Convert color uniforms to linear space
    vec3 linearLightColor = sRGBToLinear(lightColor);
    vec3 linearSkyColor = sRGBToLinear(skyColor);
    vec3 linearBackgroundColor = sRGBToLinear(backgroundColor);
    
    // Normalize light direction once
    vec3 normalizedLightDir = normalize(lightDirection);
    
    // Camera setup
    vec3 ro = vec3(uv, cameraHeight);  // Ray origin (camera position)
    vec3 rd = normalize(rayDirectionParameter);  // Ray direction

    // Ray march
    SdfResult result = rayTrace(ro, rd);
    
    if(result.dist < MAX_DIST) {
        // Hit point
        vec3 p = ro + rd * result.dist;
        
        // Calculate normal and view direction
        vec3 normal = calcNormal(p, result.shape);  
        vec3 shiftNormal = calcShiftNormal(p, result.shape);
        vec3 viewDir = normalize(ro - p);
        
        // Create background shape if needed
        Shape finalShape = result.shape;
        if (result.shape.size.x <= EPSILON) {
            finalShape = Shape(
                vec2(0.0, 0.0),
                vec3(0.0, 0.0, 0.0),
                0.0,
                0.0,
                linearBackgroundColor,
                backgroundMetallic,
                backgroundRoughness,
                backgroundReflectance
            );
        }
        
        // Calculate base lighting using PBR
        vec3 color = calcPBR(p, normal, shiftNormal, viewDir, normalizedLightDir, finalShape);
        
        // Calculate base F0 for reflection
        vec3 albedo = finalShape.size.x <= EPSILON ? linearBackgroundColor : 
                     (normal.z < EPSILON ? finalShape.sideColor : 
                     sRGBToLinear(texture(uTexture, vec2(p.x / resolution.x, 1.0 - p.y / resolution.y)).rgb));
        vec3 F0 = vec3(0.16 * finalShape.reflectance * finalShape.reflectance);
        F0 = mix(F0, albedo, finalShape.metallic);
        
        // Add reflection contribution
        color += calculateReflection(p, normal, viewDir, F0, finalShape.roughness);
        
        // Apply tonemapping
        // color = tonemap(color);
        
        fragColor = vec4(linearToSRGB(color), 1.0);
    } else {
        // Background color
        fragColor = vec4(linearToSRGB(linearSkyColor), 1.0);
    }
}