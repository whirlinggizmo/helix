package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Animations;
import helix.ray.internal.Models;
import helix.ray.internal.ObjModels;
import helix.formats.obj.MtlFile;
import helix.formats.obj.ObjFile;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.internal.CallbackFiles;
import helix.ray.internal.WaveReader;
import helix.ray.internal.Waves;
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
	// LoadTextureAsync's call where its file's name isn't known as the program builds (Raylib.LoadTextureAsync): a GIF file's first
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

	// LoadModelAsync's call where its file's name isn't known as the program builds (Raylib.LoadModelAsync): the reader picked by its
	// extension as it runs, so both readers are in the program. A format helix-ray doesn't read is refused.
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

	/** Loads the materials of an .mtl file, with the textures they name, answering when they are ready: helix-ray's own, in place of
		raylib's `LoadMaterials`. Each is made as raylib's `ProcessMaterialsOBJ` makes it: raylib's default material, then its diffuse
		texture (`map_Kd`), or with none its diffuse color (`Kd`, alpha 255); its specular texture (`map_Ks`) and color (`Ks`); the
		normal map its bump texture (`bump` or `map_bump`), white, its value the specular exponent (`Ns`); its emission color (`Ke`); the
		height map its displacement texture (`disp`). What a material doesn't give is tinyobj_loader_c's default, as raylib has it: each
		color black, the specular exponent 1. A texture that can't be read is none (id 0, logged). The program holds each material until
		`UnloadMaterial`. Where raylib's reading is broken, helix-ray reads the file as the format has it (a texture's path resolved
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

	/** Loads a glTF or GLB file's animations, answering when they are read: helix-ray's own, in place of raylib's
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

	// LoadWaveAsync's call (Raylib.LoadWaveAsync): the file fetched, then read by read, the reader its extension names (WaveMacro).
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

	// LoadWaveFromMemoryAsync's call (Raylib.LoadWaveFromMemoryAsync): the bytes read by read, the reader fileType names (WaveMacro).
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

	// An Ogg Vorbis file, decoded by the platform at its own rate and made 16-bit as stb_vorbis makes its floats for raylib; its frames
	// the stream's length as stb_vorbis reads it (the last page's position), a decoder that ends early (Chromium's) padded with silence.
	static function readOgg(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void
		RAudio.audioDecoder().decode(data, 0, (samples, channelCount, sampleRate) -> {
			var decoded = Std.int(samples.length / (4 * channelCount)),
				length = Math.round(helix.formats.audio.AudioHeader.readDuration(data, data.length) * sampleRate);
			var frames = length > 0 ? length : decoded;
			done(new Wave(frames, sampleRate, 16, channelCount, Waves.toInt16(samples, frames * channelCount)));
		}, message -> failed('WAVE: Failed to load OGG data: $message'));

	// An MP3 file, decoded by the platform at its own rate as dr_mp3 0.6.39 decodes it for raylib: every frame decoded, its Xing, Info
	// or VBRI frame as silence and its LAME delay and padding kept, as that dr_mp3 reads no tag, the tag hidden from the platform's
	// decoder (Waves.hideMp3Tag), which would trim them; its 16-bit samples made 32-bit floats (Waves.toMp3Floats).
	static function readMp3(fileType:String, data:haxe.io.Bytes, done:Wave->Void, failed:String->Void):Void {
		var file = Waves.hideMp3Tag(data);
		RAudio.audioDecoder().decode(file, 0, (samples, channelCount, sampleRate) -> {
			var floats = Waves.toMp3Floats(samples, channelCount, file, file != data);
			done(new Wave(Std.int(floats.length / (4 * channelCount)), sampleRate, 32, channelCount, floats));
		}, message -> failed('WAVE: Failed to load MP3 data: $message'));
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

	// LoadFontAsync's call where its file's name isn't known as the program builds (Raylib.LoadFontAsync): a GIF image's glyphs or the
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

	// LoadImageAsync's call where its file's name isn't known as the program builds (Raylib.LoadImageAsync): a GIF file's first frame
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

	// LoadImageFromMemoryAsync's call where its type isn't known as the program builds (Raylib.LoadImageFromMemoryAsync): raylib's two
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

	// LoadImageAnimAsync's call where its file's name isn't known as the program builds (Raylib.LoadImageAnimAsync): the GIF reader or
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

	/** Reads a texture's pixels, answering when they are read: helix-ray's own, in place of raylib's `LoadImageFromTexture`, as the GPU
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
		Runtime.imaging();
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

	// Answers a load that failed: to the program's failed callback, or logged. Every error names the file, as the services' do.
	static function refuse(name:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			Runtime.log(4, '$name: $error');
	}
	#end
}
