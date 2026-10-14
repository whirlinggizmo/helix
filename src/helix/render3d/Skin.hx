package helix.render3d;

import haxe.ds.Vector;

/** A skin: the joints a skinned mesh's vertices follow, by name, and each joint's inverse bind matrix (the mesh's space into the joint's, as it
	was bound). Shared by every model of a file showing it; a Model node binds its joints to nodes by these names (Node.bindSkeleton), so a
	mesh skinned in one file can follow a skeleton from another with the same joint names. Read, never changed. */
class Skin {
	var names:Array<String>;
	var inverseBind:Vector<Float>;

	/** A skin of joints named names, inverseBind their inverse bind matrices one after another (16 floats each, column-major; null for
		identities). Throws for matrices that don't match the names. */
	public function new(names:Array<String>, ?inverseBind:Array<Float>) {
		if (inverseBind != null && inverseBind.length != names.length * 16)
			throw "A skin's inverse bind matrices don't match its joints";
		this.names = names.copy();
		this.inverseBind = new Vector<Float>(names.length * 16);
		for (j in 0...names.length)
			for (i in 0...16)
				this.inverseBind[j * 16 + i] = inverseBind != null ? inverseBind[j * 16 + i] : i % 5 == 0 ? 1 : 0;
	}

	/** How many joints. */
	public function getJointCount():Int
		return names.length;

	/** Joint index's name. */
	public function getJointName(index:Int):String
		return names[index];

	/** Joint index's inverse bind matrix's element at (column-major) i. */
	public inline function getInverseBind(index:Int, i:Int):Float
		return inverseBind[index * 16 + i];
}
