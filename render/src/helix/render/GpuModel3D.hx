package helix.render;

import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.services.models.Model3D;

/** Represents a model on the GPU: its meshes uploaded, its images made textures, its materials made `Material3D`s over them.

	`Renderer.createModel` makes one from helix-services' `Model3D`; `Batch3D.drawModel` draws it, skinned when given its bones. It owns its
	meshes and textures, and `dispose` frees them; its materials may be changed, and a mesh's material swapped through
	`meshMaterialIndices` or `materials`. Its skeleton, skins and animations are the model's (`model.skeleton`). */
class GpuModel3D {
	/** Gets the model it was made from. */
	public final model:Model3D;

	/** Gets the meshes, beside the model's `meshes`. */
	public final meshes:Array<GpuMesh3D>;

	/** Gets the materials, beside the model's `materials`, and one more, white, when a mesh has none in the file. */
	public final materials:Array<Material3D>;

	/** Gets the index of each mesh's material in `materials`, beside it in `meshes`. */
	public final meshMaterialIndices:Array<Int>;

	/** Gets the textures, beside the model's `images`; null for an image that is null. */
	public final textures:Array<Null<Texture2D>>;

	/** Gets the box around its meshes at rest, in the model's units. */
	public final bounds = new Bounds3D();

	@:allow(helix.render)
	function new(model:Model3D, meshes:Array<GpuMesh3D>, materials:Array<Material3D>, meshMaterialIndices:Array<Int>, textures:Array<Null<Texture2D>>) {
		this.model = model;
		this.meshes = meshes;
		this.materials = materials;
		this.meshMaterialIndices = meshMaterialIndices;
		this.textures = textures;
	}

	/** Returns the box around the model as drawn: each mesh's vertices, a skinned one's posed on the CPU by its skeleton's bones, placed
		by a transform.

		It is exact, for framing a camera and picking, and goes through every vertex.
		@param transform  The model's place in the world.
		@param boneMatrices  Optional. Each bone's place in the model, as `Batch3D.drawModel` takes them; the rest pose when omitted.
		@param out  Optional. Set to the box; a new one when omitted.
		@return  The box, in world units, or the box made empty for a model with no vertices. */
	public function computeBounds(transform:Matrix3D, ?boneMatrices:Array<Matrix3D>, ?out:Bounds3D):Bounds3D {
		throw "helix-render: GpuModel3D.computeBounds is not yet built (stage 1)";
	}

	/** Frees its meshes and textures, after the frame being recorded when it holds a draw of them. A second call does nothing.

		A texture of it a program gave another material is freed too. */
	public function dispose():Void {
		throw "helix-render: GpuModel3D.dispose is not yet built (stage 1)";
	}
}
