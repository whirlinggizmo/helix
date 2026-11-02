package helix.services.shaders;

import helix.platform.Sampling;

/** Represents values for every variant of a set at once, as a material's: written once, and packed for each variant a draw uses.

	`getValues` makes the values for a variant the first time a draw asks, from everything written so far, over the variant's values of
	the base when there is one (its unwritten blocks the base's by reference, as `ShaderValues` has them), and keeps them; each value written after is written to every variant's values made, each handle
	resolved once per variant. A handle the variant doesn't declare (a skinned variant's `boneMatrices` on a plain one) is kept and
	skipped. Nothing is copied by name when a draw switches between variants. A typed class (`ShaderValueClasses.buildVariants`)
	returns its own typed values for each variant, so a draw's own uniforms keep their types.

	A draw's own uniforms (the model's matrix, its bones) go on a draw values over the variant's values (`ShaderValues.base`), never on
	the material's: a material-wide write then can't reach them.

	```haxe
	var defaults = new ShaderVariantValues(lit);
	var red = new ShaderVariantValues(lit, defaults);
	red.writeColor(lit.getUniform("baseColor"), 0xffd04040);
	drawn.base = red.getValues(skinned);         // the renderer's draw values for the skinned variant
	drawn.writeMatrix(model, transform);
	``` */
class ShaderVariantValues extends ShaderUniformValues implements IShaderValues {
	/** Gets the variants these are values for. */
	public final variants:ShaderVariants;

	/** Gets the values these read what they haven't written or shared from, variant by variant, or null. */
	public final base:Null<ShaderVariantValues>;

	/** Gets or sets the scene every variant's values read shared blocks and textures from when neither they nor their base share
		them, or null for their base's. Changing it copies nothing. */
	public var scene(get, set):Null<ShaderScene>;

	/** Creates values for every variant of a set.

		@param variants  The set.
		@param base  Optional. Values of the same set to read what these don't write or share from, as a scene's defaults.
		@throws String  A base of another set. */
	public function new(variants:ShaderVariants, ?base:ShaderVariantValues) {
		super();
		if (base != null && base.variants != variants)
			throw 'shader values: a base of another set of variants';
		this.variants = variants;
		this.base = base;
		made = [for (_ in variants.shaders) null];
	}

	function get_scene():Null<ShaderScene> {
		return ownScene != null ? ownScene : base != null ? base.scene : null;
	}

	function set_scene(value:Null<ShaderScene>):Null<ShaderScene> {
		ownScene = value;
		for (v in made)
			if (v != null)
				v.scene = value;
		return value;
	}

	/** Returns the values for the variant with a combination of features, made the first time and kept in step after.

		@param features  The combination.
		@return  Its values, the same each call; a typed class's own typed values.
		@throws String  A combination not compiled. */
	public function getValues(features:ShaderFeatures):ShaderValues {
		var shader = variants.findShader(features);
		if (shader == null)
			throw 'shader values: no variant [${variants.computeFeatureNames(features).join(", ")}] was compiled';
		return getShaderValues(shader);
	}

	/** Returns the values for one variant, made the first time and kept in step after.

		@param shader  A variant of the set (`ShaderVariants.getShader`).
		@return  Its values, the same each call.
		@throws String  A shader that isn't one of the set's. */
	public function getShaderValues(shader:Shader):ShaderValues {
		var i = variants.shaders.indexOf(shader);
		if (i < 0)
			throw 'shader values: a shader that isn\'t one of the set\'s variants';
		var v = made[i];
		if (v == null) {
			v = made[i] = makeValues(shader, base == null ? null : base.getShaderValues(shader));
			if (ownScene != null)
				v.scene = ownScene;
			v.copyWritten(this);
			for (name => t in textureWrites)
				for (s in shader.samplers)
					if (s.name == name)
						v.writeTexture(s, t.texture, t.sampling);
			for (name => t in textureShares)
				for (s in shader.samplers)
					if (s.name == name)
						v.shareTexture(s, t);
			for (block in blockShares)
				if (shader.hasSharedBlock(block.blockName))
					v.shareBlock(block);
		}
		return v;
	}

	/** Makes the values for one variant, the first time `getValues` asks: a typed class overrides it with its own typed values.

		@param shader  The variant.
		@param base  The variant's values of the base, or null.
		@return  The values. */
	function makeValues(shader:Shader, base:Null<ShaderValues>):ShaderValues {
		return new ShaderValues(shader, base);
	}

	/** Writes the texture a sampler reads, and how, in every variant that samples it.

		@param sampler  The sampler.
		@param texture  The texture, as an `IGraphics` handle, or 0 for none.
		@param sampling  Optional. How it is sampled; defaults to `Sampling.LINEAR`. */
	public function writeTexture(sampler:ShaderSampler, texture:Int, ?sampling:Sampling):Void {
		textureWrites.set(sampler.name, new ShaderSharedTexture(texture, sampling));
		for (k => v in made)
			if (v != null && variants.shaders[k].hasSampler(sampler.name))
				v.writeTexture(sampler, texture, sampling);
	}

	/** Writes a sampler from a value held as data (`ShaderValue.Texture`).

		@param sampler  The sampler.
		@param value  A `ShaderValue.Texture`.
		@throws String  A value of another case. */
	public function writeSamplerValue(sampler:ShaderSampler, value:ShaderValue):Void {
		switch value {
			case Texture(texture, sampling):
				writeTexture(sampler, texture, sampling);
			case _:
				throw 'shader values: ${sampler.name} is a sampler; it takes a ShaderValue.Texture';
		}
	}

	/** Makes a sampler read a shared texture in every variant that samples it.

		@param sampler  The sampler.
		@param shared  The shared texture. */
	public function shareTexture(sampler:ShaderSampler, shared:ShaderSharedTexture):Void {
		textureShares.set(sampler.name, shared);
		for (k => v in made)
			if (v != null && variants.shaders[k].hasSampler(sampler.name))
				v.shareTexture(sampler, shared);
	}

	/** Stops a sampler reading a shared texture in every variant.

		@param sampler  The sampler. */
	public function unshareTexture(sampler:ShaderSampler):Void {
		textureShares.remove(sampler.name);
		for (v in made)
			if (v != null)
				v.unshareTexture(sampler);
	}

	/** Shares a block on every variant's values, made and to be made, replacing one of that name shared before.

		@param block  The shared block.
		@throws String  A set none of whose variants names the block shared. */
	public function shareBlock(block:ShaderBlockValues):Void {
		if (!variants.hasSharedBlock(block.blockName))
			throw 'shader values: no variant names a shared block ${block.blockName} (ShaderOptions.shared)';
		blockShares.set(block.blockName, block);
		for (k => v in made)
			if (v != null && variants.shaders[k].hasSharedBlock(block.blockName))
				v.shareBlock(block);
	}

	/** Stops sharing a block of a name on every variant's values.

		@param blockName  The block's name. */
	public function unshareBlock(blockName:String):Void {
		blockShares.remove(blockName);
		for (v in made)
			if (v != null)
				v.unshareBlock(blockName);
	}

	/** Returns the shared block a block of a name reads now: its own, or its base's.

		@param blockName  The block's name.
		@return  The shared block, or null. */
	public function findSharedBlock(blockName:String):Null<ShaderBlockValues> {
		var own = blockShares.get(blockName);
		return own != null ? own : base != null ? base.findSharedBlock(blockName) : null;
	}

	/** Removes every written value, texture and share, in every variant, so everything reads its base's again. */
	public function deleteValues():Void {
		written.clear();
		textureWrites.clear();
		textureShares.clear();
		blockShares.clear();
		for (v in made)
			if (v != null)
				v.deleteValues();
	}

	var ownScene:Null<ShaderScene>;
	// Each variant's values, by its index in the set, made the first time a draw asks.
	final made:Array<Null<ShaderValues>>;
	final textureWrites = new Map<String, ShaderSharedTexture>();
	final textureShares = new Map<String, ShaderSharedTexture>();
	final blockShares = new Map<String, ShaderBlockValues>();

	// A write reaches every variant's values made, each resolving the handle by name; one without it keeps it.
	override function changed(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void
		for (v in made)
			if (v != null)
				v.writeElement(uniform, elementIndex, values);
}
