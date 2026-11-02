#version 330
// GL's form: loose uniforms, the camera from an include, the bones under SKINNED.
#include "camera.glsl"
in vec3 position;
in vec3 normal;
in vec4 color;
#ifdef SKINNED
in vec4 joints;
in vec4 weights;
uniform mat4 boneMatrices[4];
#endif
uniform mat4 model;
out vec3 vNormal;
out vec4 vColor;
void main() {
    vec4 p = vec4(position, 1.0);
#ifdef SKINNED
    p = boneMatrices[int(joints.x)] * p * weights.x;
#endif
    vNormal = normal;
    vColor = color;
    gl_Position = viewProjection * model * p;
}
