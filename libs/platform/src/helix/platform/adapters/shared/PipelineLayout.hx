package helix.platform.adapters.shared;

import helix.platform.PipelineDesc;

/** Checks a pipeline's vertex layout against the platform's rules and its program's inputs, the same for every graphics adapter, so a
	pipeline made in a page is made natively too. */
@:noCompletion
class PipelineLayout {
	/** Checks a pipeline's buffers and attribute constants: at most 8 buffers and 16 attributes, slots 0 to 15, strides and offsets
		multiples of 4, a stride at most 255 (WebGL's limit), each attribute's format within its record, each fed slot a float input of the
		program, and each constant for a slot no buffer feeds, of at most four values.

		@param desc  The pipeline's description.
		@param attributeTypes  The program's attributes' GLSL types, by slot (`ShaderSource.attributeTypes`).
		@throws String  A layout that breaks a rule, naming it. */
	public static function check(desc:PipelineDesc, attributeTypes:Array<String>):Void {
		var count = 0;
		for (b in desc.buffers)
			count += b.attributes.length;
		if (desc.buffers.length > 8 || count > 16)
			throw "Invalid pipeline layout: more than 8 buffers or 16 attributes";
		for (b in desc.buffers) {
			if (b.stride < 0 || b.stride > 255 || b.stride % 4 != 0)
				throw "Invalid pipeline layout: a stride";
			for (a in b.attributes) {
				var format:Int = a.format;
				if (a.slot < 0 || a.slot > 15 || format < 0 || format > 11)
					throw "Invalid pipeline layout: a slot or format";
				if (a.offset < 0 || a.offset % 4 != 0 || a.offset + a.format.bytes > b.stride)
					throw "Invalid pipeline layout: an offset";
				// An integer input's type starts with i or u (int, ivecN, uint, uvecN); a float one's with f, v or m.
				var type = a.slot < attributeTypes.length ? attributeTypes[a.slot] : "";
				if (type.charAt(0) == "i" || type.charAt(0) == "u")
					throw "Invalid pipeline layout: an integer input";
			}
		}
		if (desc.attributeConstants != null)
			for (c in desc.attributeConstants)
				if (c.slot < 0
					|| c.slot > 15
					|| c.values.length > 4
					|| Lambda.exists(desc.buffers, b -> Lambda.exists(b.attributes, a -> a.slot == c.slot)))
					throw "Invalid pipeline attribute constant: a slot from 0 to 15 no buffer feeds, at most four values";
	}
}
