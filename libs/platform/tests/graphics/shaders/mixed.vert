#version 450
// A position, a color and a texture coordinate from one record, shown as the color's red and green and the coordinate's two. Block 0 is
// the clip scale the adapter writes (ClipScale).
layout(location = 0) in vec2 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec2 texCoord;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec4 v_color;
void main() {
    gl_Position = vec4(position * scale.xy, 0.0, 1.0);
    v_color = vec4(color.rg, texCoord);
}
