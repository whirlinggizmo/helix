#version 450
// A position in clip space and, for each component of a value, 1 where it reads 0 (within 1e-4) and 0 elsewhere: a signed normalized 0
// must read 0, not GL 4.1's 1/255. Block 0 is the clip scale the adapter writes (ClipScale).
layout(location = 0) in vec2 position;
layout(location = 1) in vec4 value;
layout(binding = 0) uniform clip { vec4 scale; };
layout(location = 0) out vec4 v_color;
void main() {
    gl_Position = vec4(position * scale.xy, 0.0, 1.0);
    v_color = vec4(lessThan(abs(value), vec4(1e-4)));
}
