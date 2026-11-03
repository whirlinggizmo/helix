#version 450
// Colors each pixel the triangle covers with the vertices' colors, blended.
layout(location = 0) in vec3 v_color;
layout(location = 0) out vec4 frag_color;

void main() {
    frag_color = vec4(v_color, 1.0);
}
