// helix-jolt's C ABI over Jolt Physics (hj.h): constraints between two bodies.
#include "hj_internal.h"

#include <Jolt/Physics/Body/BodyLock.h>
#include <Jolt/Physics/Body/BodyLockMulti.h>
#include <Jolt/Physics/Constraints/ConeConstraint.h>
#include <Jolt/Physics/Constraints/DistanceConstraint.h>
#include <Jolt/Physics/Constraints/FixedConstraint.h>
#include <Jolt/Physics/Constraints/HingeConstraint.h>
#include <Jolt/Physics/Constraints/PointConstraint.h>
#include <Jolt/Physics/Constraints/SixDOFConstraint.h>
#include <Jolt/Physics/Constraints/SliderConstraint.h>

using namespace JPH;
using namespace hj;

namespace {

Vec3 vec3_at(const float *f) { return Vec3(f[0], f[1], f[2]); }

RVec3 rvec3_at(const float *f) { return RVec3(f[0], f[1], f[2]); }

// A spring from its mode and three floats: frequency, stiffness, damping.
SpringSettings spring_at(int32_t mode, const float *f) {
	SpringSettings spring;
	spring.mMode = ESpringMode(mode);
	if (spring.mMode == ESpringMode::FrequencyAndDamping)
		spring.mFrequency = f[0];
	else
		spring.mStiffness = f[1];
	spring.mDamping = f[2];
	return spring;
}

void write_spring(float *f, int32_t *mode, const SpringSettings &spring) {
	*mode = int32_t(spring.mMode);
	f[0] = spring.mMode == ESpringMode::FrequencyAndDamping ? spring.mFrequency : 0.0f;
	f[1] = spring.mMode == ESpringMode::FrequencyAndDamping ? 0.0f : spring.mStiffness;
	f[2] = spring.mDamping;
}

// A motor from its spring's mode and seven floats: the spring's three, then the force and torque limits.
MotorSettings motor_at(int32_t mode, const float *f) {
	MotorSettings motor;
	motor.mSpringSettings = spring_at(mode, f);
	motor.mMinForceLimit = f[3];
	motor.mMaxForceLimit = f[4];
	motor.mMinTorqueLimit = f[5];
	motor.mMaxTorqueLimit = f[6];
	return motor;
}

void write_motor(float *f, int32_t *mode, const MotorSettings &motor) {
	write_spring(f, mode, motor.mSpringSettings);
	f[3] = motor.mMinForceLimit;
	f[4] = motor.mMaxForceLimit;
	f[5] = motor.mMinTorqueLimit;
	f[6] = motor.mMaxTorqueLimit;
}

ConstraintEntry *entry_of(int32_t world, int32_t constraint) {
	World *w = world_of(world);
	if (w == nullptr)
		return nullptr;
	auto found = w->constraints.find(constraint);
	return found == w->constraints.end() ? nullptr : &found->second;
}

TwoBodyConstraint *constraint_of(int32_t world, int32_t constraint) {
	ConstraintEntry *entry = entry_of(world, constraint);
	return entry == nullptr ? nullptr : entry->ref.GetPtr();
}

template <class T> T *kind_of(int32_t world, int32_t constraint, EConstraintSubType sub_type) {
	TwoBodyConstraint *c = constraint_of(world, constraint);
	return c != nullptr && c->GetSubType() == sub_type ? static_cast<T *>(c) : nullptr;
}

// The settings of a kind, read from hj_io_f and hj_io_i in the order of its settings class (and for six axes, the bulk buffer).
TwoBodyConstraintSettings *settings_of(int32_t kind) {
	const float *f = io_f;
	EConstraintSpace space = EConstraintSpace(io_i[0]);
	switch (kind) {
	case 0: {
		FixedConstraintSettings *s = new FixedConstraintSettings();
		s->mSpace = space;
		s->mAutoDetectPoint = io_i[2] != 0;
		s->mPoint1 = rvec3_at(f);
		s->mAxisX1 = vec3_at(f + 3);
		s->mAxisY1 = vec3_at(f + 6);
		s->mPoint2 = rvec3_at(f + 9);
		s->mAxisX2 = vec3_at(f + 12);
		s->mAxisY2 = vec3_at(f + 15);
		return s;
	}
	case 1: {
		PointConstraintSettings *s = new PointConstraintSettings();
		s->mSpace = space;
		s->mPoint1 = rvec3_at(f);
		s->mPoint2 = rvec3_at(f + 3);
		return s;
	}
	case 2: {
		DistanceConstraintSettings *s = new DistanceConstraintSettings();
		s->mSpace = space;
		s->mPoint1 = rvec3_at(f);
		s->mPoint2 = rvec3_at(f + 3);
		s->mMinDistance = f[6];
		s->mMaxDistance = f[7];
		s->mLimitsSpringSettings = spring_at(io_i[2], f + 8);
		return s;
	}
	case 3: {
		HingeConstraintSettings *s = new HingeConstraintSettings();
		s->mSpace = space;
		s->mPoint1 = rvec3_at(f);
		s->mHingeAxis1 = vec3_at(f + 3);
		s->mNormalAxis1 = vec3_at(f + 6);
		s->mPoint2 = rvec3_at(f + 9);
		s->mHingeAxis2 = vec3_at(f + 12);
		s->mNormalAxis2 = vec3_at(f + 15);
		s->mLimitsMin = f[18];
		s->mLimitsMax = f[19];
		s->mMaxFrictionTorque = f[20];
		s->mLimitsSpringSettings = spring_at(io_i[2], f + 21);
		s->mMotorSettings = motor_at(io_i[3], f + 24);
		return s;
	}
	case 4: {
		SliderConstraintSettings *s = new SliderConstraintSettings();
		s->mSpace = space;
		s->mAutoDetectPoint = io_i[2] != 0;
		s->mPoint1 = rvec3_at(f);
		s->mSliderAxis1 = vec3_at(f + 3);
		s->mNormalAxis1 = vec3_at(f + 6);
		s->mPoint2 = rvec3_at(f + 9);
		s->mSliderAxis2 = vec3_at(f + 12);
		s->mNormalAxis2 = vec3_at(f + 15);
		s->mLimitsMin = f[18];
		s->mLimitsMax = f[19];
		s->mMaxFrictionForce = f[20];
		s->mLimitsSpringSettings = spring_at(io_i[3], f + 21);
		s->mMotorSettings = motor_at(io_i[4], f + 24);
		return s;
	}
	case 5: {
		ConeConstraintSettings *s = new ConeConstraintSettings();
		s->mSpace = space;
		s->mPoint1 = rvec3_at(f);
		s->mTwistAxis1 = vec3_at(f + 3);
		s->mPoint2 = rvec3_at(f + 6);
		s->mTwistAxis2 = vec3_at(f + 9);
		s->mHalfConeAngle = f[12];
		return s;
	}
	case 6: {
		// The bulk buffer: 96 floats (points and axes 0-17, friction 18-23, limit min 24-29, limit max 30-35, each axis' limits spring
		// 36-53, each axis' motor 54-95), then 12 ints (each axis' limits spring mode, each axis' motor spring mode).
		const uint8 *area = bulk_at(96 * 4 + 12 * 4);
		const float *b = reinterpret_cast<const float *>(area);
		const int32_t *modes = reinterpret_cast<const int32_t *>(area + 96 * 4);
		SixDOFConstraintSettings *s = new SixDOFConstraintSettings();
		s->mSpace = space;
		s->mPosition1 = rvec3_at(b);
		s->mAxisX1 = vec3_at(b + 3);
		s->mAxisY1 = vec3_at(b + 6);
		s->mPosition2 = rvec3_at(b + 9);
		s->mAxisX2 = vec3_at(b + 12);
		s->mAxisY2 = vec3_at(b + 15);
		for (int a = 0; a < 6; a++) {
			s->mMaxFriction[a] = b[18 + a];
			s->mLimitMin[a] = b[24 + a];
			s->mLimitMax[a] = b[30 + a];
			s->mLimitsSpringSettings[a] = spring_at(modes[a], b + 36 + a * 3);
			s->mMotorSettings[a] = motor_at(modes[6 + a], b + 54 + a * 7);
		}
		return s;
	}
	default: return nullptr;
	}
}

} // namespace

extern "C" {

int32_t hj_constraint_create(int32_t world, int32_t kind, int32_t body1, int32_t body2) {
	World *w = world_of(world);
	if (w == nullptr)
		return -1;
	Ref<TwoBodyConstraintSettings> settings = settings_of(kind);
	if (settings == nullptr)
		return -1;
	settings->mEnabled = io_i[1] != 0;
	BodyID ids[] = {BodyID(uint32(body1)), BodyID(uint32(body2))};
	BodyLockMultiWrite lock(w->system.GetBodyLockInterfaceNoLock(), ids, 2);
	Body *first = lock.GetBody(0), *second = lock.GetBody(1);
	if (first == nullptr && second == nullptr)
		return -1;
	TwoBodyConstraint *constraint = settings->Create(first != nullptr ? *first : Body::sFixedToWorld, second != nullptr ? *second : Body::sFixedToWorld);
	int32_t handle = w->next_constraint++;
	w->constraints[handle] = ConstraintEntry{Ref<TwoBodyConstraint>(constraint), false};
	return handle;
}

void hj_constraint_add(int32_t world, int32_t constraint) {
	ConstraintEntry *entry = entry_of(world, constraint);
	if (entry == nullptr || entry->added)
		return;
	world_of(world)->system.AddConstraint(entry->ref);
	entry->added = true;
}

void hj_constraint_remove(int32_t world, int32_t constraint) {
	ConstraintEntry *entry = entry_of(world, constraint);
	if (entry == nullptr || !entry->added)
		return;
	world_of(world)->system.RemoveConstraint(entry->ref);
	entry->added = false;
}

// The count the program sees: Jolt's, less the table's hold and the system's while added.
int32_t hj_constraint_get_ref_count(int32_t world, int32_t constraint) {
	ConstraintEntry *entry = entry_of(world, constraint);
	return entry == nullptr ? 0 : int32_t(entry->ref->GetRefCount()) - 1;
}

void hj_constraint_add_ref(int32_t world, int32_t constraint) {
	if (ConstraintEntry *entry = entry_of(world, constraint))
		entry->ref->AddRef();
}

void hj_constraint_release(int32_t world, int32_t constraint) {
	ConstraintEntry *entry = entry_of(world, constraint);
	if (entry == nullptr)
		return;
	uint held = 1 + (entry->added ? 1 : 0);
	if (entry->ref->GetRefCount() > held)
		entry->ref->Release();
	if (!entry->added && entry->ref->GetRefCount() == 1)
		world_of(world)->constraints.erase(constraint);
}

int32_t hj_constraint_get_sub_type(int32_t world, int32_t constraint) {
	TwoBodyConstraint *c = constraint_of(world, constraint);
	return c == nullptr ? 0 : int32_t(c->GetSubType());
}

void hj_constraint_set_enabled(int32_t world, int32_t constraint, int32_t enabled) {
	if (TwoBodyConstraint *c = constraint_of(world, constraint))
		c->SetEnabled(enabled != 0);
}

int32_t hj_constraint_get_enabled(int32_t world, int32_t constraint) {
	TwoBodyConstraint *c = constraint_of(world, constraint);
	return c != nullptr && c->GetEnabled() ? 1 : 0;
}

void hj_constraint_set_user_data(int32_t world, int32_t constraint, int32_t user_data) {
	if (TwoBodyConstraint *c = constraint_of(world, constraint))
		c->SetUserData(uint64(uint32(user_data)));
}

int32_t hj_constraint_get_user_data(int32_t world, int32_t constraint) {
	TwoBodyConstraint *c = constraint_of(world, constraint);
	return c == nullptr ? 0 : int32_t(uint32(c->GetUserData()));
}

int32_t hj_constraint_get_body(int32_t world, int32_t constraint, int32_t second) {
	TwoBodyConstraint *c = constraint_of(world, constraint);
	if (c == nullptr)
		return -1;
	return int32_t((second != 0 ? c->GetBody2() : c->GetBody1())->GetID().GetIndexAndSequenceNumber());
}

// A number of a kind's, by `what`: the hinge's current angle 0, friction torque 1, target angular velocity 2, target angle 3, limits
// 4 and 5, has limits 6; the slider's current position 10, friction force 11, target velocity 12, target position 13, limits 14 and 15,
// has limits 16; the distance's min 20 and max 21; a six axes' limit min 40 + axis, max 50 + axis, fixed 60 + axis, free 70 + axis.
float hj_constraint_get_float(int32_t world, int32_t constraint, int32_t what) {
	if (HingeConstraint *h = kind_of<HingeConstraint>(world, constraint, EConstraintSubType::Hinge)) {
		switch (what) {
		case 0: return h->GetCurrentAngle();
		case 1: return h->GetMaxFrictionTorque();
		case 2: return h->GetTargetAngularVelocity();
		case 3: return h->GetTargetAngle();
		case 4: return h->GetLimitsMin();
		case 5: return h->GetLimitsMax();
		case 6: return h->HasLimits() ? 1.0f : 0.0f;
		}
	}
	if (SliderConstraint *s = kind_of<SliderConstraint>(world, constraint, EConstraintSubType::Slider)) {
		switch (what) {
		case 10: return s->GetCurrentPosition();
		case 11: return s->GetMaxFrictionForce();
		case 12: return s->GetTargetVelocity();
		case 13: return s->GetTargetPosition();
		case 14: return s->GetLimitsMin();
		case 15: return s->GetLimitsMax();
		case 16: return s->HasLimits() ? 1.0f : 0.0f;
		}
	}
	if (DistanceConstraint *d = kind_of<DistanceConstraint>(world, constraint, EConstraintSubType::Distance)) {
		switch (what) {
		case 20: return d->GetMinDistance();
		case 21: return d->GetMaxDistance();
		}
	}
	if (SixDOFConstraint *x = kind_of<SixDOFConstraint>(world, constraint, EConstraintSubType::SixDOF)) {
		SixDOFConstraintSettings::EAxis axis = SixDOFConstraintSettings::EAxis(what % 10);
		switch (what / 10) {
		case 4: return x->GetLimitsMin(axis);
		case 5: return x->GetLimitsMax(axis);
		case 6: return x->IsFixedAxis(axis) ? 1.0f : 0.0f;
		case 7: return x->IsFreeAxis(axis) ? 1.0f : 0.0f;
		}
	}
	return 0.0f;
}

// Sets a number of a kind's, by `what`: the hinge's friction torque 1, target angular velocity 2, target angle 3; the slider's
// friction force 11, target velocity 12, target position 13; the cone's half angle 30; a six axes' friction 80 + axis.
void hj_constraint_set_float(int32_t world, int32_t constraint, int32_t what, float value) {
	if (HingeConstraint *h = kind_of<HingeConstraint>(world, constraint, EConstraintSubType::Hinge)) {
		switch (what) {
		case 1: h->SetMaxFrictionTorque(value); return;
		case 2: h->SetTargetAngularVelocity(value); return;
		case 3: h->SetTargetAngle(value); return;
		}
	}
	if (SliderConstraint *s = kind_of<SliderConstraint>(world, constraint, EConstraintSubType::Slider)) {
		switch (what) {
		case 11: s->SetMaxFrictionForce(value); return;
		case 12: s->SetTargetVelocity(value); return;
		case 13: s->SetTargetPosition(value); return;
		}
	}
	if (ConeConstraint *c = kind_of<ConeConstraint>(world, constraint, EConstraintSubType::Cone)) {
		if (what == 30)
			c->SetHalfConeAngle(value);
		return;
	}
	if (SixDOFConstraint *x = kind_of<SixDOFConstraint>(world, constraint, EConstraintSubType::SixDOF))
		if (what / 10 == 8)
			x->SetMaxFriction(SixDOFConstraintSettings::EAxis(what % 10), value);
}

// The hinge's or slider's limits, or the distance's range.
void hj_constraint_set_range(int32_t world, int32_t constraint, float min, float max) {
	if (HingeConstraint *h = kind_of<HingeConstraint>(world, constraint, EConstraintSubType::Hinge))
		h->SetLimits(min, max);
	else if (SliderConstraint *s = kind_of<SliderConstraint>(world, constraint, EConstraintSubType::Slider))
		s->SetLimits(min, max);
	else if (DistanceConstraint *d = kind_of<DistanceConstraint>(world, constraint, EConstraintSubType::Distance))
		d->SetDistance(min, max);
}

// The motor of a hinge or slider (axis -1), or of a six axes' axis.
void hj_constraint_set_motor_state(int32_t world, int32_t constraint, int32_t axis, int32_t state) {
	if (HingeConstraint *h = kind_of<HingeConstraint>(world, constraint, EConstraintSubType::Hinge))
		h->SetMotorState(EMotorState(state));
	else if (SliderConstraint *s = kind_of<SliderConstraint>(world, constraint, EConstraintSubType::Slider))
		s->SetMotorState(EMotorState(state));
	else if (SixDOFConstraint *x = kind_of<SixDOFConstraint>(world, constraint, EConstraintSubType::SixDOF))
		x->SetMotorState(SixDOFConstraintSettings::EAxis(axis), EMotorState(state));
}

int32_t hj_constraint_get_motor_state(int32_t world, int32_t constraint, int32_t axis) {
	if (HingeConstraint *h = kind_of<HingeConstraint>(world, constraint, EConstraintSubType::Hinge))
		return int32_t(h->GetMotorState());
	if (SliderConstraint *s = kind_of<SliderConstraint>(world, constraint, EConstraintSubType::Slider))
		return int32_t(s->GetMotorState());
	if (SixDOFConstraint *x = kind_of<SixDOFConstraint>(world, constraint, EConstraintSubType::SixDOF))
		return int32_t(x->GetMotorState(SixDOFConstraintSettings::EAxis(axis)));
	return 0;
}

static MotorSettings *motor_of(int32_t world, int32_t constraint, int32_t axis) {
	if (HingeConstraint *h = kind_of<HingeConstraint>(world, constraint, EConstraintSubType::Hinge))
		return &h->GetMotorSettings();
	if (SliderConstraint *s = kind_of<SliderConstraint>(world, constraint, EConstraintSubType::Slider))
		return &s->GetMotorSettings();
	if (SixDOFConstraint *x = kind_of<SixDOFConstraint>(world, constraint, EConstraintSubType::SixDOF))
		return &x->GetMotorSettings(SixDOFConstraintSettings::EAxis(axis));
	return nullptr;
}

// A motor's settings, seven floats into hj_io_f and its spring's mode into hj_io_i, and back.
void hj_constraint_get_motor(int32_t world, int32_t constraint, int32_t axis) {
	if (MotorSettings *motor = motor_of(world, constraint, axis))
		write_motor(io_f, io_i, *motor);
}

void hj_constraint_set_motor(int32_t world, int32_t constraint, int32_t axis) {
	if (MotorSettings *motor = motor_of(world, constraint, axis))
		*motor = motor_at(io_i[0], io_f);
}

// A six axes' limits of moving (translation 1) or turning (0), min x, y, z then max x, y, z from hj_io_f.
void hj_constraint_six_dof_set_limits(int32_t world, int32_t constraint, int32_t translation) {
	SixDOFConstraint *x = kind_of<SixDOFConstraint>(world, constraint, EConstraintSubType::SixDOF);
	if (x == nullptr)
		return;
	if (translation != 0)
		x->SetTranslationLimits(vec3_at(io_f), vec3_at(io_f + 3));
	else
		x->SetRotationLimits(vec3_at(io_f), vec3_at(io_f + 3));
}

// A six axes' target from hj_io_f: velocity 0, angular velocity 1, position 2 (three floats each), orientation 3 (four).
void hj_constraint_six_dof_set_target(int32_t world, int32_t constraint, int32_t which) {
	SixDOFConstraint *x = kind_of<SixDOFConstraint>(world, constraint, EConstraintSubType::SixDOF);
	if (x == nullptr)
		return;
	switch (which) {
	case 0: x->SetTargetVelocityCS(vec3_at(io_f)); break;
	case 1: x->SetTargetAngularVelocityCS(vec3_at(io_f)); break;
	case 2: x->SetTargetPositionCS(vec3_at(io_f)); break;
	case 3: x->SetTargetOrientationCS(Quat(io_f[0], io_f[1], io_f[2], io_f[3])); break;
	}
}

} // extern "C"
