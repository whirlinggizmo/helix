package helix.services.shaders;

/** Represents where an attribute is in a vertex buffer's records, at a byte offset: by name, or by slot for a layer that numbers
	attributes as GL does (raylib's `rlSetVertexAttribute`). */
typedef ShaderVertexPlacement = {
	/** The attribute's name: its GLSL name, or the name `Shader.withNames` gave it. Optional; one of `name` and `slot` is given. */
	@:optional final name:String;

	/** The attribute's slot, its `layout(location = n)`, for a shader whose slots the layer fixes. Optional; one of `name` and `slot` is
		given. */
	@:optional final slot:Int;

	/** Its byte offset in a record. */
	final offset:Int;

	/** The number of floats a record holds for it, fewer than the attribute takes, the rest read as 0, 0, 1 as (0, 0, 0, 1) has them:
		a `vec3` position fed into a `vec4` input reads w 1, as GL feeds it. Optional; the attribute's own count when omitted. */
	@:optional final componentCount:Int;

	/** Whether a shader may leave it unread, as an unlit shader leaves a mesh's normals, unread meaning not declared or declared and
		not read alike; its bytes are then skipped. Optional; false by default, and an undeclared placement not marked so is refused. */
	@:optional final optional:Bool;
}
