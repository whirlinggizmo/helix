#version 300 es
// Batch3D's own fragment stage for its batch draws with toneMapped on: the texel times the vertex color as stored, decoded, exposed, tone
// mapped and encoded into an sRGB target; decoded and written linear into a linear one; a distance-field font's edge made sharp.
precision highp float;
#include <helix/render/shaders/color.glsl>

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
	vec3 light = decodeSrgb(c.rgb);
	fragColor = vec4(linearTarget != 0 ? light : encodeSrgb(clamp(applyToneMapping(light), 0.0, 1.0)), c.a);
}
