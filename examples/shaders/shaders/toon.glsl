/* Toon shading (examples/shaders): the stage's lights in a few flat bands, and a rim of light around the silhouette. A surface shader: it
 * includes helix_surface, so a Stage3D material draws with it. */
@fs fs
@include_block helix_surface
layout(binding=2) uniform params {
    float bands; // light levels
    float rim;   // rim light strength
};

void main() {
    vec4 albedo = helix_base();
    vec3 n = helix_normal();
    vec3 light = helix_ambient();
    for (int i = 0; i < 4; i++) {
        if (i >= helix_light_count()) {
            break;
        }
        vec3 to_light;
        vec3 radiance = helix_light(i, helix_world_position(), n, to_light);
        float lambert = max(dot(n, to_light), 0.0);
        light += radiance * (floor(lambert * bands + 0.5) / max(bands, 1.0)) / 3.14159265;
    }
    vec3 v = normalize(helix_camera_position() - helix_world_position());
    float edge = pow(1.0 - max(dot(n, v), 0.0), 3.0) * rim;
    helix_output(albedo.rgb * light + vec3(edge) + helix_emissive(), albedo.a);
}
@end
