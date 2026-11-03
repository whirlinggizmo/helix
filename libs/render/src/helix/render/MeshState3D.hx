package helix.render;

import helix.platform.Blend;
import helix.platform.ColorChannels;
import helix.platform.CullFace;
import helix.platform.DepthTest;

/** Represents state a mesh draw takes in place of its material's: its blend, depth test, depth write, cull and color channels, each
	null for the material's own.

	`Batch3D.drawMesh` and `drawModel` (and `DrawList3D`'s) take one, read as each draw is made, and change nothing in the material. A
	layer whose state is global keeps one and updates it as its state changes: helix-raylib keeps one mirroring rlgl's, passed to every
	mesh draw, while the materials stay as three.js expects them.

	```haxe
	var rlState = new MeshState3D();
	rlState.depthWrite = false; // rlDisableDepthMask
	batch.drawModel(model, transform, null, tint, rlState);
	``` */
class MeshState3D {
	/** Gets or sets how the draw is blended, or null for the material's `blend`: null until set. */
	public var blend:Null<Blend> = null;

	/** Gets or sets the draw's depth test, or null for the material's `depthTest`: null until set. */
	public var depthTest:Null<DepthTest> = null;

	/** Gets or sets whether the draw writes depth, or null for the material's `depthWrite`: null until set. */
	public var depthWrite:Null<Bool> = null;

	/** Gets or sets which faces the draw leaves out, or null for the material's `cull`: null until set. */
	public var cull:Null<CullFace> = null;

	/** Gets or sets the color channels the draw writes, or null for the material's `colorWrite`: null until set. */
	public var colorWrite:Null<ColorChannels> = null;

	/** Creates state that takes nothing from the material: every value null. */
	public function new() {}
}
