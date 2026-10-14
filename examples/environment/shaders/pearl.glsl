/* Pearl (examples/environment): a surface shader that changes only its inputs and lets the stage shade it (helix_shade), environment and
 * all: its base color shifts from pink to green to blue as the surface turns from the viewer, like a pearl's nacre. */
@fs fs
@include_block helix_surface

void main() {
    vec3 n = helix_normal();
    vec3 v = normalize(helix_camera_position() - helix_world_position());
    float facing = clamp(dot(n, v), 0.0, 1.0);
    vec3 sheen = 0.5 + 0.5 * cos(6.2831853 * (vec3(0.0, 0.33, 0.67) + facing * 0.8));
    vec4 base = helix_base();
    helix_output(helix_shade(n, vec4(base.rgb * mix(vec3(1.0), sheen, 0.35), base.a)), base.a);
}
@end
