package helix.platform.adapters.shared;

/** Puts a resource's kind into its graphics handle, the same for every graphics adapter, so a handle of one kind given where another is
	expected is refused.

	A handle is its kind in bits 28 to 30 and the adapter's own number below: a counter in a page, the C's slot and generation natively
	(graphics.h). Bit 31 stays clear, so a handle is a positive `Int` on every target. 0 is no handle, of any kind. */
@:noCompletion
class GraphicsHandle {
	/** A buffer's kind. */
	public static inline final BUFFER = 1;

	/** A texture's kind: a plain or cube texture, a data texture, a render target or a shadow map. */
	public static inline final TEXTURE = 2;

	/** A program's kind. */
	public static inline final SHADER = 3;

	/** A pipeline's kind. */
	public static inline final PIPELINE = 4;

	/** The bits below the kind, which hold the adapter's own number. */
	public static inline final NUMBER_MASK = 0x0fffffff;

	static inline final KIND_SHIFT = 28;

	/** Returns the handle of a kind for the adapter's own number.

		@param kind  The kind: `BUFFER`, `TEXTURE`, `SHADER` or `PIPELINE`.
		@param number  The adapter's number, nonzero and below 1 << 28. 0 gives 0, no handle.
		@return  The handle. */
	public static inline function make(kind:Int, number:Int):Int
		return number == 0 ? 0 : (kind << KIND_SHIFT) | (number & NUMBER_MASK);

	/** Returns the kind a handle carries, or 0 for none.

		@param handle  The handle.
		@return  Its kind. */
	public static inline function kindOf(handle:Int):Int
		return handle >>> KIND_SHIFT;

	/** Returns a handle of a kind, refusing one of another kind.

		@param handle  The handle.
		@param kind  The kind it must be.
		@param message  What a handle of another kind throws.
		@return  The handle.
		@throws String  The message, for a handle of another kind, 0 among them. */
	public static inline function expect(handle:Int, kind:Int, message:String):Int {
		if ((handle >>> KIND_SHIFT) != kind)
			throw message;
		return handle;
	}

	/** Returns the adapter's own number in a handle of a kind, refusing one of another kind.

		@param handle  The handle.
		@param kind  The kind it must be.
		@param message  What a handle of another kind throws.
		@return  The adapter's number.
		@throws String  The message, for a handle of another kind, 0 among them. */
	public static inline function numberOf(handle:Int, kind:Int, message:String):Int
		return expect(handle, kind, message) & NUMBER_MASK;
}
