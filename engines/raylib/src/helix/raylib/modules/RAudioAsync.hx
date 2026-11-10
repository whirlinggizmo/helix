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
import helix.raylib.modules.RFilesAsync.*;
import helix.raylib.modules.RTexturesAsync.*;
import helix.raylib.modules.RTextAsync.*;
import helix.raylib.modules.RModelsAsync.*;
#end

/** Provides helix-raylib's async sound, wave and music loads and wave writes. They replace raylib's calls that wait for a file, a
	decode or a write.

	`helix.raylib.Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RAudioAsync {
	#if !macro
	/** Asynchronously loads and decodes a sound file, ready to play at once, replacing raylib's `LoadSound`. See `LoadMusicStreamAsync` for playing a file as it is read.

		`InitAudioDevice` must come first.

		A file loaded again shares its first load's decoded sound.

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

	/** Asynchronously opens a music file to be played as it is read, replacing raylib's `LoadMusicStream`. See `LoadSoundAsync` for decoding a file whole first.

		`InitAudioDevice` must come first.

		A FLAC file is refused, as raylib 5.5's default build leaves FLAC out.

		Never loaded whole: it is read as it plays (helix-services' `Audio.stream`).

		@param fileName  The file, as the program names it, such as "assets/theme.ogg".
		@param loaded  Receives the music, ready to play, once enough of the file has arrived to start.
		@param failed  Optional. Receives why it couldn't be opened; when omitted, it is logged. */
	static function LoadMusicStreamAsync(fileName:String, loaded:Music->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (StringTools.endsWith(path.toLowerCase(), ".flac")) {
			Runtime.later(() -> refuse("LoadMusicStreamAsync", '$path: STREAM: File format not supported', failed));
			return;
		}
		if (Runtime.audio == null) {
			Runtime.later(() -> refuse("LoadMusicStreamAsync", '$path: InitAudioDevice first', failed));
			return;
		}
		var music = new Music();
		RAudio.open(music, path, "LoadMusicStreamAsync", () -> loaded(music), error -> refuse("LoadMusicStreamAsync", error, failed));
	}

	/** Asynchronously writes a wave to a sound file, replacing raylib's `ExportWave`. See `ExportWaveAsCodeAsync` for writing a C header.

		The extension chooses the format:

		- ".wav": 8, 16 and 24-bit samples as integers, 32-bit as floats, as raylib's dr_wav writes them.
		- ".raw": the samples unchanged.

		A ".qoa" file is refused, though raylib writes one.

		The file is written and kept by `SaveFileDataAsync`.

		@param wave  The wave.
		@param fileName  The file; its extension chooses the format.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't, such as a wave with no samples or another extension; when omitted, it is logged. */
	static function ExportWaveAsync(wave:Wave, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportData("ExportWaveAsync", fileName, RAudio.waveFile(wave, fileName), "Wave data exported successfully", "Failed to export wave data", done, failed);
	}

	/** Asynchronously writes a wave as a C header, replacing raylib's `ExportWaveAsCode`. See `ExportWaveAsync` for writing a sound file.

		The header holds:

		- the frame count, sample rate, sample size and channel count, as defines.
		- the samples, as an array of floats with 4 places for 32-bit samples, else of bytes, 20 a line.

		The file is written by `SaveFileTextAsync`.

		@param wave  The wave.
		@param fileName  The file; its name, upper case, names the defines and the array.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportWaveAsCodeAsync(wave:Wave, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportWaveAsCodeAsync", fileName, RAudio.waveAsCode(wave, fileName), "Wave as code exported successfully", done, failed);
	}
	#end
}
