package helix.ray;

/** Represents raylib's `Shader`: a program, made by `Raylib.LoadShader` or `Raylib.LoadShaderFromMemory`, and the locations of what it
	declares. */
class Shader {
	/** Gets the program's handle, 0 for none. */
	@:allow(helix.ray)
	public var id(default, null):Int;

	/** Gets the locations of the values raylib sets itself, by `SHADER_LOC_*`, -1 for each it doesn't declare. A program may set them, as
		raylib's do; values are found by name here, so they change nothing. */
	public var locs(default, null):Array<Int>;

	@:allow(helix.ray)
	var program:Null<helix.ray.internal.Program>;

	/** Creates a shader's record. Shaders are made by `Raylib.LoadShader`.

		@param id  The handle.
		@param locs  The locations, by `SHADER_LOC_*`. */
	@:allow(helix.ray)
	function new(id:Int, locs:Array<Int>, program:Null<helix.ray.internal.Program>) {
		this.id = id;
		this.locs = locs;
		this.program = program;
	}
}
