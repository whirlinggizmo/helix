package helix.geometry;

import helix.math.Matrix4;

/** Represents a skin: the bones of a skeleton a mesh's vertices follow, and how each vertex was bound to them. A vertex's `jointIndices`
	index this skin's `boneIndices`, not the skeleton's. */
class Skin3D {
	/** Gets its name: empty for none. */
	public final name:String;

	/** Gets the indices of its bones in the skeleton's `bones`. */
	public final boneIndices:Array<Int>;

	/** Gets each of its bones' inverse bind matrix, moving a vertex from the mesh's space to the bone's as the mesh was bound. */
	public final inverseBinds:Array<Matrix4>;

	/** Creates a skin.

		@param name  Its name.
		@param boneIndices  The indices of its bones in the skeleton's.
		@param inverseBinds  Each one's inverse bind matrix. */
	public function new(name:String, boneIndices:Array<Int>, inverseBinds:Array<Matrix4>) {
		this.name = name;
		this.boneIndices = boneIndices;
		this.inverseBinds = inverseBinds;
	}

	/** Returns the matrices a mesh of this skin is moved by, from each bone's place in the model (`Skeleton3D.computeWorld`): each of its
		bones' inverse bind, then its place, so a skinned vertex comes out in the model's space. For a shader's joint matrices, or
		`Mesh3D.computeSkinned`.

		@param world  Each of the skeleton's bones' place in the model.
		@param out  Optional. Set to the matrices, reused, grown or shrunk to fit.
		@return  The matrices, by this skin's bone. */
	public function computeSkinning(world:Array<Matrix4>, ?out:Array<Matrix4>):Array<Matrix4> {
		out = Skeleton3D.fit(out, boneIndices.length, () -> new Matrix4());
		for (j => bone in boneIndices)
			Matrix4.compose(inverseBinds[j], world[bone], out[j]);
		return out;
	}
}
