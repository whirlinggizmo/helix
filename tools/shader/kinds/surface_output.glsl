out vec4 helix_frag_color;
// Writes linear color and alpha: the material's rim light added, its hit flash mixed over the light after the exposure, tone mapped and encoded
// as the framebuffer's sRGB; in an HDR scene (a PostProcess chain tone mapping it later) the light after the exposure, as sRGB values running
// past 1.
void helix_output(vec3 color, float alpha) {
    vec3 l = mix(max((color + helix_rim_light()) * helix_tonemap_params.y, vec3(0.0)), helix_flash.rgb, helix_flash.a);
    if (helix_tonemap_params.z > 0.5) {
        helix_frag_color = vec4(mix(l * 12.92, 1.055 * pow(max(l, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), l)), alpha);
        return;
    }
    vec3 c = clamp(helix_tonemap_curve(l), vec3(0.0), vec3(1.0));
    helix_frag_color = vec4(mix(c * 12.92, 1.055 * pow(max(c, vec3(0.0031308)), vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c)), alpha);
}
