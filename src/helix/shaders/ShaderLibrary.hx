package helix.shaders;

import helix.graphics.IGraphics;
import helix.graphics.Shader;

/** The shader library's programs on each GPU. A library shader's source (src/helix/shaders/*.glsl) is packed at build time into generated
	Haxe holding its .hxshader (tools/pack_shader.py: <Name>Packed.text()), so a class in helix.shaders gets its shader at once, with no load
	and no asset, and a shader nothing uses is left out of the build. Each is built the first time it's asked for on a GPU and kept, shared
	by everything drawing with it, until the runner releases the GPU's. In development a hot reload brings the shaders packed again from
	changed sources, and each built is built again in place, as Shaders does an app's. */
class ShaderLibrary {
	// Kept across a hot reload, so the reload's rebuild finds every GPU's shaders.
	@:hot static var all = new haxe.ds.ObjectMap<IGraphics, Map<String, {shader:Shader, text:String}>>();

	/** The library shader name (its source's file stem: "unlit") on gpu, built from text (its packed .hxshader, <Name>Packed.text()) the first
		time it's asked for there. Throws, saying why, for a program that doesn't build. */
	public static function get(gpu:IGraphics, name:String, text:String):Shader {
		var shaders = all.get(gpu);
		if (shaders == null)
			all.set(gpu, shaders = new Map());
		var entry = shaders[name];
		if (entry == null)
			shaders[name] = entry = {shader: Shader.fromText(gpu, text), text: text};
		return entry.shader;
	}

	/** Frees gpu's library shaders and the pipelines made over them, before the adapter shuts down. */
	public static function release(gpu:IGraphics):Void {
		var shaders = all.get(gpu);
		if (shaders == null)
			return;
		for (entry in shaders)
			entry.shader.destroy();
		all.remove(gpu);
	}

	#if hotreload
	// Development only (hotreload-hx): a reload brings the library packed again; a shader whose text changed is built again in place (its
	// pipelines made again as they're next asked for), and one that no longer builds stays as it was, its log traced.
	@:afterHotReload static function reloadShaders():Void {
		var texts = PackedShaders.texts();
		for (shaders in all)
			for (name => entry in shaders) {
				var packed = texts[name];
				if (packed == null)
					continue;
				var text = packed();
				if (text == entry.text)
					continue;
				try {
					@:privateAccess entry.shader.replace(text);
					entry.text = text;
				} catch (e:Dynamic)
					trace('helix.shaders $name: $e');
			}
	}
	#end
}
