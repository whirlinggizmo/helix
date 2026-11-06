#version 300 es
// SpriteRuns2D's vertex stage: a run of quads of one texture drawn as instances of one quad, each instance a record of its four corners
// in order round it, its texture's rectangle and its color (52 bytes), where batch2d.vert reads six 24-byte vertices. Its texture
// coordinates and color are passed on as batch2d.vert passes them, so batch2d.frag draws both.
in float spriteCorner;
in vec4 spriteCornersAB;
in vec4 spriteCornersCD;
in vec4 spriteRegion;
in vec4 spriteColor;
uniform mat4 modelViewProjection;
out vec2 texCoord;
out vec4 color;

void main() {
	// The corner this vertex is, 0 to 3: the first, second and third corners then the first, third and fourth make the two triangles.
	int c = int(spriteCorner + 0.5);
	vec2 corner = c == 0 ? spriteCornersAB.xy : c == 1 ? spriteCornersAB.zw : c == 2 ? spriteCornersCD.xy : spriteCornersCD.zw;
	// The rectangle's u0, v0 at the first corner, u0, v1 at the second, u1, v1 at the third and u1, v0 at the fourth.
	texCoord = vec2(c < 2 ? spriteRegion.x : spriteRegion.z, c == 0 || c == 3 ? spriteRegion.y : spriteRegion.w);
	color = spriteColor;
	gl_Position = modelViewProjection * vec4(corner, 0.0, 1.0);
}
