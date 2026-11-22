package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;
import helix.jolt.Jolt.*;

/** Represents a listener recording the contacts of a step, read after the step: an extra of helix-jolt's, in place of Jolt's
	`ContactListener` calls made during it.

	```haxe
	var contacts = new ContactEventQueue(1024);
	physicsSystem.SetContactListener(contacts);
	var event = new ContactEvent();
	// each frame:
	jolt.Step(1 / 60, 1);
	for (i in 0...contacts.GetNumEvents()) {
		contacts.GetEvent(i, event);
		if (event.mType == EContactEventType_Added && event.mBodyID1 == pickup)
			collect(event.mBodyID2);
	}
	```

	`JoltInterface.Step` empties the queue before the step, and the step fills it, in the order the contacts were found, which is the
	same natively and in a page. The events cross from the module in one copy after the step. */
class ContactEventQueue extends ContactListener {
	/** Creates an empty queue.

		@param inMaxEvents  The most events a step records: a pair of bodies starting to touch is one event, and stopping another. A
		step's events past it are counted by `GetNumDroppedEvents`.
		@param inRecordPersisted  Optional. Whether `EContactEventType_Persisted` events are recorded, one a touching pair a step;
		defaults to false. */
	public function new(inMaxEvents:Int, inRecordPersisted = false) {
		super();
		maxEvents = inMaxEvents;
		recordPersisted = inRecordPersisted;
	}

	/** Returns the number of events of the last step.

		@return  The count. */
	public function GetNumEvents():Int {
		return count;
	}

	/** Returns an event of the last step.

		@param inIndex  The event's index, 0 to `GetNumEvents() - 1`.
		@param out  Optional. The event to fill; a new one when omitted.
		@return  The event. */
	public function GetEvent(inIndex:Int, ?out:ContactEvent):ContactEvent {
		var event = out == null ? new ContactEvent() : out;
		var at = inIndex * 12;
		event.mType = cast ints[at];
		event.mBodyID1 = new BodyID(ints[at + 1]);
		event.mBodyID2 = new BodyID(ints[at + 2]);
		event.mSubShapeID1 = cast ints[at + 3];
		event.mSubShapeID2 = cast ints[at + 4];
		(event.mWorldSpaceNormal : helix.math.Vector3).set(floats[at + 5], floats[at + 6], floats[at + 7]);
		(event.mContactPoint : helix.math.Vector3).set(floats[at + 8], floats[at + 9], floats[at + 10]);
		event.mPenetrationDepth = floats[at + 11];
		return event;
	}

	/** Returns the number of events of the last step past `inMaxEvents`, which were not recorded.

		@return  The count. */
	public function GetNumDroppedEvents():Int {
		return dropped;
	}

	var maxEvents:Int;
	var recordPersisted:Bool;
	var count = 0;
	var dropped = 0;
	var ints:Array<Int> = [];
	var floats:Array<Float> = [];

	override function attach(world:Int):Void {
		Hj.worldSetContactQueue(world, maxEvents, recordPersisted ? 1 : 0);
		count = 0;
		dropped = 0;
	}

	override function stepped(world:Int):Void {
		count = Hj.worldGetContacts(world);
		dropped = Hj.worldGetDroppedContacts(world);
		var base = Io.bulk(count * 48);
		for (n in 0...count * 12) {
			ints[n] = Io.bulkI(base, n);
			floats[n] = Io.bulkF(base, n);
		}
	}
}
