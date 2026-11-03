package helix.raylib.internal;

#if macro
import haxe.macro.Expr;

/** Chooses a wave's reader as the program builds (`Extras.LoadWaveAsync`, `Extras.LoadWaveFromMemoryAsync`), so a program carries only
	the readers it names, as `ModelMacro` chooses a model's. */
@:noCompletion
class WaveMacro {
	/** Returns the call loading a wave from a file, by the reader its extension names when the name is known as the program builds
		(`ShaderMacro.known`), or the one choosing as the program runs otherwise.

		@param fileName  The file's name.
		@param loaded  Receives the wave.
		@param failed  Optional. Receives why it couldn't be loaded.
		@return  The call. */
	public static function load(fileName:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		var name = ShaderMacro.known(fileName);
		var read = reader(name == null ? null : extension(name));
		if (failed == null)
			failed = macro null;
		return macro @:privateAccess helix.raylib.modules.RAsync.loadWave($fileName, $read, $loaded, $failed);
	}

	/** Returns the call reading a wave from a file's bytes, by the reader its type names when the type is known as the program builds,
		or the one choosing as the program runs otherwise.

		@param fileType  The file's extension with its dot.
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param loaded  Receives the wave.
		@param failed  Optional. Receives why it couldn't be read.
		@return  The call. */
	public static function fromMemory(fileType:Expr, fileData:Expr, dataSize:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		var read = reader(ShaderMacro.known(fileType));
		if (failed == null)
			failed = macro null;
		return macro @:privateAccess helix.raylib.modules.RAsync.loadWaveFromMemory($fileType, $fileData, $dataSize, $read, $loaded, $failed);
	}

	// A file name's extension as raylib's GetFileExtension gives it: from its last dot, none when the dot leads the name.
	static function extension(name:String):String {
		var dot = name.lastIndexOf(".");
		return dot <= 0 ? "" : name.substr(dot);
	}

	// The reader of a file type, compared as raylib's LoadWaveFromMemory compares it (lower or upper case); the one choosing as the
	// program runs for a type known only then.
	static function reader(fileType:Null<String>):Expr {
		var name = switch fileType {
			case null: "readWave";
			case ".wav" | ".WAV": "readWav";
			case ".ogg" | ".OGG": "readOgg";
			case ".mp3" | ".MP3": "readMp3";
			case ".qoa" | ".QOA": "readQoa";
			case _: "readUnsupported";
		}
		return macro @:privateAccess $p{["helix", "raylib", "modules", "RAsync", name]};
	}
}
#end
