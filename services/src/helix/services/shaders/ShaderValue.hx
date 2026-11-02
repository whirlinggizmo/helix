package helix.services.shaders;

import helix.math.Matrix3D;

/** Specifies a uniform's value for `ShaderUniformValues.write`, for code that holds values as data (a material's table of them).

	Each is written as its method writes it: `Vector` as `writeVector`, `Color` as `writeColor`, `LinearColor` as `writeLinearColor`. */
enum ShaderValue {
	/** A float. */
	Float(value:Float);

	/** A vector's components, as many as the uniform has. */
	Vector(x:Float, y:Float, z:Float, w:Float);

	/** A color, 0xAARRGGBB, its channels over 255. */
	Color(color:Int);

	/** A color, 0xAARRGGBB, decoded from sRGB to linear light. */
	LinearColor(color:Int);

	/** A color without alpha, 0xRRGGBB, as stored (`writeRgb`). */
	Rgb(rgb:Int);

	/** A color without alpha, 0xRRGGBB, decoded to linear light and multiplied by a scale (`writeLinearRgb`). */
	LinearRgb(rgb:Int, scale:Float);

	/** A texture and how it is sampled, for a sampler (`IShaderValues.writeSamplerValue`); `write` refuses it. */
	Texture(texture:Int, ?sampling:helix.platform.Sampling);

	/** A `bool`. */
	Bool(value:Bool);

	/** A `mat4`. */
	Matrix(matrix:Matrix3D);

	/** Floats in GLSL's order: a vector's components, a matrix's by columns, elements one after another. */
	Floats(values:Array<Float>);

	/** An integer. */
	Int(value:Int);

	/** Integers in order: an `ivecN`'s components, elements one after another. */
	Ints(values:Array<Int>);
}
