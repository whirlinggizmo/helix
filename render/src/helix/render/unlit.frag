#version 300 es
// The Unlit material: its base color, texture and vertex color multiplied as its colorSpace says, its alpha by alphaTexture's green, cut
// by alphaCutoff, then exposed, tone mapped and encoded as writeColor says.
precision highp float;
#include <helix/render/color.glsl>

in vec3 worldPosition;
in vec2 texCoord;
in vec4 color;
uniform vec4 baseColor;
uniform sampler2D baseColorTexture;
uniform sampler2D alphaTexture;
uniform int colorSpaceSrgb;
uniform float alphaCutoff;
// Whether the base color texture is decoded from sRGB (its Texture2D.colorSpace, Auto as a color slot).
uniform int baseColorTextureSrgb;
out vec4 fragColor;

void main() {
	vec4 texel = texture(baseColorTexture, texCoord);
	vec4 c;
	if (colorSpaceSrgb != 0) {
		c = baseColor * texel * color;
		c.rgb = decodeSrgb(c.rgb);
	} else
		c = decodeSrgb(baseColor) * (baseColorTextureSrgb != 0 ? decodeSrgb(texel) : texel) * color;
	c.a *= texture(alphaTexture, texCoord).g;
	if (c.a < alphaCutoff)
		discard;
	fragColor = writeColor(c);
}
