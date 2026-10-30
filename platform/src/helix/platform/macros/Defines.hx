package helix.platform.macros;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import helix.platform.adapters.shared.FilePath;
#end

/** Provides the init macro the platform's haxelib runs for every build on it (its extraParams.hxml).

	It registers the platform's defines, so `haxe --help-user-defines` and an editor's hxml completion show them, and the API reference
	lists them. It refuses a company or product that can't be one directory's name, so the mistake fails the build. Natively it also sets
	hxcpp's architecture define for this machine, `HXCPP_ARM64` on arm64 and `HXCPP_M64` elsewhere, when the build sets none, because hxcpp
	builds 32-bit on Windows otherwise and every SDL3 the platform links is 64-bit. */
@:noCompletion
class Defines {
	#if macro
	/** The platform's defines, each with its documentation. */
	public static final ALL:Array<haxe.macro.Compiler.DefineDescription> = [
		{
			define: "helix-company",
			doc: "The company that makes the program, one directory's name. ISystem's data and cache directories are under it, and natively SDL names the program by its product. Defaults to DefaultCompany.",
			params: ["name"]
		},
		{
			define: "helix-product",
			doc: "The program's name, one directory's name. ISystem's data and cache directories are under the company and it, and natively SDL names the program by it, in the OS's audio mixer for one. Defaults to the executable's name natively and Game in a page.",
			params: ["name"]
		}
	];

	/** Prints the defines as JSON, for the API reference (`tools/gen_apidoc.py`). */
	public static function describe():Void
		Sys.println(haxe.Json.stringify(ALL));

	/** Registers the defines, checks the names, and natively defines this machine's architecture when the build names none. */
	public static function configure():Void {
		for (define in ALL)
			Compiler.registerCustomDefine(define, "helix-platform");
		for (define in ["helix-company", "helix-product"]) {
			var value = Context.definedValue(define);
			if (value != null && !FilePath.isDirectoryName(value))
				Context.error('-D $define=$value: the name must be one directory\'s name on every OS (1 to 64 characters, no / \\ : * ? " < > |, and no space or dot at its end)',
					Context.currentPos());
		}
		if (Context.defined("cpp")
			&& !Context.defined("HXCPP_M64")
			&& !Context.defined("HXCPP_M32")
			&& !Context.defined("HXCPP_ARM64"))
			Compiler.define(helix.platform.tools.ShaderTools.arm64() ? "HXCPP_ARM64" : "HXCPP_M64");
	}
	#end
}
