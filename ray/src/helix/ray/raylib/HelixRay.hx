package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
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
class HelixRay {
	#if !macro
	// ---- Loading in a page: helix-ray's own, not raylib's ----

	/** Loads an image file as a texture, answering when it is ready: helix-ray's own, for a page, where `LoadTexture` answers only for a
		file already loaded (one the program names, so it was loaded before `main`, or one loaded this way). Natively the file is read
		at once. Either way the answer comes at a later frame, never during the call, and `LoadTexture` of the file answers at once after.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the texture.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	public static function LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(LoadTexture(path)) : refuse("LoadTextureAsync", path, error, failed));
	}

	/** Loads a model from a glTF or GLB file, with its images and the files it points to, answering when it is ready: helix-ray's own, as
		`LoadTextureAsync` is for textures.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the model.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	public static function LoadModelAsync(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(LoadModel(path)) : refuse("LoadModelAsync", path, error, failed));
	}

	/** Loads a sound file and decodes it, answering when it is ready to play at once: helix-ray's own, as `LoadTextureAsync` is for
		textures. `InitAudioDevice` comes first.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the sound.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	public static function LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Runtime.audio == null) {
			Runtime.later(() -> refuse("LoadSoundAsync", path, "InitAudioDevice first", failed));
			return;
		}
		var sound = LoadSound(path);
		var entry = sounds.get(path);
		if (entry.loaded != null)
			Runtime.later(() -> loaded(sound));
		else
			entry.answers.push(error -> error == null ? loaded(sound) : refuse("LoadSoundAsync", path, error, failed));
	}

	/** Reads a text file, answering when it is read: helix-ray's own, as `LoadTextureAsync` is for textures. A file `SaveFileText`
		wrote is answered from the saves.

		@param fileName  The file.
		@param loaded  Receives its text.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	public static function LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Runtime.saves != null && Runtime.saves.hasKey(SAVED + path)) {
			var text = Runtime.saves.getString(SAVED + path, "");
			Runtime.later(() -> loaded(text));
			return;
		}
		Runtime.fetch(path, error -> error == null ? loaded(Runtime.files.get(path).toString()) : refuse("LoadFileTextAsync", path, error, failed));
	}

	@:allow(helix.ray)
	static function refuse(name:String, path:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			trace('$name: $path: $error');
	}
	#end
}
