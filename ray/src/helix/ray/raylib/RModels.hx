package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.RAsync.*;
#end

/** Holds raylib's rmodels (3D shapes, models, meshes, materials and rays), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RModels {
	#if !macro
	// ---- 3D shapes ----

	/** Draws a line in 3D.

		@param startPos  The start.
		@param endPos  The end.
		@param color  The color. */
	static function DrawLine3D(startPos:Vector3, endPos:Vector3, color:Color):Void {
		var t = Runtime.frame.white;
		Runtime.frame.vertex(t, true, startPos.x, startPos.y, startPos.z, 0, 0, color);
		Runtime.frame.vertex(t, true, endPos.x, endPos.y, endPos.z, 0, 0, color);
	}

	/** Draws a filled box.

		@param position  Its center.
		@param width  Its size along x.
		@param height  Along y.
		@param length  Along z.
		@param color  The color. */
	static function DrawCube(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void {
		var x = position.x, y = position.y, z = position.z, w = width / 2, h = height / 2, l = length / 2;
		var f = Runtime.frame, t = f.white;
		function face(nx:Float, ny:Float, nz:Float, corners:Array<Float>):Void {
			f.nx = nx;
			f.ny = ny;
			f.nz = nz;
			for (i in [0, 1, 2, 0, 2, 3])
				f.vertex(t, false, x + corners[i * 3], y + corners[i * 3 + 1], z + corners[i * 3 + 2], 0, 0, color);
		}
		face(0, 0, 1, [-w, -h, l, w, -h, l, w, h, l, -w, h, l]);
		face(0, 0, -1, [-w, -h, -l, -w, h, -l, w, h, -l, w, -h, -l]);
		face(0, 1, 0, [-w, h, -l, -w, h, l, w, h, l, w, h, -l]);
		face(0, -1, 0, [-w, -h, -l, w, -h, -l, w, -h, l, -w, -h, l]);
		face(1, 0, 0, [w, -h, -l, w, h, -l, w, h, l, w, -h, l]);
		face(-1, 0, 0, [-w, -h, -l, -w, -h, l, -w, h, l, -w, h, -l]);
		f.nx = 0;
		f.ny = 0;
		f.nz = 1;
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
		var min = new Vector3(position.x - w, position.y - h, position.z - l),
			max = new Vector3(position.x + w, position.y + h, position.z + l);
		DrawBoundingBox(new BoundingBox(min, max), color);
	}

	/** Draws a box's edges.

		@param position  Its center.
		@param size  Its size.
		@param color  The color. */
	static function DrawCubeWiresV(position:Vector3, size:Vector3, color:Color):Void {
		DrawCubeWires(position, size.x, size.y, size.z, color);
	}

	/** Draws a bounding box's edges.

		@param box  The box.
		@param color  The color. */
	static function DrawBoundingBox(box:BoundingBox, color:Color):Void {
		var a = box.min, b = box.max;
		var c = [
			[a.x, a.y, a.z], [b.x, a.y, a.z], [b.x, b.y, a.z], [a.x, b.y, a.z],
			[a.x, a.y, b.z], [b.x, a.y, b.z], [b.x, b.y, b.z], [a.x, b.y, b.z]
		];
		for (e in [
			[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]])
			DrawLine3D(new Vector3(c[e[0]][0], c[e[0]][1], c[e[0]][2]), new Vector3(c[e[1]][0], c[e[1]][1], c[e[1]][2]), color);
	}

	/** Draws a filled sphere, 16 rings and 16 slices.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param color  The color. */
	static function DrawSphere(centerPos:Vector3, radius:Float, color:Color):Void {
		DrawSphereEx(centerPos, radius, 16, 16, color);
	}

	/** Draws a filled sphere.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param rings  Rings top to bottom.
		@param slices  Slices around.
		@param color  The color. */
	static function DrawSphereEx(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void {
		var f = Runtime.frame, t = f.white;
		function at(r:Int, s:Int):Array<Float> {
			var phi = Math.PI * r / rings, theta = Math.PI * 2 * s / slices;
			return [Math.sin(phi) * Math.cos(theta), Math.cos(phi), Math.sin(phi) * Math.sin(theta)];
		}
		function put(p:Array<Float>):Void {
			f.nx = p[0];
			f.ny = p[1];
			f.nz = p[2];
			f.vertex(t, false, centerPos.x + p[0] * radius, centerPos.y + p[1] * radius, centerPos.z + p[2] * radius, 0, 0, color);
		}
		for (r in 0...rings)
			for (s in 0...slices) {
				var a = at(r, s), b = at(r, s + 1), c = at(r + 1, s), d = at(r + 1, s + 1);
				for (p in [a, b, c, c, b, d])
					put(p);
			}
		f.nx = 0;
		f.ny = 0;
		f.nz = 1;
	}

	/** Draws a sphere's wires.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param rings  Rings top to bottom.
		@param slices  Slices around.
		@param color  The color. */
	static function DrawSphereWires(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void {
		function at(r:Int, s:Int):Vector3 {
			var phi = Math.PI * r / rings, theta = Math.PI * 2 * s / slices;
			return new Vector3(centerPos.x
				+ Math.sin(phi) * Math.cos(theta) * radius, centerPos.y
				+ Math.cos(phi) * radius,
				centerPos.z
				+ Math.sin(phi) * Math.sin(theta) * radius);
		}
		for (r in 0...rings)
			for (s in 0...slices) {
				DrawLine3D(at(r, s), at(r + 1, s), color);
				DrawLine3D(at(r, s), at(r, s + 1), color);
			}
	}

	/** Draws a flat rectangle on the XZ plane, facing up.

		@param centerPos  Its center.
		@param size  Its size along x and z.
		@param color  The color. */
	static function DrawPlane(centerPos:Vector3, size:Vector2, color:Color):Void {
		var f = Runtime.frame, t = f.white, x = size.x / 2, z = size.y / 2;
		f.nx = 0;
		f.ny = 1;
		f.nz = 0;
		var c = [[-x, z], [x, z], [x, -z], [-x, z], [x, -z], [-x, -z]];
		for (p in c)
			f.vertex(t, false, centerPos.x + p[0], centerPos.y, centerPos.z + p[1], 0, 0, color);
		f.nz = 1;
		f.ny = 0;
	}

	/** Draws a grid on the XZ plane, centered on the origin: its center lines darker, as raylib's.

		@param slices  The lines each way.
		@param spacing  The space between them. */
	static function DrawGrid(slices:Int, spacing:Float):Void {
		var half = slices / 2;
		for (i in 0...slices + 1) {
			var p = (i - half) * spacing, e = half * spacing;
			var color = i == Std.int(half) ? new Color(128, 128, 128, 255) : new Color(191, 191, 191, 255);
			DrawLine3D(new Vector3(p, 0, -e), new Vector3(p, 0, e), color);
			DrawLine3D(new Vector3(-e, 0, p), new Vector3(e, 0, p), color);
		}
	}

	// ---- Models and meshes ----

	/** raylib's model load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadModelAsync` loads it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unimplemented("LoadModel: Synchronous loading is not supported. See LoadModelAsync(fileName:String, loaded:Model->Void, ?failed:String->Void)")
	static function LoadModel(fileName:String):Model {
		throw "LoadModel is unimplemented";
	}

	// The model of a glTF or GLB file `LoadModelAsync` brought in: its meshes, their materials and its images. A file loaded again shares
	// its first load's meshes and textures, with materials of its own; meshes go to the GPU when first drawn.

	static function loadModel(fileName:String):Model {
		var path = normalize(fileName);
		var lower = path.toLowerCase();
		if (!(StringTools.endsWith(lower, ".glb") || StringTools.endsWith(lower, ".gltf"))) {
			Runtime.log(4, 'LoadModelAsync: $fileName: only glTF and GLB are read here');
			return new Model([], [Models.defaultMaterial(defaultShader())], []);
		}
		try {
			var model = Models.load(path, () -> Runtime.file(path), defaultShader());
			if (model != null)
				return model;
			Runtime.log(4, 'LoadModelAsync: $path couldn\'t be read');
		} catch (e:Dynamic) {
			Runtime.log(4, 'LoadModelAsync: $fileName: $e');
		}
		return new Model([], [Models.defaultMaterial(defaultShader())], []);
	}

	/** Makes a model of one mesh, with the default material.

		@param mesh  The mesh.
		@return  The model. */
	static function LoadModelFromMesh(mesh:Mesh):Model {
		return new Model([mesh], [Models.defaultMaterial(defaultShader())], [0]);
	}

	/** Returns whether a model has meshes.

		@param model  The model.
		@return  True when it has. */
	static function IsModelValid(model:Model):Bool {
		return model.meshCount > 0;
	}

	/** Frees a model: one load of its file, its meshes and textures with the last; a model of a mesh, its meshes and its materials'
		textures at once.

		@param model  The model. */
	static function UnloadModel(model:Model):Void {
		if (model.path != "") {
			Models.release(model);
			model.path = "";
			return;
		}
		for (mesh in model.meshes)
			Models.unload(mesh);
		for (m in model.materials)
			for (map in m.maps)
				if (map.texture.id != 0) {
					Textures.release(map.texture.id);
					map.texture.id = 0;
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
		var m = new Matrix3D().makeScale(scale.x, scale.y, scale.z);
		m = new Matrix3D().compose(m, new Matrix3D().makeRotation(rotationAxis.x, rotationAxis.y, rotationAxis.z, rotationAngle * DEG2RAD));
		m = new Matrix3D().compose(m, new Matrix3D().makeTranslation(position.x, position.y, position.z));
		var transform = new Matrix3D().compose(toMatrix3D(model.transform), m);
		for (i in 0...model.meshCount) {
			var material = model.materials[model.meshMaterial[i]];
			if (material == null)
				material = model.materials[0];
			drawMesh(model.meshes[i], material, transform, tint);
		}
	}

	/** Draws a mesh with a material and a transform.

		@param mesh  The mesh.
		@param material  The material.
		@param transform  The transform. */
	static function DrawMesh(mesh:Mesh, material:Material, transform:Matrix):Void {
		drawMesh(mesh, material, toMatrix3D(transform), WHITE);
	}

	/** Sends a mesh's vertices to the GPU, so it can be drawn. The `GenMesh*` functions and `LoadModelAsync` do it themselves.

		@param mesh  The mesh.
		@param isDynamic  Whether it will change (raylib names it `dynamic`, a Haxe keyword); meshes here can't, so it is ignored. */
	static function UploadMesh(mesh:Mesh, isDynamic:Bool):Void {
		Models.upload(mesh);
	}

	/** Frees a mesh's GPU buffers.

		@param mesh  The mesh. */
	static function UnloadMesh(mesh:Mesh):Void {
		Models.unload(mesh);
	}

	/** Makes a box mesh, centered on the origin.

		@param width  Along x.
		@param height  Along y.
		@param length  Along z.
		@return  The mesh. */
	static function GenMeshCube(width:Float, height:Float, length:Float):Mesh {
		return Models.cube(width, height, length);
	}

	/** Makes a flat mesh on the XZ plane, facing up.

		@param width  Along x.
		@param length  Along z.
		@param resX  Divisions along x.
		@param resZ  Divisions along z.
		@return  The mesh. */
	static function GenMeshPlane(width:Float, length:Float, resX:Int, resZ:Int):Mesh {
		return Models.plane(width, length, resX, resZ);
	}

	/** Makes a sphere mesh, centered on the origin.

		@param radius  Its radius.
		@param rings  Rings top to bottom.
		@param slices  Slices around.
		@return  The mesh. */
	static function GenMeshSphere(radius:Float, rings:Int, slices:Int):Mesh {
		return Models.sphere(radius, rings, slices);
	}

	/** Returns raylib's default material: the default shader, white.

		@return  The material. */
	static function LoadMaterialDefault():Material {
		return Models.defaultMaterial(defaultShader());
	}

	/** Sets a texture on a material's map.

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

	/** Returns a mesh's bounds.

		@param mesh  The mesh.
		@return  The box. */
	static function GetMeshBoundingBox(mesh:Mesh):BoundingBox {
		return Models.bounds(mesh);
	}

	/** Returns a model's bounds, its transform applied.

		@param model  The model.
		@return  The box. */
	static function GetModelBoundingBox(model:Model):BoundingBox {
		var t = toMatrix3D(model.transform);
		var min = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
		var max = [Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];
		for (mesh in model.meshes) {
			var b = Models.bounds(mesh);
			for (x in [b.min.x, b.max.x])
				for (y in [b.min.y, b.max.y])
					for (z in [b.min.z, b.max.z]) {
						var p = t.transformPoint(x, y, z), q = [p.x, p.y, p.z];
						for (c in 0...3) {
							if (q[c] < min[c])
								min[c] = q[c];
							if (q[c] > max[c])
								max[c] = q[c];
						}
					}
		}
		if (model.meshes.length == 0)
			return new BoundingBox(new Vector3(), new Vector3());
		return new BoundingBox(new Vector3(min[0], min[1], min[2]), new Vector3(max[0], max[1], max[2]));
	}

	// ---- Collisions in 3D ----

	/** Returns whether two boxes overlap.

		@param box1  One.
		@param box2  The other.
		@return  True when they overlap. */
	static function CheckCollisionBoxes(box1:BoundingBox, box2:BoundingBox):Bool {
		return box1.max.x >= box2.min.x && box1.min.x <= box2.max.x && box1.max.y >= box2.min.y && box1.min.y <= box2.max.y && box1.max.z >= box2.min.z
			&& box1.min.z <= box2.max.z;
	}

	/** Returns whether two spheres overlap.

		@param center1  One's center.
		@param radius1  Its radius.
		@param center2  The other's center.
		@param radius2  Its radius.
		@return  True when they overlap. */
	static function CheckCollisionSpheres(center1:Vector3, radius1:Float, center2:Vector3, radius2:Float):Bool {
		return Vector3Distance(center1, center2) <= radius1 + radius2;
	}

	/** Returns whether a box and a sphere overlap.

		@param box  The box.
		@param center  The sphere's center.
		@param radius  Its radius.
		@return  True when they overlap. */
	static function CheckCollisionBoxSphere(box:BoundingBox, center:Vector3, radius:Float):Bool {
		var x = Clamp(center.x, box.min.x, box.max.x),
			y = Clamp(center.y, box.min.y, box.max.y),
			z = Clamp(center.z, box.min.z, box.max.z);
		return Vector3Distance(new Vector3(x, y, z), center) <= radius;
	}

	/** Returns where a ray hits a sphere.

		@param ray  The ray.
		@param center  The sphere's center.
		@param radius  Its radius.
		@return  The hit. */
	static function GetRayCollisionSphere(ray:Ray, center:Vector3, radius:Float):RayCollision {
		var result = new RayCollision(false, 0, new Vector3(), new Vector3());
		var oc = Vector3Subtract(ray.position, center);
		var b = Vector3DotProduct(oc, ray.direction),
			c = Vector3DotProduct(oc, oc) - radius * radius;
		var d = b * b - c;
		if (d < 0)
			return result;
		var t = -b - Math.sqrt(d);
		if (t < 0)
			t = -b + Math.sqrt(d);
		if (t < 0)
			return result;
		result.hit = true;
		result.distance = t;
		result.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
		result.normal = Vector3Normalize(Vector3Subtract(result.point, center));
		return result;
	}

	/** Returns where a ray hits a box.

		@param ray  The ray.
		@param box  The box.
		@return  The hit. */
	static function GetRayCollisionBox(ray:Ray, box:BoundingBox):RayCollision {
		var result = new RayCollision(false, 0, new Vector3(), new Vector3());
		var o = [ray.position.x, ray.position.y, ray.position.z],
			d = [ray.direction.x, ray.direction.y, ray.direction.z];
		var lo = [box.min.x, box.min.y, box.min.z],
			hi = [box.max.x, box.max.y, box.max.z];
		var tmin = Math.NEGATIVE_INFINITY, tmax = Math.POSITIVE_INFINITY, axis = 0, sign = 1.;
		for (i in 0...3) {
			if (d[i] == 0) {
				if (o[i] < lo[i] || o[i] > hi[i])
					return result;
				continue;
			}
			var t1 = (lo[i] - o[i]) / d[i], t2 = (hi[i] - o[i]) / d[i];
			var near = Math.min(t1, t2), far = Math.max(t1, t2);
			if (near > tmin) {
				tmin = near;
				axis = i;
				sign = t1 < t2 ? -1 : 1;
			}
			if (far < tmax)
				tmax = far;
		}
		if (tmax < 0 || tmin > tmax)
			return result;
		var t = tmin >= 0 ? tmin : tmax;
		result.hit = true;
		result.distance = t;
		result.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
		var n = [0., 0, 0];
		n[axis] = sign;
		result.normal = new Vector3(n[0], n[1], n[2]);
		return result;
	}

	/** Returns where a ray hits a triangle.

		@param ray  The ray.
		@param p1  A corner.
		@param p2  A corner.
		@param p3  A corner.
		@return  The hit. */
	static function GetRayCollisionTriangle(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3):RayCollision {
		var result = new RayCollision(false, 0, new Vector3(), new Vector3());
		var e1 = Vector3Subtract(p2, p1), e2 = Vector3Subtract(p3, p1);
		var p = Vector3CrossProduct(ray.direction, e2),
			det = Vector3DotProduct(e1, p);
		if (Math.abs(det) < 1e-6)
			return result;
		var inv = 1 / det, t0 = Vector3Subtract(ray.position, p1);
		var u = Vector3DotProduct(t0, p) * inv;
		if (u < 0 || u > 1)
			return result;
		var q = Vector3CrossProduct(t0, e1),
			v = Vector3DotProduct(ray.direction, q) * inv;
		if (v < 0 || u + v > 1)
			return result;
		var t = Vector3DotProduct(e2, q) * inv;
		if (t <= 1e-6)
			return result;
		result.hit = true;
		result.distance = t;
		result.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
		result.normal = Vector3Normalize(Vector3CrossProduct(e1, e2));
		return result;
	}

	/** Returns where a ray hits a mesh drawn with a transform: its nearest triangle.

		@param ray  The ray.
		@param mesh  The mesh.
		@param transform  The transform.
		@return  The hit. */
	static function GetRayCollisionMesh(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision {
		var best = new RayCollision(false, 0, new Vector3(), new Vector3());
		var v = mesh.vertices;
		if (v == null)
			return best;
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
			if (hit.hit && (!best.hit || hit.distance < best.distance))
				best = hit;
		}
		return best;
	}

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
	static var deltaX = 0.;
	static var deltaY = 0.;
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

		@param source  The compiled program.
		@return  The shader. */
	@:noCompletion
	static function makeShader(source:helix.ray.internal.ProgramSource):Shader {
		var p = new helix.ray.internal.Program(Runtime.graphics, source);
		return new Shader(p.handle, locations(p), p);
	}

	// raylib's SHADER_LOC_* locations of a program.

	static function locations(p:helix.ray.internal.Program):Array<Int> {
		var locs = [for (_ in 0...32) -1];
		locs[SHADER_LOC_VERTEX_POSITION] = p.attributes.indexOf("vertexPosition");
		locs[SHADER_LOC_VERTEX_TEXCOORD01] = p.attributes.indexOf("vertexTexCoord");
		locs[SHADER_LOC_VERTEX_NORMAL] = p.attributes.indexOf("vertexNormal");
		locs[SHADER_LOC_VERTEX_COLOR] = p.attributes.indexOf("vertexColor");
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

	static function cameraView(camera:Camera3D):Matrix3D {
		var p = camera.position, t = camera.target, u = camera.up;
		return new Matrix3D().makeLookAt(p.x, p.y, p.z, t.x, t.y, t.z, u.x, u.y, u.z);
	}

	// raylib's near and far planes, 0.01 and 1000.

	static function cameraProjection(camera:Camera3D, aspect:Float):Matrix3D {
		if (camera.projection == CAMERA_ORTHOGRAPHIC) {
			var top = camera.fovy / 2, right = top * aspect;
			return new Matrix3D().makeOrthographic(-right, right, -top, top, .01, 1000);
		}
		return new Matrix3D().makePerspective(camera.fovy * DEG2RAD, aspect, .01, 1000);
	}

	static function drawMesh(mesh:Mesh, material:Material, transform:Matrix3D, tint:Color):Void {
		if (mesh.gpu.buffers == null)
			Models.upload(mesh);
		if (mesh.gpu.buffers == null)
			return;
		var shader = material.shader == null || material.shader.program == null ? defaultShader() : material.shader;
		var c = material.maps[MATERIAL_MAP_DIFFUSE].color;
		var diffuse = [
			c.r / 255 * tint.r / 255,
			c.g / 255 * tint.g / 255,
			c.b / 255 * tint.b / 255,
			c.a / 255 * tint.a / 255
		];
		var textures = [for (i in 0...3) Textures.handle(material.maps[i].texture.id)];
		Runtime.frame.mesh(mesh, shader.program, transform, diffuse, textures);
	}
	#end
}
