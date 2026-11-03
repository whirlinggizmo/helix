#version 450
// Colors the quad with its texture, tinted, its brightness pulsing with the time.
layout(location = 0) in vec2 uv;
layout(binding = 1) uniform Look {
    vec4 tint;
    float time;
};
layout(binding = 0) uniform sampler2D image;
layout(location = 0) out vec4 color;

void main() {
    float pulse = 0.75 + 0.25 * sin(time * 3.0);
    color = texture(image, uv) * tint * vec4(vec3(pulse), 1.0);
}
