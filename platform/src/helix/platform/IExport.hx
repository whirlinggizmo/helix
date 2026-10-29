package helix.platform;

import haxe.io.Bytes;

/** Defines handing a finished file to the user.

	In a page the file is a download. Natively it is written to a directory chosen when the adapter is made. */
interface IExport {
	/** Hands a file over to the user.

		Natively, a file of the same name is replaced, and is never left half written. One of `exported` or `failed` is called once, on the
		main thread, during this call or later.
		@param name  The file's name, with no directory, and not hidden.
		@param mimeType  The file's type, such as `"image/png"`.
		@param bytes  The file.
		@param exported  Receives where the file went. Natively it is the file's path. In a page it is the file's name, and the download has
			only begun.
		@param failed  Receives why the file couldn't be exported, such as no room or no permission.
		@throws String  When the name isn't a plain file name. */
	function export(name:String, mimeType:String, bytes:Bytes, exported:(where:String) -> Void, failed:String->Void):Void;
}
