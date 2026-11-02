#version 300 es
// The batches' own fragment stage: the texel times the vertex color as stored, a distance-field atlas's edge made sharp, written as it is
// into an sRGB target unless fog or tone mapping reaches it, decoded into a linear one.
precision highp float;
#include <helix/render/color.glsl>

in vec2 texCoord;
in vec4 color;
in vec3 worldPosition;
uniform sampler2D baseColorTexture;
uniform int fontKind;
uniform int fogged;
out vec4 fragColor;

void main() {
	vec4 texel = texture(baseColorTexture, texCoord);
	if (fontKind == 2) {
		float edge = max(fwidth(texel.a), 1e-4) * 0.75;
		texel = vec4(1.0, 1.0, 1.0, smoothstep(0.5 - edge, 0.5 + edge, texel.a));
	}
	vec4 c = texel * color;
	bool fogs = fogged != 0 && fogParams.x > 0.5;
	if (linearTarget != 0) {
		vec3 light = decodeSrgb(c.rgb);
		fragColor = vec4(fogs ? applyFog(light, worldPosition) : light, c.a);
		return;
	}
	if (fogs || toneMapped != 0) {
		vec3 light = decodeSrgb(c.rgb);
		if (fogs)
			light = applyFog(light, worldPosition);
		if (toneMapped != 0)
			light = applyToneMapping(light);
		c.rgb = encodeSrgb(clamp(light, 0.0, 1.0));
	}
	fragColor = c;
}
