#version 330
// A program's own fragment stage declaring rlights' lights as raylib's examples' lighting.fs does, four of them (LightingTests).
#define MAX_LIGHTS 4
struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
};
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform Light lights[MAX_LIGHTS];
out vec4 finalColor;
void main() {
    vec3 light = vec3(0.0);
    for (int i = 0; i < MAX_LIGHTS; i++)
        if (lights[i].enabled == 1)
            light += lights[i].color.rgb*max(dot(normalize(fragNormal), normalize(lights[i].position - fragPosition)), 0.0);
    finalColor = texture(texture0, fragTexCoord)*colDiffuse*fragColor*vec4(light, 1.0);
}
