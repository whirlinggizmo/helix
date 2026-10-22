/* Toon (helix.shader.Toon): the stage's lights in a few flat bands over the material's base color (their shadows banded with them), the
 * unlit side no darker than a shadow color, the material's emission; its rim is the material's rim light (helix.shader.Rim), which Toon
 * turns on. A surface shader of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_surface
layout(binding=2) uniform toon_params {
    vec4 shadow_color; // rgb linear: the least light the surface shows, its unlit side's
    float bands;       // light levels, 1 or more
};

void main() {
    vec4 albedo = helix_base();
    vec3 n = helix_normal();
    vec3 light = helix_ambient();
    for (int i = 0; i < 8; i++) {
        if (i >= helix_light_count()) break;
        vec3 to_light;
        float lit;
        vec3 radiance = helix_light_lit(i, helix_world_position(), n, to_light, lit);
        // The light's own strength here (its radiance before its shadow) through the banded share of it the surface faces and its shadow lets by.
        float level = max(dot(n, to_light), 0.0) * lit;
        light += radiance / max(lit, 1e-3) * (floor(level * bands + 0.5) / max(bands, 1.0)) / HELIX_PI;
    }
    helix_output(albedo.rgb * max(light, shadow_color.rgb) + helix_emissive(), albedo.a);
}
@end
