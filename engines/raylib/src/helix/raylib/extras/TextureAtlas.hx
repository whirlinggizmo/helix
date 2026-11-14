package helix.raylib.extras;

import helix.raylib.*;

/** Holds an atlas loaded by `Textures.LoadTextureAtlasAsync`: its texture and each image's rectangle in it, by name. */
@:allow(helix.raylib.modules.RTextureAtlases)
class TextureAtlas {
	/** Gets the atlas's texture. */
	public var texture(default, null):Texture2D;

	/** Gets the names of the atlas's images, in the file's order. */
	public var names(default, null):Array<String> = [];

	// Each image's x, y, width and height, in the order of names.
	var rectangles:Array<Float> = [];
	// Each name's index in names, the first image of a name repeated.
	var index:Map<String, Int> = [];
	// The texture's file, as the atlas's file names it.
	var sheet:String = "";

	function new() {}

	function add(name:String, x:Float, y:Float, width:Float, height:Float):Void {
		if (!index.exists(name))
			index.set(name, names.length);
		names.push(name);
		rectangles.push(x);
		rectangles.push(y);
		rectangles.push(width);
		rectangles.push(height);
	}

	function indexOf(name:String):Int {
		var at = index.get(name);
		return at == null ? -1 : at;
	}
}
