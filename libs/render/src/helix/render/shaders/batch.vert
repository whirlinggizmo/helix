#version 300 es
// The batches' own vertex stage: every batch draw, 2D and 3D, placed by placeBatchVertex.
#include <helix/render/shaders/batch.glsl>

void main() {
	gl_Position = placeBatchVertex(vertexPosition, vertexLineEnd);
}
