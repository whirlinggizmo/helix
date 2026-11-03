package helix.services.shaders;

import haxe.io.Bytes;
import helix.platform.ShaderBlock;
import helix.platform.ShaderMember;

/** A shader's uniform block as values lay it out: its name, its indices in a draw's uniforms, its size, whether it is shared, and its
	members. Its key tells two layouts apart. */
@:noCompletion
@:allow(helix.services.shaders)
class ShaderBlockLayout {
	final name:String;
	final slot:Int;
	final stage:String;
	final size:Int;
	final indices:Array<Int>;
	final shared:Bool;
	final members:Array<ShaderMember>;
	final key:String;

	function new(block:ShaderBlock, shared:Bool) {
		name = block.glslName;
		slot = block.slot;
		stage = block.stage;
		size = block.size;
		this.shared = shared;
		members = block.members;
		indices = stage == "vertex" ? [slot] : stage == "fragment" ? [4 + slot] : [slot, 4 + slot];
		key = '$size:' + [
			for (m in members)
				'${m.glslName} ${m.type} ${m.offset} ${m.elementCount} ${m.stride}'
		].join(";");
	}

	function findMember(path:String):Null<ShaderMember> {
		for (m in members)
			if (m.glslName == path)
				return m;
		return null;
	}
}

/** Where a uniform is: its block (by its index among the shader's blocks), offset, type, elements and stride. */
@:noCompletion
@:allow(helix.services.shaders)
class ShaderPlace {
	final block:ShaderBlockLayout;
	final blockIndex:Int;
	final offset:Int;
	final type:ShaderValueType;
	final elementCount:Int;
	final stride:Int;

	function new(block:ShaderBlockLayout, blockIndex:Int, member:ShaderMember) {
		this.block = block;
		this.blockIndex = blockIndex;
		offset = member.offset;
		type = cast member.type;
		elementCount = member.elementCount;
		stride = member.stride;
	}

	/** Writes one element's components (a matrix's by columns) into a block's bytes. */
	function pack(bytes:Bytes, elementIndex:Int, values:Array<Float>):Void {
		var rows = type.componentCount,
			columns = type.columnCount,
			integer = type.integer;
		var boolean = StringTools.startsWith(type, "b");
		var base = offset + elementIndex * stride;
		for (c in 0...columns)
			for (r in 0...rows) {
				var at = base + c * 16 + r * 4, v = values[c * rows + r];
				if (at + 4 > bytes.length)
					continue;
				if (boolean)
					bytes.setInt32(at, v != 0 ? 1 : 0);
				else if (integer)
					bytes.setInt32(at, Std.int(v));
				else
					bytes.setFloat(at, v);
			}
	}

	/** Reads one element's components from a block's bytes into values. */
	function unpack(bytes:Bytes, elementIndex:Int, values:Array<Float>):Void {
		var rows = type.componentCount,
			columns = type.columnCount,
			integer = type.integer;
		var base = offset + elementIndex * stride;
		for (c in 0...columns)
			for (r in 0...rows) {
				var at = base + c * 16 + r * 4;
				if (at + 4 <= bytes.length)
					values[c * rows + r] = integer ? bytes.getInt32(at) : bytes.getFloat(at);
			}
	}
}

/** A uniform's values as written on values, independent of any layout: each element's components (a matrix's by columns), null for an
	element not written. */
@:noCompletion
@:allow(helix.services.shaders)
class ShaderWritten {
	final elements:Array<Null<Array<Float>>> = [];

	function new() {}
}
