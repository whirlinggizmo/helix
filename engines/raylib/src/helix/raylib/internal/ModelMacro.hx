package helix.raylib.internal;

#if macro
import haxe.macro.Expr;

using StringTools;

/** Chooses a model's reader as the program builds (`Extras.LoadModelAsync`), so a program carries only the readers it names. */
@:noCompletion
class ModelMacro {
	/** Returns the call loading a model by the reader its file needs: when its name is known as the program builds (`ShaderMacro.known`),
		the glTF reader alone for a .gltf or .glb file and the OBJ reader alone for an .obj file, so dead-code elimination leaves the other
		out; otherwise the call choosing by the extension as the program runs, which brings both.

		@param fileName  The file's name.
		@param loaded  Receives the model.
		@param failed  Optional. Receives why it couldn't be loaded.
		@return  The call. */
	public static function load(fileName:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		var name = ShaderMacro.known(fileName), reader = "loadModel";
		if (name != null) {
			var lower = name.toLowerCase();
			if (lower.endsWith(".obj"))
				reader = "loadObjModel";
			else if (lower.endsWith(".gltf") || lower.endsWith(".glb"))
				reader = "loadGltfModel";
		}
		if (failed == null)
			failed = macro null;
		return macro @:privateAccess $p{["helix", "raylib", "modules", "RAsync", reader]}($fileName, $loaded, $failed);
	}
}
#end
