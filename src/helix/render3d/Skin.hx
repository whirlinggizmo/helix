package helix.render3d;

import haxe.ds.Vector;

/** A skin: the joints a skinned mesh's vertices follow, by name, and each joint's inverse bind matrix (the mesh's space into the joint's, as it
	was bound). Shared by every model of a file showing it; a Model binds its joints to nodes by these names (Model.bindSkeleton), so a
	mesh skinned in one file can follow a skeleton from another with the same joint names. Read, never changed. */
class Skin {
	var names:Array<String>;
	var inverseBind:Vector<Float>;
	var bind:Vector<Float>;

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
		// Each joint's place in the mesh's space as bound: its inverse bind matrix's inverse's translation, -R⁻¹t of that affine matrix.
		bind = new Vector<Float>(names.length * 3);
		for (j in 0...names.length) {
			var m = j * 16, b = this.inverseBind;
			var a00 = b[m], a10 = b[m + 1], a20 = b[m + 2], a01 = b[m + 4], a11 = b[m + 5], a21 = b[m + 6], a02 = b[m + 8], a12 = b[m + 9], a22 = b[m + 10];
			var c00 = a11 * a22 - a12 * a21,
				c01 = a02 * a21 - a01 * a22,
				c02 = a01 * a12 - a02 * a11;
			var c10 = a12 * a20 - a10 * a22,
				c11 = a00 * a22 - a02 * a20,
				c12 = a02 * a10 - a00 * a12;
			var c20 = a10 * a21 - a11 * a20,
				c21 = a01 * a20 - a00 * a21,
				c22 = a00 * a11 - a01 * a10;
			var det = a00 * c00 + a01 * c10 + a02 * c20;
			var tx = b[m + 12], ty = b[m + 13], tz = b[m + 14];
			if (det != 0) {
				bind[j * 3] = -(c00 * tx + c01 * ty + c02 * tz) / det;
				bind[j * 3 + 1] = -(c10 * tx + c11 * ty + c12 * tz) / det;
				bind[j * 3 + 2] = -(c20 * tx + c21 * ty + c22 * tz) / det;
			}
		}
	}

	/** How many joints. */
	public var jointCount(get, never):Int;

	function get_jointCount():Int
		return names.length;

	/** Joint index's name. */
	public function getJointName(index:Int):String
		return names[index];

	/** Joint index's place in its mesh's space as bound, axis 0 (x), 1 (y) or 2 (z). */
	public inline function getBindPosition(index:Int, axis:Int):Float
		return bind[index * 3 + axis];

	/** Joint index's inverse bind matrix's element at (column-major) i. */
	public inline function getInverseBind(index:Int, i:Int):Float
		return inverseBind[index * 16 + i];
}
