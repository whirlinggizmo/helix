package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RMath.*;
#end

/** Holds helix-raylib's bounds of a model as posed, which raylib's `GetModelBoundingBox` leaves at the bind pose. Each is written here,
	and `helix.raylib.extras.Models` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RModelsPosed {
	#if !macro
	/** Returns a model's bounds as its last `UpdateModelAnimation` (or `UpdateModelAnimationEx`) posed it: `GetModelBoundingBox`'s box,
		each skinned mesh bounded by its vertices where its bones put them rather than where the skin was bound. A mesh never posed, or
		without bones, counts as it is, and so does a vertex no bone weights. It is exact whatever shader draws the mesh, as it works the positions out from the pose itself,
		allocating nothing; that is each skinned vertex moved by its bones, on the CPU, each call. As `GetModelBoundingBox`, its least and
		most corners are then moved by the model's transform (a turned model's box is not its bounds).

		@param model  The model.
		@return  The box. */
	static function GetModelBoundingBoxPosed(model:Model):BoundingBox {
		var minX = Math.POSITIVE_INFINITY,
			minY = Math.POSITIVE_INFINITY,
			minZ = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY,
			maxY = Math.NEGATIVE_INFINITY,
			maxZ = Math.NEGATIVE_INFINITY;
		for (m in 0...model.meshCount) {
			var mesh = model.meshes[m];
			var v = mesh.vertices;
			if (v == null)
				continue;
			@:privateAccess var pose = mesh.pose;
			var ids = mesh.boneIds, weights = mesh.boneWeights;
			var skinned = pose != null && ids != null && weights != null;
			var bones = skinned ? pose.bones : null;
			var boneCount = skinned ? Std.int(bones.length / 16) : 0;
			for (i in 0...mesh.vertexCount) {
				var x = v[i * 3], y = v[i * 3 + 1], z = v[i * 3 + 2];
				if (skinned) {
					// The vertex moved by each of its bones, by its weight, as raylib's CPU skinning moves it.
					var px = 0., py = 0., pz = 0., weighed = false;
					for (k in 0...4) {
						var w = weights[i * 4 + k], b = ids[i * 4 + k];
						if (w <= 0 || b >= boneCount)
							continue;
						var at = b * 16;
						px += (bones[at] * x + bones[at + 4] * y + bones[at + 8] * z + bones[at + 12]) * w;
						py += (bones[at + 1] * x + bones[at + 5] * y + bones[at + 9] * z + bones[at + 13]) * w;
						pz += (bones[at + 2] * x + bones[at + 6] * y + bones[at + 10] * z + bones[at + 14]) * w;
						weighed = true;
					}
					if (weighed) {
						x = px;
						y = py;
						z = pz;
					}
				}
				if (x < minX)
					minX = x;
				if (y < minY)
					minY = y;
				if (z < minZ)
					minZ = z;
				if (x > maxX)
					maxX = x;
				if (y > maxY)
					maxY = y;
				if (z > maxZ)
					maxZ = z;
			}
		}
		if (minX > maxX)
			minX = minY = minZ = maxX = maxY = maxZ = 0;
		return new BoundingBox(Vector3Transform(new Vector3(minX, minY, minZ), model.transform),
			Vector3Transform(new Vector3(maxX, maxY, maxZ), model.transform));
	}
	#end
}
