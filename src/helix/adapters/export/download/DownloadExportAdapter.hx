package helix.adapters.export.download;

import haxe.io.Bytes;
import helix.assets.IExport;
import js.Browser;

/** IExport in a browser: the file is downloaded, as a link with the download attribute does it (the browser may ask where, or keep it in its
	downloads). The page can't know whether the user kept it; Exported says only that the download began. */
class DownloadExportAdapter implements IExport {
	/** Downloads through the page's document. */
	public function new() {}

	public function export(name:String, mimeType:String, bytes:Bytes, done:ExportResult->Void):Void {
		if (name == "" || name.indexOf("/") >= 0 || name.indexOf("\\") >= 0 || name.charAt(0) == ".")
			throw "Invalid export name";
		var blob = new js.html.Blob([bytes.getData()], {type: mimeType}),
			url = js.html.URL.createObjectURL(blob);
		var link = Browser.document.createAnchorElement();
		link.href = url;
		link.download = name;
		link.style.display = "none";
		Browser.document.body.appendChild(link);
		link.click();
		link.remove();
		// The download has taken the blob's URL by the next task.
		Browser.window.setTimeout(() -> js.html.URL.revokeObjectURL(url), 0);
		done(Exported(name));
	}
}
