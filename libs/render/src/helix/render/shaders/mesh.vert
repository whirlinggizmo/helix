#version 300 es
// The materials' own vertex stage: every mesh, skinned and instanced, placed by placeVertex.
#include <helix/render/shaders/mesh.glsl>

void main() {
	gl_Position = placeVertex();
}
