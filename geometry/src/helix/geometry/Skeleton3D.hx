package helix.geometry;

import helix.math.Matrix3D;
import helix.math.Transform3D;

/** Represents a skeleton: bones, each a parent's child or a root, that skinned meshes' vertices follow, through skins.

	A pose is each bone's transform relative to its parent, by its index in `bones`: the rest pose (`computeRestPose`), or an
	animation's at a time (`Animation3D.computePose`). From a pose comes each bone's place in the model (`computeWorld`), and from that
	a skin's matrices (`Skin3D.computeSkinning`). Each method's out array is reused, grown or shrunk to fit, its objects reused. */
class Skeleton3D {
	/** Gets its bones, each after its parent. */
	public final bones:Array<Bone3D>;

	/** Creates a skeleton.

		@param bones  Its bones, each after its parent. */
	public function new(bones:Array<Bone3D>) {
		this.bones = bones;
	}

	/** Returns the index of the first bone of a name.

		@param name  The name.
		@return  Its index, or -1 for none. */
	public function findBone(name:String):Int {
		for (i => bone in bones)
			if (bone.name == name)
				return i;
		return -1;
	}

	/** Returns the rest pose: each bone's `rest`, copied.

		@param out  Optional. Set to the pose, its transforms reused.
		@return  The pose. */
	public function computeRestPose(?out:Array<Transform3D>):Array<Transform3D> {
		out = fit(out, bones.length, () -> new Transform3D());
		for (i => bone in bones)
			out[i].copyFrom(bone.rest);
		return out;
	}

	/** Returns each bone's place in the model for a pose: its transform after its parents'.

		@param pose  Each bone's transform relative to its parent.
		@param out  Optional. Set to the matrices, reused.
		@return  The matrices, by bone. */
	public function computeWorld(pose:Array<Transform3D>, ?out:Array<Matrix3D>):Array<Matrix3D> {
		out = fit(out, bones.length, () -> new Matrix3D());
		for (i => bone in bones) {
			pose[i].toMatrix(out[i]);
			if (bone.parentIndex >= 0)
				Matrix3D.compose(out[i], out[bone.parentIndex], out[i]);
		}
		return out;
	}

	// An out array of a length: the one given, grown or shrunk, its objects kept, or a new one.

	@:allow(helix.geometry)
	static function fit<T>(out:Null<Array<T>>, length:Int, make:() -> T):Array<T> {
		if (out == null)
			out = [];
		if (out.length > length)
			out.resize(length);
		while (out.length < length)
			out.push(make());
		return out;
	}
}
