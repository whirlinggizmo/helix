package helix.services.shaders;

/** Specifies the GLSL type of a uniform or a vertex attribute, as its GLSL name. */
enum abstract ShaderValueType(String) to String {
	/** One float. */
	var Float = "float";

	/** Two floats. */
	var Vec2 = "vec2";

	/** Three floats; in a block it takes 16 bytes' alignment and 12 of room. */
	var Vec3 = "vec3";

	/** Four floats. */
	var Vec4 = "vec4";

	/** A 2x2 matrix of floats, by columns, each column 16 bytes in a block. */
	var Mat2 = "mat2";

	/** A 3x3 matrix of floats, by columns, each column 16 bytes in a block. */
	var Mat3 = "mat3";

	/** A 4x4 matrix of floats, by columns. */
	var Mat4 = "mat4";

	/** One 32-bit integer. */
	var Int = "int";

	/** Two integers. */
	var Ivec2 = "ivec2";

	/** Three integers. */
	var Ivec3 = "ivec3";

	/** Four integers. */
	var Ivec4 = "ivec4";

	/** One `bool`, 4 bytes in a block, written as 0 or 1 (`writeBool`, `writeInt`). */
	var Bool = "bool";

	/** Two `bool`s. */
	var Bvec2 = "bvec2";

	/** Three `bool`s. */
	var Bvec3 = "bvec3";

	/** Four `bool`s. */
	var Bvec4 = "bvec4";

	/** One 32-bit unsigned integer, written as an `Int`'s bits (`writeInt`). */
	var Uint = "uint";

	/** Two unsigned integers. */
	var Uvec2 = "uvec2";

	/** Three unsigned integers. */
	var Uvec3 = "uvec3";

	/** Four unsigned integers. */
	var Uvec4 = "uvec4";

	/** Gets the number of components in one column: 1 for a scalar, 2 to 4 for a vector, a matrix's rows. */
	public var componentCount(get, never):StdTypes.Int;

	/** Gets the number of columns: a matrix's 2 to 4, and 1 for anything else. As a vertex attribute, a matrix takes a slot a column. */
	public var columnCount(get, never):StdTypes.Int;

	/** Gets a value indicating whether it holds integers, unsigned integers or bools rather than floats. */
	public var integer(get, never):StdTypes.Bool;

	function get_componentCount():StdTypes.Int {
		var last = this.charCodeAt(this.length - 1);
		return last >= "2".code && last <= "4".code ? last - "0".code : 1;
	}

	function get_columnCount():StdTypes.Int
		return StringTools.startsWith(this, "mat") ? this.charCodeAt(3) - "0".code : 1;

	function get_integer():StdTypes.Bool
		return !(StringTools.startsWith(this, "float") || StringTools.startsWith(this, "vec") || StringTools.startsWith(this, "mat"));
}
