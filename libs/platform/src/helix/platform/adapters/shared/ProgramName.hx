package helix.platform.adapters.shared;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Gives the program's company and product, from the `helix-company` and `helix-product` defines, for the system adapters' directories
	and SDL's name for the program. Both are required: a build without either fails, saying what to add (`Defines` checks each is a
	directory's name). */
@:noCompletion
class ProgramName {
	/** Returns the company: the `helix-company` define. */
	public static macro function company():ExprOf<String>
		return macro $v{name("helix-company")};

	/** Returns the product: the `helix-product` define. */
	public static macro function product():ExprOf<String>
		return macro $v{name("helix-product")};

	#if macro
	// A define's value, failing the build when it's unset.
	static function name(define:String):String {
		var value = Context.definedValue(define);
		if (value == null)
			Context.fatalError('$define isn\'t set. Every program names its company and product with two defines, as '
				+ '-D helix-company=<company> -D helix-product=<product> (in an hxml, or on the haxe command line). They name where the '
				+ 'program\'s saves and cache are kept (natively <company>/<product> in the user\'s data and cache directories, in a page '
				+ 'the browser\'s databases "<company>/<product>/data" and "/cache"), so two programs keep apart, and natively the name '
				+ 'the system shows for the program.',
				Context.currentPos());
		return value;
	}
	#end
}
