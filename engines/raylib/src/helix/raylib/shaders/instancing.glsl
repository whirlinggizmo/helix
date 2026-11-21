// <helix/raylib/shaders/instancing.glsl>: an instance's transform, for the vertex stages of helix-raylib's shaders drawn instanced
// (DrawMeshInstanced through LoadLightingShader's and LoadPbrShader's).
//
// It declares instanceTransform, the instance's transform, as raylib's instancing example names it.
//
// vec4 helixInstance(vec4 position) returns a position moved by it.
//
// vec3 helixInstanceNormal(vec3 normal) returns a normal moved by it, not normalized.
#ifndef HELIX_RAYLIB_SHADERS_INSTANCING_GLSL
#define HELIX_RAYLIB_SHADERS_INSTANCING_GLSL

in mat4 instanceTransform;

vec4 helixInstance(vec4 position) {
    return instanceTransform*position;
}

vec3 helixInstanceNormal(vec3 normal) {
    return transpose(inverse(mat3(instanceTransform)))*normal;
}

#endif
