package helix.raylib.modules;

#if !macro
import helix.geometry.Mesh3D;
import helix.math.Matrix3D;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
#end

/** Holds helix-raylib's merge of models. It is written here, and `helix.raylib.extras.Models` forwards to it (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RModelsMerged {
	#if !macro
	/** Returns a new model with the provided models' meshes merged where possible. The provided models are unchanged. For example, a
		character's head, body, legs and feet models, whose materials differ only in color, are merged into one character model with one
		mesh.

		Meshes whose materials differ only in diffuse color are merged into one mesh. Each material's diffuse color is multiplied into the
		vertex colors, and the merged mesh has one material, the same material with a white diffuse color. Meshes whose materials differ in
		anything else (the shader, a texture, `unlit`, or another map's color or value) stay separate meshes.

		A shader that ignores the vertex color draws a merged mesh without the materials' colors.

		A mesh lacking normals, texture coordinates or colors that another merged mesh has gets normals (0, 0, 1), texture coordinates
		(0, 0) and white colors. Tangents are kept when every merged mesh has them. `texcoords2` is dropped.

		With `skeleton`, the new model has the bones, bind pose and transform of `skeleton`, and an animation that poses `skeleton` poses
		the new model. Each provided model's bones are matched to the bones of `skeleton` by name. A vertex following a bone that `skeleton`
		lacks follows the nearest ancestor of that bone that `skeleton` has. A vertex with no such ancestor stays where it is when the new
		model is posed. A provided model bound in another bind pose is rebound to the bind pose of `skeleton`. A vertex following several
		bones whose bind poses differ by different amounts is rebound approximately. A provided model without bones is placed where its
		transform put it.

		Without `skeleton`, the new model has no bones and the identity transform. Each provided model's transform is multiplied into the
		model's vertices, and a provided model with bones is merged at its bind pose.

		The merged meshes are uploaded. Refused, with the reason logged, for an empty list, for a provided model with bones whose transform
		differs from the transform of `skeleton`, and for a `skeleton` of more than 256 bones.

		@param models  The models.
		@param skeleton  Optional. The model whose bones, bind pose and transform the new model takes. Usually one of the provided models.
		@return  The new model, or null when refused. */
	static function LoadModelFromModels(models:Array<Model>, ?skeleton:Model):Null<Model> {
		if (models.length == 0)
			return refuse("no models");
		if (skeleton != null && skeleton.boneCount > 256)
			return refuse('a skeleton of ${skeleton.boneCount} bones, over 256');
		var skeletonTransform = skeleton == null ? null : RModels.toMatrix3D(skeleton.transform);
		if (skeleton != null)
			for (model in models)
				if (hasBones(model) && !near(RModels.toMatrix3D(model.transform), skeletonTransform, 1e-5))
					return refuse("a model with bones whose transform differs from the skeleton's");

		// Each group is the meshes of one material but for its diffuse color, in the order the groups' first meshes come.
		var groupMaterials:Array<Material> = [],
			groups:Array<Array<Mesh3D>> = [];
		for (model in models) {
			var placed = skeleton == null || !hasBones(model) ? placement(model, skeletonTransform) : null;
			var rewritten = skeleton != null && hasBones(model) ? bonesOnto(model, skeleton) : null;
			for (i in 0...model.meshCount) {
				var mesh = model.meshes[i];
				if (mesh.vertices == null || mesh.vertexCount == 0)
					continue;
				var material = model.materials[model.meshMaterial[i]];
				var index = 0;
				while (index < groupMaterials.length && !sameButDiffuse(groupMaterials[index], material))
					index++;
				if (index == groupMaterials.length) {
					groupMaterials.push(material);
					groups.push([]);
				}
				var part = readMesh(mesh, skeleton != null && hasBones(model));
				if (placed != null)
					part = part.transform(placed);
				if (rewritten != null && part.jointIndices != null) {
					if (rewritten.rebinds != null)
						rebind(part, rewritten.rebinds);
					part = part.remapJointIndices(rewritten.newJointIndices);
				}
				var c = material.maps[MATERIAL_MAP_ALBEDO].color;
				if (c.r != 255 || c.g != 255 || c.b != 255 || c.a != 255)
					part = part.tint((c.a << 24) | (c.r << 16) | (c.g << 8) | c.b);
				groups[index].push(part);
			}
		}

		var meshes = [for (group in groups) writeMesh(mergedWithNormals(group))];
		var materials = [for (m in groupMaterials) whiteCopy(m)];
		var model = new Model(meshes, materials, [for (i in 0...meshes.length) i]);
		Models.disown(meshes, materials);
		for (mesh in meshes)
			Models.upload(mesh);
		if (skeleton != null) {
			model.transform = skeleton.transform.copy();
			if (hasBones(skeleton)) {
				model.boneCount = skeleton.boneCount;
				model.bones = [for (b in skeleton.bones) b.copy()];
				model.bindPose = skeleton.bindPose == null ? null : [for (t in skeleton.bindPose) t.copy()];
				Models.posable(model);
			}
		}
		return model;
	}

	static function refuse(reason:String):Null<Model> {
		Runtime.log(LOG_WARNING, 'MODEL: LoadModelFromModels refused: $reason');
		return null;
	}

	static inline function hasBones(model:Model):Bool
		return model.boneCount > 0 && model.bones != null;

	// What moves a model's vertices to their place in the new model: its transform, under a skeleton's the inverse of that one's.
	static function placement(model:Model, skeletonTransform:Null<Matrix3D>):Matrix3D {
		var own = RModels.toMatrix3D(model.transform);
		if (skeletonTransform == null)
			return own;
		var inverse = skeletonTransform.invert();
		return inverse == null ? own : Matrix3D.compose(own, inverse);
	}

	static function near(a:Matrix3D, b:Matrix3D, tolerance:Float):Bool {
		for (i in 0...16)
			if (Math.abs(a.values[i] - b.values[i]) > tolerance)
				return false;
		return true;
	}

	static function sameButDiffuse(a:Material, b:Material):Bool {
		if (a == b)
			return true;
		if (a.shader.id != b.shader.id || a.unlit != b.unlit || a.maps.length != b.maps.length)
			return false;
		for (i in 0...a.params.length)
			if (a.params[i] != b.params[i])
				return false;
		for (i in 0...a.maps.length) {
			var x = a.maps[i], y = b.maps[i];
			if (x.texture.id != y.texture.id || x.value != y.value)
				return false;
			if (i != MATERIAL_MAP_ALBEDO
				&& (x.color.r != y.color.r || x.color.g != y.color.g || x.color.b != y.color.b || x.color.a != y.color.a))
				return false;
		}
		return true;
	}

	static function whiteCopy(material:Material):Material {
		var maps = [for (m in material.maps) new MaterialMap(m.texture, m.color, m.value)];
		maps[MATERIAL_MAP_ALBEDO].color = new Color(255, 255, 255, 255);
		var copy = new Material(material.shader, maps, material.params.copy());
		copy.unlit = material.unlit;
		return copy;
	}

	// A mesh's arrays as a Mesh3D, shared but for the colors, which change from bytes to 0 to 1.
	static function readMesh(mesh:Mesh, keepJoints:Bool):Mesh3D {
		var part = new Mesh3D();
		part.positions = mesh.vertices;
		part.normals = mesh.normals;
		part.texCoords = mesh.texcoords;
		part.tangents = mesh.tangents;
		part.indices = mesh.indices;
		if (mesh.colors != null) {
			var colors:Array<Float> = [];
			colors.resize(mesh.colors.length);
			for (i in 0...colors.length)
				colors[i] = mesh.colors[i] / 255;
			part.colors = colors;
		}
		if (keepJoints && mesh.boneIds != null && mesh.boneWeights != null) {
			part.jointIndices = mesh.boneIds;
			part.weights = mesh.boneWeights;
		}
		return part;
	}

	// The group merged, a mesh without normals given raylib's default of (0, 0, 1) where another mesh has normals.
	static function mergedWithNormals(group:Array<Mesh3D>):Mesh3D {
		var anyNormals = false;
		for (part in group)
			anyNormals = anyNormals || part.normals != null;
		if (anyNormals)
			for (part in group)
				if (part.normals == null) {
					var normals:Array<Float> = [];
					normals.resize(part.vertexCount * 3);
					for (i in 0...part.vertexCount) {
						normals[i * 3] = 0;
						normals[i * 3 + 1] = 0;
						normals[i * 3 + 2] = 1;
					}
					part.normals = normals;
				}
		return Mesh3D.merge(group);
	}

	static function writeMesh(part:Mesh3D):Mesh {
		var mesh = new Mesh();
		mesh.vertexCount = part.vertexCount;
		mesh.triangleCount = part.triangleCount;
		mesh.vertices = part.positions;
		mesh.normals = part.normals;
		mesh.texcoords = part.texCoords;
		mesh.tangents = part.tangents;
		mesh.indices = part.indices;
		mesh.boneIds = part.jointIndices;
		mesh.boneWeights = part.weights;
		if (part.colors != null) {
			var colors:Array<Int> = [];
			colors.resize(part.colors.length);
			for (i in 0...colors.length)
				colors[i] = Std.int(part.colors[i] * 255 + .5);
			mesh.colors = colors;
		}
		return mesh;
	}

	// Each of a model's bones' new index in the skeleton, by name, or its nearest ancestor's, or -1; and when a bind pose differs, what
	// moves a vertex following each bone from the model's bind pose to the skeleton's (null for a bone the skeleton has nothing for).
	static function bonesOnto(model:Model, skeleton:Model):{newJointIndices:Array<Int>, rebinds:Null<Array<Null<Matrix3D>>>} {
		var byName = new Map<String, Int>();
		if (hasBones(skeleton))
			for (i => b in skeleton.bones)
				byName.set(b.name, i);
		var count = model.boneCount;
		var newJointIndices = [for (_ in 0...count) -1],
			matched = [for (_ in 0...count) -1];
		for (i in 0...count) {
			var at = i, steps = 0;
			while (at >= 0 && steps++ <= count) {
				var found = byName.get(model.bones[at].name);
				if (found != null) {
					newJointIndices[i] = found;
					matched[i] = at;
					break;
				}
				at = model.bones[at].parent;
			}
		}
		if (model.bindPose == null || skeleton.bindPose == null)
			return {newJointIndices: newJointIndices, rebinds: null};
		var identity = new Matrix3D();
		var any = false;
		var rebinds:Array<Null<Matrix3D>> = [
			for (i in 0...count) {
				var move:Null<Matrix3D> = null;
				if (matched[i] >= 0) {
					var inverse = matrixOf(model.bindPose[matched[i]]).invert();
					if (inverse != null) {
						move = Matrix3D.compose(inverse, matrixOf(skeleton.bindPose[newJointIndices[i]]));
						any = any || !near(move, identity, 1e-4);
					}
				}
				move;
			}
		];
		return {newJointIndices: newJointIndices, rebinds: any ? rebinds : null};
	}

	static function matrixOf(t:Transform):Matrix3D {
		var m = Matrix3D.compose(Matrix3D.fromScale(t.scale.x, t.scale.y, t.scale.z),
			Matrix3D.fromQuaternion(t.rotation.x, t.rotation.y, t.rotation.z, t.rotation.w));
		return Matrix3D.compose(m, Matrix3D.fromTranslation(t.translation.x, t.translation.y, t.translation.z));
	}

	// Moves each vertex by its bones' moves, blended by its weights, into new arrays: a part's positions and normals are the mesh's own.
	static function rebind(part:Mesh3D, rebinds:Array<Null<Matrix3D>>):Void {
		var joints = part.jointIndices, weights = part.weights;
		var positions = part.positions.copy();
		var normals = part.normals == null ? null : part.normals.copy();
		var tangents = part.tangents == null ? null : part.tangents.copy();
		var m = [for (_ in 0...16) 0.];
		for (k in 0...part.vertexCount) {
			for (i in 0...16)
				m[i] = 0;
			var total = 0.;
			for (j in k * 4...k * 4 + 4) {
				var w = weights[j];
				var move = w != 0 && joints[j] < rebinds.length ? rebinds[joints[j]] : null;
				if (move != null) {
					total += w;
					for (i in 0...16)
						m[i] += move.values[i] * w;
				}
			}
			if (total == 0)
				continue;
			for (i in 0...16)
				m[i] /= total;
			var x = positions[k * 3],
				y = positions[k * 3 + 1],
				z = positions[k * 3 + 2];
			positions[k * 3] = m[0] * x + m[4] * y + m[8] * z + m[12];
			positions[k * 3 + 1] = m[1] * x + m[5] * y + m[9] * z + m[13];
			positions[k * 3 + 2] = m[2] * x + m[6] * y + m[10] * z + m[14];
			if (normals != null) {
				// The upper 3 by 3's cofactors: its inverse transposed, times its determinant.
				var c0 = m[5] * m[10] - m[9] * m[6],
					c1 = m[9] * m[2] - m[1] * m[10],
					c2 = m[1] * m[6] - m[5] * m[2];
				var c3 = m[8] * m[6] - m[4] * m[10],
					c4 = m[0] * m[10] - m[8] * m[2],
					c5 = m[4] * m[2] - m[0] * m[6];
				var c6 = m[4] * m[9] - m[8] * m[5],
					c7 = m[8] * m[1] - m[0] * m[9],
					c8 = m[0] * m[5] - m[4] * m[1];
				var sign = m[0] * c0 + m[4] * c1 + m[8] * c2 < 0 ? -1 : 1;
				var a = normals[k * 3],
					b = normals[k * 3 + 1],
					c = normals[k * 3 + 2];
				unit(normals, k * 3, (c0 * a + c1 * b + c2 * c) * sign, (c3 * a + c4 * b + c5 * c) * sign, (c6 * a + c7 * b + c8 * c) * sign);
			}
			if (tangents != null) {
				var a = tangents[k * 4],
					b = tangents[k * 4 + 1],
					c = tangents[k * 4 + 2];
				unit(tangents, k * 4, m[0] * a + m[4] * b + m[8] * c, m[1] * a + m[5] * b + m[9] * c, m[2] * a + m[6] * b + m[10] * c);
			}
		}
		part.positions = positions;
		part.normals = normals;
		part.tangents = tangents;
	}

	static inline function unit(out:Array<Float>, at:Int, x:Float, y:Float, z:Float):Void {
		var length = Math.sqrt(x * x + y * y + z * z);
		out[at] = length > 0 ? x / length : x;
		out[at + 1] = length > 0 ? y / length : y;
		out[at + 2] = length > 0 ? z / length : z;
	}
	#end
}
