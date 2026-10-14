/* Particles (render3d's Stage3D emitters), after wgrender-c's: a particle is a birth record the CPU writes once, when it's born; where it
 * is, how big, what color and how turned follow from how long ago that was, here. One draw an emitter, an instance a particle.
 *
 * i_born    xyz where, w when (the emitter's clock, seconds)
 * i_motion  xyz velocity, w life (seconds)
 * i_shape   x size scale, y spin (radians a second), z angle at birth, w a random 0..1 (its palette color, its flipbook start) */
@vs particle3d_vs
layout(binding=0) uniform particle3d_params {
    mat4 view_projection;
    vec4 axis_x;      // xyz: the quad's right before spin (the camera's right)
    vec4 axis_y;      // xyz: its up (the camera's up)
    vec4 gravity_now; // xyz gravity, w the emitter's clock now (seconds)
    vec4 counts;      // x size keys, y color keys, z alpha mode (as sprites': > 0 a cutoff, < 0 opaque, 0 as is), w palette colors
    vec4 region;      // the texture region: u0, v0, u1, v1
    vec4 dynamics;    // x drag (a second), y stretch (seconds of motion; 0 none)
    vec4 frames;      // flipbook: x columns, y rows, z frames (< 2: none), w a second (0: over the life)
    vec4 size_times[2];  // up to 8 keys over the life (0..1), in order, four a vec4
    vec4 size_values[2];
    vec4 color_times[2];
    vec4 color_values[8];
    vec4 palette[8];     // each particle's tint, picked at birth
};
layout(location=0) in vec2 corner; // x -0.5 left .. 0.5 right, y -0.5 bottom .. 0.5 top
layout(location=1) in vec4 i_born;
layout(location=2) in vec4 i_motion;
layout(location=3) in vec4 i_shape;
out vec2 v_uv;
out vec4 v_tint;
out float v_alpha_mode;

/* Key i (0..7) of a curve packed four keys a vec4, two vec4s a curve. Both halves are read and one chosen arithmetically: an index into the
   flattened uniform array the compiler can't bound (i / 4, or a branch around the read) fails to link on Adreno's GLES driver (wgrender-c's
   finding), and the emitter silently draws nothing. A constant array index, and a dynamic component, are fine. */
float curve_key(vec4 lo, vec4 hi, int i) { vec4 q = mix(lo, hi, step(3.5, float(i))); return q[i % 4]; }
float size_time(int i) { return curve_key(size_times[0], size_times[1], i); }
float size_value(int i) { return curve_key(size_values[0], size_values[1], i); }
float color_time(int i) { return curve_key(color_times[0], color_times[1], i); }

// A curve at t: its first key's value before it, its last's after, and between two keys the line between them.
float size_at(float t) {
    int n = int(counts.x);
    float value = size_value(0);
    float prev_t = size_time(0);
    for (int i = 1; i < 8; i++) {
        if (i >= n || t <= prev_t) break;
        float key_t = size_time(i);
        float key_v = size_value(i);
        value = t >= key_t ? key_v : mix(value, key_v, (t - prev_t) / max(key_t - prev_t, 0.000001));
        prev_t = key_t;
    }
    return value;
}

vec4 color_at(float t) {
    int n = int(counts.y);
    vec4 value = color_values[0];
    float prev_t = color_time(0);
    for (int i = 1; i < 8; i++) {
        if (i >= n || t <= prev_t) break;
        float key_t = color_time(i);
        value = t >= key_t ? color_values[i] : mix(value, color_values[i], (t - prev_t) / max(key_t - prev_t, 0.000001));
        prev_t = key_t;
    }
    return value;
}

void main() {
    float age = gravity_now.w - i_born.w;
    float t = age / i_motion.w;
    if (age < 0.0 || t >= 1.0) { // not born yet, or dead: nothing to draw
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
        v_uv = vec2(0.0);
        v_tint = vec4(0.0);
        v_alpha_mode = 0.0;
        return;
    }
    // Gravity, and drag: slowing in proportion to speed, toward gravity / drag.
    vec3 pos;
    vec3 vel;
    float drag = dynamics.x;
    if (drag > 0.0001) {
        vec3 terminal = gravity_now.xyz / drag;
        float decay = exp(-drag * age);
        pos = i_born.xyz + terminal * age + (i_motion.xyz - terminal) * ((1.0 - decay) / drag);
        vel = terminal + (i_motion.xyz - terminal) * decay;
    } else {
        pos = i_born.xyz + i_motion.xyz * age + 0.5 * gravity_now.xyz * age * age;
        vel = i_motion.xyz + gravity_now.xyz * age;
    }
    float size = size_at(t) * i_shape.x;
    float along = size;
    vec3 right;
    vec3 up;
    // Stretched: the quad's up follows the velocity across the screen, as long as the distance moved in `stretch` seconds (plus its size),
    // trailing behind.
    vec2 screen_vel = vec2(dot(vel, axis_x.xyz), dot(vel, axis_y.xyz));
    float speed = length(screen_vel);
    if (dynamics.y > 0.0 && speed > 0.00001) {
        vec2 d = screen_vel / speed;
        up = axis_x.xyz * d.x + axis_y.xyz * d.y;
        right = axis_x.xyz * d.y - axis_y.xyz * d.x;
        float extra = speed * dynamics.y;
        along = size + extra;
        pos -= up * (extra * 0.5);
    } else {
        float angle = i_shape.z + i_shape.y * age; // positive turns clockwise on screen
        float c = cos(angle);
        float s = sin(angle);
        right = axis_x.xyz * c - axis_y.xyz * s;
        up = axis_x.xyz * s + axis_y.xyz * c;
    }
    gl_Position = view_projection * vec4(pos + right * (corner.x * size) + up * (corner.y * along), 1.0);
    // The flipbook's frame: played once over the life, or looped from a random frame.
    vec4 cell = region;
    if (frames.z > 1.5) {
        float frame = frames.w > 0.0 ? mod(floor(age * frames.w + fract(i_shape.w * 7.31) * frames.z), frames.z)
                                     : min(floor(t * frames.z), frames.z - 1.0);
        vec2 cell_size = (region.zw - region.xy) / frames.xy;
        cell.xy = region.xy + cell_size * vec2(mod(frame, frames.x), floor(frame / frames.x));
        cell.zw = cell.xy + cell_size;
    }
    v_uv = vec2(mix(cell.x, cell.z, corner.x + 0.5), mix(cell.y, cell.w, 0.5 - corner.y));
    v_tint = color_at(t);
    int colors = int(counts.w);
    if (colors > 0) {
        v_tint *= palette[min(int(i_shape.w * float(colors)), colors - 1)];
    }
    v_alpha_mode = counts.z;
}
@end

@fs particle3d_fs
layout(binding=0) uniform texture2D particle3d_texture;
layout(binding=0) uniform sampler particle3d_sampler;
in vec2 v_uv;
in vec4 v_tint;
in float v_alpha_mode;
out vec4 frag_color;
void main() {
    frag_color = texture(sampler2D(particle3d_texture, particle3d_sampler), v_uv) * v_tint;
    if (v_alpha_mode > 0.0 && frag_color.a < v_alpha_mode) {
        discard;
    }
    if (v_alpha_mode < 0.0) {
        frag_color.a = 1.0;
    }
}
@end

@program particle3d particle3d_vs particle3d_fs
