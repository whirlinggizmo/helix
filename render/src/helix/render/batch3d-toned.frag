#version 300 es
// Batch3D's own fragment stage for its batch draws with toneMapped on: the texel times the vertex color as stored, decoded, exposed, tone
// mapped and encoded into an sRGB target; decoded and written linear into a linear one.
precision highp float;
#include <helix/render/color.glsl>

in vec2 texCoord;
in vec4 color;
uniform sampler2D baseColorTexture;
out vec4 fragColor;

void main() {
	vec4 c = texture(baseColorTexture, texCoord) * color;
	vec3 light = decodeSrgb(c.rgb);
	fragColor = vec4(linearTarget != 0 ? light : encodeSrgb(clamp(applyToneMapping(light), 0.0, 1.0)), c.a);
}
