// The lights, loose uniforms a shader gathers into a shared block by name.
struct PointLight { vec3 position; float range; vec4 color; };
uniform PointLight pointLights[3];
uniform vec4 ambient;
