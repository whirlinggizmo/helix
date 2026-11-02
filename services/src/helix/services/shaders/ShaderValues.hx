package helix.services.shaders;

import haxe.io.Bytes;
import helix.platform.Sampling;

/** Represents values for one shader's uniforms and textures, kept as `IGraphics.draw` takes them.

	Each uniform block is kept as its bytes at its declared size, by slot; each texture slot as a texture handle and its sampling. A
	draw hands the three arrays over as they are:

	```haxe
	graphics.draw(pipeline.handle, [vertices], indices, 0, 6, 0, 1, values.textures, values.samplings, values.uniforms);
	```

	`IGraphics.draw` reads them during the call, so a value changed between two draws gives each its own. Values are written by handle
	(`ShaderUniformValues`' `write` methods, `writeTexture`).

	**Layers.** A values made over a base reads, for each uniform and texture it hasn't written and each block and texture it hasn't
	shared, the base's as they are now. A block it hasn't written into is the base's own bytes, shared by reference, so nothing is
	copied. Its first write into one of the base's blocks gives it its own copy of that block (copy on write), which takes the base's
	later changes to the block's other uniforms at its next read, once a change, never per draw. A base may itself have a base.

	The layers a program makes: a scene's defaults; each material over them, its values written once; and a draw's own values over
	the material, its per-draw uniforms (a model's matrix, its bones) written each draw. A material-wide write then never reaches what
	a draw wrote, and a renderer keeps one draw values per shader, its `base` set to each draw's material, so nothing is allocated per
	draw:

	```haxe
	var defaults = new ShaderValues(lit);
	var red = new ShaderValues(lit, defaults);              // a material
	var drawn = new ShaderValues(lit);                      // the renderer's, for every draw through `lit`
	// a draw:
	drawn.base = red;
	drawn.scene = mainScene;
	drawn.writeMatrix(model, transform);
	graphics.draw(pipeline.handle, buffers, indices, 0, count, 0, 1, drawn.textures, drawn.samplings, drawn.uniforms);
	```

	Setting `base` copies nothing for the blocks the draw values haven't written into; the block holding their per-draw uniforms is
	filled again from the new base once (one copy of that block a draw). With no base, a uniform reads 0, a texture none.

	**When values are read.** `IGraphics.draw` reads the arrays during the call, so a value written after a draw doesn't reach it. A
	batcher recording draws to submit later captures each (`capture`, into a reused `ShaderSnapshot`).

	**Shared blocks and textures.** A block the shader names shared (`ShaderOptions.shared`) is read from a `ShaderBlockValues` shared on
	these values, their base, or their scene (`ShaderScene`), its bytes shared, never copied; a `ShaderSharedTexture` likewise for a
	sampler. Reading `uniforms` while a shared block is shared nowhere throws, naming the block, so a frame's data is never silently 0.
	Writing a shared block's uniform on these values throws too: it is written on the block.

	**After a replacement** of the shader (`Shader.reloadCount`), the values are packed again into the new layout from what was written
	on them, at the next write or read; what the new shader lacks is kept, and written again if a later replacement brings it back.

	For a material whose values serve every variant of a set, `ShaderVariantValues` makes and keeps one of these for each variant. */
class ShaderValues extends ShaderUniformValues implements IShaderValues {
	/** Gets the shader whose values these are. */
	public final shader:Shader;

	/** Gets or sets the values these read what they haven't written or shared from, or null: values of the same shader, as a material
		under a draw's own values. Setting it copies nothing for a block these haven't written into; a block they have written into is
		filled again, once, from the new base's for what they didn't write.
		@throws String  Values of another shader. */
	public var base(default, set):Null<ShaderValues>;

	/** Gets or sets the scene these read shared blocks and textures from when neither they nor their base share them, or null for
		their base's. Changing it copies nothing. */
	public var scene(get, set):Null<ShaderScene>;

	/** Gets each uniform block's bytes, by slot (by stage and slot, proposal 10), at its declared size, or null for a slot the shader
		lacks: `IGraphics.draw`'s `uniforms`. The array is kept and updated in place: reading it allocates nothing.
		A shared block's slot holds its `ShaderBlockValues.bytes`. Reading it throws while a block the shader names shared is shared
		nowhere. */
	public var uniforms(get, never):Array<Null<Bytes>>;

	/** Gets the texture handle bound at each texture slot, by slot, 0 for none: `IGraphics.draw`'s `textures`, kept and updated in place. */
	public var textures(get, never):Array<Int>;

	/** Gets how each texture slot is sampled, by slot: `IGraphics.draw`'s `samplings`, kept and updated in place. */
	public var samplings(get, never):Array<Sampling>;

	/** Creates values for a shader.

		@param shader  The shader.
		@param base  Optional. Values of the same shader to read what these don't write or share from: a material's, under a draw's own.
		@param scene  Optional. The scene to read shared blocks and textures from.
		@throws String  A base of another shader. */
	public function new(shader:Shader, ?base:ShaderValues, ?scene:ShaderScene) {
		super();
		this.shader = shader;
		this.base = base;
		ownScene = scene;
		layOut();
	}

	function set_base(value:Null<ShaderValues>):Null<ShaderValues> {
		if (value != null && value.shader != shader)
			throw 'shader values: a base of another shader';
		if (value == this)
			throw 'shader values: values can\'t be their own base';
		base = value;
		// Blocks written into are filled again from the new base, once, at the next read.
		for (i in 0...syncedWith.length)
			syncedWith[i] = null;
		return value;
	}

	function get_scene():Null<ShaderScene> {
		return ownScene != null ? ownScene : base != null ? base.scene : null;
	}

	function set_scene(value:Null<ShaderScene>):Null<ShaderScene> {
		ownScene = value;
		return value;
	}

	function get_uniforms():Array<Null<Bytes>> {
		follow();
		for (b in 0...shader.blocks.length) {
			var bytes = blockBytes(b);
			for (i in shader.blocks[b].indices)
				out[i] = bytes;
		}
		return out;
	}

	function get_textures():Array<Int> {
		follow();
		for (slot in 0...shader.textureCount) {
			var bound = textureAt(shader.slotSamplers[slot]);
			outTextures[slot] = bound == null ? 0 : bound.texture;
		}
		return outTextures;
	}

	function get_samplings():Array<Sampling> {
		follow();
		for (slot in 0...shader.textureCount) {
			var bound = textureAt(shader.slotSamplers[slot]);
			outSamplings[slot] = bound == null ? Sampling.LINEAR : bound.sampling;
		}
		return outSamplings;
	}

	/** Writes the texture a sampler reads, and how.

		@param sampler  The sampler.
		@param texture  The texture, as an `IGraphics` handle of the sampler's kind, or 0 for none.
		@param sampling  Optional. How it is sampled; defaults to `Sampling.LINEAR`. */
	public function writeTexture(sampler:ShaderSampler, texture:Int, ?sampling:Sampling):Void {
		follow();
		var t = ownTextures.get(sampler.name);
		if (t == null)
			ownTextures.set(sampler.name, t = new ShaderSharedTexture());
		t.texture = texture;
		t.sampling = sampling == null ? Sampling.LINEAR : sampling;
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

	/** Makes a sampler read a shared texture, until `unshareTexture`.

		@param sampler  The sampler.
		@param shared  The shared texture. */
	public function shareTexture(sampler:ShaderSampler, shared:ShaderSharedTexture):Void {
		sharedTextures.set(sampler.name, shared);
	}

	/** Stops a sampler reading a shared texture; it reads what was written, or its base's.

		@param sampler  The sampler. */
	public function unshareTexture(sampler:ShaderSampler):Void {
		sharedTextures.remove(sampler.name);
	}

	/** Makes the shader's block of a shared block's name read the shared block's bytes, replacing one of that name shared before.

		@param block  The shared block.
		@throws String  A shader that names no shared block of that name. */
	public function shareBlock(block:ShaderBlockValues):Void {
		var layout = shader.blockNamed(block.blockName);
		if (layout == null || !layout.shared)
			throw 'shader values: the shader names no shared block ${block.blockName} (ShaderOptions.shared)';
		block.noteSharer(shader, layout);
		sharedBlocks.set(block.blockName, block);
	}

	/** Stops sharing a block of a name: it reads its base's, or nothing.

		@param blockName  The block's name. */
	public function unshareBlock(blockName:String):Void {
		sharedBlocks.remove(blockName);
	}

	/** Returns the shared block a block of a name reads now: its own, or its base's.

		@param blockName  The block's name.
		@return  The shared block, or null. */
	public function findSharedBlock(blockName:String):Null<ShaderBlockValues> {
		var own = sharedBlocks.get(blockName);
		return own != null ? own : base != null ? base.findSharedBlock(blockName) : null;
	}

	/** Copies the values as a draw would read them now into a snapshot, for a draw recorded and submitted later.

		@param snapshot  The snapshot, its bytes and arrays reused. */
	public function capture(snapshot:ShaderSnapshot):Void {
		var uniforms = get_uniforms(),
			textures = get_textures(),
			samplings = get_samplings();
		snapshot.uniforms.resize(uniforms.length);
		for (i => bytes in uniforms) {
			if (bytes == null) {
				snapshot.uniforms[i] = null;
				continue;
			}
			// A block both stages read is one copy at both indices.
			var first = uniforms.indexOf(bytes);
			if (first < i) {
				snapshot.uniforms[i] = snapshot.uniforms[first];
				continue;
			}
			var kept = snapshot.uniforms[i];
			if (kept == null || kept.length != bytes.length || Lambda.exists(snapshot.uniforms.slice(0, i), k -> k == kept))
				kept = snapshot.uniforms[i] = Bytes.alloc(bytes.length);
			kept.blit(0, bytes, 0, bytes.length);
		}
		snapshot.textures.resize(textures.length);
		snapshot.samplings.resize(samplings.length);
		for (i in 0...textures.length) {
			snapshot.textures[i] = textures[i];
			snapshot.samplings[i] = samplings[i];
		}
	}

	/** Removes a uniform's written value, so it reads its base's again (or 0).

		@param uniform  The uniform. */
	public function deleteValue(uniform:ShaderUniform):Void {
		written.remove(uniform);
		for (i in 0...syncedWith.length)
			syncedWith[i] = null;
		// A block with nothing written in it any more reads its base's again.
		for (b in 0...own.length)
			if (own[b] != null && !writesInto(b))
				own[b] = null;
	}

	/** Removes every written value, texture and share, so everything reads its base's again (or nothing). */
	public function deleteValues():Void {
		written.clear();
		for (b in 0...own.length)
			own[b] = null;
		ownTextures.clear();
		sharedTextures.clear();
		sharedBlocks.clear();
	}

	// The scene given these values, or null for their base's.
	var ownScene:Null<ShaderScene>;
	// The shader's layout these were packed for: its reloadCount.
	var packedAt = -1;
	// Each block's own bytes once written into (copy on write), else null; its version, which moves with each change; and the base and
	// base version it was last filled from.
	var own:Array<Null<Bytes>> = [];
	var versions:Array<Int> = [];
	var syncedWith:Array<Null<ShaderValues>> = [];
	var syncedVersions:Array<Int> = [];
	// Each block's zeros, for values with no base and nothing written there.
	var zeros:Array<Bytes> = [];
	// Textures written, shared textures and shared blocks, by name.
	final ownTextures = new Map<String, ShaderSharedTexture>();
	final sharedTextures = new Map<String, ShaderSharedTexture>();
	final sharedBlocks = new Map<String, ShaderBlockValues>();
	// What a draw takes, kept and updated in place.
	final out:Array<Null<Bytes>> = [];
	final outTextures:Array<Int> = [];
	final outSamplings:Array<Sampling> = [];

	// The arrays and blocks as the shader lays them out now.
	function layOut():Void {
		packedAt = shader.reloadCount;
		var count = shader.blocks.length;
		own = [for (_ in 0...count) null];
		versions = [for (_ in 0...count) 0];
		syncedWith = [for (_ in 0...count) null];
		syncedVersions = [for (_ in 0...count) -1];
		zeros = [for (b in shader.blocks) Bytes.alloc(b.size)];
		out.resize(0);
		for (_ in 0...shader.uniformCount)
			out.push(null);
		outTextures.resize(0);
		outSamplings.resize(0);
		for (_ in 0...shader.textureCount) {
			outTextures.push(0);
			outSamplings.push(Sampling.LINEAR);
		}
	}

	// After a replacement of the shader: laid out anew and packed again from what was written, at the next read or write.
	function follow():Void {
		if (packedAt == shader.reloadCount)
			return;
		layOut();
		for (uniform => w in written)
			for (index => e in w.elements)
				if (e != null && shader.placesOf(uniform) != null)
					changed(uniform, index, e);
	}

	override function typeOf(uniform:ShaderUniform):Null<ShaderValueType> {
		follow();
		var places = shader.placesOf(uniform);
		return places == null ? null : places[0].type;
	}

	override function elementCountOf(uniform:ShaderUniform):Int {
		var places = shader.placesOf(uniform);
		return places == null ? -1 : places[0].elementCount;
	}

	override function initial(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void {
		var places = shader.placesOf(uniform);
		if (places != null && !places[0].block.shared)
			places[0].unpack(blockBytes(places[0].blockIndex), elementIndex, values);
	}

	override function changed(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void {
		follow();
		var places = shader.placesOf(uniform);
		if (places == null)
			return;
		for (p in places) {
			if (p.block.shared)
				throw 'shader values: ${uniform.name} is in shared block ${p.block.name}; it is written on the block (ShaderBlockValues)';
			var b = p.blockIndex;
			if (own[b] == null) {
				var from = baseBytes(b);
				own[b] = Bytes.alloc(from.length);
				own[b].blit(0, from, 0, from.length);
				syncedWith[b] = base;
				syncedVersions[b] = base == null ? 0 : base.versionOf(b);
			}
			p.pack(own[b], elementIndex, values);
			versions[b]++;
		}
	}

	// Whether anything written lies in a block.
	function writesInto(b:Int):Bool {
		for (uniform => _ in written) {
			var places = shader.placesOf(uniform);
			if (places != null)
				for (p in places)
					if (p.blockIndex == b)
						return true;
		}
		return false;
	}

	// The bytes a block reads under these values' own: the base's, or zeros.
	function baseBytes(b:Int):Bytes
		return base != null ? base.blockBytes(b) : zeros[b];

	// A block's version as these read it: their own, or the base's for a block they read by reference.

	@:allow(helix.services.shaders)
	function versionOf(b:Int):Int {
		follow();
		if (own[b] != null) {
			refill(b);
			return versions[b];
		}
		return base != null ? base.versionOf(b) : 0;
	}

	// A block written into, filled again from its base when the base has changed since: the base's bytes, then what these wrote there.
	function refill(b:Int):Void {
		var current = base == null ? 0 : base.versionOf(b);
		if (syncedWith[b] == base && syncedVersions[b] == current)
			return;
		var from = baseBytes(b);
		own[b].blit(0, from, 0, from.length);
		syncedWith[b] = base;
		syncedVersions[b] = current;
		for (uniform => w in written) {
			var places = shader.placesOf(uniform);
			if (places != null)
				for (p in places)
					if (p.blockIndex == b)
						for (index => e in w.elements)
							if (e != null)
								p.pack(own[b], index, e);
		}
		versions[b]++;
	}

	// The bytes a draw reads for a block: a shared block's, these values' own, or the base's by reference.

	@:allow(helix.services.shaders)
	function blockBytes(b:Int):Bytes {
		var layout = shader.blocks[b];
		if (layout.shared) {
			var block = sharedBlockFor(layout.name);
			if (block == null)
				throw 'shader values: shared block ${layout.name} is shared nowhere (on the values, their base or their scene), so a draw would read 0';
			block.noteSharer(shader, layout);
			return block.bytesFor(layout);
		}
		if (own[b] != null) {
			refill(b);
			return own[b];
		}
		return baseBytes(b);
	}

	// The shared block a block of a name reads: these values', their base's, then their scene's.
	function sharedBlockFor(name:String):Null<ShaderBlockValues> {
		var found = findSharedBlock(name);
		if (found != null)
			return found;
		var s = scene;
		return s == null ? null : s.findSharedBlock(name);
	}

	// The texture a sampler of a name reads: shared, written, the base's, then the scene's.
	function textureAt(name:String):Null<ShaderSharedTexture> {
		if (name == "")
			return null;
		var found = ownTextureAt(name);
		if (found != null)
			return found;
		var s = scene;
		return s == null ? null : s.findSharedTexture(name);
	}

	function ownTextureAt(name:String):Null<ShaderSharedTexture> {
		var t = sharedTextures.get(name);
		if (t != null)
			return t;
		t = ownTextures.get(name);
		if (t != null)
			return t;
		return base != null ? base.ownTextureAt(name) : null;
	}
}
