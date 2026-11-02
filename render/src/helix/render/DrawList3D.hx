package helix.render;

import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.math.Vector3D;

/** Represents 3D drawing recorded once and replayed by a `Batch3D` as often as wanted (`Batch3D.drawList`), under a transform: a debug
	grid, a path, gizmos, a group of props placed together.

	A program records into it with `Batch3D`'s calls for meshes, models and the batch draws (lines, debug shapes, billboards, points,
	triangles, shapes, sprites and text), named alike, in the list's own units; `makeEmpty` empties it to record again. A replay draws the calls in the order recorded, batched as
	`Batch3D` batches them, with the batch's draw state, views, lights, environment and fog at the replay; the list holds no state of its own.
	It holds references to the meshes, models, materials, textures, regions, fonts and layouts it is given and owns none: one disposed after it was
	recorded makes a replay throw, and a material is drawn as it is at each replay. Arrays, boxes and matrices given are copied. It may be
	recorded at any time, outside a frame too.

	```haxe
	var guides = new DrawList3D();
	guides.drawGrid(40, 1, 0xff404858);
	guides.drawAxes(new Matrix3D(), 2);
	// each frame, inside batch.begin and end:
	batch.drawList(guides, identity);
	``` */
class DrawList3D {
	/** Gets the box around what it holds, in its own units: empty when it holds nothing. A model counts by its box at rest, posed by the
		bones given; a billboard by the sphere it can turn in; text as it is measured when recorded. */
	public final bounds = new Bounds3D();

	/** Gets the number of calls recorded. */
	public var callCount(default, null):Int = 0;

	/** Creates an empty list. */
	public function new() {}

	/** Removes every call, to record again.

		@return  This list. */
	public function makeEmpty():DrawList3D {
		calls.resize(0);
		callCount = 0;
		bounds.makeEmpty();
		return this;
	}

	/** Records a mesh with a material, placed by a transform.

		@param mesh  The mesh, held.
		@param material  The material, held, drawn as it is at each replay.
		@param transform  The mesh's place in the list's units, copied.
		@param skinning  Optional. Its skin's matrices (`Skin3D.computeSkinning`), copied, for a mesh with joints; the mesh is drawn
			unskinned when omitted.
		@param morphWeights  Optional. How much of each of its morph targets is added, copied, by target; none when omitted.
		@param tint  Optional. A color, 0xAARRGGBB, multiplying the material's `baseColor` for this draw alone; white when omitted.
		@param state  Optional. State this draw takes in place of the material's (`MeshState3D`), copied; the material's when
			omitted. */
	public function drawMesh(mesh:GpuMesh3D, material:Material3D, transform:Matrix3D, ?skinning:Array<Matrix3D>, ?morphWeights:Array<Float>, ?tint:Int,
			?state:MeshState3D):Void {
		var t = copy(transform),
			s = skinning == null ? null : [for (m in skinning) copy(m)],
			w = morphWeights == null ? null : morphWeights.copy();
		var st = state == null ? null : copyState(state), m = new Matrix3D();
		add((b, place) -> b.drawMesh(mesh, material, Matrix3D.compose(t, place, m), s, w, tint, st));
		boxed(mesh.bounds, t);
	}

	/** Records a mesh many times with one material, each copy placed by its own transform and tinted by its own color, in one GPU draw.

		A shader for it reads each copy's transform as `instanceModel` and its color as `instanceColor`; the default does. A mesh's joints
		are ignored here.
		@param mesh  The mesh, held.
		@param material  The material, held, drawn as it is at each replay.
		@param transforms  Each copy's place in the list's units, copied.
		@param colors  Optional. Each copy's color, 0xAARRGGBB, multiplying its base color, copied, indexed as `transforms`; white when
			omitted.
		@param transform  Optional. The parent all the copies are placed in, in the list's units, copied; identity when omitted.
		@param firstInstanceIndex  Optional. The index in `transforms` of the first copy recorded; defaults to 0.
		@param instanceCount  Optional. How many copies are recorded from it; every one to the end of `transforms` when omitted. None
			draws nothing.
		@throws String  Copies past the end of `transforms`. */
	public function drawMeshInstanced(mesh:GpuMesh3D, material:Material3D, transforms:Array<Matrix3D>, ?colors:Array<Int>, ?transform:Matrix3D,
			firstInstanceIndex = 0, ?instanceCount:Int):Void {
		var count = instanceCount == null ? transforms.length - firstInstanceIndex : instanceCount;
		if (firstInstanceIndex < 0 || count < 0 || firstInstanceIndex + count > transforms.length)
			throw 'helix-render: copies $firstInstanceIndex to ${firstInstanceIndex + count} of ${transforms.length} transforms';
		var copies = [for (i in firstInstanceIndex...firstInstanceIndex + count) copy(transforms[i])];
		var c = colors == null ? null : [for (i in firstInstanceIndex...firstInstanceIndex + count) colors[i]];
		var parent = transform == null ? new Matrix3D() : copy(transform),
			m = new Matrix3D();
		add((b, place) -> b.drawMeshInstanced(mesh, material, copies, c, Matrix3D.compose(parent, place, m)));
		for (copy in copies)
			boxed(mesh.bounds, Matrix3D.compose(copy, parent));
	}

	/** Records a model: each of its meshes with its material, placed by a transform, each skinned mesh posed by its skin.

		@param model  The model, held.
		@param transform  The model's place in the list's units, copied.
		@param boneMatrices  Optional. Each of its skeleton's bones' place in the model (`Skeleton3D.computeWorld`), copied; the rest
			pose when omitted. Ignored for a model without a skeleton.
		@param tint  Optional. A color, 0xAARRGGBB, multiplying each material's `baseColor` for this draw alone; white when omitted.
		@param state  Optional. State every mesh of this draw takes in place of its material's (`MeshState3D`), copied; each
			material's when omitted. */
	public function drawModel(model:GpuModel3D, transform:Matrix3D, ?boneMatrices:Array<Matrix3D>, ?tint:Int, ?state:MeshState3D):Void {
		var t = copy(transform),
			bones = boneMatrices == null ? null : [for (m in boneMatrices) copy(m)];
		var st = state == null ? null : copyState(state), m = new Matrix3D();
		add((b, place) -> b.drawModel(model, Matrix3D.compose(t, place, m), bones, tint, st));
		var placed = model.computeBounds(t, bones);
		if (!placed.isEmpty)
			bounds.union(placed, bounds);
	}

	/** Records a line between two points, one pixel wide.

		@param x0  The start's x.
		@param y0  The start's y.
		@param z0  The start's z.
		@param x1  The end's x.
		@param y1  The end's y.
		@param z1  The end's z.
		@param color  The color. */
	public function drawLine(x0:Float, y0:Float, z0:Float, x1:Float, y1:Float, z1:Float, color:Int):Void {
		drawLines([x0, y0, z0, x1, y1, z1], color);
	}

	/** Records lines through positions, as segments two by two or as one strip, of a width in pixels.

		A line wider than a pixel is a quad made in the vertex stage, facing the screen, the same on every backend.
		@param positions  The positions, x, y and z each, copied.
		@param color  The color of lines without colors of their own.
		@param colors  Optional. Each position's color, 0xAARRGGBB, blended along each line; `color` everywhere when omitted.
		@param width  Optional. The width, in framebuffer pixels, whatever the transform; defaults to 1.
		@param strip  Optional. Whether the positions are one line through them all, rather than a segment each two; defaults to false.
		@param transform  Optional. What the positions are moved by, in the list's units, copied; identity when omitted. */
	public function drawLines(positions:Array<Float>, color:Int, ?colors:Array<Int>, width = 1., strip = false, ?transform:Matrix3D):Void {
		var p = positions.copy(),
			c = colors == null ? null : colors.copy(),
			t = transform == null ? null : copy(transform),
			m = new Matrix3D();
		add((b, place) -> b.drawLines(p, color, c, width, strip, placed(t, place, m)));
		pointsBox(p, t);
	}

	/** Records a box's twelve edges.

		@param bounds  The box, in the list's units; copied.
		@param color  The color. */
	public function strokeBox(bounds:Bounds3D, color:Int):Void {
		drawLines(@:privateAccess Batch3D.boxEdges(bounds), color);
	}

	/** Records a sphere as three circles about its center, one square to each axis.

		@param x  The center's x.
		@param y  The center's y.
		@param z  The center's z.
		@param radius  The radius.
		@param color  The color. */
	public function strokeSphere(x:Float, y:Float, z:Float, radius:Float, color:Int):Void {
		drawLines(@:privateAccess Batch3D.sphereEdges(x, y, z, radius), color);
	}

	/** Records a grid of lines on the ground (y 0), centered on the origin.

		@param lineCount  The number of lines each way.
		@param spacing  The distance between two lines.
		@param color  The color. */
	public function drawGrid(lineCount:Int, spacing:Float, color:Int):Void {
		drawLines(@:privateAccess Batch3D.gridEdges(lineCount, spacing), color);
	}

	/** Records a transform's axes from its origin: x red, y green, z blue.

		@param transform  The transform, as a mesh would be placed by it, in the list's units; copied.
		@param length  Each axis' length, before the transform's scale. */
	public function drawAxes(transform:Matrix3D, length:Float):Void {
		drawLines([0, 0, 0, length, 0, 0, 0, 0, 0, 0, length, 0, 0, 0, 0, 0, 0, length], 0,
			[0xffff0000, 0xffff0000, 0xff00ff00, 0xff00ff00, 0xff0000ff, 0xff0000ff], 1, false, transform);
	}

	/** Records a texture's region facing the camera, upright with the camera's up and turned about its center, its center at a point.

		@param region  The region of the texture, held.
		@param x  The center's x.
		@param y  The center's y.
		@param z  The center's z.
		@param width  The width, in the list's units.
		@param height  The height, in the list's units.
		@param tint  Optional. The color its texels are multiplied by; defaults to white.
		@param rotation  Optional. Its turn in the screen's plane, in radians, clockwise; defaults to 0. */
	public function drawBillboard(region:TextureRegion2D, x:Float, y:Float, z:Float, width:Float, height:Float, tint:Int = 0xffffffff, rotation = 0.):Void {
		var at = new Vector3D();
		add((b, place) -> {
			place.transformPoint(x, y, z, at);
			b.drawBillboard(region, at.x, at.y, at.z, width, height, tint, rotation);
		});
		var r = Math.sqrt(width * width + height * height) / 2;
		bounds.expand(x - r, y - r, z - r);
		bounds.expand(x + r, y + r, z + r);
	}

	/** Records positions as points, drawn at the replaying batch's `pointSize`, unlit.

		@param positions  The points' positions, x, y and z each, in the list's units; copied.
		@param color  The color of points without one of their own.
		@param colors  Optional. Each point's own color, 0xAARRGGBB; `color` for every point when omitted.
		@param texture  Optional. The texture across each square, held; white when omitted.
		@param transform  Optional. What the positions are moved by, in the list's units, copied; identity when omitted. */
	public function drawPoints(positions:Array<Float>, color:Int, ?colors:Array<Int>, ?texture:Texture2D, ?transform:Matrix3D):Void {
		var p = positions.copy(),
			c = colors == null ? null : colors.copy(),
			t = transform == null ? null : copy(transform),
			m = new Matrix3D();
		add((b, place) -> b.drawPoints(p, color, c, texture, placed(t, place, m)));
		pointsBox(p, t);
	}

	/** Records triangles as given, in the list's units: textured, colored by vertex, or both, unlit, for what has no mesh.

		The arrays are copied, so they may be reused.
		@param texture  The texture, or null for white.
		@param positions  The vertices' positions, x, y and z each.
		@param texCoords  Optional. The texture coordinates, u and v each; 0, 0 for every vertex when omitted.
		@param colors  Optional. Each vertex's color, 0xAARRGGBB; white when omitted.
		@param indices  Optional. Three a triangle, indexing the vertices; when omitted, the vertices are the triangles in order.
		@param normals  Optional. Each vertex's normal, x, y and z, for a program's own shader; 0, 0, 1 for every vertex when omitted.
		@param transform  Optional. What the positions and normals are moved by, in the list's units, copied; identity when omitted. */
	public function drawTriangles(texture:Null<Texture2D>, positions:Array<Float>, ?texCoords:Array<Float>, ?colors:Array<Int>, ?indices:Array<Int>,
			?normals:Array<Float>, ?transform:Matrix3D):Void {
		var p = positions.copy(),
			uv = texCoords == null ? null : texCoords.copy(),
			c = colors == null ? null : colors.copy(),
			i = indices == null ? null : indices.copy(),
			n = normals == null ? null : normals.copy(),
			t = transform == null ? null : copy(transform),
			m = new Matrix3D();
		add((b, place) -> b.drawTriangles(texture, p, uv, c, i, n, placed(t, place, m)));
		pointsBox(p, t);
	}

	/** Records lines through points in a plane, one after another, joined at each point with a miter, or a bevel where the miter would
		reach past twice the thickness, as `Batch3D.drawPolyline` draws them; two points are one line, its ends square, cut at the points.

		@param points  The points, x and y each, in the plane's units, copied; fewer than two draws nothing.
		@param thickness  The width, in the plane's units.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function drawPolyline(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		var p = points.copy();
		inPlane(transform, (b, t) -> b.drawPolyline(p, thickness, color, t));
		planePoints(p, thickness * 2);
	}

	/** Records a filled triangle in a plane.

		@param x0  The first corner, across.
		@param y0  The first corner, down.
		@param x1  The second corner, across.
		@param y1  The second corner, down.
		@param x2  The third corner, across.
		@param y2  The third corner, down.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillTriangle(x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.fillTriangle(x0, y0, x1, y1, x2, y2, color, t));
		planeBox(Math.min(x0, Math.min(x1, x2)), Math.min(y0, Math.min(y1, y2)), Math.max(x0, Math.max(x1, x2)), Math.max(y0, Math.max(y1, y2)));
	}

	/** Records a filled rectangle in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.fillRectangle(x, y, width, height, color, t));
		planeBox(x, y, x + width, y + height);
	}

	/** Records a rectangle's outline in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function strokeRectangle(x:Float, y:Float, width:Float, height:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.strokeRectangle(x, y, width, height, thickness, color, t));
		planeBox(x - thickness, y - thickness, x + width + thickness, y + height + thickness);
	}

	/** Records a filled rectangle with rounded corners in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.fillRoundedRectangle(x, y, width, height, radius, color, t));
		planeBox(x, y, x + width, y + height);
	}

	/** Records the outline of a rectangle with rounded corners in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param radius  The corners' radius, clamped to half the shorter side.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function strokeRoundedRectangle(x:Float, y:Float, width:Float, height:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.strokeRoundedRectangle(x, y, width, height, radius, thickness, color, t));
		planeBox(x - thickness, y - thickness, x + width + thickness, y + height + thickness);
	}

	/** Records a filled circle in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillCircle(x:Float, y:Float, radius:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.fillCircle(x, y, radius, color, t));
		planeBox(x - radius, y - radius, x + radius, y + radius);
	}

	/** Records a circle's outline in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param thickness  The outline's width, centered on the circle.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.strokeCircle(x, y, radius, thickness, color, t));
		var r = radius + thickness / 2;
		planeBox(x - r, y - r, x + r, y + r);
	}

	/** Records a filled ellipse in a plane, its axes across and down.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.fillEllipse(x, y, radiusX, radiusY, color, t));
		planeBox(x - Math.abs(radiusX), y - Math.abs(radiusY), x + Math.abs(radiusX), y + Math.abs(radiusY));
	}

	/** Records an ellipse's outline in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param thickness  The outline's width, centered on the ellipse.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function strokeEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.strokeEllipse(x, y, radiusX, radiusY, thickness, color, t));
		var rx = Math.abs(radiusX) + thickness / 2,
			ry = Math.abs(radiusY) + thickness / 2;
		planeBox(x - rx, y - ry, x + rx, y + ry);
	}

	/** Records a filled polygon in a plane, convex or not, whose edges don't cross.

		@param points  The corners in order, x and y each, either way round, copied; fewer than three draws nothing.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
		@return  False when its edges cross, and nothing is recorded. */
	public function fillPolygon(points:Array<Float>, color:Int, ?transform:Matrix3D):Bool {
		if (points.length >= 6 && Tessellator2D.crosses(points))
			return false;
		var p = points.copy();
		inPlane(transform, (b, t) -> b.fillPolygon(p, color, t));
		planePoints(p, 0);
		return true;
	}

	/** Records a polygon's outline in a plane: lines through its corners and back to the first, joined as `drawPolyline` joins them.

		@param points  The corners in order, x and y each, copied; fewer than two draws nothing.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function strokePolygon(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		var p = points.copy();
		inPlane(transform, (b, t) -> b.strokePolygon(p, thickness, color, t));
		planePoints(p, thickness * 2);
	}

	/** Records a texture's region in a plane, turned and scaled about its origin, as `Batch3D.drawSprite` draws it.

		@param region  The region of the texture, held.
		@param x  Where the origin goes, across.
		@param y  Where the origin goes, down the texture.
		@param rotation  Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
		@param scaleX  Optional. The scale across; defaults to 1, a unit a texel.
		@param scaleY  Optional. The scale down; defaults to 1.
		@param tint  Optional. The color its texels are multiplied by; defaults to white.
		@param flipX  Optional. Whether it is mirrored across about its origin, after its scale; defaults to false.
		@param flipY  Optional. Whether it is mirrored down about its origin, after its scale; defaults to false.
		@param originX  Optional. The point it turns about and is placed by, in texels from the region's left; the region's `originX` when
			omitted.
		@param originY  Optional. That point, in texels from the region's top; the region's `originY` when omitted.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function drawSprite(region:TextureRegion2D, x:Float, y:Float, rotation = 0., scaleX = 1., scaleY = 1., tint:Int = 0xffffffff, flipX = false,
			flipY = false, ?originX:Float, ?originY:Float, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.drawSprite(region, x, y, rotation, scaleX, scaleY, tint, flipX, flipY, originX, originY, t));
		var ox = originX == null ? region.originX : originX,
			oy = originY == null ? region.originY : originY;
		var reach = Math.sqrt(Math.pow(Math.max(ox, region.regionWidth - ox) * scaleX, 2) + Math.pow(Math.max(oy, region.regionHeight - oy) * scaleY, 2));
		planeBox(x - reach, y - reach, x + reach, y + reach);
	}

	/** Records a rectangle of a texture drawn into a rectangle in a plane, as `Batch3D.drawTextureRegion` draws it.

		@param texture  The texture, held.
		@param regionX  The part's left edge, in texels from the texture's left.
		@param regionY  The part's top edge, in texels from the texture's top.
		@param regionWidth  The part's width, in texels; negative mirrors it across.
		@param regionHeight  The part's height, in texels; negative mirrors it down.
		@param x  Where the origin goes, across.
		@param y  Where the origin goes, down the texture.
		@param width  The width it is drawn at.
		@param height  The height it is drawn at.
		@param rotation  Optional. The turn about the origin, in radians, from x toward y; defaults to 0.
		@param originX  Optional. The point it turns about and is placed by, from the drawn rectangle's left; defaults to 0.
		@param originY  Optional. That point, from the drawn rectangle's top; defaults to 0.
		@param tint  Optional. The color its texels are multiplied by; defaults to white.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function drawTextureRegion(texture:Texture2D, regionX:Float, regionY:Float, regionWidth:Float, regionHeight:Float, x:Float, y:Float, width:Float,
			height:Float, rotation = 0., originX = 0., originY = 0., tint:Int = 0xffffffff, ?transform:Matrix3D):Void {
		inPlane(transform,
			(b, t) -> b.drawTextureRegion(texture, regionX, regionY, regionWidth, regionHeight, x, y, width, height, rotation, originX, originY, tint, t));
		var reach = Math.sqrt(Math.pow(Math.max(Math.abs(originX), Math.abs(width - originX)), 2)
			+ Math.pow(Math.max(Math.abs(originY), Math.abs(height - originY)), 2));
		planeBox(x - reach, y - reach, x + reach, y + reach);
	}

	/** Records text in a font in a plane, as `Batch3D.drawText` draws it.

		@param font  The font, held.
		@param text  The text; a character the font lacks is skipped.
		@param x  The left edge.
		@param y  The top of the first line, lines following down the texture.
		@param color  Optional. The color; defaults to white.
		@param size  Optional. The size, as the font's size is measured; the font's own when omitted.
		@param letterSpacing  Optional. Space added after each character; defaults to 0.
		@param kerned  Optional. Whether pairs of characters are kerned as the font gives them; defaults to true.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function drawText(font:GpuFont2D, text:String, x:Float, y:Float, color:Int = 0xffffffff, ?size:Float, letterSpacing = 0., kerned = true,
			?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.drawText(font, text, x, y, color, size, letterSpacing, kerned, t));
		var measured = font.measureText(text, size, letterSpacing, kerned);
		planeBox(x, y, x + measured.x, y + measured.y);
	}

	/** Records laid-out text in a plane, as `Batch3D.drawTextLayout` draws it; the layout is held, and drawn as it is at each replay.

		@param layout  The layout, held.
		@param x  The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest
			line when `maxWidth` is 0.
		@param y  The top of the first line.
		@param color  Optional. The color; defaults to white.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, color:Int = 0xffffffff, ?transform:Matrix3D):Void {
		inPlane(transform, (b, t) -> b.drawTextLayout(layout, x, y, color, t));
		var width = layout.maxWidth > 0 ? layout.maxWidth : layout.width;
		planeBox(x, y, x + width, y + layout.height);
	}

	// The calls recorded, each replayed on a batch with the list's placement; the plane the last call was recorded in.
	final calls:Array<(Batch3D, Matrix3D) -> Void> = [];
	var planeMatrix:Null<Matrix3D> = null;

	function add(call:(Batch3D, Matrix3D) -> Void):Void {
		calls.push(call);
		callCount++;
	}

	// Replays the calls on a batch, placed by a transform.

	@:allow(helix.render)
	function replay(batch:Batch3D, place:Matrix3D):Void
		for (call in calls)
			call(batch, place);

	static function copy(m:Matrix3D):Matrix3D
		return new Matrix3D().copyFrom(m);

	static function copyState(s:MeshState3D):MeshState3D {
		var c = new MeshState3D();
		c.blend = s.blend;
		c.depthTest = s.depthTest;
		c.depthWrite = s.depthWrite;
		c.cull = s.cull;
		c.colorWrite = s.colorWrite;
		return c;
	}

	// A call's own transform, or none, then the list's placement.
	static function placed(own:Null<Matrix3D>, place:Matrix3D, out:Matrix3D):Matrix3D
		return own == null ? out.copyFrom(place) : Matrix3D.compose(own, place, out);

	// Records a 2D call in a plane: its transform copied, then the list's placement.
	function inPlane(transform:Null<Matrix3D>, call:(Batch3D, Matrix3D) -> Void):Void {
		var t = transform == null ? null : copy(transform), m = new Matrix3D();
		planeMatrix = t;
		add((b, place) -> call(b, placed(t, place, m)));
	}

	function boxed(b:Bounds3D, t:Matrix3D):Void {
		if (b.isEmpty)
			return;
		var m = t.values;
		for (corner in 0...8) {
			var x = corner & 1 == 0 ? b.minX : b.maxX,
				y = corner & 2 == 0 ? b.minY : b.maxY,
				z = corner & 4 == 0 ? b.minZ : b.maxZ;
			bounds.expand(m[0] * x + m[4] * y + m[8] * z + m[12], m[1] * x + m[5] * y + m[9] * z + m[13], m[2] * x + m[6] * y + m[10] * z + m[14]);
		}
	}

	function pointsBox(p:Array<Float>, t:Null<Matrix3D>):Void {
		var at = new Vector3D(), i = 0;
		while (i + 2 < p.length) {
			if (t == null)
				bounds.expand(p[i], p[i + 1], p[i + 2]);
			else {
				t.transformPoint(p[i], p[i + 1], p[i + 2], at);
				bounds.expand(at.x, at.y, at.z);
			}
			i += 3;
		}
	}

	// A box of the plane the last call was recorded in.
	function planeBox(minX:Float, minY:Float, maxX:Float, maxY:Float):Void {
		var b = new Bounds3D().set(minX, minY, 0, maxX, maxY, 0);
		boxed(b, planeMatrix == null ? new Matrix3D() : planeMatrix);
	}

	function planePoints(points:Array<Float>, margin:Float):Void {
		var minX = Math.POSITIVE_INFINITY, minY = Math.POSITIVE_INFINITY, maxX = Math.NEGATIVE_INFINITY, maxY = Math.NEGATIVE_INFINITY, i = 0;
		while (i + 1 < points.length) {
			minX = Math.min(minX, points[i]);
			maxX = Math.max(maxX, points[i]);
			minY = Math.min(minY, points[i + 1]);
			maxY = Math.max(maxY, points[i + 1]);
			i += 2;
		}
		if (minX <= maxX)
			planeBox(minX - margin, minY - margin, maxX + margin, maxY + margin);
	}
}
