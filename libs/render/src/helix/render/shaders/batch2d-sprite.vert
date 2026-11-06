#version 300 es
// Batch2D's sprite vertex stage: a run of quads of one texture drawn as instances of one quad, each instance a record of its four
// corners in order round it (already moved by the batch's transform), its texture's rectangle, its color and the batch's custom data
// (56 bytes), where the vertex stage reads six 24-byte vertices. Its texture coordinates and color are passed on as batch2d.vert
// passes them, so batch2d.frag draws both.
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
	// The rectangle's u0, v0 at the first corner, u1, v0 at the second, u1, v1 at the third and u0, v1 at the fourth.
	texCoord = vec2(c == 1 || c == 2 ? spriteRegion.z : spriteRegion.x, c < 2 ? spriteRegion.y : spriteRegion.w);
	color = spriteColor;
	gl_Position = modelViewProjection * vec4(corner, 0.0, 1.0);
}
