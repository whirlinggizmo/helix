package helix.raylib;

/** Represents raylib's `Shader`: a program and the locations of what it declares.

	Made by `LoadCompiledShaderAsync` or `LoadCompiledShaderFromData` (`helix.raylib.extras.Shaders`), or by helix-raylib's own, such as
	`LoadPbrShader`. */
class Shader {
	/** Gets the program's handle, 0 for none. */
	@:allow(helix.raylib)
	public var id(default, null):Int;

	/** Gets the locations of the values raylib sets itself, by `SHADER_LOC_*`, -1 for each the shader doesn't declare.

		A program may set them, as raylib's programs do. Values are found by name here, so setting them changes nothing. */
	public var locs(default, null):Array<Int>;

	@:allow(helix.raylib)
	var program:Null<helix.raylib.internal.Program>;

	// A material's copy (`Material.shader`), holding the material's count, as a map's copy of a texture does (`Texture2D.mapped`).
	@:allow(helix.raylib)
	var mapped = false;

	// Whether a material's copy has let go of the material's count already, through `UnloadShader`.
	@:allow(helix.raylib)
	var spent = false;

	/** Creates a shader's record. See `LoadCompiledShaderAsync` for making a shader.

		@param id  The handle.
		@param locs  The locations, by `SHADER_LOC_*`. */
	@:allow(helix.raylib)
	function new(id:Int, locs:Array<Int>, program:Null<helix.raylib.internal.Program>) {
		this.id = id;
		this.locs = locs;
		this.program = program;
	}
}
