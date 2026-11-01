package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Animations;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.internal.CallbackFiles;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.RAsync.*;
#end

/** Holds the async loads, helix-ray's own in place of raylib's loads that wait for a file, written here; `Raylib` forwards to each
	(`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RAsync {
	#if !macro
	// ---- The async loads: helix-ray's own, not raylib's ----

	/** Loads an image file as a texture, answering when it is ready: helix-ray's own, in place of raylib's `LoadTexture`, as a page
		can't wait for a file. A file loaded again shares its first load's texture, and the image goes to the GPU when first drawn. The
		answer comes at a later frame, never during the call.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the texture.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(RTextures.loadTexture(path)) : refuse("LoadTextureAsync", error, failed));
	}

	/** Loads a model from a glTF or GLB file, with its images and the files it points to, answering when it is ready: helix-ray's own,
		in place of raylib's `LoadModel`. A file loaded again, while a load of it lives, shares its meshes' GPU buffers and its textures, with materials of its own.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the model.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadModelAsync(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName), lower = path.toLowerCase();
		if (!(StringTools.endsWith(lower, ".glb") || StringTools.endsWith(lower, ".gltf"))) {
			Runtime.later(() -> refuse("LoadModelAsync", '$path: only glTF and GLB are read here', failed));
			return;
		}
		if (Models.isKept(path)) {
			Runtime.later(() -> loaded(RModels.loadModel(path)));
			return;
		}
		Runtime.loading();
		Runtime.models.load(path, read -> {
			// raylib gives a mesh without joints whose node is a bone's child to that bone: the nodes are the file's, read again.
			if (read.skeleton != null && read.skins.length > 0 && Lambda.exists(read.meshes, m -> m.joints == null)) {
				Animations.read(path, file -> {
					Models.keep(read, defaultShader(), Animations.attached(file));
					loaded(RModels.loadModel(path));
				}, error -> refuse("LoadModelAsync", error, failed));
				return;
			}
			Models.keep(read, defaultShader());
			loaded(RModels.loadModel(path));
		}, error -> refuse("LoadModelAsync", error, failed));
	}

	/** Loads a glTF or GLB file's animations, answering when they are read: helix-ray's own, in place of raylib's
		`LoadModelAnimations`. They are read as raylib 6.2 reads them, of the file's first skin: each sampled 60 times a second, with
		(int)(duration * 60) + 1 frames, each frame's pose its bones' transforms in the model. A file without skins gives none.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the animations, as many as the file has; their count is its length.
		@param failed  Optional. Receives why they couldn't be loaded; when omitted, it is logged. */
	static function LoadModelAnimationsAsync(fileName:String, loaded:Array<ModelAnimation>->Void, ?failed:String->Void):Void {
		var path = normalize(fileName), lower = path.toLowerCase();
		if (!(StringTools.endsWith(lower, ".glb") || StringTools.endsWith(lower, ".gltf"))) {
			Runtime.later(() -> refuse("LoadModelAnimationsAsync", '$path: only glTF and GLB are read here', failed));
			return;
		}
		Animations.read(path, file -> {
			var animations = try Animations.fromGltf(file, path) catch (e:Dynamic) {
				refuse("LoadModelAnimationsAsync", '$path: $e', failed);
				return;
			}
			loaded(animations);
		}, error -> refuse("LoadModelAnimationsAsync", error, failed));
	}

	/** Loads a sound file and decodes it, answering when it is ready to play at once: helix-ray's own, in place of raylib's `LoadSound`.
		A file loaded again shares its first load's decoded sound. `InitAudioDevice` comes first.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the sound.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Runtime.audio == null) {
			Runtime.later(() -> refuse("LoadSoundAsync", '$path: InitAudioDevice first', failed));
			return;
		}
		var sound = RAudio.loadSound(path);
		var entry = sounds.get(path);
		if (entry.loaded != null)
			Runtime.later(() -> loaded(sound));
		else
			entry.answers.push(error -> error == null ? loaded(sound) : refuse("LoadSoundAsync", error, failed));
	}

	/** Loads a sound file's samples, answering when they are read: helix-ray's own, in place of raylib's `LoadWave`. The formats are
		`LoadWaveFromMemoryAsync`'s, by the file's extension.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the wave, its samples its own.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadWaveAsync(fileName:String, loaded:Wave->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse("LoadWaveAsync", error, failed);
				return;
			}
			var bytes = Runtime.files.get(path);
			var type = GetFileExtension(fileName);
			LoadWaveFromMemoryAsync(type == null ? "" : type, bytes, bytes.length, loaded, message -> refuse("LoadWaveAsync", '$path: $message', failed));
		});
	}

	/** Reads a sound file's samples from its bytes, answering when they are read: helix-ray's own, in place of raylib's
		`LoadWaveFromMemory`, as files other than WAV are decoded off the main thread.

		A ".wav" file is read as raylib's dr_wav reads it, as 16-bit samples at the file's rate and channels (ADPCM and other compressed
		WAV encodings aren't read). An ".ogg", ".mp3" or ".flac" file is decoded by the platform, as 32-bit float samples at 44100 Hz in
		the file's channels, where raylib keeps the file's rate (and gives Ogg 16-bit samples); a file of more than 2 channels is mixed to
		stereo. FLAC is read here, which raylib's default build leaves out; QOA isn't. As raylib's, the extension is lower or upper case.
		The answer comes at a later frame.

		@param fileType  The file's extension with its dot: ".wav", ".ogg", ".mp3" or ".flac", or the same in upper case.
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param loaded  Receives the wave, its samples its own.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadWaveFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Wave->Void, ?failed:String->Void):Void {
		var data = fileData == null ? haxe.io.Bytes.alloc(0) : dataSize < fileData.length ? fileData.sub(0, Std.int(Math.max(0, dataSize))) : fileData;
		function done(wave:Wave):Void {
			Runtime.log(LOG_INFO, 'WAVE: Data loaded successfully (${wave.sampleRate} Hz, ${wave.sampleSize} bit, ${wave.channels} channels)');
			loaded(wave);
		}
		if (fileType == ".wav" || fileType == ".WAV") {
			var wav = try helix.formats.wav.WavFile.read(data) catch (_:Dynamic) null;
			Runtime.later(() -> wav == null ? refuse("LoadWaveFromMemoryAsync", "WAVE: Failed to load WAV data",
				failed) : done(new Wave(wav.frameCount, wav.sampleRate, 16, wav.channels, wav.toInt16())));
			return;
		}
		var decoded = ["ogg", "mp3", "flac"].indexOf(fileType == null ? "" : fileType.substr(1).toLowerCase()) >= 0;
		if (!decoded || fileType.substr(1) != fileType.substr(1).toLowerCase() && fileType.substr(1) != fileType.substr(1).toUpperCase()) {
			Runtime.later(() -> refuse("LoadWaveFromMemoryAsync", "WAVE: Data format not supported", failed));
			return;
		}
		RAudio.audioDecoder()
			.decode(data, (samples, channels) -> done(new Wave(Std.int(samples.length / (4 * channels)), 44100, 32, channels, samples)),
				message -> refuse("LoadWaveFromMemoryAsync", 'WAVE: Failed to load ${fileType.substr(1).toUpperCase()} data: $message', failed));
	}

	/** Reads a text file, answering when it is read: helix-ray's own, in place of raylib's `LoadFileText`. The program's
		`SetLoadFileTextCallback` answers first, then what `SaveFileText` wrote, then the program's files.

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
			Runtime.fetch(path, error -> error == null ? loaded(Runtime.files.get(path).toString()) : refuse("LoadFileTextAsync", error, failed));
		});
	}

	/** Reads a file's bytes, answering when they are read: helix-ray's own, in place of raylib's `LoadFileData`. The program's
		`SetLoadFileDataCallback` answers first, then what `SaveFileData` wrote, then the program's files.

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

	/** Loads an automation events list from a text file, answering when it is read: helix-ray's own, in place of raylib's
		`LoadAutomationEventList` given a file. It reads the file as `LoadFileTextAsync` does, then as raylib's does: each line starting
		`c` sets the count, each starting `e` is an event, its frame, type and four parameters; other lines are skipped, and so is a last
		line with no newline at its end, as raylib's reading skips it. A count that isn't the events read warns, and the events read are
		the count.

		@param fileName  The file, as `ExportAutomationEventList` writes it.
		@param loaded  Receives the list, its capacity 16384.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadAutomationEventListAsync(fileName:String, loaded:AutomationEventList->Void, ?failed:String->Void):Void {
		LoadFileTextAsync(fileName, text -> {
			var list = new AutomationEventList();
			list.capacity = helix.ray.internal.Automation.CAPACITY;
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

	/** Answers whether a file exists: helix-ray's own, in place of raylib's `FileExists`. One `SaveFileText` or `SaveFileData` wrote
		exists, as does one of the program's; finding one of the program's reads it, so a load of it after answers at once. The answer
		comes at a later frame, never during the call.

		@param fileName  The file.
		@param answer  Receives true when it exists. */
	static function FileExistsAsync(fileName:String, answer:Bool->Void):Void {
		var path = normalize(fileName);
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED + path)
				|| saves.hasKey(SAVED_DATA + path)
				|| Runtime.files.exists(path)
				|| Runtime.images.exists(path))
				Runtime.later(() -> answer(true));
			else
				Runtime.fetch(path, error -> answer(error == null));
		});
	}

	/** Answers a file's size: helix-ray's own, in place of raylib's `GetFileLength`. A file `SaveFileText` or `SaveFileData` wrote, or
		the program's `SetLoadFileDataCallback` gives, is its bytes' size; a dropped file's is its own. Natively a file of the program's is
		its size on disk; in a page it is read from the server to be measured, so a load of it after answers at once. The answer comes at
		a later frame, never during the call.

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

	/** Answers when a file was last written: helix-ray's own, in place of raylib's `GetFileModTime`. Natively a file of the program's
		answers its time on disk; a file `SaveFileText` or `SaveFileData` wrote, when it was saved. A page's own files are on its server,
		and a dropped file or one the program's load callback gives has no time kept, so each answers 0. The answer comes at a later frame,
		never during the call.

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

	/** Answers whether a path is a file, not a directory: helix-ray's own, in place of raylib's `IsPathFile`. A file `SaveFileText` or
		`SaveFileData` wrote, a dropped file, and a file the program has, as `FileExistsAsync` finds them, are files. The answer comes at a
		later frame, never during the call.

		@param path  The path.
		@param answer  Receives true for a file; false for a directory or nothing there. */
	static function IsPathFileAsync(path:String, answer:Bool->Void):Void {
		var file = normalize(path);
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED + file) || saves.hasKey(SAVED_DATA + file) || Runtime.file(file) != null || Runtime.images.exists(file)) {
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

	/** Answers whether a directory exists: helix-ray's own, in place of raylib's `DirectoryExists`. Natively it is a directory of the
		program's files; `helix-ray-dropped` and the directories under it hold the dropped files. A page's own files are on its server,
		which can't be listed, so there only its root ("", "." or "./") and the dropped files' directories exist. The answer comes at a later
		frame, never during the call.

		@param dirPath  The directory.
		@param answer  Receives true when it exists. */
	static function DirectoryExistsAsync(dirPath:String, answer:Bool->Void):Void {
		listOf(directoryOf(dirPath), names -> answer(names != null));
	}

	/** Lists a directory's files and subdirectories: helix-ray's own, in place of raylib's `LoadDirectoryFiles`. Each path is the
		directory's followed by `/` and the name (`dirPath` "levels" gives "levels/1.json"), sorted by name, a subdirectory's without a
		slash at its end. The directories are `DirectoryExistsAsync`'s; a page lists only the dropped files. Files `SaveFileText` and
		`SaveFileData` wrote aren't listed. The answer comes at a later frame, never during the call.

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

	/** Lists a directory's files, those with some extensions, and with `scanSubdirs` its subdirectories' too: helix-ray's own, in place
		of raylib's `LoadDirectoryFilesEx`. The paths are `LoadDirectoryFilesAsync`'s, a subdirectory's files right after it. As raylib's:
		a null filter keeps every file, and without `scanSubdirs` every subdirectory too; a filter is `IsFileExtension`'s list, and
		"DIR" in it keeps the subdirectories; at most 8192 paths are listed (`MAX_FILEPATH_CAPACITY`), with a warning when there are
		more. The answer comes at a later frame, never during the call.

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

	/** Loads a font file, answering when its glyphs are ready: helix-ray's own, in place of raylib's `LoadFont`. A TrueType or OpenType
		file gives its printable ASCII at 32 pixels; a BMFont (.fnt, the text format) its characters and pages, the pages stacked onto
		one texture, as raylib's; an image (PNG, JPEG, BMP, TGA or QOI) its glyphs on a `MAGENTA` key from the space on, as
		`LoadFontFromImage` reads them; each drawn with `TEXTURE_FILTER_POINT`.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadFontAsync(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
		var path = normalize(fileName),
			type = haxe.io.Path.extension(path).toLowerCase();
		if (type == "fnt") {
			Runtime.fonts().loadBmFont(path, font -> {
				var made = RText.fromBmFont(font);
				SetTextureFilter(made.texture, TEXTURE_FILTER_POINT);
				loaded(made);
			}, message -> refuse("LoadFontAsync", message, failed));
			return;
		}
		if (isDecoded(type) || type == "qoi") {
			LoadImageAsync(path, image -> {
				var font = LoadFontFromImage(image, MAGENTA, 32);
				SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
				loaded(font);
			}, message -> refuse("LoadFontAsync", message, failed));
			return;
		}
		if (type != "ttf" && type != "otf") {
			Runtime.later(() -> refuse("LoadFontAsync", '$path: .$type fonts aren\'t in helix-ray yet', failed));
			return;
		}
		LoadFontExAsync(path, 32, null, 95, font -> {
			SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
			loaded(font);
		}, failed);
	}

	/** Loads a TrueType or OpenType font file at a size, answering when its glyphs are ready: helix-ray's own, in place of raylib's
		`LoadFontEx`.

		The font holds only the characters the file has, so `glyphCount` may be fewer than asked for and a character it lacks draws as
		its '?'; each Unicode space it has (U+0020, U+00A0, U+2000 to U+200A, U+3000 and the others) is a blank glyph as wide as its
		advance.

		@param fileName  The file, as the program names it.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadFontExAsync(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> {
			if (error != null)
				refuse("LoadFontExAsync", error, failed);
			else
				LoadFontFromMemoryAsync("." + haxe.io.Path.extension(path), Runtime.files.get(path), Runtime.files.get(path).length, fontSize, codepoints,
					codepointCount, loaded, message -> refuse("LoadFontExAsync", '$path: $message', failed));
		});
	}

	/** Makes a font from a TrueType or OpenType file's bytes, answering when its glyphs are ready: helix-ray's own, in place of raylib's
		`LoadFontFromMemory`, as the glyphs are rasterized off the main thread.

		The font holds only the characters the file has, as `LoadFontExAsync`'s does; with none of them, it is the default font.

		@param fileType  The file's extension, ".ttf" or ".otf".
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be made; when omitted, it is logged. */
	static function LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int,
			loaded:Font->Void, ?failed:String->Void):Void {
		var type = fileType.toLowerCase();
		if (type != ".ttf" && type != ".otf") {
			Runtime.later(() -> refuse("LoadFontFromMemoryAsync", '$fileType fonts aren\'t in helix-ray yet', failed));
			return;
		}
		var count = codepointCount > 0 ? codepointCount : 95;
		var wanted = codepoints == null ? [for (i in 0...count) 32 + i] : codepoints.slice(0, count);
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.rasterizer()
			.rasterize(data, fontSize, wanted, false, (glyphs, ascent, _, _) -> loaded(RText.fontOf(RText.foundGlyphs(glyphs, ascent, fontSize), fontSize)),
				message -> refuse("LoadFontFromMemoryAsync", message, failed));
	}

	/** Rasterizes a TrueType or OpenType font's glyphs, answering when they are ready: helix-ray's own, in place of raylib's
		`LoadFontData`. Each glyph has its own image, 8-bit grayscale, for `GenImageFontAtlas`; `FONT_SDF` makes them signed distances, with
		4 texels of padding, 128 on the outline and 64 a texel.

		@param fileData  The font file's bytes.
		@param dataSize  How many of them.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95.
		@param type  `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances.
		@param loaded  Receives the glyphs.
		@param failed  Optional. Receives why the font couldn't be read; when omitted, it is logged. */
	static function LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int,
			loaded:Array<GlyphInfo>->Void, ?failed:String->Void):Void {
		var count = codepointCount > 0 ? codepointCount : 95;
		var wanted = codepoints == null ? [for (i in 0...count) 32 + i] : codepoints.slice(0, count);
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.rasterizer()
			.rasterize(data, fontSize, wanted, type == FONT_SDF, (glyphs, ascent, _, _) -> loaded(RText.fontData(glyphs, ascent, fontSize, type)),
				message -> refuse("LoadFontDataAsync", message, failed));
	}

	/** Loads an image file, answering when it is decoded: helix-ray's own, in place of raylib's `LoadImage`, as a page can't wait for a
		file. A PNG, JPEG, BMP or TGA file is decoded by the platform, so it gives `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` whatever its
		channels, where raylib's gives a grayscale file grayscale; a QOI file gives its own channels, RGB or RGBA, as raylib's. The answer
		comes at a later frame, never during the call.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the image, its pixels its own.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadImageAsync(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
		var path = normalize(fileName),
			type = haxe.io.Path.extension(path).toLowerCase();
		if (type == "qoi") {
			Runtime.fetch(path, error -> {
				if (error != null)
					refuse("LoadImageAsync", error, failed);
				else
					decoded("LoadImageAsync", "." + type, Runtime.files.get(path), loaded, failed);
			});
			return;
		}
		if (!isDecoded(type)) {
			Runtime.later(() -> refuse("LoadImageAsync", '$path: .$type images aren\'t read here', failed));
			return;
		}
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse("LoadImageAsync", error, failed);
				return;
			}
			var image = Runtime.image(path);
			loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height));
		});
	}

	/** Loads an image's raw pixels from a file, answering when they are read: helix-ray's own, in place of raylib's `LoadImageRaw`. The
		file holds the pixels in a format, after a header of some bytes; a file too small for them fails.

		@param fileName  The file.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param format  The pixel format (`PIXELFORMAT_*`).
		@param headerSize  The bytes before the pixels, skipped when the file holds them and the pixels.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadImageRawAsync(fileName:String, width:Int, height:Int, format:Int, headerSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		LoadFileDataAsync(fileName, bytes -> {
			var size = GetPixelDataSize(width, height, format);
			if (size > bytes.length) {
				refuse("LoadImageRawAsync", '${normalize(fileName)}: ${bytes.length} bytes, too few for $width x $height pixels', failed);
				return;
			}
			var start = headerSize > 0 && headerSize + size <= bytes.length ? headerSize : 0;
			loaded(new Image(bytes.sub(start, size), width, height, 1, format));
		}, error -> refuse("LoadImageRawAsync", error, failed));
	}

	/** Decodes an image file's bytes, answering when it is decoded: helix-ray's own, in place of raylib's `LoadImageFromMemory`, as
		images are decoded asynchronously. The formats and channels are `LoadImageAsync`'s.

		@param fileType  The file's extension: ".png", ".jpg", ".jpeg", ".bmp", ".tga" or ".qoi".
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be decoded; when omitted, it is logged. */
	static function LoadImageFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.loading();
		Runtime.later(() -> decoded("LoadImageFromMemoryAsync", fileType == null ? "" : fileType.toLowerCase(), data, loaded, failed));
	}

	/** Reads a texture's pixels, answering when they are read: helix-ray's own, in place of raylib's `LoadImageFromTexture`, as the GPU
		answers later. A render texture's are read back from the GPU after the frame it was drawn in, rows bottom first as raylib's are,
		so it reads upside down as raylib's does. Another texture's pixels are what went to the GPU, while they are in memory: before it
		is first drawn, or when it was loaded from a file (raylib's default texture's, its white pixel, always); once only on the GPU they
		can't be read here, and it fails.

		@param texture  The texture.
		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image->Void, ?failed:String->Void):Void {
		if (texture.flipped) {
			var answered = false, during = true;
			Runtime.graphics.readPixels(Textures.handle(texture.id), (pixels, width, height) -> {
				var image = rgba(pixels, width, height);
				ImageFlipVertical(image);
				Runtime.log(LOG_INFO, 'TEXTURE: [ID ${texture.id}] Pixel data retrieved successfully');
				during ? Runtime.later(() -> loaded(image)) : loaded(image);
			},
				error -> during ? Runtime.later(() -> refuse("LoadImageFromTextureAsync", error, failed)) : refuse("LoadImageFromTextureAsync", error, failed));
			during = false;
			return;
		}
		var image = Textures.imageOf(texture.id);
		Runtime.later(() -> image == null ? refuse("LoadImageFromTextureAsync",
			'TEXTURE: [ID ${texture.id}] Failed to retrieve pixel data: its pixels are on the GPU alone',
			failed) : loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height)));
	}

	/** Reads the screen, answering as the next frame ends: helix-ray's own, in place of raylib's `LoadImageFromScreen`, as the GPU
		answers later. The image is the framebuffer's size, as raylib 6.2's is (5.5 scaled the screen's size by its DPI instead), rows top
		first, its alpha opaque.

		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadImageFromScreenAsync(loaded:Image->Void, ?failed:String->Void):Void {
		if (Runtime.frame == null) {
			Runtime.later(() -> refuse("LoadImageFromScreenAsync", "InitWindow first", failed));
			return;
		}
		Runtime.screenshots().captureFrame(captured -> {
			var pixels = captured.pixels;
			for (i in 0...captured.width * captured.height)
				pixels.set(i * 4 + 3, 255);
			loaded(rgba(pixels, captured.width, captured.height));
		}, error -> refuse("LoadImageFromScreenAsync", error, failed));
	}

	/** Reads the clipboard's text, answering at a later poll: helix-ray's own, in place of raylib's `GetClipboardText`, as a page's
		clipboard answers later. A page reads it only with the player's permission, which the browser may ask for.

		@param read  Receives the text; "" when the clipboard holds none.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardTextAsync(read:String->Void, ?failed:String->Void):Void {
		Runtime.clipboard().requestText(text -> Runtime.later(() -> read(text)), error -> Runtime.later(() -> refuse("GetClipboardTextAsync", error, failed)));
	}

	/** Reads the clipboard's image, answering at a later poll once it is decoded: helix-ray's own, in place of raylib's
		`GetClipboardImage`. A page reads it only with the player's permission.

		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardImageAsync(loaded:Image->Void, ?failed:String->Void):Void {
		Runtime.loading();
		Runtime.clipboard()
			.requestImage(png -> Runtime.later(() -> decoded("GetClipboardImageAsync", ".png", png, loaded, failed)),
				error -> Runtime.later(() -> refuse("GetClipboardImageAsync", error, failed)));
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
		return path == "helix-ray-dropped" || StringTools.startsWith(path, helix.ray.internal.MemoryFiles.DROPPED);
	}

	// Lists a directory: of the dropped files, else natively of the program's files. Null when there is none, at a later poll; a page's
	// own files can't be listed, so its root lists nothing and any other directory is none.
	static function listOf(directory:String, listed:Null<Array<String>>->Void):Void {
		Runtime.loading();
		var files:helix.platform.IFileSystem = isDropped(directory) ? Runtime.memory : Runtime.shipped;
		if (directory != "" && !helix.platform.FilePath.isValid(directory)) {
			Runtime.later(() -> listed(null));
			return;
		}
		if (files == null) {
			Runtime.later(() -> listed(directory == "" ? [] : null));
			return;
		}
		files.list(directory, names -> listed(names), () -> listed(null), error -> {
			Runtime.log(LOG_WARNING, 'FILEIO: [$directory] $error');
			listed(null);
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

	// Whether an image file's extension is one the platform decodes.
	static function isDecoded(type:String):Bool {
		return type == "png" || type == "jpg" || type == "jpeg" || type == "bmp" || type == "tga";
	}

	// An image of RGBA pixels, which it keeps.
	static function rgba(pixels:haxe.io.Bytes, width:Int, height:Int):Image {
		return new Image(pixels, width, height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
	}

	// An image file's bytes decoded, by its extension: QOI here, with its channels, the rest by the platform, as RGBA.
	static function decoded(name:String, fileType:String, data:haxe.io.Bytes, loaded:Image->Void, failed:Null<String->Void>):Void {
		if (fileType == ".qoi") {
			var qoi = try helix.formats.qoi.QoiFile.read(data) catch (e:Dynamic) null;
			if (qoi == null) {
				refuse(name, "IMAGE: Failed to load image data", failed);
				return;
			}
			loaded(new Image(qoi.pixels, qoi.width, qoi.height, 1, qoi.channels == 4 ? PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 : PIXELFORMAT_UNCOMPRESSED_R8G8B8));
			return;
		}
		if (!isDecoded(fileType.substr(1))) {
			refuse(name, 'IMAGE: Data format not supported: $fileType', failed);
			return;
		}
		Runtime.decoding.decode(data, image -> loaded(rgba(image.pixels, image.width, image.height)), error -> refuse(name, error, failed));
	}

	// Answers a load that failed: to the program's failed callback, or logged. Every error names the file, as the services' do.
	static function refuse(name:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			Runtime.log(4, '$name: $error');
	}
	#end
}
