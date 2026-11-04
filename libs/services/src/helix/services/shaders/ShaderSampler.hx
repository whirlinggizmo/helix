package helix.services.shaders;

/** Represents a texture a shader samples, found once by name, which `writeTexture` and `shareTexture` take.

	`getSampler` and `findSampler` (`IShaderHandles`) return it. The same name gives the same handle each time, updated in place when its
	shader is reloaded, and it works on values of any shader, resolved there once by name. A sampler array (`uniform sampler2D maps[4]`)
	is refused while the program builds: every adapter binds one texture a slot.

	A sampler given no texture reads the platform's clear texture of its kind (`IGraphics.draw`): 0 in every channel for 2D, cube,
	array and data textures, and for a shadow map one cleared to the farthest depth, so a comparison reads lit (1). A render target
	sampled in a later pass reads the right way up on every adapter (stored top row first, texture coordinates from 0 at the top).

	A texture handle is an `Int`, so the values can't tell its kind: one of another kind than `kind` is the program's mistake, which
	`IGraphics.draw` refuses. */
class ShaderSampler {
	/** Gets the name it is found by: its GLSL name, or the name `Shader.withNames` gave it. */
	public final name:String;

	/** Gets the kind of texture it reads. */
	public var kind(default, null):ShaderSamplerKind;

	/** Gets its texture slot in its shader, as `IGraphics.draw`'s `textures` holds it; on a set's handle, the first variant's. */
	public var slot(default, null):Int;

	/** Gets a value indicating whether its shader's code samples it, as the compiler finds; one unsampled is still reflected and bound. */
	public var active(default, null):Bool;

	/** Gets a value indicating whether its shader declares it now: false after a reload removed it, or in a variant without it. */
	public var declared(default, null):Bool;

	// Its name's id (ShaderNameIds), by which values keep the texture it is given.
	@:allow(helix.services.shaders)
	final nameId:Int;

	@:allow(helix.services.shaders)
	function new(name:String, kind:ShaderSamplerKind, slot:Int) {
		this.name = name;
		nameId = helix.services.shaders.ShaderLayout.ShaderNameIds.of(name);
		this.kind = kind;
		this.slot = slot;
		active = true;
		declared = true;
	}

	// Takes what a shader now declares for it, or that it declares it no more.

	@:allow(helix.services.shaders)
	function update(kind:ShaderSamplerKind, slot:Int, active:Bool, declared:Bool):Void {
		this.kind = kind;
		this.slot = slot;
		this.active = active;
		this.declared = declared;
	}
}
