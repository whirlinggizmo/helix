#version 330
// A lit surface: loose material uniforms, lights gathered into a shared block by name, the camera's eye.
#include "camera.glsl"
in vec3 vNormal;
in vec4 vColor;
out vec4 fragColor;
#include "lights.glsl"
uniform vec4 baseColor;
uniform float roughness;
uniform sampler2D baseColorTexture;
#ifdef FOG
uniform vec3 fogColor;
#endif
void main() {
    vec4 c = texture(baseColorTexture, vNormal.xy) * baseColor * vColor + ambient * roughness + pointLights[0].color * eye.w;
#ifdef FOG
    c.rgb += fogColor;
#endif
    fragColor = c;
}
