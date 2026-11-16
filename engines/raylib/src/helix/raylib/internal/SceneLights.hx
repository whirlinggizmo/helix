package helix.raylib.internal;

import haxe.io.Bytes;
import helix.math.Matrix4;
import helix.services.shaders.ShaderUniform;

/** Holds the scene's lights (rlights' `CreateLight`) and lights each draw through a shader declaring rlights' `lights`: the lights
	reaching the draw's bounds most, at most `DRAW_LIGHTS`, written into the shader's `lights` before the draw is recorded, the rest of
	them off.

	A light's score is its brightness (the luminance of its color times its intensity), times its falloff at the bounds' nearest point
	(the shaders' inverse square windowed to nothing at its range, none past the range, and none for a light without one), times a spot
	light's cone toward the bounds' sphere, unless the light is inside it. A directional light scores its brightness everywhere.

	Linked only by a program calling `CreateLight`, whose first call sets the draws' hooks (`RModels.lighting`, `Frame.lighting`). */
@:noCompletion
@:access(helix.raylib.Mesh)
@:access(helix.raylib.Light)
class SceneLights {
	/** The most lights a draw is lit by, `lights.glsl`'s `MAX_LIGHTS`. */
	public static inline final DRAW_LIGHTS = 8;

	// The scene's lights, in the order made.
	static final lights:Array<helix.raylib.Light> = [];
	// Each draw's choice, best first, and the scores they won with.
	static final chosen:Array<Null<helix.raylib.Light>> = [for (_ in 0...DRAW_LIGHTS) null];
	static final scores:Array<Float> = [for (_ in 0...DRAW_LIGHTS) 0.];

	/** The draw's bounds in the world: the least x, y and z, then the most. */
	public static final box:Array<Float> = [0, 0, 0, 0, 0, 0];

	// An instance's transform, column by column.
	static final instance:Array<Float> = [for (_ in 0...16) 0.];
	// A program's lights fields, by the indices below, as `lights` declares them: the uniforms `lights.enabled` and the rest.
	static final FIELDS = [
		"lights.enabled",
		"lights.type",
		"lights.position",
		"lights.target",
		"lights.color",
		"lights.range",
		"lights.intensity",
		"lights.innerCosine",
		"lights.outerCosine",
		"lights.shadow"
	];
	static final NONE:Array<Null<ShaderUniform>> = [];

	/** Writes the shadows into a program its draw's lights are written into (`Shadows`): set by the first `SetLightShadows`, null in a
		program casting none. It has no initial value, as `Frame.spriteShader` has none. */
	public static var receiving:Null<Program->Void>;

	/** Adds a light to the scene, the draws' hooks set with the first.

		@param light  The light. */
	public static function add(light:helix.raylib.Light):Void {
		if (lights.length == 0) {
			helix.raylib.modules.RModels.lighting = lightMesh;
			Frame.lighting = lightRun;
		}
		if (lights.indexOf(light) < 0)
			lights.push(light);
	}

	/** Takes a light out of the scene.

		@param light  The light. */
	public static function remove(light:helix.raylib.Light):Void
		lights.remove(light);

	/** Returns whether a light is in the scene.

		@param light  The light. */
	public static function has(light:helix.raylib.Light):Bool
		return lights.indexOf(light) >= 0;

	// A program's lights fields, found once; NONE for a program whose shader declares no lights.
	static function fields(p:Program):Array<Null<ShaderUniform>> {
		if (p.lightFields == null) {
			var enabled = p.shader.findUniform(FIELDS[0]);
			p.lightFields = enabled == null || !enabled.active ? NONE : [for (name in FIELDS) p.shader.findUniform(name)];
		}
		return p.lightFields;
	}

	// Lights a mesh's draw: its bounds the mesh's moved by its transform, or by each instance's.
	static function lightMesh(p:Program, mesh:helix.raylib.Mesh, model:Matrix4, transforms:Null<Array<helix.raylib.Matrix>>, count:Int):Void {
		var own = fields(p), twin = p.twin, twins = twin == null ? NONE : fields(twin);
		if (own.length == 0 && twins.length == 0)
			return;
		if (!bound(mesh, model, transforms, count))
			unbounded();
		var n = choose();
		if (own.length > 0)
			write(p, own, n);
		if (twins.length > 0)
			write(twin, twins, n);
	}

	/** Finds a mesh's draw's bounds in the world, the least x, y and z then the most, into `box`: the mesh's moved by its transform, or
		grown to hold them moved by each instance's.

		@param mesh  The mesh.
		@param model  Its transform.
		@param transforms  The instances' transforms, `DrawMeshInstanced`'s; null for one draw.
		@param count  How many instances.
		@return  False for a mesh without positions, whose bounds aren't found. */
	public static function bound(mesh:helix.raylib.Mesh, model:Matrix4, transforms:Null<Array<helix.raylib.Matrix>>, count:Int):Bool {
		var local = meshBounds(mesh);
		if (local == null)
			return false;
		if (transforms != null)
			for (i in 0...count) {
				var t = transforms[i];
				instance[0] = t.m0;
				instance[1] = t.m1;
				instance[2] = t.m2;
				instance[3] = t.m3;
				instance[4] = t.m4;
				instance[5] = t.m5;
				instance[6] = t.m6;
				instance[7] = t.m7;
				instance[8] = t.m8;
				instance[9] = t.m9;
				instance[10] = t.m10;
				instance[11] = t.m11;
				instance[12] = t.m12;
				instance[13] = t.m13;
				instance[14] = t.m14;
				instance[15] = t.m15;
				place(local, instance, i > 0);
			}
		else
			place(local, model.values, false);
		return true;
	}

	// Lights a run of immediate vertices (rlgl's, a shape's): its bounds those of the vertices' positions, as the batch holds them.
	static function lightRun(p:Program, data:Bytes, first:Int, count:Int, stride:Int):Void {
		var own = fields(p);
		if (own.length == 0 || count <= 0)
			return;
		for (i in 0...count) {
			var at = (first + i) * stride;
			for (k in 0...3) {
				var v = data.getFloat(at + k * 4);
				if (i == 0 || v < box[k])
					box[k] = v;
				if (i == 0 || v > box[k + 3])
					box[k + 3] = v;
			}
		}
		write(p, own, choose());
	}

	// A mesh's bounds in its own space, worked out again once its positions are another array; null for a mesh without positions.
	static function meshBounds(mesh:helix.raylib.Mesh):Null<Array<Float>> {
		var v = mesh.vertices;
		if (v == null || mesh.vertexCount <= 0)
			return null;
		if (mesh.bounds == null || mesh.boundsOf != v) {
			var b = mesh.bounds == null ? [0., 0, 0, 0, 0, 0] : mesh.bounds;
			var count = mesh.vertexCount * 3 < v.length ? mesh.vertexCount : Std.int(v.length / 3);
			for (i in 0...count)
				for (k in 0...3) {
					var x = v[i * 3 + k];
					if (i == 0 || x < b[k])
						b[k] = x;
					if (i == 0 || x > b[k + 3])
						b[k + 3] = x;
				}
			mesh.bounds = b;
			mesh.boundsOf = v;
		}
		return mesh.bounds;
	}

	// The draw's bounds, every light reaching them: for a mesh without positions.
	static function unbounded():Void {
		for (k in 0...3) {
			box[k] = -1e30;
			box[k + 3] = 1e30;
		}
	}

	// Local bounds moved by a transform (column by column) into the draw's, or grown to hold them: the center moved and the half
	// extents through the matrix's absolute values.
	static function place(local:Array<Float>, m:Array<Float>, grow:Bool):Void {
		var cx = (local[0] + local[3]) / 2,
			cy = (local[1] + local[4]) / 2,
			cz = (local[2] + local[5]) / 2;
		var ex = (local[3] - local[0]) / 2,
			ey = (local[4] - local[1]) / 2,
			ez = (local[5] - local[2]) / 2;
		for (k in 0...3) {
			var c = m[k] * cx + m[4 + k] * cy + m[8 + k] * cz + m[12 + k];
			var e = Math.abs(m[k]) * ex + Math.abs(m[4 + k]) * ey + Math.abs(m[8 + k]) * ez;
			if (!grow || c - e < box[k])
				box[k] = c - e;
			if (!grow || c + e > box[k + 3])
				box[k + 3] = c + e;
		}
	}

	// Chooses the lights reaching the draw's bounds most, best first, ties in the order made; returns how many reach them.
	static function choose():Int {
		var n = 0;
		for (light in lights) {
			if (!light.enabled)
				continue;
			var s = score(light);
			if (s <= 0)
				continue;
			var at = n;
			while (at > 0 && scores[at - 1] < s)
				at--;
			if (at >= DRAW_LIGHTS)
				continue;
			if (n < DRAW_LIGHTS)
				n++;
			var j = n - 1;
			while (j > at) {
				scores[j] = scores[j - 1];
				chosen[j] = chosen[j - 1];
				j--;
			}
			scores[at] = s;
			chosen[at] = light;
		}
		return n;
	}

	/** Returns how much a light reaches the draw's bounds: its brightness, through its falloff at their nearest point and a spot
		light's cone toward them; 0 for a light that can't reach them.

		@param light  The light. */
	static function score(light:helix.raylib.Light):Float {
		var c = light.color;
		var s = (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) / 255 * light.intensity;
		if (s <= 0 || (light.type != helix.raylib.Rlights.LIGHT_POINT && light.type != SPOT))
			return s;
		var px = light.position.x,
			py = light.position.y,
			pz = light.position.z;
		var nx = clamp(px, box[0], box[3]) - px,
			ny = clamp(py, box[1], box[4]) - py,
			nz = clamp(pz, box[2], box[5]) - pz;
		var d2 = nx * nx + ny * ny + nz * nz, range = light.range;
		if (range > 0) {
			if (d2 >= range * range)
				return 0;
			// The shaders' falloff: inverse square (from 0.1 out, for the score), windowed to nothing at the range.
			var q2 = d2 / (range * range), window = clamp(1 - q2 * q2, 0, 1);
			s *= window * window / (d2 > 0.01 ? d2 : 0.01);
		}
		if (light.type == SPOT) {
			// The cone toward the bounds' sphere: the angle from the cone's middle to their center, less the angle their radius takes
			// up, so a spot over part of a wide floor reaches it; a light within the sphere reaches it whatever its cone.
			var tx = (box[0] + box[3]) / 2 - px,
				ty = (box[1] + box[4]) / 2 - py,
				tz = (box[2] + box[5]) / 2 - pz;
			var tl = Math.sqrt(tx * tx + ty * ty + tz * tz);
			var rx = (box[3] - box[0]) / 2,
				ry = (box[4] - box[1]) / 2,
				rz = (box[5] - box[2]) / 2;
			var radius = Math.sqrt(rx * rx + ry * ry + rz * rz);
			if (tl > radius) {
				var dx = light.target.x - px,
					dy = light.target.y - py,
					dz = light.target.z - pz;
				var dl = Math.sqrt(dx * dx + dy * dy + dz * dz);
				var cosine = dl > 0 ? (tx * dx + ty * dy + tz * dz) / (tl * dl) : 1;
				var angle = Math.acos(clamp(cosine, -1, 1)) - Math.asin(radius / tl);
				s *= cone(angle > 0 ? Math.cos(angle) : 1, light.innerCosine, light.outerCosine);
			}
		}
		return s;
	}

	/** Returns a spot light's cone at a direction, as the shaders have it: 1 inside the inner angle, fading smoothly to 0 at the outer.

		@param cosine  The cosine of the angle from the cone's middle.
		@param inner  The inner angle's cosine.
		@param outer  The outer angle's cosine. */
	public static function cone(cosine:Float, inner:Float, outer:Float):Float {
		if (inner - outer <= 1e-6)
			return cosine >= outer ? 1 : 0;
		var t = clamp((cosine - outer) / (inner - outer), 0, 1);
		return t * t * (3 - 2 * t);
	}

	static inline final SPOT = 2;

	static inline function clamp(x:Float, low:Float, high:Float):Float
		return x < low ? low : x > high ? high : x;

	// Writes the draw's lights into a program's lights, its others off, and the shadows they cast.
	static function write(p:Program, f:Array<Null<ShaderUniform>>, n:Int):Void {
		if (receiving != null)
			receiving(p);
		var values = p.values;
		var slots = f[0].elementCount < DRAW_LIGHTS ? f[0].elementCount : DRAW_LIGHTS;
		for (i in 0...slots) {
			if (i >= n) {
				values.writeInt(f[0], 0, i);
				continue;
			}
			var light = chosen[i];
			values.writeInt(f[0], 1, i);
			if (f[1] != null)
				values.writeInt(f[1], light.type, i);
			if (f[2] != null)
				values.writeVector3(f[2], light.position.x, light.position.y, light.position.z, i);
			if (f[3] != null)
				values.writeVector3(f[3], light.target.x, light.target.y, light.target.z, i);
			if (f[4] != null) {
				var c = light.color;
				if (f[4].type.componentCount == 4)
					values.writeVector(f[4], c.r / 255, c.g / 255, c.b / 255, c.a / 255, i);
				else
					values.writeVector3(f[4], c.r / 255, c.g / 255, c.b / 255, i);
			}
			if (f[5] != null)
				values.writeFloat(f[5], light.range, i);
			if (f[6] != null)
				values.writeFloat(f[6], light.intensity, i);
			if (f[7] != null)
				values.writeFloat(f[7], light.innerCosine, i);
			if (f[8] != null)
				values.writeFloat(f[8], light.outerCosine, i);
			if (f[9] != null)
				values.writeInt(f[9], light.shadowIndex, i);
		}
	}
}
