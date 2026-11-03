package helix.services.shaders;

import helix.math.Matrix3D;

/** Provides writing uniform values by handle, which `ShaderValues`, `ShaderBlockValues` and `ShaderVariantValues` share.

	Each `write` method takes a `ShaderUniform`, found once (`getUniform`), and writes the value at its std140 offset at once, so nothing
	is looked up or converted when it draws. Every name here starts with `write`, so a typed class's generated `setX` members
	(`ShaderValueClasses`) never meet one, whatever a uniform is called.

	A value of the wrong kind for the uniform's type (a float for a `mat4`, an element past its end) throws, naming the uniform: it is
	the program's mistake. A handle the values' shader doesn't declare now (`ShaderUniform.declared` false, in a variant without it or
	after a reload removed it) is kept and written once the shader declares it.

	Colors: `writeColor` writes 0xAARRGGBB's channels as stored, each over 255, so 0 to 1 and still sRGB-encoded, as raylib and a 2D
	tint want; `writeLinearColor` decodes red, green and blue from sRGB to linear light first (alpha as stored), as three.js's color
	management does with a hex color. A color without alpha (0xRRGGBB) is written with `writeRgb` or `writeLinearRgb`, the latter with
	a scale (a light's color times its intensity); `writeColor` would read its top byte as alpha 0. A color above 1 otherwise is written
	with `writeVector3` or `writeVector`.

	A values made over a base (`ShaderValues.base`) reads, for each uniform it hasn't written, its base's value now: a block it hasn't
	written into is the base's bytes by reference, and its first write into one copies it (copy on write). */
class ShaderUniformValues {
	@:allow(helix.services.shaders)
	function new() {}

	/** Writes a uniform from a value held as data.

		@param uniform  The uniform.
		@param value  The value, written as its method writes it; a `Texture` is refused (it is a sampler's, `writeSamplerValue`).
		@param elementIndex  Optional. The index of the array element written first; defaults to 0. */
	public function write(uniform:ShaderUniform, value:ShaderValue, elementIndex:Int = 0):Void {
		switch value {
			case Float(v):
				writeFloat(uniform, v, elementIndex);
			case Vector(x, y, z, w):
				writeVector(uniform, x, y, z, w, elementIndex);
			case Color(c):
				writeColor(uniform, c, elementIndex);
			case LinearColor(c):
				writeLinearColor(uniform, c, elementIndex);
			case Rgb(c):
				writeRgb(uniform, c, elementIndex);
			case LinearRgb(c, scale):
				writeLinearRgb(uniform, c, scale, elementIndex);
			case Texture(_, _):
				throw 'shader values: ${uniform.name} is a uniform; a Texture value is a sampler\'s (writeSamplerValue)';
			case Bool(v):
				writeBool(uniform, v, elementIndex);
			case Matrix(m):
				writeMatrix(uniform, m, elementIndex);
			case Floats(values):
				writeFloats(uniform, values, elementIndex);
			case Int(v):
				writeInt(uniform, v, elementIndex);
			case Ints(values):
				writeInts(uniform, values, elementIndex);
		}
	}

	/** Writes a float uniform, or an element of one.

		@param uniform  The uniform.
		@param value  The value.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeFloat(uniform:ShaderUniform, value:Float, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeFloat", FLOAT);
		e[0] = value;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `vec2`, `vec3` or `vec4` uniform's components, as many as it has, or an element of one.

		@param uniform  The uniform.
		@param x  The first component.
		@param y  The second component.
		@param z  The third component, for a `vec3` or `vec4`.
		@param w  The fourth component, for a `vec4`.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeVector(uniform:ShaderUniform, x:Float, y:Float, z:Float, w:Float, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeVector", VECTORS);
		e[0] = x;
		e[1] = y;
		if (e.length > 2)
			e[2] = z;
		if (e.length > 3)
			e[3] = w;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `vec3` uniform, or an element of one.

		@param uniform  The uniform.
		@param x  The first component.
		@param y  The second component.
		@param z  The third component.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeVector3(uniform:ShaderUniform, x:Float, y:Float, z:Float, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeVector3", VEC3);
		e[0] = x;
		e[1] = y;
		e[2] = z;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `vec2` uniform, or an element of one.

		@param uniform  The uniform.
		@param x  The first component.
		@param y  The second component.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeVector2(uniform:ShaderUniform, x:Float, y:Float, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeVector2", VEC2);
		e[0] = x;
		e[1] = y;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `vec4` uniform as a color's red, green, blue and alpha, or a `vec3` as its red, green and blue, or an element of one.

		@param uniform  The uniform.
		@param color  The color, as 0xAARRGGBB.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeColor(uniform:ShaderUniform, color:Int, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeColor", COLORS);
		e[0] = (color >> 16 & 255) / 255;
		e[1] = (color >> 8 & 255) / 255;
		e[2] = (color & 255) / 255;
		if (e.length > 3)
			e[3] = (color >>> 24) / 255;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `vec3` or `vec4` uniform's red, green and blue from 0xRRGGBB as stored, each over 255, leaving a `vec4`'s fourth
		component as it was, or an element of one: a color without alpha, as three.js writes one (`0xff8040`), which `writeColor` would
		read as alpha 0.

		@param uniform  The uniform.
		@param rgb  The color, as 0xRRGGBB.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeRgb(uniform:ShaderUniform, rgb:Int, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeRgb", COLORS);
		e[0] = (rgb >> 16 & 255) / 255;
		e[1] = (rgb >> 8 & 255) / 255;
		e[2] = (rgb & 255) / 255;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `vec3` or `vec4` uniform's red, green and blue from 0xRRGGBB decoded from sRGB to linear light and multiplied by a
		scale, leaving a `vec4`'s fourth component as it was, or an element of one: three.js's `color.setHex(hex)` times a light's
		intensity.

		@param uniform  The uniform.
		@param rgb  The color, as 0xRRGGBB, sRGB-encoded.
		@param scale  Optional. What each linear channel is multiplied by; defaults to 1.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeLinearRgb(uniform:ShaderUniform, rgb:Int, scale:Float = 1, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeLinearRgb", COLORS);
		e[0] = linear((rgb >> 16 & 255) / 255) * scale;
		e[1] = linear((rgb >> 8 & 255) / 255) * scale;
		e[2] = linear((rgb & 255) / 255) * scale;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `vec4` uniform as a color decoded from sRGB to linear light (red, green and blue; alpha as stored), or a `vec3` as its red,
		green and blue so decoded, or an element of one.

		@param uniform  The uniform.
		@param color  The color, as 0xAARRGGBB, sRGB-encoded.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeLinearColor(uniform:ShaderUniform, color:Int, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeLinearColor", COLORS);
		e[0] = linear((color >> 16 & 255) / 255);
		e[1] = linear((color >> 8 & 255) / 255);
		e[2] = linear((color & 255) / 255);
		if (e.length > 3)
			e[3] = (color >>> 24) / 255;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `bool` uniform, as 1 or 0, or an element of one.

		@param uniform  The uniform.
		@param value  The value.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeBool(uniform:ShaderUniform, value:Bool, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeBool", BOOL);
		e[0] = value ? 1 : 0;
		changed(uniform, elementIndex, e);
	}

	/** Writes a `mat4` uniform, or an element of one.

		@param uniform  The uniform.
		@param matrix  The matrix.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeMatrix(uniform:ShaderUniform, matrix:Matrix3D, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeMatrix", MAT4);
		var m = matrix.values;
		for (i in 0...16)
			e[i] = m[i];
		changed(uniform, elementIndex, e);
	}

	/** Writes a float uniform from its floats in GLSL's order, packed: each element its type's floats one after another, with no
		padding (3 for a `vec3`, 9 for a `mat3` by columns), whatever std140 pads them to in the block.

		@param uniform  The uniform.
		@param values  The floats, a whole number of elements, which must not run past the uniform's last element: a write past it throws,
			writing nothing.
		@param firstElementIndex  Optional. The index of the first element written; defaults to 0. */
	public function writeFloats(uniform:ShaderUniform, values:Array<Float>, firstElementIndex:Int = 0):Void {
		writeMany(uniform, values, firstElementIndex, "writeFloats", FLOATS);
	}

	/** Writes an integer uniform (`int`, `uint` as the value's bits, `bool` as 0 or not), or the first component of an integer vector, or
		an element of one.

		@param uniform  The uniform.
		@param value  The value.
		@param elementIndex  Optional. The index of the array element written; defaults to 0. */
	public function writeInt(uniform:ShaderUniform, value:Int, elementIndex:Int = 0):Void {
		var e = element(uniform, elementIndex, "writeInt", INTEGERS);
		e[0] = value;
		changed(uniform, elementIndex, e);
	}

	/** Writes an integer, unsigned or `bool` uniform from integers in order, packed as `writeFloats` packs floats: an `ivecN`'s or
		`bvecN`'s components, elements one after another (a `bool` 0 or not).

		@param uniform  The uniform.
		@param values  The integers, a whole number of elements, which must not run past the uniform's last element: a write past it
			throws, writing nothing.
		@param firstElementIndex  Optional. The index of the first element written; defaults to 0. */
	public function writeInts(uniform:ShaderUniform, values:Array<Int>, firstElementIndex:Int = 0):Void {
		var floats = [for (v in values) (v : Float)];
		writeMany(uniform, floats, firstElementIndex, "writeInts", INTEGERS);
	}

	static final FLOAT = ["float"];
	static final VEC2 = ["vec2"];
	static final VEC3 = ["vec3"];
	static final VECTORS = ["vec2", "vec3", "vec4"];
	static final COLORS = ["vec3", "vec4"];
	static final BOOL = ["bool"];
	static final MAT4 = ["mat4"];
	static final FLOATS = ["float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4"];
	static final INTEGERS = [
		"int", "ivec2", "ivec3", "ivec4", "uint", "uvec2", "uvec3", "uvec4", "bool", "bvec2", "bvec3", "bvec4"
	];

	// What was written, by handle: each element's components as written, whatever the layout.
	@:allow(helix.services.shaders)
	final written = new haxe.ds.ObjectMap<ShaderUniform, helix.services.shaders.ShaderLayout.ShaderWritten>();

	// The type a handle has where these write it, or null where it isn't declared (a write is then kept and checked when it is).

	@:allow(helix.services.shaders)
	function typeOf(uniform:ShaderUniform):Null<ShaderValueType>
		return uniform.declared ? uniform.type : null;

	// The elements a handle has where these write it, or -1 where it isn't declared.
	function elementCountOf(uniform:ShaderUniform):Int
		return uniform.declared ? uniform.elementCount : -1;

	// What a new element starts as before a write fills part of it: what these read there now.
	function initial(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void {}

	// Called after a write has put an element's components in place: packs them.
	function changed(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void {}

	// The element a write fills, its type checked: the same array each time, as long as its type's components.
	function element(uniform:ShaderUniform, elementIndex:Int, method:String, types:Array<String>):Array<Float> {
		var type = typeOf(uniform);
		var count = elementCountOf(uniform);
		if (type != null && types.indexOf(type) < 0)
			throw 'shader values: $method can\'t write ${uniform.name}, a $type';
		if (elementIndex < 0 || count >= 0 && elementIndex >= count)
			throw 'shader values: ${uniform.name} has no element $elementIndex (it has ${count < 0 ? 1 : count})';
		var size = type == null ? 16 : type.componentCount * type.columnCount;
		var w = written.get(uniform);
		if (w == null)
			written.set(uniform, w = new helix.services.shaders.ShaderLayout.ShaderWritten());
		while (w.elements.length <= elementIndex)
			w.elements.push(null);
		var e = w.elements[elementIndex];
		if (e == null || e.length != size) {
			e = [for (_ in 0...size) 0.];
			initial(uniform, elementIndex, e);
			w.elements[elementIndex] = e;
		}
		return e;
	}

	// writeFloats and writeInts: elements packed one after another, checked whole before any is written.
	function writeMany(uniform:ShaderUniform, values:Array<Float>, first:Int, method:String, types:Array<String>):Void {
		var type = typeOf(uniform);
		if (type != null && types.indexOf(type) < 0)
			throw 'shader values: $method can\'t write ${uniform.name}, a $type';
		var size = type == null ? values.length : type.componentCount * type.columnCount;
		if (size == 0 || values.length % size != 0)
			throw 'shader values: $method gives ${values.length} numbers for ${uniform.name}, not a whole number of ${type}s';
		var count = elementCountOf(uniform),
			elements = Std.int(values.length / size);
		if (first < 0 || count >= 0 && first + elements > count)
			throw 'shader values: $method writes ${uniform.name}\'s elements $first to ${first + elements - 1}, past its $count';
		for (k in 0...elements) {
			var e = element(uniform, first + k, method, types);
			for (i in 0...size)
				e[i] = values[k * size + i];
			changed(uniform, first + k, e);
		}
	}

	// Takes another values' written elements as these values' own: a material's values replayed into a variant's.

	@:allow(helix.services.shaders)
	function copyWritten(from:ShaderUniformValues):Void
		for (uniform => w in from.written)
			for (index => e in w.elements)
				if (e != null)
					writeElement(uniform, index, e);

	// Writes one element as given, as a write method would; a kept value the declared type can't take is logged and dropped.

	@:allow(helix.services.shaders)
	function writeElement(uniform:ShaderUniform, elementIndex:Int, values:Array<Float>):Void {
		var type = typeOf(uniform), count = elementCountOf(uniform);
		if (type != null && (values.length < type.componentCount * type.columnCount || count >= 0 && elementIndex >= count)) {
			helix.log.Log.warn('shader values: a value kept for ${uniform.name} doesn\'t fit its ${type}; dropped', "shaders");
			return;
		}
		var size = type == null ? values.length : type.componentCount * type.columnCount;
		var w = written.get(uniform);
		if (w == null)
			written.set(uniform, w = new helix.services.shaders.ShaderLayout.ShaderWritten());
		while (w.elements.length <= elementIndex)
			w.elements.push(null);
		var e = values.slice(0, size);
		w.elements[elementIndex] = e;
		changed(uniform, elementIndex, e);
	}

	// sRGB to linear light, as three.js's color management decodes a hex color.
	static function linear(c:Float):Float
		return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}
