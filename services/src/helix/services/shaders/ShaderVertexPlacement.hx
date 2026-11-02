package helix.services.shaders;

import helix.platform.VertexFormat;

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

	/** How a record holds it (`VertexFormat`): floats, half floats, or normalized integers read as floats. A format of fewer components
		than the attribute takes reads the rest as 0, 0, 1 as (0, 0, 0, 1) has them (a `Float3` position fed into a `vec4` input reads w 1,
		as GL feeds it); one of more reads the first ones (a `Byte4Norm` normal into a `vec3`). A matrix takes it for each column, each
		column its `bytes` after the last. Optional; the attribute's own floats when omitted (`Float3` for a `vec3`, a `Float4` a column
		for a `mat4`). */
	@:optional final format:VertexFormat;

	/** Whether a shader may leave it unread, as an unlit shader leaves a mesh's normals, unread meaning not declared or declared and
		not read alike; its bytes are then skipped. Optional; false by default, and an undeclared placement not marked so is refused. */
	@:optional final optional:Bool;
}
