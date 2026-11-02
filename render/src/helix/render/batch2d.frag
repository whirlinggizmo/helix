#version 300 es
// Batch2D's own fragment stage: the texel times the vertex color as stored, decoded from sRGB into a linear target.
precision highp float;
precision highp int;

in vec2 texCoord;
in vec4 color;
uniform sampler2D baseColorTexture;
uniform int linearTarget;
out vec4 fragColor;

void main() {
	vec4 c = texture(baseColorTexture, texCoord) * color;
	if (linearTarget != 0) {
		vec3 s = max(c.rgb, vec3(0.0));
		c.rgb = mix(s / 12.92, pow((s + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), s));
	}
	fragColor = c;
}
