package helix.render;

import helix.math.Bounds3D;
import helix.math.Matrix3D;

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
		throw "helix-render: DrawList3D.makeEmpty is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawMesh is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawMeshInstanced is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawModel is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawLine is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawLines is not yet built (stage 1)";
	}

	/** Records a box's twelve edges.

		@param bounds  The box, in the list's units; copied.
		@param color  The color. */
	public function strokeBox(bounds:Bounds3D, color:Int):Void {
		throw "helix-render: DrawList3D.strokeBox is not yet built (stage 1)";
	}

	/** Records a sphere as three circles about its center, one square to each axis.

		@param x  The center's x.
		@param y  The center's y.
		@param z  The center's z.
		@param radius  The radius.
		@param color  The color. */
	public function strokeSphere(x:Float, y:Float, z:Float, radius:Float, color:Int):Void {
		throw "helix-render: DrawList3D.strokeSphere is not yet built (stage 1)";
	}

	/** Records a grid of lines on the ground (y 0), centered on the origin.

		@param lineCount  The number of lines each way.
		@param spacing  The distance between two lines.
		@param color  The color. */
	public function drawGrid(lineCount:Int, spacing:Float, color:Int):Void {
		throw "helix-render: DrawList3D.drawGrid is not yet built (stage 1)";
	}

	/** Records a transform's axes from its origin: x red, y green, z blue.

		@param transform  The transform, as a mesh would be placed by it, in the list's units; copied.
		@param length  Each axis' length, before the transform's scale. */
	public function drawAxes(transform:Matrix3D, length:Float):Void {
		throw "helix-render: DrawList3D.drawAxes is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawBillboard is not yet built (stage 1)";
	}

	/** Records positions as points, drawn at the replaying batch's `pointSize`, unlit.

		@param positions  The points' positions, x, y and z each, in the list's units; copied.
		@param color  The color of points without one of their own.
		@param colors  Optional. Each point's own color, 0xAARRGGBB; `color` for every point when omitted.
		@param texture  Optional. The texture across each square, held; white when omitted.
		@param transform  Optional. What the positions are moved by, in the list's units, copied; identity when omitted. */
	public function drawPoints(positions:Array<Float>, color:Int, ?colors:Array<Int>, ?texture:Texture2D, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.drawPoints is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawTriangles is not yet built (stage 1)";
	}

	/** Records lines through points in a plane, one after another, joined at each point with a miter, or a bevel where the miter would
		reach past twice the thickness, as `Batch3D.drawPolyline` draws them; two points are one line, its ends square, cut at the points.

		@param points  The points, x and y each, in the plane's units, copied; fewer than two draws nothing.
		@param thickness  The width, in the plane's units.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function drawPolyline(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.drawPolyline is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.fillTriangle is not yet built (stage 1)";
	}

	/** Records a filled rectangle in a plane.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillRectangle(x:Float, y:Float, width:Float, height:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.fillRectangle is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.strokeRectangle is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.fillRoundedRectangle is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.strokeRoundedRectangle is not yet built (stage 1)";
	}

	/** Records a filled circle in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillCircle(x:Float, y:Float, radius:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.fillCircle is not yet built (stage 1)";
	}

	/** Records a circle's outline in a plane.

		@param x  The center, across.
		@param y  The center, down.
		@param radius  The radius.
		@param thickness  The outline's width, centered on the circle.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function strokeCircle(x:Float, y:Float, radius:Float, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.strokeCircle is not yet built (stage 1)";
	}

	/** Records a filled ellipse in a plane, its axes across and down.

		@param x  The center, across.
		@param y  The center, down.
		@param radiusX  The radius across.
		@param radiusY  The radius down.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function fillEllipse(x:Float, y:Float, radiusX:Float, radiusY:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.fillEllipse is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.strokeEllipse is not yet built (stage 1)";
	}

	/** Records a filled polygon in a plane, convex or not, whose edges don't cross.

		@param points  The corners in order, x and y each, either way round, copied; fewer than three draws nothing.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted.
		@return  False when its edges cross, and nothing is recorded. */
	public function fillPolygon(points:Array<Float>, color:Int, ?transform:Matrix3D):Bool {
		throw "helix-render: DrawList3D.fillPolygon is not yet built (stage 1)";
	}

	/** Records a polygon's outline in a plane: lines through its corners and back to the first, joined as `drawPolyline` joins them.

		@param points  The corners in order, x and y each, copied; fewer than two draws nothing.
		@param thickness  The outline's width, centered on the edges.
		@param color  The color.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function strokePolygon(points:Array<Float>, thickness:Float, color:Int, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.strokePolygon is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawSprite is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawTextureRegion is not yet built (stage 1)";
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
		throw "helix-render: DrawList3D.drawText is not yet built (stage 1)";
	}

	/** Records laid-out text in a plane, as `Batch3D.drawTextLayout` draws it; the layout is held, and drawn as it is at each replay.

		@param layout  The layout, held.
		@param x  The left edge of the layout's box, in which its lines are aligned: the box is `maxWidth` wide, or as wide as its widest
			line when `maxWidth` is 0.
		@param y  The top of the first line.
		@param color  Optional. The color; defaults to white.
		@param transform  Optional. The plane it is drawn in, in the list's units, copied; identity when omitted. */
	public function drawTextLayout(layout:TextLayout2D, x:Float, y:Float, color:Int = 0xffffffff, ?transform:Matrix3D):Void {
		throw "helix-render: DrawList3D.drawTextLayout is not yet built (stage 1)";
	}
}
