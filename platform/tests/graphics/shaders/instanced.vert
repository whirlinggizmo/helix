#version 450
// A position moved by a matrix and given a color, both an instance's, the matrix a mat4 input over four locations. Block 0 is the clip
// scale the adapter writes (ClipScale).
layout(location = 0) in vec2 position;
layout(location = 1) in mat4 placement;
layout(location = 5) in vec4 color;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec4 v_color;
void main() {
    vec4 moved = placement * vec4(position, 0.0, 1.0);
    gl_Position = vec4(moved.xy * scale.xy, moved.z, moved.w);
    v_color = color;
}
