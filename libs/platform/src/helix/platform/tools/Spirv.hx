package helix.platform.tools;

import haxe.io.Bytes;

/** Provides rewriting where a SPIR-V module's resources are bound: each texture's and uniform block's descriptor set and binding, read from
	its decorations and written back in place. The module is otherwise left as it is. */
@:noCompletion
class Spirv {
	static inline final MAGIC = 0x07230203;
	static inline final OP_VARIABLE = 59;
	static inline final OP_DECORATE = 71;
	static inline final DECORATION_BINDING = 33;
	static inline final DECORATION_SET = 34;

	/** The storage class of a texture (a combined sampler). */
	public static inline final TEXTURES = 0;

	/** The storage class of a uniform block. */
	public static inline final BLOCKS = 2;

	/** Returns a copy of a module with its resources bound anew.

		@param module  The module, as glslang wrote it.
		@param bind  Receives a resource's storage class (`TEXTURES` or `BLOCKS`) and its binding, and returns its new set and binding, or
			null to leave it as it is.
		@return  The module rebound.
		@throws CommandException  The bytes aren't a SPIR-V module. */
	public static function rebind(module:Bytes, bind:(storage:Int, binding:Int) -> Null<{set:Int, binding:Int}>):Bytes {
		var out = module.sub(0, module.length);
		if (out.length < 20 || out.length % 4 != 0 || out.getInt32(0) != MAGIC)
			throw new CommandException("shader: not a SPIR-V module");
		var storage = new Map<Int, Int>(),
			bindingAt = new Map<Int, Int>(),
			setAt = new Map<Int, Int>();
		var at = 20;
		while (at < out.length) {
			var word = out.getInt32(at),
				count = word >>> 16,
				op = word & 0xffff;
			if (count == 0)
				throw new CommandException("shader: a SPIR-V instruction of no words");
			if (op == OP_VARIABLE)
				storage.set(out.getInt32(at + 8), out.getInt32(at + 12));
			else if (op == OP_DECORATE) {
				var decoration = out.getInt32(at + 8);
				if (decoration == DECORATION_BINDING)
					bindingAt.set(out.getInt32(at + 4), at + 12);
				else if (decoration == DECORATION_SET)
					setAt.set(out.getInt32(at + 4), at + 12);
			}
			at += count * 4;
		}
		for (id => position in bindingAt) {
			var kind = storage.get(id);
			if (kind != TEXTURES && kind != BLOCKS || !setAt.exists(id))
				continue;
			var moved = bind(kind, out.getInt32(position));
			if (moved == null)
				continue;
			out.setInt32(position, moved.binding);
			out.setInt32(setAt.get(id), moved.set);
		}
		return out;
	}
}
