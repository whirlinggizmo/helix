// <helix/raylib/shaders/lights.glsl>: raylib's lighting from its examples' rlights.h and lighting.fs, lit by the scene's lights, for a
// fragment stage.
//
// It declares rlights' uniforms: lights[MAX_LIGHTS] (MAX_LIGHTS is 8), ambient and viewPos. Each draw's lights are the scene's lights
// reaching it most (CreateLight), written before the draw, the rest off. The program sets viewPos, the camera's position, each frame at
// shader.locs[SHADER_LOC_VECTOR_VIEW].
//
// Each light also has helix-raylib's range, intensity and a spot light's cone (SetLightRange, SetLightIntensity and SetLightCone, the
// Lighting extra's): lights[i].range, lights[i].intensity, and lights[i].innerCosine and lights[i].outerCosine, the cosines of the cone's
// angles. lights[i].shadow is its shadows' index plus 1, 0 for a light that casts none (SetLightShadowCasting).
//
// It includes <helix/raylib/shaders/shadows.glsl>, so a light casting shadows (SetLightShadowCasting, BeginShadowMode) is shadowed in
// helixLight, and helixShadow is there for the program's own lighting.
//
// It also declares the material's values (the Materials extra's), written by each draw: emissiveColor, the light the material gives
// off, its color times its intensity; modelEmissiveColor, the light its model gives off (SetModelEmissive), 0 for a mesh drawn alone;
// and alphaCutoff, 0 for none.
//
// vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal) returns the fragment's lit color, gamma corrected,
// each light's shadow taken from it, the material's and the model's light added. A fragment whose alpha, texelColor's times tint's, is
// below alphaCutoff is discarded. fragPosition is in world space. fragNormal needn't be normalized.
//
// A point or spot light with a range dims with the square of the distance, to nothing at its range. Without one, it doesn't dim. A spot
// light shines from its position toward its target, full inside its inner angle and fading to nothing at its outer one.
//
// float helixLightStrength(int i, vec3 fragPosition) returns light i's strength at the fragment: its intensity, dimmed by its range and
// a spot light's cone. vec3 helixLightDirection(int i, vec3 fragPosition) returns the direction toward light i from the fragment.
//
// The stage declares its inputs, textures, uniforms and output itself, as the example does.
//
// LoadLightingShader (helix.raylib.extras.Lighting) is built on it. A fragment stage of the program's own lights with it like this:
//
//     #version 330
//     #include <helix/raylib/shaders/lights.glsl>
//     in vec3 fragPosition;
//     in vec2 fragTexCoord;
//     in vec4 fragColor;
//     in vec3 fragNormal;
//     uniform sampler2D texture0;
//     uniform vec4 colDiffuse;
//     out vec4 finalColor;
//     void main() {
//         finalColor = helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal);
//     }
#ifndef HELIX_RAYLIB_SHADERS_LIGHTS_GLSL
#define HELIX_RAYLIB_SHADERS_LIGHTS_GLSL

#define MAX_LIGHTS 8
#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT 1
#define LIGHT_SPOT 2

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
    float range;
    float intensity;
    float innerCosine;
    float outerCosine;
    int shadow;
};

uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;
uniform vec3 emissiveColor;
uniform vec3 modelEmissiveColor;
uniform float alphaCutoff;

// A light's strength at a fragment: its intensity; for a point or spot light with a range, inverse-square falloff faded to nothing at
// the range, as glTF's KHR_lights_punctual has it; and a spot light's cone, smooth between its angles. Exactly its intensity for a
// point light of range 0.
float helixLightStrength(int i, vec3 fragPosition) {
    float strength = lights[i].intensity;
    if (lights[i].type != LIGHT_DIRECTIONAL && lights[i].range > 0.0) {
        float d = length(lights[i].position - fragPosition);
        float w = clamp(1.0 - pow(d/lights[i].range, 4.0), 0.0, 1.0);
        strength *= w*w/max(d*d, 0.0001);
    }
    if (lights[i].type == LIGHT_SPOT) {
        float c = dot(normalize(fragPosition - lights[i].position), normalize(lights[i].target - lights[i].position));
        float inner = lights[i].innerCosine, outer = lights[i].outerCosine;
        strength *= inner - outer > 1e-6 ? smoothstep(outer, inner, c) : step(outer, c);
    }
    return strength;
}

// The direction toward a light from a fragment: a directional light's from its target toward its position.
vec3 helixLightDirection(int i, vec3 fragPosition) {
    if (lights[i].type == LIGHT_DIRECTIONAL)
        return -normalize(lights[i].target - lights[i].position);
    return normalize(lights[i].position - fragPosition);
}

#include <helix/raylib/shaders/shadows.glsl>

vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal) {
    if (texelColor.a*tint.a < alphaCutoff)
        discard;
    vec3 lightDot = vec3(0.0);
    vec3 normal = normalize(fragNormal);
    vec3 viewD = normalize(viewPos - fragPosition);
    vec3 specular = vec3(0.0);
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (lights[i].enabled == 1) {
            vec3 light = helixLightDirection(i, fragPosition);
            float NdotL = max(dot(normal, light), 0.0);
            float strength = helixLightStrength(i, fragPosition)*helixShadow(i, fragPosition, normal);
            lightDot += lights[i].color.rgb*NdotL*strength;
            float specCo = 0.0;
            if (NdotL > 0.0)
                specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), 16.0);
            specular += specCo*strength;
        }
    }
    vec4 color = (texelColor*((tint + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
    color += texelColor*(ambient/10.0)*tint;
    color.rgb += emissiveColor + modelEmissiveColor;
    return pow(color, vec4(1.0/2.2));
}

#endif
