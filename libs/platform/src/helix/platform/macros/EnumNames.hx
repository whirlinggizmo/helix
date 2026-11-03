package helix.platform.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Provides the build macro for the platform's enum abstracts over Int, which adds a toString returning each value's name.

	A value that is traced, interpolated or passed to Std.string then reads as its name ("Space", "LeftX") while staying an Int. A value
	typed as Dynamic, or passed through haxe.Json, is still its number, since Haxe calls an abstract's toString only where the value is
	typed. Two values with the same number both read as the first one's name. */
@:noCompletion
class EnumNames {
	#if macro
	/** Returns the enum abstract's fields with toString added.

		@return  The fields, unchanged if the abstract declares its own toString. */
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields)
			if (field.name == "toString")
				return fields;
		var pos = Context.currentPos();
		var cases:Array<Case> = [], numbers = new Map<String, Bool>(), next = 0;
		for (field in fields)
			switch field.kind {
				case FVar(_, value) if (!field.access.contains(AStatic)):
					// Its number: written, or one past the last (as an enum abstract over Int numbers them).
					var number = next;
					if (value != null)
						switch value.expr {
							case EConst(CInt(v)): number = Std.parseInt(v);
							default: number = -1;
						}
					next = number + 1;
					var key = number < 0 ? field.name : Std.string(number);
					if (numbers.exists(key))
						continue;
					numbers.set(key, true);
					cases.push({values: [macro $i{field.name}], expr: macro $v{field.name}});
				default:
			}
		var body:Expr = {expr: ESwitch(macro abstract, cases, macro Std.string(this)), pos: pos};
		// Its doc names the abstract's own first values, as examples.
		var names = [
			for (c in cases.slice(0, 2))
				switch c.values[0].expr {
					case EConst(CIdent(name)):
						name;
					default:
						null;
				}
		].filter(name -> name != null);
		fields.push({
			name: "toString",
			access: [APublic],
			doc: "Returns the value's name as written" + (names.length > 0 ? ' (${names.join(", ")})' : "") +
			": what Std.string, interpolation and trace show.",
			kind: FFun({
				args: [],
				ret: macro :String,
				expr: macro return $body
			}),
			pos: pos
		});
		return fields;
	}
	#end
}
