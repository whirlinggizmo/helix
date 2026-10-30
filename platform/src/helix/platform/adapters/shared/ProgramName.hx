package helix.platform.adapters.shared;

/** Gives the program's company and product, from the `helix-company` and `helix-product` defines, for the system adapters' directories
	and SDL's name for the program. */
@:noCompletion
class ProgramName {
	/** Returns the company: `helix-company`, or "DefaultCompany". */
	public static function company():String {
		var name = haxe.macro.Compiler.getDefine("helix-company");
		return name == null ? "DefaultCompany" : name;
	}

	/** Returns the product: `helix-product`, or natively the executable's name and in a page "Game".

		@throws String  Natively, for an executable whose name can't be one directory's name, when `helix-product` is unset. */
	public static function product():String {
		var name = haxe.macro.Compiler.getDefine("helix-product");
		if (name != null)
			return name;
		#if js
		return "Game";
		#else
		var executable = haxe.io.Path.withoutExtension(haxe.io.Path.withoutDirectory(Sys.programPath()));
		if (!FilePath.isDirectoryName(executable))
			throw 'the executable\'s name "$executable" can\'t be a directory\'s: set -D helix-product';
		return executable;
		#end
	}
}
