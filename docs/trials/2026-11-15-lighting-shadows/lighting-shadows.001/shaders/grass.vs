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
    vec3 pos = vertexPosition;
    // sway grows with height above the root (texcoord.y: 0 root, 1 tip)
    float bend = vertexTexCoord.y*vertexTexCoord.y;
    pos.x += sin(time*2.0 + pos.x*1.7 + pos.z*1.3)*0.08*bend;
    pos.z += cos(time*1.6 + pos.x*1.1 + pos.z*1.9)*0.05*bend;

    fragPosition = vec3(matModel*vec4(pos, 1.0));
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    fragNormal = normalize(vec3(matNormal*vec4(vertexNormal, 1.0)));
    gl_Position = mvp*vec4(pos, 1.0);
}
