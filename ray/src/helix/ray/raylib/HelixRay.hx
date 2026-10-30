package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
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
import helix.ray.raylib.HelixRay.*;
#end

/** Holds helix-ray's own, not raylib's (loading in a page), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class HelixRay {
	#if !macro
	// ---- Loading in a page: helix-ray's own, not raylib's ----

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
		in place of raylib's `LoadModel`. A file loaded again shares its first load's meshes and textures, with materials of its own.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the model.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadModelAsync(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(RModels.loadModel(path)) : refuse("LoadModelAsync", error, failed));
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

	// Answers a load that failed: to the program's failed callback, or logged. Every error names the file, as the services' do.
	static function refuse(name:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			Runtime.log(4, '$name: $error');
	}
	#end
}
