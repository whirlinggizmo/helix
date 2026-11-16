// <helix/raylib/shaders/shadows.glsl>: the shadows of the scene's lights (the Lighting extra's SetLightShadowCasting and
// BeginShadowMode), for a fragment stage.
//
// It includes <helix/raylib/shaders/lights.glsl>, which includes it too, so helixLight and helixPbr receive the shadows as well.
//
// float helixShadow(int light, vec3 fragPosition, vec3 fragNormal) returns how much of light i of lights reaches the fragment: 0 in full
// shadow, 1 in full light, and 1 for a light that casts no shadows. fragPosition is in world space. fragNormal needn't be normalized.
//
// It declares shadowed, 1 when shadows fall on the material (SetMaterialShadowed, the Materials extra), written by each draw; with 0,
// helixShadow returns 1. Each light's lights[i].shadow is its shadows' index plus 1, 0 for none. The shadow maps and how each light's
// are read (helixShadowMap, the block HelixShadows) are written by each draw too.
//
// A fragment stage of the program's own lights with it like this:
//
//     #version 330
//     #include <helix/raylib/shaders/shadows.glsl>
//     in vec3 fragPosition;
//     in vec3 fragNormal;
//     out vec4 finalColor;
//     void main() {
//         float lit = helixShadow(0, fragPosition, fragNormal);
//         finalColor = vec4(vec3(0.2 + 0.8*lit), 1.0);
//     }
#include <helix/raylib/shaders/lights.glsl>
#ifndef HELIX_RAYLIB_SHADERS_SHADOWS_GLSL
#define HELIX_RAYLIB_SHADERS_SHADOWS_GLSL

uniform int shadowed;
uniform highp sampler2DArrayShadow helixShadowMap;

// Each shadow's maps and how they are read, by its index (lights[i].shadow less 1):
// - helixShadowParams: x its first map, plus 32 times its map count, plus 256 times its kind (0 a directional light's cascades, picked
//   by the fragment's depth from the camera; 1 a directional light over a fixed box; 2 a spot light; 3 a point light, a map a cube
//   face), plus 1024 times its softness in sixteenths of a texel; y its bias, z its slope bias and w its normal offset, in texels.
// - helixShadowStrengths: how much of the light its shadows take away.
// - helixShadowSplits: where a directional light's cascades end, in world units from the camera.
// Each map is a whole layer of helixShadowMap, all of one size.
// helixShadowView is the camera's forward direction, and w less its distance along it from the origin, so a fragment's depth from the
// camera is dot(xyz, fragPosition) + w.
uniform HelixShadows {
    mat4 helixShadowMatrices[24];
    vec4 helixShadowParams[4];
    vec4 helixShadowStrengths;
    vec4 helixShadowSplits[4];
    vec4 helixShadowView;
};

// A spot or point light's near plane, as a share of its reach.
const float HELIX_SHADOW_NEAR = 1.0/512.0;

// The shadow map's comparisons at a point (x and y across the layer, z its depth, 0 to 1), filtered over a radius in texels: one lookup at
// 0, a 3 x 3 grid to 1, then a disc of 16, each lookup itself the comparisons of its four nearest texels, blended.
float helixShadowFilter(vec3 at, float layer, float radius, float texel) {
    if (radius <= 0.0)
        return texture(helixShadowMap, vec4(at.xy, layer, at.z));
    float sum = 0.0;
    if (radius <= 1.0) {
        for (int y = -1; y <= 1; y++)
            for (int x = -1; x <= 1; x++)
                sum += texture(helixShadowMap, vec4(at.xy + vec2(float(x), float(y))*radius*texel, layer, at.z));
        return sum/9.0;
    }
    for (int i = 0; i < 16; i++) {
        float r = sqrt((float(i) + 0.5)/16.0)*radius;
        float a = float(i)*2.39996323;
        sum += texture(helixShadowMap, vec4(at.xy + vec2(cos(a), sin(a))*r*texel, layer, at.z));
    }
    return sum/16.0;
}

// The shadow's map picked for the fragment, the lookup moved off the surface along its normal and toward the light by the biases, each a
// number of the map's texels at the fragment, filtered, faded out over the map's last tenth, and taken from the light by its strength.
float helixShadow(int light, vec3 fragPosition, vec3 fragNormal) {
    if (shadowed == 0 || lights[light].shadow <= 0)
        return 1.0;
    int index = lights[light].shadow - 1;
    vec4 params = helixShadowParams[index];
    float width = float(textureSize(helixShadowMap, 0).x);
    float packed = params.x;
    int first = int(mod(packed, 32.0));
    int count = int(mod(floor(packed/32.0), 8.0));
    int kind = int(mod(floor(packed/256.0), 4.0));
    float radius = floor(packed/1024.0)/16.0;
    float depth = dot(helixShadowView.xyz, fragPosition) + helixShadowView.w;
    int k = 0;
    if (kind == 0) {
        k = count - 1;
        for (int i = 0; i < 3; i++)
            if (i < count - 1 && depth < helixShadowSplits[index][i]) {
                k = i;
                break;
            }
    } else if (kind == 3) {
        vec3 d = fragPosition - lights[light].position;
        vec3 a = abs(d);
        k = a.x >= a.y && a.x >= a.z ? (d.x >= 0.0 ? 0 : 1) : a.y >= a.z ? (d.y >= 0.0 ? 2 : 3) : (d.z >= 0.0 ? 4 : 5);
    }
    mat4 m = helixShadowMatrices[first + k];
    vec4 clip = m*vec4(fragPosition, 1.0);
    if (clip.w <= 0.0)
        return 1.0;
    vec3 ndc = clip.xyz/clip.w;
    float fade;
    if (kind == 0)
        fade = depth/helixShadowSplits[index][count - 1];
    else if (kind == 1)
        fade = max(abs(ndc.x), abs(ndc.y));
    else {
        float reach = 2.0*HELIX_SHADOW_NEAR/(1.0 + HELIX_SHADOW_NEAR - ndc.z*(1.0 - HELIX_SHADOW_NEAR));
        fade = kind == 2 ? max(reach, max(abs(ndc.x), abs(ndc.y))) : reach;
    }
    fade = smoothstep(0.9, 1.0, fade);
    if (fade >= 1.0)
        return 1.0;
    vec3 normal = normalize(fragNormal);
    vec3 toLight = helixLightDirection(light, fragPosition);
    // A texel's width in the world at the fragment: 2 over the map's width in texels, over how fast x across the map grows there.
    float texel = 2.0*clip.w/(width*length(vec3(m[0][0], m[1][0], m[2][0])));
    float cosine = clamp(dot(normal, toLight), -1.0, 1.0);
    float sine = sqrt(max(1.0 - cosine*cosine, 0.0));
    float slope = min(sine/max(abs(cosine), 1e-3), 3.0);
    vec3 moved = fragPosition + normal*(params.w*texel*(1.0 + sine)) + toLight*(texel*(params.y + params.z*slope));
    vec4 c = m*vec4(moved, 1.0);
    vec3 at = c.xyz/c.w*0.5 + 0.5;
    if (at.z >= 1.0)
        return 1.0;
    float lit = helixShadowFilter(at, float(first + k), radius, 1.0/width);
    return 1.0 - helixShadowStrengths[index]*(1.0 - lit)*(1.0 - fade);
}

#endif
