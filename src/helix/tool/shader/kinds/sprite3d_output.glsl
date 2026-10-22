in float helix_sprite_v_alpha_mode;
// Writes the color here as the sprite's alpha mode says (Sprite3D.alphaMode): under a mask's cutoff discarded, opaque or masked written
// whole, blended or added as it is.
void helix_output(vec3 color, float alpha) {
    if (helix_sprite_v_alpha_mode > 0.0 && alpha < helix_sprite_v_alpha_mode) discard;
    helix_frag_color = vec4(color, helix_sprite_v_alpha_mode != 0.0 ? 1.0 : alpha);
}