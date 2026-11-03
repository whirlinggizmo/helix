package helix.platform;

/** Represents a member of a uniform block that a program declares, as a leaf: its path, its GLSL type, where it starts in the block's
	bytes, and how many elements it has.

	The block is laid out by std140: each element of an array, and each column of a matrix, starts on a 16-byte boundary, and a `vec3`
	is followed by room for one float. A struct member is reflected as its fields, each with its path (`light.color`); a field of an
	array of structs is one member whose elements are the array's (`lights.color`, `elementCount` the array's length, `stride` the
	struct's size). A member of a block with an instance name (`uniform Camera { ... } camera;`) has a path starting with that name
	(`camera.viewProjection`), as the GLSL writes it. */
typedef ShaderMember = {
	/** The member's path in the GLSL: its name, or a struct field's `name.field`. */
	final glslName:String;

	/** The GLSL type: `float`, `vec2`, `vec3`, `vec4`, `mat2`, `mat3`, `mat4`, `int`, `ivec2`, `ivec3`, `ivec4`, `uint`, `uvec2`,
		`uvec3`, `uvec4`, `bool`, `bvec2`, `bvec3` or `bvec4`. A `bool` takes 4 bytes, 0 or 1, as a `uint` does. */
	final type:String;

	/** The byte offset of its first element in the block. */
	final offset:Int;

	/** The number of elements: 1, an array's length, or the length of the array of structs it is a field of. */
	final elementCount:Int;

	/** Whether the program's code reads it, as glslang's reflection of the stages finds; an unread one is still reflected, at its place.
		It is the whole member's: an array read at any element is active. */
	final active:Bool;

	/** The bytes from one element to the next: 16 for a scalar or a vector, 16 a column for a matrix (64 for a `mat4`), a struct's size for
		a field of an array of structs. */
	final stride:Int;
}
