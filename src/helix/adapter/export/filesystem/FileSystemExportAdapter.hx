package helix.adapter.export.filesystem;

import helix.adapter.shared.ReplaceBridge;
import haxe.io.Bytes;
import haxe.io.Path;
import helix.asset.IExport;
import helix.asset.ExportResult;

/** IExport natively: the file is written into a directory (made when first needed), through a temporary file renamed over it, so a file
	there is never half written. */
@:noCompletion
class FileSystemExportAdapter implements IExport {
	var directory:String;

	/** Exports into directory. */
	public function new(directory:String)
		this.directory = directory;

	/** The user's pictures directory for product, on Linux: XDG_PICTURES_DIR (from the environment, else the user's user-dirs.dirs), else
		~/Pictures, then product; null without a home directory. */
	public static function getPicturesDirectory(product:String):Null<String> {
		var home = Sys.getEnv("HOME"),
			pictures = Sys.getEnv("XDG_PICTURES_DIR");
		if (pictures == null && home != null) {
			var config = Sys.getEnv("XDG_CONFIG_HOME");
			var dirs = Path.join([
				config != null && config != "" ? config : Path.join([home, ".config"]),
				"user-dirs.dirs"
			]);
			if (sys.FileSystem.exists(dirs))
				for (line in sys.io.File.getContent(dirs).split("\n")) {
					var at = line.indexOf("XDG_PICTURES_DIR=");
					if (at == 0)
						pictures = StringTools.replace(StringTools.replace(line.substr(17), '"', ""), "$HOME", home);
				}
			if (pictures == null)
				pictures = Path.join([home, "Pictures"]);
		}
		return pictures == null || pictures == "" ? null : Path.join([pictures, product]);
	}

	public function export(name:String, mimeType:String, bytes:Bytes, done:ExportResult->Void):Void {
		if (name == "" || name.indexOf("/") >= 0 || name.indexOf("\\") >= 0 || name.charAt(0) == ".")
			throw "Invalid export name";
		var path = Path.join([directory, name]), temporary = path + ".part";
		try {
			sys.FileSystem.createDirectory(directory);
			sys.io.File.saveBytes(temporary, bytes);
			if (ReplaceBridge.replace(temporary, path) == 0)
				throw 'Could not replace $path';
			done(Exported(path));
		} catch (error:Dynamic) {
			try
				sys.FileSystem.deleteFile(temporary)
			catch (_:Dynamic) {}
			done(Failed(Std.string(error)));
		}
	}
}
