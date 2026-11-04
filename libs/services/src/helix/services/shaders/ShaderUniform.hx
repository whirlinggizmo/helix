package helix.services.shaders;

/** Represents a uniform, found once by name, which the values' `write` methods take: a block member, a struct's field, or a field of an
	array of structs.

	`getUniform` and `findUniform` (`IShaderHandles`) return it. The same name gives the same handle each time. It is never looked up
	again: when its shader is replaced in place (`Shader.reloadCount`), the shader updates it. A handle works on values of any shader,
	as on another variant of its set or a shader sharing its block: it is resolved there once, by name, and kept.

	An array of structs is not indexed by name. Each of its fields is one uniform whose elements are the array's (`lights.color`, with
	`elementCount` 4), so per-frame code builds no strings: `values.writeVector3(lightColor, r, g, b, i)`. A by-name layer holding paths
	like `lights[1].color` turns each into a handle and an element once (`getUniformPath`). */
class ShaderUniform {
	/** Gets the name it is found by: its GLSL path (`roughness`, `material.roughness`, `lights.color`), or the name `Shader.withNames`
		gave it. */
	public final name:String;

	/** Gets its type: its declaration's, or, for one reserved (`reserveUniform`) and not declared yet, `Float` until it is. */
	public var type(default, null):ShaderValueType;

	/** Gets the number of elements: 1, an array's length, or the length of the array of structs it is a field of. */
	public var elementCount(default, null):Int;

	/** Gets the GLSL name of the block it is in: a named block, a shared block's (`ShaderSharedBlock.name`), or `helix_uniforms` for a
		loose uniform. */
	public var blockName(default, null):String;

	/** Gets a value indicating whether its block is shared (`ShaderOptions.shared`), so it is written on a `ShaderBlockValues`. */
	public var shared(default, null):Bool;

	/** Gets a value indicating whether its shader's code reads it, as the compiler finds: GL's `glGetUniformLocation` gives -1 for one
		that isn't, which a layer matching GL (helix-raylib) does too. Every declared uniform is reflected, read or not. It is the whole
		uniform's: an array read at any element is active, as the compiler can't tell which elements a dynamic index reads. */
	public var active(default, null):Bool;

	/** Gets a value indicating whether its shader declares it now. False after a reload removed it, or in a variant without it: values
		written through it are then kept, and written once a reload brings it back. */
	public var declared(default, null):Bool;

	// A number of its own, by which a shader keeps where it is (Shader.placesOf), and its type's shape.
	@:allow(helix.services.shaders)
	final id:Int = takeId();
	@:allow(helix.services.shaders)
	var shape(default, null):helix.services.shaders.ShaderLayout.ShaderShape;

	// The next id, counted from the first handle, as a shader may be read (in a build macro) before this class's statics are.
	static var nextId:Null<Int> = null;

	static function takeId():Int {
		var id = nextId == null ? 0 : nextId;
		nextId = id + 1;
		return id;
	}

	@:allow(helix.services.shaders)
	function new(name:String, type:ShaderValueType, elementCount:Int, blockName:String, shared:Bool) {
		this.name = name;
		shape = helix.services.shaders.ShaderLayout.ShaderShape.of(type);
		this.type = type;
		this.elementCount = elementCount;
		this.blockName = blockName;
		this.shared = shared;
		active = true;
		declared = true;
	}

	// Takes what a shader now declares for it, or that it declares it no more.

	@:allow(helix.services.shaders)
	function update(type:ShaderValueType, elementCount:Int, blockName:String, shared:Bool, active:Bool, declared:Bool):Void {
		this.type = type;
		shape = helix.services.shaders.ShaderLayout.ShaderShape.of(type);
		this.elementCount = elementCount;
		this.blockName = blockName;
		this.shared = shared;
		this.active = active;
		this.declared = declared;
	}
}
