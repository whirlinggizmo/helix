package helix.platform;

import haxe.io.Bytes;

/** Defines the system's clipboard: text, and an image as PNG.

	Reading answers later everywhere, as a page's clipboard does. A page reads only with the player's permission, which the browser may
	ask for, and writes only while it has the keyboard, soon after a key press, click or tap. */
interface IClipboard {
	/** Asks for the clipboard's text.

		One of `read` or `failed` is called once, during this call or later.
		@param read  Receives the text; "" when the clipboard holds none.
		@param failed  Optional. Receives why it couldn't be read, such as a page's permission refused.
		@return  True, because it always asks. */
	function requestText(read:String->Void, ?failed:String->Void):Bool;

	/** Puts text on the clipboard.

		One of `done` or `failed` is called once, during this call or later.
		@param text  The text.
		@param done  Optional. Called once the text is on the clipboard.
		@param failed  Optional. Receives why it couldn't be, such as a page without the keyboard. */
	function setText(text:String, ?done:Void->Void, ?failed:String->Void):Void;

	/** Asks for the clipboard's image, as PNG.

		One of `read` or `failed` is called once, during this call or later.
		@param read  Receives the PNG's bytes. A page's browser may give the same picture encoded anew.
		@param failed  Optional. Receives why there is none: no image on the clipboard, or a page's permission refused.
		@return  True, because it always asks. */
	function requestImage(read:Bytes->Void, ?failed:String->Void):Bool;

	/** Puts an image on the clipboard.

		One of `done` or `failed` is called once, during this call or later.
		@param png  The image, as a PNG file's bytes.
		@param done  Optional. Called once the image is on the clipboard.
		@param failed  Optional. Receives why it couldn't be. */
	function setImage(png:Bytes, ?done:Void->Void, ?failed:String->Void):Void;

	/** Releases the adapter; the clipboard keeps what was put on it, where the system does. */
	function dispose():Void;
}
