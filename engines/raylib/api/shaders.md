# helix-raylib's shader includes

[Back to the library](README.md)

A shader of the program's own is raylib's GLSL (`#version 330`, or `100`), compiled ahead of time by `CompileShaderFile`. It may include these.

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
