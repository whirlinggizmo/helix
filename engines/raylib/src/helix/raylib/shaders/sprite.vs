#version 330
// helix-raylib's sprite vertex stage: a run of quads of one texture drawn as instances of one quad, each instance a record of its four
// corners, its texture rectangle and its color (52 bytes), where raylib's batch writes four 36-byte vertices. The corners are the
// batch's, as rlgl's drawing functions computed them, so the picture is raylib's to the pixel.
in float spriteCorner;
in vec4 spriteAB;
in vec4 spriteCD;
in vec4 spriteRect;
in vec4 spriteColor;
out vec2 fragTexCoord;
out vec4 fragColor;
uniform mat4 mvp;
void main() {
    // The corner this vertex is, 0 to 3: the first, second and third corners then the first, third and fourth make the two triangles.
    int c = int(spriteCorner + 0.5);
    vec2 corner = c == 0 ? spriteAB.xy : c == 1 ? spriteAB.zw : c == 2 ? spriteCD.xy : spriteCD.zw;
    // The rectangle's u0, v0 at the first corner, u0, v1 at the second, u1, v1 at the third and u1, v0 at the fourth.
    fragTexCoord = vec2(c < 2 ? spriteRect.x : spriteRect.z, (c == 0 || c == 3) ? spriteRect.y : spriteRect.w);
    fragColor = spriteColor;
    gl_Position = mvp*vec4(corner, 0.0, 1.0);
}
