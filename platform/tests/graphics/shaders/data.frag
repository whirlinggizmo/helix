#version 450
// Reads a 4 x 1 data texture texel by texel, a quarter of the width each, and brings its floats into 0 to 1: x / 8, -y, z.
layout(location = 0) in vec2 v_uv;
layout(binding = 0) uniform sampler2D table;
layout(location = 0) out vec4 result;
void main() {
    vec4 texel = texelFetch(table, ivec2(int(v_uv.x * 4.0), 0), 0);
    result = vec4(texel.x / 8.0, -texel.y, texel.z, 1.0);
}
