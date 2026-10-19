/* Dissolve (helix.shaders.Dissolve): the material shaded as the stage shades it, burnt away where a noise texture, laid over the model at rest
 * in its own space, is below a threshold rising with the amount, a glowing edge along the cut. Its discard reaches its shadow (the caster the
 * packer makes for it), which reads the same noise at the same places. A surface shader of the library: packed into the program by
 * tools/pack_shader.py. */
@fs fs
@include_block helix_surface
layout(binding=2) uniform dissolve_params {
    vec4 edge_color;  // rgb linear light, times its intensity
    float amount;     // 0 whole to 1 gone
    float edge_width; // how far into the noise's 0..1 the edge glows
    float scale;      // the noise's repeats per unit of the model's own space
};
layout(binding=6) uniform texture2D dissolve_noise;
layout(binding=6) uniform sampler dissolve_noise_sampler;

float dissolve_read(vec2 at) { return texture(sampler2D(dissolve_noise, dissolve_noise_sampler), at).r; }

void main() {
    // Triplanar: the noise read across the three planes of the model's space, each weighed by how squarely the surface faces along its axis
    // (sharpened, so most of the surface reads one plane and keeps the noise's contrast). A texture, not noise computed here, so every GPU
    // reads the same values.
    vec3 p = helix_model_position() * scale, w = abs(helix_model_normal());
    w *= w;
    w *= w;
    w *= w;
    w /= max(w.x + w.y + w.z, 1e-6);
    float noise = dissolve_read(p.zy) * w.x + dissolve_read(p.xz) * w.y + dissolve_read(p.xy) * w.z;
    // From below the noise's least (nothing cut, no edge) at 0 to past its most (everything cut) at 1.
    float over = noise - (amount * (1.0 + edge_width + 0.002) - edge_width - 0.001);
    if (over < 0.0) discard;
    vec4 base = helix_base();
    float edge = 1.0 - smoothstep(0.0, edge_width, over);
    helix_output(helix_shade(helix_normal(), base) + edge_color.rgb * edge, base.a);
}
@end
