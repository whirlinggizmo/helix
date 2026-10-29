#version 450
// Six columns across, each looking down one axis: +X, -X, +Y, -Y, +Z, -Z.
layout(location = 0) in vec2 v_uv;
layout(binding = 0) uniform samplerCube sky;
layout(location = 0) out vec4 result;
const vec3 AXES[6] = vec3[6](vec3(1.0, 0.0, 0.0), vec3(-1.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0), vec3(0.0, -1.0, 0.0), vec3(0.0, 0.0, 1.0),
    vec3(0.0, 0.0, -1.0));
void main() { result = texture(sky, AXES[min(int(v_uv.x * 6.0), 5)]); }
