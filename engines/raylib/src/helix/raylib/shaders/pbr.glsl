// <helix/raylib/shaders/pbr.glsl>: a metallic-roughness surface lit by rlights' lights, for a fragment stage of helix-raylib's.
//
// It includes <helix/raylib/shaders/lights.glsl>, so it declares rlights' uniforms (lights[MAX_LIGHTS], ambient and viewPos, set as
// LoadLightingShader's are), and three functions more. vec3 helixDecodeSrgb(vec3 color) and vec3 helixEncodeSrgb(vec3 linear) go between
// sRGB and linear. vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition,
// vec3 normal) is the fragment's color: from each enabled light a Lambert diffuse and a GGX specular (Schlick's Fresnel, Smith's
// height-correlated visibility), a light's color what a white surface facing it shows and a point light undimmed by distance, as
// lights.glsl has them; a tenth of ambient as the light from everywhere, dimmed by occlusion; and emissive added. Every input is linear,
// baseColor and emissive as a glTF's factors are, so a texel from an sRGB image is decoded first. The result is encoded to sRGB, its
// alpha baseColor's. fragPosition is the fragment's in the world, and normal its own, normalized here.
//
// LoadPbrShader (helix.raylib.extras.Lights) is a shader built on it. A program's own fragment stage lights with it so:
//
//     #version 330
//     #include <helix/raylib/shaders/pbr.glsl>
//     in vec3 fragPosition;
//     in vec2 fragTexCoord;
//     in vec4 fragColor;
//     in vec3 fragNormal;
//     uniform sampler2D texture0;
//     uniform vec4 colDiffuse;
//     out vec4 finalColor;
//     void main() {
//         vec4 texel = texture(texture0, fragTexCoord);
//         vec4 base = vec4(helixDecodeSrgb(texel.rgb), texel.a)*colDiffuse*fragColor;
//         finalColor = helixPbr(base, 0.0, 0.5, 1.0, vec3(0.0), fragPosition, fragNormal);
//     }
#ifndef HELIX_RAYLIB_SHADERS_PBR_GLSL
#define HELIX_RAYLIB_SHADERS_PBR_GLSL
#include <helix/raylib/shaders/lights.glsl>

#define HELIX_PI 3.14159265358979

vec3 helixDecodeSrgb(vec3 color) {
    return mix(color/12.92, pow((color + 0.055)/1.055, vec3(2.4)), step(0.04045, color));
}

vec3 helixEncodeSrgb(vec3 linear) {
    return mix(linear*12.92, 1.055*pow(linear, vec3(1.0/2.4)) - 0.055, step(0.0031308, linear));
}

// Schlick's Fresnel: f0 at a straight look, white at a glancing one.
vec3 helixSchlick(vec3 f0, float cosine) {
    float f = pow(1.0 - cosine, 5.0);
    return f0*(1.0 - f) + f;
}

// The GGX specular lobe: its distribution, Smith's height-correlated visibility and Schlick's Fresnel, for a light's direction l, the
// eye's v and the normal n.
vec3 helixGgx(vec3 l, vec3 v, vec3 n, vec3 f0, float roughness) {
    float a = roughness*roughness, a2 = a*a;
    vec3 h = normalize(l + v);
    float nl = clamp(dot(n, l), 0.0, 1.0), nv = clamp(dot(n, v), 0.0, 1.0), nh = clamp(dot(n, h), 0.0, 1.0), vh = clamp(dot(v, h), 0.0, 1.0);
    float gv = nl*sqrt(a2 + (1.0 - a2)*nv*nv), gl = nv*sqrt(a2 + (1.0 - a2)*nl*nl);
    float visibility = 0.5/max(gv + gl, 1e-6);
    float d = nh*nh*(a2 - 1.0) + 1.0;
    float distribution = a2/(HELIX_PI*d*d);
    return helixSchlick(f0, vh)*(visibility*distribution);
}

vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal) {
    vec3 n = normalize(normal);
    vec3 v = normalize(viewPos - fragPosition);
    metallic = clamp(metallic, 0.0, 1.0);
    roughness = clamp(roughness, 0.03, 1.0);
    vec3 f0 = mix(vec3(0.04), baseColor.rgb, metallic);
    vec3 diffuseColor = baseColor.rgb*(1.0 - metallic);
    vec3 color = (ambient.rgb/10.0)*(diffuseColor + f0)*occlusion;
    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (lights[i].enabled == 1) {
            vec3 l = vec3(0.0);
            if (lights[i].type == LIGHT_DIRECTIONAL)
                l = -normalize(lights[i].target - lights[i].position);
            if (lights[i].type == LIGHT_POINT)
                l = normalize(lights[i].position - fragPosition);
            // A white surface facing the light shows its color: the BRDF scaled by pi.
            vec3 irradiance = lights[i].color.rgb*clamp(dot(n, l), 0.0, 1.0);
            color += irradiance*(diffuseColor + HELIX_PI*helixGgx(l, v, n, f0, roughness));
        }
    }
    color += emissive;
    return vec4(helixEncodeSrgb(clamp(color, 0.0, 1.0)), baseColor.a);
}

#endif
