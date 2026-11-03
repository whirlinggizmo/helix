package helix.formats.gltf;

import haxe.io.Bytes;

/** Represents one image of a glTF model: its encoded file's bytes when the model holds them, or the path of its own file.

	An image held in the model (a buffer view, a base64 `data:` URI) has `encoded` and no `path`; one in a file of its own has `path`,
	URI-decoded and resolved against the model's directory, and no `encoded`. Nothing is decoded: `encoded` is the PNG or JPEG file. */
class GltfImage {
	/** Gets the image's encoded file, or null when it is in a file of its own (`path`). */
	public final encoded:Null<Bytes>;

	/** Gets the path of the image's own file, resolved against the model's directory, or null when the model holds it (`encoded`). */
	public final path:Null<String>;

	/** Gets the image's media type as the file gives it (`image/png`, `image/jpeg`), or null when it gives none. */
	public final mimeType:Null<String>;

	@:allow(helix.formats.gltf)
	function new(encoded:Null<Bytes>, path:Null<String>, mimeType:Null<String>) {
		this.encoded = encoded;
		this.path = path;
		this.mimeType = mimeType;
	}
}
