import haxe.Json;
import haxe.macro.Context;
import haxe.macro.Type;

/** Writes what a program's libraries mark `@:keep`, as the compiler typed them: a JSON array of "<type>" or "<type>.<field>", for every
	class and enum under a package given, in source order. A build with `-dce full` adds `:keep` to every type it keeps, so its `-xml`
	can't tell a library's own `@:keep` from one the build added; this reads the metadata as written, before dead-code elimination runs.
	Interfaces and abstracts' implementations are left out: the compiler keeps those itself.

	--macro Kept.write("kept.json", ["helix."])

	tools/measure_sizes.py runs it in each rung's build, beside -xml (docs/DECISIONS.md 30). */
class Kept {
	/** Writes the types and fields marked `@:keep` once the program is typed.

		@param out  The file to write.
		@param prefixes  The packages read, as prefixes of a type's full name ("helix."). */
	public static function write(out:String, prefixes:Array<String>):Void {
		Context.onAfterTyping(types -> {
			var found:Array<String> = [];
			for (type in types) {
				var t:Null<BaseType> = switch type {
					case TClassDecl(c): var cl = c.get(); cl.isInterface || cl.isExtern ? null : cl;
					case TEnumDecl(e): e.get();
					case _: null;
				}
				if (t == null)
					continue;
				var name = t.pack.concat([t.name]).join(".");
				if (name.indexOf("_Impl_") >= 0 || !Lambda.exists(prefixes, p -> StringTools.startsWith(name, p)))
					continue;
				if (t.meta.has(":keep"))
					found.push(name);
				switch type {
					case TClassDecl(c):
						var cl = c.get();
						for (f in cl.fields.get().concat(cl.statics.get()))
							if (f.meta.has(":keep"))
								found.push('$name.${f.name}');
					case _:
				}
			}
			sys.io.File.saveContent(out, Json.stringify(found));
		});
	}
}
