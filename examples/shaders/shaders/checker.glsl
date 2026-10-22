/* Checker (examples/shaders): the example's own surface shader, to show how one is written (docs/SHADERS.md). It includes helix_surface, so
 * a material draws with it (Material3D.setShader) and it gets the stage's lights, shadows and environment. It is packed into
 * shaders/checker.hxshader in the assets, which the example loads (Shaders.load): by tools/example.py for the examples, as a game's are by
 * helix.tool.Build.packShaders. Its parameters are the uniform block at binding 2, set by name (Material3D.shaderParameters); helix_shade
 * lights the colors it picks as the stage lights any material, and helix_output writes them, the material's hit flash and rim light too. */
@fs fs
@include_block helix_surface
layout(binding=2) uniform checker_params {
    vec4 light_color; // linear rgb (set with setValues, not decoded), alternating with dark_color
    vec4 dark_color;
    float cell;       // a square's side, world units
};

void main() {
    vec2 at = floor(helix_world_position().xz / max(cell, 1e-3));
    float pick = mod(at.x + at.y, 2.0);
    vec4 base = helix_base() * mix(light_color, dark_color, pick);
    helix_output(helix_shade(helix_normal(), base), base.a);
}
@end
