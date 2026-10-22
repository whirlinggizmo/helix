/* Sepia (examples/postprocess): the frame toned like an old photograph, the example's own screen effect beside the library's, to show how one
 * is written. A screen effect includes helix_screen, which gives it the frame (helix_screen_color, helix_screen_color_at, helix_screen_uv
 * from the top left), its size and the time, and helix_output; its own parameters are a uniform block at binding 2, set by name
 * (ScreenEffect.parameters; paper with setColor, its channels as they are, sRGB as the frame's). Packed into shaders/sepia.hxshader in the
 * assets (by tools/example.py for the examples, as a game's are by helix.tool.Build.packShaders), loaded at run time, and reloaded in place
 * as this file is edited while the dev loop runs (docs/SHADERS.md). */
@fs fs
@include_block helix_screen
layout(binding=2) uniform params {
    float amount; // how much of the toning, 0..1
    vec4 paper;   // the brightest tone: rgb, as the frame's colors are (sRGB)
};

void main() {
    vec4 frame = helix_screen_color();
    float luma = dot(frame.rgb, vec3(0.299, 0.587, 0.114));
    vec3 toned = paper.rgb * luma;
    helix_output(mix(frame.rgb, toned, clamp(amount, 0.0, 1.0)), frame.a);
}
@end
