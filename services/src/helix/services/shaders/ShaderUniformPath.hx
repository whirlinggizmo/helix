package helix.services.shaders;

/** Represents a uniform path as GLSL and three.js write it (`pointLights[1].color`, `bones[3]`), turned once into the uniform and the
	element it names.

	`getUniformPath` and `findUniformPath` (`IShaderHandles`) return it, the same object for the same path, so a layer that sets values by
	such names parses each once: `values.writeColor(path.uniform, color, path.elementIndex)`. */
class ShaderUniformPath {
	/** Gets the path as given. */
	public final path:String;

	/** Gets the uniform it names (`pointLights.color`). */
	public final uniform:ShaderUniform;

	/** Gets the index of the element it names: the index in its brackets, or 0. */
	public final elementIndex:Int;

	@:allow(helix.services.shaders)
	function new(path:String, uniform:ShaderUniform, elementIndex:Int) {
		this.path = path;
		this.uniform = uniform;
		this.elementIndex = elementIndex;
	}
}
