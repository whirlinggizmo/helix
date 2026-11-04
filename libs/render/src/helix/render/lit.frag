#version 300 es
// The lit materials, every shading: the surface read, shaded by the draw's lights and the ambient light as its shading says, its emissive
// light added, then fogged, exposed, tone mapped and encoded as writeMaterialColor says.
precision highp float;
#include <helix/render/material.glsl>

out vec4 fragColor;

void main() {
	Surface surface = readMaterialSurface(texCoord);
	fragColor = writeMaterialColor(surface, shadeMaterial(surface));
}
