package helix.geometry;

import helix.math.Matrix3D;

/** Represents a skin: the bones of a skeleton a mesh's vertices follow, and how each vertex was bound to them. A vertex's `jointIndices`
	index this skin's `boneIndices`, not the skeleton's. */
class Skin3D {
	/** Gets its name: empty for none. */
	public final name:String;

	/** Gets the indices of its bones in the skeleton's `bones`. */
	public final boneIndices:Array<Int>;

	/** Gets each of its bones' inverse bind matrix, taking a vertex from the mesh's space to the bone's as the mesh was bound. */
	public final inverseBinds:Array<Matrix3D>;

	/** Creates a skin.

		@param name  Its name.
		@param boneIndices  The indices of its bones in the skeleton's.
		@param inverseBinds  Each one's inverse bind matrix. */
	public function new(name:String, boneIndices:Array<Int>, inverseBinds:Array<Matrix3D>) {
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
	public function computeSkinning(world:Array<Matrix3D>, ?out:Array<Matrix3D>):Array<Matrix3D> {
		out = Skeleton3D.fit(out, boneIndices.length, () -> new Matrix3D());
		for (j => bone in boneIndices)
			Matrix3D.compose(inverseBinds[j], world[bone], out[j]);
		return out;
	}
}
