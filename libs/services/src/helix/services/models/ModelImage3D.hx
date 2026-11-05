package helix.services.models;

import haxe.io.Bytes;
import helix.platform.IDecodedImage;

/** Represents one of a model's images: its file's bytes, and the image decoded for the GPU from them.

	`Models` decodes each image through `Images.decodeForGpu`, so a program draws it without holding its pixels. What uploads it takes the
	decoded image once (`takeDecoded`) and disposes it once sent. `encoded` stays with the model, so the image can be decoded again
	(`Images.decodeForGpu`), as a texture lost with the GPU's context is. */
class ModelImage3D {
	/** Gets the path of the image's own file, as the assets name it, or "" for an image held in the model's file. */
	public final path:String;

	/** Gets the image file's bytes: the file at `path`, or the model's bytes holding the image (a glTF buffer view, or a `data:` URI
		decoded). `Images.decodeForGpu` decodes them again. */
	public final encoded:Bytes;

	/** Gets its width, in pixels. */
	public final width:Int;

	/** Gets its height, in pixels. */
	public final height:Int;

	var decoded:Null<IDecodedImage>;

	@:allow(helix.services.models)
	function new(path:String, encoded:Bytes, decoded:IDecodedImage) {
		this.path = path;
		this.encoded = encoded;
		this.decoded = decoded;
		width = decoded.width;
		height = decoded.height;
	}

	/** Returns the image decoded for the GPU, once: the caller owns it, uploads it (`IGraphics.createTextureFromImage`) or reads its
		pixels, and disposes it after.

		@return  The decoded image, or null once it was taken or disposed. */
	public function takeDecoded():Null<IDecodedImage> {
		var image = decoded;
		decoded = null;
		return image;
	}

	/** Frees the decoded image while it is held. `encoded` stays. */
	public function dispose():Void {
		if (decoded != null)
			decoded.dispose();
		decoded = null;
	}
}
