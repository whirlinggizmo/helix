/* Dissolve (examples/shaders): the surface burns away and back where a noise texture is below a moving threshold, with a glowing edge. A
 * surface shader with a texture of its own (binding 2: the framework's base and normal textures are 0 and 1). */
@fs fs
@include_block helix_surface
layout(binding=2) uniform params {
    vec4 color;      // linear rgba
    vec3 edge_color; // linear rgb, may exceed 1
    float speed;     // cycles a second
};
layout(binding=2) uniform texture2D noise_texture;
layout(binding=2) uniform sampler noise_sampler;

void main() {
    float noise = texture(sampler2D(noise_texture, noise_sampler), helix_uv() * 2.0).r;
    float threshold = 0.3 + 0.4 * sin(helix_time() * speed * 6.2831853); // never quite all gone
    if (noise < threshold) {
        discard;
    }
    vec3 n = helix_normal();
    vec3 light = helix_ambient();
    for (int i = 0; i < 4; i++) {
        if (i >= helix_light_count()) {
            break;
        }
        vec3 to_light;
        vec3 radiance = helix_light(i, helix_world_position(), to_light);
        light += radiance * max(dot(n, to_light), 0.0) / 3.14159265;
    }
    float edge = 1.0 - smoothstep(0.0, 0.06, noise - threshold);
    helix_output(color.rgb * light + edge_color * edge, color.a);
}
@end
