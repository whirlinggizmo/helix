package helix.render;

import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.services.images.Image;
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
		if (out == null)
			out = new Bounds3D();
		out.makeEmpty();
		var box = new Bounds3D();
		for (i in 0...meshes.length) {
			var skinning = skinningOf(i, boneMatrices);
			meshes[i].computeBounds(transform, skinning, null, box);
			if (!box.isEmpty)
				out.union(box, out);
		}
		return out;
	}

	/** Frees its meshes and textures, after the frame being recorded when it holds a draw of them. A second call does nothing.

		A texture of it a program gave another material is freed too. */
	public function dispose():Void {
		if (disposed)
			return;
		disposed = true;
		for (m in meshes)
			m.dispose();
		for (t in textures)
			if (t != null)
				t.dispose();
		if (renderer != null)
			renderer.forget(this);
	}

	@:allow(helix.render)
	var renderer:Null<Renderer> = null;

	@:allow(helix.render)
	var disposed = false;

	// The rest pose's bones in the model, worked out the first time a skinned mesh is drawn without bones; each skin's matrices, reused.
	var rest:Null<Array<Matrix3D>> = null;
	final skinnings:Array<Array<Matrix3D>> = [];

	// The skinning matrices of a mesh, posed by bones or at rest; null for a mesh without a skin.

	@:allow(helix.render)
	function skinningOf(meshIndex:Int, boneMatrices:Null<Array<Matrix3D>>):Null<Array<Matrix3D>> {
		var skinIndex = meshIndex < model.meshSkinIndices.length ? model.meshSkinIndices[meshIndex] : -1;
		var skeleton = model.skeleton;
		if (skinIndex < 0 || skeleton == null || !meshes[meshIndex].hasJoints)
			return null;
		var bones = boneMatrices;
		if (bones == null) {
			if (rest == null)
				rest = skeleton.computeWorld(skeleton.computeRestPose());
			bones = rest;
		}
		while (skinnings.length <= skinIndex)
			skinnings.push([]);
		return model.skins[skinIndex].computeSkinning(bones, skinnings[skinIndex]);
	}

	// A model uploaded: its textures, meshes and materials.

	@:allow(helix.render)
	static function make(renderer:Renderer, model:Model3D, upload:Image->Texture2D, mipmapFilter:helix.platform.MipmapFilter,
			colorSpace:ColorSpace):GpuModel3D {
		var textures:Array<Null<Texture2D>> = [
			for (image in model.images)
				if (image == null) null else {
					var t = upload(image);
					t.sampling = new helix.platform.Sampling(Linear, Repeat, Repeat, mipmapFilter);
					t;
				}
		];
		var meshes = [for (m in model.meshes) renderer.createMesh(m)];
		var obj = StringTools.endsWith(model.path.toLowerCase(), ".obj");
		var asStored = colorSpace == Srgb || colorSpace == Auto && obj;
		var materials = [];
		for (g in model.materials) {
			var m = new Material3D();
			m.shading = obj ? Phong : MetallicRoughness;
			m.colorSpace = colorSpace == Srgb ? Srgb : Linear;
			var f = g.baseColorFactor;
			m.baseColor = color(f[0], f[1], f[2], f.length > 3 ? f[3] : 1, asStored);
			m.metallic = g.metallic;
			m.roughness = g.roughness;
			var e = g.emissiveFactor;
			m.emissiveColor = color(e[0], e[1], e[2], 1, asStored);
			inline function slot(index:Int, space:ColorSpace):Null<Texture2D> {
				var t = index >= 0 && index < textures.length ? textures[index] : null;
				if (t != null)
					t.colorSpace = space;
				return t;
			}
			m.baseColorTexture = slot(g.baseColorImageIndex, Srgb);
			m.metallicRoughnessTexture = slot(g.metallicRoughnessImageIndex, Linear);
			m.normalTexture = slot(g.normalImageIndex, Linear);
			m.occlusionTexture = slot(g.occlusionImageIndex, Linear);
			m.emissiveTexture = slot(g.emissiveImageIndex, Srgb);
			materials.push(m);
		}
		var indices = [];
		var white = -1;
		for (i in 0...meshes.length) {
			var index = i < model.meshMaterialIndices.length ? model.meshMaterialIndices[i] : -1;
			if (index < 0 || index >= materials.length) {
				if (white < 0) {
					var m = new Material3D();
					m.colorSpace = colorSpace == Srgb ? Srgb : Linear;
					materials.push(m);
					white = materials.length - 1;
				}
				index = white;
			}
			indices.push(index);
		}
		var made = new GpuModel3D(model, meshes, materials, indices, textures);
		made.renderer = renderer;
		for (m in meshes)
			made.bounds.union(m.bounds, made.bounds);
		renderer.live.set(made, made.dispose);
		return made;
	}

	// A color from a file's factors: as stored, each times 255, or linear encoded to sRGB.
	static function color(r:Float, g:Float, b:Float, a:Float, asStored:Bool):Int {
		inline function channel(c:Float):Int {
			var v = Math.max(0, Math.min(1, c));
			if (!asStored)
				v = v <= .0031308 ? v * 12.92 : 1.055 * Math.pow(v, 1 / 2.4) - .055;
			return Math.round(v * 255);
		}
		return Math.round(Math.max(0, Math.min(1, a)) * 255) << 24 | channel(r) << 16 | channel(g) << 8 | channel(b);
	}
}
