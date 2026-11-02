package helix.render;

import helix.math.Bounds2D;

/** Represents 2D drawing recorded once and replayed by a `Batch2D` as often as wanted (`Batch2D.drawList`), under a transform: a HUD
	panel, a level's static decoration, a shape built of many calls.

	A program records into it with the calls `Batch2D` draws with, named alike, in the list's own units; `makeEmpty` empties it to
	record again. A replay draws the calls in the order recorded, batched as `Batch2D` batches them, with the batch's `blend`, `shaderValues` and
	`customData` at the replay; the list holds no state of its own. It holds references to the textures, regions, fonts and layouts it is given and owns
	none: a texture disposed after it was recorded makes a replay throw, and a layout is drawn as it is at each replay. Point and vertex
	arrays are copied. It may be recorded at any time, outside a frame too, as it draws nothing itself.

	```haxe
	var panel = new DrawList2D();
	panel.fillRoundedRectangle(0, 0, 220, 64, 8, 0xc0101828);
	panel.strokeRoundedRectangle(0, 0, 220, 64, 8, 2, 0xff4080c0);
	panel.drawText(font, "Cargo", 12, 10);
	// each frame:
	batch.drawList(panel, Matrix2D.fromTranslation(16, 16, place));
	``` */
class DrawList2D {
	/** Gets the box around what it holds, in its own units: empty when it holds nothing. Text is measured as it is recorded. */
	public final bounds = new Bounds2D();

	/** Gets the number of calls recorded. */
	public var callCount(default, null):Int = 0;

	/** Creates an empty list. */
	public function new() {}

	/** Removes every call, to record again.

		@return  This list. */
	public function makeEmpty():DrawList2D {
		throw "helix-render: DrawList2D.makeEmpty is not yet built (stage 1)";
	}

	/** Records a whole texture at its size, its top left at a point.

		@param texture  The texture.
		@param x  The left edge.
		@param y  The top edge.
		@param tint  Optional. The color its texels are multiplied by; defaults to white. */
	public function drawTexture(texture:Texture2D, x:Float, y:Float, tint:Int = 0xffffffff):Void {
		throw "helix-render: DrawList2D.drawTexture is not yet built (stage 1)";
	}

	/** Records a rectangle of a texture drawn into a rectangle, turned about an origin, as `Batch2D.drawTextureRegion` draws it.

		@param texture  The texture.
		@param regionX  The part's left edge, in texels from the texture's left.
		@param regionY  The part's top edge, in texels from the texture's top.
		@param regionWidth  The part's width, in texels; negative mirrors it left to right.
		@param regionHeight  The part's height, in texels; negative mirrors it top to bottom.
		@param x  Where the origin goes, across.
		@param y  Where the origin goes, down.
		@param width  The width it is drawn at, in the list's units.
		@param height  The height it is drawn at, in the list's units.
		@param rotation  Optional. The turn about the origin, in radians; defaults to 0.
		@param originX  Optional. The point it turns about and is placed by, in the list's units from the drawn rectangle's left;
			defaults to 0.
		@param originY  Optional. That point, in the list's units from the drawn rectangle's top; defaults to 0.
		@param tint  Optional. The color its texels are multiplied by; defaults to white. */
	public function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float,
			height:Float, rotation = 0., originX = 0., originY = 0., tint:Int = 0xffffffff):Void {
		throw "helix-render: DrawList2D.drawTextureRegion is not yet built (stage 1)";
	}

	/** Records a texture's region, turned and scaled about its origin, the origin at a point.

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
		throw "helix-render: DrawList2D.drawSprite is not yet built (stage 1)";
	}

	/** Records a line between two points.

		@param x0  The start, across.
		@param y0  The start, down.
		@param x1  The end, across.
		@param y1  The end, down.
		@param thickness  The width, in the list's units; its ends are square, cut at the points.
		@param color  The color. */
	public function drawLine(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Float, color:Int):Void {
		throw "helix-render: DrawList2D.drawLine is not yet built (stage 1)";
	}

	/** Records lines through points, one after another, joined at each point with a miter, or a bevel where the miter would reach past twice
		the thickness.

		@param points  The points, x and y each; fewer than two draws nothing.
		@param thickness  The width, in the list's units.
		@param color  The color. */
	public function drawPolyline(points:Array<Float>, thickness:Float, color:Int):Void {
		throw "helix-render: DrawList2D.drawPolyline is not yet built (stage 1)";
	}

	/** Records a filled triangle.

		@param x0  The first corner, across.
		@param y0  The first corner, down.
		@param x1  The second corner, across.
		@param y1  The second corner, down.
		@param x2  The third corner, across.
		@param y2  The third corner, down.
		@param color  The color. */
	public function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int):Void {
		throw "helix-render: DrawList2D.fillTriangle is not yet built (stage 1)";
	}

	/** Records a filled rectangle.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	public function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int):Void {
		throw "helix-render: DrawList2D.fillRectangle is not yet built (stage 1)";
	}

	/** Records a rectangle's outline.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int):Void {
		throw "helix-render: DrawList2D.strokeRectangle is not yet built (stage 1)";
	}

	/** Records a filled rectangle with rounded corners.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param color  The color. */
	public function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int):Void {
		throw "helix-render: DrawList2D.fillRoundedRectangle is not yet built (stage 1)";
	}

	/** Records the outline of a rectangle with rounded corners.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int):Void {
		throw "helix-render: DrawList2D.strokeRoundedRectangle is not yet built (stage 1)";
	}

	/** Records a filled circle.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param color  The color. */
	public function fillCircle(x:Float, y:Float, radius:Float, color:Int):Void {
		throw "helix-render: DrawList2D.fillCircle is not yet built (stage 1)";
	}

	/** Records a circle's outline.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param thickness  The outline's width, centered on the circle.
		@param color  The color. */
	public function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int):Void {
		throw "helix-render: DrawList2D.strokeCircle is not yet built (stage 1)";
	}

	/** Records a filled ellipse whose axes run across and down.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param color  The color. */
	public function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int):Void {
		throw "helix-render: DrawList2D.fillEllipse is not yet built (stage 1)";
	}

	/** Records an ellipse's outline.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param thickness  The outline's width, centered on the ellipse.
		@param color  The color. */
	public function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int):Void {
		throw "helix-render: DrawList2D.strokeEllipse is not yet built (stage 1)";
	}

	/** Records a filled polygon, convex or not, whose edges don't cross.

		@param points  The corners in order, x and y each, either way round; fewer than three draws nothing.
		@param color  The color.
		@return  False when its edges cross, and nothing is recorded. */
	public function fillPolygon(points:Array<Float>, color:Int):Bool {
		throw "helix-render: DrawList2D.fillPolygon is not yet built (stage 1)";
	}

	/** Records a polygon's outline: lines through its corners and back to the first, joined as `drawPolyline` joins them.

		@param points  The corners in order, x and y each; fewer than two draws nothing.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokePolygon(points:Array<Float>, thickness:Float, color:Int):Void {
		throw "helix-render: DrawList2D.strokePolygon is not yet built (stage 1)";
	}

	/** Records triangles as given: textured, colored by vertex, or both, for what the shapes here don't make.

		The arrays are copied, so they may be reused.
		@param texture  The texture, or null for white.
		@param positions  The vertices' positions, x and y each.
		@param texCoords  Optional. The texture coordinates, u and v each, 0 to 1 across the texture; 0, 0 for every vertex when omitted.
		@param colors  Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
		@param indices  Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order. */
	public function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>):Void {
		throw "helix-render: DrawList2D.drawTriangles is not yet built (stage 1)";
	}

	/** Records text in a font, line by line at each line break, left-aligned, its first line's top at a point.

		A distance-field font stays sharp at any size; another is scaled from its atlas. Pairs of characters are kerned as the font gives
		them, unless `kerned` is false.
		@param font  The font.
		@param text  The text; a character the font lacks is skipped.
		@param x  The left edge.
		@param y  The top of the first line: its ascent above the baseline.
		@param color  Optional. The color; defaults to white.
		@param size  Optional. The size, in the list's units, as the font's size is measured; the font's own when omitted.
		@param letterSpacing  Optional. Space added after each character, in the list's units; defaults to 0.
		@param kerned  Optional. Whether pairs of characters are kerned as the font gives them; defaults to true. raylib's `DrawTextEx`
			doesn't kern. */
	public function drawText(font:GpuFont2D, text:String, x:Float, y:Float, color:Int = 0xffffffff, ?size:Float, letterSpacing = 0., kerned = true):Void {
		throw "helix-render: DrawList2D.drawText is not yet built (stage 1)";
	}

	/** Records laid-out text, wrapped and aligned as its layout says, the layout's top left at a point.

		The layout is held, not copied: it is drawn as it is at each replay.
		@param layout  The layout.
		@param x  The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest
			line when `maxWidth` is 0.
		@param y  The top of the first line.
		@param color  Optional. The color; defaults to white. */
	public function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, color:Int = 0xffffffff):Void {
		throw "helix-render: DrawList2D.drawTextLayout is not yet built (stage 1)";
	}
}
