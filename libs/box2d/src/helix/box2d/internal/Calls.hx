package helix.box2d.internal;

import helix.box2d.*;

/** Written by tools/gen_box2d.py: each of Box2D's functions helix-box2d has, its arguments written to the call buffer
	or passed as numbers, its results read back, and each struct's words. */
@:noCompletion
class Calls {
	public static inline function b2GetByteCount():Int {
		var result = Hb.b2GetByteCount();
		return result;
	}

	public static inline function b2SetLogCallback(logFcn:B2LogCallbackFcn):Void {
		Callbacks.log = logFcn;
		Hb.b2SetLogCallback(logFcn != null ? 1 : 0);
	}

	public static inline function b2GetVersion(?out:B2Version):B2Version {
		var value = out == null ? new B2Version() : out;
		Hb.b2GetVersion();
		Io.begin();
		rdB2Version(value);
		return value;
	}

	public static inline function b2IsDoublePrecision():Bool {
		var result = Hb.b2IsDoublePrecision();
		return result != 0;
	}

	public static inline function b2IsAVX2Available():Bool {
		var result = Hb.b2IsAVX2Available();
		return result != 0;
	}

	public static inline function b2GetTicks():haxe.Int64 {
		Hb.b2GetTicks();
		Io.begin();
		var value = Io.rl();
		return value;
	}

	public static inline function b2GetMilliseconds(ticks:haxe.Int64):Float {
		var result = Hb.b2GetMilliseconds(ticks.low, ticks.high);
		return result;
	}

	public static inline function b2GetMillisecondsAndReset(ticks:Array<haxe.Int64>):Float {
		var result = Hb.b2GetMillisecondsAndReset();
		Io.begin();
		ticks[0] = Io.rl();
		return result;
	}

	public static inline function b2Hash(hash:Int, data:haxe.io.Bytes, count:Int):Int {
		Io.begin();
		Io.wbytes(data, count);
		var result = Hb.b2Hash(hash, count);
		return result;
	}

	public static inline function b2IsValidFloat(a:Float):Bool {
		var result = Hb.b2IsValidFloat(a);
		return result != 0;
	}

	public static inline function b2IsValidVec2(v:B2Vec2):Bool {
		var result = Hb.b2IsValidVec2(v.x, v.y);
		return result != 0;
	}

	public static inline function b2IsValidRot(q:B2Rot):Bool {
		var result = Hb.b2IsValidRot(q.c, q.s);
		return result != 0;
	}

	public static inline function b2IsValidTransform(t:B2Transform):Bool {
		var result = Hb.b2IsValidTransform(t.p.x, t.p.y, t.q.c, t.q.s);
		return result != 0;
	}

	public static inline function b2IsValidAABB(aabb:B2AABB):Bool {
		var result = Hb.b2IsValidAABB(aabb.lowerBound.x, aabb.lowerBound.y, aabb.upperBound.x, aabb.upperBound.y);
		return result != 0;
	}

	public static inline function b2IsValidPlane(a:B2Plane):Bool {
		var result = Hb.b2IsValidPlane(a.normal.x, a.normal.y, a.offset);
		return result != 0;
	}

	public static inline function b2IsValidPos(p:B2Vec2):Bool {
		var result = Hb.b2IsValidPos(p.x, p.y);
		return result != 0;
	}

	public static inline function b2IsValidWorldTransform(t:B2Transform):Bool {
		var result = Hb.b2IsValidWorldTransform(t.p.x, t.p.y, t.q.c, t.q.s);
		return result != 0;
	}

	public static inline function b2MinInt(a:Int, b:Int):Int {
		var result = Hb.b2MinInt(a, b);
		return result;
	}

	public static inline function b2MaxInt(a:Int, b:Int):Int {
		var result = Hb.b2MaxInt(a, b);
		return result;
	}

	public static inline function b2AbsInt(a:Int):Int {
		var result = Hb.b2AbsInt(a);
		return result;
	}

	public static inline function b2ClampInt(a:Int, lower:Int, upper:Int):Int {
		var result = Hb.b2ClampInt(a, lower, upper);
		return result;
	}

	public static inline function b2CeilingInt(numerator:Int, denominator:Int):Int {
		var result = Hb.b2CeilingInt(numerator, denominator);
		return result;
	}

	public static inline function b2MinFloat(a:Float, b:Float):Float {
		var result = Hb.b2MinFloat(a, b);
		return result;
	}

	public static inline function b2MaxFloat(a:Float, b:Float):Float {
		var result = Hb.b2MaxFloat(a, b);
		return result;
	}

	public static inline function b2AbsFloat(a:Float):Float {
		var result = Hb.b2AbsFloat(a);
		return result;
	}

	public static inline function b2ClampFloat(a:Float, lower:Float, upper:Float):Float {
		var result = Hb.b2ClampFloat(a, lower, upper);
		return result;
	}

	public static inline function b2Atan2(y:Float, x:Float):Float {
		var result = Hb.b2Atan2(y, x);
		return result;
	}

	public static inline function b2ComputeCosSin(radians:Float, ?out:B2CosSin):B2CosSin {
		var value = out == null ? new B2CosSin() : out;
		Hb.b2ComputeCosSin(radians);
		Io.begin();
		rdB2CosSin(value);
		return value;
	}

	public static inline function b2Dot(a:B2Vec2, b:B2Vec2):Float {
		var result = Hb.b2Dot(a.x, a.y, b.x, b.y);
		return result;
	}

	public static inline function b2Cross(a:B2Vec2, b:B2Vec2):Float {
		var result = Hb.b2Cross(a.x, a.y, b.x, b.y);
		return result;
	}

	public static inline function b2CrossVS(v:B2Vec2, s:Float, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2CrossVS(v.x, v.y, s);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2CrossSV(s:Float, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2CrossSV(s, v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2LeftPerp(v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2LeftPerp(v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2RightPerp(v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2RightPerp(v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Add(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Add(a.x, a.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Sub(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Sub(a.x, a.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Neg(a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Neg(a.x, a.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Lerp(a:B2Vec2, b:B2Vec2, t:Float, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Lerp(a.x, a.y, b.x, b.y, t);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Mul(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Mul(a.x, a.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2MulSV(s:Float, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2MulSV(s, v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2MulAdd(a:B2Vec2, s:Float, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2MulAdd(a.x, a.y, s, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2MulSub(a:B2Vec2, s:Float, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2MulSub(a.x, a.y, s, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Abs(a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Abs(a.x, a.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Min(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Min(a.x, a.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Max(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Max(a.x, a.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Clamp(v:B2Vec2, a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Clamp(v.x, v.y, a.x, a.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Length(v:B2Vec2):Float {
		var result = Hb.b2Length(v.x, v.y);
		return result;
	}

	public static inline function b2Distance(a:B2Vec2, b:B2Vec2):Float {
		var result = Hb.b2Distance(a.x, a.y, b.x, b.y);
		return result;
	}

	public static inline function b2Normalize(a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Normalize(a.x, a.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2IsNormalized(a:B2Vec2):Bool {
		var result = Hb.b2IsNormalized(a.x, a.y);
		return result != 0;
	}

	public static inline function b2GetLengthAndNormalize(length:Array<Float>, a:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2GetLengthAndNormalize(a.x, a.y);
		Io.begin();
		Io.rv(value);
		length[0] = Io.rf();
		return value;
	}

	public static inline function b2NormalizeRot(q:B2Rot, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2NormalizeRot(q.c, q.s);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2IntegrateRotation(q1:B2Rot, deltaAngle:Float, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2IntegrateRotation(q1.c, q1.s, deltaAngle);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2LengthSquared(v:B2Vec2):Float {
		var result = Hb.b2LengthSquared(v.x, v.y);
		return result;
	}

	public static inline function b2DistanceSquared(a:B2Vec2, b:B2Vec2):Float {
		var result = Hb.b2DistanceSquared(a.x, a.y, b.x, b.y);
		return result;
	}

	public static inline function b2MakeRot(radians:Float, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2MakeRot(radians);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2MakeRotFromUnitVector(unitVector:B2Vec2, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2MakeRotFromUnitVector(unitVector.x, unitVector.y);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2ComputeRotationBetweenUnitVectors(v1:B2Vec2, v2:B2Vec2, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2ComputeRotationBetweenUnitVectors(v1.x, v1.y, v2.x, v2.y);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2IsNormalizedRot(q:B2Rot):Bool {
		var result = Hb.b2IsNormalizedRot(q.c, q.s);
		return result != 0;
	}

	public static inline function b2InvertRot(a:B2Rot, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2InvertRot(a.c, a.s);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2NLerp(q1:B2Rot, q2:B2Rot, t:Float, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2NLerp(q1.c, q1.s, q2.c, q2.s, t);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2ComputeAngularVelocity(q1:B2Rot, q2:B2Rot, inv_h:Float):Float {
		var result = Hb.b2ComputeAngularVelocity(q1.c, q1.s, q2.c, q2.s, inv_h);
		return result;
	}

	public static inline function b2Rot_GetAngle(q:B2Rot):Float {
		var result = Hb.b2Rot_GetAngle(q.c, q.s);
		return result;
	}

	public static inline function b2Rot_GetXAxis(q:B2Rot, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Rot_GetXAxis(q.c, q.s);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Rot_GetYAxis(q:B2Rot, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Rot_GetYAxis(q.c, q.s);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2MulRot(q:B2Rot, r:B2Rot, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2MulRot(q.c, q.s, r.c, r.s);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2InvMulRot(a:B2Rot, b:B2Rot, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2InvMulRot(a.c, a.s, b.c, b.s);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2RelativeAngle(a:B2Rot, b:B2Rot):Float {
		var result = Hb.b2RelativeAngle(a.c, a.s, b.c, b.s);
		return result;
	}

	public static inline function b2UnwindAngle(radians:Float):Float {
		var result = Hb.b2UnwindAngle(radians);
		return result;
	}

	public static inline function b2RotateVector(q:B2Rot, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2RotateVector(q.c, q.s, v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2InvRotateVector(q:B2Rot, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2InvRotateVector(q.c, q.s, v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2TransformPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2TransformPoint(t.p.x, t.p.y, t.q.c, t.q.s, p.x, p.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2InvTransformPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2InvTransformPoint(t.p.x, t.p.y, t.q.c, t.q.s, p.x, p.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2MulTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2MulTransforms(A.p.x, A.p.y, A.q.c, A.q.s, B.p.x, B.p.y, B.q.c, B.q.s);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2InvMulTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2InvMulTransforms(A.p.x, A.p.y, A.q.c, A.q.s, B.p.x, B.p.y, B.q.c, B.q.s);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2ToPos(v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2ToPos(v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2ToVec2(p:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2ToVec2(p.x, p.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2RoundDownFloat(x:Float):Float {
		var result = Hb.b2RoundDownFloat(x);
		return result;
	}

	public static inline function b2RoundUpFloat(x:Float):Float {
		var result = Hb.b2RoundUpFloat(x);
		return result;
	}

	public static inline function b2SubPos(a:B2Vec2, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2SubPos(a.x, a.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2OffsetPos(p:B2Vec2, d:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2OffsetPos(p.x, p.y, d.x, d.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2LerpPos(a:B2Vec2, b:B2Vec2, t:Float, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2LerpPos(a.x, a.y, b.x, b.y, t);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2TransformWorldPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2TransformWorldPoint(t.p.x, t.p.y, t.q.c, t.q.s, p.x, p.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2InvTransformWorldPoint(t:B2Transform, p:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2InvTransformWorldPoint(t.p.x, t.p.y, t.q.c, t.q.s, p.x, p.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2InvMulWorldTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2InvMulWorldTransforms(A.p.x, A.p.y, A.q.c, A.q.s, B.p.x, B.p.y, B.q.c, B.q.s);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2MulWorldTransforms(A:B2Transform, B:B2Transform, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2MulWorldTransforms(A.p.x, A.p.y, A.q.c, A.q.s, B.p.x, B.p.y, B.q.c, B.q.s);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2ToRelativeTransform(t:B2Transform, base:B2Vec2, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2ToRelativeTransform(t.p.x, t.p.y, t.q.c, t.q.s, base.x, base.y);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2MakeWorldTransform(t:B2Transform, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2MakeWorldTransform(t.p.x, t.p.y, t.q.c, t.q.s);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2MulMV(A:B2Mat22, v:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2MulMV(A.cx.x, A.cx.y, A.cy.x, A.cy.y, v.x, v.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2GetInverse22(A:B2Mat22, ?out:B2Mat22):B2Mat22 {
		var value = out == null ? new B2Mat22() : out;
		Hb.b2GetInverse22(A.cx.x, A.cx.y, A.cy.x, A.cy.y);
		Io.begin();
		rdB2Mat22(value);
		return value;
	}

	public static inline function b2Solve22(A:B2Mat22, b:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Solve22(A.cx.x, A.cx.y, A.cy.x, A.cy.y, b.x, b.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2AABB_Contains(a:B2AABB, b:B2AABB):Bool {
		var result = Hb.b2AABB_Contains(a.lowerBound.x, a.lowerBound.y, a.upperBound.x, a.upperBound.y, b.lowerBound.x, b.lowerBound.y, b.upperBound.x, b.upperBound.y);
		return result != 0;
	}

	public static inline function b2AABB_Center(a:B2AABB, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2AABB_Center(a.lowerBound.x, a.lowerBound.y, a.upperBound.x, a.upperBound.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2AABB_Extents(a:B2AABB, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2AABB_Extents(a.lowerBound.x, a.lowerBound.y, a.upperBound.x, a.upperBound.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2AABB_Union(a:B2AABB, b:B2AABB, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Hb.b2AABB_Union(a.lowerBound.x, a.lowerBound.y, a.upperBound.x, a.upperBound.y, b.lowerBound.x, b.lowerBound.y, b.upperBound.x, b.upperBound.y);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2AABB_Overlaps(a:B2AABB, b:B2AABB):Bool {
		var result = Hb.b2AABB_Overlaps(a.lowerBound.x, a.lowerBound.y, a.upperBound.x, a.upperBound.y, b.lowerBound.x, b.lowerBound.y, b.upperBound.x, b.upperBound.y);
		return result != 0;
	}

	public static inline function b2MakeAABB(points:Array<B2Vec2>, count:Int, radius:Float, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Io.begin();
		for (k in 0...count)
			Io.wv(points[k]);
		Hb.b2MakeAABB(count, radius);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2PlaneSeparation(plane:B2Plane, point:B2Vec2):Float {
		var result = Hb.b2PlaneSeparation(plane.normal.x, plane.normal.y, plane.offset, point.x, point.y);
		return result;
	}

	public static inline function b2SpringDamper(hertz:Float, dampingRatio:Float, position:Float, velocity:Float, timeStep:Float):Float {
		var result = Hb.b2SpringDamper(hertz, dampingRatio, position, velocity, timeStep);
		return result;
	}

	public static inline function b2SetLengthUnitsPerMeter(lengthUnits:Float):Void {
		Hb.b2SetLengthUnitsPerMeter(lengthUnits);
	}

	public static inline function b2GetLengthUnitsPerMeter():Float {
		var result = Hb.b2GetLengthUnitsPerMeter();
		return result;
	}

	public static inline function b2IsValidRay(input:B2RayCastInput):Bool {
		Io.begin();
		wrB2RayCastInput(input);
		var result = Hb.b2IsValidRay();
		return result != 0;
	}

	public static inline function b2MakePolygon(hull:B2Hull, radius:Float, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Io.begin();
		wrB2Hull(hull);
		Hb.b2MakePolygon(radius);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2MakeOffsetPolygon(hull:B2Hull, position:B2Vec2, rotation:B2Rot, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Io.begin();
		wrB2Hull(hull);
		Hb.b2MakeOffsetPolygon(position.x, position.y, rotation.c, rotation.s);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2MakeOffsetRoundedPolygon(hull:B2Hull, position:B2Vec2, rotation:B2Rot, radius:Float, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Io.begin();
		wrB2Hull(hull);
		Hb.b2MakeOffsetRoundedPolygon(position.x, position.y, rotation.c, rotation.s, radius);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2MakeSquare(halfWidth:Float, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Hb.b2MakeSquare(halfWidth);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2MakeBox(halfWidth:Float, halfHeight:Float, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Hb.b2MakeBox(halfWidth, halfHeight);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2MakeRoundedBox(halfWidth:Float, halfHeight:Float, radius:Float, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Hb.b2MakeRoundedBox(halfWidth, halfHeight, radius);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2MakeOffsetBox(halfWidth:Float, halfHeight:Float, center:B2Vec2, rotation:B2Rot, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Hb.b2MakeOffsetBox(halfWidth, halfHeight, center.x, center.y, rotation.c, rotation.s);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2MakeOffsetRoundedBox(halfWidth:Float, halfHeight:Float, center:B2Vec2, rotation:B2Rot, radius:Float, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Hb.b2MakeOffsetRoundedBox(halfWidth, halfHeight, center.x, center.y, rotation.c, rotation.s, radius);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2TransformPolygon(transform:B2Transform, polygon:B2Polygon, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Io.begin();
		wrB2Polygon(polygon);
		Hb.b2TransformPolygon(transform.p.x, transform.p.y, transform.q.c, transform.q.s);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2ComputeCircleMass(shape:B2Circle, density:Float, ?out:B2MassData):B2MassData {
		var value = out == null ? new B2MassData() : out;
		Io.begin();
		wrB2Circle(shape);
		Hb.b2ComputeCircleMass(density);
		Io.begin();
		rdB2MassData(value);
		return value;
	}

	public static inline function b2ComputeCapsuleMass(shape:B2Capsule, density:Float, ?out:B2MassData):B2MassData {
		var value = out == null ? new B2MassData() : out;
		Io.begin();
		wrB2Capsule(shape);
		Hb.b2ComputeCapsuleMass(density);
		Io.begin();
		rdB2MassData(value);
		return value;
	}

	public static inline function b2ComputePolygonMass(shape:B2Polygon, density:Float, ?out:B2MassData):B2MassData {
		var value = out == null ? new B2MassData() : out;
		Io.begin();
		wrB2Polygon(shape);
		Hb.b2ComputePolygonMass(density);
		Io.begin();
		rdB2MassData(value);
		return value;
	}

	public static inline function b2ComputeCircleBounds(shape:B2Circle, transform:B2Transform, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Io.begin();
		wrB2Circle(shape);
		Hb.b2ComputeCircleBounds(transform.p.x, transform.p.y, transform.q.c, transform.q.s);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2ComputeCapsuleBounds(shape:B2Capsule, transform:B2Transform, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Io.begin();
		wrB2Capsule(shape);
		Hb.b2ComputeCapsuleBounds(transform.p.x, transform.p.y, transform.q.c, transform.q.s);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2ComputePolygonBounds(shape:B2Polygon, transform:B2Transform, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Io.begin();
		wrB2Polygon(shape);
		Hb.b2ComputePolygonBounds(transform.p.x, transform.p.y, transform.q.c, transform.q.s);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2ComputeSegmentBounds(shape:B2Segment, transform:B2Transform, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Io.begin();
		wrB2Segment(shape);
		Hb.b2ComputeSegmentBounds(transform.p.x, transform.p.y, transform.q.c, transform.q.s);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2PointInCircle(shape:B2Circle, point:B2Vec2):Bool {
		Io.begin();
		wrB2Circle(shape);
		var result = Hb.b2PointInCircle(point.x, point.y);
		return result != 0;
	}

	public static inline function b2PointInCapsule(shape:B2Capsule, point:B2Vec2):Bool {
		Io.begin();
		wrB2Capsule(shape);
		var result = Hb.b2PointInCapsule(point.x, point.y);
		return result != 0;
	}

	public static inline function b2PointInPolygon(shape:B2Polygon, point:B2Vec2):Bool {
		Io.begin();
		wrB2Polygon(shape);
		var result = Hb.b2PointInPolygon(point.x, point.y);
		return result != 0;
	}

	public static inline function b2CastRayCircle(shape:B2Circle, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Circle(shape);
		wrB2RayCastInput(input);
		Hb.b2CastRayCircle();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2CastRayCapsule(shape:B2Capsule, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Capsule(shape);
		wrB2RayCastInput(input);
		Hb.b2CastRayCapsule();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2CastRaySegment(shape:B2Segment, input:B2RayCastInput, oneSided:Bool, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Segment(shape);
		wrB2RayCastInput(input);
		Hb.b2CastRaySegment(oneSided ? 1 : 0);
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2CastRayPolygon(shape:B2Polygon, input:B2RayCastInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Polygon(shape);
		wrB2RayCastInput(input);
		Hb.b2CastRayPolygon();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2CastShapeCircle(shape:B2Circle, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Circle(shape);
		wrB2ShapeCastInput(input);
		Hb.b2CastShapeCircle();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2CastShapeCapsule(shape:B2Capsule, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Capsule(shape);
		wrB2ShapeCastInput(input);
		Hb.b2CastShapeCapsule();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2CastShapeSegment(shape:B2Segment, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Segment(shape);
		wrB2ShapeCastInput(input);
		Hb.b2CastShapeSegment();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2CastShapePolygon(shape:B2Polygon, input:B2ShapeCastInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2Polygon(shape);
		wrB2ShapeCastInput(input);
		Hb.b2CastShapePolygon();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2ComputeHull(points:Array<B2Vec2>, count:Int, ?out:B2Hull):B2Hull {
		var value = out == null ? new B2Hull() : out;
		Io.begin();
		for (k in 0...count)
			Io.wv(points[k]);
		Hb.b2ComputeHull(count);
		Io.begin();
		rdB2Hull(value);
		return value;
	}

	public static inline function b2ValidateHull(hull:B2Hull):Bool {
		Io.begin();
		wrB2Hull(hull);
		var result = Hb.b2ValidateHull();
		return result != 0;
	}

	public static inline function b2ComputeSegmentDistance(p1:B2Vec2, q1:B2Vec2, p2:B2Vec2, q2:B2Vec2, ?out:B2SegmentDistanceResult):B2SegmentDistanceResult {
		var value = out == null ? new B2SegmentDistanceResult() : out;
		Hb.b2ComputeSegmentDistance(p1.x, p1.y, q1.x, q1.y, p2.x, p2.y, q2.x, q2.y);
		Io.begin();
		rdB2SegmentDistanceResult(value);
		return value;
	}

	public static inline function b2ComputeShapeDistance(input:B2DistanceInput, cache:B2SimplexCache, ?simplexes:Array<B2Simplex>, simplexCapacity = 0, ?out:B2DistanceOutput):B2DistanceOutput {
		var value = out == null ? new B2DistanceOutput() : out;
		Io.begin();
		wrB2DistanceInput(input);
		wrB2SimplexCache(cache);
		Hb.b2ComputeShapeDistance(simplexCapacity);
		Io.begin();
		rdB2DistanceOutput(value);
		rdB2SimplexCache(cache);
		{
			var filled = Io.ri();
			if (simplexes != null)
				for (k in 0...filled) {
					if (k >= simplexes.length)
						simplexes.push(Init.makeB2Simplex());
					rdB2Simplex(simplexes[k]);
				}
		}
		return value;
	}

	public static inline function b2CastShape(input:B2ShapeCastPairInput, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Io.begin();
		wrB2ShapeCastPairInput(input);
		Hb.b2CastShape();
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2MakeProxy(points:Array<B2Vec2>, count:Int, radius:Float, ?out:B2ShapeProxy):B2ShapeProxy {
		var value = out == null ? new B2ShapeProxy() : out;
		Io.begin();
		for (k in 0...count)
			Io.wv(points[k]);
		Hb.b2MakeProxy(count, radius);
		Io.begin();
		rdB2ShapeProxy(value);
		return value;
	}

	public static inline function b2MakeOffsetProxy(points:Array<B2Vec2>, count:Int, radius:Float, position:B2Vec2, rotation:B2Rot, ?out:B2ShapeProxy):B2ShapeProxy {
		var value = out == null ? new B2ShapeProxy() : out;
		Io.begin();
		for (k in 0...count)
			Io.wv(points[k]);
		Hb.b2MakeOffsetProxy(count, radius, position.x, position.y, rotation.c, rotation.s);
		Io.begin();
		rdB2ShapeProxy(value);
		return value;
	}

	public static inline function b2GetSweepTransform(sweep:B2Sweep, time:Float, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Io.begin();
		wrB2Sweep(sweep);
		Hb.b2GetSweepTransform(time);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2ComputeTimeOfImpact(input:B2TOIInput, ?out:B2TOIOutput):B2TOIOutput {
		var value = out == null ? new B2TOIOutput() : out;
		Io.begin();
		wrB2TOIInput(input);
		Hb.b2ComputeTimeOfImpact();
		Io.begin();
		rdB2TOIOutput(value);
		return value;
	}

	public static inline function b2CollideCircles(circleA:B2Circle, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Circle(circleA);
		wrB2Circle(circleB);
		Hb.b2CollideCircles(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollideCapsuleAndCircle(capsuleA:B2Capsule, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Capsule(capsuleA);
		wrB2Circle(circleB);
		Hb.b2CollideCapsuleAndCircle(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollideSegmentAndCircle(segmentA:B2Segment, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Segment(segmentA);
		wrB2Circle(circleB);
		Hb.b2CollideSegmentAndCircle(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollidePolygonAndCircle(polygonA:B2Polygon, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Polygon(polygonA);
		wrB2Circle(circleB);
		Hb.b2CollidePolygonAndCircle(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollideCapsules(capsuleA:B2Capsule, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Capsule(capsuleA);
		wrB2Capsule(capsuleB);
		Hb.b2CollideCapsules(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollideSegmentAndCapsule(segmentA:B2Segment, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Segment(segmentA);
		wrB2Capsule(capsuleB);
		Hb.b2CollideSegmentAndCapsule(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollidePolygonAndCapsule(polygonA:B2Polygon, capsuleB:B2Capsule, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Polygon(polygonA);
		wrB2Capsule(capsuleB);
		Hb.b2CollidePolygonAndCapsule(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollidePolygons(polygonA:B2Polygon, polygonB:B2Polygon, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Polygon(polygonA);
		wrB2Polygon(polygonB);
		Hb.b2CollidePolygons(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollideSegmentAndPolygon(segmentA:B2Segment, polygonB:B2Polygon, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2Segment(segmentA);
		wrB2Polygon(polygonB);
		Hb.b2CollideSegmentAndPolygon(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollideChainSegmentAndCircle(segmentA:B2ChainSegment, circleB:B2Circle, xf:B2Transform, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2ChainSegment(segmentA);
		wrB2Circle(circleB);
		Hb.b2CollideChainSegmentAndCircle(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		return value;
	}

	public static inline function b2CollideChainSegmentAndCapsule(segmentA:B2ChainSegment, capsuleB:B2Capsule, xf:B2Transform, cache:B2SimplexCache, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2ChainSegment(segmentA);
		wrB2Capsule(capsuleB);
		wrB2SimplexCache(cache);
		Hb.b2CollideChainSegmentAndCapsule(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		rdB2SimplexCache(cache);
		return value;
	}

	public static inline function b2CollideChainSegmentAndPolygon(segmentA:B2ChainSegment, polygonB:B2Polygon, xf:B2Transform, cache:B2SimplexCache, ?out:B2LocalManifold):B2LocalManifold {
		var value = out == null ? new B2LocalManifold() : out;
		Io.begin();
		wrB2ChainSegment(segmentA);
		wrB2Polygon(polygonB);
		wrB2SimplexCache(cache);
		Hb.b2CollideChainSegmentAndPolygon(xf.p.x, xf.p.y, xf.q.c, xf.q.s);
		Io.begin();
		rdB2LocalManifold(value);
		rdB2SimplexCache(cache);
		return value;
	}

	public static inline function b2DefaultWorldDef(?out:B2WorldDef):B2WorldDef {
		var value = out == null ? new B2WorldDef() : out;
		Hb.b2DefaultWorldDef();
		Io.begin();
		rdB2WorldDef(value);
		return value;
	}

	public static inline function b2DefaultBodyDef(?out:B2BodyDef):B2BodyDef {
		var value = out == null ? new B2BodyDef() : out;
		Hb.b2DefaultBodyDef();
		Io.begin();
		rdB2BodyDef(value);
		return value;
	}

	public static inline function b2DefaultFilter(?out:B2Filter):B2Filter {
		var value = out == null ? new B2Filter() : out;
		Hb.b2DefaultFilter();
		Io.begin();
		rdB2Filter(value);
		return value;
	}

	public static inline function b2DefaultQueryFilter(?out:B2QueryFilter):B2QueryFilter {
		var value = out == null ? new B2QueryFilter() : out;
		Hb.b2DefaultQueryFilter();
		Io.begin();
		rdB2QueryFilter(value);
		return value;
	}

	public static inline function b2DefaultSurfaceMaterial(?out:B2SurfaceMaterial):B2SurfaceMaterial {
		var value = out == null ? new B2SurfaceMaterial() : out;
		Hb.b2DefaultSurfaceMaterial();
		Io.begin();
		rdB2SurfaceMaterial(value);
		return value;
	}

	public static inline function b2DefaultShapeDef(?out:B2ShapeDef):B2ShapeDef {
		var value = out == null ? new B2ShapeDef() : out;
		Hb.b2DefaultShapeDef();
		Io.begin();
		rdB2ShapeDef(value);
		return value;
	}

	public static inline function b2DefaultChainDef(?out:B2ChainDef):B2ChainDef {
		var value = out == null ? new B2ChainDef() : out;
		Hb.b2DefaultChainDef();
		Io.begin();
		rdB2ChainDef(value);
		return value;
	}

	public static inline function b2DefaultDistanceJointDef(?out:B2DistanceJointDef):B2DistanceJointDef {
		var value = out == null ? new B2DistanceJointDef() : out;
		Hb.b2DefaultDistanceJointDef();
		Io.begin();
		rdB2DistanceJointDef(value);
		return value;
	}

	public static inline function b2DefaultFilterJointDef(?out:B2FilterJointDef):B2FilterJointDef {
		var value = out == null ? new B2FilterJointDef() : out;
		Hb.b2DefaultFilterJointDef();
		Io.begin();
		rdB2FilterJointDef(value);
		return value;
	}

	public static inline function b2DefaultMotorJointDef(?out:B2MotorJointDef):B2MotorJointDef {
		var value = out == null ? new B2MotorJointDef() : out;
		Hb.b2DefaultMotorJointDef();
		Io.begin();
		rdB2MotorJointDef(value);
		return value;
	}

	public static inline function b2DefaultPrismaticJointDef(?out:B2PrismaticJointDef):B2PrismaticJointDef {
		var value = out == null ? new B2PrismaticJointDef() : out;
		Hb.b2DefaultPrismaticJointDef();
		Io.begin();
		rdB2PrismaticJointDef(value);
		return value;
	}

	public static inline function b2DefaultRevoluteJointDef(?out:B2RevoluteJointDef):B2RevoluteJointDef {
		var value = out == null ? new B2RevoluteJointDef() : out;
		Hb.b2DefaultRevoluteJointDef();
		Io.begin();
		rdB2RevoluteJointDef(value);
		return value;
	}

	public static inline function b2DefaultWeldJointDef(?out:B2WeldJointDef):B2WeldJointDef {
		var value = out == null ? new B2WeldJointDef() : out;
		Hb.b2DefaultWeldJointDef();
		Io.begin();
		rdB2WeldJointDef(value);
		return value;
	}

	public static inline function b2DefaultWheelJointDef(?out:B2WheelJointDef):B2WheelJointDef {
		var value = out == null ? new B2WheelJointDef() : out;
		Hb.b2DefaultWheelJointDef();
		Io.begin();
		rdB2WheelJointDef(value);
		return value;
	}

	public static inline function b2DefaultExplosionDef(?out:B2ExplosionDef):B2ExplosionDef {
		var value = out == null ? new B2ExplosionDef() : out;
		Hb.b2DefaultExplosionDef();
		Io.begin();
		rdB2ExplosionDef(value);
		return value;
	}

	public static inline function b2GetGraphColor(index:Int):B2HexColor {
		var result = Hb.b2GetGraphColor(index);
		return cast result;
	}

	public static inline function b2DefaultDebugDraw(?out:B2DebugDraw):B2DebugDraw {
		var value = out == null ? new B2DebugDraw() : out;
		Hb.b2DefaultDebugDraw();
		Io.begin();
		rdB2DebugDraw(value);
		return value;
	}

	public static inline function b2CreateWorld(def:B2WorldDef, ?out:B2WorldId):B2WorldId {
		var value = out == null ? new B2WorldId() : out;
		Io.begin();
		wrB2WorldDef(def);
		Hb.b2CreateWorld();
		Io.begin();
		rdB2WorldId(value);
		Data.set(value, def.userData);
		Callbacks.setWorldFunction(value, "b2FrictionCallbackFcn", def.frictionCallback);
		Callbacks.setWorldFunction(value, "b2RestitutionCallbackFcn", def.restitutionCallback);
		return value;
	}

	public static inline function b2DestroyWorld(worldId:B2WorldId):Void {
		Hb.b2DestroyWorld(worldId.index1, worldId.generation);
		Data.clear(worldId);
		Callbacks.clear(worldId);
	}

	public static inline function b2World_IsValid(id:B2WorldId):Bool {
		var result = Hb.b2World_IsValid(id.index1, id.generation);
		return result != 0;
	}

	public static inline function b2World_Step(worldId:B2WorldId, timeStep:Float, subStepCount:Int):Void {
		Hb.b2World_Step(worldId.index1, worldId.generation, timeStep, subStepCount);
	}

	public static inline function b2World_Draw(worldId:B2WorldId, draw:B2DebugDraw):Void {
		var slot = Callbacks.open([draw], draw.context);
		Io.begin();
		wrB2DebugDraw(draw);
		Hb.b2World_Draw(worldId.index1, worldId.generation, slot);
		Callbacks.close(slot);
	}

	public static inline function b2World_GetBounds(worldId:B2WorldId, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Hb.b2World_GetBounds(worldId.index1, worldId.generation);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2World_GetBodyEvents(worldId:B2WorldId, ?out:B2BodyEvents):B2BodyEvents {
		var value = out == null ? new B2BodyEvents() : out;
		Hb.b2World_GetBodyEvents(worldId.index1, worldId.generation);
		Io.begin();
		rdB2BodyEvents(value);
		return value;
	}

	public static inline function b2World_GetSensorEvents(worldId:B2WorldId, ?out:B2SensorEvents):B2SensorEvents {
		var value = out == null ? new B2SensorEvents() : out;
		Hb.b2World_GetSensorEvents(worldId.index1, worldId.generation);
		Io.begin();
		rdB2SensorEvents(value);
		return value;
	}

	public static inline function b2World_GetContactEvents(worldId:B2WorldId, ?out:B2ContactEvents):B2ContactEvents {
		var value = out == null ? new B2ContactEvents() : out;
		Hb.b2World_GetContactEvents(worldId.index1, worldId.generation);
		Io.begin();
		rdB2ContactEvents(value);
		return value;
	}

	public static inline function b2World_GetJointEvents(worldId:B2WorldId, ?out:B2JointEvents):B2JointEvents {
		var value = out == null ? new B2JointEvents() : out;
		Hb.b2World_GetJointEvents(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointEvents(value);
		return value;
	}

	public static inline function b2World_OverlapAABB(worldId:B2WorldId, origin:B2Vec2, aabb:B2AABB, filter:B2QueryFilter, fcn:B2OverlapResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		var slot = Callbacks.open([fcn], context);
		var value = out == null ? new B2TreeStats() : out;
		Io.begin();
		wrB2QueryFilter(filter);
		Hb.b2World_OverlapAABB(worldId.index1, worldId.generation, origin.x, origin.y, aabb.lowerBound.x, aabb.lowerBound.y, aabb.upperBound.x, aabb.upperBound.y, fcn != null ? 1 : 0, slot);
		Io.begin();
		rdB2TreeStats(value);
		Callbacks.close(slot);
		return value;
	}

	public static inline function b2World_OverlapShape(worldId:B2WorldId, origin:B2Vec2, proxy:B2ShapeProxy, filter:B2QueryFilter, fcn:B2OverlapResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		var slot = Callbacks.open([fcn], context);
		var value = out == null ? new B2TreeStats() : out;
		Io.begin();
		wrB2ShapeProxy(proxy);
		wrB2QueryFilter(filter);
		Hb.b2World_OverlapShape(worldId.index1, worldId.generation, origin.x, origin.y, fcn != null ? 1 : 0, slot);
		Io.begin();
		rdB2TreeStats(value);
		Callbacks.close(slot);
		return value;
	}

	public static inline function b2World_CastRay(worldId:B2WorldId, origin:B2Vec2, translation:B2Vec2, filter:B2QueryFilter, fcn:B2CastResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		var slot = Callbacks.open([fcn], context);
		var value = out == null ? new B2TreeStats() : out;
		Io.begin();
		wrB2QueryFilter(filter);
		Hb.b2World_CastRay(worldId.index1, worldId.generation, origin.x, origin.y, translation.x, translation.y, fcn != null ? 1 : 0, slot);
		Io.begin();
		rdB2TreeStats(value);
		Callbacks.close(slot);
		return value;
	}

	public static inline function b2World_CastRayClosest(worldId:B2WorldId, origin:B2Vec2, translation:B2Vec2, filter:B2QueryFilter, ?out:B2RayResult):B2RayResult {
		var value = out == null ? new B2RayResult() : out;
		Io.begin();
		wrB2QueryFilter(filter);
		Hb.b2World_CastRayClosest(worldId.index1, worldId.generation, origin.x, origin.y, translation.x, translation.y);
		Io.begin();
		rdB2RayResult(value);
		return value;
	}

	public static inline function b2World_CastShape(worldId:B2WorldId, origin:B2Vec2, proxy:B2ShapeProxy, translation:B2Vec2, filter:B2QueryFilter, fcn:B2CastResultCallbackFcn, context:Dynamic, ?out:B2TreeStats):B2TreeStats {
		var slot = Callbacks.open([fcn], context);
		var value = out == null ? new B2TreeStats() : out;
		Io.begin();
		wrB2ShapeProxy(proxy);
		wrB2QueryFilter(filter);
		Hb.b2World_CastShape(worldId.index1, worldId.generation, origin.x, origin.y, translation.x, translation.y, fcn != null ? 1 : 0, slot);
		Io.begin();
		rdB2TreeStats(value);
		Callbacks.close(slot);
		return value;
	}

	public static inline function b2World_EnableSleeping(worldId:B2WorldId, flag:Bool):Void {
		Hb.b2World_EnableSleeping(worldId.index1, worldId.generation, flag ? 1 : 0);
	}

	public static inline function b2World_IsSleepingEnabled(worldId:B2WorldId):Bool {
		var result = Hb.b2World_IsSleepingEnabled(worldId.index1, worldId.generation);
		return result != 0;
	}

	public static inline function b2World_EnableContinuous(worldId:B2WorldId, flag:Bool):Void {
		Hb.b2World_EnableContinuous(worldId.index1, worldId.generation, flag ? 1 : 0);
	}

	public static inline function b2World_IsContinuousEnabled(worldId:B2WorldId):Bool {
		var result = Hb.b2World_IsContinuousEnabled(worldId.index1, worldId.generation);
		return result != 0;
	}

	public static inline function b2World_SetRestitutionThreshold(worldId:B2WorldId, value:Float):Void {
		Hb.b2World_SetRestitutionThreshold(worldId.index1, worldId.generation, value);
	}

	public static inline function b2World_GetRestitutionThreshold(worldId:B2WorldId):Float {
		var result = Hb.b2World_GetRestitutionThreshold(worldId.index1, worldId.generation);
		return result;
	}

	public static inline function b2World_SetRestitutionIterations(worldId:B2WorldId, iterations:Int):Void {
		Hb.b2World_SetRestitutionIterations(worldId.index1, worldId.generation, iterations);
	}

	public static inline function b2World_GetRestitutionIterations(worldId:B2WorldId):Int {
		var result = Hb.b2World_GetRestitutionIterations(worldId.index1, worldId.generation);
		return result;
	}

	public static inline function b2World_EnableRestitutionPropagation(worldId:B2WorldId, flag:Bool):Void {
		Hb.b2World_EnableRestitutionPropagation(worldId.index1, worldId.generation, flag ? 1 : 0);
	}

	public static inline function b2World_IsRestitutionPropagationEnabled(worldId:B2WorldId):Bool {
		var result = Hb.b2World_IsRestitutionPropagationEnabled(worldId.index1, worldId.generation);
		return result != 0;
	}

	public static inline function b2World_SetHitEventThreshold(worldId:B2WorldId, value:Float):Void {
		Hb.b2World_SetHitEventThreshold(worldId.index1, worldId.generation, value);
	}

	public static inline function b2World_GetHitEventThreshold(worldId:B2WorldId):Float {
		var result = Hb.b2World_GetHitEventThreshold(worldId.index1, worldId.generation);
		return result;
	}

	public static inline function b2World_SetCustomFilterCallback(worldId:B2WorldId, fcn:B2CustomFilterCallbackFcn, context:Dynamic):Void {
		var slot = Callbacks.world(worldId, "b2World_SetCustomFilterCallback", [fcn], context);
		Hb.b2World_SetCustomFilterCallback(worldId.index1, worldId.generation, fcn != null ? 1 : 0, slot);
	}

	public static inline function b2World_SetPreSolveCallback(worldId:B2WorldId, preSolveFcn:B2PreSolveCallbackFcn, preContinuousFcn:B2PreContinuousCallbackFcn, context:Dynamic):Void {
		var slot = Callbacks.world(worldId, "b2World_SetPreSolveCallback", [preSolveFcn, preContinuousFcn], context);
		Hb.b2World_SetPreSolveCallback(worldId.index1, worldId.generation, preSolveFcn != null ? 1 : 0, preContinuousFcn != null ? 1 : 0, slot);
	}

	public static inline function b2World_SetGravity(worldId:B2WorldId, gravity:B2Vec2):Void {
		Hb.b2World_SetGravity(worldId.index1, worldId.generation, gravity.x, gravity.y);
	}

	public static inline function b2World_GetGravity(worldId:B2WorldId, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2World_GetGravity(worldId.index1, worldId.generation);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2World_Explode(worldId:B2WorldId, explosionDef:B2ExplosionDef):Void {
		Io.begin();
		wrB2ExplosionDef(explosionDef);
		Hb.b2World_Explode(worldId.index1, worldId.generation);
	}

	public static inline function b2World_SetContactTuning(worldId:B2WorldId, hertz:Float, dampingRatio:Float, pushSpeed:Float):Void {
		Hb.b2World_SetContactTuning(worldId.index1, worldId.generation, hertz, dampingRatio, pushSpeed);
	}

	public static inline function b2World_GetContactTuning(worldId:B2WorldId, hertz:Array<Float>, dampingRatio:Array<Float>, pushSpeed:Array<Float>):Void {
		Hb.b2World_GetContactTuning(worldId.index1, worldId.generation);
		Io.begin();
		hertz[0] = Io.rf();
		dampingRatio[0] = Io.rf();
		pushSpeed[0] = Io.rf();
	}

	public static inline function b2World_SetContactRecycleDistance(worldId:B2WorldId, recycleDistance:Float):Void {
		Hb.b2World_SetContactRecycleDistance(worldId.index1, worldId.generation, recycleDistance);
	}

	public static inline function b2World_GetContactRecycleDistance(worldId:B2WorldId):Float {
		var result = Hb.b2World_GetContactRecycleDistance(worldId.index1, worldId.generation);
		return result;
	}

	public static inline function b2World_SetMaxLinearSpeed(worldId:B2WorldId, maximumLinearSpeed:Float):Void {
		Hb.b2World_SetMaxLinearSpeed(worldId.index1, worldId.generation, maximumLinearSpeed);
	}

	public static inline function b2World_GetMaxLinearSpeed(worldId:B2WorldId):Float {
		var result = Hb.b2World_GetMaxLinearSpeed(worldId.index1, worldId.generation);
		return result;
	}

	public static inline function b2World_EnableWarmStarting(worldId:B2WorldId, flag:Bool):Void {
		Hb.b2World_EnableWarmStarting(worldId.index1, worldId.generation, flag ? 1 : 0);
	}

	public static inline function b2World_IsWarmStartingEnabled(worldId:B2WorldId):Bool {
		var result = Hb.b2World_IsWarmStartingEnabled(worldId.index1, worldId.generation);
		return result != 0;
	}

	public static inline function b2World_EnableSSE2Fallback(worldId:B2WorldId, flag:Bool):Void {
		Hb.b2World_EnableSSE2Fallback(worldId.index1, worldId.generation, flag ? 1 : 0);
	}

	public static inline function b2World_GetAwakeBodyCount(worldId:B2WorldId):Int {
		var result = Hb.b2World_GetAwakeBodyCount(worldId.index1, worldId.generation);
		return result;
	}

	public static inline function b2World_GetProfile(worldId:B2WorldId, ?out:B2Profile):B2Profile {
		var value = out == null ? new B2Profile() : out;
		Hb.b2World_GetProfile(worldId.index1, worldId.generation);
		Io.begin();
		rdB2Profile(value);
		return value;
	}

	public static inline function b2World_GetCounters(worldId:B2WorldId, ?out:B2Counters):B2Counters {
		var value = out == null ? new B2Counters() : out;
		Hb.b2World_GetCounters(worldId.index1, worldId.generation);
		Io.begin();
		rdB2Counters(value);
		return value;
	}

	public static inline function b2World_GetMaxCapacity(worldId:B2WorldId, ?out:B2Capacity):B2Capacity {
		var value = out == null ? new B2Capacity() : out;
		Hb.b2World_GetMaxCapacity(worldId.index1, worldId.generation);
		Io.begin();
		rdB2Capacity(value);
		return value;
	}

	public static inline function b2World_SetUserData(worldId:B2WorldId, userData:Dynamic):Void {
		Data.set(worldId, userData);
	}

	public static inline function b2World_GetUserData(worldId:B2WorldId):Dynamic {
		return Data.get(worldId);
	}

	public static inline function b2World_SetFrictionCallback(worldId:B2WorldId, callback:B2FrictionCallbackFcn):Void {
		Callbacks.setWorldFunction(worldId, "b2FrictionCallbackFcn", callback);
		Hb.b2World_SetFrictionCallback(worldId.index1, worldId.generation, callback != null ? 1 : 0);
	}

	public static inline function b2World_SetRestitutionCallback(worldId:B2WorldId, callback:B2RestitutionCallbackFcn):Void {
		Callbacks.setWorldFunction(worldId, "b2RestitutionCallbackFcn", callback);
		Hb.b2World_SetRestitutionCallback(worldId.index1, worldId.generation, callback != null ? 1 : 0);
	}

	public static inline function b2World_SetWorkerCount(worldId:B2WorldId, count:Int):Void {
		Hb.b2World_SetWorkerCount(worldId.index1, worldId.generation, count);
	}

	public static inline function b2World_GetWorkerCount(worldId:B2WorldId):Int {
		var result = Hb.b2World_GetWorkerCount(worldId.index1, worldId.generation);
		return result;
	}

	public static inline function b2World_RebuildStaticTree(worldId:B2WorldId):Void {
		Hb.b2World_RebuildStaticTree(worldId.index1, worldId.generation);
	}

	public static inline function b2World_GetStateHash(worldId:B2WorldId):haxe.Int64 {
		Hb.b2World_GetStateHash(worldId.index1, worldId.generation);
		Io.begin();
		var value = Io.rl();
		return value;
	}

	public static inline function b2World_GetSnapshot(worldId:B2WorldId, image:haxe.io.Bytes, capacity:Int):Int {
		var result = Hb.b2World_GetSnapshot(worldId.index1, worldId.generation, image != null ? 1 : 0, capacity);
		Io.begin();
		if (image != null)
			Io.rbytes(image, result < capacity ? result : capacity);
		return result;
	}

	public static inline function b2World_RestoreFromSnapshot(worldId:B2WorldId, image:haxe.io.Bytes, size:Int):Bool {
		Io.begin();
		Io.wbytes(image, size);
		var result = Hb.b2World_RestoreFromSnapshot(worldId.index1, worldId.generation, size);
		return result != 0;
	}

	public static inline function b2CreateWorldFromSnapshot(image:haxe.io.Bytes, size:Int, workerCount:Int, ?out:B2WorldId):B2WorldId {
		var value = out == null ? new B2WorldId() : out;
		Io.begin();
		Io.wbytes(image, size);
		Hb.b2CreateWorldFromSnapshot(size, workerCount);
		Io.begin();
		rdB2WorldId(value);
		return value;
	}

	public static inline function b2CreateBody(worldId:B2WorldId, def:B2BodyDef, ?out:B2BodyId):B2BodyId {
		var value = out == null ? new B2BodyId() : out;
		Io.begin();
		wrB2BodyDef(def);
		Hb.b2CreateBody(worldId.index1, worldId.generation);
		Io.begin();
		rdB2BodyId(value);
		if (def.userData != null)
			Data.set(value, def.userData);
		return value;
	}

	public static inline function b2DestroyBody(bodyId:B2BodyId):Void {
		Hb.b2DestroyBody(bodyId.index1, bodyId.world0, bodyId.generation);
	}

	public static inline function b2Body_IsValid(id:B2BodyId):Bool {
		var result = Hb.b2Body_IsValid(id.index1, id.world0, id.generation);
		return result != 0;
	}

	public static inline function b2Body_GetType(bodyId:B2BodyId):B2BodyType {
		var result = Hb.b2Body_GetType(bodyId.index1, bodyId.world0, bodyId.generation);
		return cast result;
	}

	public static inline function b2Body_SetType(bodyId:B2BodyId, type:B2BodyType):Void {
		Hb.b2Body_SetType(bodyId.index1, bodyId.world0, bodyId.generation, (cast type : Int));
	}

	public static inline function b2Body_SetName(bodyId:B2BodyId, name:String):Void {
		Io.begin();
		Io.ws(name);
		Hb.b2Body_SetName(bodyId.index1, bodyId.world0, bodyId.generation);
	}

	public static inline function b2Body_GetName(bodyId:B2BodyId):String {
		Hb.b2Body_GetName(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		var value = Io.rs();
		return value;
	}

	public static inline function b2Body_SetUserData(bodyId:B2BodyId, userData:Dynamic):Void {
		Data.set(bodyId, userData);
	}

	public static inline function b2Body_GetUserData(bodyId:B2BodyId):Dynamic {
		return Data.get(bodyId);
	}

	public static inline function b2Body_GetPosition(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetPosition(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetRotation(bodyId:B2BodyId, ?out:B2Rot):B2Rot {
		var value = out == null ? new B2Rot() : out;
		Hb.b2Body_GetRotation(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2Rot(value);
		return value;
	}

	public static inline function b2Body_GetTransform(bodyId:B2BodyId, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2Body_GetTransform(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2Body_SetTransform(bodyId:B2BodyId, position:B2Vec2, rotation:B2Rot):Void {
		Hb.b2Body_SetTransform(bodyId.index1, bodyId.world0, bodyId.generation, position.x, position.y, rotation.c, rotation.s);
	}

	public static inline function b2Body_GetLocalPoint(bodyId:B2BodyId, worldPoint:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetLocalPoint(bodyId.index1, bodyId.world0, bodyId.generation, worldPoint.x, worldPoint.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetWorldPoint(bodyId:B2BodyId, localPoint:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetWorldPoint(bodyId.index1, bodyId.world0, bodyId.generation, localPoint.x, localPoint.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetLocalVector(bodyId:B2BodyId, worldVector:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetLocalVector(bodyId.index1, bodyId.world0, bodyId.generation, worldVector.x, worldVector.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetWorldVector(bodyId:B2BodyId, localVector:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetWorldVector(bodyId.index1, bodyId.world0, bodyId.generation, localVector.x, localVector.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetLinearVelocity(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetLinearVelocity(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetAngularVelocity(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetAngularVelocity(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_SetLinearVelocity(bodyId:B2BodyId, linearVelocity:B2Vec2):Void {
		Hb.b2Body_SetLinearVelocity(bodyId.index1, bodyId.world0, bodyId.generation, linearVelocity.x, linearVelocity.y);
	}

	public static inline function b2Body_SetAngularVelocity(bodyId:B2BodyId, angularVelocity:Float):Void {
		Hb.b2Body_SetAngularVelocity(bodyId.index1, bodyId.world0, bodyId.generation, angularVelocity);
	}

	public static inline function b2Body_SetTargetTransform(bodyId:B2BodyId, target:B2Transform, timeStep:Float, wake:Bool):Void {
		Hb.b2Body_SetTargetTransform(bodyId.index1, bodyId.world0, bodyId.generation, target.p.x, target.p.y, target.q.c, target.q.s, timeStep, wake ? 1 : 0);
	}

	public static inline function b2Body_GetLocalPointVelocity(bodyId:B2BodyId, localPoint:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetLocalPointVelocity(bodyId.index1, bodyId.world0, bodyId.generation, localPoint.x, localPoint.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetWorldPointVelocity(bodyId:B2BodyId, worldPoint:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetWorldPointVelocity(bodyId.index1, bodyId.world0, bodyId.generation, worldPoint.x, worldPoint.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_ApplyForce(bodyId:B2BodyId, force:B2Vec2, point:B2Vec2, wake:Bool):Void {
		Hb.b2Body_ApplyForce(bodyId.index1, bodyId.world0, bodyId.generation, force.x, force.y, point.x, point.y, wake ? 1 : 0);
	}

	public static inline function b2Body_ApplyForceToCenter(bodyId:B2BodyId, force:B2Vec2, wake:Bool):Void {
		Hb.b2Body_ApplyForceToCenter(bodyId.index1, bodyId.world0, bodyId.generation, force.x, force.y, wake ? 1 : 0);
	}

	public static inline function b2Body_ApplyTorque(bodyId:B2BodyId, torque:Float, wake:Bool):Void {
		Hb.b2Body_ApplyTorque(bodyId.index1, bodyId.world0, bodyId.generation, torque, wake ? 1 : 0);
	}

	public static inline function b2Body_ClearForces(bodyId:B2BodyId):Void {
		Hb.b2Body_ClearForces(bodyId.index1, bodyId.world0, bodyId.generation);
	}

	public static inline function b2Body_ApplyLinearImpulse(bodyId:B2BodyId, impulse:B2Vec2, point:B2Vec2, wake:Bool):Void {
		Hb.b2Body_ApplyLinearImpulse(bodyId.index1, bodyId.world0, bodyId.generation, impulse.x, impulse.y, point.x, point.y, wake ? 1 : 0);
	}

	public static inline function b2Body_ApplyLinearImpulseToCenter(bodyId:B2BodyId, impulse:B2Vec2, wake:Bool):Void {
		Hb.b2Body_ApplyLinearImpulseToCenter(bodyId.index1, bodyId.world0, bodyId.generation, impulse.x, impulse.y, wake ? 1 : 0);
	}

	public static inline function b2Body_ApplyAngularImpulse(bodyId:B2BodyId, impulse:Float, wake:Bool):Void {
		Hb.b2Body_ApplyAngularImpulse(bodyId.index1, bodyId.world0, bodyId.generation, impulse, wake ? 1 : 0);
	}

	public static inline function b2Body_GetMass(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetMass(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_GetRotationalInertia(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetRotationalInertia(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_GetLocalCenter(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetLocalCenter(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_GetWorldCenter(bodyId:B2BodyId, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Body_GetWorldCenter(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Body_SetMassData(bodyId:B2BodyId, massData:B2MassData):Void {
		Hb.b2Body_SetMassData(bodyId.index1, bodyId.world0, bodyId.generation, massData.mass, massData.center.x, massData.center.y, massData.rotationalInertia);
	}

	public static inline function b2Body_GetMassData(bodyId:B2BodyId, ?out:B2MassData):B2MassData {
		var value = out == null ? new B2MassData() : out;
		Hb.b2Body_GetMassData(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2MassData(value);
		return value;
	}

	public static inline function b2Body_UpdateMassFromShapes(bodyId:B2BodyId):Void {
		Hb.b2Body_UpdateMassFromShapes(bodyId.index1, bodyId.world0, bodyId.generation);
	}

	public static inline function b2Body_SetLinearDamping(bodyId:B2BodyId, linearDamping:Float):Void {
		Hb.b2Body_SetLinearDamping(bodyId.index1, bodyId.world0, bodyId.generation, linearDamping);
	}

	public static inline function b2Body_GetLinearDamping(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetLinearDamping(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_SetAngularDamping(bodyId:B2BodyId, angularDamping:Float):Void {
		Hb.b2Body_SetAngularDamping(bodyId.index1, bodyId.world0, bodyId.generation, angularDamping);
	}

	public static inline function b2Body_GetAngularDamping(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetAngularDamping(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_SetGravityScale(bodyId:B2BodyId, gravityScale:Float):Void {
		Hb.b2Body_SetGravityScale(bodyId.index1, bodyId.world0, bodyId.generation, gravityScale);
	}

	public static inline function b2Body_GetGravityScale(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetGravityScale(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_IsAwake(bodyId:B2BodyId):Bool {
		var result = Hb.b2Body_IsAwake(bodyId.index1, bodyId.world0, bodyId.generation);
		return result != 0;
	}

	public static inline function b2Body_SetAwake(bodyId:B2BodyId, awake:Bool):Void {
		Hb.b2Body_SetAwake(bodyId.index1, bodyId.world0, bodyId.generation, awake ? 1 : 0);
	}

	public static inline function b2Body_WakeTouching(bodyId:B2BodyId):Void {
		Hb.b2Body_WakeTouching(bodyId.index1, bodyId.world0, bodyId.generation);
	}

	public static inline function b2Body_EnableSleeping(bodyId:B2BodyId, enableSleep:Bool):Void {
		Hb.b2Body_EnableSleeping(bodyId.index1, bodyId.world0, bodyId.generation, enableSleep ? 1 : 0);
	}

	public static inline function b2Body_IsSleepingEnabled(bodyId:B2BodyId):Bool {
		var result = Hb.b2Body_IsSleepingEnabled(bodyId.index1, bodyId.world0, bodyId.generation);
		return result != 0;
	}

	public static inline function b2Body_SetSleepThreshold(bodyId:B2BodyId, sleepThreshold:Float):Void {
		Hb.b2Body_SetSleepThreshold(bodyId.index1, bodyId.world0, bodyId.generation, sleepThreshold);
	}

	public static inline function b2Body_GetSleepThreshold(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetSleepThreshold(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_SetSafetyFactor(bodyId:B2BodyId, safetyFactor:Float):Void {
		Hb.b2Body_SetSafetyFactor(bodyId.index1, bodyId.world0, bodyId.generation, safetyFactor);
	}

	public static inline function b2Body_GetSafetyFactor(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetSafetyFactor(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_IsEnabled(bodyId:B2BodyId):Bool {
		var result = Hb.b2Body_IsEnabled(bodyId.index1, bodyId.world0, bodyId.generation);
		return result != 0;
	}

	public static inline function b2Body_Disable(bodyId:B2BodyId):Void {
		Hb.b2Body_Disable(bodyId.index1, bodyId.world0, bodyId.generation);
	}

	public static inline function b2Body_Enable(bodyId:B2BodyId):Void {
		Hb.b2Body_Enable(bodyId.index1, bodyId.world0, bodyId.generation);
	}

	public static inline function b2Body_SetMotionLocks(bodyId:B2BodyId, locks:B2MotionLocks):Void {
		Hb.b2Body_SetMotionLocks(bodyId.index1, bodyId.world0, bodyId.generation, locks.linearX ? 1 : 0, locks.linearY ? 1 : 0, locks.angularZ ? 1 : 0);
	}

	public static inline function b2Body_GetMotionLocks(bodyId:B2BodyId, ?out:B2MotionLocks):B2MotionLocks {
		var value = out == null ? new B2MotionLocks() : out;
		Hb.b2Body_GetMotionLocks(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2MotionLocks(value);
		return value;
	}

	public static inline function b2Body_SetBullet(bodyId:B2BodyId, flag:Bool):Void {
		Hb.b2Body_SetBullet(bodyId.index1, bodyId.world0, bodyId.generation, flag ? 1 : 0);
	}

	public static inline function b2Body_IsBullet(bodyId:B2BodyId):Bool {
		var result = Hb.b2Body_IsBullet(bodyId.index1, bodyId.world0, bodyId.generation);
		return result != 0;
	}

	public static inline function b2Body_EnableContactRecycling(bodyId:B2BodyId, flag:Bool):Void {
		Hb.b2Body_EnableContactRecycling(bodyId.index1, bodyId.world0, bodyId.generation, flag ? 1 : 0);
	}

	public static inline function b2Body_IsContactRecyclingEnabled(bodyId:B2BodyId):Bool {
		var result = Hb.b2Body_IsContactRecyclingEnabled(bodyId.index1, bodyId.world0, bodyId.generation);
		return result != 0;
	}

	public static inline function b2Body_EnableContactEvents(bodyId:B2BodyId, flag:Bool):Void {
		Hb.b2Body_EnableContactEvents(bodyId.index1, bodyId.world0, bodyId.generation, flag ? 1 : 0);
	}

	public static inline function b2Body_EnableHitEvents(bodyId:B2BodyId, flag:Bool):Void {
		Hb.b2Body_EnableHitEvents(bodyId.index1, bodyId.world0, bodyId.generation, flag ? 1 : 0);
	}

	public static inline function b2Body_GetWorld(bodyId:B2BodyId, ?out:B2WorldId):B2WorldId {
		var value = out == null ? new B2WorldId() : out;
		Hb.b2Body_GetWorld(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2WorldId(value);
		return value;
	}

	public static inline function b2Body_GetShapeCount(bodyId:B2BodyId):Int {
		var result = Hb.b2Body_GetShapeCount(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_GetShapes(bodyId:B2BodyId, shapeArray:Array<B2ShapeId>, capacity:Int):Int {
		var result = Hb.b2Body_GetShapes(bodyId.index1, bodyId.world0, bodyId.generation, capacity);
		Io.begin();
		{
			var filled = Io.ri();
			if (shapeArray != null)
				for (k in 0...filled) {
					if (k >= shapeArray.length)
						shapeArray.push(Init.makeB2ShapeId());
					rdB2ShapeId(shapeArray[k]);
				}
		}
		return result;
	}

	public static inline function b2Body_GetJointCount(bodyId:B2BodyId):Int {
		var result = Hb.b2Body_GetJointCount(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_GetJoints(bodyId:B2BodyId, jointArray:Array<B2JointId>, capacity:Int):Int {
		var result = Hb.b2Body_GetJoints(bodyId.index1, bodyId.world0, bodyId.generation, capacity);
		Io.begin();
		{
			var filled = Io.ri();
			if (jointArray != null)
				for (k in 0...filled) {
					if (k >= jointArray.length)
						jointArray.push(Init.makeB2JointId());
					rdB2JointId(jointArray[k]);
				}
		}
		return result;
	}

	public static inline function b2Body_GetContactCapacity(bodyId:B2BodyId):Int {
		var result = Hb.b2Body_GetContactCapacity(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_GetContactData(bodyId:B2BodyId, contactData:Array<B2ContactData>, capacity:Int):Int {
		var result = Hb.b2Body_GetContactData(bodyId.index1, bodyId.world0, bodyId.generation, capacity);
		Io.begin();
		{
			var filled = Io.ri();
			if (contactData != null)
				for (k in 0...filled) {
					if (k >= contactData.length)
						contactData.push(Init.makeB2ContactData());
					rdB2ContactData(contactData[k]);
				}
		}
		return result;
	}

	public static inline function b2Body_ComputeBounds(bodyId:B2BodyId, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Hb.b2Body_ComputeBounds(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2Body_GetMinExtent(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetMinExtent(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_GetMaxExtent(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetMaxExtent(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2Body_GetMaxExtentFromOrigin(bodyId:B2BodyId):Float {
		var result = Hb.b2Body_GetMaxExtentFromOrigin(bodyId.index1, bodyId.world0, bodyId.generation);
		return result;
	}

	public static inline function b2CreateCircleShape(bodyId:B2BodyId, def:B2ShapeDef, circle:B2Circle, ?out:B2ShapeId):B2ShapeId {
		var value = out == null ? new B2ShapeId() : out;
		Io.begin();
		wrB2ShapeDef(def);
		wrB2Circle(circle);
		Hb.b2CreateCircleShape(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2ShapeId(value);
		if (def.userData != null)
			Data.set(value, def.userData);
		return value;
	}

	public static inline function b2CreateSegmentShape(bodyId:B2BodyId, def:B2ShapeDef, segment:B2Segment, ?out:B2ShapeId):B2ShapeId {
		var value = out == null ? new B2ShapeId() : out;
		Io.begin();
		wrB2ShapeDef(def);
		wrB2Segment(segment);
		Hb.b2CreateSegmentShape(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2ShapeId(value);
		if (def.userData != null)
			Data.set(value, def.userData);
		return value;
	}

	public static inline function b2CreateChainSegmentShape(bodyId:B2BodyId, def:B2ShapeDef, chainSegment:B2ChainSegment, ?out:B2ShapeId):B2ShapeId {
		var value = out == null ? new B2ShapeId() : out;
		Io.begin();
		wrB2ShapeDef(def);
		wrB2ChainSegment(chainSegment);
		Hb.b2CreateChainSegmentShape(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2ShapeId(value);
		if (def.userData != null)
			Data.set(value, def.userData);
		return value;
	}

	public static inline function b2CreateCapsuleShape(bodyId:B2BodyId, def:B2ShapeDef, capsule:B2Capsule, ?out:B2ShapeId):B2ShapeId {
		var value = out == null ? new B2ShapeId() : out;
		Io.begin();
		wrB2ShapeDef(def);
		wrB2Capsule(capsule);
		Hb.b2CreateCapsuleShape(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2ShapeId(value);
		if (def.userData != null)
			Data.set(value, def.userData);
		return value;
	}

	public static inline function b2CreatePolygonShape(bodyId:B2BodyId, def:B2ShapeDef, polygon:B2Polygon, ?out:B2ShapeId):B2ShapeId {
		var value = out == null ? new B2ShapeId() : out;
		Io.begin();
		wrB2ShapeDef(def);
		wrB2Polygon(polygon);
		Hb.b2CreatePolygonShape(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2ShapeId(value);
		if (def.userData != null)
			Data.set(value, def.userData);
		return value;
	}

	public static inline function b2DestroyShape(shapeId:B2ShapeId, updateBodyMass:Bool):Void {
		Hb.b2DestroyShape(shapeId.index1, shapeId.world0, shapeId.generation, updateBodyMass ? 1 : 0);
	}

	public static inline function b2Shape_IsValid(id:B2ShapeId):Bool {
		var result = Hb.b2Shape_IsValid(id.index1, id.world0, id.generation);
		return result != 0;
	}

	public static inline function b2Shape_GetType(shapeId:B2ShapeId):B2ShapeType {
		var result = Hb.b2Shape_GetType(shapeId.index1, shapeId.world0, shapeId.generation);
		return cast result;
	}

	public static inline function b2Shape_GetBody(shapeId:B2ShapeId, ?out:B2BodyId):B2BodyId {
		var value = out == null ? new B2BodyId() : out;
		Hb.b2Shape_GetBody(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2BodyId(value);
		return value;
	}

	public static inline function b2Shape_GetWorld(shapeId:B2ShapeId, ?out:B2WorldId):B2WorldId {
		var value = out == null ? new B2WorldId() : out;
		Hb.b2Shape_GetWorld(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2WorldId(value);
		return value;
	}

	public static inline function b2Shape_IsSensor(shapeId:B2ShapeId):Bool {
		var result = Hb.b2Shape_IsSensor(shapeId.index1, shapeId.world0, shapeId.generation);
		return result != 0;
	}

	public static inline function b2Shape_SetUserData(shapeId:B2ShapeId, userData:Dynamic):Void {
		Data.set(shapeId, userData);
	}

	public static inline function b2Shape_GetUserData(shapeId:B2ShapeId):Dynamic {
		return Data.get(shapeId);
	}

	public static inline function b2Shape_SetDensity(shapeId:B2ShapeId, density:Float, updateBodyMass:Bool):Void {
		Hb.b2Shape_SetDensity(shapeId.index1, shapeId.world0, shapeId.generation, density, updateBodyMass ? 1 : 0);
	}

	public static inline function b2Shape_GetDensity(shapeId:B2ShapeId):Float {
		var result = Hb.b2Shape_GetDensity(shapeId.index1, shapeId.world0, shapeId.generation);
		return result;
	}

	public static inline function b2Shape_SetFriction(shapeId:B2ShapeId, friction:Float):Void {
		Hb.b2Shape_SetFriction(shapeId.index1, shapeId.world0, shapeId.generation, friction);
	}

	public static inline function b2Shape_GetFriction(shapeId:B2ShapeId):Float {
		var result = Hb.b2Shape_GetFriction(shapeId.index1, shapeId.world0, shapeId.generation);
		return result;
	}

	public static inline function b2Shape_SetRestitution(shapeId:B2ShapeId, restitution:Float):Void {
		Hb.b2Shape_SetRestitution(shapeId.index1, shapeId.world0, shapeId.generation, restitution);
	}

	public static inline function b2Shape_GetRestitution(shapeId:B2ShapeId):Float {
		var result = Hb.b2Shape_GetRestitution(shapeId.index1, shapeId.world0, shapeId.generation);
		return result;
	}

	public static inline function b2Shape_SetUserMaterial(shapeId:B2ShapeId, material:haxe.Int64):Void {
		Hb.b2Shape_SetUserMaterial(shapeId.index1, shapeId.world0, shapeId.generation, material.low, material.high);
	}

	public static inline function b2Shape_GetUserMaterial(shapeId:B2ShapeId):haxe.Int64 {
		Hb.b2Shape_GetUserMaterial(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		var value = Io.rl();
		return value;
	}

	public static inline function b2Shape_SetSurfaceMaterial(shapeId:B2ShapeId, surfaceMaterial:B2SurfaceMaterial):Void {
		Io.begin();
		wrB2SurfaceMaterial(surfaceMaterial);
		Hb.b2Shape_SetSurfaceMaterial(shapeId.index1, shapeId.world0, shapeId.generation);
	}

	public static inline function b2Shape_GetSurfaceMaterial(shapeId:B2ShapeId, ?out:B2SurfaceMaterial):B2SurfaceMaterial {
		var value = out == null ? new B2SurfaceMaterial() : out;
		Hb.b2Shape_GetSurfaceMaterial(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2SurfaceMaterial(value);
		return value;
	}

	public static inline function b2Shape_GetFilter(shapeId:B2ShapeId, ?out:B2Filter):B2Filter {
		var value = out == null ? new B2Filter() : out;
		Hb.b2Shape_GetFilter(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2Filter(value);
		return value;
	}

	public static inline function b2Shape_SetFilter(shapeId:B2ShapeId, filter:B2Filter):Void {
		Io.begin();
		wrB2Filter(filter);
		Hb.b2Shape_SetFilter(shapeId.index1, shapeId.world0, shapeId.generation);
	}

	public static inline function b2Shape_EnableSensorEvents(shapeId:B2ShapeId, flag:Bool):Void {
		Hb.b2Shape_EnableSensorEvents(shapeId.index1, shapeId.world0, shapeId.generation, flag ? 1 : 0);
	}

	public static inline function b2Shape_AreSensorEventsEnabled(shapeId:B2ShapeId):Bool {
		var result = Hb.b2Shape_AreSensorEventsEnabled(shapeId.index1, shapeId.world0, shapeId.generation);
		return result != 0;
	}

	public static inline function b2Shape_EnableContactEvents(shapeId:B2ShapeId, flag:Bool):Void {
		Hb.b2Shape_EnableContactEvents(shapeId.index1, shapeId.world0, shapeId.generation, flag ? 1 : 0);
	}

	public static inline function b2Shape_AreContactEventsEnabled(shapeId:B2ShapeId):Bool {
		var result = Hb.b2Shape_AreContactEventsEnabled(shapeId.index1, shapeId.world0, shapeId.generation);
		return result != 0;
	}

	public static inline function b2Shape_EnablePreSolveEvents(shapeId:B2ShapeId, flag:Bool):Void {
		Hb.b2Shape_EnablePreSolveEvents(shapeId.index1, shapeId.world0, shapeId.generation, flag ? 1 : 0);
	}

	public static inline function b2Shape_ArePreSolveEventsEnabled(shapeId:B2ShapeId):Bool {
		var result = Hb.b2Shape_ArePreSolveEventsEnabled(shapeId.index1, shapeId.world0, shapeId.generation);
		return result != 0;
	}

	public static inline function b2Shape_EnableHitEvents(shapeId:B2ShapeId, flag:Bool):Void {
		Hb.b2Shape_EnableHitEvents(shapeId.index1, shapeId.world0, shapeId.generation, flag ? 1 : 0);
	}

	public static inline function b2Shape_AreHitEventsEnabled(shapeId:B2ShapeId):Bool {
		var result = Hb.b2Shape_AreHitEventsEnabled(shapeId.index1, shapeId.world0, shapeId.generation);
		return result != 0;
	}

	public static inline function b2Shape_TestPoint(shapeId:B2ShapeId, point:B2Vec2):Bool {
		var result = Hb.b2Shape_TestPoint(shapeId.index1, shapeId.world0, shapeId.generation, point.x, point.y);
		return result != 0;
	}

	public static inline function b2Shape_CastRay(shapeId:B2ShapeId, origin:B2Vec2, translation:B2Vec2, ?out:B2CastOutput):B2CastOutput {
		var value = out == null ? new B2CastOutput() : out;
		Hb.b2Shape_CastRay(shapeId.index1, shapeId.world0, shapeId.generation, origin.x, origin.y, translation.x, translation.y);
		Io.begin();
		rdB2CastOutput(value);
		return value;
	}

	public static inline function b2Shape_GetCircle(shapeId:B2ShapeId, ?out:B2Circle):B2Circle {
		var value = out == null ? new B2Circle() : out;
		Hb.b2Shape_GetCircle(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2Circle(value);
		return value;
	}

	public static inline function b2Shape_GetSegment(shapeId:B2ShapeId, ?out:B2Segment):B2Segment {
		var value = out == null ? new B2Segment() : out;
		Hb.b2Shape_GetSegment(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2Segment(value);
		return value;
	}

	public static inline function b2Shape_GetChainSegment(shapeId:B2ShapeId, ?out:B2ChainSegment):B2ChainSegment {
		var value = out == null ? new B2ChainSegment() : out;
		Hb.b2Shape_GetChainSegment(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2ChainSegment(value);
		return value;
	}

	public static inline function b2Shape_GetCapsule(shapeId:B2ShapeId, ?out:B2Capsule):B2Capsule {
		var value = out == null ? new B2Capsule() : out;
		Hb.b2Shape_GetCapsule(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2Capsule(value);
		return value;
	}

	public static inline function b2Shape_GetPolygon(shapeId:B2ShapeId, ?out:B2Polygon):B2Polygon {
		var value = out == null ? new B2Polygon() : out;
		Hb.b2Shape_GetPolygon(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2Polygon(value);
		return value;
	}

	public static inline function b2Shape_SetCircle(shapeId:B2ShapeId, circle:B2Circle):Void {
		Io.begin();
		wrB2Circle(circle);
		Hb.b2Shape_SetCircle(shapeId.index1, shapeId.world0, shapeId.generation);
	}

	public static inline function b2Shape_SetCapsule(shapeId:B2ShapeId, capsule:B2Capsule):Void {
		Io.begin();
		wrB2Capsule(capsule);
		Hb.b2Shape_SetCapsule(shapeId.index1, shapeId.world0, shapeId.generation);
	}

	public static inline function b2Shape_SetSegment(shapeId:B2ShapeId, segment:B2Segment):Void {
		Io.begin();
		wrB2Segment(segment);
		Hb.b2Shape_SetSegment(shapeId.index1, shapeId.world0, shapeId.generation);
	}

	public static inline function b2Shape_SetPolygon(shapeId:B2ShapeId, polygon:B2Polygon):Void {
		Io.begin();
		wrB2Polygon(polygon);
		Hb.b2Shape_SetPolygon(shapeId.index1, shapeId.world0, shapeId.generation);
	}

	public static inline function b2Shape_SetChainSegment(shapeId:B2ShapeId, chainSegment:B2ChainSegment):Void {
		Io.begin();
		wrB2ChainSegment(chainSegment);
		Hb.b2Shape_SetChainSegment(shapeId.index1, shapeId.world0, shapeId.generation);
	}

	public static inline function b2Shape_GetParentChain(shapeId:B2ShapeId, ?out:B2ChainId):B2ChainId {
		var value = out == null ? new B2ChainId() : out;
		Hb.b2Shape_GetParentChain(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2ChainId(value);
		return value;
	}

	public static inline function b2Shape_GetContactCapacity(shapeId:B2ShapeId):Int {
		var result = Hb.b2Shape_GetContactCapacity(shapeId.index1, shapeId.world0, shapeId.generation);
		return result;
	}

	public static inline function b2Shape_GetContactData(shapeId:B2ShapeId, contactData:Array<B2ContactData>, capacity:Int):Int {
		var result = Hb.b2Shape_GetContactData(shapeId.index1, shapeId.world0, shapeId.generation, capacity);
		Io.begin();
		{
			var filled = Io.ri();
			if (contactData != null)
				for (k in 0...filled) {
					if (k >= contactData.length)
						contactData.push(Init.makeB2ContactData());
					rdB2ContactData(contactData[k]);
				}
		}
		return result;
	}

	public static inline function b2Shape_GetSensorCapacity(shapeId:B2ShapeId):Int {
		var result = Hb.b2Shape_GetSensorCapacity(shapeId.index1, shapeId.world0, shapeId.generation);
		return result;
	}

	public static inline function b2Shape_GetSensorData(shapeId:B2ShapeId, visitorIds:Array<B2ShapeId>, capacity:Int):Int {
		var result = Hb.b2Shape_GetSensorData(shapeId.index1, shapeId.world0, shapeId.generation, capacity);
		Io.begin();
		{
			var filled = Io.ri();
			if (visitorIds != null)
				for (k in 0...filled) {
					if (k >= visitorIds.length)
						visitorIds.push(Init.makeB2ShapeId());
					rdB2ShapeId(visitorIds[k]);
				}
		}
		return result;
	}

	public static inline function b2Shape_GetBounds(shapeId:B2ShapeId, ?out:B2AABB):B2AABB {
		var value = out == null ? new B2AABB() : out;
		Hb.b2Shape_GetBounds(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2AABB(value);
		return value;
	}

	public static inline function b2Shape_ComputeMassData(shapeId:B2ShapeId, ?out:B2MassData):B2MassData {
		var value = out == null ? new B2MassData() : out;
		Hb.b2Shape_ComputeMassData(shapeId.index1, shapeId.world0, shapeId.generation);
		Io.begin();
		rdB2MassData(value);
		return value;
	}

	public static inline function b2Shape_GetClosestPoint(shapeId:B2ShapeId, target:B2Vec2, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Shape_GetClosestPoint(shapeId.index1, shapeId.world0, shapeId.generation, target.x, target.y);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Shape_ApplyWind(shapeId:B2ShapeId, wind:B2Vec2, drag:Float, lift:Float, wake:Bool):Void {
		Hb.b2Shape_ApplyWind(shapeId.index1, shapeId.world0, shapeId.generation, wind.x, wind.y, drag, lift, wake ? 1 : 0);
	}

	public static inline function b2CreateChain(bodyId:B2BodyId, def:B2ChainDef, ?out:B2ChainId):B2ChainId {
		var value = out == null ? new B2ChainId() : out;
		Io.begin();
		wrB2ChainDef(def);
		Hb.b2CreateChain(bodyId.index1, bodyId.world0, bodyId.generation);
		Io.begin();
		rdB2ChainId(value);
		if (def.userData != null)
			Data.set(value, def.userData);
		return value;
	}

	public static inline function b2DestroyChain(chainId:B2ChainId):Void {
		Hb.b2DestroyChain(chainId.index1, chainId.world0, chainId.generation);
	}

	public static inline function b2Chain_GetWorld(chainId:B2ChainId, ?out:B2WorldId):B2WorldId {
		var value = out == null ? new B2WorldId() : out;
		Hb.b2Chain_GetWorld(chainId.index1, chainId.world0, chainId.generation);
		Io.begin();
		rdB2WorldId(value);
		return value;
	}

	public static inline function b2Chain_GetSegmentCount(chainId:B2ChainId):Int {
		var result = Hb.b2Chain_GetSegmentCount(chainId.index1, chainId.world0, chainId.generation);
		return result;
	}

	public static inline function b2Chain_GetSegments(chainId:B2ChainId, segmentArray:Array<B2ShapeId>, capacity:Int):Int {
		var result = Hb.b2Chain_GetSegments(chainId.index1, chainId.world0, chainId.generation, capacity);
		Io.begin();
		{
			var filled = Io.ri();
			if (segmentArray != null)
				for (k in 0...filled) {
					if (k >= segmentArray.length)
						segmentArray.push(Init.makeB2ShapeId());
					rdB2ShapeId(segmentArray[k]);
				}
		}
		return result;
	}

	public static inline function b2Chain_SetAllSurfaceMaterials(chainId:B2ChainId, material:B2SurfaceMaterial):Void {
		Io.begin();
		wrB2SurfaceMaterial(material);
		Hb.b2Chain_SetAllSurfaceMaterials(chainId.index1, chainId.world0, chainId.generation);
	}

	public static inline function b2Chain_SetSurfaceMaterial(chainId:B2ChainId, material:B2SurfaceMaterial, segmentIndex:Int):Void {
		Io.begin();
		wrB2SurfaceMaterial(material);
		Hb.b2Chain_SetSurfaceMaterial(chainId.index1, chainId.world0, chainId.generation, segmentIndex);
	}

	public static inline function b2Chain_GetSurfaceMaterial(chainId:B2ChainId, segmentIndex:Int, ?out:B2SurfaceMaterial):B2SurfaceMaterial {
		var value = out == null ? new B2SurfaceMaterial() : out;
		Hb.b2Chain_GetSurfaceMaterial(chainId.index1, chainId.world0, chainId.generation, segmentIndex);
		Io.begin();
		rdB2SurfaceMaterial(value);
		return value;
	}

	public static inline function b2Chain_IsValid(id:B2ChainId):Bool {
		var result = Hb.b2Chain_IsValid(id.index1, id.world0, id.generation);
		return result != 0;
	}

	public static inline function b2DestroyJoint(jointId:B2JointId):Void {
		Hb.b2DestroyJoint(jointId.index1, jointId.world0, jointId.generation);
	}

	public static inline function b2Joint_IsValid(id:B2JointId):Bool {
		var result = Hb.b2Joint_IsValid(id.index1, id.world0, id.generation);
		return result != 0;
	}

	public static inline function b2Joint_GetType(jointId:B2JointId):B2JointType {
		var result = Hb.b2Joint_GetType(jointId.index1, jointId.world0, jointId.generation);
		return cast result;
	}

	public static inline function b2Joint_GetBodyA(jointId:B2JointId, ?out:B2BodyId):B2BodyId {
		var value = out == null ? new B2BodyId() : out;
		Hb.b2Joint_GetBodyA(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		rdB2BodyId(value);
		return value;
	}

	public static inline function b2Joint_GetBodyB(jointId:B2JointId, ?out:B2BodyId):B2BodyId {
		var value = out == null ? new B2BodyId() : out;
		Hb.b2Joint_GetBodyB(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		rdB2BodyId(value);
		return value;
	}

	public static inline function b2Joint_GetWorld(jointId:B2JointId, ?out:B2WorldId):B2WorldId {
		var value = out == null ? new B2WorldId() : out;
		Hb.b2Joint_GetWorld(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		rdB2WorldId(value);
		return value;
	}

	public static inline function b2Joint_SetLocalFrameA(jointId:B2JointId, localFrame:B2Transform):Void {
		Hb.b2Joint_SetLocalFrameA(jointId.index1, jointId.world0, jointId.generation, localFrame.p.x, localFrame.p.y, localFrame.q.c, localFrame.q.s);
	}

	public static inline function b2Joint_GetLocalFrameA(jointId:B2JointId, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2Joint_GetLocalFrameA(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2Joint_SetLocalFrameB(jointId:B2JointId, localFrame:B2Transform):Void {
		Hb.b2Joint_SetLocalFrameB(jointId.index1, jointId.world0, jointId.generation, localFrame.p.x, localFrame.p.y, localFrame.q.c, localFrame.q.s);
	}

	public static inline function b2Joint_GetLocalFrameB(jointId:B2JointId, ?out:B2Transform):B2Transform {
		var value = out == null ? new B2Transform() : out;
		Hb.b2Joint_GetLocalFrameB(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		rdB2Transform(value);
		return value;
	}

	public static inline function b2Joint_SetCollideConnected(jointId:B2JointId, shouldCollide:Bool):Void {
		Hb.b2Joint_SetCollideConnected(jointId.index1, jointId.world0, jointId.generation, shouldCollide ? 1 : 0);
	}

	public static inline function b2Joint_GetCollideConnected(jointId:B2JointId):Bool {
		var result = Hb.b2Joint_GetCollideConnected(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2Joint_SetUserData(jointId:B2JointId, userData:Dynamic):Void {
		Data.set(jointId, userData);
	}

	public static inline function b2Joint_GetUserData(jointId:B2JointId):Dynamic {
		return Data.get(jointId);
	}

	public static inline function b2Joint_WakeBodies(jointId:B2JointId):Void {
		Hb.b2Joint_WakeBodies(jointId.index1, jointId.world0, jointId.generation);
	}

	public static inline function b2Joint_GetConstraintForce(jointId:B2JointId, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2Joint_GetConstraintForce(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2Joint_GetConstraintTorque(jointId:B2JointId):Float {
		var result = Hb.b2Joint_GetConstraintTorque(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2Joint_GetLinearSeparation(jointId:B2JointId):Float {
		var result = Hb.b2Joint_GetLinearSeparation(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2Joint_GetAngularSeparation(jointId:B2JointId):Float {
		var result = Hb.b2Joint_GetAngularSeparation(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2Joint_SetConstraintTuning(jointId:B2JointId, hertz:Float, dampingRatio:Float):Void {
		Hb.b2Joint_SetConstraintTuning(jointId.index1, jointId.world0, jointId.generation, hertz, dampingRatio);
	}

	public static inline function b2Joint_GetConstraintTuning(jointId:B2JointId, hertz:Array<Float>, dampingRatio:Array<Float>):Void {
		Hb.b2Joint_GetConstraintTuning(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		hertz[0] = Io.rf();
		dampingRatio[0] = Io.rf();
	}

	public static inline function b2Joint_SetForceThreshold(jointId:B2JointId, threshold:Float):Void {
		Hb.b2Joint_SetForceThreshold(jointId.index1, jointId.world0, jointId.generation, threshold);
	}

	public static inline function b2Joint_GetForceThreshold(jointId:B2JointId):Float {
		var result = Hb.b2Joint_GetForceThreshold(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2Joint_SetTorqueThreshold(jointId:B2JointId, threshold:Float):Void {
		Hb.b2Joint_SetTorqueThreshold(jointId.index1, jointId.world0, jointId.generation, threshold);
	}

	public static inline function b2Joint_GetTorqueThreshold(jointId:B2JointId):Float {
		var result = Hb.b2Joint_GetTorqueThreshold(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2CreateDistanceJoint(worldId:B2WorldId, def:B2DistanceJointDef, ?out:B2JointId):B2JointId {
		var value = out == null ? new B2JointId() : out;
		Io.begin();
		wrB2DistanceJointDef(def);
		Hb.b2CreateDistanceJoint(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointId(value);
		if (def.base.userData != null)
			Data.set(value, def.base.userData);
		return value;
	}

	public static inline function b2DistanceJoint_SetRestLength(jointId:B2JointId, length:Float):Void {
		Hb.b2DistanceJoint_SetRestLength(jointId.index1, jointId.world0, jointId.generation, length);
	}

	public static inline function b2DistanceJoint_GetRestLength(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetRestLength(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		Hb.b2DistanceJoint_EnableSpring(jointId.index1, jointId.world0, jointId.generation, enableSpring ? 1 : 0);
	}

	public static inline function b2DistanceJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2DistanceJoint_IsSpringEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2DistanceJoint_SetSpringForceRange(jointId:B2JointId, lowerForce:Float, upperForce:Float):Void {
		Hb.b2DistanceJoint_SetSpringForceRange(jointId.index1, jointId.world0, jointId.generation, lowerForce, upperForce);
	}

	public static inline function b2DistanceJoint_GetSpringForceRange(jointId:B2JointId, lowerForce:Array<Float>, upperForce:Array<Float>):Void {
		Hb.b2DistanceJoint_GetSpringForceRange(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		lowerForce[0] = Io.rf();
		upperForce[0] = Io.rf();
	}

	public static inline function b2DistanceJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2DistanceJoint_SetSpringHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2DistanceJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		Hb.b2DistanceJoint_SetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation, dampingRatio);
	}

	public static inline function b2DistanceJoint_GetSpringHertz(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetSpringHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_GetSpringForce(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetSpringForce(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		Hb.b2DistanceJoint_EnableLimit(jointId.index1, jointId.world0, jointId.generation, enableLimit ? 1 : 0);
	}

	public static inline function b2DistanceJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2DistanceJoint_IsLimitEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2DistanceJoint_SetLimits(jointId:B2JointId, minLength:Float, maxLength:Float):Void {
		Hb.b2DistanceJoint_SetLimits(jointId.index1, jointId.world0, jointId.generation, minLength, maxLength);
	}

	public static inline function b2DistanceJoint_GetLowerLimit(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetLowerLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_GetUpperLimit(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetUpperLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_GetCurrentLength(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetCurrentLength(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		Hb.b2DistanceJoint_EnableMotor(jointId.index1, jointId.world0, jointId.generation, enableMotor ? 1 : 0);
	}

	public static inline function b2DistanceJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2DistanceJoint_IsMotorEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2DistanceJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		Hb.b2DistanceJoint_SetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation, motorSpeed);
	}

	public static inline function b2DistanceJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_SetMaxMotorForce(jointId:B2JointId, force:Float):Void {
		Hb.b2DistanceJoint_SetMaxMotorForce(jointId.index1, jointId.world0, jointId.generation, force);
	}

	public static inline function b2DistanceJoint_GetMaxMotorForce(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetMaxMotorForce(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2DistanceJoint_GetCurrentMotorForce(jointId:B2JointId):Float {
		var result = Hb.b2DistanceJoint_GetCurrentMotorForce(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2CreateFilterJoint(worldId:B2WorldId, def:B2FilterJointDef, ?out:B2JointId):B2JointId {
		var value = out == null ? new B2JointId() : out;
		Io.begin();
		wrB2FilterJointDef(def);
		Hb.b2CreateFilterJoint(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointId(value);
		if (def.base.userData != null)
			Data.set(value, def.base.userData);
		return value;
	}

	public static inline function b2CreateMotorJoint(worldId:B2WorldId, def:B2MotorJointDef, ?out:B2JointId):B2JointId {
		var value = out == null ? new B2JointId() : out;
		Io.begin();
		wrB2MotorJointDef(def);
		Hb.b2CreateMotorJoint(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointId(value);
		if (def.base.userData != null)
			Data.set(value, def.base.userData);
		return value;
	}

	public static inline function b2MotorJoint_SetLinearVelocity(jointId:B2JointId, velocity:B2Vec2):Void {
		Hb.b2MotorJoint_SetLinearVelocity(jointId.index1, jointId.world0, jointId.generation, velocity.x, velocity.y);
	}

	public static inline function b2MotorJoint_GetLinearVelocity(jointId:B2JointId, ?out:B2Vec2):B2Vec2 {
		var value = out == null ? new B2Vec2() : out;
		Hb.b2MotorJoint_GetLinearVelocity(jointId.index1, jointId.world0, jointId.generation);
		Io.begin();
		Io.rv(value);
		return value;
	}

	public static inline function b2MotorJoint_SetAngularVelocity(jointId:B2JointId, velocity:Float):Void {
		Hb.b2MotorJoint_SetAngularVelocity(jointId.index1, jointId.world0, jointId.generation, velocity);
	}

	public static inline function b2MotorJoint_GetAngularVelocity(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetAngularVelocity(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetMaxVelocityForce(jointId:B2JointId, maxForce:Float):Void {
		Hb.b2MotorJoint_SetMaxVelocityForce(jointId.index1, jointId.world0, jointId.generation, maxForce);
	}

	public static inline function b2MotorJoint_GetMaxVelocityForce(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetMaxVelocityForce(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetMaxVelocityTorque(jointId:B2JointId, maxTorque:Float):Void {
		Hb.b2MotorJoint_SetMaxVelocityTorque(jointId.index1, jointId.world0, jointId.generation, maxTorque);
	}

	public static inline function b2MotorJoint_GetMaxVelocityTorque(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetMaxVelocityTorque(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetLinearHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2MotorJoint_SetLinearHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2MotorJoint_GetLinearHertz(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetLinearHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetLinearDampingRatio(jointId:B2JointId, damping:Float):Void {
		Hb.b2MotorJoint_SetLinearDampingRatio(jointId.index1, jointId.world0, jointId.generation, damping);
	}

	public static inline function b2MotorJoint_GetLinearDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetLinearDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetAngularHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2MotorJoint_SetAngularHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2MotorJoint_GetAngularHertz(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetAngularHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetAngularDampingRatio(jointId:B2JointId, damping:Float):Void {
		Hb.b2MotorJoint_SetAngularDampingRatio(jointId.index1, jointId.world0, jointId.generation, damping);
	}

	public static inline function b2MotorJoint_GetAngularDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetAngularDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetMaxSpringForce(jointId:B2JointId, maxForce:Float):Void {
		Hb.b2MotorJoint_SetMaxSpringForce(jointId.index1, jointId.world0, jointId.generation, maxForce);
	}

	public static inline function b2MotorJoint_GetMaxSpringForce(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetMaxSpringForce(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2MotorJoint_SetMaxSpringTorque(jointId:B2JointId, maxTorque:Float):Void {
		Hb.b2MotorJoint_SetMaxSpringTorque(jointId.index1, jointId.world0, jointId.generation, maxTorque);
	}

	public static inline function b2MotorJoint_GetMaxSpringTorque(jointId:B2JointId):Float {
		var result = Hb.b2MotorJoint_GetMaxSpringTorque(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2CreatePrismaticJoint(worldId:B2WorldId, def:B2PrismaticJointDef, ?out:B2JointId):B2JointId {
		var value = out == null ? new B2JointId() : out;
		Io.begin();
		wrB2PrismaticJointDef(def);
		Hb.b2CreatePrismaticJoint(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointId(value);
		if (def.base.userData != null)
			Data.set(value, def.base.userData);
		return value;
	}

	public static inline function b2PrismaticJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		Hb.b2PrismaticJoint_EnableSpring(jointId.index1, jointId.world0, jointId.generation, enableSpring ? 1 : 0);
	}

	public static inline function b2PrismaticJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2PrismaticJoint_IsSpringEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2PrismaticJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2PrismaticJoint_SetSpringHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2PrismaticJoint_GetSpringHertz(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetSpringHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		Hb.b2PrismaticJoint_SetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation, dampingRatio);
	}

	public static inline function b2PrismaticJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_SetTargetTranslation(jointId:B2JointId, translation:Float):Void {
		Hb.b2PrismaticJoint_SetTargetTranslation(jointId.index1, jointId.world0, jointId.generation, translation);
	}

	public static inline function b2PrismaticJoint_GetTargetTranslation(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetTargetTranslation(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		Hb.b2PrismaticJoint_EnableLimit(jointId.index1, jointId.world0, jointId.generation, enableLimit ? 1 : 0);
	}

	public static inline function b2PrismaticJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2PrismaticJoint_IsLimitEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2PrismaticJoint_GetLowerLimit(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetLowerLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_GetUpperLimit(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetUpperLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void {
		Hb.b2PrismaticJoint_SetLimits(jointId.index1, jointId.world0, jointId.generation, lower, upper);
	}

	public static inline function b2PrismaticJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		Hb.b2PrismaticJoint_EnableMotor(jointId.index1, jointId.world0, jointId.generation, enableMotor ? 1 : 0);
	}

	public static inline function b2PrismaticJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2PrismaticJoint_IsMotorEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2PrismaticJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		Hb.b2PrismaticJoint_SetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation, motorSpeed);
	}

	public static inline function b2PrismaticJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_SetMaxMotorForce(jointId:B2JointId, force:Float):Void {
		Hb.b2PrismaticJoint_SetMaxMotorForce(jointId.index1, jointId.world0, jointId.generation, force);
	}

	public static inline function b2PrismaticJoint_GetMaxMotorForce(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetMaxMotorForce(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_GetCurrentTranslation(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetCurrentTranslation(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_GetCurrentSpeed(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetCurrentSpeed(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2PrismaticJoint_GetCurrentMotorForce(jointId:B2JointId):Float {
		var result = Hb.b2PrismaticJoint_GetCurrentMotorForce(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2CreateRevoluteJoint(worldId:B2WorldId, def:B2RevoluteJointDef, ?out:B2JointId):B2JointId {
		var value = out == null ? new B2JointId() : out;
		Io.begin();
		wrB2RevoluteJointDef(def);
		Hb.b2CreateRevoluteJoint(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointId(value);
		if (def.base.userData != null)
			Data.set(value, def.base.userData);
		return value;
	}

	public static inline function b2RevoluteJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		Hb.b2RevoluteJoint_EnableSpring(jointId.index1, jointId.world0, jointId.generation, enableSpring ? 1 : 0);
	}

	public static inline function b2RevoluteJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2RevoluteJoint_IsSpringEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2RevoluteJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2RevoluteJoint_SetSpringHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2RevoluteJoint_GetSpringHertz(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetSpringHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		Hb.b2RevoluteJoint_SetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation, dampingRatio);
	}

	public static inline function b2RevoluteJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_SetTargetAngle(jointId:B2JointId, angle:Float):Void {
		Hb.b2RevoluteJoint_SetTargetAngle(jointId.index1, jointId.world0, jointId.generation, angle);
	}

	public static inline function b2RevoluteJoint_GetTargetAngle(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetTargetAngle(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		Hb.b2RevoluteJoint_EnableLimit(jointId.index1, jointId.world0, jointId.generation, enableLimit ? 1 : 0);
	}

	public static inline function b2RevoluteJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2RevoluteJoint_IsLimitEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2RevoluteJoint_GetLowerLimit(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetLowerLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_GetUpperLimit(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetUpperLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void {
		Hb.b2RevoluteJoint_SetLimits(jointId.index1, jointId.world0, jointId.generation, lower, upper);
	}

	public static inline function b2RevoluteJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		Hb.b2RevoluteJoint_EnableMotor(jointId.index1, jointId.world0, jointId.generation, enableMotor ? 1 : 0);
	}

	public static inline function b2RevoluteJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2RevoluteJoint_IsMotorEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2RevoluteJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		Hb.b2RevoluteJoint_SetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation, motorSpeed);
	}

	public static inline function b2RevoluteJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_SetMaxMotorTorque(jointId:B2JointId, torque:Float):Void {
		Hb.b2RevoluteJoint_SetMaxMotorTorque(jointId.index1, jointId.world0, jointId.generation, torque);
	}

	public static inline function b2RevoluteJoint_GetMaxMotorTorque(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetMaxMotorTorque(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_GetCurrentAngle(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetCurrentAngle(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_GetCurrentSpeed(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetCurrentSpeed(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2RevoluteJoint_GetCurrentMotorTorque(jointId:B2JointId):Float {
		var result = Hb.b2RevoluteJoint_GetCurrentMotorTorque(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2CreateWeldJoint(worldId:B2WorldId, def:B2WeldJointDef, ?out:B2JointId):B2JointId {
		var value = out == null ? new B2JointId() : out;
		Io.begin();
		wrB2WeldJointDef(def);
		Hb.b2CreateWeldJoint(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointId(value);
		if (def.base.userData != null)
			Data.set(value, def.base.userData);
		return value;
	}

	public static inline function b2WeldJoint_SetLinearHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2WeldJoint_SetLinearHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2WeldJoint_GetLinearHertz(jointId:B2JointId):Float {
		var result = Hb.b2WeldJoint_GetLinearHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WeldJoint_SetLinearDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		Hb.b2WeldJoint_SetLinearDampingRatio(jointId.index1, jointId.world0, jointId.generation, dampingRatio);
	}

	public static inline function b2WeldJoint_GetLinearDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2WeldJoint_GetLinearDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WeldJoint_SetAngularHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2WeldJoint_SetAngularHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2WeldJoint_GetAngularHertz(jointId:B2JointId):Float {
		var result = Hb.b2WeldJoint_GetAngularHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WeldJoint_SetAngularDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		Hb.b2WeldJoint_SetAngularDampingRatio(jointId.index1, jointId.world0, jointId.generation, dampingRatio);
	}

	public static inline function b2WeldJoint_GetAngularDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2WeldJoint_GetAngularDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2CreateWheelJoint(worldId:B2WorldId, def:B2WheelJointDef, ?out:B2JointId):B2JointId {
		var value = out == null ? new B2JointId() : out;
		Io.begin();
		wrB2WheelJointDef(def);
		Hb.b2CreateWheelJoint(worldId.index1, worldId.generation);
		Io.begin();
		rdB2JointId(value);
		if (def.base.userData != null)
			Data.set(value, def.base.userData);
		return value;
	}

	public static inline function b2WheelJoint_EnableSpring(jointId:B2JointId, enableSpring:Bool):Void {
		Hb.b2WheelJoint_EnableSpring(jointId.index1, jointId.world0, jointId.generation, enableSpring ? 1 : 0);
	}

	public static inline function b2WheelJoint_IsSpringEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2WheelJoint_IsSpringEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2WheelJoint_SetSpringHertz(jointId:B2JointId, hertz:Float):Void {
		Hb.b2WheelJoint_SetSpringHertz(jointId.index1, jointId.world0, jointId.generation, hertz);
	}

	public static inline function b2WheelJoint_GetSpringHertz(jointId:B2JointId):Float {
		var result = Hb.b2WheelJoint_GetSpringHertz(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WheelJoint_SetSpringDampingRatio(jointId:B2JointId, dampingRatio:Float):Void {
		Hb.b2WheelJoint_SetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation, dampingRatio);
	}

	public static inline function b2WheelJoint_GetSpringDampingRatio(jointId:B2JointId):Float {
		var result = Hb.b2WheelJoint_GetSpringDampingRatio(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WheelJoint_EnableLimit(jointId:B2JointId, enableLimit:Bool):Void {
		Hb.b2WheelJoint_EnableLimit(jointId.index1, jointId.world0, jointId.generation, enableLimit ? 1 : 0);
	}

	public static inline function b2WheelJoint_IsLimitEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2WheelJoint_IsLimitEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2WheelJoint_GetLowerLimit(jointId:B2JointId):Float {
		var result = Hb.b2WheelJoint_GetLowerLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WheelJoint_GetUpperLimit(jointId:B2JointId):Float {
		var result = Hb.b2WheelJoint_GetUpperLimit(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WheelJoint_SetLimits(jointId:B2JointId, lower:Float, upper:Float):Void {
		Hb.b2WheelJoint_SetLimits(jointId.index1, jointId.world0, jointId.generation, lower, upper);
	}

	public static inline function b2WheelJoint_EnableMotor(jointId:B2JointId, enableMotor:Bool):Void {
		Hb.b2WheelJoint_EnableMotor(jointId.index1, jointId.world0, jointId.generation, enableMotor ? 1 : 0);
	}

	public static inline function b2WheelJoint_IsMotorEnabled(jointId:B2JointId):Bool {
		var result = Hb.b2WheelJoint_IsMotorEnabled(jointId.index1, jointId.world0, jointId.generation);
		return result != 0;
	}

	public static inline function b2WheelJoint_SetTargetMotorSpeed(jointId:B2JointId, motorSpeed:Float):Void {
		Hb.b2WheelJoint_SetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation, motorSpeed);
	}

	public static inline function b2WheelJoint_GetTargetMotorSpeed(jointId:B2JointId):Float {
		var result = Hb.b2WheelJoint_GetTargetMotorSpeed(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WheelJoint_SetMaxMotorTorque(jointId:B2JointId, torque:Float):Void {
		Hb.b2WheelJoint_SetMaxMotorTorque(jointId.index1, jointId.world0, jointId.generation, torque);
	}

	public static inline function b2WheelJoint_GetMaxMotorTorque(jointId:B2JointId):Float {
		var result = Hb.b2WheelJoint_GetMaxMotorTorque(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2WheelJoint_GetCurrentMotorTorque(jointId:B2JointId):Float {
		var result = Hb.b2WheelJoint_GetCurrentMotorTorque(jointId.index1, jointId.world0, jointId.generation);
		return result;
	}

	public static inline function b2Contact_IsValid(id:B2ContactId):Bool {
		var result = Hb.b2Contact_IsValid(id.index1, id.world0, id.padding, id.generation);
		return result != 0;
	}

	public static inline function b2Contact_GetData(contactId:B2ContactId, ?out:B2ContactData):B2ContactData {
		var value = out == null ? new B2ContactData() : out;
		Hb.b2Contact_GetData(contactId.index1, contactId.world0, contactId.padding, contactId.generation);
		Io.begin();
		rdB2ContactData(value);
		return value;
	}

	public static function rdB2AABB(v:B2AABB):B2AABB {
		Io.rv(v.lowerBound);
		Io.rv(v.upperBound);
		return v;
	}

	public static function wrB2AABB(v:B2AABB):Void {
		Io.wv(v.lowerBound);
		Io.wv(v.upperBound);
	}

	public static function rdB2BodyDef(v:B2BodyDef):B2BodyDef {
		v.type = cast Io.ri();
		Io.rv(v.position);
		rdB2Rot(v.rotation);
		Io.rv(v.linearVelocity);
		v.angularVelocity = Io.rf();
		v.linearDamping = Io.rf();
		v.angularDamping = Io.rf();
		v.gravityScale = Io.rf();
		v.sleepThreshold = Io.rf();
		v.safetyFactor = Io.rf();
		v.name = Io.rs();
		Io.ri();
		v.userData = null;
		rdB2MotionLocks(v.motionLocks);
		v.enableSleep = Io.rb();
		v.isAwake = Io.rb();
		v.isBullet = Io.rb();
		v.isEnabled = Io.rb();
		v.allowFastRotation = Io.rb();
		v.enableContactRecycling = Io.rb();
		return v;
	}

	public static function wrB2BodyDef(v:B2BodyDef):Void {
		Io.wi(v.type);
		Io.wv(v.position);
		wrB2Rot(v.rotation);
		Io.wv(v.linearVelocity);
		Io.wf(v.angularVelocity);
		Io.wf(v.linearDamping);
		Io.wf(v.angularDamping);
		Io.wf(v.gravityScale);
		Io.wf(v.sleepThreshold);
		Io.wf(v.safetyFactor);
		Io.ws(v.name);
		Io.wi(0);
		wrB2MotionLocks(v.motionLocks);
		Io.wb(v.enableSleep);
		Io.wb(v.isAwake);
		Io.wb(v.isBullet);
		Io.wb(v.isEnabled);
		Io.wb(v.allowFastRotation);
		Io.wb(v.enableContactRecycling);
	}

	public static function rdB2BodyEvents(v:B2BodyEvents):B2BodyEvents {
		{
			var count = Io.ri();
			if (v.moveEvents == null)
				v.moveEvents = [];
			var a = v.moveEvents;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2BodyMoveEvent());
				rdB2BodyMoveEvent(a[k]);
			}
		}
		v.moveCount = Io.ri();
		return v;
	}

	public static function wrB2BodyEvents(v:B2BodyEvents):Void {
		Io.wi(v.moveCount);
		for (k in 0...v.moveCount)
			wrB2BodyMoveEvent(v.moveEvents[k]);
		Io.wi(v.moveCount);
	}

	public static function rdB2BodyId(v:B2BodyId):B2BodyId {
		v.index1 = Io.ri();
		v.world0 = Io.ri();
		v.generation = Io.ri();
		return v;
	}

	public static function wrB2BodyId(v:B2BodyId):Void {
		Io.wi(v.index1);
		Io.wi(v.world0);
		Io.wi(v.generation);
	}

	public static function rdB2BodyMoveEvent(v:B2BodyMoveEvent):B2BodyMoveEvent {
		Io.ri();
		v.userData = null;
		rdB2Transform(v.transform);
		rdB2BodyId(v.bodyId);
		v.fellAsleep = Io.rb();
		v.userData = Data.get(v.bodyId);
		return v;
	}

	public static function wrB2BodyMoveEvent(v:B2BodyMoveEvent):Void {
		Io.wi(0);
		wrB2Transform(v.transform);
		wrB2BodyId(v.bodyId);
		Io.wb(v.fellAsleep);
	}

	public static function rdB2Capacity(v:B2Capacity):B2Capacity {
		v.staticShapeCount = Io.ri();
		v.dynamicShapeCount = Io.ri();
		v.staticBodyCount = Io.ri();
		v.dynamicBodyCount = Io.ri();
		v.contactCount = Io.ri();
		v.arenaByteCount = Io.ri();
		return v;
	}

	public static function wrB2Capacity(v:B2Capacity):Void {
		Io.wi(v.staticShapeCount);
		Io.wi(v.dynamicShapeCount);
		Io.wi(v.staticBodyCount);
		Io.wi(v.dynamicBodyCount);
		Io.wi(v.contactCount);
		Io.wi(v.arenaByteCount);
	}

	public static function rdB2Capsule(v:B2Capsule):B2Capsule {
		Io.rv(v.center1);
		Io.rv(v.center2);
		v.radius = Io.rf();
		return v;
	}

	public static function wrB2Capsule(v:B2Capsule):Void {
		Io.wv(v.center1);
		Io.wv(v.center2);
		Io.wf(v.radius);
	}

	public static function rdB2CastOutput(v:B2CastOutput):B2CastOutput {
		Io.rv(v.normal);
		Io.rv(v.point);
		v.fraction = Io.rf();
		v.iterations = Io.ri();
		v.hit = Io.rb();
		return v;
	}

	public static function wrB2CastOutput(v:B2CastOutput):Void {
		Io.wv(v.normal);
		Io.wv(v.point);
		Io.wf(v.fraction);
		Io.wi(v.iterations);
		Io.wb(v.hit);
	}

	public static function rdB2ChainDef(v:B2ChainDef):B2ChainDef {
		Io.ri();
		v.userData = null;
		{
			var count = Io.ri();
			if (v.points == null)
				v.points = [];
			var a = v.points;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(new B2Vec2());
				Io.rv(a[k]);
			}
		}
		v.pointCount = Io.ri();
		Io.rv(v.ghost1);
		Io.rv(v.ghost2);
		{
			var count = Io.ri();
			if (v.materials == null)
				v.materials = [];
			var a = v.materials;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2SurfaceMaterial());
				rdB2SurfaceMaterial(a[k]);
			}
		}
		v.materialCount = Io.ri();
		rdB2Filter(v.filter);
		v.isLoop = Io.rb();
		v.enableSensorEvents = Io.rb();
		return v;
	}

	public static function wrB2ChainDef(v:B2ChainDef):Void {
		Io.wi(0);
		Io.wi(v.pointCount);
		for (k in 0...v.pointCount)
			Io.wv(v.points[k]);
		Io.wi(v.pointCount);
		Io.wv(v.ghost1);
		Io.wv(v.ghost2);
		Io.wi(v.materialCount);
		for (k in 0...v.materialCount)
			wrB2SurfaceMaterial(v.materials[k]);
		Io.wi(v.materialCount);
		wrB2Filter(v.filter);
		Io.wb(v.isLoop);
		Io.wb(v.enableSensorEvents);
	}

	public static function rdB2ChainId(v:B2ChainId):B2ChainId {
		v.index1 = Io.ri();
		v.world0 = Io.ri();
		v.generation = Io.ri();
		return v;
	}

	public static function wrB2ChainId(v:B2ChainId):Void {
		Io.wi(v.index1);
		Io.wi(v.world0);
		Io.wi(v.generation);
	}

	public static function rdB2ChainSegment(v:B2ChainSegment):B2ChainSegment {
		Io.rv(v.ghost1);
		rdB2Segment(v.segment);
		Io.rv(v.ghost2);
		v.chainId = Io.ri();
		return v;
	}

	public static function wrB2ChainSegment(v:B2ChainSegment):Void {
		Io.wv(v.ghost1);
		wrB2Segment(v.segment);
		Io.wv(v.ghost2);
		Io.wi(v.chainId);
	}

	public static function rdB2Circle(v:B2Circle):B2Circle {
		Io.rv(v.center);
		v.radius = Io.rf();
		return v;
	}

	public static function wrB2Circle(v:B2Circle):Void {
		Io.wv(v.center);
		Io.wf(v.radius);
	}

	public static function rdB2ContactBeginTouchEvent(v:B2ContactBeginTouchEvent):B2ContactBeginTouchEvent {
		rdB2ShapeId(v.shapeIdA);
		rdB2ShapeId(v.shapeIdB);
		rdB2ContactId(v.contactId);
		return v;
	}

	public static function wrB2ContactBeginTouchEvent(v:B2ContactBeginTouchEvent):Void {
		wrB2ShapeId(v.shapeIdA);
		wrB2ShapeId(v.shapeIdB);
		wrB2ContactId(v.contactId);
	}

	public static function rdB2ContactData(v:B2ContactData):B2ContactData {
		rdB2ContactId(v.contactId);
		rdB2ShapeId(v.shapeIdA);
		rdB2ShapeId(v.shapeIdB);
		rdB2Manifold(v.manifold);
		return v;
	}

	public static function wrB2ContactData(v:B2ContactData):Void {
		wrB2ContactId(v.contactId);
		wrB2ShapeId(v.shapeIdA);
		wrB2ShapeId(v.shapeIdB);
		wrB2Manifold(v.manifold);
	}

	public static function rdB2ContactEndTouchEvent(v:B2ContactEndTouchEvent):B2ContactEndTouchEvent {
		rdB2ShapeId(v.shapeIdA);
		rdB2ShapeId(v.shapeIdB);
		rdB2ContactId(v.contactId);
		return v;
	}

	public static function wrB2ContactEndTouchEvent(v:B2ContactEndTouchEvent):Void {
		wrB2ShapeId(v.shapeIdA);
		wrB2ShapeId(v.shapeIdB);
		wrB2ContactId(v.contactId);
	}

	public static function rdB2ContactEvents(v:B2ContactEvents):B2ContactEvents {
		{
			var count = Io.ri();
			if (v.beginEvents == null)
				v.beginEvents = [];
			var a = v.beginEvents;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2ContactBeginTouchEvent());
				rdB2ContactBeginTouchEvent(a[k]);
			}
		}
		{
			var count = Io.ri();
			if (v.endEvents == null)
				v.endEvents = [];
			var a = v.endEvents;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2ContactEndTouchEvent());
				rdB2ContactEndTouchEvent(a[k]);
			}
		}
		{
			var count = Io.ri();
			if (v.hitEvents == null)
				v.hitEvents = [];
			var a = v.hitEvents;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2ContactHitEvent());
				rdB2ContactHitEvent(a[k]);
			}
		}
		v.beginCount = Io.ri();
		v.endCount = Io.ri();
		v.hitCount = Io.ri();
		return v;
	}

	public static function wrB2ContactEvents(v:B2ContactEvents):Void {
		Io.wi(v.beginCount);
		for (k in 0...v.beginCount)
			wrB2ContactBeginTouchEvent(v.beginEvents[k]);
		Io.wi(v.endCount);
		for (k in 0...v.endCount)
			wrB2ContactEndTouchEvent(v.endEvents[k]);
		Io.wi(v.hitCount);
		for (k in 0...v.hitCount)
			wrB2ContactHitEvent(v.hitEvents[k]);
		Io.wi(v.beginCount);
		Io.wi(v.endCount);
		Io.wi(v.hitCount);
	}

	public static function rdB2ContactHitEvent(v:B2ContactHitEvent):B2ContactHitEvent {
		rdB2ShapeId(v.shapeIdA);
		rdB2ShapeId(v.shapeIdB);
		rdB2ContactId(v.contactId);
		Io.rv(v.point);
		Io.rv(v.normal);
		v.approachSpeed = Io.rf();
		return v;
	}

	public static function wrB2ContactHitEvent(v:B2ContactHitEvent):Void {
		wrB2ShapeId(v.shapeIdA);
		wrB2ShapeId(v.shapeIdB);
		wrB2ContactId(v.contactId);
		Io.wv(v.point);
		Io.wv(v.normal);
		Io.wf(v.approachSpeed);
	}

	public static function rdB2ContactId(v:B2ContactId):B2ContactId {
		v.index1 = Io.ri();
		v.world0 = Io.ri();
		v.padding = Io.ri();
		v.generation = Io.ri();
		return v;
	}

	public static function wrB2ContactId(v:B2ContactId):Void {
		Io.wi(v.index1);
		Io.wi(v.world0);
		Io.wi(v.padding);
		Io.wi(v.generation);
	}

	public static function rdB2CosSin(v:B2CosSin):B2CosSin {
		v.cosine = Io.rf();
		v.sine = Io.rf();
		return v;
	}

	public static function wrB2CosSin(v:B2CosSin):Void {
		Io.wf(v.cosine);
		Io.wf(v.sine);
	}

	public static function rdB2Counters(v:B2Counters):B2Counters {
		v.byteCount = Io.ri();
		v.bodyCount = Io.ri();
		v.shapeCount = Io.ri();
		v.contactCount = Io.ri();
		v.jointCount = Io.ri();
		v.islandCount = Io.ri();
		v.stackUsed = Io.ri();
		v.staticTreeHeight = Io.ri();
		v.treeHeight = Io.ri();
		v.taskCount = Io.ri();
		for (k in 0...24)
			v.colorCounts[k] = Io.ri();
		v.awakeContactCount = Io.ri();
		v.recycledContactCount = Io.ri();
		return v;
	}

	public static function wrB2Counters(v:B2Counters):Void {
		Io.wi(v.byteCount);
		Io.wi(v.bodyCount);
		Io.wi(v.shapeCount);
		Io.wi(v.contactCount);
		Io.wi(v.jointCount);
		Io.wi(v.islandCount);
		Io.wi(v.stackUsed);
		Io.wi(v.staticTreeHeight);
		Io.wi(v.treeHeight);
		Io.wi(v.taskCount);
		for (k in 0...24)
			Io.wi(v.colorCounts[k]);
		Io.wi(v.awakeContactCount);
		Io.wi(v.recycledContactCount);
	}

	public static function rdB2DebugDraw(v:B2DebugDraw):B2DebugDraw {
		Io.ri();
		Io.ri();
		Io.ri();
		Io.ri();
		Io.ri();
		Io.ri();
		Io.ri();
		Io.ri();
		Io.ri();
		Io.ri();
		rdB2AABB(v.drawingBounds);
		v.forceScale = Io.rf();
		v.jointScale = Io.rf();
		v.drawContacts = Io.rb();
		v.drawAnchorA = Io.rb();
		v.drawShapes = Io.rb();
		v.drawChainNormals = Io.rb();
		v.drawJoints = Io.rb();
		v.drawJointExtras = Io.rb();
		v.drawBounds = Io.rb();
		v.drawMass = Io.rb();
		v.drawBodyNames = Io.rb();
		v.drawGraphColors = Io.rb();
		v.drawContactFeatures = Io.rb();
		v.drawContactNormals = Io.rb();
		v.drawContactForces = Io.rb();
		v.drawFrictionForces = Io.rb();
		v.drawIslands = Io.rb();
		Io.ri();
		v.context = null;
		return v;
	}

	public static function wrB2DebugDraw(v:B2DebugDraw):Void {
		Io.wb(v.DrawPolygonFcn != null);
		Io.wb(v.DrawSolidPolygonFcn != null);
		Io.wb(v.DrawCircleFcn != null);
		Io.wb(v.DrawSolidCircleFcn != null);
		Io.wb(v.DrawSolidCapsuleFcn != null);
		Io.wb(v.DrawLineFcn != null);
		Io.wb(v.DrawTransformFcn != null);
		Io.wb(v.DrawPointFcn != null);
		Io.wb(v.DrawStringFcn != null);
		Io.wb(v.DrawBoundsFcn != null);
		wrB2AABB(v.drawingBounds);
		Io.wf(v.forceScale);
		Io.wf(v.jointScale);
		Io.wb(v.drawContacts);
		Io.wb(v.drawAnchorA);
		Io.wb(v.drawShapes);
		Io.wb(v.drawChainNormals);
		Io.wb(v.drawJoints);
		Io.wb(v.drawJointExtras);
		Io.wb(v.drawBounds);
		Io.wb(v.drawMass);
		Io.wb(v.drawBodyNames);
		Io.wb(v.drawGraphColors);
		Io.wb(v.drawContactFeatures);
		Io.wb(v.drawContactNormals);
		Io.wb(v.drawContactForces);
		Io.wb(v.drawFrictionForces);
		Io.wb(v.drawIslands);
		Io.wi(0);
	}

	public static function rdB2DistanceInput(v:B2DistanceInput):B2DistanceInput {
		rdB2ShapeProxy(v.proxyA);
		rdB2ShapeProxy(v.proxyB);
		rdB2Transform(v.transform);
		v.useRadii = Io.rb();
		return v;
	}

	public static function wrB2DistanceInput(v:B2DistanceInput):Void {
		wrB2ShapeProxy(v.proxyA);
		wrB2ShapeProxy(v.proxyB);
		wrB2Transform(v.transform);
		Io.wb(v.useRadii);
	}

	public static function rdB2DistanceJointDef(v:B2DistanceJointDef):B2DistanceJointDef {
		rdB2JointDef(v.base);
		v.length = Io.rf();
		v.enableSpring = Io.rb();
		v.lowerSpringForce = Io.rf();
		v.upperSpringForce = Io.rf();
		v.hertz = Io.rf();
		v.dampingRatio = Io.rf();
		v.enableLimit = Io.rb();
		v.minLength = Io.rf();
		v.maxLength = Io.rf();
		v.enableMotor = Io.rb();
		v.maxMotorForce = Io.rf();
		v.motorSpeed = Io.rf();
		return v;
	}

	public static function wrB2DistanceJointDef(v:B2DistanceJointDef):Void {
		wrB2JointDef(v.base);
		Io.wf(v.length);
		Io.wb(v.enableSpring);
		Io.wf(v.lowerSpringForce);
		Io.wf(v.upperSpringForce);
		Io.wf(v.hertz);
		Io.wf(v.dampingRatio);
		Io.wb(v.enableLimit);
		Io.wf(v.minLength);
		Io.wf(v.maxLength);
		Io.wb(v.enableMotor);
		Io.wf(v.maxMotorForce);
		Io.wf(v.motorSpeed);
	}

	public static function rdB2DistanceOutput(v:B2DistanceOutput):B2DistanceOutput {
		Io.rv(v.pointA);
		Io.rv(v.pointB);
		Io.rv(v.normal);
		v.distance = Io.rf();
		v.iterations = Io.ri();
		v.simplexCount = Io.ri();
		return v;
	}

	public static function wrB2DistanceOutput(v:B2DistanceOutput):Void {
		Io.wv(v.pointA);
		Io.wv(v.pointB);
		Io.wv(v.normal);
		Io.wf(v.distance);
		Io.wi(v.iterations);
		Io.wi(v.simplexCount);
	}

	public static function rdB2ExplosionDef(v:B2ExplosionDef):B2ExplosionDef {
		v.maskBits = Io.rl();
		Io.rv(v.position);
		v.radius = Io.rf();
		v.falloff = Io.rf();
		v.impulsePerLength = Io.rf();
		return v;
	}

	public static function wrB2ExplosionDef(v:B2ExplosionDef):Void {
		Io.wl(v.maskBits);
		Io.wv(v.position);
		Io.wf(v.radius);
		Io.wf(v.falloff);
		Io.wf(v.impulsePerLength);
	}

	public static function rdB2Filter(v:B2Filter):B2Filter {
		v.categoryBits = Io.rl();
		v.maskBits = Io.rl();
		v.groupIndex = Io.ri();
		return v;
	}

	public static function wrB2Filter(v:B2Filter):Void {
		Io.wl(v.categoryBits);
		Io.wl(v.maskBits);
		Io.wi(v.groupIndex);
	}

	public static function rdB2FilterJointDef(v:B2FilterJointDef):B2FilterJointDef {
		rdB2JointDef(v.base);
		return v;
	}

	public static function wrB2FilterJointDef(v:B2FilterJointDef):Void {
		wrB2JointDef(v.base);
	}

	public static function rdB2Hull(v:B2Hull):B2Hull {
		for (k in 0...8)
			Io.rv(v.points[k]);
		v.count = Io.ri();
		return v;
	}

	public static function wrB2Hull(v:B2Hull):Void {
		for (k in 0...8)
			Io.wv(v.points[k]);
		Io.wi(v.count);
	}

	public static function rdB2JointDef(v:B2JointDef):B2JointDef {
		Io.ri();
		v.userData = null;
		rdB2BodyId(v.bodyIdA);
		rdB2BodyId(v.bodyIdB);
		rdB2Transform(v.localFrameA);
		rdB2Transform(v.localFrameB);
		v.forceThreshold = Io.rf();
		v.torqueThreshold = Io.rf();
		v.constraintHertz = Io.rf();
		v.constraintDampingRatio = Io.rf();
		v.drawScale = Io.rf();
		v.collideConnected = Io.rb();
		return v;
	}

	public static function wrB2JointDef(v:B2JointDef):Void {
		Io.wi(0);
		wrB2BodyId(v.bodyIdA);
		wrB2BodyId(v.bodyIdB);
		wrB2Transform(v.localFrameA);
		wrB2Transform(v.localFrameB);
		Io.wf(v.forceThreshold);
		Io.wf(v.torqueThreshold);
		Io.wf(v.constraintHertz);
		Io.wf(v.constraintDampingRatio);
		Io.wf(v.drawScale);
		Io.wb(v.collideConnected);
	}

	public static function rdB2JointEvent(v:B2JointEvent):B2JointEvent {
		rdB2JointId(v.jointId);
		Io.ri();
		v.userData = null;
		return v;
	}

	public static function wrB2JointEvent(v:B2JointEvent):Void {
		wrB2JointId(v.jointId);
		Io.wi(0);
	}

	public static function rdB2JointEvents(v:B2JointEvents):B2JointEvents {
		{
			var count = Io.ri();
			if (v.jointEvents == null)
				v.jointEvents = [];
			var a = v.jointEvents;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2JointEvent());
				rdB2JointEvent(a[k]);
			}
		}
		v.count = Io.ri();
		return v;
	}

	public static function wrB2JointEvents(v:B2JointEvents):Void {
		Io.wi(v.count);
		for (k in 0...v.count)
			wrB2JointEvent(v.jointEvents[k]);
		Io.wi(v.count);
	}

	public static function rdB2JointId(v:B2JointId):B2JointId {
		v.index1 = Io.ri();
		v.world0 = Io.ri();
		v.generation = Io.ri();
		return v;
	}

	public static function wrB2JointId(v:B2JointId):Void {
		Io.wi(v.index1);
		Io.wi(v.world0);
		Io.wi(v.generation);
	}

	public static function rdB2LocalManifold(v:B2LocalManifold):B2LocalManifold {
		Io.rv(v.normal);
		for (k in 0...2)
			rdB2LocalManifoldPoint(v.points[k]);
		v.pointCount = Io.ri();
		return v;
	}

	public static function wrB2LocalManifold(v:B2LocalManifold):Void {
		Io.wv(v.normal);
		for (k in 0...2)
			wrB2LocalManifoldPoint(v.points[k]);
		Io.wi(v.pointCount);
	}

	public static function rdB2LocalManifoldPoint(v:B2LocalManifoldPoint):B2LocalManifoldPoint {
		Io.rv(v.point);
		v.separation = Io.rf();
		v.id = Io.ri();
		return v;
	}

	public static function wrB2LocalManifoldPoint(v:B2LocalManifoldPoint):Void {
		Io.wv(v.point);
		Io.wf(v.separation);
		Io.wi(v.id);
	}

	public static function rdB2Manifold(v:B2Manifold):B2Manifold {
		Io.rv(v.normal);
		v.rollingImpulse = Io.rf();
		for (k in 0...2)
			rdB2ManifoldPoint(v.points[k]);
		v.pointCount = Io.ri();
		return v;
	}

	public static function wrB2Manifold(v:B2Manifold):Void {
		Io.wv(v.normal);
		Io.wf(v.rollingImpulse);
		for (k in 0...2)
			wrB2ManifoldPoint(v.points[k]);
		Io.wi(v.pointCount);
	}

	public static function rdB2ManifoldPoint(v:B2ManifoldPoint):B2ManifoldPoint {
		Io.rv(v.anchorA);
		Io.rv(v.anchorB);
		v.separation = Io.rf();
		v.normalImpulse = Io.rf();
		v.tangentImpulse = Io.rf();
		v.totalNormalImpulse = Io.rf();
		v.normalVelocity = Io.rf();
		v.baseSeparation = Io.rf();
		v.id = Io.ri();
		v.persisted = Io.rb();
		return v;
	}

	public static function wrB2ManifoldPoint(v:B2ManifoldPoint):Void {
		Io.wv(v.anchorA);
		Io.wv(v.anchorB);
		Io.wf(v.separation);
		Io.wf(v.normalImpulse);
		Io.wf(v.tangentImpulse);
		Io.wf(v.totalNormalImpulse);
		Io.wf(v.normalVelocity);
		Io.wf(v.baseSeparation);
		Io.wi(v.id);
		Io.wb(v.persisted);
	}

	public static function rdB2MassData(v:B2MassData):B2MassData {
		v.mass = Io.rf();
		Io.rv(v.center);
		v.rotationalInertia = Io.rf();
		return v;
	}

	public static function wrB2MassData(v:B2MassData):Void {
		Io.wf(v.mass);
		Io.wv(v.center);
		Io.wf(v.rotationalInertia);
	}

	public static function rdB2Mat22(v:B2Mat22):B2Mat22 {
		Io.rv(v.cx);
		Io.rv(v.cy);
		return v;
	}

	public static function wrB2Mat22(v:B2Mat22):Void {
		Io.wv(v.cx);
		Io.wv(v.cy);
	}

	public static function rdB2MotionLocks(v:B2MotionLocks):B2MotionLocks {
		v.linearX = Io.rb();
		v.linearY = Io.rb();
		v.angularZ = Io.rb();
		return v;
	}

	public static function wrB2MotionLocks(v:B2MotionLocks):Void {
		Io.wb(v.linearX);
		Io.wb(v.linearY);
		Io.wb(v.angularZ);
	}

	public static function rdB2MotorJointDef(v:B2MotorJointDef):B2MotorJointDef {
		rdB2JointDef(v.base);
		Io.rv(v.linearVelocity);
		v.maxVelocityForce = Io.rf();
		v.angularVelocity = Io.rf();
		v.maxVelocityTorque = Io.rf();
		v.linearHertz = Io.rf();
		v.linearDampingRatio = Io.rf();
		v.maxSpringForce = Io.rf();
		v.angularHertz = Io.rf();
		v.angularDampingRatio = Io.rf();
		v.maxSpringTorque = Io.rf();
		return v;
	}

	public static function wrB2MotorJointDef(v:B2MotorJointDef):Void {
		wrB2JointDef(v.base);
		Io.wv(v.linearVelocity);
		Io.wf(v.maxVelocityForce);
		Io.wf(v.angularVelocity);
		Io.wf(v.maxVelocityTorque);
		Io.wf(v.linearHertz);
		Io.wf(v.linearDampingRatio);
		Io.wf(v.maxSpringForce);
		Io.wf(v.angularHertz);
		Io.wf(v.angularDampingRatio);
		Io.wf(v.maxSpringTorque);
	}

	public static function rdB2Plane(v:B2Plane):B2Plane {
		Io.rv(v.normal);
		v.offset = Io.rf();
		return v;
	}

	public static function wrB2Plane(v:B2Plane):Void {
		Io.wv(v.normal);
		Io.wf(v.offset);
	}

	public static function rdB2Polygon(v:B2Polygon):B2Polygon {
		for (k in 0...8)
			Io.rv(v.vertices[k]);
		for (k in 0...8)
			Io.rv(v.normals[k]);
		Io.rv(v.centroid);
		v.radius = Io.rf();
		v.count = Io.ri();
		return v;
	}

	public static function wrB2Polygon(v:B2Polygon):Void {
		for (k in 0...8)
			Io.wv(v.vertices[k]);
		for (k in 0...8)
			Io.wv(v.normals[k]);
		Io.wv(v.centroid);
		Io.wf(v.radius);
		Io.wi(v.count);
	}

	public static function rdB2PrismaticJointDef(v:B2PrismaticJointDef):B2PrismaticJointDef {
		rdB2JointDef(v.base);
		v.enableSpring = Io.rb();
		v.hertz = Io.rf();
		v.dampingRatio = Io.rf();
		v.targetTranslation = Io.rf();
		v.enableLimit = Io.rb();
		v.lowerTranslation = Io.rf();
		v.upperTranslation = Io.rf();
		v.enableMotor = Io.rb();
		v.maxMotorForce = Io.rf();
		v.motorSpeed = Io.rf();
		return v;
	}

	public static function wrB2PrismaticJointDef(v:B2PrismaticJointDef):Void {
		wrB2JointDef(v.base);
		Io.wb(v.enableSpring);
		Io.wf(v.hertz);
		Io.wf(v.dampingRatio);
		Io.wf(v.targetTranslation);
		Io.wb(v.enableLimit);
		Io.wf(v.lowerTranslation);
		Io.wf(v.upperTranslation);
		Io.wb(v.enableMotor);
		Io.wf(v.maxMotorForce);
		Io.wf(v.motorSpeed);
	}

	public static function rdB2Profile(v:B2Profile):B2Profile {
		v.step = Io.rf();
		v.pairs = Io.rf();
		v.collide = Io.rf();
		v.solve = Io.rf();
		v.solverSetup = Io.rf();
		v.constraints = Io.rf();
		v.prepareConstraints = Io.rf();
		v.integrateVelocities = Io.rf();
		v.warmStart = Io.rf();
		v.solveImpulses = Io.rf();
		v.integratePositions = Io.rf();
		v.relaxImpulses = Io.rf();
		v.restitution = Io.rf();
		v.storeImpulses = Io.rf();
		v.splitIslands = Io.rf();
		v.transforms = Io.rf();
		v.sensorHits = Io.rf();
		v.jointEvents = Io.rf();
		v.hitEvents = Io.rf();
		v.refit = Io.rf();
		v.bullets = Io.rf();
		v.sleepIslands = Io.rf();
		v.sensors = Io.rf();
		return v;
	}

	public static function wrB2Profile(v:B2Profile):Void {
		Io.wf(v.step);
		Io.wf(v.pairs);
		Io.wf(v.collide);
		Io.wf(v.solve);
		Io.wf(v.solverSetup);
		Io.wf(v.constraints);
		Io.wf(v.prepareConstraints);
		Io.wf(v.integrateVelocities);
		Io.wf(v.warmStart);
		Io.wf(v.solveImpulses);
		Io.wf(v.integratePositions);
		Io.wf(v.relaxImpulses);
		Io.wf(v.restitution);
		Io.wf(v.storeImpulses);
		Io.wf(v.splitIslands);
		Io.wf(v.transforms);
		Io.wf(v.sensorHits);
		Io.wf(v.jointEvents);
		Io.wf(v.hitEvents);
		Io.wf(v.refit);
		Io.wf(v.bullets);
		Io.wf(v.sleepIslands);
		Io.wf(v.sensors);
	}

	public static function rdB2QueryFilter(v:B2QueryFilter):B2QueryFilter {
		v.categoryBits = Io.rl();
		v.maskBits = Io.rl();
		return v;
	}

	public static function wrB2QueryFilter(v:B2QueryFilter):Void {
		Io.wl(v.categoryBits);
		Io.wl(v.maskBits);
	}

	public static function rdB2RayCastInput(v:B2RayCastInput):B2RayCastInput {
		Io.rv(v.origin);
		Io.rv(v.translation);
		v.maxFraction = Io.rf();
		return v;
	}

	public static function wrB2RayCastInput(v:B2RayCastInput):Void {
		Io.wv(v.origin);
		Io.wv(v.translation);
		Io.wf(v.maxFraction);
	}

	public static function rdB2RayResult(v:B2RayResult):B2RayResult {
		rdB2ShapeId(v.shapeId);
		Io.rv(v.point);
		Io.rv(v.normal);
		v.fraction = Io.rf();
		v.nodeVisits = Io.ri();
		v.leafVisits = Io.ri();
		v.hit = Io.rb();
		return v;
	}

	public static function wrB2RayResult(v:B2RayResult):Void {
		wrB2ShapeId(v.shapeId);
		Io.wv(v.point);
		Io.wv(v.normal);
		Io.wf(v.fraction);
		Io.wi(v.nodeVisits);
		Io.wi(v.leafVisits);
		Io.wb(v.hit);
	}

	public static function rdB2RevoluteJointDef(v:B2RevoluteJointDef):B2RevoluteJointDef {
		rdB2JointDef(v.base);
		v.targetAngle = Io.rf();
		v.enableSpring = Io.rb();
		v.hertz = Io.rf();
		v.dampingRatio = Io.rf();
		v.enableLimit = Io.rb();
		v.lowerAngle = Io.rf();
		v.upperAngle = Io.rf();
		v.enableMotor = Io.rb();
		v.maxMotorTorque = Io.rf();
		v.motorSpeed = Io.rf();
		return v;
	}

	public static function wrB2RevoluteJointDef(v:B2RevoluteJointDef):Void {
		wrB2JointDef(v.base);
		Io.wf(v.targetAngle);
		Io.wb(v.enableSpring);
		Io.wf(v.hertz);
		Io.wf(v.dampingRatio);
		Io.wb(v.enableLimit);
		Io.wf(v.lowerAngle);
		Io.wf(v.upperAngle);
		Io.wb(v.enableMotor);
		Io.wf(v.maxMotorTorque);
		Io.wf(v.motorSpeed);
	}

	public static function rdB2Rot(v:B2Rot):B2Rot {
		v.c = Io.rf();
		v.s = Io.rf();
		return v;
	}

	public static function wrB2Rot(v:B2Rot):Void {
		Io.wf(v.c);
		Io.wf(v.s);
	}

	public static function rdB2Segment(v:B2Segment):B2Segment {
		Io.rv(v.point1);
		Io.rv(v.point2);
		return v;
	}

	public static function wrB2Segment(v:B2Segment):Void {
		Io.wv(v.point1);
		Io.wv(v.point2);
	}

	public static function rdB2SegmentDistanceResult(v:B2SegmentDistanceResult):B2SegmentDistanceResult {
		Io.rv(v.closest1);
		Io.rv(v.closest2);
		v.fraction1 = Io.rf();
		v.fraction2 = Io.rf();
		v.distanceSquared = Io.rf();
		return v;
	}

	public static function wrB2SegmentDistanceResult(v:B2SegmentDistanceResult):Void {
		Io.wv(v.closest1);
		Io.wv(v.closest2);
		Io.wf(v.fraction1);
		Io.wf(v.fraction2);
		Io.wf(v.distanceSquared);
	}

	public static function rdB2SensorBeginTouchEvent(v:B2SensorBeginTouchEvent):B2SensorBeginTouchEvent {
		rdB2ShapeId(v.sensorShapeId);
		rdB2ShapeId(v.visitorShapeId);
		return v;
	}

	public static function wrB2SensorBeginTouchEvent(v:B2SensorBeginTouchEvent):Void {
		wrB2ShapeId(v.sensorShapeId);
		wrB2ShapeId(v.visitorShapeId);
	}

	public static function rdB2SensorEndTouchEvent(v:B2SensorEndTouchEvent):B2SensorEndTouchEvent {
		rdB2ShapeId(v.sensorShapeId);
		rdB2ShapeId(v.visitorShapeId);
		return v;
	}

	public static function wrB2SensorEndTouchEvent(v:B2SensorEndTouchEvent):Void {
		wrB2ShapeId(v.sensorShapeId);
		wrB2ShapeId(v.visitorShapeId);
	}

	public static function rdB2SensorEvents(v:B2SensorEvents):B2SensorEvents {
		{
			var count = Io.ri();
			if (v.beginEvents == null)
				v.beginEvents = [];
			var a = v.beginEvents;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2SensorBeginTouchEvent());
				rdB2SensorBeginTouchEvent(a[k]);
			}
		}
		{
			var count = Io.ri();
			if (v.endEvents == null)
				v.endEvents = [];
			var a = v.endEvents;
			for (k in 0...count) {
				if (k >= a.length)
					a.push(Init.makeB2SensorEndTouchEvent());
				rdB2SensorEndTouchEvent(a[k]);
			}
		}
		v.beginCount = Io.ri();
		v.endCount = Io.ri();
		return v;
	}

	public static function wrB2SensorEvents(v:B2SensorEvents):Void {
		Io.wi(v.beginCount);
		for (k in 0...v.beginCount)
			wrB2SensorBeginTouchEvent(v.beginEvents[k]);
		Io.wi(v.endCount);
		for (k in 0...v.endCount)
			wrB2SensorEndTouchEvent(v.endEvents[k]);
		Io.wi(v.beginCount);
		Io.wi(v.endCount);
	}

	public static function rdB2ShapeCastInput(v:B2ShapeCastInput):B2ShapeCastInput {
		rdB2ShapeProxy(v.proxy);
		Io.rv(v.translation);
		v.maxFraction = Io.rf();
		v.canEncroach = Io.rb();
		return v;
	}

	public static function wrB2ShapeCastInput(v:B2ShapeCastInput):Void {
		wrB2ShapeProxy(v.proxy);
		Io.wv(v.translation);
		Io.wf(v.maxFraction);
		Io.wb(v.canEncroach);
	}

	public static function rdB2ShapeCastPairInput(v:B2ShapeCastPairInput):B2ShapeCastPairInput {
		rdB2ShapeProxy(v.proxyA);
		rdB2ShapeProxy(v.proxyB);
		rdB2Transform(v.transform);
		Io.rv(v.translationB);
		v.maxFraction = Io.rf();
		v.canEncroach = Io.rb();
		return v;
	}

	public static function wrB2ShapeCastPairInput(v:B2ShapeCastPairInput):Void {
		wrB2ShapeProxy(v.proxyA);
		wrB2ShapeProxy(v.proxyB);
		wrB2Transform(v.transform);
		Io.wv(v.translationB);
		Io.wf(v.maxFraction);
		Io.wb(v.canEncroach);
	}

	public static function rdB2ShapeDef(v:B2ShapeDef):B2ShapeDef {
		Io.ri();
		v.userData = null;
		rdB2SurfaceMaterial(v.material);
		v.density = Io.rf();
		rdB2Filter(v.filter);
		v.enableCustomFiltering = Io.rb();
		v.isSensor = Io.rb();
		v.enableSensorEvents = Io.rb();
		v.enableContactEvents = Io.rb();
		v.enableHitEvents = Io.rb();
		v.enablePreSolveEvents = Io.rb();
		v.invokeContactCreation = Io.rb();
		v.updateBodyMass = Io.rb();
		return v;
	}

	public static function wrB2ShapeDef(v:B2ShapeDef):Void {
		Io.wi(0);
		wrB2SurfaceMaterial(v.material);
		Io.wf(v.density);
		wrB2Filter(v.filter);
		Io.wb(v.enableCustomFiltering);
		Io.wb(v.isSensor);
		Io.wb(v.enableSensorEvents);
		Io.wb(v.enableContactEvents);
		Io.wb(v.enableHitEvents);
		Io.wb(v.enablePreSolveEvents);
		Io.wb(v.invokeContactCreation);
		Io.wb(v.updateBodyMass);
	}

	public static function rdB2ShapeId(v:B2ShapeId):B2ShapeId {
		v.index1 = Io.ri();
		v.world0 = Io.ri();
		v.generation = Io.ri();
		return v;
	}

	public static function wrB2ShapeId(v:B2ShapeId):Void {
		Io.wi(v.index1);
		Io.wi(v.world0);
		Io.wi(v.generation);
	}

	public static function rdB2ShapeProxy(v:B2ShapeProxy):B2ShapeProxy {
		for (k in 0...8)
			Io.rv(v.points[k]);
		v.count = Io.ri();
		v.radius = Io.rf();
		return v;
	}

	public static function wrB2ShapeProxy(v:B2ShapeProxy):Void {
		for (k in 0...8)
			Io.wv(v.points[k]);
		Io.wi(v.count);
		Io.wf(v.radius);
	}

	public static function rdB2Simplex(v:B2Simplex):B2Simplex {
		rdB2SimplexVertex(v.v1);
		rdB2SimplexVertex(v.v2);
		rdB2SimplexVertex(v.v3);
		v.count = Io.ri();
		return v;
	}

	public static function wrB2Simplex(v:B2Simplex):Void {
		wrB2SimplexVertex(v.v1);
		wrB2SimplexVertex(v.v2);
		wrB2SimplexVertex(v.v3);
		Io.wi(v.count);
	}

	public static function rdB2SimplexCache(v:B2SimplexCache):B2SimplexCache {
		v.count = Io.ri();
		for (k in 0...3)
			v.indexA[k] = Io.ri();
		for (k in 0...3)
			v.indexB[k] = Io.ri();
		return v;
	}

	public static function wrB2SimplexCache(v:B2SimplexCache):Void {
		Io.wi(v.count);
		for (k in 0...3)
			Io.wi(v.indexA[k]);
		for (k in 0...3)
			Io.wi(v.indexB[k]);
	}

	public static function rdB2SimplexVertex(v:B2SimplexVertex):B2SimplexVertex {
		Io.rv(v.wA);
		Io.rv(v.wB);
		Io.rv(v.w);
		v.a = Io.rf();
		v.indexA = Io.ri();
		v.indexB = Io.ri();
		return v;
	}

	public static function wrB2SimplexVertex(v:B2SimplexVertex):Void {
		Io.wv(v.wA);
		Io.wv(v.wB);
		Io.wv(v.w);
		Io.wf(v.a);
		Io.wi(v.indexA);
		Io.wi(v.indexB);
	}

	public static function rdB2SurfaceMaterial(v:B2SurfaceMaterial):B2SurfaceMaterial {
		v.friction = Io.rf();
		v.restitution = Io.rf();
		v.rollingResistance = Io.rf();
		v.tangentSpeed = Io.rf();
		v.userMaterialId = Io.rl();
		v.customColor = Io.ri();
		return v;
	}

	public static function wrB2SurfaceMaterial(v:B2SurfaceMaterial):Void {
		Io.wf(v.friction);
		Io.wf(v.restitution);
		Io.wf(v.rollingResistance);
		Io.wf(v.tangentSpeed);
		Io.wl(v.userMaterialId);
		Io.wi(v.customColor);
	}

	public static function rdB2Sweep(v:B2Sweep):B2Sweep {
		Io.rv(v.localCenter);
		Io.rv(v.c1);
		Io.rv(v.c2);
		rdB2Rot(v.q1);
		rdB2Rot(v.q2);
		return v;
	}

	public static function wrB2Sweep(v:B2Sweep):Void {
		Io.wv(v.localCenter);
		Io.wv(v.c1);
		Io.wv(v.c2);
		wrB2Rot(v.q1);
		wrB2Rot(v.q2);
	}

	public static function rdB2TOIInput(v:B2TOIInput):B2TOIInput {
		rdB2ShapeProxy(v.proxyA);
		rdB2ShapeProxy(v.proxyB);
		rdB2Sweep(v.sweepA);
		rdB2Sweep(v.sweepB);
		v.maxFraction = Io.rf();
		return v;
	}

	public static function wrB2TOIInput(v:B2TOIInput):Void {
		wrB2ShapeProxy(v.proxyA);
		wrB2ShapeProxy(v.proxyB);
		wrB2Sweep(v.sweepA);
		wrB2Sweep(v.sweepB);
		Io.wf(v.maxFraction);
	}

	public static function rdB2TOIOutput(v:B2TOIOutput):B2TOIOutput {
		v.state = cast Io.ri();
		Io.rv(v.point);
		Io.rv(v.normal);
		v.fraction = Io.rf();
		return v;
	}

	public static function wrB2TOIOutput(v:B2TOIOutput):Void {
		Io.wi(v.state);
		Io.wv(v.point);
		Io.wv(v.normal);
		Io.wf(v.fraction);
	}

	public static function rdB2Transform(v:B2Transform):B2Transform {
		Io.rv(v.p);
		rdB2Rot(v.q);
		return v;
	}

	public static function wrB2Transform(v:B2Transform):Void {
		Io.wv(v.p);
		wrB2Rot(v.q);
	}

	public static function rdB2TreeStats(v:B2TreeStats):B2TreeStats {
		v.nodeVisits = Io.ri();
		v.leafVisits = Io.ri();
		return v;
	}

	public static function wrB2TreeStats(v:B2TreeStats):Void {
		Io.wi(v.nodeVisits);
		Io.wi(v.leafVisits);
	}

	public static function rdB2Version(v:B2Version):B2Version {
		v.major = Io.ri();
		v.minor = Io.ri();
		v.revision = Io.ri();
		return v;
	}

	public static function wrB2Version(v:B2Version):Void {
		Io.wi(v.major);
		Io.wi(v.minor);
		Io.wi(v.revision);
	}

	public static function rdB2WeldJointDef(v:B2WeldJointDef):B2WeldJointDef {
		rdB2JointDef(v.base);
		v.linearHertz = Io.rf();
		v.angularHertz = Io.rf();
		v.linearDampingRatio = Io.rf();
		v.angularDampingRatio = Io.rf();
		return v;
	}

	public static function wrB2WeldJointDef(v:B2WeldJointDef):Void {
		wrB2JointDef(v.base);
		Io.wf(v.linearHertz);
		Io.wf(v.angularHertz);
		Io.wf(v.linearDampingRatio);
		Io.wf(v.angularDampingRatio);
	}

	public static function rdB2WheelJointDef(v:B2WheelJointDef):B2WheelJointDef {
		rdB2JointDef(v.base);
		v.enableSpring = Io.rb();
		v.hertz = Io.rf();
		v.dampingRatio = Io.rf();
		v.enableLimit = Io.rb();
		v.lowerTranslation = Io.rf();
		v.upperTranslation = Io.rf();
		v.enableMotor = Io.rb();
		v.maxMotorTorque = Io.rf();
		v.motorSpeed = Io.rf();
		return v;
	}

	public static function wrB2WheelJointDef(v:B2WheelJointDef):Void {
		wrB2JointDef(v.base);
		Io.wb(v.enableSpring);
		Io.wf(v.hertz);
		Io.wf(v.dampingRatio);
		Io.wb(v.enableLimit);
		Io.wf(v.lowerTranslation);
		Io.wf(v.upperTranslation);
		Io.wb(v.enableMotor);
		Io.wf(v.maxMotorTorque);
		Io.wf(v.motorSpeed);
	}

	public static function rdB2WorldDef(v:B2WorldDef):B2WorldDef {
		Io.rv(v.gravity);
		v.restitutionThreshold = Io.rf();
		v.restitutionIterations = Io.ri();
		v.enableRestitutionPropagation = Io.rb();
		v.hitEventThreshold = Io.rf();
		v.contactHertz = Io.rf();
		v.contactDampingRatio = Io.rf();
		v.contactSpeed = Io.rf();
		v.maximumLinearSpeed = Io.rf();
		Io.ri();
		Io.ri();
		v.enableSleep = Io.rb();
		v.enableContinuous = Io.rb();
		v.workerCount = Io.ri();
		Io.ri();
		v.userData = null;
		rdB2Capacity(v.capacity);
		return v;
	}

	public static function wrB2WorldDef(v:B2WorldDef):Void {
		Io.wv(v.gravity);
		Io.wf(v.restitutionThreshold);
		Io.wi(v.restitutionIterations);
		Io.wb(v.enableRestitutionPropagation);
		Io.wf(v.hitEventThreshold);
		Io.wf(v.contactHertz);
		Io.wf(v.contactDampingRatio);
		Io.wf(v.contactSpeed);
		Io.wf(v.maximumLinearSpeed);
		Io.wb(v.frictionCallback != null);
		Io.wb(v.restitutionCallback != null);
		Io.wb(v.enableSleep);
		Io.wb(v.enableContinuous);
		Io.wi(v.workerCount);
		Io.wi(0);
		wrB2Capacity(v.capacity);
	}

	public static function rdB2WorldId(v:B2WorldId):B2WorldId {
		v.index1 = Io.ri();
		v.generation = Io.ri();
		return v;
	}

	public static function wrB2WorldId(v:B2WorldId):Void {
		Io.wi(v.index1);
		Io.wi(v.generation);
	}
}
