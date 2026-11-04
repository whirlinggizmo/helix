// helix-render's batch vertex stage's names (Batch3D lists them): the attributes, the per-draw uniforms and the five outputs, and
// placeBatchVertex, which places a vertex as the batches' own stage does: a wide line's or a large point's corner pushed out across the
// screen.
#ifndef HELIX_RENDER_BATCH_GLSL
#define HELIX_RENDER_BATCH_GLSL
#include <helix/render/shaders/view.glsl>
#include <helix/render/shaders/clip.glsl>

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;
in vec4 vertexCustomData;
in vec2 vertexCorner;
in vec3 vertexLineEnd;

uniform mat4 model;
uniform mat4 normalMatrix;
uniform mat4 modelViewProjection;
uniform vec4 baseColor;
uniform int fontKind;
uniform float lineWidth;
uniform float pointSize;
uniform int pointSizeAttenuated;
uniform int fogged;
uniform int toneMapped;

out vec2 texCoord;
out vec4 color;
out vec4 customData;
out vec3 normal;
out vec3 worldPosition;

vec4 placeBatchVertex(vec3 position, vec3 lineEnd) {
	texCoord = vertexTexCoord;
	color = vertexColor;
	customData = vertexCustomData;
	normal = vertexNormal;
	worldPosition = position;
	vec4 clip = modelViewProjection * vec4(position, 1.0);
	if (vertexCorner.x == 0.0 && vertexCorner.y == 0.0)
		return clip;
	vec2 half_ = max(viewportSize.xy, vec2(1.0)) * 0.5;
	vec2 offset;
	if (lineEnd != position) {
		// A wide line: its corner across the screen from the segment, x along it (start -1, end 1), y across.
		vec4 other = modelViewProjection * vec4(lineEnd, 1.0);
		vec2 here = clip.xy / max(abs(clip.w), 1e-6) * half_;
		vec2 there = other.xy / max(abs(other.w), 1e-6) * half_;
		vec2 along = there - here;
		along = length(along) > 1e-6 ? normalize(along) : vec2(1.0, 0.0);
		if (vertexCorner.x > 0.0)
			along = -along;
		offset = vec2(-along.y, along.x) * vertexCorner.y * lineWidth * 0.5;
	} else {
		// A large point: a square of pointSize pixels, attenuated under a perspective projection.
		float size = pointSize;
		if (pointSizeAttenuated != 0 && projectionMatrix[2][3] != 0.0) {
			float depth = -(viewMatrix * vec4(position, 1.0)).z;
			size = pointSize * viewportSize.y * 0.5 / max(depth, 1e-6);
		}
		offset = vertexCorner * size * 0.5;
	}
	clip.xy += offset / half_ * clip.w;
	return clip;
}
#endif
