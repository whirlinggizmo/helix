package helix.render;

import helix.geometry.Mesh3D;
import helix.math.Bounds3D;
import helix.math.Matrix3D;

/** Represents a mesh on the GPU: its vertices and indices, uploaded once and drawn as often as wanted (`Batch3D.drawMesh`).

	`Renderer.createMesh` makes one from helix-geometry's `Mesh3D`, and `Renderer.createModel` one for each of a model's meshes. The
	program frees it with `dispose`. It keeps its positions on the CPU, and a skinned mesh its joints and weights, for `computeBounds`;
	for a skinned mesh it also records each joint's box of the vertices it moves, which `Batch3D` culls by. */
class GpuMesh3D {
	/** Gets the number of vertices. */
	public var vertexCount(default, null):Int;

	/** Gets the number of triangles. */
	public var triangleCount(default, null):Int;

	/** Gets the box around its positions as uploaded, in the mesh's own units (a skinned mesh's in its bind pose). */
	public final bounds = new Bounds3D();

	/** Gets a value indicating whether it has joints and weights, so it is drawn skinned when given a skin's matrices. */
	public var hasJoints(default, null):Bool;

	/** Gets the number of its morph targets: 0 for none. */
	public var morphTargetCount(default, null):Int;

	@:allow(helix.render)
	function new() {}

	/** Replaces its vertices and indices with a mesh's, for the draws after it.

		Draws already recorded this frame draw what it held before. A mesh made `updatedOften` (`Renderer.createMesh`) is replaced in place; another
		is uploaded again.
		@param mesh  The mesh. It may have other arrays and another vertex count than before.
		@throws String  A mesh without positions, or a disposed one. */
	public function update(mesh:Mesh3D):Void {
		throw "helix-render: GpuMesh3D.update is not yet built (stage 1)";
	}

	/** Returns the box around the mesh as drawn: its vertices posed by a skin's matrices when given, on the CPU, then placed by a transform.

		It is exact where the box culling uses may be larger, so it suits framing a camera and picking. It goes through every vertex, so it
		is for now and then, not every mesh every frame.
		@param transform  The mesh's place in the world.
		@param skinning  Optional. Its skin's matrices, as `Batch3D.drawMesh` takes them; the mesh as uploaded when omitted.
		@param morphWeights  Optional. Its morph targets' weights, as `Batch3D.drawMesh` takes them; none when omitted.
		@param out  Optional. Set to the box; a new one when omitted.
		@return  The box, in world units.
		@throws String  A disposed mesh. */
	public function computeBounds(transform:Matrix3D, ?skinning:Array<Matrix3D>, ?morphWeights:Array<Float>, ?out:Bounds3D):Bounds3D {
		throw "helix-render: GpuMesh3D.computeBounds is not yet built (stage 1)";
	}

	/** Frees its buffers on the GPU, after the frame being recorded when it holds a draw of it. A second call does nothing. */
	public function dispose():Void {
		throw "helix-render: GpuMesh3D.dispose is not yet built (stage 1)";
	}
}
