package helix.render;

/** What both batches draw in a plane: textures, sprites, shapes and text, made into textured, colored vertices on the CPU, as `Batch2D`
	draws them and `Batch3D` draws them in a plane. The batch gives where the vertices go (`vertex`), which texture they read (`use`), and
	what is in view (`visible`). */
@:noCompletion
@:allow(helix.render)
class PlaneDrawing2D {
	/** Makes the following vertices read a texture (null for the white one), a font's kind's way. */
	var use:(texture:Null<Texture2D>, fontKind:Int) -> Void;

	/** Adds a vertex, in the plane's units. */
	var vertex:(x:Float, y:Float, u:Float, v:Float, color:Int) -> Void;

	/** Whether a box of the plane may be seen, or a draw of it is skipped. */
	var visible:(minX:Float, minY:Float, maxX:Float, maxY:Float) -> Bool;

	/** The region shapes read the center of, or null for the white texture. */
	var shapeRegion:Null<TextureRegion2D> = null;

	// The shapes' tessellator, made at the first shape, so a program drawing only sprites and text links none of it.
	var tessellator:Null<Tessellator2D> = null;
	var shapeU = .5;
	var shapeV = .5;
	var shapeColor = 0;

	static final corners = [for (_ in 0...8) 0.];

	function new(use:(Null<Texture2D>, Int) -> Void, vertex:(Float, Float, Float, Float, Int) -> Void, visible:(Float, Float, Float, Float) -> Bool) {
		this.use = use;
		this.vertex = vertex;
		this.visible = visible;
	}

	/** Pixels a unit where the plane is drawn, for the curves' segments. */
	var scale = 1.;

	// The tessellator, at the plane's scale.
	function tess():Tessellator2D {
		if (tessellator == null)
			tessellator = new Tessellator2D(shapeTriangle);
		tessellator.scale = scale;
		return tessellator;
	}

	function shapeTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float):Void {
		vertex(x0, y0, shapeU, shapeV, shapeColor);
		vertex(x1, y1, shapeU, shapeV, shapeColor);
		vertex(x2, y2, shapeU, shapeV, shapeColor);
	}

	// Makes the following shapes read the shapes' region's center, in a color.
	function shape(color:Int):Void {
		var r = shapeRegion;
		if (r == null) {
			use(null, 0);
			shapeU = shapeV = .5;
		} else {
			use(r.texture, 0);
			shapeU = (r.regionX + r.regionWidth / 2) / r.texture.width;
			shapeV = (r.regionY + r.regionHeight / 2) / r.texture.height;
		}
		shapeColor = color;
	}

	// A quad's four corners (x, y each, in order round it) with their texture coordinates.
	function quad(c:Array<Float>, u0:Float, v0:Float, u1:Float, v1:Float, tint:Int):Void {
		vertex(c[0], c[1], u0, v0, tint);
		vertex(c[2], c[3], u1, v0, tint);
		vertex(c[4], c[5], u1, v1, tint);
		vertex(c[0], c[1], u0, v0, tint);
		vertex(c[4], c[5], u1, v1, tint);
		vertex(c[6], c[7], u0, v1, tint);
	}

	// Whether the four corners' box may be seen.
	function cornersVisible(c:Array<Float>):Bool {
		var minX = Math.min(Math.min(c[0], c[2]), Math.min(c[4], c[6])),
			maxX = Math.max(Math.max(c[0], c[2]), Math.max(c[4], c[6]));
		var minY = Math.min(Math.min(c[1], c[3]), Math.min(c[5], c[7])),
			maxY = Math.max(Math.max(c[1], c[3]), Math.max(c[5], c[7]));
		return visible(minX, minY, maxX, maxY);
	}

	// A rectangle's corners turned about a point of it and moved: from (left, top) to (right, bottom) around the origin, then turned and
	// placed at x, y.
	function place(left:Float, top:Float, right:Float, bottom:Float, x:Float, y:Float, rotation:Float):Array<Float> {
		var c = corners, cos = Math.cos(rotation), sin = Math.sin(rotation);
		var px = [left, right, right, left], py = [top, top, bottom, bottom];
		for (i in 0...4) {
			c[i * 2] = x + px[i] * cos - py[i] * sin;
			c[i * 2 + 1] = y + px[i] * sin + py[i] * cos;
		}
		return c;
	}

	function textureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float,
			height:Float, rotation:Float, originX:Float, originY:Float, tint:Int):Void {
		texture.drawnHandle();
		var c = place(-originX, -originY, width - originX, height - originY, x, y, rotation);
		if (!cornersVisible(c))
			return;
		var w = texture.width, h = texture.height;
		var u0 = regionX / w, u1 = (regionX + Math.abs(regionWidth)) / w;
		var v0 = regionY / h, v1 = (regionY + Math.abs(regionHeight)) / h;
		if (regionWidth < 0) {
			var t = u0;
			u0 = u1;
			u1 = t;
		}
		if (regionHeight < 0) {
			var t = v0;
			v0 = v1;
			v1 = t;
		}
		use(texture, 0);
		quad(c, u0, v0, u1, v1, tint);
	}

	function sprite(region:TextureRegion2D, x:Float, y:Float, rotation:Float, scaleX:Float, scaleY:Float, tint:Int, flipX:Bool, flipY:Bool, ?originX:Float,
			?originY:Float):Void {
		var texture = region.texture;
		texture.drawnHandle();
		var ox = originX == null ? region.originX : originX,
			oy = originY == null ? region.originY : originY;
		var sx = flipX ? -scaleX : scaleX, sy = flipY ? -scaleY : scaleY;
		var c = place(-ox * sx, -oy * sy, (region.regionWidth - ox) * sx, (region.regionHeight - oy) * sy, x, y, rotation);
		if (!cornersVisible(c))
			return;
		var w = texture.width, h = texture.height;
		use(texture, 0);
		quad(c, region.regionX / w, region.regionY / h, (region.regionX + region.regionWidth) / w, (region.regionY + region.regionHeight) / h, tint);
	}

	function line(x0:Float, y0:Float, x1:Float, y1:Float, thickness:Float, color:Int):Void {
		var h = thickness / 2;
		if (!visible(Math.min(x0, x1) - h, Math.min(y0, y1) - h, Math.max(x0, x1) + h, Math.max(y0, y1) + h))
			return;
		shape(color);
		tess().line(x0, y0, x1, y1, thickness);
	}

	// Whether points' box, grown by a margin, may be seen.
	function pointsVisible(points:Array<Float>, margin:Float):Bool {
		var minX = Math.POSITIVE_INFINITY,
			minY = Math.POSITIVE_INFINITY,
			maxX = Math.NEGATIVE_INFINITY,
			maxY = Math.NEGATIVE_INFINITY;
		var i = 0;
		while (i + 1 < points.length) {
			minX = Math.min(minX, points[i]);
			maxX = Math.max(maxX, points[i]);
			minY = Math.min(minY, points[i + 1]);
			maxY = Math.max(maxY, points[i + 1]);
			i += 2;
		}
		return minX <= maxX && visible(minX - margin, minY - margin, maxX + margin, maxY + margin);
	}

	function polyline(points:Array<Float>, thickness:Float, color:Int, closed:Bool):Void {
		if (points.length < 4 || !pointsVisible(points, thickness * 2))
			return;
		shape(color);
		tess().stroke(points, closed, thickness);
	}

	function triangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int):Void {
		if (!visible(Math.min(x0, Math.min(x1, x2)), Math.min(y0, Math.min(y1, y2)), Math.max(x0, Math.max(x1, x2)), Math.max(y0, Math.max(y1, y2))))
			return;
		shape(color);
		shapeTriangle(x0, y0, x1, y1, x2, y2);
	}

	function rectangle(x:Float, y:Float, width:Float, height:Float, color:Int):Void {
		if (!visible(Math.min(x, x + width), Math.min(y, y + height), Math.max(x, x + width), Math.max(y, y + height)))
			return;
		shape(color);
		tess().rectangle(x, y, width, height);
	}

	function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int):Void {
		polyline([x, y, x + width, y, x + width, y + height, x, y + height], thickness, color, true);
	}

	function roundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int):Void {
		if (!visible(x, y, x + width, y + height))
			return;
		shape(color);
		tess().fillRounded(x, y, width, height, radius);
	}

	function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int):Void {
		var h = thickness / 2;
		if (!visible(x - h, y - h, x + width + h, y + height + h))
			return;
		shape(color);
		tess().strokeRounded(x, y, width, height, radius, thickness);
	}

	function ellipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int):Void {
		var rx = Math.abs(radiusX), ry = Math.abs(radiusY);
		if (!visible(x - rx, y - ry, x + rx, y + ry))
			return;
		shape(color);
		tess().fillEllipse(x, y, rx, ry);
	}

	function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int):Void {
		var rx = Math.abs(radiusX) + thickness / 2,
			ry = Math.abs(radiusY) + thickness / 2;
		if (!visible(x - rx, y - ry, x + rx, y + ry))
			return;
		shape(color);
		tess().strokeEllipse(x, y, Math.abs(radiusX), Math.abs(radiusY), thickness);
	}

	function polygon(points:Array<Float>, color:Int):Bool {
		if (points.length < 6)
			return true;
		if (Tessellator2D.crosses(points))
			return false;
		if (!pointsVisible(points, 0))
			return true;
		shape(color);
		return tess().fillPolygon(points);
	}

	function triangles(texture:Null<Texture2D>, positions:Array<Float>, texCoords:Null<Array<Float>>, colors:Null<Array<Int>>, indices:Null<Array<Int>>):Void {
		if (texture != null)
			texture.drawnHandle();
		use(texture, 0);
		var count = indices != null ? indices.length - indices.length % 3 : Std.int(positions.length / 6) * 3;
		for (k in 0...count) {
			var i = indices != null ? indices[k] : k;
			vertex(positions[i * 2], positions[i * 2 + 1], texCoords != null ? texCoords[i * 2] : 0, texCoords != null ? texCoords[i * 2 + 1] : 0,
				colors != null ? colors[i] : 0xffffffff);
		}
	}

	function text(font:GpuFont2D, text:String, x:Float, y:Float, color:Int, size:Null<Float>, letterSpacing:Float):Void {
		var scale = font.scaleOf(size),
			lines = text.split("\n"),
			step = font.lineHeight * scale;
		var top = y;
		for (line in lines) {
			glyphs(font, GpuFont2D.codes(line), x, top, scale, letterSpacing, color);
			top += step;
		}
	}

	function layout(layout:TextLayout2D, x:Float, y:Float, color:Int):Void {
		layout.layOut();
		var font = layout.font,
			scale = layout.scale,
			step = font.lineHeight * scale * layout.lineSpacing;
		var box = layout.maxWidth > 0 ? layout.maxWidth : layout.width;
		var top = y;
		for (i in 0...layout.lines.length) {
			var w = layout.widths[i];
			var left = x + switch layout.align {
				case Left: 0.;
				case Center: (box - w) / 2;
				case Right: box - w;
			};
			glyphs(font, layout.lines[i], left, top, scale, layout.letterSpacing, color);
			top += step;
		}
	}

	// A line of glyphs, its top at y: each glyph's quad from the atlas, the pen moved by its advance and the spacing.
	function glyphs(font:GpuFont2D, codes:Array<Int>, x:Float, top:Float, scale:Float, spacing:Float, color:Int):Void {
		var f = font.font, atlas = font.atlas;
		var width = font.widthOf(codes, scale, spacing);
		if (!visible(x, top, x + width, top + (f.ascent - f.descent) * scale))
			return;
		atlas.drawnHandle();
		use(atlas, 0);
		var baseline = top + f.ascent * scale, pen = x, aw = atlas.width, ah = atlas.height, c = corners;
		for (code in codes) {
			var g = font.glyphFor(code);
			if (g == null)
				continue;
			if (g.width > 0 && g.height > 0) {
				var left = pen + g.offsetX * scale,
					gy = baseline + g.offsetY * scale;
				var right = left + g.width * scale,
					bottom = gy + g.height * scale;
				c[0] = left;
				c[1] = gy;
				c[2] = right;
				c[3] = gy;
				c[4] = right;
				c[5] = bottom;
				c[6] = left;
				c[7] = bottom;
				quad(c, g.x / aw, g.y / ah, (g.x + g.width) / aw, (g.y + g.height) / ah, color);
			}
			pen += g.advance * scale + spacing;
		}
	}
}
