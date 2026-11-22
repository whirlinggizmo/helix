package helix.jolt;

/** Represents a body's id: its index in the system and a sequence number, so a destroyed body's id is never another body's. Holds no
	object. Two ids are compared with `==` and `!=`, by value. */
abstract BodyID(Int) {
	/** Creates an id from its index and sequence number.

		@param inIndexAndSequenceNumber  Optional. The value from `GetIndexAndSequenceNumber`; defaults to the invalid id. */
	public inline function new(inIndexAndSequenceNumber = 0xffffffff) {
		this = inIndexAndSequenceNumber;
	}

	/** Returns the body's index in the system.

		@return  The index. */
	public function GetIndex():Int {
		throw "not built yet";
	}

	/** Returns the id's whole value, the index and the sequence number together.

		@return  The value. */
	public function GetIndexAndSequenceNumber():Int {
		throw "not built yet";
	}

	/** Returns whether two ids are the same.

		@param a  One id.
		@param b  The other id.
		@return  True when the ids are equal. */
	@:op(A == B) static function equals(a:BodyID, b:BodyID):Bool;

	/** Returns whether two ids differ.

		@param a  One id.
		@param b  The other id.
		@return  True when the ids differ. */
	@:op(A != B) static function differs(a:BodyID, b:BodyID):Bool;

	/** Returns whether the id names a body. A query that hits nothing leaves its result's body id invalid.

		@return  False for the invalid id. */
	public function IsInvalid():Bool {
		throw "not built yet";
	}
}
