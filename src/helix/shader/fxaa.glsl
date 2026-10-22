/* FXAA (helix.shader.Fxaa): Timothy Lottes's FXAA 3.11, its quality version at preset 12 (five steps along an edge), over the tone-mapped
 * frame: where the luma's contrast around a pixel passes a threshold, the edge's direction and its ends are found and the pixel is read from
 * across it by how far it is from the nearer end, plus a share of a blur for edges thinner than a pixel. Its luma is worked out here from the
 * frame's sRGB values (Rec. 601's weights), so the frame needs none in its alpha. Its steps are written out (no loop or array), as some
 * mobile GPUs' compilers want. A screen effect of the library: packed into the program by tools/pack_shader.py. */
@fs fs
@include_block helix_screen
layout(binding=2) uniform fxaa_params {
    float subpixel;            // how much of the blur thinner-than-a-pixel edges get, 0..1
    float edge_threshold;      // the least contrast worked on, a share of the brightest luma around
    float edge_threshold_min;  // and the least in all, so dark areas are left alone
};

float luma_at(vec2 uv) {
    return dot(helix_screen_color_at(uv).rgb, vec3(0.299, 0.587, 0.114));
}

// One step along the edge: each end not yet found moved on by s texels and read again.
void search(inout vec2 pos_n, inout vec2 pos_p, inout float end_n, inout float end_p, inout bool done_n, inout bool done_p, vec2 off,
            float half_pair, float gradient_scaled, float s) {
    if (!done_n) {
        pos_n -= off * s;
        end_n = luma_at(pos_n) - half_pair;
        done_n = abs(end_n) >= gradient_scaled;
    }
    if (!done_p) {
        pos_p += off * s;
        end_p = luma_at(pos_p) - half_pair;
        done_p = abs(end_p) >= gradient_scaled;
    }
}

void main() {
    vec2 pos = helix_screen_uv;
    vec2 rcp = 1.0 / helix_screen_size();
    vec4 middle = helix_screen_color();
    float luma_m = dot(middle.rgb, vec3(0.299, 0.587, 0.114));
    float luma_s = luma_at(pos + vec2(0.0, rcp.y));
    float luma_e = luma_at(pos + vec2(rcp.x, 0.0));
    float luma_n = luma_at(pos - vec2(0.0, rcp.y));
    float luma_w = luma_at(pos - vec2(rcp.x, 0.0));
    float range_max = max(max(luma_n, luma_w), max(luma_e, max(luma_s, luma_m)));
    float range_min = min(min(luma_n, luma_w), min(luma_e, min(luma_s, luma_m)));
    float range = range_max - range_min;
    if (range < max(edge_threshold_min, range_max * edge_threshold)) {
        helix_output(middle.rgb, middle.a);
        return;
    }
    float luma_nw = luma_at(pos - rcp);
    float luma_se = luma_at(pos + rcp);
    float luma_ne = luma_at(pos + vec2(rcp.x, -rcp.y));
    float luma_sw = luma_at(pos + vec2(-rcp.x, rcp.y));

    // Which way the edge runs.
    float luma_ns = luma_n + luma_s;
    float luma_we = luma_w + luma_e;
    float edge_horz1 = -2.0 * luma_m + luma_ns;
    float edge_vert1 = -2.0 * luma_m + luma_we;
    float luma_nese = luma_ne + luma_se;
    float luma_nwne = luma_nw + luma_ne;
    float edge_horz2 = -2.0 * luma_e + luma_nese;
    float edge_vert2 = -2.0 * luma_n + luma_nwne;
    float luma_nwsw = luma_nw + luma_sw;
    float luma_swse = luma_sw + luma_se;
    float edge_horz = abs(-2.0 * luma_w + luma_nwsw) + abs(edge_horz1) * 2.0 + abs(edge_horz2);
    float edge_vert = abs(-2.0 * luma_s + luma_swse) + abs(edge_vert1) * 2.0 + abs(edge_vert2);
    bool horz_span = edge_horz >= edge_vert;
    float subpix_b = ((luma_ns + luma_we) * 2.0 + luma_nwsw + luma_nese) * (1.0 / 12.0) - luma_m;
    if (!horz_span) {
        luma_n = luma_w;
        luma_s = luma_e;
    }
    float length_sign = horz_span ? rcp.y : rcp.x;
    float gradient_n = luma_n - luma_m;
    float gradient_s = luma_s - luma_m;
    bool pair_n = abs(gradient_n) >= abs(gradient_s);
    float gradient = max(abs(gradient_n), abs(gradient_s));
    if (pair_n) {
        length_sign = -length_sign;
    }
    float subpix_c = clamp(abs(subpix_b) / range, 0.0, 1.0);

    // Along the edge, half a texel across it, to its ends.
    vec2 pos_b = pos;
    vec2 off = horz_span ? vec2(rcp.x, 0.0) : vec2(0.0, rcp.y);
    if (horz_span) {
        pos_b.y += length_sign * 0.5;
    } else {
        pos_b.x += length_sign * 0.5;
    }
    float half_pair = (pair_n ? luma_n + luma_m : luma_s + luma_m) * 0.5;
    float gradient_scaled = gradient * 0.25;
    bool luma_m_below = luma_m - half_pair < 0.0;
    vec2 pos_n = pos_b - off;
    vec2 pos_p = pos_b + off;
    float end_n = luma_at(pos_n) - half_pair;
    float end_p = luma_at(pos_p) - half_pair;
    bool done_n = abs(end_n) >= gradient_scaled;
    bool done_p = abs(end_p) >= gradient_scaled;
    search(pos_n, pos_p, end_n, end_p, done_n, done_p, off, half_pair, gradient_scaled, 1.5);
    search(pos_n, pos_p, end_n, end_p, done_n, done_p, off, half_pair, gradient_scaled, 2.0);
    search(pos_n, pos_p, end_n, end_p, done_n, done_p, off, half_pair, gradient_scaled, 4.0);
    search(pos_n, pos_p, end_n, end_p, done_n, done_p, off, half_pair, gradient_scaled, 12.0);

    // Read from across the edge by how near the nearer end is, or the sub-pixel share, whichever is more.
    float dst_n = horz_span ? pos.x - pos_n.x : pos.y - pos_n.y;
    float dst_p = horz_span ? pos_p.x - pos.x : pos_p.y - pos.y;
    bool good_n = (end_n < 0.0) != luma_m_below;
    bool good_p = (end_p < 0.0) != luma_m_below;
    bool direction_n = dst_n < dst_p;
    float dst = min(dst_n, dst_p);
    bool good = direction_n ? good_n : good_p;
    float offset = good ? 0.5 - dst / (dst_n + dst_p) : 0.0;
    float subpix_f = (-2.0 * subpix_c + 3.0) * subpix_c * subpix_c;
    float pixel_offset = max(offset, subpix_f * subpix_f * subpixel);
    if (horz_span) {
        pos.y += pixel_offset * length_sign;
    } else {
        pos.x += pixel_offset * length_sign;
    }
    helix_output(helix_screen_color_at(pos).rgb, middle.a);
}
@end
