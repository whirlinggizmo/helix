// <helix/raylib/shaders/vertex.glsl>: the vertex stage of helix-raylib's lit shaders, raylib's examples' lighting.vs (raylib 5.5), for
// lit.vs and lit_skinned.vs, and under pbr_vertex.glsl.
//
// It declares raylib's attributes, matrices and the outputs lit.fs reads (fragPosition, fragTexCoord, fragColor and fragNormal), and
// void helixVertex(vec4 position, vec3 normal), which writes them and gl_Position from a vertex's position and normal in the mesh's own
// space: as the mesh has them, or moved by its bones.
#ifndef HELIX_RAYLIB_SHADERS_VERTEX_GLSL
#define HELIX_RAYLIB_SHADERS_VERTEX_GLSL

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;
uniform mat4 mvp;
uniform mat4 matModel;
uniform mat4 matNormal;
out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;

void helixVertex(vec4 position, vec3 normal) {
    fragPosition = vec3(matModel*position);
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragNormal = normalize(vec3(matNormal*vec4(normal, 1.0)));
    gl_Position = mvp*position;
}

#endif
