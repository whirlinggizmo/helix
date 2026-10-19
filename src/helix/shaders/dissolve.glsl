/* Dissolve (helix.shaders.Dissolve): the material shaded as the stage shades it, burnt away where a noise texture is below a threshold rising
 * with the amount, a glowing edge along the cut. Its discard reaches its shadow (the caster the packer makes for it). A surface shader of the
 * library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_surface
layout(binding=2) uniform dissolve_params {
    vec4 edge_color;  // rgb linear light, times its intensity
    float amount;     // 0 whole to 1 gone
    float edge_width; // how far into the noise's 0..1 the edge glows
    float scale;      // the noise's repeats across the surface's uv
};
layout(binding=6) uniform texture2D dissolve_noise;
layout(binding=6) uniform sampler dissolve_noise_sampler;

void main() {
    float noise = texture(sampler2D(dissolve_noise, dissolve_noise_sampler), helix_uv() * scale).r;
    // From below the noise's least (nothing cut, no edge) at 0 to past its most (everything cut) at 1.
    float over = noise - (amount * (1.0 + edge_width + 0.002) - edge_width - 0.001);
    if (over < 0.0) discard;
    vec4 base = helix_base();
    float edge = 1.0 - smoothstep(0.0, edge_width, over);
    helix_output(helix_shade(helix_normal(), base) + edge_color.rgb * edge, base.a);
}
@end
