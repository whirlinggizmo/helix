# helix-raylib's shader includes

[Back to the library](README.md)

A shader of the program's own is raylib's GLSL (`#version 330`, or `100` for the web), compiled ahead of time by `CompileShaderFile`. It may include these.

## `<helix/raylib/shaders/skinning.glsl>`

Skinning on the GPU, for a vertex stage.

It declares the bone inputs a skinned mesh feeds: vertexBoneIds and vertexBoneWeights, four bones a vertex, as raylib's.

It declares the uniforms each draw sets: bonePalette and boneOffset.

mat4 helixSkin() returns the vertex's skin matrix.

vec3 helixSkinNormal(vec3 normal) returns the normal moved by the bones, not normalized.

The stage declares raylib's attributes, its own uniforms and its outputs itself, as the example does.

A mesh posed by UpdateModelAnimation or UpdateModelAnimationBones is drawn in that pose. A model drawn several times in a frame shows each pose it was given. A mesh never posed, or without bones, is drawn in its bind pose.

```glsl
#version 330
#include <helix/raylib/shaders/skinning.glsl>
in vec3 vertexPosition;
in vec3 vertexNormal;
uniform mat4 mvp;
out vec3 fragNormal;
void main() {
    fragNormal = helixSkinNormal(vertexNormal);
    gl_Position = mvp*helixSkin()*vec4(vertexPosition, 1.0);
}
```

## `<helix/raylib/shaders/lights.glsl>`

raylib's lighting from its examples' rlights.h and lighting.fs, for a fragment stage.

It declares rlights' uniforms: lights[MAX_LIGHTS] (MAX_LIGHTS is 4), ambient and viewPos. CreateLight and UpdateLightValues set the lights. The program sets viewPos, the camera's position, each frame at shader.locs[SHADER_LOC_VECTOR_VIEW].

vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal) returns the fragment's lit color, gamma corrected. fragPosition is in world space. fragNormal needn't be normalized.

A point light doesn't dim with distance.

The stage declares its inputs, textures, uniforms and output itself, as the example does.

LoadLightingShader (helix.raylib.extras.Lights) is built on it. A fragment stage of the program's own lights with it like this:

```glsl
#version 330
#include <helix/raylib/shaders/lights.glsl>
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    finalColor = helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal);
}
```

## `<helix/raylib/shaders/pbr.glsl>`

A metallic-roughness surface lit by rlights' lights, for a fragment stage.

It includes <helix/raylib/shaders/lights.glsl>, so it declares the same uniforms, set the same way.

vec3 helixDecodeSrgb(vec3 color) converts sRGB to linear. vec3 helixEncodeSrgb(vec3 linear) converts back.

vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal) returns the fragment's lit color, encoded to sRGB. Its alpha is baseColor's.

Its inputs are linear, as a glTF's factors are. Decode a texel from an sRGB image first. fragPosition is in world space. normal needn't be normalized.

A point light doesn't dim with distance.

LoadPbrShader (helix.raylib.extras.Lights) is built on it. A fragment stage of the program's own lights with it like this:

```glsl
#version 330
#include <helix/raylib/shaders/pbr.glsl>
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    vec4 texel = texture(texture0, fragTexCoord);
    vec4 base = vec4(helixDecodeSrgb(texel.rgb), texel.a)*colDiffuse*fragColor;
    finalColor = helixPbr(base, 0.0, 0.5, 1.0, vec3(0.0), fragPosition, fragNormal);
}
```
