package helix.ray.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/** Makes `Raylib` one class from files by section, as raylib's source is split (rcore, rshapes, rtextures, rtext, rmodels, raudio,
	raymath): each section's class hands its members over as they are written, untyped, and is left empty; `Raylib` takes them, each
	tagged with its section for the reference, so a program sees one class and the members' bodies are typed in it. Only the program's
	`Raylib` is built so: Haxe builds no class compiled for macros, and `Raylib` is one, for its macro functions (`LoadShader` and the
	refusals of what isn't here), which stay in `Raylib.hx`. */
class Sections {
	static final parts = new Map<String, Array<Field>>();

	/** Hands a section class's members to `Raylib`, leaving the class empty. Run by each section's `@:build`.

		@param id  The section.
		@param title  Its heading in the reference: raylib's module, and what it holds.
		@return  No fields. */
	public static function part(id:String, title:String):Array<Field> {
		var fields = Context.getBuildFields();
		for (f in fields) {
			if (f.meta == null)
				f.meta = [];
			f.meta.push({name: ":section", params: [macro $v{id}, macro $v{title}], pos: f.pos});
		}
		parts.set(id, fields);
		return [];
	}

	/** Adds the sections' members to `Raylib`, in the order given. Run by `Raylib`'s `@:build`.

		@param sections  The section classes, by name in `helix.ray.raylib`, and the id each tags its members with.
		@return  `Raylib`'s own fields and the sections'. */
	public static function merge(sections:Array<{name:String, id:String}>):Array<Field> {
		var fields = Context.getBuildFields();
		for (s in sections) {
			// Its fields asked for, so its build has run.
			switch Context.getType("helix.ray.raylib." + s.name) {
				case TInst(c, _):
					c.get().fields.get();
				case _:
			}
			var part = parts.get(s.id);
			if (part == null)
				Context.error('helix-ray: section ${s.name} gave no members', Context.currentPos());
			fields = fields.concat(part);
		}
		return fields;
	}
}
#end
