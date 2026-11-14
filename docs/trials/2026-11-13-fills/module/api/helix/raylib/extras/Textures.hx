package helix.raylib.extras;

/** Provides texture draws beyond raylib's, helix-raylib's own: fills (a bar, a beaker, a mana ball or a cooldown shown up to an
	amount), tiled draws, nine-patches whose edges repeat, textured polygons, atlases read from a packer's file, and a render texture
	fitted to the window. Imported apart: `import helix.raylib.extras.Textures.*;`, and the atlas's type apart:
	`import helix.raylib.extras.TextureAtlas;`.

	```haxe
	// A mana ball: the glass, the liquid up to the mana, the froth on its surface.
	DrawTexturePro(glass, new Rectangle(0, 0, 64, 64), ballRectangle, new Vector2(0, 0), 0, WHITE);
	DrawTextureFill(liquid, new Rectangle(0, 0, 64, 64), ballRectangle, mana, TEXTURE_FILL_BOTTOM_TO_TOP, WHITE);
	var edge = GetTextureFillEdge(ballRectangle, mana, TEXTURE_FILL_BOTTOM_TO_TOP);
	DrawTexture(froth, Std.int(edge.x - froth.width / 2), Std.int(edge.y - froth.height / 2), WHITE);
	```

	A fill is drawn at its full size and shown up to the amount, never stretched to it, so its ends keep their shape. For a fill of one
	color, raylib's `DrawRectangle`, `DrawCircleSector` and `DrawRing` draw it, and `GetTextureFillEdge` finds its edge all the same. */
class Textures {
	/** Fills from the left edge to the right. */
	public static inline final TEXTURE_FILL_LEFT_TO_RIGHT = 0;

	/** Fills from the right edge to the left. */
	public static inline final TEXTURE_FILL_RIGHT_TO_LEFT = 1;

	/** Fills from the top edge down. */
	public static inline final TEXTURE_FILL_TOP_TO_BOTTOM = 2;

	/** Fills from the bottom edge up. */
	public static inline final TEXTURE_FILL_BOTTOM_TO_TOP = 3;

	/** Fills clockwise about the middle, as a clock's hand sweeps. */
	public static inline final TEXTURE_FILL_CLOCKWISE = 4;

	/** Fills counterclockwise about the middle. */
	public static inline final TEXTURE_FILL_COUNTER_CLOCKWISE = 5;

	/** A nine-patch's middle and edges are stretched along an axis, as raylib's `DrawTextureNPatch` draws them. */
	public static inline final NPATCH_MODE_STRETCH = 0;

	/** A nine-patch's middle and edges are repeated at the texture's size along an axis, the last tile cut where it reaches the far
		side. */
	public static inline final NPATCH_MODE_TILE = 1;

	/** A nine-patch's middle and edges are repeated a whole number of times along an axis, each tile scaled a little to fit exactly. */
	public static inline final NPATCH_MODE_TILE_FIT = 2;

	/** Draws part of a texture as a fill: drawn at dest's size and shown up to the amount, in the direction. A radial fill turns
		about dest's middle, starts straight up and sweeps the whole circle. See `DrawTextureFillEx` for a radial fill's origin, start and
		sweep.

		@param texture  The texture.
		@param source  The part of the texture, in pixels.
		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param tint  The tint. */
	public static function DrawTextureFill(texture:Texture2D, source:Rectangle, dest:Rectangle, amount:Float, fillDirection:Int, tint:Color):Void {}

	/** Draws part of a texture as a fill, as `DrawTextureFill` does, a radial fill turning about an
		origin, starting at an angle and sweeping part of the circle: a gauge's half circle about its hub, say. A fill across or down ignores
		the origin and the angles.

		@param texture  The texture.
		@param source  The part of the texture, in pixels.
		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param origin  The point a radial fill turns about, from dest's top-left, in pixels, as `DrawTexturePro`'s origin.
		@param startAngle  Where a radial fill starts, in degrees clockwise from straight up, wrapped to [0, 360).
		@param fillDegrees  How far a full radial fill sweeps, in degrees, clamped to [0, 360].
		@param tint  The tint. */
	public static function DrawTextureFillEx(texture:Texture2D, source:Rectangle, dest:Rectangle, amount:Float, fillDirection:Int, origin:Vector2,
		startAngle:Float, fillDegrees:Float, tint:Color):Void {}

	/** Returns the middle of a fill's moving edge, for drawing something there: froth on a liquid, a thermometer's tip, a needle.
		At an amount of 0 the edge is at the fill's start, and at 1 at its far end. A radial fill's edge runs out from the point the fill
		turns about: x and y are that point, and z the edge's angle, in degrees clockwise from straight up. See `GetTextureFillEdgeEx`
		for a radial fill's origin, start and sweep.

		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param out  Optional. The vector to fill, or null for a new one.
		@return  out, or the new vector: x and y in screen pixels, as dest's, z a radial fill's angle and 0 for the others. */
	public static function GetTextureFillEdge(dest:Rectangle, amount:Float, fillDirection:Int, ?out:Vector3):Vector3
		return out == null ? new Vector3(0, 0, 0) : out;

	/** Returns the middle of a fill's moving edge, as `GetTextureFillEdge` does, for a radial fill turning about an origin, starting
		at an angle and sweeping part of the circle.

		@param dest  Where the fill is drawn, in pixels.
		@param amount  How full, clamped to [0, 1].
		@param fillDirection  A `TEXTURE_FILL_` value.
		@param origin  The point a radial fill turns about, from dest's top-left, in pixels, as `DrawTexturePro`'s origin.
		@param startAngle  Where a radial fill starts, in degrees clockwise from straight up, wrapped to [0, 360).
		@param fillDegrees  How far a full radial fill sweeps, in degrees, clamped to [0, 360].
		@param out  Optional. The vector to fill, or null for a new one.
		@return  out, or the new vector. */
	public static function GetTextureFillEdgeEx(dest:Rectangle, amount:Float, fillDirection:Int, origin:Vector2, startAngle:Float, fillDegrees:Float,
			?out:Vector3):Vector3
		return out == null ? new Vector3(0, 0, 0) : out;

	/** Draws part of a texture repeated across dest, the last copies cut where they reach dest's far sides, as raylib's
		`DrawTexturePro` draws one copy.

		@param texture  The texture.
		@param source  The part of the texture repeated, in pixels.
		@param dest  Where the copies are drawn, in pixels.
		@param origin  The point dest rotates about, from its top-left, in pixels.
		@param rotation  The rotation, in degrees clockwise.
		@param scale  Each copy's size, a multiple of source's.
		@param tint  The tint. */
	public static function DrawTextureTiled(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, scale:Float,
		tint:Color):Void {}

	/** Draws a nine-patch, as raylib's `DrawTextureNPatch` does, its middle and edges stretched or repeated along each axis: a rope
		frame whose twists repeat along its sides.

		@param texture  The texture.
		@param nPatchInfo  The patch and its borders.
		@param dest  Where the patch is drawn, in pixels.
		@param origin  The point dest rotates about, from its top-left, in pixels.
		@param rotation  The rotation, in degrees clockwise.
		@param horizontalPatchMode  How the middle and edges fill dest across: `NPATCH_MODE_STRETCH`, `NPATCH_MODE_TILE` or `NPATCH_MODE_TILE_FIT`.
		@param verticalPatchMode  How the middle and edges fill dest down, as `horizontalPatchMode`.
		@param tint  The tint. */
	public static function DrawTextureNPatchEx(texture:Texture2D, nPatchInfo:NPatchInfo, dest:Rectangle, origin:Vector2, rotation:Float,
		horizontalPatchMode:Int, verticalPatchMode:Int, tint:Color):Void {}

	/** Draws a texture inside a polygon: a portrait in a hexagon, a ground texture on a hill. Each point is drawn with the texture at its
		texture coordinate, the points joined to center as a triangle fan. The
		polygon is closed from the last point back to the first.

		@param texture  The texture.
		@param center  The fan's middle, in pixels, drawn with the texture's middle.
		@param points  The polygon's points, in pixels, in order around it.
		@param texcoords  Each point's texture coordinate, from (0, 0) at the texture's top-left to (1, 1) at its bottom-right.
		@param pointCount  How many points are drawn, each counted once.
		@param tint  The tint. */
	public static function DrawTexturePoly(texture:Texture2D, center:Vector2, points:Array<Vector2>, texcoords:Array<Vector2>, pointCount:Int,
		tint:Color):Void {}

	/** Loads an atlas: a texture packed with images and the file naming each image's rectangle. Reads TexturePacker's JSON (hash or
		array) and the XML of Starling and Kenney's sheets. The texture is the file the atlas names, beside it. See
		`LoadTextureAtlasAsync` for a page, which loads files only asynchronously.

		Refused, with the reason logged, for a file of another format or a texture that doesn't load.

		@param fileName  The atlas's file.
		@return  The atlas, or null when refused. */
	public static function LoadTextureAtlas(fileName:String):Null<TextureAtlas>
		return null;

	/** Loads an atlas, as `LoadTextureAtlas` does, calling back once its file and texture have loaded.

		@param fileName  The atlas's file.
		@param loaded  Called with the atlas.
		@param failed  Optional. Called with the reason when refused. */
	public static function LoadTextureAtlasAsync(fileName:String, loaded:TextureAtlas->Void, ?failed:String->Void):Void {}

	/** Unloads an atlas's texture.

		@param atlas  The atlas. */
	public static function UnloadTextureAtlas(atlas:TextureAtlas):Void {}

	/** Returns the rectangle of an image in an atlas, for a draw's source. Refused, with the name logged, for a name the atlas
		lacks.

		@param atlas  The atlas.
		@param name  The image's name, as the atlas's file names it, extension and all: `sword.png`.
		@param out  Optional. The rectangle to fill, or null for a new one.
		@return  out, or the new rectangle, in pixels of the atlas's texture, or an empty rectangle when refused. */
	public static function GetTextureAtlasRectangle(atlas:TextureAtlas, name:String, ?out:Rectangle):Rectangle
		return out == null ? new Rectangle(0, 0, 0, 0) : out;

	/** Draws a render texture fitted to the screen: as large as fits, its aspect kept, centered with bars beside or above it, and the
		right way up. Drawn between `BeginDrawing` and `EndDrawing`, outside the render texture's `BeginTextureMode`.

		@param target  The render texture.
		@param integerScale  Whether its size is a whole multiple of the render texture's, for pixel art.
		@param tint  The tint. */
	public static function DrawRenderTextureFit(target:RenderTexture2D, integerScale:Bool, tint:Color):Void {}

	/** Sets the mouse's offset and scale (raylib's `SetMouseOffset` and `SetMouseScale`) to a render texture drawn by
		`DrawRenderTextureFit`. `GetMousePosition` and raygui's controls then read the mouse in the render texture's pixels. Set again
		when the window's size changes, or each frame.

		@param target  The render texture.
		@param integerScale  Whether its size is a whole multiple of the render texture's, as given `DrawRenderTextureFit`. */
	public static function SetMouseRenderTextureFit(target:RenderTexture2D, integerScale:Bool):Void {}

	/** Returns where `DrawRenderTextureFit` draws a render texture on the screen.

		@param target  The render texture.
		@param integerScale  Whether its size is a whole multiple of the render texture's.
		@param out  Optional. The rectangle to fill, or null for a new one.
		@return  out, or the new rectangle, in screen pixels. */
	public static function GetRenderTextureFitRectangle(target:RenderTexture2D, integerScale:Bool, ?out:Rectangle):Rectangle
		return out == null ? new Rectangle(0, 0, 0, 0) : out;
}
