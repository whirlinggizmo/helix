/* Water (helix.shaders.Water): a vertex hook moves the surface along its normals in travelling waves, tilting the normals with their slopes;
 * the fragment stage colors it deep where it's looked into and shallow toward grazing, lights it, reflects the stage's environment (or a sky
 * color without one) at grazing angles (Fresnel) and adds the lights' glints. Its waves reach its shadow (the caster the packer makes for it).
 * A surface shader of the library: packed into the program by tools/pack_shader.py. */
@block vertex
layout(binding=3) uniform water_waves {
    float amplitude;  // the waves' height, model-space units
    float wavelength; // between crests, model-space units
    float wave_speed; // the crests' speed, model-space units a second
};
void helix_vertex(inout vec3 position, inout vec3 normal) {
    float k = 6.2831853 / max(wavelength, 1e-4);
    float phase = (position.x + position.z) * 0.70710678 * k - helix_time() * wave_speed * k;
    // The slope's gradient in the model's space, along the waves' direction, kept off the normal: the normal tilts against it.
    vec3 slope = vec3(0.70710678, 0.0, 0.70710678) * (cos(phase) * amplitude * k);
    position += normal * sin(phase) * amplitude;
    normal = normalize(normal - (slope - normal * dot(slope, normal)));
}
@end

@fs fs
@include_block helix_surface
layout(binding=2) uniform water_params {
    vec4 deep_color;    // rgb linear: looked straight into
    vec4 shallow_color; // rgb linear: toward grazing
    vec4 sky_color;     // rgb linear: reflected at grazing angles without an environment
    float shininess;    // the glints' tightness
};

void main() {
    vec3 n = helix_normal();
    vec3 v = helix_view_direction();
    float facing = clamp(dot(n, v), 0.0, 1.0);
    vec3 light = helix_ambient(), glint = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        if (i >= helix_light_count()) break;
        vec3 to_light;
        vec3 radiance = helix_light(i, helix_world_position(), n, to_light);
        light += radiance * max(dot(n, to_light), 0.0) / HELIX_PI;
        glint += radiance * pow(max(dot(n, normalize(to_light + v)), 0.0), shininess);
    }
    vec3 body = mix(shallow_color.rgb, deep_color.rgb, facing) * light;
    vec3 sky = helix_has_environment() ? helix_environment_reflection(reflect(-v, n), 0.05) : sky_color.rgb;
    float fresnel = 0.04 + 0.96 * pow(1.0 - facing, 5.0);
    helix_output(mix(body, sky, fresnel) + glint, helix_base().a);
}
@end
