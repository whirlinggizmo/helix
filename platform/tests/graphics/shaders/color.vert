#version 450
// A position in clip space and a color per vertex. Block 0 is the clip scale the adapter writes (ClipScale), so a target is drawn the
// right way up.
layout(location = 0) in vec2 position;
layout(location = 1) in vec4 color;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec4 v_color;
void main() {
    gl_Position = vec4(position * scale.xy, 0.0, 1.0);
    v_color = color;
}
