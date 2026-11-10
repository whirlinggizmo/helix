package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.Animations;
import helix.raylib.internal.Models;
import helix.raylib.internal.ObjModels;
import helix.formats.obj.MtlFile;
import helix.formats.obj.ObjFile;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.internal.CallbackFiles;
import helix.raylib.internal.WaveReader;
import helix.raylib.internal.Waves;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.internal.Answers.*;
import helix.raylib.modules.RWindowAsync.*;
import helix.raylib.modules.RTexturesAsync.*;
import helix.raylib.modules.RTextAsync.*;
import helix.raylib.modules.RModelsAsync.*;
import helix.raylib.modules.RAudioAsync.*;
#end

/** Provides the async versions of rcore's file calls, which replace raylib's calls that wait for a file or a write.

	Each is helix-raylib's own, written here. `helix.raylib.Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RFilesAsync {
	#if !macro
	/** Asynchronously reads a file's bytes, replacing raylib's `LoadFileData`. See `LoadFileTextAsync` for reading a text file.

		Reads the first of these that has the file:
		- the program's `SetLoadFileDataCallback`
		- what `SaveFileData` wrote
		- the program's files

		@param fileName  The file.
		@param loaded  Receives its bytes.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.withSaves(_ -> {
			var bytes = RCore.dataNow(path);
			if (bytes != null) {
				Runtime.later(() -> loaded(bytes));
				return;
			}
			Runtime.fetch(path, error -> error == null ? loaded(Runtime.files.get(path)) : refuse("LoadFileDataAsync", error, failed));
		});
	}

	/** Asynchronously reads a text file, replacing raylib's `LoadFileText`. See `LoadFileDataAsync` for reading a file's bytes.

		Reads the first of these that has the file:
		- the program's `SetLoadFileTextCallback`
		- what `SaveFileText` wrote
		- the program's files

		The text ends at the file's first NUL byte, as raylib's C string does.

		A byte that isn't UTF-8 is read as U+FFFD. A file is never refused for what it holds.

		@param fileName  The file.
		@param loaded  Receives its text.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		var given = RCore.loadText == null ? null : RCore.loadText(path);
		if (given != null) {
			Runtime.later(() -> loaded(given));
			return;
		}
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED + path)) {
				var text = saves.getString(SAVED + path, "");
				Runtime.later(() -> loaded(text));
				return;
			}
			Runtime.fetch(path, error -> error == null ? loaded(fileText(Runtime.files.get(path))) : refuse("LoadFileTextAsync", error, failed));
		});
	}

	// A file's text as raylib's LoadFileText gives it: its bytes up to the first NUL (a C string ends there for every text function), and
	// never refused for what they hold; bytes that aren't UTF-8, which a String can't hold, read as U+FFFD.
	static function fileText(bytes:haxe.io.Bytes):String {
		var end = 0;
		while (end < bytes.length && bytes.get(end) != 0)
			end++;
		return helix.formats.text.Utf8Text.decodeReplacing(bytes, 0, end);
	}

	/** Asynchronously writes a file's bytes, replacing raylib's `SaveFileData`. See `SaveFileTextAsync` for writing text.

		They are written through the program's `SetSaveFileDataCallback` when it has one. Otherwise they are kept across runs, as
		`SaveFileTextAsync`'s are.

		`LoadFileDataAsync` reads them back.

		@param fileName  The file.
		@param data  The bytes.
		@param dataSize  How many of them.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function SaveFileDataAsync(fileName:String, data:haxe.io.Bytes, dataSize:Int, ?done:Void->Void, ?failed:String->Void):Void {
		RCore.writeData(fileName, data, dataSize, answered(done), error -> refuse("SaveFileDataAsync", error, failed));
	}

	/** Asynchronously writes a text file, replacing raylib's `SaveFileText`. See `SaveFileDataAsync` for writing bytes.

		Written through the program's `SetSaveFileTextCallback` when it has one, during the call, and answered by what that returned.

		Otherwise it is kept across runs, and answered once the write has finished.

		`LoadFileTextAsync` reads it back.

		@param fileName  The file.
		@param text  Its text.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function SaveFileTextAsync(fileName:String, text:String, ?done:Void->Void, ?failed:String->Void):Void {
		RCore.writeText(fileName, text, answered(done), error -> refuse("SaveFileTextAsync", error, failed));
	}

	/** Asynchronously answers whether a file exists, replacing raylib's `FileExists`. See `DirectoryExistsAsync`
		for a directory.

		The answer comes at a later frame, never during the call.

		A file exists when `SaveFileText` or `SaveFileData` wrote it, or when it is one of the program's.

		Finding one of the program's files reads it, so a load of it after answers at once.

		@param fileName  The file.
		@param answer  Receives true when it exists. */
	static function FileExistsAsync(fileName:String, answer:Bool->Void):Void {
		var path = normalize(fileName);
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED + path) || saves.hasKey(SAVED_DATA + path) || Runtime.files.exists(path) || Runtime.images.exists(path)
				|| Runtime.pictures.exists(path))
				Runtime.later(() -> answer(true));
			else
				Runtime.fetch(path, error -> answer(error == null));
		});
	}

	/** Asynchronously answers whether a directory exists, replacing raylib's `DirectoryExists`. See
		`FileExistsAsync` for a file.

		The answer comes at a later frame, never during the call.

		A directory exists when a file `SaveFileText` or `SaveFileData` wrote is in it. The root ("", "." or "./") always exists.

		`helix-raylib-dropped` and the directories under it hold the dropped files.

		The program's own files aren't in directories: a program names each one it loads.

		@param dirPath  The directory.
		@param answer  Receives true when it exists. */
	static function DirectoryExistsAsync(dirPath:String, answer:Bool->Void):Void {
		listOf(directoryOf(dirPath), names -> answer(names != null));
	}

	/** Asynchronously answers whether a path is a file, not a directory, replacing raylib's `IsPathFile`. See
		`DirectoryExistsAsync` for a directory.

		The answer comes at a later frame, never during the call.

		These are files, as `FileExistsAsync` finds them:
		- a file `SaveFileText` or `SaveFileData` wrote
		- a dropped file
		- a file the program has

		@param path  The path.
		@param answer  Receives true for a file; false for a directory or nothing there. */
	static function IsPathFileAsync(path:String, answer:Bool->Void):Void {
		var file = normalize(path);
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED + file) || saves.hasKey(SAVED_DATA + file) || Runtime.file(file) != null || Runtime.images.exists(file)
				|| Runtime.pictures.exists(file)) {
				Runtime.later(() -> answer(true));
				return;
			}
			infoOf(file, (size, _) -> {
				#if js
				if (size == null && !isDropped(file)) {
					Runtime.fetch(file, error -> answer(error == null));
					return;
				}
				#end
				answer(size != null);
			});
		});
	}

	/** Asynchronously answers a file's size, replacing raylib's `GetFileLength`.

		The answer comes at a later frame, never during the call.

		The size is:
		- for a file `SaveFileText` or `SaveFileData` wrote, or the program's `SetLoadFileDataCallback` gives, its bytes' size
		- for a dropped file, its own
		- for a file of the program's, its size

		@param fileName  The file.
		@param answer  Receives its size in bytes; 0 when there is no file, as raylib's. */
	static function GetFileLengthAsync(fileName:String, answer:Int->Void):Void {
		var path = normalize(fileName);
		Runtime.withSaves(saves -> {
			var given = CallbackFiles.load == null ? null : CallbackFiles.load(path);
			var size = given != null ? given.length : saves.hasKey(SAVED + path) ? haxe.io.Bytes.ofString(saves.getString(SAVED + path, ""))
				.length : saves.hasKey(SAVED_DATA + path) ? haxe.crypto.Base64.decode(saves.getString(SAVED_DATA + path, "")).length : -1;
			if (size >= 0) {
				Runtime.later(() -> answer(size));
				return;
			}
			infoOf(path, (size, _) -> {
				if (size != null) {
					answer(size);
					return;
				}
				#if js
				if (!isDropped(path)) {
					Runtime.fetch(path, error -> answer(error == null ? Runtime.files.get(path).length : 0));
					return;
				}
				#end
				answer(0);
			});
		});
	}

	/** Asynchronously answers when a file was last written, replacing raylib's `GetFileModTime`.

		The answer comes at a later frame, never during the call.

		The time is:
		- for a file of the program's, its time on disk
		- for a file `SaveFileText` or `SaveFileData` wrote, when it was saved
		- for a dropped file, the time kept for it
		- 0 for a file whose time isn't kept, such as one the program's load callback gives

		@param fileName  The file.
		@param answer  Receives the time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's. */
	static function GetFileModTimeAsync(fileName:String, answer:Int->Void):Void {
		var path = normalize(fileName);
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED_TIME + path) && (saves.hasKey(SAVED + path) || saves.hasKey(SAVED_DATA + path))) {
				var time = Std.int(saves.getFloat(SAVED_TIME + path, 0));
				Runtime.later(() -> answer(time));
				return;
			}
			infoOf(path, (size, modified) -> answer(size == null ? 0 : Std.int(Math.ffloor(modified))));
		});
	}

	/** Asynchronously lists a directory's files and subdirectories, replacing raylib's `LoadDirectoryFiles`. See
		`LoadDirectoryFilesExAsync` for a filter by extension and the subdirectories' files.

		The answer comes at a later frame, never during the call.

		Each path is the directory's followed by `/` and the name (`dirPath` "levels" gives "levels/1.json"). A subdirectory's has no
		slash at its end.

		The paths are sorted by name.

		The files listed are those `SaveFileText` and `SaveFileData` wrote, and the dropped files, in `DirectoryExistsAsync`'s
		directories. The program's own files aren't listed: a program names each one it loads.

		@param dirPath  The directory.
		@param loaded  Receives the list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as
			raylib's. */
	static function LoadDirectoryFilesAsync(dirPath:String, loaded:FilePathList->Void):Void {
		listOf(directoryOf(dirPath), names -> {
			var list = new FilePathList();
			if (names == null)
				Runtime.log(LOG_WARNING, "FILEIO: Failed to open requested directory");
			else
				list.paths = [
					for (name in names)
						joined(dirPath, StringTools.endsWith(name, "/") ? name.substr(0, name.length - 1) : name)
				];
			list.count = list.capacity = list.paths.length;
			loaded(list);
		});
	}

	/** Asynchronously lists a directory's files with some extensions, and with `scanSubdirs` its subdirectories' too,
		replacing raylib's `LoadDirectoryFilesEx`. See `LoadDirectoryFilesAsync` for listing one directory's every file and subdirectory.

		The answer comes at a later frame, never during the call.

		The paths are `LoadDirectoryFilesAsync`'s, a subdirectory's files right after it.

		A filter is `IsFileExtension`'s list. "DIR" in it keeps the subdirectories.

		A null filter keeps every file, and without `scanSubdirs` every subdirectory too.

		At most 8192 paths are listed (raylib's `MAX_FILEPATH_CAPACITY`), with a warning when there are more.

		@param basePath  The directory.
		@param filter  The extensions kept, such as ".png;.jpg;DIR", or null for every file.
		@param scanSubdirs  Whether the subdirectories' files are listed too.
		@param loaded  Receives the list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning. */
	static function LoadDirectoryFilesExAsync(basePath:String, filter:String, scanSubdirs:Bool, loaded:FilePathList->Void):Void {
		var list = new FilePathList();
		list.capacity = 8192;
		var withDirectories = filter != null && filter.indexOf("DIR") >= 0, full = false;
		function add(path:String):Void {
			list.paths.push(path);
			list.count++;
		}
		function scan(dirPath:String, done:Void->Void):Void {
			listOf(directoryOf(dirPath), names -> {
				if (names == null) {
					Runtime.log(LOG_WARNING, 'FILEIO: Directory cannot be opened ($dirPath)');
					done();
					return;
				}
				var i = 0;
				function next():Void {
					while (i < names.length && !full) {
						if (list.count >= list.capacity) {
							full = true;
							Runtime.log(LOG_WARNING, 'FILEIO: Maximum filepath scan capacity reached (${list.capacity} files)');
							break;
						}
						var name = names[i++];
						if (!StringTools.endsWith(name, "/")) {
							var path = joined(dirPath, name);
							if (filter == null || IsFileExtension(path, filter))
								add(path);
							continue;
						}
						var path = joined(dirPath, name.substr(0, name.length - 1));
						if (withDirectories || filter == null && !scanSubdirs)
							add(path);
						if (scanSubdirs) {
							scan(path, next);
							return;
						}
					}
					done();
				}
				next();
			});
		}
		scan(basePath, () -> loaded(list));
	}

	// A directory's path as the file systems take it: "" for the root ("", "." or "./"), without "./" before it or a slash after.
	static function directoryOf(dirPath:String):String {
		var path = normalize(dirPath == null ? "" : dirPath);
		while (StringTools.endsWith(path, "/"))
			path = path.substr(0, path.length - 1);
		return path == "." ? "" : path;
	}

	// A name in a directory, as raylib joins them: the directory as given, a slash, the name.
	static function joined(dirPath:String, name:String):String {
		var base = dirPath == null ? "" : dirPath;
		while (base.length > 1 && StringTools.endsWith(base, "/"))
			base = base.substr(0, base.length - 1);
		return base == "" ? name : '$base/$name';
	}

	// Whether a path is the dropped files' or under it.
	static function isDropped(path:String):Bool {
		return path == "helix-raylib-dropped" || StringTools.startsWith(path, helix.raylib.internal.MemoryFiles.DROPPED);
	}

	// Lists a directory: of the dropped files, else of the files SaveFileText and SaveFileData wrote, a subdirectory's name ending in a
	// slash. Null when there is none, at a later poll. The root always exists. The program's own files are never listed, on any target.
	static function listOf(directory:String, listed:Null<Array<String>>->Void):Void {
		if (directory != "" && !helix.platform.FilePath.isValid(directory)) {
			Runtime.later(() -> listed(null));
			return;
		}
		if (isDropped(directory)) {
			Runtime.loading();
			Runtime.memory.list(directory, names -> listed(names), () -> listed(null), error -> {
				Runtime.log(LOG_WARNING, 'FILEIO: [$directory] $error');
				listed(null);
			});
			return;
		}
		Runtime.withSaves(saves -> {
			var names = new Map<String, Bool>();
			for (key in saves.getKeys()) {
				var path = StringTools.startsWith(key,
					SAVED) ? key.substr(SAVED.length) : StringTools.startsWith(key, SAVED_DATA) ? key.substr(SAVED_DATA.length) : null;
				if (path == null || directory != "" && !StringTools.startsWith(path, directory + "/"))
					continue;
				var inside = directory == "" ? path : path.substr(directory.length + 1);
				var slash = inside.indexOf("/");
				names.set(slash < 0 ? inside : inside.substr(0, slash + 1), true);
			}
			var sorted = [for (name in names.keys()) name];
			sorted.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
			Runtime.later(() -> listed(directory == "" || sorted.length > 0 ? sorted : null));
		});
	}

	// A file's size and when it was last written: of the dropped files, else natively of the program's files. A null size when there is
	// none, at a later poll; a page's own files are on its server, whose times aren't known.
	static function infoOf(path:String, answer:(size:Null<Int>, modified:Float) -> Void):Void {
		Runtime.loading();
		var files:helix.platform.IFileSystem = isDropped(path) ? Runtime.memory : Runtime.shipped;
		if (files == null || !helix.platform.FilePath.isValid(path)) {
			Runtime.later(() -> answer(null, 0));
			return;
		}
		files.getInfo(path, (size, modified) -> answer(size, modified), () -> answer(null, 0), error -> {
			Runtime.log(LOG_WARNING, 'FILEIO: [$path] $error');
			answer(null, 0);
		});
	}

	/** Asynchronously writes bytes as a C header, the text raylib's `ExportDataAsCode` writes. See
		`SaveFileDataAsync` for the bytes as they are.

		The header is raylib's, byte for byte:
		- the bytes' count, as a define
		- the bytes, as an array in hexadecimal, 20 a line

		Written through `SaveFileTextAsync`.

		@param data  The bytes.
		@param dataSize  How many of them.
		@param fileName  The file; its name, upper case, names the define and the array, with `_` for `.`, `-`, `?`, `!` and `+`.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportDataAsCodeAsync(data:haxe.io.Bytes, dataSize:Int, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportDataAsCodeAsync", fileName, RCore.dataAsCode(data, dataSize, fileName), "Data as code exported successfully", done, failed);
	}

	/** Asynchronously loads an automation events list from a text file, replacing raylib's `LoadAutomationEventList` given a file. See `ExportAutomationEventListAsync` for writing one.

		The file is read as `LoadFileTextAsync` reads it.

		Reads these lines, as raylib's does:
		- a line starting `c`, the count
		- a line starting `e`, an event: its frame, type and four parameters

		Other lines are skipped. So is a last line with no newline at its end, as raylib's reading skips it. A line is read 255 characters at most, as raylib's `fgets` reads it.

		A count that isn't the number of events read warns, and the count becomes the events read.

		@param fileName  The file, as `ExportAutomationEventList` writes it.
		@param loaded  Receives the list, its capacity 16384.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadAutomationEventListAsync(fileName:String, loaded:AutomationEventList->Void, ?failed:String->Void):Void {
		LoadFileTextAsync(fileName, text -> {
			var list = new AutomationEventList();
			list.capacity = helix.raylib.internal.Automation.CAPACITY;
			var counter = 0, at = 0;
			// raylib's fgets, 255 characters at most, and feof: a line is read when it ended in a newline or filled the buffer.
			while (at < text.length) {
				var end = text.indexOf("\n", at);
				var length = end < 0 ? text.length - at : end + 1 - at;
				if (length > 255)
					length = 255;
				var line = text.substr(at, length);
				at += length;
				if (!StringTools.endsWith(line, "\n") && length < 255)
					break;
				switch line.charAt(0) {
					case "c":
						var count = scanInts(line, 1, 1, true);
						if (count.length == 1) list.count = count[0];
					case "e":
						var event = new AutomationEvent();
						var values = scanInts(line, 1, 6, false);
						for (i in 0...values.length)
							if (i == 0)
								event.frame = values[0];
							else if (i == 1)
								event.type = values[1];
							else
								event.params[i - 2] = values[i];
						list.events.push(event);
						counter++;
					case _:
				}
			}
			if (counter != list.count) {
				Runtime.log(LOG_WARNING, 'AUTOMATION: Events read from file [$counter] do not mach event count specified [${list.count}]');
				list.count = counter;
			}
			Runtime.log(LOG_INFO, "AUTOMATION: Events file loaded successfully");
			Runtime.log(LOG_INFO, 'AUTOMATION: Events loaded from file: ${list.count}');
			loaded(list);
		}, error -> refuse("LoadAutomationEventListAsync", error, failed));
	}

	// sscanf's " %d" (or " %i", which reads 0x as hexadecimal and a leading 0 as octal) up to count times from a place in a line:
	// the numbers read before the first that isn't one.
	static function scanInts(line:String, from:Int, count:Int, prefixed:Bool):Array<Int> {
		var out:Array<Int> = [], i = from;
		inline function code(at:Int):Int
			return at < line.length ? StringTools.fastCodeAt(line, at) : 0;
		inline function digit(c:Int, base:Int):Int {
			var d = c >= "0".code
				&& c <= "9".code ? c - "0".code : c >= "a".code
					&& c <= "f".code ? c - "a".code + 10 : c >= "A".code && c <= "F".code ? c - "A".code + 10 : 99;
			return d < base ? d : -1;
		}
		while (out.length < count) {
			while (i < line.length && StringTools.isSpace(line, i))
				i++;
			var negative = false;
			if (code(i) == "+".code || code(i) == "-".code) {
				negative = code(i) == "-".code;
				i++;
			}
			var base = 10;
			if (prefixed && code(i) == "0".code) {
				if ((code(i + 1) == "x".code || code(i + 1) == "X".code) && digit(code(i + 2), 16) >= 0) {
					base = 16;
					i += 2;
				} else
					base = 8;
			}
			if (digit(code(i), base) < 0)
				break;
			var value = 0;
			while (digit(code(i), base) >= 0)
				value = (value * base + digit(code(i++), base)) | 0;
			out.push(negative ? -value | 0 : value);
		}
		return out;
	}

	/** Asynchronously writes a list's events as text, the text raylib's `ExportAutomationEventList` writes. See
		`LoadAutomationEventListAsync` for reading it back.

		The text is raylib's, byte for byte:
		- a header of comments
		- `c` and the count
		- a line for each event: `e`, its frame, type and four parameters, and its type's name

		Written through `SaveFileTextAsync`.

		@param list  The list.
		@param fileName  The file.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportAutomationEventListAsync(list:AutomationEventList, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportAutomationEventListAsync", fileName, RCore.automationText(list), null, done, failed);
	}
	#end
}
