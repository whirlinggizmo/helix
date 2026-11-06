#version 330
// helix-raylib's PBR shader's fragment stage (LoadPbrShader), over <helix/raylib/shaders/pbr.glsl>: a material's maps and values as
// LoadModel reads a glTF's (albedo, metalness, roughness, normal, occlusion, emission), the values written by each draw. A map the
// material lacks reads white, the normal map a flat normal.
#include <helix/raylib/shaders/pbr.glsl>
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
in vec4 fragTangent;
uniform sampler2D albedoMap;
uniform sampler2D metalnessMap;
uniform sampler2D roughnessMap;
uniform sampler2D normalMap;
uniform sampler2D occlusionMap;
uniform sampler2D emissiveMap;
uniform vec4 colDiffuse;
uniform float metallicValue;
uniform float roughnessValue;
uniform vec4 emissiveColor;
out vec4 finalColor;
void main() {
    vec4 albedo = texture(albedoMap, fragTexCoord);
    vec4 base = vec4(helixDecodeSrgb(albedo.rgb), albedo.a)*colDiffuse*fragColor;
    float metallic = metallicValue*texture(metalnessMap, fragTexCoord).r;
    float roughness = roughnessValue*texture(roughnessMap, fragTexCoord).r;
    float occlusion = texture(occlusionMap, fragTexCoord).r;
    vec3 emissive = helixDecodeSrgb(texture(emissiveMap, fragTexCoord).rgb)*emissiveColor.rgb;
    vec3 n = normalize(fragNormal);
    vec3 t = normalize(fragTangent.xyz - dot(fragTangent.xyz, n)*n);
    vec3 b = cross(n, t)*fragTangent.w;
    vec3 m = texture(normalMap, fragTexCoord).rgb*2.0 - 1.0;
    n = normalize(t*m.x + b*m.y + n*m.z);
    finalColor = helixPbr(base, metallic, roughness, occlusion, emissive, fragPosition, n);
}
