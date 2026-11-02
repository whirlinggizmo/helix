package helix.render;

import haxe.io.Bytes;
import helix.platform.VertexFormat;
import helix.services.shaders.ShaderVertexPlacement;

/** The values helix-render's attributes read where a draw's own buffers don't feed them, kept in a record a buffer of their own (or an
	instance's record) holds, so every attribute a shader declares is fed by a buffer.

	The platform's contract has an unfed attribute read its pipeline's constant (`PipelineDesc.attributeConstants`), but sokol_gfx's GL
	adapter refuses a layout whose fed attributes leave a gap of slots ("layout.attrs is not continuous"), and draws nothing past the gap
	in a release build. Until the adapter fills such gaps itself (a platform change, for review), helix-render feeds them from these
	records: its batch draws from one static record, stepped once an instance; its meshes from each instance's record. */
@:noCompletion
@:allow(helix.render)
class RenderConstants {
	/** Each attribute's place in a batch draw's constants record, its format and its value. */
	static final BATCH:Array<{
		name:String,
		offset:Int,
		format:VertexFormat,
		values:Array<Float>
	}> = [
		{
			name: "vertexNormal",
			offset: 0,
			format: Float3,
			values: [0, 0, 1]
		},
		{
			name: "vertexCorner",
			offset: 12,
			format: Float2,
			values: [0, 0]
		},
		{
			name: "vertexLineEnd",
			offset: 20,
			format: Float3,
			values: [0, 0, 0]
		},
		{
			name: "vertexTangent",
			offset: 32,
			format: Float4,
			values: [1, 0, 0, 1]
		},
		{
			name: "vertexTexCoord2",
			offset: 48,
			format: Float2,
			values: [0, 0]
		},
		{
			name: "vertexJoints",
			offset: 56,
			format: Float4,
			values: [0, 0, 0, 0]
		},
		{
			name: "vertexWeights",
			offset: 72,
			format: Float4,
			values: [0, 0, 0, 0]
		},
		{
			name: "instanceModel",
			offset: 88,
			format: Float4,
			values: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
		},
		{
			name: "instanceColor",
			offset: 152,
			format: Float4,
			values: [1, 1, 1, 1]
		},
		{
			name: "vertexTexCoord",
			offset: 168,
			format: Float2,
			values: [0, 0]
		},
		{
			name: "vertexColor",
			offset: 176,
			format: Float4,
			values: [1, 1, 1, 1]
		},
		{
			name: "vertexCustomData",
			offset: 192,
			format: Float4,
			values: [0, 0, 0, 0]
		}
	];

	/** The bytes of a batch draw's constants record. */
	static inline final BATCH_STRIDE = 208;

	/** Each attribute's place in a mesh's instance record, after the copy's matrix (at 0) and color (at 64), its format and its value. */
	static final MESH:Array<{
		name:String,
		offset:Int,
		format:VertexFormat,
		values:Array<Float>
	}> = [
		{
			name: "vertexNormal",
			offset: 68,
			format: Float3,
			values: [0, 0, 1]
		},
		{
			name: "vertexTexCoord",
			offset: 80,
			format: Float2,
			values: [0, 0]
		},
		{
			name: "vertexTexCoord2",
			offset: 88,
			format: Float2,
			values: [0, 0]
		},
		{
			name: "vertexTangent",
			offset: 96,
			format: Float4,
			values: [1, 0, 0, 1]
		},
		{
			name: "vertexColor",
			offset: 112,
			format: Float4,
			values: [1, 1, 1, 1]
		},
		{
			name: "vertexJoints",
			offset: 128,
			format: Float4,
			values: [0, 0, 0, 0]
		},
		{
			name: "vertexWeights",
			offset: 144,
			format: Float4,
			values: [0, 0, 0, 0]
		},
		{
			name: "vertexCorner",
			offset: 160,
			format: Float2,
			values: [0, 0]
		}
	];

	/** The bytes of a mesh's instance record. */
	static inline final MESH_STRIDE = 168;

	/** The placements of a table's attributes that a buffer doesn't feed, each optional. */
	static function placements(table:Array<{
		name:String,
		offset:Int,
		format:VertexFormat,
		values:Array<Float>
	}>, fed:Array<String>):Array<ShaderVertexPlacement> {
		return [
			for (c in table)
				if (fed.indexOf(c.name) < 0) {
					name: c.name,
					offset: c.offset,
					format: c.format,
					optional: true
				}
		];
	}

	/** A record holding a table's values at their places: a batch draw's constants, or a mesh's copy placed where it is and white. */
	static function record(table:Array<{
		name:String,
		offset:Int,
		format:VertexFormat,
		values:Array<Float>
	}>, stride:Int, mesh:Bool):Bytes {
		var bytes = Bytes.alloc(stride);
		bytes.fill(0, stride, 0);
		if (mesh) {
			for (i in 0...16)
				bytes.setFloat(i * 4, i % 5 == 0 ? 1 : 0);
			bytes.setInt32(64, -1);
		}
		for (c in table)
			for (i in 0...c.values.length)
				bytes.setFloat(c.offset + i * 4, c.values[i]);
		return bytes;
	}
}
