#version 300 es
// Batch3D's own fragment stage for its batch draws: the texel times the vertex color as stored, written as it is into an sRGB target
// and decoded into a linear one; a distance-field font's edge made sharp.
precision highp float;
#include <helix/render/shaders/view.glsl>

in vec2 texCoord;
in vec4 color;
uniform sampler2D baseColorTexture;
uniform int fontKind;
out vec4 fragColor;

void main() {
	vec4 t = texture(baseColorTexture, texCoord);
	// A distance-field font's texels: its outline at 0.5, made a sharp edge a pixel wide at any size.
	if (fontKind == 2) {
		float w = max(fwidth(t.a), 1.0 / 255.0) * 0.5;
		t.a = smoothstep(0.5 - w, 0.5 + w, t.a);
	}
	vec4 c = t * color;
	if (linearTarget != 0) {
		vec3 s = max(c.rgb, vec3(0.0));
		c.rgb = mix(s / 12.92, pow((s + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), s));
	}
	fragColor = c;
}
