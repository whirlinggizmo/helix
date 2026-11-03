#version 450
// A position and a color fed from a record, slots 0 and 2, and a tint at slot 1 between them that no buffer feeds, read as its
// constant: a layout with a gap of slots. Block 0 is the clip scale the adapter writes (ClipScale).
layout(location = 0) in vec2 position;
layout(location = 1) in vec4 tint;
layout(location = 2) in vec4 color;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec4 v_color;
void main() {
    gl_Position = vec4(position * scale.xy, 0.0, 1.0);
    v_color = color * tint;
}
