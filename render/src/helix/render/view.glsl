// helix-render's View block, both stages: one view's matrices, the rectangle it fills, what the target holds, the renderer's exposure and
// tone mapping, and the fog (View3D lists the names). Written once a view and shared with every draw in it.
#ifndef HELIX_RENDER_VIEW_GLSL
#define HELIX_RENDER_VIEW_GLSL
precision highp float;
precision highp int;

layout(std140) uniform View {
	mat4 viewMatrix;
	mat4 projectionMatrix;
	mat4 viewProjection;
	vec4 cameraPosition;
	vec4 viewportSize;
	vec4 fogColor;
	vec4 fogParams;
	int linearTarget;
	float exposure;
	int toneMapping;
};
#endif
