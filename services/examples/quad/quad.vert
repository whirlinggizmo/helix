#version 450
// Places the quad's corners: each position scaled and moved by the block's offsetScale, its texture coordinates handed on.
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 texCoord;
layout(binding = 0) uniform Placement {
    vec4 offsetScale; // xy the offset, zw the scale, in clip space
};
layout(location = 0) out vec2 uv;

void main() {
    gl_Position = vec4(position * offsetScale.zw + offsetScale.xy, 0.0, 1.0);
    uv = texCoord;
}
