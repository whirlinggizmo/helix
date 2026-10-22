/* SpriteDissolve (helix.shader.SpriteDissolve): a sprite burnt away where a noise texture, laid across its region, is below a threshold rising
 * with the amount, a glowing edge along the cut. A sprite shader of the library: packed into the program by ShaderPacker (tools/gen_code.py). */
@fs fs
@include_block helix_sprite
layout(binding=2) uniform sprite_dissolve_params {
    vec4 edge_color;  // sRGB, its alpha how much of it
    float amount;     // 0 whole to 1 gone
    float edge_width; // how far into the noise's 0..1 the edge glows
    float scale;      // the noise's repeats across the sprite's region
};
layout(binding=1) uniform texture2D dissolve_noise;
layout(binding=1) uniform sampler dissolve_noise_sampler;

void main() {
    float noise = texture(sampler2D(dissolve_noise, dissolve_noise_sampler), helix_quad_uv() * scale).r;
    // From below the noise's least (nothing cut, no edge) at 0 to past its most (everything cut) at 1.
    float over = noise - (amount * (1.0 + edge_width + 0.002) - edge_width - 0.001);
    if (over < 0.0) discard;
    vec4 own = helix_sprite_color();
    float edge = (1.0 - smoothstep(0.0, edge_width, over)) * edge_color.a;
    helix_output(mix(own.rgb, edge_color.rgb, edge), own.a);
}
@end
