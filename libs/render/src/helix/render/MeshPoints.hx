package helix.render;

import haxe.io.Bytes;
import helix.render.RenderDraw.RenderPipeline;
import helix.services.shaders.Shader;
import helix.services.shaders.ShaderValues;
import helix.services.shaders.ShaderVertexLayout;

/** `Batch3D`'s meshes drawn as points larger than a pixel: each vertex a square of six corners made in the vertex stage, the mesh's
	records one an instance, the corners carrying an instanced copy's matrix and color.

	It is linked only by a program setting `Batch3D.pointSize` or `pointSizeAttenuated` (`install`), so a program drawing no large points
	carries none of it. */
@:noCompletion
@:allow(helix.render)
@:access(helix.render.Batch3D)
@:access(helix.render.GpuMesh3D)
class MeshPoints {
	// The bytes of a corner's record: its corner, then a copy's matrix and color, as an instance's record holds them.
	static inline final CORNER_STRIDE = 8 + GpuMesh3D.INSTANCE_STRIDE;
	// A square as two triangles of corners, x and y each.
	static final CORNERS = [-1., -1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1];
	// The layout of large points for each mesh layout.
	static final layouts = new haxe.ds.ObjectMap<ShaderVertexLayout, ShaderVertexLayout>();

	// The first corner of the draw being recorded, written at its first view.
	static var firstCorner = 0;

	/** Makes the batches draw meshes as large points. */
	static function install():Void {
		Batch3D.pointsPipeline = pipeline;
		Batch3D.pointsRecord = record;
	}

	/** The pipeline a mesh's large points are drawn by: triangles from no index buffer, neither face culled, in its points' layout, blended,
		tested and written as the draw's state says, or else its material. */
	static function pipeline(batch:Batch3D, s:Shader, mesh:GpuMesh3D, material:Material3D, state:Null<MeshState3D>):RenderPipeline {
		var r = batch.renderer;
		return r.pipelineFor(s,
			r.stateFor(Triangles,
				false, state != null && state.blend != null ? state.blend : material.blend, state != null && state.depthTest != null ? state.depthTest : material.depthTest,
				state != null
				&& state.depthWrite != null ? state.depthWrite : material.depthWrite,
				None, state != null && state.colorWrite != null ? state.colorWrite : material.colorWrite),
			layoutOf(mesh));
	}

	/** Records a mesh's large points in one view: one draw, or one for each instanced copy, its six corners carrying the copy. The
		corners are written at the first view. */
	static function record(batch:Batch3D, spec:RenderPipeline, mesh:GpuMesh3D, values:ShaderValues, instanced:Bool, firstInstance:Int, instanceCount:Int,
			viewIndex:Int):Void {
		if (viewIndex == 0)
			firstCorner = cornersOf(batch, instanced, firstInstance, instanceCount);
		var r = batch.renderer;
		for (copy in 0...(instanced ? instanceCount : 1)) {
			var d = r.makeDraw(spec);
			d.setBuffer(0, mesh.buffer);
			if (instanced)
				d.setBuffer(1, 0, batch.copyCorners);
			else
				d.setBuffer(1, batch.pointCorners);
			d.first = firstCorner + copy * 6;
			d.count = 6;
			d.firstInstance = 0;
			d.instanceCount = mesh.vertexCount;
			values.capture(d.snapshot);
			r.record(d);
		}
	}

	/** The layout a mesh's large points are drawn by: its records, as its own layout places them, one an instance, beside the corners. */
	static function layoutOf(mesh:GpuMesh3D):ShaderVertexLayout {
		var found = layouts.get(mesh.layout);
		if (found != null)
			return found;
		var records = mesh.layout.buffers[0];
		found = new ShaderVertexLayout([
			{stride: records.stride, instanced: true, placements: records.placements},
			{
				stride: CORNER_STRIDE,
				placements: [
					{
						name: "vertexCorner",
						offset: 0,
						format: Float2,
						optional: true
					},
					{name: "instanceModel", offset: 8, optional: true},
					{
						name: "instanceColor",
						offset: 8 + 64,
						format: UByte4Norm,
						optional: true
					}
				]
			}
		], Renderer.unfedAttributes);
		layouts.set(mesh.layout, found);
		return found;
	}

	/** The first of a large point's six corners in the buffer its draws read as their second: the batch's static corners of a copy placed
		where it is and white (`pointCorners`), or six written into the frame's stream (`copyCorners`) for each instanced copy, from the
		copies' records. */
	static function cornersOf(batch:Batch3D, instanced:Bool, firstInstance:Int, instanceCount:Int):Int {
		var corners = CORNERS;
		if (!instanced) {
			if (batch.pointCorners == 0) {
				var b = Bytes.alloc(6 * CORNER_STRIDE);
				for (k in 0...6) {
					var at = k * CORNER_STRIDE;
					b.setFloat(at, corners[k * 2]);
					b.setFloat(at + 4, corners[k * 2 + 1]);
					b.blit(at + 8, batch.instanceTemplate, 0, GpuMesh3D.INSTANCE_STRIDE);
				}
				batch.pointCorners = batch.renderer.staticBuffer(b, false);
			}
			return 0;
		}
		if (batch.copyCorners == null)
			batch.copyCorners = batch.renderer.stream("corners3d", CORNER_STRIDE, Batch3D.layoutOf(false));
		var stream = batch.copyCorners,
			first = stream.count,
			from = batch.instances;
		for (copy in 0...instanceCount) {
			var record = (firstInstance + copy) * GpuMesh3D.INSTANCE_STRIDE;
			for (k in 0...6) {
				var at = stream.reserve(1), b = stream.bytes;
				b.setFloat(at, corners[k * 2]);
				b.setFloat(at + 4, corners[k * 2 + 1]);
				b.blit(at + 8, from.bytes, record, GpuMesh3D.INSTANCE_STRIDE);
			}
		}
		return first;
	}
}
