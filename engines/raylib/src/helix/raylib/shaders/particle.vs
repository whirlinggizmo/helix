#version 330
// helix-raylib's particle vertex stage (the Particles extra's 3D emitters): an emitter's particles drawn as instances of one quad facing
// the camera, each worked out from its age. A particle's record is six texels of particleRecords, 256 particles a row, written once at
// its birth: where (xyz) and when (w) it was born; its velocity (xyz) and life (w); its size scale, its spin in radians a second, a
// random number from 0 to 1 and its pulse's phase from 0 to 1; its tint; its offset from where the emitter was (xyz) and its orbit in
// radians a second (w); and the axis it orbits (xyz).
in float spriteCorner;
in float particleIndex;
out vec2 fragTexCoord;
out vec4 fragColor;
out vec3 fragPosition;
uniform mat4 mvp;
uniform sampler2D particleRecords;
// xyz: the quad's right before it turns, the camera's; w: the oldest particle's slot.
uniform vec4 particleRight;
// xyz: the quad's up; w: the emitter's slots, its most particles alive.
uniform vec4 particleUp;
// x: the emitter's clock now; y: drag; z: stretch; w: wander distance.
uniform vec4 particleClock;
// xyz: gravity; w: wander rate.
uniform vec4 particleGravity;
// The flipbook: x its columns, y its rows, z the frames played, w the frames a second.
uniform vec4 particleFrames;
// The texture's part drawn: u0, v0, u1, v1.
uniform vec4 particleSource;
// x: the size keys; y: the color keys; z: the pulse's beats a second; w: how far the pulse takes the alpha down.
uniform vec4 particleCounts;
// The sizes over a life, in order: x when, 0 to 1, and y the size; the colors, and when each is.
uniform vec4 particleSizes[8];
uniform vec4 particleColorTimes[8];
uniform vec4 particleColors[8];

vec4 particleRecord(int slot, int texel) {
    return texelFetch(particleRecords, ivec2(slot % 256 * 6 + texel, slot / 256), 0);
}

// A curve at t: its first key's value before it, its last's after, and between two keys the line between them.
float particleSizeAt(float t) {
    int n = int(particleCounts.x + 0.5);
    float value = particleSizes[0].y;
    for (int i = 1; i < 8; i++) {
        if (i >= n)
            break;
        vec4 a = particleSizes[i - 1];
        vec4 b = particleSizes[i];
        if (t >= b.x) {
            value = b.y;
            continue;
        }
        if (t > a.x)
            value = mix(a.y, b.y, (t - a.x)/max(b.x - a.x, 0.000001));
        break;
    }
    return value;
}

vec4 particleColorAt(float t) {
    int n = int(particleCounts.y + 0.5);
    vec4 value = particleColors[0];
    for (int i = 1; i < 8; i++) {
        if (i >= n)
            break;
        float a = particleColorTimes[i - 1].x;
        float b = particleColorTimes[i].x;
        if (t >= b) {
            value = particleColors[i];
            continue;
        }
        if (t > a)
            value = mix(particleColors[i - 1], particleColors[i], (t - a)/max(b - a, 0.000001));
        break;
    }
    return value;
}

void main() {
    int count = int(particleUp.w + 0.5);
    int slot = (int(particleRight.w + 0.5) + int(particleIndex + 0.5)) % count;
    vec4 born = particleRecord(slot, 0);
    vec4 motion = particleRecord(slot, 1);
    vec4 shape = particleRecord(slot, 2);
    vec4 tint = particleRecord(slot, 3);
    vec4 orbit = particleRecord(slot, 4);
    float age = particleClock.x - born.w;
    float t = motion.w > 0.0 ? age/motion.w : 1.0;
    if (age < 0.0 || t >= 1.0) {
        // Not born yet, or dead: outside the view.
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
        fragTexCoord = vec2(0.0);
        fragColor = vec4(0.0);
        fragPosition = vec3(0.0);
        return;
    }
    // Gravity, and drag slowing it in proportion to its speed, toward gravity / drag.
    vec3 gravity = particleGravity.xyz;
    float drag = particleClock.y;
    vec3 position;
    vec3 velocity;
    if (drag > 0.0001) {
        vec3 terminal = gravity/drag;
        float decay = exp(-drag*age);
        position = born.xyz + terminal*age + (motion.xyz - terminal)*((1.0 - decay)/drag);
        velocity = terminal + (motion.xyz - terminal)*decay;
    } else {
        position = born.xyz + motion.xyz*age + 0.5*gravity*age*age;
        velocity = motion.xyz + gravity*age;
    }
    // Its orbit: its offset from where the emitter was, turned about the axis counterclockwise as seen from where the axis points,
    // in place of the offset as born.
    if (orbit.w != 0.0) {
        vec3 axis = particleRecord(slot, 5).xyz;
        float turn = orbit.w*age;
        float c = cos(turn);
        float s = sin(turn);
        vec3 turned = orbit.xyz*c + cross(axis, orbit.xyz)*s + axis*dot(axis, orbit.xyz)*(1.0 - c);
        position += turned - orbit.xyz;
    }
    // A smooth wandering course off its path, starting at its path.
    if (particleClock.w > 0.0) {
        float turn = 6.2831853*particleGravity.w*age;
        vec3 first = fract(shape.z*vec3(1.0, 7.31, 13.7))*6.2831853;
        vec3 second = fract(shape.z*vec3(3.17, 5.93, 11.1))*6.2831853;
        position += particleClock.w*(0.6*sin(turn + first) + 0.4*sin(2.3*turn + second) - 0.6*sin(first) - 0.4*sin(second));
    }
    float size = max(particleSizeAt(t), 0.0)*shape.x;
    float along = size;
    vec3 right = particleRight.xyz;
    vec3 up = particleUp.xyz;
    vec2 seen = vec2(dot(velocity, right), dot(velocity, up));
    float speed = length(seen);
    vec3 center = position;
    if (particleClock.z > 0.0 && speed > 0.00001) {
        // A streak: the texture's width along its motion on screen, as long as the way it moves in stretch seconds more, trailing.
        vec2 d = seen/speed;
        vec3 forward = right*d.x + up*d.y;
        up = up*d.x - right*d.y;
        right = forward;
        along = size + speed*particleClock.z;
        position -= right*(speed*particleClock.z*0.5);
    } else {
        // Turned clockwise as seen by its spin.
        float angle = shape.y*age;
        float c = cos(angle);
        float s = sin(angle);
        vec3 turned = right*c - up*s;
        up = up*c + right*s;
        right = turned;
    }
    // The corner: 0 the top left, 1 the bottom left, 2 the bottom right and 3 the top right, as a sprite's.
    int corner = int(spriteCorner + 0.5);
    vec2 at = vec2(corner < 2 ? -0.5 : 0.5, (corner == 0 || corner == 3) ? 0.5 : -0.5);
    // The flipbook's frame: played once over the life, or looped at its rate.
    vec2 cells = max(particleFrames.xy, vec2(1.0));
    float frames = particleFrames.z;
    float frame = 0.0;
    if (frames > 1.5)
        frame = particleFrames.w > 0.0 ? mod(floor(age*particleFrames.w), frames) : min(floor(t*frames), frames - 1.0);
    vec2 cell = (particleSource.zw - particleSource.xy)/cells;
    vec2 low = particleSource.xy + cell*vec2(mod(frame, cells.x), floor(frame/cells.x));
    fragTexCoord = vec2(corner < 2 ? low.x : low.x + cell.x, (corner == 0 || corner == 3) ? low.y : low.y + cell.y);
    fragColor = particleColorAt(t)*tint;
    // The pulse: the alpha down by up to its depth, on the particle's own phase.
    if (particleCounts.z > 0.0)
        fragColor.a *= 1.0 - particleCounts.w*(0.5 + 0.5*sin(6.2831853*fract(particleCounts.z*age + shape.w)));
    fragPosition = center;
    gl_Position = mvp*vec4(position + right*(at.x*along) + up*(at.y*size), 1.0);
}
