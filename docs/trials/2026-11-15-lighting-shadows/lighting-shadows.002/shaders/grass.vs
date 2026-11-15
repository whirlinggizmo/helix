#version 330

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

uniform mat4 mvp;
uniform mat4 matModel;
uniform mat4 matNormal;
uniform float time;

out vec3 fragPosition;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragNormal;

void main()
{
    vec4 world = matModel*vec4(vertexPosition, 1.0);
    // sway grows toward the tip (texcoord.y = 0 at the root, 1 at the tip)
    float bend = vertexTexCoord.y*vertexTexCoord.y;
    float phase = world.x*0.7 + world.z*0.9;
    world.x += sin(time*2.0 + phase)*0.06*bend;
    world.z += cos(time*1.7 + phase*1.3)*0.04*bend;

    fragPosition = world.xyz;
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragNormal = normalize(vec3(matNormal*vec4(vertexNormal, 1.0)));

    gl_Position = mvp*(inverse(matModel)*world);
}
