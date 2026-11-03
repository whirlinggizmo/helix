#version 450
// A color from the shared block's members, each read at its std140 place: the picked light's color if it is on, doubled when bright,
// times a weight, blue from the matrix's second column, green from the mask's second bit.
#include "shared.glsl"
layout(location = 0) out vec4 result;
void main() {
    vec3 c = lights[pick].color * float(lights[pick].on);
    if (bright)
        c *= 2.0;
    c *= weights[2];
    c.b += turn[1][2];
    c.g += float(mask & 2u) * 0.125;
    result = vec4(c, 1.0);
}
