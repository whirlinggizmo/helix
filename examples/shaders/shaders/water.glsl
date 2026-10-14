/* Water (examples/shaders): a vertex hook moves the surface along its normals in travelling waves; the fragment stage colors it by height,
 * lights it, and adds a sky color at grazing angles (Fresnel) and the lights' glints. */
@block vertex
layout(binding=3) uniform wave_params {
    float amplitude;  // model-space units
    float frequency;  // waves across one unit
    float wave_speed; // radians a second
};
void helix_vertex(inout vec3 position, inout vec3 normal) {
    float phase = (position.x + position.z) * frequency * 6.2831853 + helix_time() * wave_speed;
    position += normal * sin(phase) * amplitude;
}
@end

@fs fs
@include_block helix_surface
layout(binding=2) uniform params {
    vec4 low_color;  // linear rgba
    vec4 high_color;
    vec4 sky_color;  // linear rgb, reflected at grazing angles
    float shininess; // the glints' tightness
};

void main() {
    vec3 n = helix_normal();
    vec3 v = normalize(helix_camera_position() - helix_world_position());
    vec3 light = helix_ambient();
    vec3 glint = vec3(0.0);
    for (int i = 0; i < 4; i++) {
        if (i >= helix_light_count()) {
            break;
        }
        vec3 to_light;
        vec3 radiance = helix_light(i, helix_world_position(), to_light);
        light += radiance * max(dot(n, to_light), 0.0) / 3.14159265;
        glint += radiance * pow(max(dot(n, normalize(to_light + v)), 0.0), shininess);
    }
    float height = clamp(helix_world_position().y * 0.5 + 0.5, 0.0, 1.0);
    vec4 color = mix(low_color, high_color, height);
    float fresnel = 0.04 + 0.96 * pow(1.0 - max(dot(n, v), 0.0), 5.0);
    helix_output(mix(color.rgb * light, sky_color.rgb, fresnel) + glint, color.a);
}
@end
