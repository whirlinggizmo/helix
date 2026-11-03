// The camera both stages read: a block shared by every material.
layout(std140) uniform Camera {
    mat4 viewProjection;
    vec4 eye;
};
