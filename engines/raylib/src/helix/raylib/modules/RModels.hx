package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.math.Trig;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.GpuMemory;
import helix.raylib.internal.Animations;
import helix.raylib.internal.Models;
import helix.raylib.internal.ParShapes;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.modules.RRlgl.*;
#end

/** Holds raylib's rmodels (3D shapes, models, meshes, materials and rays), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RModels {
	#if !macro
	// ---- 3D shapes ----
	// As rmodels.c draws them, through rlgl: the same vertices, in the same order, with the same color, normal and texture state.

	/** Draws a line in 3D.

		@param startPos  The start.
		@param endPos  The end.
		@param color  The color. */
	static function DrawLine3D(startPos:Vector3, endPos:Vector3, color:Color):Void {
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex3f(startPos.x, startPos.y, startPos.z);
		rlVertex3f(endPos.x, endPos.y, endPos.z);
		rlEnd();
	}

	/** Draws a point in 3D, as raylib does: a line 0.1 long toward +z.

		@param position  The point.
		@param color  The color. */
	static function DrawPoint3D(position:Vector3, color:Color):Void {
		rlPushMatrix();
		rlTranslatef(position.x, position.y, position.z);
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex3f(0, 0, 0);
		rlVertex3f(0, 0, 0.1);
		rlEnd();
		rlPopMatrix();
	}

	/** Draws a circle's outline in 3D, 36 lines, on the XY plane turned about an axis.

		@param center  Its center.
		@param radius  Its radius.
		@param rotationAxis  The axis it is turned about.
		@param rotationAngle  The angle, in degrees.
		@param color  The color. */
	static function DrawCircle3D(center:Vector3, radius:Float, rotationAxis:Vector3, rotationAngle:Float, color:Color):Void {
		rlPushMatrix();
		rlTranslatef(center.x, center.y, center.z);
		rlRotatef(rotationAngle, rotationAxis.x, rotationAxis.y, rotationAxis.z);
		rlBegin(RL_LINES);
		var i = 0;
		while (i < 360) {
			rlColor4ub(color.r, color.g, color.b, color.a);
			rlVertex3f(Math.sin(DEG2RAD * i) * radius, Math.cos(DEG2RAD * i) * radius, 0);
			rlVertex3f(Math.sin(DEG2RAD * (i + 10)) * radius, Math.cos(DEG2RAD * (i + 10)) * radius, 0);
			i += 10;
		}
		rlEnd();
		rlPopMatrix();
	}

	/** Draws a filled triangle in 3D, its corners counterclockwise from the side it faces.

		@param v1  A corner.
		@param v2  The next.
		@param v3  The last.
		@param color  The color. */
	static function DrawTriangle3D(v1:Vector3, v2:Vector3, v3:Vector3, color:Color):Void {
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex3f(v1.x, v1.y, v1.z);
		rlVertex3f(v2.x, v2.y, v2.z);
		rlVertex3f(v3.x, v3.y, v3.z);
		rlEnd();
	}

	/** Draws a strip of triangles in 3D: each point after the second makes a triangle with the two before it.

		@param points  The points.
		@param pointCount  How many of them; fewer than 3 draws nothing.
		@param color  The color. */
	static function DrawTriangleStrip3D(points:Array<Vector3>, pointCount:Int, color:Color):Void {
		if (pointCount < 3)
			return;
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (i in 2...pointCount) {
			var a = points[i], b = i % 2 == 0 ? points[i - 2] : points[i - 1], c = i % 2 == 0 ? points[i - 1] : points[i - 2];
			rlVertex3f(a.x, a.y, a.z);
			rlVertex3f(b.x, b.y, b.z);
			rlVertex3f(c.x, c.y, c.z);
		}
		rlEnd();
	}

	/** Draws a filled box, each face with its normal.

		@param position  Its center.
		@param width  Its size along x.
		@param height  Along y.
		@param length  Along z.
		@param color  The color. */
	static function DrawCube(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void {
		var w = width / 2, h = height / 2, l = length / 2;
		rlPushMatrix();
		rlTranslatef(position.x, position.y, position.z);
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		// Each face: its normal, then its two triangles' corners, as raylib's.
		for (face in [
			[0, 0, 1, -w, -h, l, w, -h, l, -w, h, l, w, h, l, -w, h, l, w, -h, l],
			[0, 0, -1, -w, -h, -l, -w, h, -l, w, -h, -l, w, h, -l, w, -h, -l, -w, h, -l],
			[0, 1, 0, -w, h, -l, -w, h, l, w, h, l, w, h, -l, -w, h, -l, w, h, l],
			[0, -1, 0, -w, -h, -l, w, -h, l, -w, -h, l, w, -h, -l, w, -h, l, -w, -h, -l],
			[1, 0, 0, w, -h, -l, w, h, -l, w, h, l, w, -h, l, w, -h, -l, w, h, l],
			[-1, 0, 0, -w, -h, -l, -w, h, l, -w, h, -l, -w, -h, l, -w, h, l, -w, -h, -l]
		]) {
			rlNormal3f(face[0], face[1], face[2]);
			for (c in 0...6)
				rlVertex3f(face[3 + c * 3], face[4 + c * 3], face[5 + c * 3]);
		}
		rlEnd();
		rlPopMatrix();
	}

	/** Draws a filled box.

		@param position  Its center.
		@param size  Its size.
		@param color  The color. */
	static function DrawCubeV(position:Vector3, size:Vector3, color:Color):Void {
		DrawCube(position, size.x, size.y, size.z, color);
	}

	/** Draws a box's edges.

		@param position  Its center.
		@param width  Its size along x.
		@param height  Along y.
		@param length  Along z.
		@param color  The color. */
	static function DrawCubeWires(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void {
		var w = width / 2, h = height / 2, l = length / 2;
		rlPushMatrix();
		rlTranslatef(position.x, position.y, position.z);
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		// The front face's four edges, the back's, then the four between them, as raylib's.
		for (edge in [
			  [-w, -h, l, w, -h, l],   [w, -h, l, w, h, l],     [w, h, l, -w, h, l],   [-w, h, l, -w, -h, l],
			[-w, -h, -l, w, -h, -l], [w, -h, -l, w, h, -l],   [w, h, -l, -w, h, -l], [-w, h, -l, -w, -h, -l],
			  [-w, h, l, -w, h, -l],   [w, h, l, w, h, -l], [-w, -h, l, -w, -h, -l],   [w, -h, l, w, -h, -l]
		]) {
			rlVertex3f(edge[0], edge[1], edge[2]);
			rlVertex3f(edge[3], edge[4], edge[5]);
		}
		rlEnd();
		rlPopMatrix();
	}

	/** Draws a box's edges.

		@param position  Its center.
		@param size  Its size.
		@param color  The color. */
	static function DrawCubeWiresV(position:Vector3, size:Vector3, color:Color):Void {
		DrawCubeWires(position, size.x, size.y, size.z, color);
	}

	/** Draws a filled sphere, 16 rings and 16 slices.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param color  The color. */
	static function DrawSphere(centerPos:Vector3, radius:Float, color:Color):Void {
		DrawSphereEx(centerPos, radius, 16, 16, color);
	}

	/** Draws a filled sphere: rings bands of slices, from the top, each vertex with its normal.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param rings  Bands top to bottom.
		@param slices  Slices around.
		@param color  The color. */
	static function DrawSphereEx(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void {
		rlPushMatrix();
		rlTranslatef(centerPos.x, centerPos.y, centerPos.z);
		rlScalef(radius, radius, radius);
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		var faces = sphereFaces(rings, slices);
		for (k in 0...faces.length >> 2) {
			var v0 = faces[k * 4],
				v1 = faces[k * 4 + 1],
				v2 = faces[k * 4 + 2],
				v3 = faces[k * 4 + 3];
			for (v in [v0, v3, v1, v0, v2, v3]) {
				rlNormal3f(v[0], v[1], v[2]);
				rlVertex3f(v[0], v[1], v[2]);
			}
		}
		rlEnd();
		rlPopMatrix();
	}

	/** Draws a sphere's wires: rings bands of slices, from the top, each face's longitude, latitude and diagonal lines.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param rings  Bands top to bottom.
		@param slices  Slices around.
		@param color  The color. */
	static function DrawSphereWires(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void {
		rlPushMatrix();
		rlTranslatef(centerPos.x, centerPos.y, centerPos.z);
		rlScalef(radius, radius, radius);
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		var faces = sphereFaces(rings, slices);
		for (k in 0...faces.length >> 2) {
			var v0 = faces[k * 4],
				v1 = faces[k * 4 + 1],
				v2 = faces[k * 4 + 2],
				v3 = faces[k * 4 + 3];
			for (v in [v0, v1, v0, v2, v0, v3])
				rlVertex3f(v[0], v[1], v[2]);
		}
		rlEnd();
		rlPopMatrix();
	}

	// A unit sphere's faces as raylib 6.2's DrawSphereEx and DrawSphereWires make them, four corners each: rings bands of 180 / rings
	// degrees, each of slices faces, the corners turned about y for the next face and about z for the next band.
	static function sphereFaces(rings:Int, slices:Int):Array<Array<Float>> {
		var ringangle = DEG2RAD * (180.0 / rings),
			sliceangle = DEG2RAD * (360.0 / slices);
		var cosring = Math.cos(ringangle), sinring = Math.sin(ringangle);
		var cosslice = Math.cos(sliceangle), sinslice = Math.sin(sliceangle);
		var v2 = [0., 1, 0], v3 = [sinring, cosring, 0];
		var faces = [];
		for (_ in 0...rings) {
			for (_ in 0...slices) {
				var v0 = v2, v1 = v3;
				v2 = [cosslice * v2[0] - sinslice * v2[2], v2[1], sinslice * v2[0] + cosslice * v2[2]];
				v3 = [cosslice * v3[0] - sinslice * v3[2], v3[1], sinslice * v3[0] + cosslice * v3[2]];
				faces.push(v0);
				faces.push(v1);
				faces.push(v2);
				faces.push(v3);
			}
			v2 = v3;
			v3 = [cosring * v3[0] + sinring * v3[1], -sinring * v3[0] + cosring * v3[1], v3[2]];
		}
		return faces;
	}

	/** Draws a filled cylinder standing on the XZ plane, or a cone when its top's radius is 0.

		@param position  Its base's center.
		@param radiusTop  Its top's radius.
		@param radiusBottom  Its base's.
		@param height  Its height.
		@param sides  Its sides, at least 3.
		@param color  The color. */
	static function DrawCylinder(position:Vector3, radiusTop:Float, radiusBottom:Float, height:Float, sides:Int, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var angleStep = 360.0 / sides;
		inline function x(i:Int, r:Float):Float
			return Math.sin(DEG2RAD * i * angleStep) * r;
		inline function z(i:Int, r:Float):Float
			return Math.cos(DEG2RAD * i * angleStep) * r;
		rlPushMatrix();
		rlTranslatef(position.x, position.y, position.z);
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		if (radiusTop > 0) {
			for (i in 0...sides) {
				rlVertex3f(x(i, radiusBottom), 0, z(i, radiusBottom));
				rlVertex3f(x(i + 1, radiusBottom), 0, z(i + 1, radiusBottom));
				rlVertex3f(x(i + 1, radiusTop), height, z(i + 1, radiusTop));
				rlVertex3f(x(i, radiusTop), height, z(i, radiusTop));
				rlVertex3f(x(i, radiusBottom), 0, z(i, radiusBottom));
				rlVertex3f(x(i + 1, radiusTop), height, z(i + 1, radiusTop));
			}
			for (i in 0...sides) {
				rlVertex3f(0, height, 0);
				rlVertex3f(x(i, radiusTop), height, z(i, radiusTop));
				rlVertex3f(x(i + 1, radiusTop), height, z(i + 1, radiusTop));
			}
		} else
			for (i in 0...sides) {
				rlVertex3f(0, height, 0);
				rlVertex3f(x(i, radiusBottom), 0, z(i, radiusBottom));
				rlVertex3f(x(i + 1, radiusBottom), 0, z(i + 1, radiusBottom));
			}
		for (i in 0...sides) {
			rlVertex3f(0, 0, 0);
			rlVertex3f(x(i + 1, radiusBottom), 0, z(i + 1, radiusBottom));
			rlVertex3f(x(i, radiusBottom), 0, z(i, radiusBottom));
		}
		rlEnd();
		rlPopMatrix();
	}

	// The corners of a cylinder's side i from start to end: w1 and w2 at the start, w3 and w4 at the end, as raylib's DrawCylinderEx
	// and DrawCylinderWiresEx make them. Null when start and end are one point.
	static function cylinderSides(startPos:Vector3, endPos:Vector3, startRadius:Float, endRadius:Float, sides:Int):Null<Array<Array<Vector3>>> {
		var direction = new Vector3(endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z);
		if (direction.x == 0 && direction.y == 0 && direction.z == 0)
			return null;
		var b1 = Vector3Normalize(Vector3Perpendicular(direction));
		var b2 = Vector3Normalize(Vector3CrossProduct(b1, direction));
		var baseAngle = (2.0 * PI) / sides;
		function corner(p:Vector3, k:Int, r:Float):Vector3 {
			var s = Math.sin(baseAngle * k) * r,
				c = Math.cos(baseAngle * k) * r;
			return new Vector3(p.x + s * b1.x + c * b2.x, p.y + s * b1.y + c * b2.y, p.z + s * b1.z + c * b2.z);
		}
		return [
			for (i in 0...sides) [
				corner(startPos, i, startRadius),
				corner(startPos, i + 1, startRadius),
				corner(endPos, i, endRadius),
				corner(endPos, i + 1, endRadius)
			]
		];
	}

	/** Draws a filled cylinder from one point to another, or a cone when a radius is 0.

		@param startPos  Its base's center.
		@param endPos  Its top's.
		@param startRadius  Its base's radius.
		@param endRadius  Its top's.
		@param sides  Its sides, at least 3.
		@param color  The color. */
	static function DrawCylinderEx(startPos:Vector3, endPos:Vector3, startRadius:Float, endRadius:Float, sides:Int, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var all = cylinderSides(startPos, endPos, startRadius, endRadius, sides);
		if (all == null)
			return;
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (w in all) {
			var points = [];
			if (startRadius > 0)
				points = points.concat([startPos, w[1], w[0]]);
			points = points.concat([w[0], w[1], w[2], w[1], w[3], w[2]]);
			if (endRadius > 0)
				points = points.concat([endPos, w[2], w[3]]);
			for (p in points)
				rlVertex3f(p.x, p.y, p.z);
		}
		rlEnd();
	}

	/** Draws a cylinder's wires standing on the XZ plane, or a cone's when its top's radius is 0.

		@param position  Its base's center.
		@param radiusTop  Its top's radius.
		@param radiusBottom  Its base's.
		@param height  Its height.
		@param sides  Its sides, at least 3.
		@param color  The color. */
	static function DrawCylinderWires(position:Vector3, radiusTop:Float, radiusBottom:Float, height:Float, sides:Int, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var angleStep = 360.0 / sides;
		inline function x(i:Int, r:Float):Float
			return Math.sin(DEG2RAD * i * angleStep) * r;
		inline function z(i:Int, r:Float):Float
			return Math.cos(DEG2RAD * i * angleStep) * r;
		rlPushMatrix();
		rlTranslatef(position.x, position.y, position.z);
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (i in 0...sides) {
			rlVertex3f(x(i, radiusBottom), 0, z(i, radiusBottom));
			rlVertex3f(x(i + 1, radiusBottom), 0, z(i + 1, radiusBottom));
			rlVertex3f(x(i + 1, radiusBottom), 0, z(i + 1, radiusBottom));
			rlVertex3f(x(i + 1, radiusTop), height, z(i + 1, radiusTop));
			rlVertex3f(x(i + 1, radiusTop), height, z(i + 1, radiusTop));
			rlVertex3f(x(i, radiusTop), height, z(i, radiusTop));
			rlVertex3f(x(i, radiusTop), height, z(i, radiusTop));
			rlVertex3f(x(i, radiusBottom), 0, z(i, radiusBottom));
		}
		rlEnd();
		rlPopMatrix();
	}

	/** Draws a cylinder's wires from one point to another, or a cone's when a radius is 0.

		@param startPos  Its base's center.
		@param endPos  Its top's.
		@param startRadius  Its base's radius.
		@param endRadius  Its top's.
		@param sides  Its sides, at least 3.
		@param color  The color. */
	static function DrawCylinderWiresEx(startPos:Vector3, endPos:Vector3, startRadius:Float, endRadius:Float, sides:Int, color:Color):Void {
		if (sides < 3)
			sides = 3;
		var all = cylinderSides(startPos, endPos, startRadius, endRadius, sides);
		if (all == null)
			return;
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (w in all)
			for (p in [w[0], w[1], w[0], w[2], w[2], w[3]])
				rlVertex3f(p.x, p.y, p.z);
		rlEnd();
	}

	// A capsule's quads, as raylib's DrawCapsule and DrawCapsuleWires make them: each cap's rings and slices, the end's then the start's,
	// then the middle's slices, each [w1, w2, w3, w4] and whether it is the start's cap.
	static function capsuleQuads(startPos:Vector3, endPos:Vector3, radius:Float, slices:Int, rings:Int):Array<{w:Array<Vector3>, start:Bool}> {
		var direction = new Vector3(endPos.x - startPos.x, endPos.y - startPos.y, endPos.z - startPos.z);
		var sphereCase = direction.x == 0 && direction.y == 0 && direction.z == 0;
		if (sphereCase)
			direction = new Vector3(0, 1, 0);
		var b0 = Vector3Normalize(direction);
		var b1 = Vector3Normalize(Vector3Perpendicular(direction));
		var b2 = Vector3Normalize(Vector3CrossProduct(b1, direction));
		var capCenter = endPos;
		var baseSliceAngle = (2.0 * PI) / slices,
			baseRingAngle = PI * 0.5 / rings;
		var quads = [];
		for (c in 0...2) {
			function cap(i:Int, j:Int):Vector3 {
				var ringSin = Math.sin(baseSliceAngle * j) * Math.cos(baseRingAngle * i),
					ringCos = Math.cos(baseSliceAngle * j) * Math.cos(baseRingAngle * i),
					up = Math.sin(baseRingAngle * i);
				return new Vector3(capCenter.x
					+ (up * b0.x + ringSin * b1.x + ringCos * b2.x) * radius,
					capCenter.y
					+ (up * b0.y + ringSin * b1.y + ringCos * b2.y) * radius, capCenter.z
					+ (up * b0.z + ringSin * b1.z + ringCos * b2.z) * radius);
			}
			for (i in 0...rings)
				for (j in 0...slices)
					quads.push({w: [cap(i, j), cap(i, j + 1), cap(i + 1, j), cap(i + 1, j + 1)], start: c == 1});
			capCenter = startPos;
			b0 = Vector3Scale(b0, -1.0);
		}
		if (!sphereCase) {
			function side(p:Vector3, j:Int):Vector3 {
				var ringSin = Math.sin(baseSliceAngle * j) * radius,
					ringCos = Math.cos(baseSliceAngle * j) * radius;
				return new Vector3(p.x + ringSin * b1.x + ringCos * b2.x, p.y + ringSin * b1.y + ringCos * b2.y, p.z + ringSin * b1.z + ringCos * b2.z);
			}
			for (j in 0...slices)
				quads.push({w: [side(startPos, j), side(startPos, j + 1), side(endPos, j), side(endPos, j + 1)], start: false});
		}
		return quads;
	}

	/** Draws a filled capsule: a cylinder with half a sphere on each end, their centers the two points.

		@param startPos  One end's center.
		@param endPos  The other's.
		@param radius  Its radius.
		@param slices  Slices around, at least 3.
		@param rings  Rings in each half sphere, at least 1.
		@param color  The color. */
	static function DrawCapsule(startPos:Vector3, endPos:Vector3, radius:Float, slices:Int, rings:Int, color:Color):Void {
		if (slices < 3)
			slices = 3;
		if (rings < 1)
			rings = 1;
		rlBegin(RL_TRIANGLES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		for (q in capsuleQuads(startPos, endPos, radius, slices, rings)) {
			var w = q.w;
			// The end's cap and the middle wind one way, the start's the other, so each faces out.
			var order = q.start ? [w[0], w[2], w[1], w[1], w[2], w[3]] : [w[0], w[1], w[2], w[1], w[3], w[2]];
			for (p in order)
				rlVertex3f(p.x, p.y, p.z);
		}
		rlEnd();
	}

	/** Draws a capsule's wires: a cylinder with half a sphere on each end, their centers the two points.

		@param startPos  One end's center.
		@param endPos  The other's.
		@param radius  Its radius.
		@param slices  Slices around, at least 3.
		@param rings  Rings in each half sphere, at least 1.
		@param color  The color. */
	static function DrawCapsuleWires(startPos:Vector3, endPos:Vector3, radius:Float, slices:Int, rings:Int, color:Color):Void {
		if (slices < 3)
			slices = 3;
		if (rings < 1)
			rings = 1;
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		var caps = rings * slices * 2;
		for (k => q in capsuleQuads(startPos, endPos, radius, slices, rings)) {
			var w = q.w;
			var order = k < caps ? [w[0], w[1], w[1], w[2], w[0], w[2], w[1], w[3], w[2], w[3]] : [w[0], w[2], w[1], w[3], w[1], w[2]];
			for (p in order)
				rlVertex3f(p.x, p.y, p.z);
		}
		rlEnd();
	}

	/** Draws a flat rectangle on the XZ plane, facing up.

		@param centerPos  Its center.
		@param size  Its size along x and z.
		@param color  The color. */
	static function DrawPlane(centerPos:Vector3, size:Vector2, color:Color):Void {
		rlPushMatrix();
		rlTranslatef(centerPos.x, centerPos.y, centerPos.z);
		rlScalef(size.x, 1.0, size.y);
		rlBegin(RL_QUADS);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlNormal3f(0, 1, 0);
		rlVertex3f(-0.5, 0, -0.5);
		rlVertex3f(-0.5, 0, 0.5);
		rlVertex3f(0.5, 0, 0.5);
		rlVertex3f(0.5, 0, -0.5);
		rlEnd();
		rlPopMatrix();
	}

	/** Draws a ray as a line 10000 long.

		@param ray  The ray.
		@param color  The color. */
	static function DrawRay(ray:Ray, color:Color):Void {
		var scale = 10000;
		rlBegin(RL_LINES);
		rlColor4ub(color.r, color.g, color.b, color.a);
		rlVertex3f(ray.position.x, ray.position.y, ray.position.z);
		rlVertex3f(ray.position.x
			+ ray.direction.x * scale, ray.position.y
			+ ray.direction.y * scale, ray.position.z
			+ ray.direction.z * scale);
		rlEnd();
	}

	/** Draws a grid on the XZ plane, centered on the origin, its center lines darker, as raylib's.

		@param slices  The lines each way.
		@param spacing  The space between them. */
	static function DrawGrid(slices:Int, spacing:Float):Void {
		var halfSlices = Std.int(slices / 2);
		rlBegin(RL_LINES);
		for (i in -halfSlices...halfSlices + 1) {
			if (i == 0)
				rlColor3f(0.5, 0.5, 0.5);
			else
				rlColor3f(0.75, 0.75, 0.75);
			rlVertex3f(i * spacing, 0, -halfSlices * spacing);
			rlVertex3f(i * spacing, 0, halfSlices * spacing);
			rlVertex3f(-halfSlices * spacing, 0, i * spacing);
			rlVertex3f(halfSlices * spacing, 0, i * spacing);
		}
		rlEnd();
	}

	/** Draws a bounding box's edges.

		@param box  The box.
		@param color  The color. */
	static function DrawBoundingBox(box:BoundingBox, color:Color):Void {
		var size = new Vector3(Math.abs(box.max.x - box.min.x), Math.abs(box.max.y - box.min.y), Math.abs(box.max.z - box.min.z));
		var center = new Vector3(box.min.x + size.x / 2.0, box.min.y + size.y / 2.0, box.min.z + size.z / 2.0);
		DrawCubeWires(center, size.x, size.y, size.z, color);
	}

	/** Draws a texture facing the camera, turning about y alone, at a height of scale and its own proportions.

		@param camera  The camera.
		@param texture  The texture.
		@param position  Its center.
		@param scale  Its height.
		@param tint  The tint. */
	static function DrawBillboard(camera:Camera, texture:Texture2D, position:Vector3, scale:Float, tint:Color):Void {
		var source = new Rectangle(0, 0, texture.width, texture.height);
		DrawBillboardRec(camera, texture, source, position, new Vector2(scale * Math.abs(source.width / source.height), scale), tint);
	}

	/** Draws part of a texture facing the camera, turning about y alone.

		@param camera  The camera.
		@param texture  The texture.
		@param source  The part, in its pixels.
		@param position  Its center.
		@param size  Its size; a negative one flips it.
		@param tint  The tint. */
	static function DrawBillboardRec(camera:Camera, texture:Texture2D, source:Rectangle, position:Vector3, size:Vector2, tint:Color):Void {
		var up = new Vector3(0, 1, 0);
		DrawBillboardPro(camera, texture, source, position, up, size, Vector2Scale(size, 0.5), 0, tint);
	}

	/** Draws part of a texture facing the camera's right and an up of its own, turned about the way it faces.

		@param camera  The camera.
		@param texture  The texture.
		@param source  The part, in its pixels.
		@param position  Where its origin is.
		@param up  Its up.
		@param size  Its size; a negative one flips it.
		@param origin  The point of it at the position, from its bottom left, in the size's units.
		@param rotation  How far it turns about its origin, in degrees.
		@param tint  The tint. */
	static function DrawBillboardPro(camera:Camera, texture:Texture2D, source:Rectangle, position:Vector3, up:Vector3, size:Vector2, origin:Vector2,
			rotation:Float, tint:Color):Void {
		var matView = MatrixLookAt(camera.position, camera.target, camera.up);
		var right = Vector3Scale(new Vector3(matView.m0, matView.m4, matView.m8), size.x);
		up = Vector3Scale(up, size.y);
		var sx = source.x, sy = source.y, sw = source.width, sh = source.height, ox = origin.x, oy = origin.y;
		// Flipped, its corners still counterclockwise; the part moves by the size, as raylib 6.2 moves it (#5276).
		if (size.x < 0) {
			sx -= size.x;
			sw *= -1.0;
			right = Vector3Negate(right);
			ox *= -1.0;
		}
		if (size.y < 0) {
			sy -= size.y;
			sh *= -1.0;
			up = Vector3Negate(up);
			oy *= -1.0;
		}
		var forward = rotation != 0 ? Vector3CrossProduct(right, up) : new Vector3();
		var origin3D = Vector3Add(Vector3Scale(Vector3Normalize(right), ox), Vector3Scale(Vector3Normalize(up), oy));
		var points = [new Vector3(), right, Vector3Add(up, right), up];
		for (i in 0...4) {
			points[i] = Vector3Subtract(points[i], origin3D);
			if (rotation != 0)
				points[i] = Vector3RotateByAxisAngle(points[i], forward, rotation * DEG2RAD);
			points[i] = Vector3Add(points[i], position);
		}
		var tw:Float = texture.width, th:Float = texture.height;
		var texcoords = [
			[sx / tw, (sy + sh) / th],
			[(sx + sw) / tw, (sy + sh) / th],
			[(sx + sw) / tw, sy / th],
			[sx / tw, sy / th]
		];
		rlSetTexture(texture.id);
		rlBegin(RL_QUADS);
		rlColor4ub(tint.r, tint.g, tint.b, tint.a);
		for (i in 0...4) {
			rlTexCoord2f(texcoords[i][0], texcoords[i][1]);
			rlVertex3f(points[i].x, points[i].y, points[i].z);
		}
		rlEnd();
		rlSetTexture(0);
	}

	// ---- Models and meshes ----

	/** raylib's model load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadModelAsync` loads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadModel: Synchronous loading is not supported. See LoadModelAsync(fileName:String, loaded:Model->Void, ?failed:String->Void) in helix.raylib.extras.Models (import helix.raylib.extras.Models.*;)")
	static function LoadModel(fileName:String):Model {
		throw "LoadModel is unimplemented";
	}

	/** raylib's material load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadMaterialsAsync`
		loads them.

		@param fileName  The file.
		@param materialCount  Receives how many.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadMaterials: Synchronous loading is not supported. See LoadMaterialsAsync(fileName:String, loaded:Array<Material>->Void, ?failed:String->Void) in helix.raylib.extras.Models (import helix.raylib.extras.Models.*;)")
	static function LoadMaterials(fileName:String, materialCount:Array<Int>):Array<Material> {
		throw "LoadMaterials is unimplemented";
	}

	// The model of a glTF, GLB or OBJ file `LoadModelAsync` brought in: its meshes, their materials and its images. A file loaded again shares
	// its other loads' meshes' GPU buffers and textures while one lives, with materials of its own; meshes go to the GPU when first drawn.

	static function loadModel(fileName:String):Model {
		var model = Models.load(normalize(fileName));
		if (model != null)
			return model;
		var material = Models.defaultMaterial(defaultShader());
		model = new Model([], [material], []);
		Models.disown([], [material]);
		return model;
	}

	/** Makes a model of one mesh, with the default material. The model takes over the program's hold on the mesh, as a raylib program
		doesn't unload a mesh it gave a model: `UnloadModel` frees it, and a later `UnloadMesh` does nothing.

		@param mesh  The mesh.
		@return  The model. */
	static function LoadModelFromMesh(mesh:Mesh):Model {
		var material = Models.defaultMaterial(defaultShader());
		var model = new Model([mesh], [material], [0]);
		Models.disown([mesh], [material]);
		return model;
	}

	/** Returns whether a model has meshes.

		@param model  The model.
		@return  True when it has. */
	static function IsModelValid(model:Model):Bool {
		return model.meshCount > 0;
	}

	/** Frees a model: it lets go of its meshes and materials, and what no one else holds is freed with it (docs/DECISIONS.md 25): a
		mesh's GPU buffers, a material's maps' textures and its shader, each when nothing else holds it (another load of its file, another
		model, the program); the default shader and texture stay. The model is left empty, so unloading it again does nothing.

		raylib's frees only the meshes, and leaves the textures and shaders to the program. Where helix-raylib's differs: a texture or shader
		copied out of a material (`var t = map.texture`) and used after the model is unloaded is freed, where raylib's leaks it; and a
		material or mesh shared between models works, where raylib's C frees it twice.

		@param model  The model. */
	static function UnloadModel(model:Model):Void {
		model.meshes = [];
		model.materials = [];
		if (model.path != "") {
			Models.release(model.path);
			model.path = "";
		}
	}

	/** Draws a model at a position and a scale, its materials' colors times a tint.

		@param model  The model.
		@param position  Where.
		@param scale  The scale, the same on each axis.
		@param tint  The tint. */
	static function DrawModel(model:Model, position:Vector3, scale:Float, tint:Color):Void {
		DrawModelEx(model, position, new Vector3(0, 1, 0), 0, new Vector3(scale, scale, scale), tint);
	}

	/** Draws a model scaled, turned about an axis and moved, after its own transform.

		@param model  The model.
		@param position  Where.
		@param rotationAxis  The axis.
		@param rotationAngle  The angle, in degrees.
		@param scale  The scale on each axis.
		@param tint  The tint. */
	static function DrawModelEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void {
		var m = Matrix3D.fromScale(scale.x, scale.y, scale.z);
		m = Matrix3D.compose(m, Matrix3D.fromRotation(rotationAxis.x, rotationAxis.y, rotationAxis.z, rotationAngle * DEG2RAD));
		m = Matrix3D.compose(m, Matrix3D.fromTranslation(position.x, position.y, position.z));
		var transform = Matrix3D.compose(toMatrix3D(model.transform), m);
		for (i in 0...model.meshCount) {
			var material = model.materials[model.meshMaterial[i]];
			if (material == null)
				material = model.materials[0];
			drawMesh(model.meshes[i], material, transform, tint);
		}
	}

	/** Draws a model's triangles as their edges, as `DrawModel` places it, through rlgl's wire mode.

		@param model  The model.
		@param position  Where.
		@param scale  The scale, the same on each axis.
		@param tint  The tint. */
	static function DrawModelWires(model:Model, position:Vector3, scale:Float, tint:Color):Void {
		rlEnableWireMode();
		DrawModel(model, position, scale, tint);
		rlDisableWireMode();
	}

	/** Draws a model's triangles as their edges, as `DrawModelEx` places it, through rlgl's wire mode.

		@param model  The model.
		@param position  Where.
		@param rotationAxis  The axis.
		@param rotationAngle  The angle, in degrees.
		@param scale  The scale on each axis.
		@param tint  The tint. */
	static function DrawModelWiresEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void {
		rlEnableWireMode();
		DrawModelEx(model, position, rotationAxis, rotationAngle, scale, tint);
		rlDisableWireMode();
	}

	/** Draws a model's triangles as their corners, one pixel each, as `DrawModel` places it, through rlgl's point mode with culling off.

		Each index of a mesh's triangles is a point, or each vertex of its whole triangles when it has no indices (a cloud of points is a
		mesh of vertices alone). Culling is on after it, as raylib leaves it.
		@param model  The model.
		@param position  Where.
		@param scale  The scale, the same on each axis.
		@param tint  The tint. */
	static function DrawModelPoints(model:Model, position:Vector3, scale:Float, tint:Color):Void {
		rlEnablePointMode();
		rlDisableBackfaceCulling();
		DrawModel(model, position, scale, tint);
		rlEnableBackfaceCulling();
		rlDisableWireMode();
	}

	/** Draws a model's triangles as their corners, one pixel each, as `DrawModelEx` places it, through rlgl's point mode with culling off.

		Each index of a mesh's triangles is a point, or each vertex of its whole triangles when it has no indices. Culling is on after it,
		as raylib leaves it.
		@param model  The model.
		@param position  Where.
		@param rotationAxis  The axis.
		@param rotationAngle  The angle, in degrees.
		@param scale  The scale on each axis.
		@param tint  The tint. */
	static function DrawModelPointsEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void {
		rlEnablePointMode();
		rlDisableBackfaceCulling();
		DrawModelEx(model, position, rotationAxis, rotationAngle, scale, tint);
		rlEnableBackfaceCulling();
		rlDisableWireMode();
	}

	/** Draws a mesh with a material and a transform.

		The material's maps bind as raylib's: the first three at `texture0` to `texture2`, and each other map with a texture at the sampler
		`shader.locs[SHADER_LOC_MAP_DIFFUSE + index]` names, or at a sampler set to its index with `SetShaderValue` (raylib's skybox sets
		its `samplerCube` to `MATERIAL_MAP_CUBEMAP`). `MATERIAL_MAP_CUBEMAP`, `MATERIAL_MAP_IRRADIANCE` and `MATERIAL_MAP_PREFILTER` bind a
		cubemap (`LoadTextureCubemap`) to a `samplerCube`, the rest a 2D texture to a `sampler2D`; a texture of the other kind binds nothing.

		@param mesh  The mesh.
		@param material  The material.
		@param transform  The transform. */
	static function DrawMesh(mesh:Mesh, material:Material, transform:Matrix):Void {
		drawMesh(mesh, material, toMatrix3D(transform), WHITE);
	}

	/** Draws a mesh many times in one draw, as raylib 5.5's does: each instance is placed by its own transform, which the material's
		shader takes as a `mat4` attribute at `shader.locs[SHADER_LOC_MATRIX_MODEL]` and applies itself (raylib's instancing example sets
		it with `GetShaderLocationAttrib(shader, "instanceTransform")`). `mvp` is the camera's alone, and `matNormal` the identity. A shader
		without a `mat4` attribute there draws nothing, with a warning. The mesh's attributes and the transforms are a buffer each, eight
		at most, so a shader reading every one of raylib's attributes besides the transforms can't be drawn.

		@param mesh  The mesh.
		@param material  Its material: the shader, the diffuse color and the textures.
		@param transforms  The instances' transforms.
		@param instances  How many instances, at most the transforms given. */
	static function DrawMeshInstanced(mesh:Mesh, material:Material, transforms:Array<Matrix>, instances:Int):Void {
		var count = transforms == null ? 0 : instances < transforms.length ? instances : transforms.length;
		if (count <= 0)
			return;
		var shader = material.shader == null || material.shader.program == null ? defaultShader() : material.shader;
		var slot = shader.locs[SHADER_LOC_MATRIX_MODEL],
			names = shader.program.attributes;
		if (slot < 0 || slot + 4 > names.length || names[slot] == "" || names[slot + 1] != "") {
			Runtime.log(LOG_WARNING,
				'SHADER: [ID ${shader.id}] DrawMeshInstanced: no mat4 attribute at SHADER_LOC_MATRIX_MODEL for the instances\' transforms');
			return;
		}
		var bytes = haxe.io.Bytes.alloc(count * 64);
		for (i in 0...count)
			for (k => v in toMatrix3D(transforms[i]).values)
				bytes.setFloat((i * 16 + k) * 4, v);
		var buffer = GpuMemory.buffer(Runtime.graphics.createStaticBuffer(bytes, bytes.length, false), bytes.length);
		Runtime.frame.retire(buffer);
		drawMesh(mesh, material, new Matrix3D(), WHITE, buffer, count);
	}

	/** Sends a mesh's vertices to the GPU, so it can be drawn. A mesh not sent goes when it is first drawn, as `LoadModelAsync`'s and the
		`GenMesh*` functions' do.

		An attribute the mesh has no array for reads a default in a shader: texture coordinates 0, 0, normals 0, 0, 1, colors white,
		tangents 1, 0, 0, 1, second texture coordinates, bone ids and bone weights 0.

		@param mesh  The mesh.
		@param isDynamic  Whether it will change (raylib names it `dynamic`, a Haxe keyword); any mesh here can be changed by
			`UpdateMeshBuffer`, so it is ignored. */
	static function UploadMesh(mesh:Mesh, isDynamic:Bool):Void {
		Models.upload(mesh);
	}

	/** Changes part of one of a mesh's buffers on the GPU, as raylib's: the mesh's own arrays stay as they were. Draws asked for before
		it keep what was there; those after see the change.

		@param mesh  The mesh, uploaded (`UploadMesh`, or drawn once); one that isn't changes nothing.
		@param index  The buffer: 0 positions, 1 texture coordinates, 2 normals, 3 colors, 4 tangents, 5 second texture coordinates,
			6 indices. One the mesh has no array for changes nothing.
		@param data  The new values: raylib's bytes (`haxe.io.Bytes`: 32-bit floats, colors a byte each, indices 16-bit), or an array of
			the numbers (colors 0 to 255).
		@param dataSize  How many bytes they are, as raylib counts them.
		@param offset  Where they go in the buffer, in raylib's bytes. */
	static function UpdateMeshBuffer(mesh:Mesh, index:Int, data:Dynamic, dataSize:Int, offset:Int):Void {
		if (index < 0 || index > 6 || data == null)
			return;
		var size = [4, 4, 4, 1, 4, 4, 2][index],
			count = Std.int(dataSize / size);
		var values:Array<Float> = [];
		if (Std.isOfType(data, haxe.io.Bytes)) {
			var bytes:haxe.io.Bytes = data;
			for (i in 0...count)
				if ((i + 1) * size <= bytes.length)
					values.push(index == 3 ? bytes.get(i) : index == 6 ? bytes.getUInt16(i * 2) : bytes.getFloat(i * 4));
		} else if (Std.isOfType(data, Array)) {
			var numbers:Array<Dynamic> = data;
			for (i in 0...count)
				if (i < numbers.length)
					values.push((numbers[i] : Float));
		}
		Models.update(mesh, index, values, offset);
	}

	/** Lets go of the program's hold on a mesh, freeing its GPU buffers unless a model still holds it (docs/DECISIONS.md 25). A mesh given
		to `LoadModelFromMesh`, or already freed, is left: the model frees it.

		@param mesh  The mesh. */
	static function UnloadMesh(mesh:Mesh):Void {
		Models.releaseMesh(mesh);
	}

	/** Makes a flat regular polygon on the XZ plane, facing up, centered on the origin: a triangle a side, with no indices, its texture
		coordinates 0.

		@param sides  Its sides; fewer than 3 make an empty mesh.
		@param radius  Its corners' distance from the center.
		@return  The mesh. */
	static function GenMeshPoly(sides:Int, radius:Float):Mesh {
		var mesh = new Mesh();
		if (sides < 3)
			return mesh;
		var vertexCount = sides * 3;
		var vertices = [], d = 0.0, dStep = 360.0 / sides;
		for (_ in 0...sides) {
			for (v in [
				0,
				0,
				0,
				Trig.sin(DEG2RAD * d) * radius,
				0,
				Trig.cos(DEG2RAD * d) * radius,
				Trig.sin(DEG2RAD * (d + dStep)) * radius,
				0,
				Trig.cos(DEG2RAD * (d + dStep)) * radius
			])
				vertices.push(v);
			d += dStep;
		}
		mesh.vertexCount = vertexCount;
		mesh.triangleCount = sides;
		mesh.vertices = vertices;
		mesh.texcoords = [for (_ in 0...vertexCount * 2) 0.];
		mesh.normals = [for (_ in 0...vertexCount) for (c in [0., 1, 0]) c];
		return mesh;
	}

	/** Makes a flat mesh on the XZ plane, facing up, centered on the origin: a grid of vertices shared by its cells' triangles.

		@param width  Along x.
		@param length  Along z.
		@param resX  Cells along x.
		@param resZ  Cells along z.
		@return  The mesh. */
	static function GenMeshPlane(width:Float, length:Float, resX:Int, resZ:Int):Mesh {
		var mesh = new Mesh();
		resX++;
		resZ++;
		var vertexCount = resX * resZ;
		var vertices = [], texcoords = [];
		for (z in 0...resZ) {
			var zPos = (z / (resZ - 1) - 0.5) * length;
			for (x in 0...resX) {
				vertices.push((x / (resX - 1) - 0.5) * width);
				vertices.push(0);
				vertices.push(zPos);
			}
		}
		for (v in 0...resZ)
			for (u in 0...resX) {
				texcoords.push(u / (resX - 1));
				texcoords.push(v / (resZ - 1));
			}
		var numFaces = (resX - 1) * (resZ - 1), triangles = [];
		for (face in 0...numFaces) {
			// The face's lower left corner.
			var i = face + Std.int(face / (resX - 1));
			for (t in [i + resX, i + 1, i, i + resX, i + resX + 1, i + 1])
				triangles.push(t);
		}
		mesh.vertexCount = vertexCount;
		mesh.triangleCount = numFaces * 2;
		mesh.vertices = vertices;
		mesh.texcoords = texcoords;
		mesh.normals = [for (_ in 0...vertexCount) for (c in [0., 1, 0]) c];
		mesh.indices = triangles;
		return mesh;
	}

	/** Makes a box mesh, centered on the origin: four vertices a face, each face's texture its whole.

		@param width  Along x.
		@param height  Along y.
		@param length  Along z.
		@return  The mesh. */
	static function GenMeshCube(width:Float, height:Float, length:Float):Mesh {
		var w = width / 2, h = height / 2, l = length / 2;
		var mesh = new Mesh();
		mesh.vertices = [-w,
			-h, l, w,
			-h, l, w, h, l,
			-w, h, l,
			-w,
			-h,
			-l,
			-w, h,
			-l, w, h,
			-l, w,
			-h,
			-l,
			-w, h,
			-l,
			-w, h, l, w, h, l, w, h,
			-l,
			-w,
			-h,
			-l, w,
			-h,
			-l,
			w,
			-h, l,
			-w,
			-h, l, w,
			-h,
			-l, w, h,
			-l, w, h, l, w,
			-h, l,
			-w,
			-h,
			-l,
			-w,
			-h, l,
			-w, h, l,
			-w, h,
			-l];
		mesh.texcoords = [
			0., 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1
		];
		mesh.normals = [
			for (n in [[0., 0, 1], [0., 0, -1], [0., 1, 0], [0., -1, 0], [1., 0, 0], [-1., 0, 0]])
				for (_ in 0...4)
					for (c in n)
						c
		];
		mesh.indices = [for (k in 0...6) for (i in [0, 1, 2, 0, 2, 3]) 4 * k + i];
		mesh.vertexCount = 24;
		mesh.triangleCount = 12;
		return mesh;
	}

	/** Makes a sphere mesh, centered on the origin, its poles on z, three vertices a triangle with no indices, as raylib's (par_shapes').

		@param radius  Its radius.
		@param rings  Rings pole to pole, at least 3.
		@param slices  Slices around, at least 3.
		@return  The mesh; empty for fewer rings or slices. */
	static function GenMeshSphere(radius:Float, rings:Int, slices:Int):Mesh {
		if (rings < 3 || slices < 3) {
			Runtime.log(LOG_WARNING, "MESH: Failed to generate mesh: sphere");
			return new Mesh();
		}
		ParShapes.setEpsilonDegenerateSphere(0.0);
		var sphere = ParShapes.sphere(slices, rings);
		ParShapes.scale(sphere, radius, radius, radius);
		return fromParMesh(sphere);
	}

	/** Makes half a sphere, open at its base, on the side of +y from the origin, three vertices a triangle with no indices.

		@param radius  Its radius; a negative one is 0.
		@param rings  Rings from the pole, at least 3.
		@param slices  Slices around, at least 3.
		@return  The mesh; empty for fewer rings or slices. */
	static function GenMeshHemiSphere(radius:Float, rings:Int, slices:Int):Mesh {
		if (rings < 3 || slices < 3) {
			Runtime.log(LOG_WARNING, "MESH: Failed to generate mesh: hemisphere");
			return new Mesh();
		}
		if (radius < 0)
			radius = 0;
		var sphere = ParShapes.hemisphere(slices, rings);
		ParShapes.scale(sphere, radius, radius, radius);
		return fromParMesh(sphere);
	}

	/** Makes a closed cylinder standing on the XZ plane from the origin, three vertices a triangle with no indices.

		@param radius  Its radius.
		@param height  Its height.
		@param slices  Slices around, at least 3.
		@return  The mesh; empty for fewer slices. */
	static function GenMeshCylinder(radius:Float, height:Float, slices:Int):Mesh {
		if (slices < 3) {
			Runtime.log(LOG_WARNING, "MESH: Failed to generate mesh: cylinder");
			return new Mesh();
		}
		var cylinder = ParShapes.cylinder(slices, 8);
		ParShapes.scale(cylinder, radius, radius, height);
		ParShapes.rotate(cylinder, -PI / 2.0, [1, 0, 0]);
		var capTop = ParShapes.disk(radius, slices, [0, 0, 0], [0, 0, 1]);
		capTop.tcoords = [for (_ in 0...capTop.npoints * 2) 0.];
		ParShapes.rotate(capTop, -PI / 2.0, [1, 0, 0]);
		ParShapes.rotate(capTop, 90 * DEG2RAD, [0, 1, 0]);
		ParShapes.translate(capTop, 0, height, 0);
		var capBottom = ParShapes.disk(radius, slices, [0, 0, 0], [0, 0, -1]);
		capBottom.tcoords = [for (_ in 0...capBottom.npoints * 2) 0.95];
		ParShapes.rotate(capBottom, PI / 2.0, [1, 0, 0]);
		ParShapes.rotate(capBottom, -90 * DEG2RAD, [0, 1, 0]);
		ParShapes.merge(cylinder, capTop);
		ParShapes.merge(cylinder, capBottom);
		return fromParMesh(cylinder);
	}

	/** Makes a closed cone standing on the XZ plane from the origin, three vertices a triangle with no indices.

		@param radius  Its base's radius.
		@param height  Its height.
		@param slices  Slices around, at least 3.
		@return  The mesh; empty for fewer slices. */
	static function GenMeshCone(radius:Float, height:Float, slices:Int):Mesh {
		if (slices < 3) {
			Runtime.log(LOG_WARNING, "MESH: Failed to generate mesh: cone");
			return new Mesh();
		}
		var cone = ParShapes.cone(slices, 8);
		ParShapes.scale(cone, radius, radius, height);
		ParShapes.rotate(cone, -PI / 2.0, [1, 0, 0]);
		ParShapes.rotate(cone, PI / 2.0, [0, 1, 0]);
		var capBottom = ParShapes.disk(radius, slices, [0, 0, 0], [0, 0, -1]);
		capBottom.tcoords = [for (_ in 0...capBottom.npoints * 2) 0.95];
		ParShapes.rotate(capBottom, PI / 2.0, [1, 0, 0]);
		ParShapes.merge(cone, capBottom);
		return fromParMesh(cone);
	}

	/** Makes a torus on the XY plane, centered on the origin, three vertices a triangle with no indices.

		@param radius  The tube's radius against the ring's, 0.1 to 1 (others are clamped to it).
		@param size  The torus's width, out to the ring's middle on each side.
		@param radSeg  Slices around the ring, at least 3.
		@param sides  Slices around the tube, at least 3.
		@return  The mesh; empty for fewer slices. */
	static function GenMeshTorus(radius:Float, size:Float, radSeg:Int, sides:Int):Mesh {
		if (sides < 3 || radSeg < 3) {
			Runtime.log(LOG_WARNING, "MESH: Failed to generate mesh: torus");
			return new Mesh();
		}
		if (radius > 1.0)
			radius = 1.0;
		else if (radius < 0.1)
			radius = 0.1;
		var torus = ParShapes.torus(radSeg, sides, radius);
		ParShapes.scale(torus, size / 2, size / 2, size / 2);
		return fromParMesh(torus);
	}

	/** Makes a trefoil knot, centered on the origin, three vertices a triangle with no indices.

		@param radius  The tube's radius, in tenths, 0.5 to 3 (others are clamped to it).
		@param size  The knot's scale.
		@param radSeg  Slices along the knot, at least 3.
		@param sides  Slices around the tube, at least 3.
		@return  The mesh; empty for fewer slices. */
	static function GenMeshKnot(radius:Float, size:Float, radSeg:Int, sides:Int):Mesh {
		if (sides < 3 || radSeg < 3) {
			Runtime.log(LOG_WARNING, "MESH: Failed to generate mesh: knot");
			return new Mesh();
		}
		if (radius > 3.0)
			radius = 3.0;
		else if (radius < 0.5)
			radius = 0.5;
		var knot = ParShapes.trefoilKnot(radSeg, sides, radius);
		ParShapes.scale(knot, size, size, size);
		return fromParMesh(knot);
	}

	/** Makes terrain from an image: a vertex a pixel, from the origin along +x and +z, each the height of its pixel's gray (red, green and
		blue averaged), two triangles a cell with a flat normal each, three vertices a triangle with no indices.

		@param heightmap  The image.
		@param size  The terrain's size: x and z across the image, y the height of white.
		@return  The mesh. */
	static function GenMeshHeightmap(heightmap:Image, size:Vector3):Mesh {
		var mesh = new Mesh();
		var mapX = heightmap.width, mapZ = heightmap.height;
		var pixels = LoadImageColors(heightmap);
		if (pixels == null || mapX < 2 || mapZ < 2)
			return mesh;
		inline function gray(c:Color):Float
			return (c.r + c.g + c.b) / 3.0;
		mesh.triangleCount = (mapX - 1) * (mapZ - 1) * 2;
		mesh.vertexCount = mesh.triangleCount * 3;
		var vertices = [], texcoords = [], normals = [];
		var sx = size.x / (mapX - 1),
			sy = size.y / 255.0,
			sz = size.z / (mapZ - 1);
		for (z in 0...mapZ - 1)
			for (x in 0...mapX - 1) {
				var a = [x * sx, gray(pixels[x + z * mapX]) * sy, z * sz],
					b = [x * sx, gray(pixels[x + (z + 1) * mapX]) * sy, (z + 1) * sz],
					c = [(x + 1) * sx, gray(pixels[(x + 1) + z * mapX]) * sy, z * sz],
					d = [(x + 1) * sx, gray(pixels[(x + 1) + (z + 1) * mapX]) * sy, (z + 1) * sz];
				for (p in [a, b, c, c, b, d])
					for (v in p)
						vertices.push(v);
				var u0 = x / (mapX - 1),
					u1 = (x + 1) / (mapX - 1),
					v0 = z / (mapZ - 1),
					v1 = (z + 1) / (mapZ - 1);
				for (t in [u0, v0, u0, v1, u1, v0, u1, v0, u0, v1, u1, v1])
					texcoords.push(t);
				for (tri in [[a, b, c], [c, b, d]]) {
					var n = Vector3Normalize(Vector3CrossProduct(new Vector3(tri[1][0] - tri[0][0], tri[1][1] - tri[0][1], tri[1][2] - tri[0][2]),
						new Vector3(tri[2][0] - tri[0][0], tri[2][1] - tri[0][1], tri[2][2] - tri[0][2])));
					for (_ in 0...3) {
						normals.push(n.x);
						normals.push(n.y);
						normals.push(n.z);
					}
				}
			}
		mesh.vertices = vertices;
		mesh.texcoords = texcoords;
		mesh.normals = normals;
		return mesh;
	}

	/** Makes a maze of cubes from an image, a cube a pixel centered on it from the origin: a white pixel a wall, its faces where its
		neighbors are black or the map ends, and its top and bottom; a black pixel a floor and a ceiling, facing in. The texture is split in
		four: walls from its top left (right, front) and top right (left, back), tops from its bottom left and bottoms from its bottom right.
		Three vertices a triangle, with no indices.

		@param cubicmap  The image.
		@param cubeSize  A cube's size: x along the image's width, z along its height, y the walls' height.
		@return  The mesh. */
	static function GenMeshCubicmap(cubicmap:Image, cubeSize:Vector3):Mesh {
		var mesh = new Mesh();
		var pixels = LoadImageColors(cubicmap);
		if (pixels == null)
			return mesh;
		inline function equal(a:Color, b:Color):Bool
			return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
		var width = cubicmap.width, height = cubicmap.height;
		var w = cubeSize.x, h = cubeSize.z, h2 = cubeSize.y;
		var vertices:Array<Float> = [],
			normals:Array<Float> = [],
			texcoords:Array<Float> = [];
		var n1 = [1., 0, 0],
			n2 = [-1., 0, 0],
			n3 = [0., 1, 0],
			n4 = [0., -1, 0],
			n5 = [0., 0, -1],
			n6 = [0., 0, 1];
		// Each part of the texture, x, y, width and height.
		var rightTexUV = [0., 0, 0.5, 0.5],
			leftTexUV = [0.5, 0, 0.5, 0.5],
			frontTexUV = [0., 0, 0.5, 0.5],
			backTexUV = [0.5, 0, 0.5, 0.5],
			topTexUV = [0., 0.5, 0.5, 0.5],
			bottomTexUV = [0.5, 0.5, 0.5, 0.5];
		// Two triangles: their six corners, the normal, and each corner's texture coordinate as a corner of the part (0 or 1 across, then
		// down).
		function quad(corners:Array<Array<Float>>, n:Array<Float>, uv:Array<Float>, at:Array<Int>):Void {
			for (p in corners)
				for (v in p)
					vertices.push(v);
			for (_ in 0...6)
				for (v in n)
					normals.push(v);
			for (i in 0...6) {
				texcoords.push(uv[0] + uv[2] * at[i * 2]);
				texcoords.push(uv[1] + uv[3] * at[i * 2 + 1]);
			}
		}
		for (z in 0...height)
			for (x in 0...width) {
				var v1 = [w * (x - 0.5), h2, h * (z - 0.5)],
					v2 = [w * (x - 0.5), h2, h * (z + 0.5)],
					v3 = [w * (x + 0.5), h2, h * (z + 0.5)],
					v4 = [w * (x + 0.5), h2, h * (z - 0.5)],
					v5 = [w * (x + 0.5), 0, h * (z - 0.5)],
					v6 = [w * (x - 0.5), 0, h * (z - 0.5)],
					v7 = [w * (x - 0.5), 0, h * (z + 0.5)],
					v8 = [w * (x + 0.5), 0, h * (z + 0.5)];
				var pixel = pixels[z * width + x];
				if (equal(pixel, WHITE)) {
					quad([v1, v2, v3, v1, v3, v4], n3, topTexUV, [0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0]);
					quad([v6, v8, v7, v6, v5, v8], n4, bottomTexUV, [1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1]);
					if ((z < height - 1 && equal(pixels[(z + 1) * width + x], BLACK)) || z == height - 1)
						quad([v2, v7, v3, v3, v7, v8], n6, frontTexUV, [0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1]);
					if ((z > 0 && equal(pixels[(z - 1) * width + x], BLACK)) || z == 0)
						quad([v1, v5, v6, v1, v4, v5], n5, backTexUV, [1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1]);
					if ((x < width - 1 && equal(pixels[z * width + (x + 1)], BLACK)) || x == width - 1)
						quad([v3, v8, v4, v4, v8, v5], n1, rightTexUV, [0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1]);
					if ((x > 0 && equal(pixels[z * width + (x - 1)], BLACK)) || x == 0)
						quad([v1, v7, v2, v1, v6, v7], n2, leftTexUV, [0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1]);
				} else if (equal(pixel, BLACK)) {
					quad([v1, v3, v2, v1, v4, v3], n4, topTexUV, [0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1]);
					quad([v6, v7, v8, v6, v8, v5], n3, bottomTexUV, [1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0]);
				}
			}
		mesh.vertexCount = Std.int(vertices.length / 3);
		mesh.triangleCount = Std.int(mesh.vertexCount / 3);
		mesh.vertices = vertices;
		mesh.normals = normals;
		mesh.texcoords = texcoords;
		return mesh;
	}

	/** Computes a mesh's tangents from its positions, texture coordinates and normals: each triangle's direction of u, by its indices
		when it has them, summed at each of its vertices, made square to the vertex's normal and of length 1, w the side the summed
		direction of v is on.

		A vertex whose tangent comes out of length near 0, or along its normal, takes one square to the normal: x when the normal is
		mostly z, else (-y, x, 0) of the normal, w 1.

		@param mesh  The mesh; one without positions, texture coordinates or normals is unchanged. */
	static function GenMeshTangents(mesh:Mesh):Void {
		if (mesh.vertices == null || mesh.texcoords == null || mesh.normals == null) {
			Runtime.log(LOG_WARNING, "MESH: Tangents generation requires vertices, texcoords and normals vertex attribute data");
			return;
		}
		var vs = mesh.vertices,
			uvs = mesh.texcoords,
			ns = mesh.normals,
			n = mesh.vertexCount;
		var tan1 = [for (_ in 0...n) new Vector3()],
			tan2 = [for (_ in 0...n) new Vector3()];
		for (t in 0...mesh.triangleCount) {
			var i0 = t * 3, i1 = t * 3 + 1, i2 = t * 3 + 2;
			if (mesh.indices != null) {
				i0 = mesh.indices[t * 3];
				i1 = mesh.indices[t * 3 + 1];
				i2 = mesh.indices[t * 3 + 2];
			}
			var x1 = vs[i1 * 3] - vs[i0 * 3],
				y1 = vs[i1 * 3 + 1] - vs[i0 * 3 + 1],
				z1 = vs[i1 * 3 + 2] - vs[i0 * 3 + 2];
			var x2 = vs[i2 * 3] - vs[i0 * 3],
				y2 = vs[i2 * 3 + 1] - vs[i0 * 3 + 1],
				z2 = vs[i2 * 3 + 2] - vs[i0 * 3 + 2];
			var s1 = uvs[i1 * 2] - uvs[i0 * 2],
				t1 = uvs[i1 * 2 + 1] - uvs[i0 * 2 + 1];
			var s2 = uvs[i2 * 2] - uvs[i0 * 2],
				t2 = uvs[i2 * 2 + 1] - uvs[i0 * 2 + 1];
			var div = s1 * t2 - s2 * t1;
			var r = Math.abs(div) < 0.0001 ? 0.0 : 1.0 / div;
			var sdir = new Vector3((t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r);
			var tdir = new Vector3((s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r);
			for (k in [i0, i1, i2]) {
				tan1[k] = Vector3Add(tan1[k], sdir);
				tan2[k] = Vector3Add(tan2[k], tdir);
			}
		}
		var tangents = [];
		// A tangent square to a normal, for one that can't be computed.
		function square(normal:Vector3):Vector3
			return Math.abs(normal.z) > 0.707 ? new Vector3(1, 0, 0) : Vector3Normalize(new Vector3(-normal.y, normal.x, 0));
		for (i in 0...n) {
			var normal = new Vector3(ns[i * 3], ns[i * 3 + 1], ns[i * 3 + 2]);
			var tangent = tan1[i];
			if (Vector3Length(tangent) < 0.0001) {
				tangent = square(normal);
				tangents.push(tangent.x);
				tangents.push(tangent.y);
				tangents.push(tangent.z);
				tangents.push(1.0);
				continue;
			}
			// Gram-Schmidt: the tangent less its part along the normal.
			var orthogonalized = Vector3Subtract(tangent, Vector3Scale(normal, Vector3DotProduct(normal, tangent)));
			orthogonalized = Vector3Length(orthogonalized) < 0.0001 ? square(normal) : Vector3Normalize(orthogonalized);
			tangents.push(orthogonalized.x);
			tangents.push(orthogonalized.y);
			tangents.push(orthogonalized.z);
			tangents.push(Vector3DotProduct(Vector3CrossProduct(normal, orthogonalized), tan2[i]) < 0.0 ? -1.0 : 1.0);
		}
		mesh.tangents = tangents;
		// An uploaded mesh's tangents go to the GPU with the next draw that reads them.
		mesh.gpu.contents[4] = null;
		if (mesh.gpu.buffers != null && mesh.gpu.buffers[4] != 0) {
			Runtime.frame.retire(mesh.gpu.buffers[4]);
			mesh.gpu.buffers[4] = 0;
		}
		Runtime.log(LOG_INFO, "MESH: Tangents data computed and uploaded for provided mesh");
	}

	/** raylib's mesh export, done when it returns. A file is kept later, once written, so a call doesn't compile on any target:
		`ExportMeshAsync` writes it and answers.

		@param mesh  The mesh.
		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("ExportMesh: A file is written later, or is refused. See ExportMeshAsync(mesh:Mesh, fileName:String, ?done:Void->Void, ?failed:String->Void) in helix.raylib.extras.Models (import helix.raylib.extras.Models.*;)")
	static function ExportMesh(mesh:Mesh, fileName:String):Bool {
		throw "ExportMesh is unimplemented";
	}

	// ExportMeshAsync's OBJ file, as raylib's writes it.
	static function meshObj(mesh:Mesh):String {
		var text = new StringBuf();
		text.add("# //////////////////////////////////////////////////////////////////////////////////\n");
		text.add("# //                                                                              //\n");
		text.add("# // rMeshOBJ exporter v1.0 - Mesh exported as triangle faces and not optimized   //\n");
		text.add("# //                                                                              //\n");
		text.add("# // more info and bugs-report:  github.com/raysan5/raylib                        //\n");
		text.add("# // feedback and support:       ray[at]raylib.com                                //\n");
		text.add("# //                                                                              //\n");
		text.add("# // Copyright (c) 2018-2026 Ramon Santamaria (@raysan5)                          //\n");
		text.add("# //                                                                              //\n");
		text.add("# //////////////////////////////////////////////////////////////////////////////////\n\n");
		text.add('# Vertex Count:     ${mesh.vertexCount}\n');
		text.add('# Triangle Count:   ${mesh.triangleCount}\n\n');
		text.add("g mesh\n");
		inline function at(a:Null<Array<Float>>, i:Int):Float
			return a != null && i < a.length ? a[i] : 0;
		for (i in 0...mesh.vertexCount)
			text.add(TextFormat("v %.6f %.6f %.6f\n", at(mesh.vertices, i * 3), at(mesh.vertices, i * 3 + 1), at(mesh.vertices, i * 3 + 2)));
		for (i in 0...mesh.vertexCount)
			text.add(TextFormat("vt %.6f %.6f\n", at(mesh.texcoords, i * 2), at(mesh.texcoords, i * 2 + 1)));
		for (i in 0...mesh.vertexCount)
			text.add(TextFormat("vn %.4f %.4f %.4f\n", at(mesh.normals, i * 3), at(mesh.normals, i * 3 + 1), at(mesh.normals, i * 3 + 2)));
		for (i in 0...mesh.triangleCount) {
			var a = mesh.indices != null ? mesh.indices[i * 3] + 1 : i * 3 + 1,
				b = mesh.indices != null ? mesh.indices[i * 3 + 1] + 1 : i * 3 + 2,
				c = mesh.indices != null ? mesh.indices[i * 3 + 2] + 1 : i * 3 + 3;
			text.add('f $a/$a/$a $b/$b/$b $c/$c/$c\n');
		}
		return text.toString();
	}

	/** raylib's export of a mesh as code, done when it returns. A file is kept later, once written, so a call doesn't compile on any target:
		`ExportMeshAsCodeAsync` writes it and answers.

		@param mesh  The mesh.
		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("ExportMeshAsCode: A file is written later, or is refused. See ExportMeshAsCodeAsync(mesh:Mesh, fileName:String, ?done:Void->Void, ?failed:String->Void) in helix.raylib.extras.Models (import helix.raylib.extras.Models.*;)")
	static function ExportMeshAsCode(mesh:Mesh, fileName:String):Bool {
		throw "ExportMeshAsCode is unimplemented";
	}

	// ExportMeshAsCodeAsync's text, as raylib's writes it.
	static function meshAsCode(mesh:Mesh, fileName:String):String {
		var text = new StringBuf();
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n");
		text.add("//                                                                                    //\n");
		text.add("// MeshAsCode exporter v1.0 - Mesh vertex data exported as arrays                     //\n");
		text.add("//                                                                                    //\n");
		text.add("// more info and bugs-report:  github.com/raysan5/raylib                              //\n");
		text.add("// feedback and support:       ray[at]raylib.com                                      //\n");
		text.add("//                                                                                    //\n");
		text.add("// Copyright (c) 2023 Ramon Santamaria (@raysan5)                                     //\n");
		text.add("//                                                                                    //\n");
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n\n");
		var name = new StringBuf(), base = GetFileNameWithoutExt(fileName);
		for (i in 0...base.length) {
			var c = StringTools.fastCodeAt(base, i);
			name.addChar(c >= "a".code && c <= "z".code ? c - 32 : c);
		}
		var varName = name.toString();
		text.add("// Mesh basic information\n");
		text.add('#define ${varName}_VERTEX_COUNT    ${mesh.vertexCount}\n');
		text.add('#define ${varName}_TRIANGLE_COUNT   ${mesh.triangleCount}\n\n');
		function array(type:String, label:String, values:Null<Array<Float>>, count:Int, format:Float->String, last:String):Void {
			if (values == null)
				return;
			inline function at(i:Int):Float
				return i >= 0 && i < values.length ? values[i] : 0;
			text.add('static $type ${varName}_${label}[$count] = { ');
			for (i in 0...count - 1)
				text.add(format(at(i)) + (i % 20 == 0 ? ",\n" : ", "));
			text.add(format(at(count - 1)) + last);
		}
		var float = (v:Float) -> TextFormat("%.3ff", v);
		array("float", "VERTEX_DATA", mesh.vertices, mesh.vertexCount * 3, float, " };\n\n");
		array("float", "TEXCOORD_DATA", mesh.texcoords, mesh.vertexCount * 2, float, " };\n\n");
		array("float", "TEXCOORD2_DATA", mesh.texcoords2, mesh.vertexCount * 2, float, " };\n\n");
		array("float", "NORMAL_DATA", mesh.normals, mesh.vertexCount * 3, float, " };\n\n");
		array("float", "TANGENT_DATA", mesh.tangents, mesh.vertexCount * 4, float, " };\n\n");
		array("unsigned char", "COLOR_DATA", mesh.colors == null ? null : [for (c in mesh.colors) (c : Float)], mesh.vertexCount * 4,
			v -> "0x" + StringTools.hex(Std.int(v)).toLowerCase(), " };\n\n");
		array("unsigned short", "INDEX_DATA", mesh.indices == null ? null : [for (i in mesh.indices) (i : Float)], mesh.triangleCount * 3,
			v -> Std.string(Std.int(v)), " };\n");
		return text.toString();
	}

	// ---- Model animations ----
	// As raylib 6.2 has them (raylib.h's 5.5 names and signatures, its frame a float as 6.2's): its glTF animations read, its frames mixed,
	// its CPU skinning; the bone matrices in each mesh's boneMatrices, raylib 5.5's place, so a skinning shader is given them as it draws.

	/** raylib's animation load, which waits for the file. A page can't wait, so a call doesn't compile on any target:
		`LoadModelAnimationsAsync` loads them.

		@param fileName  The file.
		@param animCount  Would be set to how many.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadModelAnimations: Synchronous loading is not supported. See LoadModelAnimationsAsync(fileName:String, loaded:Array<ModelAnimation>->Void, ?failed:String->Void) in helix.raylib.extras.Models (import helix.raylib.extras.Models.*;)")
	static function LoadModelAnimations(fileName:String, animCount:Array<Int>):Array<ModelAnimation> {
		throw "LoadModelAnimations is unimplemented";
	}

	/** Poses a model's bones by a frame of an animation, as raylib 6.2's: the frame's whole part and the next mixed by its fraction (a
		5.5 program's whole frames work as they did), each wrapped to the animation's frames; each bone's matrix then its bind pose's
		inverse and the pose, in each mesh's `boneMatrices`. Its vertices don't move: a skinning shader moves them as they are drawn, or
		`UpdateModelAnimation` on the CPU. Nothing for a model without bones or an animation without frames.

		@param model  The model.
		@param anim  The animation, of the model's skeleton (`IsModelAnimationValid`).
		@param frame  The frame, from 0. */
	static function UpdateModelAnimationBones(model:Model, anim:ModelAnimation, frame:Float):Void {
		Animations.updateBones(model, anim, frame);
	}

	/** Poses a model by a frame of an animation, as raylib 6.2's: its bones as `UpdateModelAnimationBones` poses them, and each skinned
		mesh drawn in that pose until the next call. Draws asked for before keep the pose they were asked with, so one model can be posed
		and drawn many times in a frame.

		How a mesh is moved depends on its material's shader. Under raylib's default shader it is moved on the GPU, by a skinned version
		of that shader. Under a shader of the program's own that declares the bone inputs, as raylib's `skinning.vs` does
		(`vertexBoneIds`, `vertexBoneWeights` and `uniform mat4 boneMatrices[N]`), or that includes `<helix/raylib/shaders/skinning.glsl>`,
		it is moved on the GPU by that shader. Under a shader of the program's own without them it is moved on the CPU, every vertex each
		call, which is slow for many vertices or many models: an animated model under a lighting shader of the program's own draws fastest
		when that shader declares `skinning.vs`'s inputs or includes `skinning.glsl`.

		`animVertices` and `animNormals` hold the moved positions and normals (each normal by its bones' matrices inverted and transposed,
		not normalized), worked out on the CPU when first read; a mesh whose shader moves it itself is left as raylib leaves it.

		@param model  The model.
		@param anim  The animation, of the model's skeleton.
		@param frame  The frame, from 0, fractional. */
	static function UpdateModelAnimation(model:Model, anim:ModelAnimation, frame:Float):Void {
		if (anim.frameCount > 0 && model.bones != null && anim.framePoses != null && model.boneMatrices != null) {
			Animations.updateBones(model, anim, frame);
			helix.raylib.internal.Skinning.pose(model);
		}
	}

	/** Poses a model by two animations mixed, raylib 6.2's own: each at its frame as `UpdateModelAnimation` takes one, then the two mixed
		by the blend, the bones and the vertices as it moves them, on the GPU or the CPU as `UpdateModelAnimation` says. Note that, as raylib's, a frame is wrapped to its animation's frames
		before its fraction is taken, so past the last frame it holds the frame it wrapped to. Nothing for a blend outside 0 to 1.

		@param model  The model.
		@param animA  The first animation.
		@param frameA  Its frame, fractional.
		@param animB  The second animation.
		@param frameB  Its frame, fractional.
		@param blend  How much of the second: 0 the first alone, 1 the second alone. */
	static function UpdateModelAnimationEx(model:Model, animA:ModelAnimation, frameA:Float, animB:ModelAnimation, frameB:Float, blend:Float):Void {
		if (model.boneMatrices == null)
			return;
		if (animA.frameCount > 0 && animA.framePoses != null && animB.frameCount > 0 && animB.framePoses != null && blend >= 0 && blend <= 1) {
			Animations.updateBonesEx(model, animA, frameA, animB, frameB, blend);
			helix.raylib.internal.Skinning.pose(model);
		}
	}

	/** Frees an animation's frames: its poses and bones are let go, its counts 0.

		@param anim  The animation. */
	static function UnloadModelAnimation(anim:ModelAnimation):Void {
		anim.framePoses = null;
		anim.bones = null;
		anim.frameCount = 0;
		anim.boneCount = 0;
	}

	/** Frees animations' frames, each as `UnloadModelAnimation` frees one.

		@param animations  The animations.
		@param animCount  How many of them. */
	static function UnloadModelAnimations(animations:Array<ModelAnimation>, animCount:Int):Void {
		if (animations == null)
			return;
		for (i in 0...animCount)
			if (i < animations.length)
				UnloadModelAnimation(animations[i]);
	}

	/** Returns whether an animation moves a model's skeleton, as raylib 6.2 checks it: whether they have as many bones.

		@param model  The model.
		@param anim  The animation.
		@return  True when their bone counts match. */
	static function IsModelAnimationValid(model:Model, anim:ModelAnimation):Bool {
		return model.boneCount == anim.boneCount;
	}

	/** Returns raylib's default material: the default shader, the diffuse map raylib's default texture (a 1x1 white pixel), the diffuse
		and specular colors white, and the other maps empty. The program holds it until `UnloadMaterial`; a model it is put in holds it too.

		@return  The material. */
	static function LoadMaterialDefault():Material {
		return Models.defaultMaterial(defaultShader());
	}

	/** Returns whether a material can draw: whether it has maps and a shader.

		@param material  The material.
		@return  True when its maps aren't null and its shader's id is above 0. */
	static function IsMaterialValid(material:Material):Bool {
		return material.maps != null && material.shader != null && material.shader.id > 0;
	}

	/** Lets go of a material (docs/DECISIONS.md 25): the program's hold from `LoadMaterialDefault`, or, for a model's material, the
		model's. When no one else holds it, its shader is unloaded unless it is the default one, and its maps let go of their textures:
		each texture is freed when nothing else holds it (a texture the program still holds, or another load of a file shares, stays).
		Releasing it again does nothing.

		@param material  The material. */
	static function UnloadMaterial(material:Material):Void {
		Models.releaseMaterial(material);
	}

	/** Sets a texture on a material's map, which holds it from then on (`MaterialMap.texture`).

		@param material  The material.
		@param mapType  The map (`MATERIAL_MAP_*`).
		@param texture  The texture. */
	static function SetMaterialTexture(material:Material, mapType:Int, texture:Texture2D):Void {
		material.maps[mapType].texture = texture;
	}

	/** Sets the material a model's mesh draws with.

		@param model  The model.
		@param meshId  The mesh.
		@param materialId  The material. */
	static function SetModelMeshMaterial(model:Model, meshId:Int, materialId:Int):Void {
		model.meshMaterial[meshId] = materialId;
	}

	/** Returns a mesh's bounds: the least and the most of its positions; 0 for a mesh without them.

		@param mesh  The mesh.
		@return  The box. */
	static function GetMeshBoundingBox(mesh:Mesh):BoundingBox {
		var v = mesh.vertices;
		if (v == null)
			return new BoundingBox(new Vector3(), new Vector3());
		var minVertex = new Vector3(v[0], v[1], v[2]),
			maxVertex = new Vector3(v[0], v[1], v[2]);
		for (i in 1...mesh.vertexCount) {
			var p = new Vector3(v[i * 3], v[i * 3 + 1], v[i * 3 + 2]);
			minVertex = Vector3Min(minVertex, p);
			maxVertex = Vector3Max(maxVertex, p);
		}
		return new BoundingBox(minVertex, maxVertex);
	}

	/** Returns a model's bounds: its meshes' together, its least and most corners then moved by its transform, as raylib's (a turned
		model's box is not its bounds; transform its eight corners for those).

		@param model  The model.
		@return  The box. */
	static function GetModelBoundingBox(model:Model):BoundingBox {
		var bounds = new BoundingBox(new Vector3(), new Vector3());
		if (model.meshCount > 0) {
			bounds = GetMeshBoundingBox(model.meshes[0]);
			for (i in 1...model.meshCount) {
				var other = GetMeshBoundingBox(model.meshes[i]);
				bounds.min = new Vector3(bounds.min.x < other.min.x ? bounds.min.x : other.min.x, bounds.min.y < other.min.y ? bounds.min.y : other.min.y,
					bounds.min.z < other.min.z ? bounds.min.z : other.min.z);
				bounds.max = new Vector3(bounds.max.x > other.max.x ? bounds.max.x : other.max.x, bounds.max.y > other.max.y ? bounds.max.y : other.max.y,
					bounds.max.z > other.max.z ? bounds.max.z : other.max.z);
			}
		}
		bounds.min = Vector3Transform(bounds.min, model.transform);
		bounds.max = Vector3Transform(bounds.max, model.transform);
		return bounds;
	}

	// A par_shapes mesh as raylib takes it: three vertices a triangle, each with its point's position, normal and texture coordinates.
	static function fromParMesh(m:ParMesh):Mesh {
		var mesh = new Mesh();
		mesh.vertexCount = m.ntriangles * 3;
		mesh.triangleCount = m.ntriangles;
		var vertices = [], normals = [], texcoords = [];
		for (t in m.triangles) {
			for (c in 0...3) {
				vertices.push(m.points[t * 3 + c]);
				normals.push(m.normals[t * 3 + c]);
			}
			texcoords.push(m.tcoords[t * 2]);
			texcoords.push(m.tcoords[t * 2 + 1]);
		}
		mesh.vertices = vertices;
		mesh.normals = normals;
		mesh.texcoords = texcoords;
		return mesh;
	}

	// ---- Collisions in 3D ----

	/** Returns whether two boxes overlap, touching included.

		@param box1  One.
		@param box2  The other.
		@return  True when they overlap. */
	static function CheckCollisionBoxes(box1:BoundingBox, box2:BoundingBox):Bool {
		var collision = true;
		if (box1.max.x >= box2.min.x && box1.min.x <= box2.max.x) {
			if (box1.max.y < box2.min.y || box1.min.y > box2.max.y)
				collision = false;
			if (box1.max.z < box2.min.z || box1.min.z > box2.max.z)
				collision = false;
		} else
			collision = false;
		return collision;
	}

	/** Returns whether two spheres overlap, touching included.

		@param center1  One's center.
		@param radius1  Its radius.
		@param center2  The other's center.
		@param radius2  Its radius.
		@return  True when they overlap. */
	static function CheckCollisionSpheres(center1:Vector3, radius1:Float, center2:Vector3, radius2:Float):Bool {
		var d = Vector3Subtract(center2, center1);
		return Vector3DotProduct(d, d) <= (radius1 + radius2) * (radius1 + radius2);
	}

	/** Returns whether a box and a sphere overlap, touching included.

		@param box  The box.
		@param center  The sphere's center.
		@param radius  Its radius.
		@return  True when they overlap. */
	static function CheckCollisionBoxSphere(box:BoundingBox, center:Vector3, radius:Float):Bool {
		var dmin = 0.;
		for (axis in [
			[center.x, box.min.x, box.max.x],
			[center.y, box.min.y, box.max.y],
			[center.z, box.min.z, box.max.z]
		]) {
			if (axis[0] < axis[1])
				dmin += Math.pow(axis[0] - axis[1], 2);
			else if (axis[0] > axis[2])
				dmin += Math.pow(axis[0] - axis[2], 2);
		}
		return dmin <= radius * radius;
	}

	/** Returns where a ray meets a sphere: the near side from outside, the far side from inside (its normal then pointing in).

		A sphere wholly behind the ray is missed. On a miss the point, normal and distance are 0. The ray's direction should be of
		length 1.

		@param ray  The ray.
		@param center  The sphere's center.
		@param radius  Its radius.
		@return  The hit. */
	static function GetRayCollisionSphere(ray:Ray, center:Vector3, radius:Float):RayCollision {
		var collision = new RayCollision(false, 0, new Vector3(), new Vector3());
		var raySpherePos = Vector3Subtract(center, ray.position);
		var vector = Vector3DotProduct(raySpherePos, ray.direction);
		var distanceToCenter = Vector3Length(raySpherePos);
		var d = radius * radius - (distanceToCenter * distanceToCenter - vector * vector);
		// The ray's line meets the sphere; from inside, the hit is on the far side.
		if (d >= 0.0) {
			var hitDistance, point, normal;
			if (distanceToCenter < radius) {
				hitDistance = vector + Math.sqrt(d);
				point = Vector3Add(ray.position, Vector3Scale(ray.direction, hitDistance));
				normal = Vector3Negate(Vector3Normalize(Vector3Subtract(point, center)));
			} else {
				hitDistance = vector - Math.sqrt(d);
				point = Vector3Add(ray.position, Vector3Scale(ray.direction, hitDistance));
				normal = Vector3Normalize(Vector3Subtract(point, center));
			}
			if (hitDistance >= 0.0) {
				collision.hit = true;
				collision.point = point;
				collision.normal = normal;
				collision.distance = hitDistance;
			}
		}
		return collision;
	}

	/** Returns where a ray meets a box, as raylib's: from inside, the way out, its distance negative and its normal pointing in; its point,
		distance and normal are set even when it misses.

		@param ray  The ray.
		@param box  The box.
		@return  The hit. */
	static function GetRayCollisionBox(ray:Ray, box:BoundingBox):RayCollision {
		var collision = new RayCollision(false, 0, new Vector3(), new Vector3());
		var position = ray.position, direction = ray.direction;
		// From inside, the distance is negative, as if the ray were turned round, so it is turned round.
		var insideBox = position.x > box.min.x && position.x < box.max.x && position.y > box.min.y && position.y < box.max.y && position.z > box.min.z
			&& position.z < box.max.z;
		if (insideBox)
			direction = Vector3Negate(direction);
		var t = [for (_ in 0...11) 0.];
		t[8] = 1.0 / direction.x;
		t[9] = 1.0 / direction.y;
		t[10] = 1.0 / direction.z;
		t[0] = (box.min.x - position.x) * t[8];
		t[1] = (box.max.x - position.x) * t[8];
		t[2] = (box.min.y - position.y) * t[9];
		t[3] = (box.max.y - position.y) * t[9];
		t[4] = (box.min.z - position.z) * t[10];
		t[5] = (box.max.z - position.z) * t[10];
		t[6] = fmaxf(fmaxf(fminf(t[0], t[1]), fminf(t[2], t[3])), fminf(t[4], t[5]));
		t[7] = fminf(fminf(fmaxf(t[0], t[1]), fmaxf(t[2], t[3])), fmaxf(t[4], t[5]));
		collision.hit = !(t[7] < 0 || t[6] > t[7]);
		collision.distance = t[6];
		collision.point = Vector3Add(position, Vector3Scale(direction, collision.distance));
		// The normal: from the box's center to the point, scaled to a cube a little over 2 across, each part cut to an integer.
		var normal = Vector3Subtract(collision.point, Vector3Lerp(box.min, box.max, 0.5));
		normal = Vector3Divide(Vector3Scale(normal, 2.01), Vector3Subtract(box.max, box.min));
		normal = new Vector3(truncate(normal.x), truncate(normal.y), truncate(normal.z));
		collision.normal = Vector3Normalize(normal);
		if (insideBox) {
			collision.distance *= -1.0;
			collision.normal = Vector3Negate(collision.normal);
		}
		return collision;
	}

	/** Returns where a ray first meets a mesh moved by a transform: the nearest of its triangles it meets.

		@param ray  The ray.
		@param mesh  The mesh, with its positions.
		@param transform  The transform.
		@return  The hit. */
	static function GetRayCollisionMesh(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision {
		var collision = new RayCollision(false, 0, new Vector3(), new Vector3());
		var v = mesh.vertices;
		if (v == null)
			return collision;
		var t = toMatrix3D(transform);
		function corner(i:Int):Vector3 {
			var p = t.transformPoint(v[i * 3], v[i * 3 + 1], v[i * 3 + 2]);
			return new Vector3(p.x, p.y, p.z);
		}
		for (k in 0...mesh.triangleCount) {
			var a = mesh.indices == null ? k * 3 : mesh.indices[k * 3],
				b = mesh.indices == null ? k * 3 + 1 : mesh.indices[k * 3 + 1],
				c = mesh.indices == null ? k * 3 + 2 : mesh.indices[k * 3 + 2];
			var hit = GetRayCollisionTriangle(ray, corner(a), corner(b), corner(c));
			if (hit.hit && (!collision.hit || collision.distance > hit.distance))
				collision = hit;
		}
		return collision;
	}

	/** Returns where a ray meets a triangle from either side (Möller and Trumbore's test, as raylib's), its normal that of the corners
		taken counterclockwise.

		@param ray  The ray.
		@param p1  A corner.
		@param p2  The next.
		@param p3  The last.
		@return  The hit. */
	static function GetRayCollisionTriangle(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3):RayCollision {
		var EPSILON = 0.000001;
		var collision = new RayCollision(false, 0, new Vector3(), new Vector3());
		var edge1 = Vector3Subtract(p2, p1), edge2 = Vector3Subtract(p3, p1);
		var p = Vector3CrossProduct(ray.direction, edge2);
		var det = Vector3DotProduct(edge1, p);
		// Parallel to it, or in its plane.
		if (det > -EPSILON && det < EPSILON)
			return collision;
		var invDet = 1.0 / det;
		var tv = Vector3Subtract(ray.position, p1);
		var u = Vector3DotProduct(tv, p) * invDet;
		if (u < 0.0 || u > 1.0)
			return collision;
		var q = Vector3CrossProduct(tv, edge1);
		var v = Vector3DotProduct(ray.direction, q) * invDet;
		if (v < 0.0 || (u + v) > 1.0)
			return collision;
		var t = Vector3DotProduct(edge2, q) * invDet;
		if (t > EPSILON) {
			collision.hit = true;
			collision.distance = t;
			collision.normal = Vector3Normalize(Vector3CrossProduct(edge1, edge2));
			collision.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
		}
		return collision;
	}

	/** Returns where a ray meets a quad, as two triangles: p1, p2 and p4, then p2, p3 and p4.

		@param ray  The ray.
		@param p1  A corner.
		@param p2  The next, counterclockwise.
		@param p3  The next.
		@param p4  The last.
		@return  The hit. */
	static function GetRayCollisionQuad(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3, p4:Vector3):RayCollision {
		var collision = GetRayCollisionTriangle(ray, p1, p2, p4);
		if (!collision.hit)
			collision = GetRayCollisionTriangle(ray, p2, p3, p4);
		return collision;
	}

	// C's cast of a float to int, toward 0, kept a float.
	static function truncate(x:Float):Float
		return x < 0 ? Math.ceil(x) : Math.floor(x);

	// ---- What the 3D functions share ----
	static var shaderDefault:Null<Shader> = null;
	static final sounds = new Map<String, {
		loaded:Null<helix.services.audio.Sound>,
		refs:Int,
		waiting:Array<Sound>,
		cancel:Null<Void->Void>,
		answers:Array<Null<String>->Void>
	}>();
	static var deltaFrame = -1;
	static var seenX = 0.;
	static var seenY = 0.;
	static var previousX = 0.;
	static var previousY = 0.;

	static function defaultShader():Shader {
		if (shaderDefault == null) {
			var p = Runtime.frame.defaultProgram;
			shaderDefault = new Shader(p.handle, locations(p), p);
		}
		return shaderDefault;
	}

	/** Makes a shader from a program compiled as the program built (`LoadShader`).

		@param source  The compiled shader.
		@return  The shader. */
	@:noCompletion
	static function makeShader(source:helix.services.shaders.Shader):Shader {
		var p = new helix.raylib.internal.Program(Runtime.graphics, source);
		return new Shader(p.handle, locations(p), p);
	}

	// raylib's SHADER_LOC_* locations of a program.

	static function locations(p:helix.raylib.internal.Program):Array<Int> {
		var locs = [for (_ in 0...32) -1];
		locs[SHADER_LOC_VERTEX_POSITION] = p.attributes.indexOf("vertexPosition");
		locs[SHADER_LOC_VERTEX_TEXCOORD01] = p.attributes.indexOf("vertexTexCoord");
		locs[SHADER_LOC_VERTEX_NORMAL] = p.attributes.indexOf("vertexNormal");
		locs[SHADER_LOC_VERTEX_COLOR] = p.attributes.indexOf("vertexColor");
		locs[SHADER_LOC_VERTEX_TANGENT] = p.attributes.indexOf("vertexTangent");
		locs[SHADER_LOC_VERTEX_TEXCOORD02] = p.attributes.indexOf("vertexTexCoord2");
		locs[SHADER_LOC_VERTEX_BONEIDS] = p.attributes.indexOf("vertexBoneIds") >= 0 ? p.attributes.indexOf("vertexBoneIds") : p.attributes.indexOf("vertexBoneIndices");
		locs[SHADER_LOC_VERTEX_BONEWEIGHTS] = p.attributes.indexOf("vertexBoneWeights");
		locs[SHADER_LOC_BONE_MATRICES] = p.locate("boneMatrices");
		locs[SHADER_LOC_MATRIX_MVP] = p.locate("mvp");
		locs[SHADER_LOC_MATRIX_VIEW] = p.locate("matView");
		locs[SHADER_LOC_MATRIX_PROJECTION] = p.locate("matProjection");
		locs[SHADER_LOC_MATRIX_MODEL] = p.locate("matModel");
		locs[SHADER_LOC_MATRIX_NORMAL] = p.locate("matNormal");
		locs[SHADER_LOC_VECTOR_VIEW] = p.locate("viewPos");
		locs[SHADER_LOC_COLOR_DIFFUSE] = p.locate("colDiffuse");
		locs[SHADER_LOC_MAP_ALBEDO] = p.locate("texture0");
		locs[SHADER_LOC_MAP_METALNESS] = p.locate("texture1");
		locs[SHADER_LOC_MAP_NORMAL] = p.locate("texture2");
		return locs;
	}

	// The numbers of a shader value as a program writes them.

	static function numbers(value:Dynamic):Array<Float> {
		if (Std.isOfType(value, Array))
			return [for (x in (value : Array<Dynamic>)) (x : Float)];
		if (Std.isOfType(value, Vector2))
			return [value.x, value.y];
		if (Std.isOfType(value, Vector3))
			return [value.x, value.y, value.z];
		if (Std.isOfType(value, Vector4))
			return [value.x, value.y, value.z, value.w];
		if (Std.isOfType(value, Color))
			return [value.r / 255, value.g / 255, value.b / 255, value.a / 255];
		if (Std.isOfType(value, Matrix))
			return toMatrix3D(value).values;
		return [(value : Float)];
	}

	// raylib's Matrix, named by rows, and helix-math's, stored by columns: m0 to m3 the first column in both.

	static function toMatrix3D(m:Matrix):Matrix3D {
		var out = new Matrix3D(), v = out.values;
		var all = [
			m.m0, m.m1, m.m2, m.m3, m.m4, m.m5, m.m6, m.m7, m.m8, m.m9, m.m10, m.m11, m.m12, m.m13, m.m14, m.m15
		];
		for (i in 0...16)
			v[i] = all[i];
		return out;
	}

	static function toMatrix(m:Matrix3D):Matrix {
		var a = m.values;
		return new Matrix(a[0], a[4], a[8], a[12], a[1], a[5], a[9], a[13], a[2], a[6], a[10], a[14], a[3], a[7], a[11], a[15]);
	}

	// The texture DrawMesh binds at each of the program's slots, -1 for the program's own (SetShaderValueTexture's). raylib binds each map
	// with a texture at the texture unit of its index, the cubemap, irradiance and prefilter maps as cubemaps and the rest as 2D textures,
	// and sets the sampler at shader.locs[SHADER_LOC_MAP_DIFFUSE + index] to it; a sampler set to a unit (SetShaderValue) reads what is
	// bound there. texture0 to texture2 read the first three maps, white for none.
	static function mapTextures(shader:Shader, material:Material):Array<Int>
		return mapProgramTextures(shader.program, shader.locs, material);

	// As mapTextures, for a program and the locations it is drawn by (a skinned twin's own, the default shader's).
	static function mapProgramTextures(p:helix.raylib.internal.Program, locs:Array<Int>, material:Material):Array<Int> {
		var textures = textureScratch;
		textures.resize(p.textures.length);
		for (i in 0...textures.length)
			textures[i] = -1;
		if (p.texture0 >= 0)
			textures[p.texture0] = Textures.handle(material.maps[0].texture.id);
		if (p.texture1 >= 0)
			textures[p.texture1] = Textures.handle(material.maps[1].texture.id);
		if (p.texture2 >= 0)
			textures[p.texture2] = Textures.handle(material.maps[2].texture.id);
		for (slot in 0...textures.length) {
			if (slot == p.texture0 || slot == p.texture1 || slot == p.texture2)
				continue;
			var unit = p.units[slot];
			for (i in 0...MATERIAL_MAP_BRDF + 1) {
				var location = locs[SHADER_LOC_MAP_DIFFUSE + i];
				if (location >= 0 && material.maps[i].texture.id > 0 && p.textureSlot(location) == slot)
					unit = i;
			}
			if (unit < 0 || unit >= MAX_MATERIAL_MAPS || material.maps[unit].texture.id <= 0)
				continue;
			var id = material.maps[unit].texture.id;
			var cube = unit == MATERIAL_MAP_CUBEMAP || unit == MATERIAL_MAP_IRRADIANCE || unit == MATERIAL_MAP_PREFILTER;
			// A texture bound as the other kind binds nothing, as GL refuses it.
			textures[slot] = cube == Textures.isCube(id) ? Textures.handle(id) : 0;
		}
		return textures;
	}

	// What drawMesh writes each draw's diffuse color, textures and bones into, read as the draw is recorded.
	static final diffuseScratch:Array<Float> = [0, 0, 0, 0];
	static final textureScratch:Array<Int> = [];

	// Writes a mesh's bones' matrices into a skinning shader's boneMatrices (Models.writeBones), set once a model with bones is made, so
	// a program without one links none of it.
	static var boneWriter:Null<(mesh:Mesh, shader:Shader) -> Void>;

	static function drawMesh(mesh:Mesh, material:Material, transform:Matrix3D, tint:Color, instances:Int = 0, instanceCount:Int = 1):Void {
		if (mesh.gpu.buffers == null)
			Models.upload(mesh);
		if (mesh.gpu.buffers == null)
			return;
		var shader = material.shader == null || material.shader.program == null ? defaultShader() : material.shader;
		var c = material.maps[MATERIAL_MAP_DIFFUSE].color;
		// Read as the draw is recorded, so one array serves every draw.
		var diffuse = diffuseScratch;
		diffuse[0] = c.r / 255 * tint.r / 255;
		diffuse[1] = c.g / 255 * tint.g / 255;
		diffuse[2] = c.b / 255 * tint.b / 255;
		diffuse[3] = c.a / 255 * tint.a / 255;
		// A mesh UpdateModelAnimation posed, skinned (Skinning), unless its shader moves it itself.
		var skinned = Runtime.frame.skinned;
		if (mesh.pose != null && skinned != null && skinned(mesh, shader, material, transform, diffuse, instances, instanceCount))
			return;
		// The bones' matrices, for a skinning shader, as raylib 5.5's DrawMesh uploads them: set once a model with bones is made.
		if (mesh.boneMatrices != null && boneWriter != null)
			boneWriter(mesh, shader);
		Runtime.frame.mesh(mesh, shader.program, transform, diffuse, mapTextures(shader, material), instances, instanceCount);
	}
	#end
}
