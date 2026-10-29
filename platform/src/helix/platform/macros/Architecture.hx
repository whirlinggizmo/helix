package helix.platform.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
#end

/** Provides the init macro the platform's haxelib runs for every build on it (its extraParams.hxml): natively, hxcpp's architecture
	define for this machine, `HXCPP_ARM64` on arm64 and `HXCPP_M64` elsewhere, when the build sets none.

	hxcpp builds 32-bit on Windows unless told, and every SDL3 the platform links is 64-bit, so a program's hxml would otherwise have to
	know it: HeliX's haxelib did the same. */
@:noCompletion
class Architecture {
	#if macro
	/** Defines this machine's architecture for a native build that names none. */
	public static function define():Void {
		if (Context.defined("cpp")
			&& !Context.defined("HXCPP_M64")
			&& !Context.defined("HXCPP_M32")
			&& !Context.defined("HXCPP_ARM64"))
			Compiler.define(helix.platform.tools.ShaderTools.arm64() ? "HXCPP_ARM64" : "HXCPP_M64");
	}
	#end
}
