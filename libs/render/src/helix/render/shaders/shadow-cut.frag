#version 300 es
// A cut-out caster's fragment stage: where its alpha is below alphaCutoff it isn't drawn into the map, as its color draw cuts it.
precision highp float;

in vec2 texCoord;
in vec4 color;

uniform vec4 baseColor;
uniform float alphaCutoff;
uniform sampler2D baseColorTexture;
uniform sampler2D alphaTexture;

void main() {
	if (baseColor.a * texture(baseColorTexture, texCoord).a * color.a * texture(alphaTexture, texCoord).g < alphaCutoff)
		discard;
}
