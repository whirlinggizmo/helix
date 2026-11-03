import haxe.Json;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.PositionTools;
import haxe.macro.Printer;

/** Writes classes' fields as they are declared, as the compiler parsed them: a JSON array, one object a field, with its class, name, the
	line it starts on, whether it is static and a macro function, and a function's arguments (name, whether optional, type, default) and
	result, types as declared. A target's description (haxe -xml) types a macro function's arguments as Dynamic, and omits some; this
	gives them as written (ExprOf<String>).

	--macro Fields.write("fields.json", ["helix.raylib.Raylib", "helix.raylib.Raymath"])

	tools/gen_raylib.py and tools/gen_apidoc.py run it in their compile, beside -xml. */
class Fields {
	static var found:Array<Dynamic> = [];

	/** Records classes' fields as each is built, and writes them once the program is typed. Only the classes named are built so: a build
		macro on every class of a library can break its classes' imports of each other's statics.

		@param out  The file to write.
		@param classes  The classes, by their full names. */
	public static function write(out:String, classes:Array<String>):Void {
		for (path in classes)
			haxe.macro.Compiler.addGlobalMetadata(path, "@:build(Fields.build())", false, true, false);
		Context.onAfterTyping(_ -> sys.io.File.saveContent(out, Json.stringify(found)));
	}

	/** Records the class being built's fields, leaving them as they are.

		@return  Null: the fields unchanged. */
	public static function build():Null<Array<Field>> {
		var c = Context.getLocalClass();
		if (c == null)
			return null;
		var owner = c.toString(), printer = new Printer();
		for (field in Context.getBuildFields()) {
			var described:Dynamic = {
				owner: owner,
				name: field.name,
				line: PositionTools.toLocation(field.pos).range.start.line,
				isStatic: field.access != null && field.access.indexOf(AStatic) >= 0,
				isMacro: field.access != null && field.access.indexOf(AMacro) >= 0
			};
			switch field.kind {
				case FFun(f):
					described.args = [
						for (a in f.args)
							{
								name: a.name,
								optional: a.opt == true,
								type: a.type == null ? null : printer.printComplexType(a.type),
								value: a.value == null ? null : printer.printExpr(a.value)
							}
					];
					described.result = f.ret == null ? null : printer.printComplexType(f.ret);
				case _:
			}
			found.push(described);
		}
		return null;
	}
}
