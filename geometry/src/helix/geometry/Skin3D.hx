package helix.geometry;

import helix.math.Matrix3D;

/** Represents a skin: the bones of a skeleton a mesh's vertices follow, and how each vertex was bound to them. A vertex's `joints`
	index this skin's `bones`, not the skeleton's. */
class Skin3D {
	/** Gets its name: empty for none. */
	public final name:String;

	/** Gets its bones, as indices into the skeleton's `bones`. */
	public final bones:Array<Int>;

	/** Gets each of its bones' inverse bind matrix, taking a vertex from the mesh's space to the bone's as the mesh was bound. */
	public final inverseBinds:Array<Matrix3D>;

	/** Creates a skin.

		@param name  Its name.
		@param bones  Its bones, as indices into the skeleton's.
		@param inverseBinds  Each one's inverse bind matrix. */
	public function new(name:String, bones:Array<Int>, inverseBinds:Array<Matrix3D>) {
		this.name = name;
		this.bones = bones;
		this.inverseBinds = inverseBinds;
	}

	/** Returns the matrices a mesh of this skin is moved by, from each bone's place in the model (`Skeleton3D.computeWorld`): each of its
		bones' inverse bind, then its place, so a skinned vertex comes out in the model's space. For a shader's joint matrices, or
		`Mesh3D.computeSkinned`.

		@param world  Each of the skeleton's bones' place in the model.
		@param out  Optional. Set to the matrices, reused, grown or shrunk to fit.
		@return  The matrices, by this skin's bone. */
	public function computeSkinning(world:Array<Matrix3D>, ?out:Array<Matrix3D>):Array<Matrix3D> {
		out = Skeleton3D.fit(out, bones.length, () -> new Matrix3D());
		for (j => bone in bones)
			Matrix3D.compose(inverseBinds[j], world[bone], out[j]);
		return out;
	}
}
