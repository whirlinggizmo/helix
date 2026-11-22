// helix-jolt's C ABI over Jolt Physics (hj.h): a step's contacts, recorded for ContactEventQueue.
#include "hj_internal.h"

#include <Jolt/Physics/Body/Body.h>

#include <cstring>

using namespace JPH;
using namespace hj;

namespace hj {

void ContactQueue::begin_step() {
	events.clear();
	dropped = 0;
}

// Records a contact with the sensor first, or else the body of the lower index first, its normal pointing from the first body to the
// second and its point the middle of the first body's contact points.
void ContactQueue::record(int32_t type, const Body &inBody1, const Body &inBody2, const ContactManifold &inManifold) {
	if (!enabled)
		return;
	if (int32_t(events.size()) >= max_events) {
		dropped++;
		return;
	}
	bool swap = inBody2.IsSensor() && !inBody1.IsSensor();
	if (inBody1.IsSensor() == inBody2.IsSensor())
		swap = inBody2.GetID().GetIndex() < inBody1.GetID().GetIndex();
	ContactRecord r;
	r.type = type;
	r.body1 = int32_t((swap ? inBody2 : inBody1).GetID().GetIndexAndSequenceNumber());
	r.body2 = int32_t((swap ? inBody1 : inBody2).GetID().GetIndexAndSequenceNumber());
	r.sub_shape1 = int32_t((swap ? inManifold.mSubShapeID2 : inManifold.mSubShapeID1).GetValue());
	r.sub_shape2 = int32_t((swap ? inManifold.mSubShapeID1 : inManifold.mSubShapeID2).GetValue());
	Vec3 normal = swap ? -inManifold.mWorldSpaceNormal : inManifold.mWorldSpaceNormal;
	RVec3 point = RVec3::sZero();
	uint count = uint(inManifold.mRelativeContactPointsOn1.size());
	for (uint i = 0; i < count; i++)
		point += swap ? inManifold.GetWorldSpaceContactPointOn2(i) : inManifold.GetWorldSpaceContactPointOn1(i);
	if (count > 0)
		point /= float(count);
	write_vec3(r.normal, normal);
	write_vec3(r.point, point);
	r.depth = inManifold.mPenetrationDepth;
	events.push_back(r);
}

void ContactQueue::OnContactAdded(const Body &inBody1, const Body &inBody2, const ContactManifold &inManifold, ContactSettings &) {
	record(0, inBody1, inBody2, inManifold);
}

void ContactQueue::OnContactPersisted(const Body &inBody1, const Body &inBody2, const ContactManifold &inManifold, ContactSettings &) {
	if (record_persisted)
		record(1, inBody1, inBody2, inManifold);
}

void ContactQueue::OnContactRemoved(const SubShapeIDPair &inSubShapePair) {
	if (!enabled)
		return;
	if (int32_t(events.size()) >= max_events) {
		dropped++;
		return;
	}
	BodyID first = inSubShapePair.GetBody1ID(), second = inSubShapePair.GetBody2ID();
	SubShapeID firstPart = inSubShapePair.GetSubShapeID1(), secondPart = inSubShapePair.GetSubShapeID2();
	bool sensor1 = bodies != nullptr && bodies->IsSensor(first), sensor2 = bodies != nullptr && bodies->IsSensor(second);
	bool swap = sensor1 == sensor2 ? second.GetIndex() < first.GetIndex() : sensor2;
	ContactRecord r = {};
	r.type = 2;
	r.body1 = int32_t((swap ? second : first).GetIndexAndSequenceNumber());
	r.body2 = int32_t((swap ? first : second).GetIndexAndSequenceNumber());
	r.sub_shape1 = int32_t((swap ? secondPart : firstPart).GetValue());
	r.sub_shape2 = int32_t((swap ? firstPart : secondPart).GetValue());
	events.push_back(r);
}

} // namespace hj

extern "C" {

void hj_world_set_contact_queue(int32_t world, int32_t max_events, int32_t record_persisted) {
	World *w = world_of(world);
	if (w == nullptr)
		return;
	w->contacts.enabled = max_events > 0;
	w->contacts.max_events = max_events;
	w->contacts.record_persisted = record_persisted != 0;
	w->contacts.bodies = &w->system.GetBodyInterfaceNoLock();
	w->contacts.begin_step();
}

int32_t hj_world_get_contacts(int32_t world) {
	World *w = world_of(world);
	if (w == nullptr)
		return 0;
	size_t count = w->contacts.events.size();
	uint8 *out = bulk_at(count * sizeof(ContactRecord));
	if (count > 0)
		memcpy(out, w->contacts.events.data(), count * sizeof(ContactRecord));
	return int32_t(count);
}

int32_t hj_world_get_dropped_contacts(int32_t world) {
	World *w = world_of(world);
	return w == nullptr ? 0 : w->contacts.dropped;
}

} // extern "C"
