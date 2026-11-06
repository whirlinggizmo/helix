// <helix/raylib/shaders/lights.glsl>: raylib's lighting, as its examples' rlights.h and lighting.fs (raylib 5.5) light a model, for a
// fragment stage of helix-raylib's.
//
// It declares rlights' uniforms: lights[MAX_LIGHTS] (MAX_LIGHTS is 4), each with enabled, type (LIGHT_DIRECTIONAL or LIGHT_POINT),
// position, target and color, which CreateLight and UpdateLightValues (helix.raylib.extras.Lights) set; ambient, a color; and viewPos,
// the camera's position, which a program sets each frame at shader.locs[SHADER_LOC_VECTOR_VIEW]. And one function,
// vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal), the fragment's color as lighting.fs computes it: each
// enabled light's diffuse and specular (a shine of 16), the ambient light a tenth of ambient, and the result gamma corrected (to the
// power 1/2.2). fragPosition is the fragment's in the world, and fragNormal its own, normalized here.
//
// LoadLightingShader (helix.raylib.extras.Lights) is a shader built on it. A program's own fragment stage lights with it so:
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
};

uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;

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
            lightDot += lights[i].color.rgb*NdotL;
            float specCo = 0.0;
            if (NdotL > 0.0)
                specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), 16.0);
            specular += specCo;
        }
    }
    vec4 color = (texelColor*((tint + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
    color += texelColor*(ambient/10.0)*tint;
    return pow(color, vec4(1.0/2.2));
}

#endif
