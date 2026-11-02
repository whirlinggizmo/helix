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
		calls.resize(0);
		callCount = 0;
		bounds.makeEmpty();
		return this;
	}

	/** Records a whole texture at its size, its top left at a point.

		@param texture  The texture.
		@param x  The left edge.
		@param y  The top edge.
		@param tint  Optional. The color its texels are multiplied by; defaults to white. */
	public function drawTexture(texture:Texture2D, x:Float, y:Float, tint:Int = 0xffffffff):Void {
		add(b -> b.drawTexture(texture, x, y, tint));
		box(x, y, x + texture.width, y + texture.height);
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
		add(b -> b.drawTextureRegion(texture, regionX, regionY, regionWidth, regionHeight, x, y, width, height, rotation, originX, originY, tint));
		turned(-originX, -originY, width - originX, height - originY, x, y, rotation);
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
		add(b -> b.drawSprite(region, x, y, rotation, scaleX, scaleY, tint, flipX, flipY, originX, originY));
		var ox = originX == null ? region.originX : originX,
			oy = originY == null ? region.originY : originY;
		var sx = flipX ? -scaleX : scaleX, sy = flipY ? -scaleY : scaleY;
		turned(-ox * sx, -oy * sy, (region.regionWidth - ox) * sx, (region.regionHeight - oy) * sy, x, y, rotation);
	}

	/** Records a line between two points.

		@param x0  The start, across.
		@param y0  The start, down.
		@param x1  The end, across.
		@param y1  The end, down.
		@param thickness  The width, in the list's units; its ends are square, cut at the points.
		@param color  The color. */
	public function drawLine(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Float, color:Int):Void {
		add(b -> b.drawLine(x0, y0, x1, y1, thickness, color));
		var h = thickness / 2;
		box(Math.min(x0, x1) - h, Math.min(y0, y1) - h, Math.max(x0, x1) + h, Math.max(y0, y1) + h);
	}

	/** Records lines through points, one after another, joined at each point with a miter, or a bevel where the miter would reach past twice
		the thickness.

		@param points  The points, x and y each; fewer than two draws nothing.
		@param thickness  The width, in the list's units.
		@param color  The color. */
	public function drawPolyline(points:Array<Float>, thickness:Float, color:Int):Void {
		var copy = points.copy();
		add(b -> b.drawPolyline(copy, thickness, color));
		pointsBox(copy, thickness * 2);
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
		add(b -> b.fillTriangle(x0, y0, x1, y1, x2, y2, color));
		box(Math.min(x0, Math.min(x1, x2)), Math.min(y0, Math.min(y1, y2)), Math.max(x0, Math.max(x1, x2)), Math.max(y0, Math.max(y1, y2)));
	}

	/** Records a filled rectangle.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	public function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int):Void {
		add(b -> b.fillRectangle(x, y, width, height, color));
		box(Math.min(x, x + width), Math.min(y, y + height), Math.max(x, x + width), Math.max(y, y + height));
	}

	/** Records a rectangle's outline.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int):Void {
		add(b -> b.strokeRectangle(x, y, width, height, thickness, color));
		box(x - thickness, y - thickness, x + width + thickness, y + height + thickness);
	}

	/** Records a filled rectangle with rounded corners.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param color  The color. */
	public function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int):Void {
		add(b -> b.fillRoundedRectangle(x, y, width, height, radius, color));
		box(x, y, x + width, y + height);
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
		add(b -> b.strokeRoundedRectangle(x, y, width, height, radius, thickness, color));
		box(x - thickness, y - thickness, x + width + thickness, y + height + thickness);
	}

	/** Records a filled circle.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param color  The color. */
	public function fillCircle(x:Float, y:Float, radius:Float, color:Int):Void {
		add(b -> b.fillCircle(x, y, radius, color));
		box(x - radius, y - radius, x + radius, y + radius);
	}

	/** Records a circle's outline.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param thickness  The outline's width, centered on the circle.
		@param color  The color. */
	public function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int):Void {
		add(b -> b.strokeCircle(x, y, radius, thickness, color));
		var r = radius + thickness / 2;
		box(x - r, y - r, x + r, y + r);
	}

	/** Records a filled ellipse whose axes run across and down.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param color  The color. */
	public function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int):Void {
		add(b -> b.fillEllipse(x, y, radiusX, radiusY, color));
		box(x - Math.abs(radiusX), y - Math.abs(radiusY), x + Math.abs(radiusX), y + Math.abs(radiusY));
	}

	/** Records an ellipse's outline.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param thickness  The outline's width, centered on the ellipse.
		@param color  The color. */
	public function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int):Void {
		add(b -> b.strokeEllipse(x, y, radiusX, radiusY, thickness, color));
		var rx = Math.abs(radiusX) + thickness / 2,
			ry = Math.abs(radiusY) + thickness / 2;
		box(x - rx, y - ry, x + rx, y + ry);
	}

	/** Records a filled polygon, convex or not, whose edges don't cross.

		@param points  The corners in order, x and y each, either way round; fewer than three draws nothing.
		@param color  The color.
		@return  False when its edges cross, and nothing is recorded. */
	public function fillPolygon(points:Array<Float>, color:Int):Bool {
		if (points.length >= 6 && Tessellator2D.crosses(points))
			return false;
		var copy = points.copy();
		add(b -> b.fillPolygon(copy, color));
		pointsBox(copy, 0);
		return true;
	}

	/** Records a polygon's outline: lines through its corners and back to the first, joined as `drawPolyline` joins them.

		@param points  The corners in order, x and y each; fewer than two draws nothing.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color. */
	public function strokePolygon(points:Array<Float>, thickness:Float, color:Int):Void {
		var copy = points.copy();
		add(b -> b.strokePolygon(copy, thickness, color));
		pointsBox(copy, thickness * 2);
	}

	/** Records triangles as given: textured, colored by vertex, or both, for what the shapes here don't make.

		The arrays are copied, so they may be reused.
		@param texture  The texture, or null for white.
		@param positions  The vertices' positions, x and y each.
		@param texCoords  Optional. The texture coordinates, u and v each, 0 to 1 across the texture; 0, 0 for every vertex when omitted.
		@param colors  Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
		@param indices  Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order. */
	public function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>):Void {
		var p = positions.copy(),
			t = texCoords == null ? null : texCoords.copy(),
			c = colors == null ? null : colors.copy(),
			i = indices == null ? null : indices.copy();
		add(b -> b.drawTriangles(texture, p, t, c, i));
		pointsBox(p, 0);
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
		add(b -> b.drawText(font, text, x, y, color, size, letterSpacing, kerned));
		var size = font.measureText(text, size, letterSpacing, kerned);
		box(x, y, x + size.x, y + size.y);
	}

	/** Records laid-out text, wrapped and aligned as its layout says, the layout's top left at a point.

		The layout is held, not copied: it is drawn as it is at each replay.
		@param layout  The layout.
		@param x  The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest
			line when `maxWidth` is 0.
		@param y  The top of the first line.
		@param color  Optional. The color; defaults to white. */
	public function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, color:Int = 0xffffffff):Void {
		add(b -> b.drawTextLayout(layout, x, y, color));
		var width = layout.maxWidth > 0 ? layout.maxWidth : layout.width;
		box(x, y, x + width, y + layout.height);
	}

	// The calls recorded, each replayed on a batch.
	final calls:Array<Batch2D->Void> = [];

	function add(call:Batch2D->Void):Void {
		calls.push(call);
		callCount++;
	}

	// Replays the calls on a batch, in the order recorded.

	@:allow(helix.render)
	function replay(batch:Batch2D):Void
		for (call in calls)
			call(batch);

	function box(minX:Float, minY:Float, maxX:Float, maxY:Float):Void {
		bounds.expand(minX, minY);
		bounds.expand(maxX, maxY);
	}

	// A rectangle around an origin, turned and placed at x, y.
	function turned(left:Float, top:Float, right:Float, bottom:Float, x:Float, y:Float, rotation:Float):Void {
		var cos = Math.cos(rotation), sin = Math.sin(rotation);
		for (p in [[left, top], [right, top], [right, bottom], [left, bottom]])
			bounds.expand(x + p[0] * cos - p[1] * sin, y + p[0] * sin + p[1] * cos);
	}

	function pointsBox(points:Array<Float>, margin:Float):Void {
		var i = 0;
		while (i + 1 < points.length) {
			box(points[i] - margin, points[i + 1] - margin, points[i] + margin, points[i + 1] + margin);
			i += 2;
		}
	}
}
