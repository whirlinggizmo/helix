import haxe.macro.Context;
import haxe.macro.PositionTools;

/** Writes the fields helix-ray's facades have in the macro context, where their macro functions are, which a target's description
	(haxe -xml) leaves out: one line each, the facade's class, the field's name and the line it starts on. tools/gen_raylib.py runs it
	beside -xml, to know what each facade writes by hand.

	--macro FacadeFields.write("fields.txt", ["helix.ray.Raylib", "helix.ray.Raymath", "helix.ray.Rlgl"]) */
class FacadeFields {
	/** Writes the fields once the program is typed.

		@param out  The file to write.
		@param classes  The facades, by their full names. */
	public static function write(out:String, classes:Array<String>):Void {
		Context.onAfterTyping(_ -> {
			var lines = [];
			for (name in classes)
				switch Context.getType(name) {
					case TInst(c, _):
						for (field in c.get().statics.get())
							lines.push('$name ${field.name} ${PositionTools.toLocation(field.pos).range.start.line}');
					case _:
				}
			sys.io.File.saveContent(out, lines.join("\n") + "\n");
		});
	}
}
