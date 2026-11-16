#version 330
// raylib's default fragment stage with a material's values (the Materials extra's): its alpha cutoff, and the light the material and
// its model give off, added. helix-raylib's default shader draws through it a material that is cut out or gives off light, and raylib's
// own fragment stage (unlit.fs) every other.
in vec2 fragTexCoord;
in vec4 fragColor;
out vec4 finalColor;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform vec3 emissiveColor;
uniform vec3 modelEmissiveColor;
uniform float alphaCutoff;
void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    if (texelColor.a*colDiffuse.a < alphaCutoff)
        discard;
    finalColor = texelColor*colDiffuse*fragColor;
    finalColor.rgb += emissiveColor + modelEmissiveColor;
}
