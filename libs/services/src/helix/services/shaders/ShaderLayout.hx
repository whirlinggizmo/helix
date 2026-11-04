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
	final shape:ShaderShape;

	function new(block:ShaderBlockLayout, blockIndex:Int, member:ShaderMember) {
		this.block = block;
		this.blockIndex = blockIndex;
		offset = member.offset;
		type = cast member.type;
		elementCount = member.elementCount;
		stride = member.stride;
		shape = ShaderShape.of(type);
	}

	/** Writes one element's components (a matrix's by columns) into a block's bytes. */
	function pack(bytes:Bytes, elementIndex:Int, values:Array<Float>):Void {
		var rows = shape.rows,
			columns = shape.columns,
			integer = shape.integer,
			boolean = shape.boolean;
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
		var rows = shape.rows,
			columns = shape.columns,
			integer = shape.integer;
		var base = offset + elementIndex * stride;
		for (c in 0...columns)
			for (r in 0...rows) {
				var at = base + c * 16 + r * 4;
				if (at + 4 <= bytes.length)
					values[c * rows + r] = integer ? bytes.getInt32(at) : bytes.getFloat(at);
			}
	}
}

/** A value type's shape, worked out once for each type: its rows and columns, its floats, whether it holds integers or bools, and its
	kind, a bit the write methods check against a mask of the kinds they take. One instance is kept for each type. */
@:noCompletion
@:allow(helix.services.shaders)
class ShaderShape {
	static inline final FLOAT = 1;
	static inline final VEC2 = 2;
	static inline final VEC3 = 4;
	static inline final VEC4 = 8;
	static inline final MAT2 = 16;
	static inline final MAT3 = 32;
	static inline final MAT4 = 64;
	static inline final BOOL = 128;
	static inline final OTHER_INTEGER = 256;
	static inline final FLOATS = FLOAT | VEC2 | VEC3 | VEC4 | MAT2 | MAT3 | MAT4;
	static inline final INTEGERS = BOOL | OTHER_INTEGER;

	final type:ShaderValueType;
	final rows:Int;
	final columns:Int;
	final size:Int;
	final integer:Bool;
	final boolean:Bool;
	final kind:Int;

	function new(type:ShaderValueType) {
		this.type = type;
		rows = type.componentCount;
		columns = type.columnCount;
		size = rows * columns;
		integer = type.integer;
		boolean = (type : String).charCodeAt(0) == "b".code;
		kind = switch type {
			case Float: FLOAT;
			case Vec2: VEC2;
			case Vec3: VEC3;
			case Vec4: VEC4;
			case Mat2: MAT2;
			case Mat3: MAT3;
			case Mat4: MAT4;
			case Bool: BOOL;
			case _: OTHER_INTEGER;
		}
	}

	// The shape of each type made so far, made at the first ask, as a shader may be read before this class's statics are.
	static var made:Null<Map<String, ShaderShape>> = null;

	/** The shape of a type, made the first time it is asked for. */
	static function of(type:ShaderValueType):ShaderShape {
		if (made == null)
			made = new Map();
		var shape = made.get(type);
		if (shape == null)
			made.set(type, shape = new ShaderShape(type));
		return shape;
	}
}

/** A number for each sampler name, the same in every shader, by which values and scenes keep their textures: a name looked up once,
	where a handle or a texture slot is made, not as a draw reads its textures. */
@:noCompletion
@:allow(helix.services.shaders)
class ShaderNameIds {
	// The id of each name seen, made at the first ask, as a shader may be read before this class's statics are.
	static var ids:Null<Map<String, Int>> = null;
	static var count:Null<Int> = null;

	/** The id of a name, made the first time it is asked for. */
	static function of(name:String):Int {
		if (ids == null)
			ids = new Map();
		var id = ids.get(name);
		if (id == null) {
			id = count == null ? 0 : count;
			count = id + 1;
			ids.set(name, id);
		}
		return id;
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
