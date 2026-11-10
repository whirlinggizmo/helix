// <helix/raylib/shaders/lights.glsl>: raylib's lighting from its examples' rlights.h and lighting.fs, for a fragment stage.
//
// It declares rlights' uniforms: lights[MAX_LIGHTS] (MAX_LIGHTS is 4), ambient and viewPos. CreateLight and UpdateLightValues set the
// lights. The program sets viewPos, the camera's position, each frame at shader.locs[SHADER_LOC_VECTOR_VIEW].
//
// Each light also has helix-raylib's range and intensity, from Light's fields. Its intensity starts at 1.
//
// vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal) returns the fragment's lit color, gamma corrected.
// fragPosition is in world space. fragNormal needn't be normalized.
//
// A point light with a range dims with the square of the distance, to nothing at its range. Without one, it doesn't dim.
//
// float helixLightStrength(int i, vec3 fragPosition) returns light i's strength at the fragment: its intensity, dimmed by its range.
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

#define MAX_LIGHTS 4
#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT 1

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
    float range;
    float intensity;
};

uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;

// A light's strength at a fragment: its intensity, and for a point light with a range, inverse-square falloff faded to nothing at the
// range, as glTF's KHR_lights_punctual has it. Exactly its intensity for a range of 0.
float helixLightStrength(int i, vec3 fragPosition) {
    float strength = lights[i].intensity;
    if (lights[i].type == LIGHT_POINT && lights[i].range > 0.0) {
        float d = length(lights[i].position - fragPosition);
        float w = clamp(1.0 - pow(d/lights[i].range, 4.0), 0.0, 1.0);
        strength *= w*w/max(d*d, 0.0001);
    }
    return strength;
}

vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal) {
    vec3 lightDot = vec3(0.0);
    vec3 normal = normalize(fragNormal);
    vec3 viewD = normalize(viewPos - fragPosition);
    vec3 specular = vec3(0.0);
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (lights[i].enabled == 1) {
            vec3 light = vec3(0.0);
            if (lights[i].type == LIGHT_DIRECTIONAL)
                light = -normalize(lights[i].target - lights[i].position);
            if (lights[i].type == LIGHT_POINT)
                light = normalize(lights[i].position - fragPosition);
            float NdotL = max(dot(normal, light), 0.0);
            float strength = helixLightStrength(i, fragPosition);
            lightDot += lights[i].color.rgb*NdotL*strength;
            float specCo = 0.0;
            if (NdotL > 0.0)
                specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), 16.0);
            specular += specCo*strength;
        }
    }
    vec4 color = (texelColor*((tint + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
    color += texelColor*(ambient/10.0)*tint;
    return pow(color, vec4(1.0/2.2));
}

#endif
