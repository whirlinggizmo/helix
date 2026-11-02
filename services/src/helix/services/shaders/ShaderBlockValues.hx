package helix.services.shaders;

import haxe.io.Bytes;
import helix.services.shaders.ShaderLayout.ShaderBlockLayout;
import helix.services.shaders.ShaderLayout.ShaderPlace;

/** Represents the values of one shared block (`ShaderOptions.shared`), read by every values that shares it (`IShaderValues.shareBlock`,
	`ShaderScene.shareBlock`).

	Per-frame data that many draws and shaders read alike (a camera, the lights) is a shared block: one the shaders declare alike in a
	file they include, or loose uniforms gathered by name (`ShaderSharedBlock.uniforms`). A renderer makes its own, and shares it on its
	scene (`ShaderScene`), so two renderers each have their own camera:

	```haxe
	var camera = ShaderBlockCompiler.compile("camera.glsl", "Camera");
	scene.shareBlock(camera);                     // every material drawn in the scene reads it
	// each frame, once:
	camera.writeMatrix(lit.getUniform("viewProjection"), viewProjection);
	// a shadow pass's scene holds the light's camera instead:
	shadowScene.shareBlock(lightCamera);
	```

	It starts with every member 0, and is written by the handles of any shader that shares it; a handle outside the block throws. A
	typed class for it is `ShaderValueClasses.buildBlock`'s.

	**A layout that changes.** When a shader sharing it is replaced in place with the block laid out anew, the block follows: it is laid
	out as the new shader has it, its values kept by name, and every values sharing it reads the new bytes. A sharer whose shader still
	has the old layout, until its own file is replaced, reads a copy packed from the block by name each time the block is written, so
	its values stay right. A layout two sharers' shaders declare differently once both are replaced, and so can't be one, is
	`layoutError`; the block keeps the newest. */
class ShaderBlockValues extends ShaderUniformValues {
	/** Gets the block's GLSL name. */
	public final blockName:String;

	/** Gets the block's bytes, at its declared size, as the newest layout lays it out: what each sharing values' `uniforms` holds at its
		slot. The platform never writes them: an adapter flipping a matrix for a render target flips its own copy (proposal 9). */
	public var bytes(default, null):Bytes;

	/** Gets why two sharers' shaders can't share the block now (their layouts differ after both were replaced), or null when they can. */
	public var layoutError(default, null):Null<String>;

	/** Creates the values of a shared block, every member 0.

		@param source  A shader, or a set of variants, that names the block shared; any shader naming it shared alike may share it.
		@param blockName  The block's name.
		@throws String  A source that names no shared block of that name (`ShaderOptions.shared`). */
	public function new(source:IShaderHandles, blockName:String) {
		super();
		this.blockName = blockName;
		var found = source.findSharedLayout(blockName);
		if (found == null)
			throw 'shader values: no shared block $blockName (ShaderOptions.shared) in the source given';
		layout = found;
		bytes = Bytes.alloc(layout.size);
	}

	// The layout the bytes follow, the newest a sharer's shader has; its places by path, and copies packed for other layouts.
	var layout:ShaderBlockLayout;
	final placesByKey = new Map<String, Map<String, ShaderPlace>>();
	final copies = new Map<String, {bytes:Bytes, version:Int}>();
	// Moves with each write, so copies know when to pack again.
	var version = 0;
	// The layout each sharer's shader had when it last read the block.
	final sharers = new haxe.ds.ObjectMap<Shader, String>();

	// A layout's places, by member path.
	function placesIn(l:ShaderBlockLayout):Map<String, ShaderPlace> {
		var found = placesByKey.get(l.key);
		if (found == null) {
			found = [for (m in l.members) m.glslName => new ShaderPlace(l, 0, m)];
			placesByKey.set(l.key, found);
		}
		return found;
	}

	override function typeOf(uniform:ShaderUniform):Null<ShaderValueType> {
		var p = placesIn(layout).get(uniform.name);
		if (p == null)
			throw 'shader values: ${uniform.name} isn\'t in shared block $blockName';
		return p.type;
	}

	override function elementCountOf(uniform:ShaderUniform):Int {
		var p = placesIn(layout).get(uniform.name);
		return p == null ? -1 : p.elementCount;
	}

	override function initial(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void {
		var p = placesIn(layout).get(uniform.name);
		if (p != null)
			p.unpack(bytes, elementIndex, values);
	}

	override function changed(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void {
		var p = placesIn(layout).get(uniform.name);
		if (p != null)
			p.pack(bytes, elementIndex, values);
		version++;
	}

	// The bytes a sharer laid out as l reads: the block's own, or a copy packed by name for an older layout.

	@:allow(helix.services.shaders)
	function bytesFor(l:ShaderBlockLayout):Bytes {
		if (l.key == layout.key)
			return bytes;
		var copy = copies.get(l.key);
		if (copy == null || copy.bytes.length != l.size) {
			copy = {bytes: Bytes.alloc(l.size), version: -1};
			copies.set(l.key, copy);
		}
		if (copy.version != version) {
			copy.bytes.fill(0, copy.bytes.length, 0);
			packInto(l, copy.bytes);
			copy.version = version;
		}
		return copy.bytes;
	}

	// Packs what was written, by name, into bytes laid out as l.
	function packInto(l:ShaderBlockLayout, into:Bytes):Void {
		var places = placesIn(l);
		for (uniform => w in written) {
			var p = places.get(uniform.name);
			if (p != null)
				for (index => e in w.elements)
					if (e != null && index < p.elementCount && e.length >= p.type.componentCount * p.type.columnCount)
						p.pack(into, index, e);
		}
	}

	// Notes a sharer's layout as it reads the block: a shader replaced with a new layout makes it the block's, the values kept by name; two
	// replaced sharers that differ are a layout error.

	@:allow(helix.services.shaders)
	function noteSharer(shader:Shader, l:ShaderBlockLayout):Void {
		var before = sharers.get(shader);
		if (before == l.key)
			return;
		sharers.set(shader, l.key);
		if (before != null && l.key != layout.key) {
			layout = l;
			bytes = Bytes.alloc(l.size);
			packInto(l, bytes);
			version++;
		}
		layoutError = null;
		for (other => key in sharers)
			if (key != layout.key && other.reloadCount > 0)
				layoutError = 'shared block $blockName is laid out differently by two of its sharers\' shaders, both replaced';
	}
}
