package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;
import helix.graphics.IGraphics;

/** The joints of a draw's skinned models, one data texture for them all (as skinning.glsl reads it: 1024 texels a row, three a joint, each
	joint's matrix's top three rows): a model's joints from its base, each the model's own space moved by the joint as posed, its inverse bind
	matrix applied (inverse(model world) × joint world × inverse bind). Stage3D fills it once a pass and uploads it; also, a posed model's box. */
class JointPalette {
	static inline var ROW = 1024;

	var gpu:IGraphics;
	var texture = 0;
	var rows = 0;
	var data:Bytes;
	var count = 0;
	var inverse = new Mat4();
	var product = new Vector<Float>(16);

	/** A palette uploading to gpu. */
	public function new(gpu:IGraphics)
		this.gpu = gpu;

	/** The data texture (0 before the first upload). */
	public function getTexture():Int
		return texture;

	/** How many joints since the last clear. */
	public function getJointCount():Int
		return count;

	/** Empties it, for a pass. */
	public function clear():Void
		count = 0;

	/** Adds model's joints as posed now (its world matrix and its joints' up to date) and returns its base: the joint its first is. */
	public function add(model:Node):Int {
		var base = count, joints = model.getJointCount(), skin = model.getSkin();
		var needed = Std.int(Math.ceil((count + joints) * 3 / ROW)) * ROW * 16;
		if (data == null || data.length < needed) {
			var grown = Bytes.alloc(Std.int(Math.max(needed, data == null ? ROW * 16 : data.length * 2)));
			if (data != null)
				grown.blit(0, data, 0, count * 48);
			data = grown;
		}
		inverse.setInverse(model.getWorldMatrix());
		for (j in 0...joints) {
			var joint = model.getJoint(j).getWorldMatrix();
			// inverse × joint world × inverse bind, column-major; its top three rows.
			for (col in 0...4)
				for (row in 0...4) {
					var jw = 0.;
					for (k in 0...4)
						jw += joint.get(k * 4 + row) * skin.getInverseBind(j, col * 4 + k);
					product[col * 4 + row] = jw;
				}
			var at = (base + j) * 48;
			for (row in 0...3)
				for (col in 0...4) {
					var v = 0.;
					for (k in 0...4)
						v += inverse.get(k * 4 + row) * product[col * 4 + k];
					data.setFloat(at + row * 16 + col * 4, v);
				}
		}
		count += joints;
		return base;
	}

	/** Element row (0 to 2), col (0 to 3) of joint index's matrix as added (from a model's base): what the GPU skins with, for skinning on the
		CPU (a pick). */
	public inline function getMatrix(index:Int, row:Int, col:Int):Float
		return data.getFloat(index * 48 + row * 16 + col * 4);

	/** Uploads what was added, making the texture taller when it must. */
	public function upload():Void {
		if (count == 0)
			return;
		var needed = Std.int(Math.ceil(count * 3 / ROW));
		if (needed > rows) {
			if (texture != 0)
				gpu.destroyTexture(texture);
			rows = needed;
			texture = gpu.createDataTexture(ROW, rows);
		}
		if (data.length < rows * ROW * 16) {
			var grown = Bytes.alloc(rows * ROW * 16);
			grown.blit(0, data, 0, data.length);
			data = grown;
		}
		gpu.updateDataTexture(texture, data);
	}

	/** Destroys the texture. */
	public function destroy():Void {
		if (texture != 0)
			gpu.destroyTexture(texture);
		texture = rows = 0;
	}

	/** A skinned model's box as posed into out (center x, y, z, then its reach along each world axis): the joints it follows where they are,
		each padded by how far its vertices reach from it (Mesh.getJointReach, scaled as the joint scales them), padded again by 2% of the box's
		diagonal (at least 0.01). False when no joint weights a vertex (use its mesh's box). */
	public static function computePosedBox(model:Node, out:Vector<Float>):Bool {
		var skin = model.getSkin(),
			reach = model.getMesh().getJointReach(skin);
		var loX = Math.POSITIVE_INFINITY,
			loY = Math.POSITIVE_INFINITY,
			loZ = Math.POSITIVE_INFINITY;
		var hiX = Math.NEGATIVE_INFINITY,
			hiY = Math.NEGATIVE_INFINITY,
			hiZ = Math.NEGATIVE_INFINITY;
		for (j in 0...model.getJointCount()) {
			var r = reach[j];
			if (r < 0)
				continue;
			var w = model.getJoint(j).getWorldMatrix();
			// How much the joint (with its inverse bind) can stretch a distance: its 3x3's Frobenius norm, never less than the largest stretch.
			var norm = 0.;
			for (col in 0...3)
				for (row in 0...3) {
					var v = 0.;
					for (k in 0...3)
						v += w.get(k * 4 + row) * skin.getInverseBind(j, col * 4 + k);
					norm += v * v;
				}
			var d = r * Math.sqrt(norm), x = w.get(12), y = w.get(13), z = w.get(14);
			loX = Math.min(loX, x - d);
			loY = Math.min(loY, y - d);
			loZ = Math.min(loZ, z - d);
			hiX = Math.max(hiX, x + d);
			hiY = Math.max(hiY, y + d);
			hiZ = Math.max(hiZ, z + d);
		}
		if (loX > hiX)
			return false;
		var pad = Math.max(.01, .02 * Math.sqrt((hiX - loX) * (hiX - loX) + (hiY - loY) * (hiY - loY) + (hiZ - loZ) * (hiZ - loZ)));
		out[0] = (loX + hiX) / 2;
		out[1] = (loY + hiY) / 2;
		out[2] = (loZ + hiZ) / 2;
		out[3] = (hiX - loX) / 2 + pad;
		out[4] = (hiY - loY) / 2 + pad;
		out[5] = (hiZ - loZ) / 2 + pad;
		return true;
	}
}
