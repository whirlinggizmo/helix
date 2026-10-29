package helix.platform;

import haxe.io.Bytes;

/** Defines handing a finished file to the user: in a page a download, natively a file in a directory chosen when the adapter is made. */
interface IExport {
	/** Hands a file over; natively a file of the same name is replaced, never left half written.

		One of `exported` or `failed` is called once, on the main thread, during this call or later.
		@param name  The file's name: no directory, not hidden.
		@param mimeType  Its type, such as `"image/png"`.
		@param bytes  The file.
		@param exported  Receives where it went: its path natively, its file name in a page, where the download only began.
		@param failed  Receives why it couldn't be, such as no room or no permission.
		@throws String  A name that isn't a plain file name. */
	function export(name:String, mimeType:String, bytes:Bytes, exported:(where:String) -> Void, failed:String->Void):Void;
}
