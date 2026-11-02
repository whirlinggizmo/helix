package helix.services.shaders;

import helix.platform.VertexBuffer;
import helix.platform.VertexFormat;

/** Represents how a mesh's vertex buffers hold its attributes, by name, for any shader drawing it: each buffer's stride, whether it
	steps per instance, and where each attribute is; and what an attribute no buffer feeds reads.

	It is made once, for a kind of mesh, and handed to `ShaderPrograms.getPipeline`, which resolves it for each shader (slots, a matrix a
	slot a column) once, again after a replacement, and keeps the result: nothing is made per draw. An attribute a shader reads that no
	buffer feeds reads its constant, or (0, 0, 0, 1) when the layout gives none (platform proposal 8); a constant for an attribute the
	shader doesn't read is skipped. A buffer none of whose placements the shader reads is a gap: the pipeline reads nothing from it, and
	a draw may pass 0 for it. An attribute is floats unless its placement gives another `VertexFormat`: a normal as four signed bytes, the
	weights as four unsigned shorts, below.

	```haxe
	var skinnedMesh = new ShaderVertexLayout([{stride: 40, placements: [
		{name: "position", offset: 0}, {name: "normal", offset: 12, format: Byte4Norm, optional: true},
		{name: "joints", offset: 16, optional: true}, {name: "weights", offset: 32, format: UShort4Norm, optional: true}
	]}], [{name: "color", values: [1, 1, 1, 1]}]);
	``` */
class ShaderVertexLayout {
	/** Gets the buffers, by their index in a draw's buffers. */
	public final buffers:Array<{stride:Int, ?instanced:Bool, placements:Array<ShaderVertexPlacement>}>;

	/** Gets the values attributes no buffer feeds read. */
	public final constants:Array<ShaderVertexConstant>;

	/** Creates a layout.

		@param buffers  Each buffer's stride in bytes, whether it steps per instance (false when omitted), and its placements.
		@param constants  Optional. What attributes no buffer feeds read; none by default. */
	public function new(buffers:Array<{stride:Int, ?instanced:Bool, placements:Array<ShaderVertexPlacement>}>, ?constants:Array<ShaderVertexConstant>) {
		this.buffers = buffers;
		this.constants = constants == null ? [] : constants;
		key = [
			for (b in buffers)
				'${b.stride} ${b.instanced == true} ' + [
					for (p in b.placements)
						'${p.name}/${p.slot}@${p.offset}x${p.format}${p.optional == true ? "?" : ""}'
				].join(",")
		].join(";") + "|" + [for (c in this.constants) '${c.name}/${c.slot}=${c.values.join(",")}'].join(";");
	}

	/** Returns a one-buffer layout packing some attributes as floats in the order given, as `Shader.computeVertexBuffer` packs them, for a
		buffer a program fills (a sprite batch's): from a shader, or from a set, whose variants share the attributes' types.

		@param source  The shader or variants declaring the attributes.
		@param names  The attributes, in their order in a record.
		@param instanced  Optional. Whether the buffer steps once an instance; defaults to false.
		@return  The layout: its stride the sum of the attributes' sizes.
		@throws String  A name nothing declares, or an integer attribute. */
	public static function fromAttributes(source:IShaderHandles, names:Array<String>, instanced:Bool = false):ShaderVertexLayout {
		var placements:Array<ShaderVertexPlacement> = [], offset = 0;
		for (name in names) {
			var a = source.getAttribute(name);
			if (a.type.integer)
				throw 'shader layout: attribute $name is a ${a.type}, an integer input, which the platform can\'t feed yet';
			placements.push({name: name, offset: offset});
			offset += a.type.componentCount * a.type.columnCount * 4;
		}
		return new ShaderVertexLayout([{stride: offset, instanced: instanced, placements: placements}]);
	}

	/** Returns the layout as one shader reads it, in the platform's form: placements the shader doesn't read left out, a matrix a
		`VertexAttribute` a column.

		@param shader  The shader.
		@return  The buffers' layouts, as `PipelineDesc.buffers` holds them.
		@throws String  A placement the shader doesn't read and isn't `optional`, an integer attribute, or one that runs past its stride. */
	public function computeBuffers(shader:Shader):Array<VertexBuffer> {
		var out:Array<VertexBuffer> = [];
		for (b in buffers) {
			var attributes:Array<helix.platform.VertexAttribute> = [];
			for (p in b.placements) {
				var a:Null<ShaderAttribute> = null;
				if (p.name != null)
					a = shader.findAttribute(p.name);
				else if (p.slot != null && p.slot >= 0 && p.slot < shader.attributes.length)
					a = shader.attributes[p.slot];
				var label = p.name != null ? p.name : 'slot ${p.slot}';
				if (a == null || !a.active && p.optional == true) {
					if (p.optional == true)
						continue;
					throw 'shader layout: the shader reads no attribute $label, which the layout places and doesn\'t mark optional';
				}
				if (a.type.integer)
					throw 'shader layout: attribute $label is a ${a.type}, an integer input, which the platform can\'t feed yet';
				var format = p.format != null ? p.format : floats(a.type.componentCount);
				for (c in 0...a.type.columnCount) {
					var at = p.offset + c * format.bytes;
					if (at + format.bytes > b.stride)
						throw 'shader layout: attribute $label runs past the buffer\'s ${b.stride}-byte records';
					attributes.push({slot: a.slot + c, format: format, offset: at});
				}
			}
			out.push({stride: b.stride, instanced: b.instanced == true, attributes: attributes});
		}
		return out;
	}

	// The format of a number of floats, 1 to 4.

	@:allow(helix.services.shaders)
	static function floats(count:Int):VertexFormat
		return count == 1 ? Float1 : count == 2 ? Float2 : count == 3 ? Float3 : Float4;

	// Its values as one string: layouts with the same values find the same pipeline.
	@:allow(helix.services.shaders)
	final key:String;

	// The constants as a shader reads them, by slot: those for attributes it declares and no buffer feeds.

	@:allow(helix.services.shaders)
	function computeConstants(shader:Shader, buffers:Array<VertexBuffer>):Array<{slot:Int, values:Array<Float>}> {
		var fed = new Map<Int, Bool>();
		for (b in buffers)
			for (a in b.attributes)
				fed.set(a.slot, true);
		var out = [];
		for (c in constants) {
			var slot = -1;
			if (c.name != null) {
				var a = shader.findAttribute(c.name);
				if (a != null)
					slot = a.slot;
			} else if (c.slot != null && c.slot < shader.attributes.length && shader.attributes[c.slot] != null)
				slot = c.slot;
			if (slot >= 0 && !fed.exists(slot))
				out.push({slot: slot, values: c.values});
		}
		return out;
	}
}
