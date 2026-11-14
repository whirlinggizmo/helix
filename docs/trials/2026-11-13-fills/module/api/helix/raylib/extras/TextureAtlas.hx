package helix.raylib.extras;

/** Holds an atlas loaded by `Textures.LoadTextureAtlas`: its texture and each image's rectangle in it, by name. */
class TextureAtlas {
	/** Gets the atlas's texture. */
	public var texture(default, null):Texture2D;

	/** Gets the names of the atlas's images, in the file's order. */
	public var names(default, null):Array<String>;

	function new() {}
}
