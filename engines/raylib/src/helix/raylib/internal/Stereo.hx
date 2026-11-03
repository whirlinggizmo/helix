package helix.raylib.internal;

import helix.math.Matrix3D;

/** Holds rlgl's stereo rendering: each eye's projection and view offset, and the frame's `eyes` while it is on, drawing what is added
	once for each eye in its half of what is drawn into, as rlgl 5.5's `rlDrawRenderBatch` and raylib's `DrawMesh` do. A program naming
	none of rlgl's stereo calls links none of it. */
@:noCompletion
class Stereo {
	/** Each eye's projection, rlgl's `projectionStereo`: zero until `rlSetMatrixProjectionStereo` sets them. */
	public static final projections = [zero(), zero()];

	/** Each eye's view offset, rlgl's `viewOffsetStereo`: zero until `rlSetMatrixViewOffsetStereo` sets them. */
	public static final offsets = [zero(), zero()];

	/** Whether stereo rendering is on, rlgl's `stereoRender`. */
	public static var enabled(default, null) = false;

	/** Turns stereo rendering on or off, for the batch flushed and the meshes drawn after: the batch waiting is drawn as it is when it is
		flushed, as rlgl's is.

		@param on  Whether it is on. */
	public static function enable(on:Bool):Void {
		enabled = on;
		if (Runtime.frame != null)
			Runtime.frame.eyes = on ? draw : null;
	}

	static function zero():Matrix3D {
		var m = new Matrix3D();
		for (i in 0...16)
			m.values[i] = 0;
		return m;
	}

	// What is added, once for each eye: in its half of what is drawn into (the left the first eye's), the batch through the view moved by
	// the eye's offset and the eye's projection, after which the matrices are as they were and the viewport the whole again, as rlgl's
	// batch leaves them; a mesh's mvp alone moved, its viewport left the second eye's, as raylib's DrawMesh leaves it.
	static function draw(add:() -> Void, mesh:Bool):Void {
		var f = Runtime.frame;
		var width = helix.raylib.modules.RRlgl.rlGetFramebufferWidth(),
			height = helix.raylib.modules.RRlgl.rlGetFramebufferHeight();
		var view = f.view, projection = f.projection;
		for (eye in 0...2) {
			f.viewport = [Std.int(eye * width / 2), 0, Std.int(width / 2), height];
			var moved = Matrix3D.compose(view, offsets[eye]);
			if (mesh) {
				f.meshView = moved;
				f.meshProjection = projections[eye];
			} else {
				f.view = moved;
				f.projection = projections[eye];
			}
			add();
		}
		if (mesh) {
			f.meshView = null;
			f.meshProjection = null;
		} else {
			f.view = view;
			f.projection = projection;
			f.viewport = null;
		}
	}
}
