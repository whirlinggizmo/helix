#version 330
// The PBR shader's fragment stage for an unlit material (glTF's KHR_materials_unlit): its base color as authored, the albedo decoded from
// sRGB, times colDiffuse and the vertex color, encoded back, and no light. LoadPbrShader draws a material marked unlit through it.
#include <helix/raylib/shaders/pbr.glsl>
in vec2 fragTexCoord;
in vec4 fragColor;
uniform sampler2D albedoMap;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    vec4 albedo = texture(albedoMap, fragTexCoord);
    vec4 base = vec4(helixDecodeSrgb(albedo.rgb), albedo.a)*colDiffuse*fragColor;
    finalColor = vec4(helixEncodeSrgb(base.rgb), base.a);
}
