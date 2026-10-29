#version 450
// Places each vertex where its position says, in clip space, and hands its color on to be blended across the triangle.
layout(location = 0) in vec2 position;
layout(location = 1) in vec3 color;
layout(location = 0) out vec3 v_color;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    v_color = color;
}
