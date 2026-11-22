package helix.jolt;

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
		throw "not built yet";
	}

	/** Returns the number of events of the last step.

		@return  The count. */
	public function GetNumEvents():Int {
		throw "not built yet";
	}

	/** Returns an event of the last step.

		@param inIndex  The event's index, 0 to `GetNumEvents() - 1`.
		@param out  Optional. The event to fill; a new one when omitted.
		@return  The event. */
	public function GetEvent(inIndex:Int, ?out:ContactEvent):ContactEvent {
		throw "not built yet";
	}

	/** Returns the number of events of the last step past `inMaxEvents`, which were not recorded.

		@return  The count. */
	public function GetNumDroppedEvents():Int {
		throw "not built yet";
	}
}
