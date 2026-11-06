package helix.render;

#if !macro
import helix.geometry.Camera2D;
import helix.math.Matrix2D;
import helix.platform.Blend;
import helix.services.shaders.ShaderValues;
import helix.math.Bounds2D;
import helix.math.Matrix3D;
import helix.platform.Sampling;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderSampler;
import helix.services.shaders.ShaderSnapshot;
import helix.services.shaders.ShaderUniform;
import helix.services.shaders.ShaderVertexLayout;
import helix.render.RenderPass.RenderCommand;
#end

/** Provides 2D drawing: sprites, shapes and text, in a camera's world units or the viewport's pixels, through as few GPU draws as their
	order allows.

	A program constructs one over its `Renderer`, and between `Renderer.beginFrame` and `endFrame` draws between `begin` or `beginCamera`
	and `end`. Units are the viewport's pixels from its top left, y down, after `begin`, or a camera's world units after `beginCamera`. Angles are radians, a positive one
	turning clockwise on screen. Colors are 0xAARRGGBB, blended by their alpha.

	Colors and texels are sRGB values. Into an RGBA8 target or the screen they are drawn as they are stored: a tint multiplies them, and
	blending mixes them, as sRGB values, which is what 2D art is drawn expecting. Into an RGBA16F target, which holds linear light, they
	are decoded to linear as they are drawn, so they blend with the 3D drawn there and show as they would on the screen once the target
	is encoded. Nothing is tone mapped. A program's own shader (`shaderValues`) is given them as stored either way.

	**Draw state.** `transform`, `blend`, `shaderValues` and `customData` are read as each draw is made, and kept across `begin`s and
	frames, as raylib's rlgl state is: a value set holds until the program sets another, and `resetState` puts all four back.

	**Order and batching.** Draws are drawn in the order they are called; nothing is sorted, so what is drawn later is on top. Consecutive
	draws become one GPU draw while they share a texture, the shader values with nothing written to them between, a blend mode, the
	renderer's clip, and a kind. A quad of one color is one kind: a texture, a sprite, a glyph or a filled rectangle, kept as one record
	and drawn as an instance of one quad. Every other draw is the other kind, made of triangles: lines, outlines, the other shapes and
	`drawTriangles`. While `shaderValues` is set, every draw is made of triangles. A draw that differs in one of them starts the next GPU
	draw, and so do assigning `blend` or `shaderValues`, `Renderer.applyScissor`, and `end`. `transform` and `customData` split nothing:
	they are written into the records and vertices as each draw is made. Sprites, shapes and text of every kind of font are drawn by one
	fragment stage, so only their textures and kinds part them: shapes are drawn from `shapeRegion`, the batch's own white texture until
	set, so a white texel on a sheet (`Texture2D.writeWhiteTexel`) or a font's atlas lets its sprites or its text and the filled
	rectangles between them be one GPU draw.

	**Culling.** With `culling` on, read at each draw, a draw wholly outside the view is skipped: the box of a quad's corners (a turned
	sprite's turned) moved by `transform`, or a shape's or a text's lines' box so moved, against the camera's visible rectangle
	(`Camera2D.computeBounds`) or the viewport.
	`drawTriangles`, and every draw while `shaderValues` is set, aren't culled, as their vertices may be moved where the batch can't know.

	**A program's shader** (`shaderValues`) is compiled by `compileShader` (a fragment stage over the batch's vertex stage) or
	`compileShaderStages`. The batch fills, by name, what it declares. Both batches fill the same names, so one shader serves `Batch2D`
	and `Batch3D` alike (raylib's `LoadShader`, through `Batch3D.makeShaderExpr` and `Shader.withNames`); for a 2D draw they are:

	| Name | Type | What |
	|---|---|---|
	| `vertexPosition` | vec3 | The vertex, in the batch's units, moved by `transform`; z 0. |
	| `vertexTexCoord` | vec2 | The texture coordinates, 0 to 1 across the texture, v down. |
	| `vertexColor` | vec4 | The vertex's color times the tint, 0 to 1, as stored. |
	| `vertexCustomData` | vec4 | `customData` as the draw was made: its red, green, blue and alpha bytes, each 0 to 1. |
	| `vertexNormal` | vec3 | 0, 0, 1. |
	| `vertexCorner`, `vertexLineEnd` | vec2, vec3 | 0: the batch makes its lines and shapes as triangles itself. |
	| `baseColorTexture` | sampler2D | The sprite's texture, the font's atlas, the draw's texture, or `shapeRegion`'s for shapes. |
	| `fontKind` | int | The kind (helix-services' `FontKind`) of the font whose atlas the draw reads: 0 Coverage, 1 Bitmap, 2 Distance; 0 for any other texture. |
	| `model`, `normalMatrix` | mat4 | Identity: the batch moves the vertices itself. |
	| `modelViewProjection` | mat4 | The view's `viewProjection`. |
	| `baseColor` | vec4 | White: a 2D draw has no material. |
	| `clipPlanes`, `clipPlaneCount` | vec4[4], int | None: 0. |
	| `pointSize`, `pointSizeAttenuated` | float, int | 1 and 0. |

	With them the view's names (`View3D`: `viewProjection`, `linearTarget` and the rest), shared through `#include
	<helix/render/shaders/view.glsl>` or written per draw when declared alone. A name the program writes on its values is overwritten by the
	batch's. A name `Shader.withNames` gives is filled exactly as the same name declared in the GLSL, and the batch shares the `View`
	block with each draw itself, so the program sets no `ShaderValues.scene` (`Batch3D` says how). Colors are given as stored and
	nothing the shader writes is encoded after it, so it works in the space it chooses; `#include <helix/render/shaders/color.glsl>` gives the
	conversions (`View3D` lists them). The batch's vertex stage passes `texCoord` (vec2), `color` (vec4), `customData` (vec4), `normal`
	(vec3) and `worldPosition` (vec3), read by name in a fragment stage, as `Batch3D`'s does.

	```glsl
	// flash.frag: the sprite's texel and tint, and a flash the program sets
	#version 300 es
	precision highp float;
	in vec2 texCoord;
	in vec4 color;
	uniform sampler2D baseColorTexture;
	uniform vec4 flashColor;
	uniform float flash;
	out vec4 fragColor;
	void main() {
		vec4 texel = texture(baseColorTexture, texCoord) * color;
		fragColor = vec4(mix(texel.rgb, flashColor.rgb, flash), texel.a);
	}
	```
	```haxe
	var flashShader = Batch2D.compileShader("flash.frag");
	var flash = new ShaderValues(flashShader);
	flash.writeColor(flashShader.getUniform("flashColor"), 0xffffffff);
	// each frame:
	flash.writeFloat(flashShader.getUniform("flash"), hit ? 1 : 0);
	batch.shaderValues = flash;
	batch.drawSprite(enemy, x, y);
	batch.shaderValues = null;
	```

	Lines, outlines and shapes are made of triangles, as many as keep a curve's edge within a quarter of a pixel where it is drawn. A
	thickness is in the batch's units, centered on the edge or the line.

	```haxe
	var batch = new Batch2D(renderer);
	// each frame, between Renderer.beginFrame and endFrame:
	batch.beginCamera(camera);
	batch.drawSprite(player, x, y, angle); // turned about the region's origin
	batch.fillCircle(coinX, coinY, 6, 0xffffd700);
	batch.end();
	batch.begin(); // the HUD, in pixels
	batch.drawText(font, 'Score $score', 8, 8);
	batch.end();
	``` */
class Batch2D {
	#if !macro
	/** Gets the matrix the following draws are moved by, before the camera: identity until changed.

		It is changed in place (`batch.transform.makeIdentity().appendRotation(turn, batch.transform)`), and read as each draw is made. */
	public final transform = new Matrix2D();

	/** Gets or sets how the following draws are combined with what is under them: `Blend.ALPHA` until set; any factors and
		operations the platform's `Blend` takes (multiply, screen, premultiplied alpha). */
	public var blend(default, set):Blend = Blend.ALPHA;

	/** Gets or sets the program's own shader the following draws are drawn with, as values over it carrying its own uniforms and
		textures, or null for the batch's default: null until set.

		Its shader is compiled by `compileShader` or `compileShaderStages`, and reads the names the class lists. Its values are read as
		each draw is made. */
	public var shaderValues(default, set):Null<ShaderValues> = null;

	/** Gets or sets the region shapes, lines and outlines are drawn with: null until set, for the batch's own white texture.

		Shapes read the texel at the region's center alone, so it must be white there: `Texture2D.writeWhiteTexel` makes one on a sheet
		or an atlas, and its sprites and filled rectangles then share GPU draws, as raylib's `SetShapesTexture` lets them. Assigning it
		ends the open GPU draw. It is not draw state: `resetState` leaves it. */
	public var shapeRegion(default, set):Null<TextureRegion2D> = null;

	/** Gets or sets a value indicating whether draws out of view are skipped: true until set; read at each draw. */
	public var culling:Bool = true;

	/** Gets or sets four bytes each following vertex carries, for a program's shader to read as `customData`: a hit flash's amount, a
		palette row, a dissolve's threshold, a sprite's own value without a GPU draw of its own. 0xAARRGGBB, read as red, green, blue and
		alpha each 0 to 1; 0 until set. It is read as each draw is made and splits nothing; the batch's own shader ignores it. */
	public var customData:Int = 0;

	/** Gets a value indicating whether it is open: from `begin` or `beginCamera` until `end`. */
	public var open(default, null):Bool = false;

	/** Creates a batch over a renderer, with its default shader: textured and colored triangles, the texel times the color, which draw
		sprites, shapes and text.

		@param renderer  The renderer it records into. */
	public function new(renderer:Renderer) {
		this.renderer = renderer;
		shader = RenderShaders.compileOwn("batch2d.vert", "batch2d.frag");
		values = new ShaderValues(shader);
		modelViewProjection = shader.getUniform("modelViewProjection");
		linearTarget = shader.getUniform("linearTarget");
		fontKind = shader.getUniform("fontKind");
		baseColorTexture = shader.getSampler("baseColorTexture");
		if (layout == null)
			layout = new ShaderVertexLayout([
				{
					stride: 24,
					placements: [
						{name: "vertexPosition", offset: 0, format: Float2},
						{name: "vertexTexCoord", offset: 8, format: Float2},
						{name: "vertexColor", offset: 16, format: UByte4Norm}
					]
				}
			]);
		if (spriteLayout == null)
			spriteLayout = new ShaderVertexLayout([
				{stride: 4, placements: [{name: "spriteCorner", offset: 0}]},
				{
					stride: SPRITE_BYTES,
					instanced: true,
					placements: [
						{name: "spriteCornersAB", offset: 0},
						{name: "spriteCornersCD", offset: 16},
						{name: "spriteRegion", offset: 32},
						{name: "spriteColor", offset: 48, format: UByte4Norm},
						{
							name: "spriteCustomData",
							offset: 52,
							format: UByte4Norm,
							optional: true
						}
					]
				}
			]);
		stream = renderer.stream("batch2d", 24, layout);
		spriteShader = RenderShaders.compileOwn("batch2d-sprite.vert", "batch2d.frag");
		spriteValues = new ShaderValues(spriteShader);
		spriteModelViewProjection = spriteShader.getUniform("modelViewProjection");
		spriteLinearTarget = spriteShader.getUniform("linearTarget");
		spriteFontKind = spriteShader.getUniform("fontKind");
		spriteBaseColorTexture = spriteShader.getSampler("baseColorTexture");
		sprites = renderer.stream("batch2d-sprites", SPRITE_BYTES, spriteLayout);
		plane = new PlaneDrawing2D(use, vertex, visible);
		plane.plainQuad = sprite;
	}

	function set_blend(value:Blend):Blend {
		if (open && value != blend)
			flush();
		return blend = value;
	}

	function set_shapeRegion(value:Null<TextureRegion2D>):Null<TextureRegion2D> {
		if (open)
			flush();
		plane.shapeRegion = value;
		return shapeRegion = value;
	}

	function set_shaderValues(value:Null<ShaderValues>):Null<ShaderValues> {
		if (open)
			flush();
		if (value != null && valuesUse == null)
			drawValues();
		return shaderValues = value;
	}

	/** Puts the draw state back to its defaults: `transform` identity, `blend` Alpha, no `shaderValues`, `customData` 0.

		It may be called at any time, open or not. `shapeRegion` and `culling` are left as they are. */
	public function resetState():Void {
		transform.makeIdentity();
		blend = Blend.ALPHA;
		if (open && shaderValues != null)
			flush();
		@:bypassAccessor shaderValues = null;
		customData = 0;
	}

	/** Opens the batch for drawing in the renderer's current pass, in the viewport's pixels from its top left, y down.

		The draw state is kept as the program left it. `beginCamera` draws in a camera's world units.
		@throws String  No frame being recorded, or a batch (this or another) already open. */
	public function begin():Void {
		var width = renderer.viewportWidth, height = renderer.viewportHeight;
		viewMatrix.makeIdentity();
		viewBounds.set(0, 0, width, height);
		zoom = 1;
		opened();
	}

	/** Opens the batch for drawing in the renderer's current pass, in a camera's world units.

		The camera is read now: changing it after takes effect at the next `begin` or `beginCamera`. The draw state is kept as the program
		left it.
		@param camera  The camera, whose view units are the viewport's pixels.
		@throws String  No frame being recorded, or a batch (this or another) already open. */
	public function beginCamera(camera:Camera2D):Void {
		var width = renderer.viewportWidth, height = renderer.viewportHeight;
		camera.computeViewMatrix(cameraMatrix).toMatrix3D(viewMatrix);
		camera.computeBounds(width, height, viewBounds);
		zoom = Math.abs(camera.zoom);
		opened();
	}

	// Opens the batch through viewMatrix, over the renderer's viewport.
	function opened():Void {
		renderer.opening(this, flush);
		open = true;
		opens++;
		var width = renderer.viewportWidth, height = renderer.viewportHeight;
		Matrix3D.fromOrthographic(0, width, height, 0, -1, 1, projectionMatrix);
		Matrix3D.compose(viewMatrix, projectionMatrix, viewProjection);
		linear = renderer.linearPass();
		renderer.command(Viewport(renderer.viewportX, renderer.viewportY, width, height));
	}

	/** Closes the batch, so another can open or the pass can end.

		@throws String  The batch isn't open. */
	public function end():Void {
		if (!open)
			throw "helix-render: Batch2D.end with the batch not open";
		flush();
		renderer.closing(this);
		open = false;
	}

	/** Draws a whole texture at its size, its top left at a point.

		@param texture  The texture.
		@param x  The left edge.
		@param y  The top edge.
		@param tint  Optional. The color its texels are multiplied by; defaults to white. */
	public function drawTexture(texture:Texture2D, x:Float, y:Float, tint:Int = 0xffffffff):Void {
		plane.textureRegion(texture, 0, 0, texture.width, texture.height, x, y, texture.width, texture.height, 0, 0, 0, tint);
	}

	/** Draws a rectangle of a texture into a rectangle, turned about an origin, as raylib's `DrawTexturePro` draws it: no region is
		made for it.

		A negative width or height of the part taken mirrors it that way.
		@param texture  The texture.
		@param regionX  The part's left edge, in texels from the texture's left.
		@param regionY  The part's top edge, in texels from the texture's top.
		@param regionWidth  The part's width, in texels; negative mirrors it left to right.
		@param regionHeight  The part's height, in texels; negative mirrors it top to bottom.
		@param x  Where the origin goes, across.
		@param y  Where the origin goes, down.
		@param width  The width it is drawn at, in the batch's units.
		@param height  The height it is drawn at, in the batch's units.
		@param rotation  Optional. The turn about the origin, in radians; defaults to 0.
		@param originX  Optional. The point it turns about and is placed by, in the batch's units from the drawn rectangle's left;
			defaults to 0.
		@param originY  Optional. That point, in the batch's units from the drawn rectangle's top; defaults to 0.
		@param tint  Optional. The color its texels are multiplied by; defaults to white. */
	public function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float,
			height:Float, rotation = 0., originX = 0., originY = 0., tint:Int = 0xffffffff):Void {
		plane.textureRegion(texture, regionX, regionY, regionWidth, regionHeight, x, y, width, height, rotation, originX, originY, tint);
	}

	/** Draws a texture's region, turned and scaled about its origin, the origin at a point.

		A negative scale flips the sprite about its origin: -1 across mirrors it left to right. `flipX` and `flipY` flip it the same way
		again, so they mirror a sprite whatever its scale: true with a scale of -1 draws it unflipped.
		@param region  The region of the texture.
		@param x  Where the origin goes, across.
		@param y  Where the origin goes, down.
		@param rotation  Optional. The turn about the origin, in radians; defaults to 0.
		@param scaleX  Optional. The scale across; defaults to 1, the region's size in texels.
		@param scaleY  Optional. The scale down; defaults to 1.
		@param tint  Optional. The color its texels are multiplied by; defaults to white.
		@param flipX  Optional. Whether it is mirrored left to right about its origin, after its scale; defaults to false.
		@param flipY  Optional. Whether it is mirrored top to bottom about its origin, after its scale; defaults to false.
		@param originX  Optional. The point it turns about and is placed by, in texels from the region's left; the region's `originX` when
			omitted.
		@param originY  Optional. That point, in texels from the region's top; the region's `originY` when omitted. */
	public function drawSprite(region:TextureRegion2D, x:Float, y:Float, rotation = 0., scaleX = 1., scaleY = 1., tint:Int = 0xffffffff, flipX = false,
			flipY = false, ?originX:Float, ?originY:Float):Void {
		plane.sprite(region, x, y, rotation, scaleX, scaleY, tint, flipX, flipY, originX, originY);
	}

	/** Draws a line between two points.

		@param x0  The start, across.
		@param y0  The start, down.
		@param x1  The end, across.
		@param y1  The end, down.
		@param thickness  The width, in the batch's units; its ends are square, cut at the points.
		@param color  The color. */
	public function drawLine(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Float, color:Int):Void {
		plane.line(x0, y0, x1, y1, thickness, color);
	}

	/** Draws lines through points, one after another, joined at each point with a miter, or a bevel where the miter would reach past twice
		the thickness.

		@param points  The points, x and y each; fewer than two draws nothing.
		@param thickness  The width, in the batch's units.
		@param color  The color. */
	public function drawPolyline(points:Array<Float>, thickness:Float, color:Int):Void {
		plane.polyline(points, thickness, color, false);
	}

	/** Fills a triangle.

		@param x0  The first corner, across.
		@param y0  The first corner, down.
		@param x1  The second corner, across.
		@param y1  The second corner, down.
		@param x2  The third corner, across.
		@param y2  The third corner, down.
		@param color  The color. */
	public function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int):Void {
		plane.triangle(x0, y0, x1, y1, x2, y2, color);
	}

	/** Fills a rectangle.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	public function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int):Void {
		plane.rectangle(x, y, width, height, color);
	}

	/** Draws a rectangle's outline.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int):Void {
		plane.strokeRectangle(x, y, width, height, thickness, color);
	}

	/** Fills a rectangle with rounded corners.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param color  The color. */
	public function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int):Void {
		plane.roundedRectangle(x, y, width, height, radius, color);
	}

	/** Draws the outline of a rectangle with rounded corners.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int):Void {
		plane.strokeRoundedRectangle(x, y, width, height, radius, thickness, color);
	}

	/** Fills a circle.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param color  The color. */
	public function fillCircle(x:Float, y:Float, radius:Float, color:Int):Void {
		plane.ellipse(x, y, radius, radius, color);
	}

	/** Draws a circle's outline.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param thickness  The outline's width, centered on the circle.
		@param color  The color. */
	public function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int):Void {
		plane.strokeEllipse(x, y, radius, radius, thickness, color);
	}

	/** Fills an ellipse whose axes run across and down.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param color  The color. */
	public function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int):Void {
		plane.ellipse(x, y, radiusX, radiusY, color);
	}

	/** Draws an ellipse's outline.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param thickness  The outline's width, centered on the ellipse.
		@param color  The color. */
	public function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int):Void {
		plane.strokeEllipse(x, y, radiusX, radiusY, thickness, color);
	}

	/** Fills a polygon, convex or not, whose edges don't cross.

		@param points  The corners in order, x and y each, either way round; fewer than three draws nothing.
		@param color  The color.
		@return  False when its edges cross, and nothing is drawn. */
	public function fillPolygon(points:Array<Float>, color:Int):Bool {
		requireOpen();
		return plane.polygon(points, color);
	}

	/** Draws a polygon's outline: lines through its corners and back to the first, joined as `drawPolyline` joins them.

		@param points  The corners in order, x and y each; fewer than two draws nothing.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokePolygon(points:Array<Float>, thickness:Float, color:Int):Void {
		plane.polyline(points, thickness, color, true);
	}

	/** Draws triangles as given: textured, colored by vertex, or both, for what the shapes here don't make.

		The arrays are read during the call, so they may be reused for the next.
		@param texture  The texture, or null for white.
		@param positions  The vertices' positions, x and y each.
		@param texCoords  Optional. The texture coordinates, u and v each, 0 to 1 across the texture; 0, 0 for every vertex when omitted.
		@param colors  Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
		@param indices  Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order. */
	public function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>):Void {
		requireOpen();
		plane.triangles(texture, positions, texCoords, colors, indices);
	}

	/** Draws text in a font, line by line at each line break, left-aligned, its first line's top at a point.

		A distance-field font stays sharp at any size; another is scaled from its atlas. Pairs of characters are kerned as the font gives
		them, unless `kerned` is false.
		@param font  The font.
		@param text  The text; a character the font lacks is drawn as the font's stand-in, as `GpuFont2D` says.
		@param x  The left edge.
		@param y  The top of the first line: its ascent above the baseline.
		@param color  Optional. The color; defaults to white.
		@param size  Optional. The size, in the batch's units, as the font's size is measured; the font's own when omitted.
		@param letterSpacing  Optional. Space added after each character, in the batch's units, as raylib's `spacing`; defaults to 0.
		@param kerned  Optional. Whether pairs of characters are kerned as the font gives them; defaults to true. raylib's `DrawTextEx`
			doesn't kern. */
	public function drawText(font:GpuFont2D, text:String, x:Float, y:Float, color:Int = 0xffffffff, ?size:Float, letterSpacing = 0., kerned = true):Void {
		plane.text(font, text, x, y, color, size, letterSpacing, kerned);
	}

	/** Draws laid-out text, wrapped and aligned as its layout says, the layout's top left at a point.

		@param layout  The layout.
		@param x  The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest
			line when `maxWidth` is 0.
		@param y  The top of the first line.
		@param color  Optional. The color; defaults to white. */
	public function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, color:Int = 0xffffffff):Void {
		plane.layout(layout, x, y, color);
	}

	/** Replays a draw list: its calls in the order recorded, in its own units placed by a transform, then by `transform` and the camera.

		With `culling` on, a list whose box (`DrawList2D.bounds`), so placed, is wholly out of view is skipped whole; a list drawn while
		`shaderValues` is set isn't culled. Its calls are drawn with the batch's `blend`, `shaderValues` and `customData` as they are now.
		@param list  The list.
		@param placement  Optional. Its place in the batch's units; identity when omitted.
		@throws String  A texture it holds disposed. */
	public function drawList(list:DrawList2D, ?placement:Matrix2D):Void {
		requireOpen();
		if (placement != null && list.bounds.isEmpty == false) {
			var b = list.bounds, p = placement;
			var x0 = p.a * b.minX + p.c * b.minY + p.tx,
				y0 = p.b * b.minX + p.d * b.minY + p.ty;
			var x1 = p.a * b.maxX + p.c * b.minY + p.tx,
				y1 = p.b * b.maxX + p.d * b.minY + p.ty;
			var x2 = p.a * b.maxX + p.c * b.maxY + p.tx,
				y2 = p.b * b.maxX + p.d * b.maxY + p.ty;
			var x3 = p.a * b.minX + p.c * b.maxY + p.tx,
				y3 = p.b * b.minX + p.d * b.maxY + p.ty;
			if (!visible(Math.min(Math.min(x0, x1), Math.min(x2, x3)), Math.min(Math.min(y0, y1), Math.min(y2, y3)),
				Math.max(Math.max(x0, x1), Math.max(x2, x3)), Math.max(Math.max(y0, y1), Math.max(y2, y3))))
				return;
		} else if (!list.bounds.isEmpty && !visible(list.bounds.minX, list.bounds.minY, list.bounds.maxX, list.bounds.maxY))
			return;
		var held = new Matrix2D().copyFrom(transform);
		if (placement != null)
			Matrix2D.compose(placement, held, transform);
		try {
			list.replay(this);
		} catch (e:Dynamic) {
			transform.copyFrom(held);
			throw e;
		}
		transform.copyFrom(held);
	}

	// The renderer, the default shader, the values its draws are filled on and the names it fills, the stream the vertices go in.
	final renderer:Renderer;
	final shader:Shader;
	final values:ShaderValues;
	final modelViewProjection:ShaderUniform;
	final linearTarget:ShaderUniform;
	final fontKind:ShaderUniform;
	final baseColorTexture:ShaderSampler;
	final stream:RenderStream;
	final plane:PlaneDrawing2D;
	// The sprite path: the shader drawing a quad a record, its values and the names it fills, the stream of records, and the quad they
	// are instances of, its four corner numbers and six indices (0 until the first run of sprites is drawn).
	final spriteShader:Shader;
	final spriteValues:ShaderValues;
	final spriteModelViewProjection:ShaderUniform;
	final spriteLinearTarget:ShaderUniform;
	final spriteFontKind:ShaderUniform;
	final spriteBaseColorTexture:ShaderSampler;
	final sprites:RenderStream;
	var quadCorners = 0;
	var quadIndices = 0;
	#if js
	// The records' bytes, and their floats and ints written through views rather than Bytes' calls; remade when the stream grows.
	var spriteBytes:Null<haxe.io.Bytes> = null;
	var spriteFloats:Null<js.lib.Float32Array> = null;
	var spriteInts:Null<js.lib.Int32Array> = null;
	#end
	// The GPU draw being made: whether it holds nothing yet, vertices or sprites, its first vertex or record, texture, sampling, font kind
	// and the program's values.
	var running = false;
	var runKind = EMPTY;
	var runFirst = 0;
	var runTexture = 0;
	var runSampling = Sampling.LINEAR;
	var runFontKind = 0;
	var runValues:Null<ShaderValues> = null;
	// What is in view, in the batch's units before the transform; the camera's zoom; the view and projection, whether the pass holds
	// linear light, and the number of opens.
	final viewBounds = new Bounds2D();
	var zoom = 1.;
	final viewMatrix = new Matrix3D();
	final projectionMatrix = new Matrix3D();
	final viewProjection = new Matrix3D();
	var linear = false;
	var opens = 0;
	// The program's shaders' draws (shaderValues), made by drawValues at the first shaderValues set, so a program that never sets one
	// links none of it: at use, the values captured and compared with the run's; at the run's start, its captured values kept; at
	// flush, the draw recorded.
	var valuesUse:Null<ShaderValues->Void> = null;
	var valuesStart:Null<Void->Void> = null;
	var valuesFlush:Null<(Int, Int) -> Void> = null;

	static final cameraMatrix = new Matrix2D();
	static final identity = new Matrix3D();
	// The default shader's vertices: x and y, u and v as floats, the color as four bytes, and customData's four bytes it doesn't read.
	static var layout:Null<ShaderVertexLayout> = null;
	// The sprite stage's buffers: the quad's corner numbers, and the records, each the four corners' x and y and the texture's u0, v0,
	// u1 and v1 as floats, the color's four bytes and customData's.
	static var spriteLayout:Null<ShaderVertexLayout> = null;

	static inline final SPRITE_BYTES = 56;
	// What the GPU draw being made holds: nothing yet, vertices, or sprites.
	static inline final EMPTY = 0;
	static inline final VERTICES = 1;
	static inline final SPRITES = 2;

	function requireOpen():Void
		if (!open)
			throw "helix-render: a Batch2D draw outside begin and end";

	// Makes the following vertices read a texture: a texture, sampling or font kind other than the GPU draw's, or values written since,
	// starts the next GPU draw.
	function use(texture:Null<Texture2D>, fontKind:Int):Void {
		requireOpen();
		var t = texture == null ? renderer.white : texture;
		var handle = t.drawnHandle(), sampling = t.sampling;
		renderer.checkReadable(handle);
		var values = shaderValues;
		if (values != null)
			valuesUse(values);
		if (running && (handle != runTexture || sampling != runSampling || fontKind != runFontKind))
			flush();
		if (!running) {
			running = true;
			runKind = EMPTY;
			runTexture = handle;
			runSampling = sampling;
			runFontKind = fontKind;
			runValues = values;
			if (values != null)
				valuesStart();
		}
	}

	// Makes the program's shaders' draws: the View block written for them, shared through its scene, at their first draw after each
	// open; each shader's names the batch fills, the attributes the vertices don't carry read as the renderer's constants; and the
	// values a draw reads, captured and compared, so values written since start the next GPU draw.
	function drawValues():Void {
		var view = new RenderView(RenderShaders.compileOwn("batch3d.vert", "batch3d.frag"));
		var fills = new haxe.ds.ObjectMap<Shader, RenderFill>();
		var runCapture = new ShaderSnapshot(),
			nextCapture = new ShaderSnapshot();
		var writtenAt = -1;
		var programLayout = new ShaderVertexLayout([
			{
				stride: 24,
				placements: [
					{name: "vertexPosition", offset: 0, format: Float2},
					{
						name: "vertexTexCoord",
						offset: 8,
						format: Float2,
						optional: true
					},
					{
						name: "vertexColor",
						offset: 16,
						format: UByte4Norm,
						optional: true
					},
					{
						name: "vertexCustomData",
						offset: 20,
						format: UByte4Norm,
						optional: true
					}
				]
			}
		], Renderer.unfedAttributes);
		function fillFor(s:Shader):RenderFill {
			var f = fills.get(s);
			if (f == null)
				fills.set(s, f = new RenderFill(s));
			if (writtenAt != opens) {
				writtenAt = opens;
				view.set(viewMatrix, projectionMatrix, renderer.viewportX, renderer.viewportY, renderer.viewportWidth, renderer.viewportHeight);
				view.setLook(linear, 0, None, null);
				view.write();
			}
			return f;
		}
		valuesUse = values -> {
			// The program's values as a draw reads them: through the draw's own values, the view's block shared.
			var probe = fillFor(values.shader).values;
			probe.base = values;
			probe.scene = view.scene;
			probe.capture(nextCapture);
			if (running && !sameValues(nextCapture, runCapture))
				flush();
		};
		valuesStart = () -> {
			var swap = runCapture;
			runCapture = nextCapture;
			nextCapture = swap;
		};
		valuesFlush = (first, count) -> {
			var s = runValues.shader;
			var fill = fillFor(s);
			fill.values.base = runValues;
			fill.values.scene = view.scene;
			fill.texture(fill.baseColorTexture, runTexture, runSampling);
			fill.integer(fill.fontKind, runFontKind);
			fill.matrix(fill.model, identity);
			fill.matrix(fill.normalMatrix, identity);
			fill.matrix(fill.modelViewProjection, view.viewProjection);
			fill.color(fill.baseColor, 0xffffffff);
			fill.float(fill.lineWidth, 1);
			fill.float(fill.pointSize, 1);
			fill.integer(fill.pointSizeAttenuated, 0);
			fill.integer(fill.clipPlaneCount, 0);
			fill.integer(fill.fogged, 0);
			fill.integer(fill.toneMapped, 0);
			fill.view(view);
			var d = renderer.makeDraw(renderer.pipelineFor(s, renderer.stateFor(Triangles, false, blend, Off, false, None, All), programLayout));
			d.setBuffer(0, 0, stream);
			d.first = first;
			d.count = count;
			fill.values.capture(d.snapshot);
			renderer.record(d);
		};
	}

	// Whether two captures of values hold the same bytes and textures.
	static function sameValues(a:ShaderSnapshot, b:ShaderSnapshot):Bool {
		if (a.uniforms.length != b.uniforms.length || a.textures.length != b.textures.length)
			return false;
		for (i in 0...a.textures.length)
			if (a.textures[i] != b.textures[i] || a.samplings[i] != b.samplings[i])
				return false;
		for (i in 0...a.uniforms.length) {
			var x = a.uniforms[i], y = b.uniforms[i];
			if (x == null || y == null) {
				if (x != y)
					return false;
				continue;
			}
			if (x.length != y.length || x.compare(y) != 0)
				return false;
		}
		return true;
	}

	// A vertex in the batch's units, moved by the transform.
	function vertex(x:Float, y:Float, u:Float, v:Float, color:Int):Void {
		if (runKind != VERTICES)
			startKind(VERTICES);
		var t = transform;
		var at = stream.reserve(1), b = stream.bytes;
		b.setFloat(at, t.a * x + t.c * y + t.tx);
		b.setFloat(at + 4, t.b * x + t.d * y + t.ty);
		b.setFloat(at + 8, u);
		b.setFloat(at + 12, v);
		b.set(at + 16, color >> 16 & 255);
		b.set(at + 17, color >> 8 & 255);
		b.set(at + 18, color & 255);
		b.set(at + 19, color >>> 24);
		var d = customData;
		b.set(at + 20, d >> 16 & 255);
		b.set(at + 21, d >> 8 & 255);
		b.set(at + 22, d & 255);
		b.set(at + 23, d >>> 24);
	}

	// Makes the GPU draw being made hold vertices or sprites: one holding the other kind is recorded, and the next, of the same texture
	// and values, starts where the kind's stream is.
	function startKind(kind:Int):Void {
		if (runKind != EMPTY)
			record();
		runKind = kind;
		runFirst = kind == SPRITES ? sprites.count : stream.count;
	}

	// A quad of one color as a sprite's record, its corners moved by the transform, skipped when culled wholly out of view; false while
	// shaderValues is set, whose shader's vertex stage reads vertices.
	function sprite(texture:Null<Texture2D>, fontKind:Int, x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, u0:Float, v0:Float,
			u1:Float, v1:Float, color:Int, cull:Bool):Bool {
		if (shaderValues != null)
			return false;
		requireOpen();
		var t = transform;
		var ax = t.a * x0 + t.c * y0 + t.tx, ay = t.b * x0 + t.d * y0 + t.ty;
		var bx = t.a * x1 + t.c * y1 + t.tx, by = t.b * x1 + t.d * y1 + t.ty;
		var cx = t.a * x2 + t.c * y2 + t.tx, cy = t.b * x2 + t.d * y2 + t.ty;
		var dx = t.a * x3 + t.c * y3 + t.tx, dy = t.b * x3 + t.d * y3 + t.ty;
		if (cull && culling) {
			// The corners' box, as moved, against the view.
			var b = viewBounds;
			var low = ax < bx ? ax : bx, high = ax < bx ? bx : ax;
			if (cx < low)
				low = cx;
			if (cx > high)
				high = cx;
			if (dx < low)
				low = dx;
			if (dx > high)
				high = dx;
			if (high < b.minX || low > b.maxX)
				return true;
			low = ay < by ? ay : by;
			high = ay < by ? by : ay;
			if (cy < low)
				low = cy;
			if (cy > high)
				high = cy;
			if (dy < low)
				low = dy;
			if (dy > high)
				high = dy;
			if (high < b.minY || low > b.maxY)
				return true;
		}
		use(texture, fontKind);
		if (runKind != SPRITES)
			startKind(SPRITES);
		var s = sprites;
		var at = s.reserve(1);
		#if js
		if (s.bytes != spriteBytes) {
			spriteBytes = s.bytes;
			spriteFloats = new js.lib.Float32Array(s.bytes.getData());
			spriteInts = new js.lib.Int32Array(s.bytes.getData());
		}
		#end
		putSprite(at, ax);
		putSprite(at + 4, ay);
		putSprite(at + 8, bx);
		putSprite(at + 12, by);
		putSprite(at + 16, cx);
		putSprite(at + 20, cy);
		putSprite(at + 24, dx);
		putSprite(at + 28, dy);
		putSprite(at + 32, u0);
		putSprite(at + 36, v0);
		putSprite(at + 40, u1);
		putSprite(at + 44, v1);
		// 0xAARRGGBB as its red, green, blue and alpha bytes in order, one little-endian int.
		putSpriteInt(at + 48, (color & 0xff00ff00) | (color >> 16 & 255) | (color & 255) << 16);
		var d = customData;
		putSpriteInt(at + 52, (d & 0xff00ff00) | (d >> 16 & 255) | (d & 255) << 16);
		return true;
	}

	// Writes a float into the sprites' records: natively without Bytes.setFloat's bounds check and call, in a page through the float view.
	inline function putSprite(at:Int, value:Float):Void {
		#if cpp
		untyped __global__.__hxcpp_memory_set_float(sprites.bytes.getData(), at, value);
		#elseif js
		spriteFloats[at >> 2] = value;
		#else
		sprites.bytes.setFloat(at, value);
		#end
	}

	// Writes a little-endian int into the sprites' records, as putSprite writes a float.
	inline function putSpriteInt(at:Int, value:Int):Void {
		#if cpp
		untyped __global__.__hxcpp_memory_set_i32(sprites.bytes.getData(), at, value);
		#elseif js
		spriteInts[at >> 2] = value;
		#else
		sprites.bytes.setInt32(at, value);
		#end
	}

	// Whether a box in the batch's units, moved by the transform, may be seen; always while culling is off or shaderValues set.
	function visible(minX:Float, minY:Float, maxX:Float, maxY:Float):Bool {
		requireOpen();
		plane.scale = zoom * Math.sqrt(Math.abs(transform.a * transform.d - transform.b * transform.c));
		if (!culling || shaderValues != null)
			return true;
		var t = transform, b = viewBounds;
		if (t.b == 0 && t.c == 0) {
			// Unturned: the box's two edges each way, moved.
			var x0 = t.a * minX + t.tx, x1 = t.a * maxX + t.tx;
			var y0 = t.d * minY + t.ty, y1 = t.d * maxY + t.ty;
			return !((x0 > x1 ? x0 : x1) < b.minX
				|| (x0 < x1 ? x0 : x1) > b.maxX || (y0 > y1 ? y0 : y1) < b.minY || (y0 < y1 ? y0 : y1) > b.maxY);
		}
		var x0 = t.a * minX + t.c * minY + t.tx,
			y0 = t.b * minX + t.d * minY + t.ty;
		var x1 = t.a * maxX + t.c * minY + t.tx,
			y1 = t.b * maxX + t.d * minY + t.ty;
		var x2 = t.a * maxX + t.c * maxY + t.tx,
			y2 = t.b * maxX + t.d * maxY + t.ty;
		var x3 = t.a * minX + t.c * maxY + t.tx,
			y3 = t.b * minX + t.d * maxY + t.ty;
		return !(Math.max(Math.max(x0, x1), Math.max(x2, x3)) < b.minX
			|| Math.min(Math.min(x0, x1), Math.min(x2, x3)) > b.maxX
			|| Math.max(Math.max(y0, y1), Math.max(y2, y3)) < b.minY
			|| Math.min(Math.min(y0, y1), Math.min(y2, y3)) > b.maxY);
	}

	// Ends the GPU draw being made, recording it.
	function flush():Void {
		if (!running)
			return;
		running = false;
		record();
	}

	// Records the GPU draw being made, with the names the batch fills: its vertices, or its sprites as instances of one quad.
	function record():Void {
		if (runKind == SPRITES) {
			recordSprites();
			return;
		}
		if (runKind == EMPTY)
			return;
		var count = stream.count - runFirst;
		if (count <= 0)
			return;
		if (runValues != null) {
			valuesFlush(runFirst, count);
			return;
		}
		values.writeTexture(baseColorTexture, runTexture, runSampling);
		values.writeMatrix(modelViewProjection, viewProjection);
		values.writeInt(linearTarget, linear ? 1 : 0);
		values.writeInt(fontKind, runFontKind);
		var d = renderer.makeDraw(renderer.pipelineFor(shader, renderer.stateFor(Triangles, false, blend, Off, false, None, All), layout));
		d.setBuffer(0, 0, stream);
		d.first = runFirst;
		d.count = count;
		values.capture(d.snapshot);
		renderer.record(d);
	}

	// Records the run of sprites being made: instances of one quad, a record each, through the sprite stage.
	function recordSprites():Void {
		var count = sprites.count - runFirst;
		if (count <= 0)
			return;
		if (quadCorners == 0) {
			var corners = haxe.io.Bytes.alloc(16);
			for (c in 0...4)
				corners.setFloat(c * 4, c);
			quadCorners = renderer.staticBuffer(corners, false);
			var indices = haxe.io.Bytes.alloc(24);
			for (k => i in [0, 1, 2, 0, 2, 3])
				indices.setInt32(k * 4, i);
			quadIndices = renderer.staticBuffer(indices, true);
		}
		spriteValues.writeTexture(spriteBaseColorTexture, runTexture, runSampling);
		spriteValues.writeMatrix(spriteModelViewProjection, viewProjection);
		spriteValues.writeInt(spriteLinearTarget, linear ? 1 : 0);
		spriteValues.writeInt(spriteFontKind, runFontKind);
		var d = renderer.makeDraw(renderer.pipelineFor(spriteShader, renderer.stateFor(Triangles, true, blend, Off, false, None, All), spriteLayout));
		d.setBuffer(0, quadCorners);
		d.setBuffer(1, 0, sprites);
		d.indexBuffer = quadIndices;
		d.first = 0;
		d.count = 6;
		d.firstInstance = runFirst;
		d.instanceCount = count;
		spriteValues.capture(d.snapshot);
		renderer.record(d);
	}
	#end

	/** Compiles a fragment stage over the batch's vertex stage, for a `Batch2D`'s draws (`shaderValues`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or
		`#version 450` (Vulkan's), the batch's vertex stage given in the same form; GLSL ES 100 (raylib's) is not taken, and a layer
		adapts it first. The vertex stage passes `texCoord` (vec2), `color` (vec4) and `customData` (vec4), read by name.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShader(fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		return helix.render.RenderShaders.fragmentOver("batch.vert", fragment, options);
	}

	/** Compiles a vertex and a fragment stage, both the program's, for a `Batch2D`'s draws (`shaderValues`).

		It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its
		vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw
		one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class
		lists declared with another type stops the build at the call.
		Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or
		`#version 450`. The batch makes its lines and shapes as triangles itself, so the vertex stage need only place each vertex and
		write what its fragment stage reads; `#include <helix/render/shaders/batch.glsl>` declares the names and outputs `Batch3D` lists, and its
		`placeBatchVertex(vertexPosition, vertexLineEnd)` does both, as for `Batch3D`.
		@param vertex  The vertex stage's file, relative to the file holding the call.
		@param fragment  The fragment stage's file, relative to the file holding the call.
		@param options  Optional. Defines, includes and a file to watch.
		@return  The shader, for a `ShaderValues` over it. */
	public static macro function compileShaderStages(vertex:String, fragment:String,
			?options:haxe.macro.Expr.ExprOf<helix.services.shaders.ShaderOptions>):haxe.macro.Expr.ExprOf<helix.services.shaders.Shader> {
		return helix.render.RenderShaders.stages(vertex, fragment, options);
	}
}
