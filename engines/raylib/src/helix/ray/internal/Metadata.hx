package helix.ray.internal;

#if macro
import haxe.macro.Compiler;
#end

/** Registers helix-ray's metadata, so `haxe --help-user-metas` lists it and an editor shows it on hover. Run by the library's
	`extraParams.hxml`. */
@:noCompletion
class Metadata {
	#if macro
	/** Registers the metadata. */
	public static function register():Void {
		Compiler.registerCustomMetadata({
			metadata: ":unsupported",
			doc: "On a section's function: helix-ray won't have it, by design. The message says why and what to use instead; tools/gen_raylib.py declares the function in the facade as a macro whose call doesn't compile, reporting it (helix.platform.macros.Build.unsupported).",
			params: ["message"],
			targets: [ClassField]
		}, "helix-ray");
		Compiler.registerCustomMetadata({
			metadata: ":unimplemented",
			doc: "On a section's function: helix-ray doesn't have it yet. tools/gen_raylib.py declares it in the facade as a macro whose call doesn't compile, reporting the message (helix.platform.macros.Build.unimplemented).",
			params: ["message"],
			targets: [ClassField]
		}, "helix-ray");
	}
	#end
}
