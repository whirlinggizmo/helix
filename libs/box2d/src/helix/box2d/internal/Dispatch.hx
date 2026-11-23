package helix.box2d.internal;

import helix.box2d.*;
import helix.box2d.internal.Calls.*;

private typedef F32 = #if cpp cpp.Float32 #else Float #end;

/** Written by tools/gen_box2d.py: the Haxe end of each callback Box2D calls, reading its arguments and calling the function
	its slot holds. A struct or an id a callback receives is reused between calls. */
#if cpp
@:cppInclude("hb.h")
@:cppFileCode("#include <hx/Native.h>")
#end
@:noCompletion
class Dispatch {
	static var scratch0b2CastResultCallbackFcn = Init.makeB2ShapeId();
	static var scratch0b2CustomFilterCallbackFcn = Init.makeB2ShapeId();
	static var scratch0b2DebugDraw_DrawBoundsFcn = Init.makeB2AABB();
	static var scratch0b2DebugDraw_DrawCircleFcn = new B2Vec2();
	static var scratch0b2DebugDraw_DrawLineFcn = new B2Vec2();
	static var scratch0b2DebugDraw_DrawPointFcn = new B2Vec2();
	static var scratch0b2DebugDraw_DrawPolygonFcn = Init.makeB2Transform();
	static var scratch0b2DebugDraw_DrawSolidCapsuleFcn = new B2Vec2();
	static var scratch0b2DebugDraw_DrawSolidCircleFcn = Init.makeB2Transform();
	static var scratch0b2DebugDraw_DrawSolidPolygonFcn = Init.makeB2Transform();
	static var scratch0b2DebugDraw_DrawStringFcn = new B2Vec2();
	static var scratch0b2DebugDraw_DrawTransformFcn = Init.makeB2Transform();
	static var scratch0b2OverlapResultCallbackFcn = Init.makeB2ShapeId();
	static var scratch0b2PlaneResultCallbackFcn = Init.makeB2ShapeId();
	static var scratch0b2PreContinuousCallbackFcn = Init.makeB2ShapeId();
	static var scratch0b2PreSolveCallbackFcn = Init.makeB2ShapeId();
	static var scratch1b2CastResultCallbackFcn = new B2Vec2();
	static var scratch1b2CustomFilterCallbackFcn = Init.makeB2ShapeId();
	static var scratch1b2DebugDraw_DrawLineFcn = new B2Vec2();
	static var scratch1b2DebugDraw_DrawSolidCapsuleFcn = new B2Vec2();
	static var scratch1b2DebugDraw_DrawSolidCircleFcn = new B2Vec2();
	static var scratch1b2PreContinuousCallbackFcn = Init.makeB2ShapeId();
	static var scratch1b2PreSolveCallbackFcn = Init.makeB2ShapeId();
	static var scratch2b2CastResultCallbackFcn = new B2Vec2();
	static var scratch2b2PreContinuousCallbackFcn = new B2Vec2();
	static var scratch3b2PreContinuousCallbackFcn = new B2Vec2();
	static var scratchB2Manifold = new B2Manifold();
	static var scratchB2PlaneResult = new B2PlaneResult();
	static var scratchB2Vec2s:Array<B2Vec2> = [];

	/** The callbacks, natively each handed to hb.c, in a page as the module's imports. */
	public static function hooks():Dynamic {
		#if cpp
		untyped __cpp__("hb_set_hb_cb_b2CastResultCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2CastResultCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2CustomFilterCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2CustomFilterCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2FrictionCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2FrictionCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2LogCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2LogCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2OverlapResultCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2OverlapResultCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2PlaneResultCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2PlaneResultCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2PreContinuousCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2PreContinuousCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2PreSolveCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2PreSolveCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2RestitutionCallbackFcn((void *){0})", cpp.Callable.fromStaticFunction(b2RestitutionCallbackFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawPolygonFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawPolygonFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawSolidPolygonFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawSolidPolygonFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawCircleFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawCircleFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawSolidCircleFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawSolidCircleFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawSolidCapsuleFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawSolidCapsuleFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawLineFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawLineFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawTransformFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawTransformFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawPointFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawPointFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawStringFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawStringFcn));
		untyped __cpp__("hb_set_hb_cb_b2DebugDraw_DrawBoundsFcn((void *){0})", cpp.Callable.fromStaticFunction(b2DebugDraw_DrawBoundsFcn));
		return null;
		#else
		return {
			hb_cb_b2CastResultCallbackFcn: b2CastResultCallbackFcn,
			hb_cb_b2CustomFilterCallbackFcn: b2CustomFilterCallbackFcn,
			hb_cb_b2FrictionCallbackFcn: b2FrictionCallbackFcn,
			hb_cb_b2LogCallbackFcn: b2LogCallbackFcn,
			hb_cb_b2OverlapResultCallbackFcn: b2OverlapResultCallbackFcn,
			hb_cb_b2PlaneResultCallbackFcn: b2PlaneResultCallbackFcn,
			hb_cb_b2PreContinuousCallbackFcn: b2PreContinuousCallbackFcn,
			hb_cb_b2PreSolveCallbackFcn: b2PreSolveCallbackFcn,
			hb_cb_b2RestitutionCallbackFcn: b2RestitutionCallbackFcn,
			hb_cb_b2DebugDraw_DrawPolygonFcn: b2DebugDraw_DrawPolygonFcn,
			hb_cb_b2DebugDraw_DrawSolidPolygonFcn: b2DebugDraw_DrawSolidPolygonFcn,
			hb_cb_b2DebugDraw_DrawCircleFcn: b2DebugDraw_DrawCircleFcn,
			hb_cb_b2DebugDraw_DrawSolidCircleFcn: b2DebugDraw_DrawSolidCircleFcn,
			hb_cb_b2DebugDraw_DrawSolidCapsuleFcn: b2DebugDraw_DrawSolidCapsuleFcn,
			hb_cb_b2DebugDraw_DrawLineFcn: b2DebugDraw_DrawLineFcn,
			hb_cb_b2DebugDraw_DrawTransformFcn: b2DebugDraw_DrawTransformFcn,
			hb_cb_b2DebugDraw_DrawPointFcn: b2DebugDraw_DrawPointFcn,
			hb_cb_b2DebugDraw_DrawStringFcn: b2DebugDraw_DrawStringFcn,
			hb_cb_b2DebugDraw_DrawBoundsFcn: b2DebugDraw_DrawBoundsFcn
		};
		#end
	}

	static function b2CastResultCallbackFcn(slot:Int, shapeId_index1:Int, shapeId_world0:Int, shapeId_generation:Int, point_x:F32, point_y:F32, normal_x:F32, normal_y:F32, fraction:F32):F32 {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var shapeId = scratch0b2CastResultCallbackFcn;
		shapeId.index1 = shapeId_index1;
		shapeId.world0 = shapeId_world0;
		shapeId.generation = shapeId_generation;
		var point = scratch1b2CastResultCallbackFcn;
		point.x = point_x;
		point.y = point_y;
		var normal = scratch2b2CastResultCallbackFcn;
		normal.x = normal_x;
		normal.y = normal_y;
		var f:B2CastResultCallbackFcn = Callbacks.get(slot, 0);
		var result = f(shapeId, point, normal, fraction, Callbacks.context(slot));
		return result;
	}

	static function b2CustomFilterCallbackFcn(slot:Int, shapeIdA_index1:Int, shapeIdA_world0:Int, shapeIdA_generation:Int, shapeIdB_index1:Int, shapeIdB_world0:Int, shapeIdB_generation:Int):Int {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var shapeIdA = scratch0b2CustomFilterCallbackFcn;
		shapeIdA.index1 = shapeIdA_index1;
		shapeIdA.world0 = shapeIdA_world0;
		shapeIdA.generation = shapeIdA_generation;
		var shapeIdB = scratch1b2CustomFilterCallbackFcn;
		shapeIdB.index1 = shapeIdB_index1;
		shapeIdB.world0 = shapeIdB_world0;
		shapeIdB.generation = shapeIdB_generation;
		var f:B2CustomFilterCallbackFcn = Callbacks.get(slot, 0);
		var result = f(shapeIdA, shapeIdB, Callbacks.context(slot));
		return result ? 1 : 0;
	}

	static function b2FrictionCallbackFcn(slot:Int, frictionA:F32, userMaterialIdA_low:Int, userMaterialIdA_high:Int, frictionB:F32, userMaterialIdB_low:Int, userMaterialIdB_high:Int):F32 {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var f:B2FrictionCallbackFcn = Callbacks.worldFunction(slot, "b2FrictionCallbackFcn");
		var result = f(frictionA, haxe.Int64.make(userMaterialIdA_high, userMaterialIdA_low), frictionB, haxe.Int64.make(userMaterialIdB_high, userMaterialIdB_low));
		return result;
	}

	static function b2LogCallbackFcn(slot:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		Io.beginBack();
		var message = Io.rs();
		var f:B2LogCallbackFcn = Callbacks.log;
		if (f == null)
			f = Callbacks.print;
		f(message);
	}

	static function b2OverlapResultCallbackFcn(slot:Int, shapeId_index1:Int, shapeId_world0:Int, shapeId_generation:Int):Int {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var shapeId = scratch0b2OverlapResultCallbackFcn;
		shapeId.index1 = shapeId_index1;
		shapeId.world0 = shapeId_world0;
		shapeId.generation = shapeId_generation;
		var f:B2OverlapResultCallbackFcn = Callbacks.get(slot, 0);
		var result = f(shapeId, Callbacks.context(slot));
		return result ? 1 : 0;
	}

	static function b2PlaneResultCallbackFcn(slot:Int, shapeId_index1:Int, shapeId_world0:Int, shapeId_generation:Int):Int {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		Io.beginBack();
		var shapeId = scratch0b2PlaneResultCallbackFcn;
		shapeId.index1 = shapeId_index1;
		shapeId.world0 = shapeId_world0;
		shapeId.generation = shapeId_generation;
		var plane = rdB2PlaneResult(scratchB2PlaneResult);
		var f:B2PlaneResultCallbackFcn = Callbacks.get(slot, 0);
		var result = f(shapeId, plane, Callbacks.context(slot));
		return result ? 1 : 0;
	}

	static function b2PreContinuousCallbackFcn(slot:Int, shapeIdA_index1:Int, shapeIdA_world0:Int, shapeIdA_generation:Int, shapeIdB_index1:Int, shapeIdB_world0:Int, shapeIdB_generation:Int, point_x:F32, point_y:F32, normal_x:F32, normal_y:F32):Int {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var shapeIdA = scratch0b2PreContinuousCallbackFcn;
		shapeIdA.index1 = shapeIdA_index1;
		shapeIdA.world0 = shapeIdA_world0;
		shapeIdA.generation = shapeIdA_generation;
		var shapeIdB = scratch1b2PreContinuousCallbackFcn;
		shapeIdB.index1 = shapeIdB_index1;
		shapeIdB.world0 = shapeIdB_world0;
		shapeIdB.generation = shapeIdB_generation;
		var point = scratch2b2PreContinuousCallbackFcn;
		point.x = point_x;
		point.y = point_y;
		var normal = scratch3b2PreContinuousCallbackFcn;
		normal.x = normal_x;
		normal.y = normal_y;
		var f:B2PreContinuousCallbackFcn = Callbacks.get(slot, 1);
		var result = f(shapeIdA, shapeIdB, point, normal, Callbacks.context(slot));
		return result ? 1 : 0;
	}

	static function b2PreSolveCallbackFcn(slot:Int, shapeIdA_index1:Int, shapeIdA_world0:Int, shapeIdA_generation:Int, shapeIdB_index1:Int, shapeIdB_world0:Int, shapeIdB_generation:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		Io.beginBack();
		var shapeIdA = scratch0b2PreSolveCallbackFcn;
		shapeIdA.index1 = shapeIdA_index1;
		shapeIdA.world0 = shapeIdA_world0;
		shapeIdA.generation = shapeIdA_generation;
		var shapeIdB = scratch1b2PreSolveCallbackFcn;
		shapeIdB.index1 = shapeIdB_index1;
		shapeIdB.world0 = shapeIdB_world0;
		shapeIdB.generation = shapeIdB_generation;
		var manifold = rdB2Manifold(scratchB2Manifold);
		var f:B2PreSolveCallbackFcn = Callbacks.get(slot, 0);
		f(shapeIdA, shapeIdB, manifold, Callbacks.context(slot));
		Io.beginBack();
		wrB2Manifold(manifold);
	}

	static function b2RestitutionCallbackFcn(slot:Int, restitutionA:F32, userMaterialIdA_low:Int, userMaterialIdA_high:Int, restitutionB:F32, userMaterialIdB_low:Int, userMaterialIdB_high:Int):F32 {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var f:B2RestitutionCallbackFcn = Callbacks.worldFunction(slot, "b2RestitutionCallbackFcn");
		var result = f(restitutionA, haxe.Int64.make(userMaterialIdA_high, userMaterialIdA_low), restitutionB, haxe.Int64.make(userMaterialIdB_high, userMaterialIdB_low));
		return result;
	}

	static function b2DebugDraw_DrawPolygonFcn(slot:Int, transform_p_x:F32, transform_p_y:F32, transform_q_c:F32, transform_q_s:F32, vertexCount:Int, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		Io.beginBack();
		var transform = scratch0b2DebugDraw_DrawPolygonFcn;
		transform.p.x = transform_p_x;
		transform.p.y = transform_p_y;
		transform.q.c = transform_q_c;
		transform.q.s = transform_q_s;
		var vertices = scratchB2Vec2s;
		for (k in 0...vertexCount) {
			if (k >= vertices.length)
				vertices.push(new B2Vec2());
			Io.rv(vertices[k]);
		}
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawPolygonFcn(transform, vertices, vertexCount, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawSolidPolygonFcn(slot:Int, transform_p_x:F32, transform_p_y:F32, transform_q_c:F32, transform_q_s:F32, vertexCount:Int, radius:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		Io.beginBack();
		var transform = scratch0b2DebugDraw_DrawSolidPolygonFcn;
		transform.p.x = transform_p_x;
		transform.p.y = transform_p_y;
		transform.q.c = transform_q_c;
		transform.q.s = transform_q_s;
		var vertices = scratchB2Vec2s;
		for (k in 0...vertexCount) {
			if (k >= vertices.length)
				vertices.push(new B2Vec2());
			Io.rv(vertices[k]);
		}
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawSolidPolygonFcn(transform, vertices, vertexCount, radius, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawCircleFcn(slot:Int, center_x:F32, center_y:F32, radius:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var center = scratch0b2DebugDraw_DrawCircleFcn;
		center.x = center_x;
		center.y = center_y;
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawCircleFcn(center, radius, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawSolidCircleFcn(slot:Int, transform_p_x:F32, transform_p_y:F32, transform_q_c:F32, transform_q_s:F32, center_x:F32, center_y:F32, radius:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var transform = scratch0b2DebugDraw_DrawSolidCircleFcn;
		transform.p.x = transform_p_x;
		transform.p.y = transform_p_y;
		transform.q.c = transform_q_c;
		transform.q.s = transform_q_s;
		var center = scratch1b2DebugDraw_DrawSolidCircleFcn;
		center.x = center_x;
		center.y = center_y;
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawSolidCircleFcn(transform, center, radius, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawSolidCapsuleFcn(slot:Int, p1_x:F32, p1_y:F32, p2_x:F32, p2_y:F32, radius:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var p1 = scratch0b2DebugDraw_DrawSolidCapsuleFcn;
		p1.x = p1_x;
		p1.y = p1_y;
		var p2 = scratch1b2DebugDraw_DrawSolidCapsuleFcn;
		p2.x = p2_x;
		p2.y = p2_y;
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawSolidCapsuleFcn(p1, p2, radius, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawLineFcn(slot:Int, p1_x:F32, p1_y:F32, p2_x:F32, p2_y:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var p1 = scratch0b2DebugDraw_DrawLineFcn;
		p1.x = p1_x;
		p1.y = p1_y;
		var p2 = scratch1b2DebugDraw_DrawLineFcn;
		p2.x = p2_x;
		p2.y = p2_y;
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawLineFcn(p1, p2, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawTransformFcn(slot:Int, transform_p_x:F32, transform_p_y:F32, transform_q_c:F32, transform_q_s:F32):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var transform = scratch0b2DebugDraw_DrawTransformFcn;
		transform.p.x = transform_p_x;
		transform.p.y = transform_p_y;
		transform.q.c = transform_q_c;
		transform.q.s = transform_q_s;
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawTransformFcn(transform, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawPointFcn(slot:Int, p_x:F32, p_y:F32, size:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var p = scratch0b2DebugDraw_DrawPointFcn;
		p.x = p_x;
		p.y = p_y;
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawPointFcn(p, size, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawStringFcn(slot:Int, p_x:F32, p_y:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		Io.beginBack();
		var p = scratch0b2DebugDraw_DrawStringFcn;
		p.x = p_x;
		p.y = p_y;
		var s = Io.rs();
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawStringFcn(p, s, cast color, Callbacks.context(slot));
	}

	static function b2DebugDraw_DrawBoundsFcn(slot:Int, aabb_lowerBound_x:F32, aabb_lowerBound_y:F32, aabb_upperBound_x:F32, aabb_upperBound_y:F32, color:Int):Void {
		#if cpp
		untyped __cpp__("hx::NativeAttach attach");
		#end
		var aabb = scratch0b2DebugDraw_DrawBoundsFcn;
		aabb.lowerBound.x = aabb_lowerBound_x;
		aabb.lowerBound.y = aabb_lowerBound_y;
		aabb.upperBound.x = aabb_upperBound_x;
		aabb.upperBound.y = aabb_upperBound_y;
		var draw:B2DebugDraw = Callbacks.get(slot, 0);
		draw.DrawBoundsFcn(aabb, cast color, Callbacks.context(slot));
	}
}
