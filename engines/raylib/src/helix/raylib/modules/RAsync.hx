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
import helix.raylib.modules.RAsync.*;
#end

/** Holds the async loads, requests and writes, helix-raylib's own in place of raylib's loads that wait for a file and its window, cursor,
	clipboard and file calls done when they return, written here; `Extras` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RAsync {
	#if !macro
	// ---- The async loads: helix-raylib's own, not raylib's ----
	// LoadTextureAsync's call where its file's name isn't known as the program builds (Extras.LoadTextureAsync): a GIF file's first
	// frame or the platform's decode, picked by its extension as it runs, so both are in the program.
	static function loadTextureFile(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifTexture(fileName, loaded, failed);
		else
			loadPlainTexture(fileName, loaded, failed);
	}

	// LoadTextureAsync's call for a GIF file: its first frame, kept as the file's image so later loads share its texture.
	static function loadGifTexture(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		gifFile("LoadTextureAsync", path, () -> loaded(RTextures.loadTexture(path)), failed);
	}

	// LoadTextureAsync's call for any other file.
	static function loadPlainTexture(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(RTextures.loadTexture(path)) : refuse("LoadTextureAsync", error, failed));
	}

	// LoadModelAsync's call where its file's name isn't known as the program builds (Extras.LoadModelAsync): the reader picked by its
	// extension as it runs, so both readers are in the program. A format helix-raylib doesn't read is refused.
	static function loadModel(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName), lower = path.toLowerCase();
		var extension = lower.lastIndexOf(".") >= 0 ? lower.substr(lower.lastIndexOf(".")) : "";
		if (extension == ".iqm" || extension == ".vox" || extension == ".m3d") {
			Runtime.later(() -> refuse("LoadModelAsync", '$path: ${extension.substr(1).toUpperCase()} models are not supported; glTF, GLB and OBJ are',
				failed));
			return;
		}
		if (extension != ".glb" && extension != ".gltf" && extension != ".obj") {
			Runtime.later(() -> refuse("LoadModelAsync", '$path: only glTF, GLB and OBJ are read here', failed));
			return;
		}
		if (extension == ".obj")
			loadObjModel(fileName, loaded, failed);
		else
			loadGltfModel(fileName, loaded, failed);
	}

	// LoadModelAsync's call for a glTF or GLB file.
	static function loadGltfModel(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Models.isKept(path)) {
			Runtime.later(() -> loaded(RModels.loadModel(path)));
			return;
		}
		Runtime.modelling();
		Runtime.models.loadGltf(path, read -> {
			// raylib gives a mesh without joints whose node is a bone's child to that bone: the nodes are the file's, read again.
			if (read.skeleton != null && read.skins.length > 0 && Lambda.exists(read.meshes, m -> m.jointIndices == null)) {
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

	// LoadModelAsync's call for an OBJ file.
	static function loadObjModel(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Models.isKept(path)) {
			Runtime.later(() -> loaded(RModels.loadModel(path)));
			return;
		}
		loadObj(path, loaded, failed);
	}

	// An OBJ file, the last library its mtllib lines name (one that can't be read logged and left out) and that library's textures (one that
	// can't be, logged and left none), then its model kept for its loads.
	static function loadObj(path:String, loaded:Model->Void, failed:Null<String->Void>):Void {
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse("LoadModelAsync", error, failed);
				return;
			}
			// raylib reads an empty file as one it can't read.
			var bytes = Runtime.files.get(path);
			if (bytes.length == 0) {
				refuse("LoadModelAsync", '$path: Unable to read obj file', failed);
				return;
			}
			var obj = try ObjFile.read(bytes, path) catch (e:String) {
				refuse("LoadModelAsync", '$path: $e', failed);
				return;
			}
			function made(library:Null<MtlFile>):Void
				withTextures(library, () -> {
					var shader = defaultShader();
					Models.keepMade(path, ObjModels.template(obj, library), library != null && library.materials.length > 0 ? () ->
						ObjModels.materials(library, shader) : () -> [Models.defaultMaterial(shader)]);
					loaded(RModels.loadModel(path));
				});
			var libraryPath = ObjModels.libraryPath(obj);
			if (libraryPath == null)
				made(null);
			else
				readLibrary(libraryPath, made, message -> {
					Runtime.log(4, 'MODEL: [$path] $message');
					made(null);
				});
		});
	}

	// An MTL file read, or why it couldn't be.
	static function readLibrary(path:String, done:MtlFile->Void, failed:String->Void):Void {
		Runtime.fetch(path, error -> {
			if (error != null) {
				failed(error);
				return;
			}
			var library = try MtlFile.read(Runtime.files.get(path), path) catch (e:String) {
				failed('$path: $e');
				return;
			}
			done(library);
		});
	}

	// Each texture a library's materials name brought in (one that can't be, logged), then done.
	static function withTextures(library:Null<MtlFile>, done:Void->Void):Void {
		var paths = ObjModels.texturePaths(library), left = paths.length + 1;
		function one():Void
			if (--left == 0)
				done();
		for (p in paths)
			Runtime.fetch(p, error -> {
				if (error != null)
					Runtime.log(4, 'TEXTURE: $error');
				one();
			});
		one();
	}

	/** Loads the materials of an .mtl file, with the textures they name, answering when they are ready: helix-raylib's own, in place of
		raylib's `LoadMaterials`. Each is made as raylib's `ProcessMaterialsOBJ` makes it: raylib's default material, then its diffuse
		texture (`map_Kd`), or with none its diffuse color (`Kd`, alpha 255); its specular texture (`map_Ks`) and color (`Ks`); the
		normal map its bump texture (`bump` or `map_bump`), white, its value the specular exponent (`Ns`); its emission color (`Ke`); the
		height map its displacement texture (`disp`). What a material doesn't give is tinyobj_loader_c's default, as raylib has it: each
		color black, the specular exponent 1. A texture that can't be read is none (id 0, logged). The program holds each material until
		`UnloadMaterial`. Where raylib's reading is broken, helix-raylib reads the file as the format has it (a texture's path resolved
		against the file's directory among them), and a file that breaks the format fails (docs/DECISIONS.md 28).

		@param fileName  The file, as the program names it: an .mtl file.
		@param loaded  Receives the materials, in the file's order; their count is its length.
		@param failed  Optional. Receives why they couldn't be loaded (the file isn't an .mtl file, can't be found or can't be read); when
			omitted, it is logged. */
	static function LoadMaterialsAsync(fileName:String, loaded:Array<Material>->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (!StringTools.endsWith(path.toLowerCase(), ".mtl")) {
			Runtime.later(() -> refuse("LoadMaterialsAsync", '$path: only .mtl files are read here', failed));
			return;
		}
		readLibrary(path, library -> withTextures(library, () -> loaded(ObjModels.materials(library, defaultShader()))),
			error -> refuse("LoadMaterialsAsync", error, failed));
	}

	/** Loads a glTF or GLB file's animations, answering when they are read: helix-raylib's own, in place of raylib's
		`LoadModelAnimations`. They are read as raylib 6.2 reads them, of the file's first skin: each sampled 60 times a second, with
		(int)(duration * 60) + 1 frames, each frame's pose its bones' transforms in the model. A file without skins gives none. IQM and M3D
		animations aren't read (docs/DECISIONS.md 27).

		@param fileName  The file, as the program names it.
		@param loaded  Receives the animations, as many as the file has; their count is its length.
		@param failed  Optional. Receives why they couldn't be loaded; when omitted, it is logged. */
	static function LoadModelAnimationsAsync(fileName:String, loaded:Array<ModelAnimation>->Void, ?failed:String->Void):Void {
		var path = normalize(fileName), lower = path.toLowerCase();
		if (StringTools.endsWith(lower, ".iqm") || StringTools.endsWith(lower, ".m3d")) {
			Runtime.later(() -> refuse("LoadModelAnimationsAsync", '$path: ${lower.substr(-3).toUpperCase()} animations are not supported; glTF and GLB are',
				failed));
			return;
		}
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

	/** Loads a sound file and decodes it, answering when it is ready to play at once: helix-raylib's own, in place of raylib's `LoadSound`.
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

	// LoadWaveAsync's call (Extras.LoadWaveAsync): the file fetched, then read by read, the reader its extension names (WaveMacro).
	static function loadWave(fileName:String, read:WaveReader, loaded:Wave->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse("LoadWaveAsync", error, failed);
				return;
			}
			var bytes = Runtime.files.get(path);
			var type = GetFileExtension(fileName);
			read(type == null ? "" : type, bytes, wave -> loadedWave(wave, loaded), message -> refuse("LoadWaveAsync", '$path: $message', failed));
		});
	}

	// LoadWaveFromMemoryAsync's call (Extras.LoadWaveFromMemoryAsync): the bytes read by read, the reader fileType names (WaveMacro).
	static function loadWaveFromMemory(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, read:WaveReader, loaded:Wave->Void, ?failed:String->Void):Void {
		var data = fileData == null ? haxe.io.Bytes.alloc(0) : dataSize < fileData.length ? fileData.sub(0, Std.int(Math.max(0, dataSize))) : fileData;
		read(fileType == null ? "" : fileType, data, wave -> loadedWave(wave, loaded), message -> refuse("LoadWaveFromMemoryAsync", message, failed));
	}

	// A wave read, logged as raylib logs it.
	static function loadedWave(wave:Wave, loaded:Wave->Void):Void {
		Runtime.log(LOG_INFO, 'WAVE: Data loaded successfully (${wave.sampleRate} Hz, ${wave.sampleSize} bit, ${wave.channels} channels)');
		loaded(wave);
	}

	// The reader chosen as the program runs, for a file type known only then: raylib's, by the type as raylib compares it (lower or
	// upper case), so every reader is in the program.
	static function readWave(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void {
		var read:WaveReader = switch fileType {
			case ".wav" | ".WAV": readWav;
			case ".ogg" | ".OGG": readOgg;
			case ".mp3" | ".MP3": readMp3;
			case ".qoa" | ".QOA": readQoa;
			case _: readUnsupported;
		}
		read(fileType, data, done, failed);
	}

	// A file type raylib 5.5 doesn't read as it is built by default: FLAC among them (config.h leaves SUPPORT_FILEFORMAT_FLAC out).
	static function readUnsupported(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void
		Runtime.later(() -> failed("WAVE: Data format not supported"));

	// A WAV file, as dr_wav reads it for raylib: 16-bit samples at the file's rate and channels.
	static function readWav(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void {
		var wav = try helix.formats.wav.WavFile.read(data) catch (_:Dynamic) null;
		Runtime.later(() -> wav == null ? failed("WAVE: Failed to load WAV data") : done(new Wave(wav.frameCount, wav.sampleRate, 16, wav.channelCount,
			wav.toInt16())));
	}

	// A QOA file, as qoa.h reads it for raylib: 16-bit samples at the file's rate and channels.
	static function readQoa(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void {
		var qoa = try helix.formats.qoa.QoaFile.read(data) catch (_:Dynamic) null;
		Runtime.later(() -> qoa == null ? failed("WAVE: Failed to load QOA data") : done(new Wave(qoa.frameCount, qoa.sampleRate, 16, qoa.channelCount,
			qoa.samples)));
	}

	// An Ogg Vorbis file, decoded by the platform at the rate its header records and made 16-bit as stb_vorbis makes its floats for
	// raylib; its frames the stream's length as stb_vorbis reads it (the last page's position), a decoder that ends early (Chromium's)
	// padded with silence.
	static function readOgg(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void {
		var sampleRate = Waves.readSampleRate(data);
		if (sampleRate <= 0) {
			Runtime.later(() -> failed("WAVE: Failed to load OGG data"));
			return;
		}
		RAudio.audioDecoder().decode(data, sampleRate, (samples, channelCount) -> {
			var decoded = Std.int(samples.length / (4 * channelCount)),
				length = Math.round(helix.formats.audio.AudioHeader.readDuration(data, data.length) * sampleRate);
			var frames = length > 0 ? length : decoded;
			done(new Wave(frames, sampleRate, 16, channelCount, Waves.toInt16(samples, frames * channelCount)));
		}, message -> failed('WAVE: Failed to load OGG data: $message'));
	}

	// An MP3 file, decoded by the platform at the rate its first frame records, as dr_mp3 0.6.39 decodes it for raylib: every frame decoded, its Xing, Info
	// or VBRI frame as silence and its LAME delay and padding kept, as that dr_mp3 reads no tag, the tag hidden from the platform's
	// decoder (Waves.hideMp3Tag), which would trim them; its 16-bit samples made 32-bit floats (Waves.toMp3Floats).
	static function readMp3(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void {
		var file = Waves.hideMp3Tag(data),
			sampleRate = Waves.readSampleRate(data);
		if (sampleRate <= 0) {
			Runtime.later(() -> failed("WAVE: Failed to load MP3 data"));
			return;
		}
		RAudio.audioDecoder().decode(file, sampleRate, (samples, channelCount) -> {
			var floats = Waves.toMp3Floats(samples, channelCount, file, file != data);
			done(new Wave(Std.int(floats.length / (4 * channelCount)), sampleRate, 32, channelCount, floats));
		}, message -> failed('WAVE: Failed to load MP3 data: $message'));
	}

	/** Reads a text file, answering when it is read: helix-raylib's own, in place of raylib's `LoadFileText`. The program's
		`SetLoadFileTextCallback` answers first, then what `SaveFileText` wrote, then the program's files.

		A file's text ends at its first NUL byte, as raylib's C string does, and a byte that isn't UTF-8 is read as U+FFFD: a file is never
		refused for what it holds.

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

	/** Reads a file's bytes, answering when they are read: helix-raylib's own, in place of raylib's `LoadFileData`. The program's
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

	/** Loads an automation events list from a text file, answering when it is read: helix-raylib's own, in place of raylib's
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

	/** Answers whether a file exists: helix-raylib's own, in place of raylib's `FileExists`. One `SaveFileText` or `SaveFileData` wrote
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

	/** Answers a file's size: helix-raylib's own, in place of raylib's `GetFileLength`. A file `SaveFileText` or `SaveFileData` wrote, or
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

	/** Answers when a file was last written: helix-raylib's own, in place of raylib's `GetFileModTime`. Natively a file of the program's
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

	/** Answers whether a path is a file, not a directory: helix-raylib's own, in place of raylib's `IsPathFile`. A file `SaveFileText` or
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

	/** Answers whether a directory exists: helix-raylib's own, in place of raylib's `DirectoryExists`. Natively it is a directory of the
		program's files; `helix-raylib-dropped` and the directories under it hold the dropped files. A page's own files are on its server,
		which can't be listed, so there only its root ("", "." or "./") and the dropped files' directories exist. The answer comes at a later
		frame, never during the call.

		@param dirPath  The directory.
		@param answer  Receives true when it exists. */
	static function DirectoryExistsAsync(dirPath:String, answer:Bool->Void):Void {
		listOf(directoryOf(dirPath), names -> answer(names != null));
	}

	/** Lists a directory's files and subdirectories: helix-raylib's own, in place of raylib's `LoadDirectoryFiles`. Each path is the
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

	/** Lists a directory's files, those with some extensions, and with `scanSubdirs` its subdirectories' too: helix-raylib's own, in place
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

	// LoadFontAsync's call where its file's name isn't known as the program builds (Extras.LoadFontAsync): a GIF image's glyphs or the
	// other readers, picked by its extension as it runs, so the GIF reader is in the program.
	static function loadFont(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifFont(fileName, loaded, failed);
		else
			loadPlainFont(fileName, loaded, failed);
	}

	// LoadFontAsync's call for a GIF file: the glyphs of its first frame.
	static function loadGifFont(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
		loadGifImage(fileName, image -> loaded(imageFont(image)), message -> refuse("LoadFontAsync", message, failed));
	}

	// A font of an image's glyphs, as LoadFontAsync reads one.
	static function imageFont(image:Image):Font {
		var font = LoadFontFromImage(image, MAGENTA, 32);
		SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
		return font;
	}

	// LoadFontAsync's call for any other file.
	static function loadPlainFont(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
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
			loadPlainImage(path, image -> loaded(imageFont(image)), message -> refuse("LoadFontAsync", message, failed));
			return;
		}
		if (type != "ttf" && type != "otf") {
			Runtime.later(() -> refuse("LoadFontAsync", '$path: .$type fonts aren\'t in helix-raylib yet', failed));
			return;
		}
		LoadFontExAsync(path, 32, null, 95, font -> {
			SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
			loaded(font);
		}, failed);
	}

	/** Loads a TrueType or OpenType font file at a size, answering when its glyphs are ready: helix-raylib's own, in place of raylib's
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

	/** Makes a font from a TrueType or OpenType file's bytes, answering when its glyphs are ready: helix-raylib's own, in place of raylib's
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
			Runtime.later(() -> refuse("LoadFontFromMemoryAsync", '$fileType fonts aren\'t in helix-raylib yet', failed));
			return;
		}
		var count = codepointCount > 0 ? codepointCount : 95;
		var wanted = codepoints == null ? [for (i in 0...count) 32 + i] : codepoints.slice(0, count);
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.fonts()
			.rasterize(data, fontSize, wanted, (glyphs, ascent, _, _) -> loaded(RText.fontOf(RText.foundGlyphs(glyphs, ascent, fontSize), fontSize)),
				message -> refuse("LoadFontFromMemoryAsync", message, failed));
	}

	/** Rasterizes a TrueType or OpenType font's glyphs, answering when they are ready: helix-raylib's own, in place of raylib's
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
		var fonts = Runtime.fonts();
		// raylib's type is a value the program passes as it runs, so each kind's rasterizing is in the program that calls it.
		var rasterize = type == FONT_SDF ? fonts.rasterizeDistanceField : type == FONT_BITMAP ? fonts.rasterizeBitmap : fonts.rasterize;
		rasterize(data, fontSize, wanted, (glyphs, ascent, _, _) -> loaded(RText.fontData(glyphs, ascent, fontSize, type)),
			message -> refuse("LoadFontDataAsync", message, failed));
	}

	// LoadImageAsync's call where its file's name isn't known as the program builds (Extras.LoadImageAsync): a GIF file's first frame
	// or the other decodes, picked by its extension as it runs, so both are in the program.
	static function loadImage(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifImage(fileName, loaded, failed);
		else
			loadPlainImage(fileName, loaded, failed);
	}

	// LoadImageAsync's call for a GIF file: its first frame, kept as the file's image.
	static function loadGifImage(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		gifFile("LoadImageAsync", path, () -> {
			var image = Runtime.image(path);
			loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height));
		}, failed);
	}

	// Brings a GIF file into memory, its first frame composited as raylib 5.5's LoadImage reads it (gifFrames) and kept as the file's
	// image (Runtime.images), then calls done; a file that can't be read or is no GIF is refused for the load named.
	static function gifFile(name:String, path:String, done:Void->Void, failed:Null<String->Void>):Void {
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse(name, error, failed);
				return;
			}
			if (!Runtime.images.exists(path)) {
				var frame = gifFrames(name, path, Runtime.files.get(path), false, failed);
				if (frame == null)
					return;
				Runtime.images.set(path, new helix.services.images.Image(path, frame.width, frame.height, frame.data));
			}
			done();
		});
	}

	// LoadImageAsync's call for any other file.
	static function loadPlainImage(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
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

	/** Loads an image's raw pixels from a file, answering when they are read: helix-raylib's own, in place of raylib's `LoadImageRaw`. The
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

	// LoadImageFromMemoryAsync's call where its type isn't known as the program builds (Extras.LoadImageFromMemoryAsync): raylib's two
	// spellings of ".gif" read as GIF, any other type decoded as the rest are, so both are in the program.
	static function decodeImage(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileType == ".gif" || fileType == ".GIF")
			decodeGifImage(fileType, fileData, dataSize, loaded, failed);
		else
			decodePlainImage(fileType, fileData, dataSize, loaded, failed);
	}

	// LoadImageFromMemoryAsync's call for a GIF file's bytes: its first frame.
	static function decodeGifImage(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.later(() -> {
			var frame = gifFrames("LoadImageFromMemoryAsync", "IMAGE", data, false, failed);
			if (frame != null)
				loaded(frame);
		});
	}

	// LoadImageFromMemoryAsync's call for any other type.
	static function decodePlainImage(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.imaging();
		Runtime.later(() -> decoded("LoadImageFromMemoryAsync", fileType == null ? "" : fileType.toLowerCase(), data, loaded, failed));
	}

	// LoadImageAnimAsync's call where its file's name isn't known as the program builds (Extras.LoadImageAnimAsync): the GIF reader or
	// the image load picked by its extension as it runs, so both are in the program.
	static function loadImageAnim(fileName:String, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifAnim(fileName, frames, loaded, failed);
		else
			loadStillAnim(fileName, frames, loaded, failed);
	}

	// LoadImageAnimAsync's call for a GIF file.
	static function loadGifAnim(fileName:String, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> {
			if (error != null)
				refuse("LoadImageAnimAsync", error, failed);
			else
				gifAnim("LoadImageAnimAsync", path, Runtime.files.get(path), frames, loaded, failed);
		});
	}

	// LoadImageAnimAsync's call for any other file: the image, one frame.
	static function loadStillAnim(fileName:String, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		loadPlainImage(fileName, image -> {
			frames[0] = 1;
			loaded(image);
		}, error -> refuse("LoadImageAnimAsync", error, failed));
	}

	// LoadImageAnimFromMemoryAsync's call where its type isn't known as the program builds: raylib's two spellings of ".gif" read as GIF.
	static function decodeImageAnim(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileType == ".gif" || fileType == ".GIF")
			decodeGifAnim(fileType, fileData, dataSize, frames, loaded, failed);
		else
			decodeStillAnim(fileType, fileData, dataSize, frames, loaded, failed);
	}

	// LoadImageAnimFromMemoryAsync's call for a GIF file's bytes.
	static function decodeGifAnim(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageAnimFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.later(() -> gifAnim("LoadImageAnimFromMemoryAsync", "IMAGE", data, frames, loaded, failed));
	}

	// LoadImageAnimFromMemoryAsync's call for any other type: the image, one frame.
	static function decodeStillAnim(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		decodePlainImage(fileType, fileData, dataSize, image -> {
			frames[0] = 1;
			loaded(image);
		}, error -> refuse("LoadImageAnimFromMemoryAsync", error, failed));
	}

	// A GIF file's frames, as raylib 5.5's LoadImageAnim gives them (gifFrames), and their count.
	static function gifAnim(name:String, what:String, data:haxe.io.Bytes, frames:Array<Int>, loaded:Image->Void, failed:Null<String->Void>):Void {
		var all = gifFrames(name, what, data, true, failed);
		if (all == null)
			return;
		frames[0] = Std.int(all.data.length / (all.width * all.height * 4));
		loaded(all);
	}

	// A broken GIF file's frames before its break, as stb_image keeps them: the most frames that read (GifFile.read's limit), or null
	// when not even the first does.
	static function gifBefore(data:haxe.io.Bytes):Null<helix.formats.gif.GifFile> {
		var read:Null<helix.formats.gif.GifFile> = null;
		while (true) {
			var count = read == null ? 1 : read.frames.length + 1;
			var next = try helix.formats.gif.GifFile.read(data, count) catch (e:String) null;
			if (next == null || next.frames.length < count)
				return read;
			read = next;
		}
	}

	// A GIF file's frames as one image, the screen's size, each frame after the last, composited as raylib 5.5 composites them
	// (stb_image's GIF reader): every frame (LoadImageAnim) or the first alone (LoadImage). As stb, the first alone is read with
	// nothing after it, and every frame of a file broken after some are those before the break (gifBefore), so a file broken after its
	// first frame loads it. helix-formats reads the file; the frames are drawn here by stb's rules. The screen starts transparent. Before each frame, a last frame disposed of to the background or the
	// previous frame has its rectangle put back as it was before it was drawn (stb restores both so, and for Previous from the third
	// frame on reads before its own buffer: docs/DECISIONS.md 24). After the first frame, when the background index isn't 0, the
	// pixels outside its rectangle take the global table's color there, opaque, its bytes in stb's palette order (blue, green, red), or
	// opaque black where the table has none. A file that can't be read, or has no frames, is refused for the load named, giving null.
	static function gifFrames(name:String, what:String, data:haxe.io.Bytes, all:Bool, failed:Null<String->Void>):Null<Image> {
		var gif = try helix.formats.gif.GifFile.read(data, all ? null : 1) catch (e:String) {
			var before = all ? gifBefore(data) : null;
			if (before == null) {
				refuse(name, '$what: $e', failed);
				return null;
			}
			before;
		}
		var width = gif.width,
			height = gif.height,
			size = width * height * 4,
			count = gif.frames.length;
		if (count == 0 || size * 1.0 * count > 0x7FFFFFFF) {
			refuse(name, count == 0 ? '$what: a GIF file with no frames' : '$what: $count frames of $width x $height pixels, over 2 GB', failed);
			return null;
		}
		var pixels = haxe.io.Bytes.alloc(size * count),
			screen = haxe.io.Bytes.alloc(size),
			before = haxe.io.Bytes.alloc(size);
		for (n in 0...count) {
			var frame = gif.frames[n];
			if (n > 0) {
				var last = gif.frames[n - 1];
				if (last.disposal == helix.formats.gif.GifDisposal.Background || last.disposal == helix.formats.gif.GifDisposal.Previous)
					for (row in last.y...last.y + last.height)
						screen.blit((row * width + last.x) * 4, before, (row * width + last.x) * 4, last.width * 4);
			}
			before.blit(0, screen, 0, size);
			var colors = frame.colors, i = 0;
			for (row in 0...frame.height) {
				var p = ((frame.y + row) * width + frame.x) * 4;
				for (_ in 0...frame.width) {
					var index = frame.indices.get(i++);
					if (index != frame.transparentIndex && index < colors.length) {
						var color = colors[index];
						screen.set(p, (color >> 16) & 0xFF);
						screen.set(p + 1, (color >> 8) & 0xFF);
						screen.set(p + 2, color & 0xFF);
						screen.set(p + 3, 255);
					}
					p += 4;
				}
			}
			if (n == 0 && gif.backgroundIndex > 0) {
				var color = gif.colors != null && gif.backgroundIndex < gif.colors.length ? gif.colors[gif.backgroundIndex] : 0xFF000000;
				for (y in 0...height)
					for (x in 0...width)
						if (x < frame.x || x >= frame.x + frame.width || y < frame.y || y >= frame.y + frame.height) {
							var p = (y * width + x) * 4;
							screen.set(p, color & 0xFF);
							screen.set(p + 1, (color >> 8) & 0xFF);
							screen.set(p + 2, (color >> 16) & 0xFF);
							screen.set(p + 3, 255);
						}
			}
			pixels.blit(n * size, screen, 0, size);
		}
		return rgba(pixels, width, height);
	}

	/** Reads a texture's pixels, answering when they are read: helix-raylib's own, in place of raylib's `LoadImageFromTexture`, as the GPU
		answers later. A texture on the GPU (one drawn, or a render texture) is read back from it as the frames drawn so far left it; a
		render texture's rows come bottom first, as raylib's do, so it reads upside down as raylib's does. A texture updated this frame
		(`UpdateTexture`) is read once the frame is drawn, so the update shows. One not drawn yet is read from memory (raylib's default
		texture is its white pixel). The image is RGBA, whatever the texture's format. A cubemap's can't be read.

		@param texture  The texture.
		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image->Void, ?failed:String->Void):Void {
		var gpu = Textures.isCube(texture.id) ? 0 : Textures.onGpu(texture.id);
		if (gpu == 0) {
			var image = Textures.imageOf(texture.id);
			Runtime.later(() -> image == null ? refuse("LoadImageFromTextureAsync", 'TEXTURE: [ID ${texture.id}] Failed to retrieve pixel data',
				failed) : loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height)));
			return;
		}
		function read():Void {
			var during = true;
			Runtime.graphics.readPixels(gpu, (pixels, width, height) -> {
				var image = rgba(pixels, width, height);
				if (texture.flipped)
					ImageFlipVertical(image);
				Runtime.log(LOG_INFO, 'TEXTURE: [ID ${texture.id}] Pixel data retrieved successfully');
				during ? Runtime.later(() -> loaded(image)) : loaded(image);
			},
				error -> during ? Runtime.later(() -> refuse("LoadImageFromTextureAsync", error, failed)) : refuse("LoadImageFromTextureAsync", error, failed));
			during = false;
		}
		if (Runtime.frame.isUpdating(gpu))
			Runtime.frame.afterDraw(read);
		else
			read();
	}

	/** Reads the screen, answering as the next frame ends: helix-raylib's own, in place of raylib's `LoadImageFromScreen`, as the GPU
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

	/** Reads the clipboard's text, answering at a later poll: helix-raylib's own, in place of raylib's `GetClipboardText`, as a page's
		clipboard answers later. A page reads it only with the player's permission, which the browser may ask for.

		@param read  Receives the text; "" when the clipboard holds none.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardTextAsync(read:String->Void, ?failed:String->Void):Void {
		Runtime.clipboard().requestText(read, error -> refuse("GetClipboardTextAsync", error, failed));
	}

	/** Reads the clipboard's image, answering at a later poll once it is decoded: helix-raylib's own, in place of raylib's
		`GetClipboardImage`. A page reads it only with the player's permission.

		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged. */
	static function GetClipboardImageAsync(loaded:Image->Void, ?failed:String->Void):Void {
		Runtime.imaging();
		Runtime.clipboard()
			.requestImage(png -> decoded("GetClipboardImageAsync", ".png", png, loaded, failed), error -> refuse("GetClipboardImageAsync", error, failed));
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

	// Whether a file's extension is .gif, in any case.
	static function isGif(fileName:String):Bool {
		return haxe.io.Path.extension(normalize(fileName)).toLowerCase() == "gif";
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
			loaded(new Image(qoi.pixels, qoi.width, qoi.height, 1,
				qoi.channelCount == 4 ? PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 : PIXELFORMAT_UNCOMPRESSED_R8G8B8));
			return;
		}
		if (!isDecoded(fileType.substr(1))) {
			refuse(name, 'IMAGE: Data format not supported: $fileType', failed);
			return;
		}
		Runtime.decoding.decode(data, image -> loaded(rgba(image.pixels, image.width, image.height)), error -> refuse(name, error, failed));
	}

	// ---- The async window requests: helix-raylib's own, not raylib's ----

	/** Asks for fullscreen, or back to the window, the size and place it had, answering once it is granted or refused: helix-raylib's
		own, in place of raylib's `ToggleFullscreen`. In a page the browser grants it only soon after a key press, click or tap; without
		one, it waits for the player's next, or refuses. `IsWindowFullscreen` says the new state once the window has changed, not when
		the call returns.

		@param done  Optional. Called once the window has changed, at a later poll.
		@param failed  Optional. Receives why it was refused; when omitted, it is logged. */
	static function ToggleFullscreenAsync(?done:Void->Void, ?failed:String->Void):Void {
		toggleFullscreen("ToggleFullscreenAsync", false, done, failed);
	}

	/** Asks for the window to fill the screen without borders, or back to the window, answering once it is granted or refused:
		helix-raylib's own, in place of raylib's `ToggleBorderlessWindowed`. The screen is asked for fullscreen, as a fullscreen window
		natively is borderless and the size of the desktop. As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it
		is, and `IsWindowFullscreen` false.

		@param done  Optional. Called once the window has changed, at a later poll.
		@param failed  Optional. Receives why it was refused; when omitted, it is logged. */
	static function ToggleBorderlessWindowedAsync(?done:Void->Void, ?failed:String->Void):Void {
		toggleFullscreen("ToggleBorderlessWindowedAsync", true, done, failed);
	}

	// Asks the screen for fullscreen, or borderless, or the window when it is that already. A fullscreen screen asked for the other of
	// the two only changes which it is. A refusal, or a window that can't be fullscreen, is refused for the request named.
	static function toggleFullscreen(name:String, borderless:Bool, done:Null<Void->Void>, failed:Null<String->Void>):Void {
		var screen = Runtime.screen;
		var leaving = screen.fullscreen && Runtime.borderless == borderless;
		if (screen.fullscreen && !leaving) {
			Runtime.borderless = borderless;
			Runtime.later(answered(done));
			return;
		}
		ask(name, (granted, refused) -> screen.requestFullscreen(!leaving, () -> {
			Runtime.borderless = borderless && !leaving;
			granted();
		}, refused), "the window can't be fullscreen here", done, failed);
	}

	/** Asks for the window's size, answering once the window manager has resized it or refused: helix-raylib's own, in place of raylib's
		`SetWindowSize`. The window manager may give another size, which `GetScreenWidth` and `GetScreenHeight` say once it has. A
		fullscreen or maximized window keeps its size, and a page's canvas follows the page, so those are refused.

		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param done  Optional. Called once the window has a size from the request, at a later poll.
		@param failed  Optional. Receives why it wasn't resized; when omitted, it is logged. */
	static function SetWindowSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowSizeAsync", (granted, refused) -> Runtime.window.requestSize(width, height, granted, refused), '$width x $height is under 1 pixel',
			done, failed);
	}

	/** Asks for the window's place on the desktop, answering once it has moved or the move is refused: helix-raylib's own, in place of
		raylib's `SetWindowPosition`. Where the window can't be moved (in a page, or under Wayland), or while it is fullscreen or
		maximized, it is refused.

		@param x  The left edge, in pixels.
		@param y  The top edge, in pixels.
		@param done  Optional. Called once the window has moved, at a later poll.
		@param failed  Optional. Receives why it didn't move; when omitted, it is logged. */
	static function SetWindowPositionAsync(x:Int, y:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowPositionAsync", (granted, refused) -> Runtime.window.requestPosition(x, y, granted, refused), "", done, failed);
	}

	/** Asks for the window on another monitor, answering once it is there or the move is refused: helix-raylib's own, in place of raylib's
		`SetWindowMonitor`. Where the window can't be moved, a monitor other than its own is refused.

		@param monitor  The monitor, 0 to `GetMonitorCount() - 1`.
		@param done  Optional. Called once the window is on the monitor, at a later poll.
		@param failed  Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged. */
	static function SetWindowMonitorAsync(monitor:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMonitorAsync", (granted, refused) -> Runtime.window.requestMonitorIndex(monitor, granted, refused), 'there is no monitor $monitor',
			done, failed);
	}

	/** Asks for the window maximized, answering once it is or the window manager refuses: helix-raylib's own, in place of raylib's
		`MaximizeWindow`. A page can't maximize its window, so it is refused there.

		@param done  Optional. Called once the window is maximized, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MaximizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MaximizeWindowAsync", (granted, refused) -> Runtime.window.requestMaximized(true, granted, refused), "", done, failed);
	}

	/** Asks for the window minimized, answering once it is or the window manager refuses: helix-raylib's own, in place of raylib's
		`MinimizeWindow`. A page can't minimize its window, so it is refused there.

		@param done  Optional. Called once the window is minimized, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function MinimizeWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("MinimizeWindowAsync", (granted, refused) -> Runtime.window.requestMinimized(true, granted, refused), "", done, failed);
	}

	/** Asks for the window back to its size from minimized or maximized, answering once it is or the window manager refuses:
		helix-raylib's own, in place of raylib's `RestoreWindow`.

		@param done  Optional. Called once the window is restored, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function RestoreWindowAsync(?done:Void->Void, ?failed:String->Void):Void {
		var window = Runtime.window;
		ask("RestoreWindowAsync",
			(granted, refused) -> window.minimized ? window.requestMinimized(false, granted, refused) : window.requestMaximized(false, granted, refused), "",
			done, failed);
	}

	/** Asks for the window brought to the front with the keyboard, answering once it has the keyboard or the window manager keeps it
		elsewhere: helix-raylib's own, in place of raylib's `SetWindowFocused`. A window manager may only flash it; in a page the canvas
		takes the keyboard.

		@param done  Optional. Called once the window has the keyboard, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowFocusedAsync(?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowFocusedAsync", (granted, refused) -> Runtime.window.requestFocus(granted, refused), "", done, failed);
	}

	/** Asks for the window see-through, answering once it is or it is refused: helix-raylib's own, in place of raylib's
		`SetWindowOpacity`. In a page the canvas fades; a desktop without a compositor refuses it.

		@param opacity  From 0 (clear) to 1 (opaque).
		@param done  Optional. Called once the window has the opacity, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowOpacityAsync(opacity:Float, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowOpacityAsync", (granted, refused) -> Runtime.window.requestOpacity(opacity, granted, refused), "", done, failed);
	}

	/** Asks for the smallest size the player can make the window, answering once it has it or it is refused: helix-raylib's own, in place
		of raylib's `SetWindowMinSize`. A page's canvas follows the page, so it is refused there.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMinSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMinSizeAsync", (granted, refused) -> Runtime.window.requestMinimumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	/** Asks for the largest size the player can make the window, answering once it has it or it is refused: helix-raylib's own, in place
		of raylib's `SetWindowMaxSize`. A page's canvas follows the page, so it is refused there.

		@param width  The width, in the screen's pixels.
		@param height  The height.
		@param done  Optional. Called once the window has the limit, at a later poll.
		@param failed  Optional. Receives why it hasn't; when omitted, it is logged. */
	static function SetWindowMaxSizeAsync(width:Int, height:Int, ?done:Void->Void, ?failed:String->Void):Void {
		ask("SetWindowMaxSizeAsync", (granted, refused) -> Runtime.window.requestMaximumSize(width, height, granted, refused),
			'$width x $height is under 0 pixels', done, failed);
	}

	// ---- The async cursor lock and clipboard: helix-raylib's own, not raylib's ----

	/** Locks the mouse to the window and hides the cursor, for looking around, answering once it is locked or refused: helix-raylib's own,
		in place of raylib's `DisableCursor`. `GetMouseDelta` keeps coming while the position goes on past the window's edges. In a page
		the browser locks it only soon after a click or key press, so without one it locks at the player's next, and Escape lets it go.
		`IsCursorHidden` is true from the call.

		@param done  Optional. Called once the mouse is locked, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function DisableCursorAsync(?done:Void->Void, ?failed:String->Void):Void {
		Runtime.mouse();
		var mouse = Runtime.mouseAdapter;
		ask("DisableCursorAsync", (granted, refused) -> mouse.requestLock(true, granted, refused), "the mouse can't be locked here", done, failed);
		RCore.cursorHidden = true;
	}

	/** Lets go of the mouse that `DisableCursorAsync` locked, and shows the cursor, answering once it is let go: helix-raylib's own, in
		place of raylib's `EnableCursor`.

		@param done  Optional. Called once the mouse is let go, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function EnableCursorAsync(?done:Void->Void, ?failed:String->Void):Void {
		Runtime.mouse();
		var mouse = Runtime.mouseAdapter;
		ask("EnableCursorAsync", (granted, refused) -> mouse.requestLock(false, granted, refused), "the mouse can't be let go here", done, failed);
		mouse.cursorVisible = true;
		RCore.cursorHidden = false;
	}

	/** Puts text on the system's clipboard, answering once it is there or refused: helix-raylib's own, in place of raylib's
		`SetClipboardText`. A page writes it only while it has the keyboard, soon after a press.

		@param text  The text.
		@param done  Optional. Called once the text is on the clipboard, at a later poll.
		@param failed  Optional. Receives why it isn't; when omitted, it is logged. */
	static function SetClipboardTextAsync(text:String, ?done:Void->Void, ?failed:String->Void):Void {
		var clipboard = Runtime.clipboard();
		ask("SetClipboardTextAsync", (granted, refused) -> {
			clipboard.setText(text, granted, refused);
			return true;
		}, "", done, failed);
	}

	// ---- The async writes: helix-raylib's own, not raylib's ----

	/** Writes a text file, answering once it is kept or refused: helix-raylib's own, in place of raylib's `SaveFileText`. It is written
		through the program's `SetSaveFileTextCallback` when it has one, during the call, answered by what that returned. Otherwise it is
		answered once the write has finished. The save file persists between runs, including both native and web builds. `LoadFileTextAsync` reads
		it back.

		@param fileName  The file.
		@param text  Its text.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function SaveFileTextAsync(fileName:String, text:String, ?done:Void->Void, ?failed:String->Void):Void {
		RCore.writeText(fileName, text, answered(done), error -> refuse("SaveFileTextAsync", error, failed));
	}

	/** Writes a file's bytes, answering once they are kept or refused: helix-raylib's own, in place of raylib's `SaveFileData`. They are
		written through the program's `SetSaveFileDataCallback` when it has one, else kept across runs as `SaveFileTextAsync`'s are.
		`LoadFileDataAsync` reads them back.

		@param fileName  The file.
		@param data  The bytes.
		@param dataSize  How many of them.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function SaveFileDataAsync(fileName:String, data:haxe.io.Bytes, dataSize:Int, ?done:Void->Void, ?failed:String->Void):Void {
		RCore.writeData(fileName, data, dataSize, answered(done), error -> refuse("SaveFileDataAsync", error, failed));
	}

	/** Writes bytes as a C header through `SaveFileTextAsync`, as raylib's `ExportDataAsCode` does, byte for byte: their count as a
		define, and the bytes as an array, in hexadecimal, 20 a line. helix-raylib's own, answering once the file is written.

		@param data  The bytes.
		@param dataSize  How many of them.
		@param fileName  The file; its name, upper case, names the define and the array, with `_` for `.`, `-`, `?`, `!` and `+`.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportDataAsCodeAsync(data:haxe.io.Bytes, dataSize:Int, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportDataAsCodeAsync", fileName, RCore.dataAsCode(data, dataSize, fileName), "Data as code exported successfully", done, failed);
	}

	/** Writes a list's events as text through `SaveFileTextAsync`, as raylib's `ExportAutomationEventList` does, byte for byte: a header
		of comments, `c` and the count, then a line for each event, `e`, its frame, type and four parameters, and its type's name.
		helix-raylib's own, answering once the file is written.

		@param list  The list.
		@param fileName  The file.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportAutomationEventListAsync(list:AutomationEventList, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportAutomationEventListAsync", fileName, RCore.automationText(list), null, done, failed);
	}

	/** Writes an image to a file through `SaveFileDataAsync`, as raylib's default build's `ExportImage` writes it: ".png" (any
		uncompressed format; a format other than 8-bit grayscale, grayscale and alpha, RGB or RGBA is written as RGBA), ".qoi" (RGB or
		RGBA alone) or ".raw" (the pixels as they are). helix-raylib's own, answering once the file is written. The file is kept as
		`SaveFileDataAsync` keeps it; `TakeScreenshotAsync` writes a real file.

		@param image  The image.
		@param fileName  The file; its extension chooses the format.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't, such as an empty image or another extension; when omitted, it is logged. */
	static function ExportImageAsync(image:Image, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		var file = image.width == 0 || image.height == 0 || image.data == null ? null : RTextures.encodeImage(image, fileName);
		exportData("ExportImageAsync", fileName, file, "Image exported successfully", "Failed to export image", done, failed);
	}

	/** Writes an image as a C header through `SaveFileTextAsync`, as raylib's `ExportImageAsCode` does: its size and format as defines,
		and its pixels (the first level's) as an array of bytes, 20 a line. helix-raylib's own, answering once the file is written.

		@param image  The image.
		@param fileName  The file; its name, upper case, names the defines and the array.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportImageAsCodeAsync(image:Image, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportImageAsCodeAsync", fileName, RTextures.imageAsCode(image, fileName), "Image as code exported successfully", done, failed);
	}

	/** Writes a font as a C header through `SaveFileTextAsync`, the text raylib 5.5's `ExportFontAsCode` writes: its texture's pixels in
		the texture's format (gray and alpha for the default font and a TrueType font's), compressed as `CompressData` compresses them,
		20 bytes a line; each glyph's rectangle and its character, offsets and advance; and a function loading it. The file's name, in
		Pascal case, names them. The pixels are those the font's texture was made from, or the texture's own while it hasn't been drawn;
		one made otherwise and already on the GPU (a render texture's) is written as an empty image, as raylib writes a texture it can't
		read back. helix-raylib's own, answering once the file is written.

		@param font  The font.
		@param fileName  The file.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportFontAsCodeAsync(font:Font, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportFontAsCodeAsync", fileName, RText.fontAsCode(font, fileName), "Font as code exported successfully", done, failed);
	}

	/** Writes a mesh as an OBJ file through `SaveFileTextAsync`, as raylib's `ExportMesh` does: its positions and texture coordinates to
		6 places, its normals to 4, and a face a triangle. helix-raylib's own, answering once the file is written.

		@param mesh  The mesh, with positions, texture coordinates and normals.
		@param fileName  The file; only ".obj" is written.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't, such as another extension; when omitted, it is logged. */
	static function ExportMeshAsync(mesh:Mesh, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		if (!IsFileExtension(fileName, ".obj"))
			Runtime.later(() -> refuse("ExportMeshAsync", '$fileName: only .obj files are written', failed));
		else
			exportText("ExportMeshAsync", fileName, RModels.meshObj(mesh), null, done, failed);
	}

	/** Writes a mesh as a C header through `SaveFileTextAsync`, as raylib's `ExportMeshAsCode` does: its counts as defines, and each
		array it has, 20 values a line, floats to 3 places. helix-raylib's own, answering once the file is written.

		@param mesh  The mesh.
		@param fileName  The file; its name, upper case, names the defines and the arrays.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportMeshAsCodeAsync(mesh:Mesh, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportMeshAsCodeAsync", fileName, RModels.meshAsCode(mesh, fileName), null, done, failed);
	}

	/** Writes a wave to a file through `SaveFileDataAsync`, as raylib's `ExportWave` does: ".wav" (8, 16 and 24 bits as integers, 32 as
		floats, as raylib's dr_wav writes them) or ".raw" (the samples as they are). raylib's ".qoa" isn't written here. helix-raylib's own,
		answering once the file is written; the file is kept as `SaveFileDataAsync` keeps it.

		@param wave  The wave.
		@param fileName  The file; its extension chooses the format.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't, such as a wave with no samples or another extension; when omitted, it is logged. */
	static function ExportWaveAsync(wave:Wave, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportData("ExportWaveAsync", fileName, RAudio.waveFile(wave, fileName), "Wave data exported successfully", "Failed to export wave data", done, failed);
	}

	/** Writes a wave as a C header through `SaveFileTextAsync`, as raylib's `ExportWaveAsCode` does: its frames, rate, sample size and
		channels as defines, and its samples as an array: floats with 4 places for 32-bit samples, else bytes, 20 a line. helix-raylib's
		own, answering once the file is written.

		@param wave  The wave.
		@param fileName  The file; its name, upper case, names the defines and the array.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportWaveAsCodeAsync(wave:Wave, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportWaveAsCodeAsync", fileName, RAudio.waveAsCode(wave, fileName), "Wave as code exported successfully", done, failed);
	}

	/** Takes a screenshot of the next frame and hands it to the user as a file, as `ExportImageAsync` writes it by the name's extension
		(".png", ".qoi" or ".raw"), answering once it is saved or refused: helix-raylib's own, in place of raylib's `TakeScreenshot`. In a
		page it is downloaded under the name's file name, as raylib's web build does; natively it is written where the name says, as
		raylib 6.2 writes it: a relative name under the working directory, its directories kept, and an absolute one where it is. A
		directory that isn't there isn't made, and the screenshot isn't saved. raylib's is taken from the frame drawn last, before it is
		shown; this one is taken as the next frame ends, when its pixels can be read back. Its alpha is opaque, as raylib's is.

		@param fileName  The file's name, or its path; a name with `'` is refused, as raylib's is.
		@param done  Optional. Called once the file is written or downloaded, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function TakeScreenshotAsync(fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		var refused = (error:String) -> refuse("TakeScreenshotAsync", error, failed);
		if (fileName.indexOf("'") >= 0) {
			Runtime.later(() -> refused('$fileName: Provided fileName could be potentially malicious, avoid [\'] character'));
			return;
		}
		var name = GetFileName(fileName);
		var exporter = Runtime.exporter();
		#if !js
		// raylib 6.2's: a relative name under the working directory, an absolute one as it is.
		var slash = lastSlash(fileName);
		if (slash >= 0) {
			var directory = fileName.substr(0, slash == 0 ? 1 : slash);
			if (!isPathAbsolute(fileName))
				directory = haxe.io.Path.join([Sys.getCwd(), directory]);
			if (!sys.FileSystem.exists(directory) || !sys.FileSystem.isDirectory(directory)) {
				Runtime.later(() -> refused('$fileName: Screenshot could not be saved: $directory isn\'t a directory'));
				return;
			}
			exporter = new helix.platform.adapters.export.filesystem.FileSystemExportAdapter({directory: directory});
		}
		#end
		if (Runtime.frame == null) {
			Runtime.later(() -> refused('$name: Screenshot could not be saved: InitWindow first'));
			return;
		}
		Runtime.screenshots().captureFrame(captured -> {
			var pixels = captured.pixels;
			for (i in 0...captured.width * captured.height)
				pixels.set(i * 4 + 3, 255);
			var file = RTextures.encodeImage(new Image(pixels, captured.width, captured.height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8), name);
			if (file == null) {
				refused('$name: Screenshot could not be saved: only .png, .qoi and .raw files are written');
				return;
			}
			var type = IsFileExtension(name, ".png") ? "image/png" : IsFileExtension(name, ".qoi") ? "image/qoi" : "application/octet-stream";
			exporter.export(name, type, file, where -> {
				Runtime.log(LOG_INFO, 'FILEIO: [$where] Image exported successfully');
				Runtime.log(LOG_INFO, 'SYSTEM: [$where] Screenshot taken successfully');
				if (done != null)
					done();
			}, error -> refused('$name: Screenshot could not be saved: $error'));
		}, error -> refused('$name: Screenshot could not be saved: $error'));
	}

	// Writes an export's text through SaveFileTextAsync's writing, logging raylib's line when it is written, as raylib's export does.
	static function exportText(name:String, fileName:String, text:String, success:Null<String>, done:Null<Void->Void>, failed:Null<String->Void>):Void {
		RCore.writeText(fileName, text, () -> {
			if (success != null)
				Runtime.log(LOG_INFO, 'FILEIO: [$fileName] $success');
			if (done != null)
				done();
		}, error -> refuse(name, error, failed));
	}

	// Writes an export's file through SaveFileDataAsync's writing, as exportText does; a file that couldn't be made is refused.
	static function exportData(name:String, fileName:String, file:Null<haxe.io.Bytes>, success:String, failure:String, done:Null<Void->Void>,
			failed:Null<String->Void>):Void {
		if (file == null) {
			Runtime.later(() -> refuse(name, '$fileName: $failure', failed));
			return;
		}
		RCore.writeData(fileName, file, file.length, () -> {
			Runtime.log(LOG_INFO, 'FILEIO: [$fileName] $success');
			if (done != null)
				done();
		}, error -> refuse(name, error, failed));
	}

	// Asks the platform, answering as it does, at a later poll. A request it can't ask is refused at a later poll, saying why not.
	static function ask(name:String, asking:(granted:Void->Void, refused:String->Void)->Bool, why:String, done:Null<Void->Void>,
			failed:Null<String->Void>):Void {
		if (!asking(answered(done), error -> refuse(name, error, failed)))
			Runtime.later(() -> refuse(name, why, failed));
	}

	// A write's done, which may be omitted.
	static function answered(done:Null<Void->Void>):Void->Void {
		return () -> if (done != null) done();
	}

	// Answers a load, a request or a write that failed: to the program's failed callback, or logged. Every error names the file, as the services' do.
	static function refuse(name:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			Runtime.log(4, '$name: $error');
	}
	#end
}
