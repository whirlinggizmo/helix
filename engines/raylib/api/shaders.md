# helix-raylib's shader includes

[Back to the library](README.md)

A shader of the program's own is raylib's GLSL (`#version 330`, or `100` for the web), compiled ahead of time by `CompileShaderFile`. It may include these.

## `<helix/raylib/shaders/skinning.glsl>`

Skinning on the GPU, for a vertex stage of helix-raylib's.

It declares the bone inputs a skinned mesh feeds, vertexBoneIds and vertexBoneWeights (four bones a vertex, as raylib's), the frame's bone palette (uniform sampler2D bonePalette) and the draw's first bone in it plus one (uniform int boneOffset, 0 for a draw without bones), and two functions: mat4 helixSkin() returns the vertex's skin matrix, each of its bones' matrices times its weight, added; vec3 helixSkinNormal(vec3 normal) returns a normal moved as raylib moves one, by each bone's matrix inverted and transposed, times its weight, added, and not normalized.

It declares nothing else: the stage declares raylib's attributes, its uniforms and its outputs itself, as the example does.

A shader including it skins on the GPU: a mesh UpdateModelAnimation or UpdateModelAnimationBones posed is drawn with its bones written into the palette and boneOffset set, so one model drawn in many poses in a frame draws each as it was asked for. A mesh drawn before either posed it, or without bones, is drawn in its bind pose, as are the vertices with no weight at all.

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

raylib's lighting, as its examples' rlights.h and lighting.fs (raylib 5.5) light a model, for a fragment stage of helix-raylib's.

It declares rlights' uniforms: lights[MAX_LIGHTS] (MAX_LIGHTS is 4), each with enabled, type (LIGHT_DIRECTIONAL or LIGHT_POINT), position, target and color, which CreateLight and UpdateLightValues (helix.raylib.extras.Lights) set; ambient, a color; and viewPos, the camera's position, which a program sets each frame at shader.locs[SHADER_LOC_VECTOR_VIEW]. And one function, vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal), the fragment's color as lighting.fs computes it: each enabled light's diffuse and specular (a shine of 16), the ambient light a tenth of ambient, and the result gamma corrected (to the power 1/2.2). fragPosition is the fragment's in the world, and fragNormal its own, normalized here.

It declares nothing else: the stage declares its inputs (raylib's varyings fragPosition, fragTexCoord, fragColor and fragNormal, as its vertex stage names them), its textures and uniforms, and its output itself, as the example does.

LoadLightingShader (helix.raylib.extras.Lights) is a shader built on it. A program's own fragment stage lights with it so:

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

A metallic-roughness surface lit by rlights' lights, for a fragment stage of helix-raylib's.

It includes <helix/raylib/shaders/lights.glsl>, so it declares rlights' uniforms (lights[MAX_LIGHTS], ambient and viewPos, set as LoadLightingShader's are), and three functions more. vec3 helixDecodeSrgb(vec3 color) and vec3 helixEncodeSrgb(vec3 linear) go between sRGB and linear. vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal) is the fragment's color: from each enabled light a Lambert diffuse and a GGX specular (Schlick's Fresnel, Smith's height-correlated visibility), a light's color what a white surface facing it shows and a point light undimmed by distance, as lights.glsl has them; a tenth of ambient as the light from everywhere, dimmed by occlusion; and emissive added. Every input is linear, baseColor and emissive as a glTF's factors are, so a texel from an sRGB image is decoded first. The result is encoded to sRGB, its alpha baseColor's. fragPosition is the fragment's in the world, and normal its own, normalized here.

LoadPbrShader (helix.raylib.extras.Lights) is a shader built on it. A program's own fragment stage lights with it so:

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
