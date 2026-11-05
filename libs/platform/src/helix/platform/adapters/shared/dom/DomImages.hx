package helix.platform.adapters.shared.dom;

import js.html.ImageBitmap;

/** Holds the browser's decoded images by handle, so an image decoder's `IDecodedImage.bitmapHandle` can name one for a graphics adapter to
	upload, as the platform's other GPU things are named by handle. The decoder registers an image as it is decoded and forgets it as
	it is disposed. */
@:noCompletion
class DomImages {
	static final images = new Map<Int, ImageBitmap>();
	static var next = 1;

	/** Registers a decoded image, giving it a handle.

		@param image  The browser's decoded image.
		@return  Its handle, never 0. */
	public static function register(image:ImageBitmap):Int {
		var id = next++;
		images.set(id, image);
		return id;
	}

	/** Returns the image a handle names, or null for one forgotten or never registered.

		@param id  The handle.
		@return  The image. */
	public static function get(id:Int):Null<ImageBitmap>
		return images.get(id);

	/** Forgets an image: its handle names nothing after this. The caller closes the image.

		@param id  The handle. */
	public static function forget(id:Int):Void
		images.remove(id);
}
