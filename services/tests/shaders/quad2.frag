#version 450
// quad.frag changed, as a file a reload brings: a new member first, time gone.
layout(location = 0) in vec2 uv;
struct Light { vec3 color; int on; };
layout(binding = 1) uniform Look {
    vec4 glow;
    vec4 tint;
    vec2 offsets[4];
    int mode;
    bool bright;
    uint mask;
    Light lights[2];
    mat3 turn;
    float weights[3];
    ivec2 cells;
};
layout(binding = 0) uniform sampler2D image;
layout(binding = 1) uniform samplerCube sky;
layout(binding = 2) uniform sampler2D table;
layout(location = 0) out vec4 color;
void main() {
    vec4 t = texture(image, uv + offsets[mode & 3]) * tint * glow + texture(sky, vec3(uv, 1.0)) + texelFetch(table, cells, 0);
    if (bright)
        t *= 2.0;
    color = t + vec4(lights[1].color * float(lights[1].on) + turn[1], weights[2] + float(mask));
}
