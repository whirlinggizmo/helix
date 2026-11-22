package helix.box2d;

/** A callback that receives Box2D's log messages. Box2D calls it when it logs a warning, such as when it rejects invalid input.

	@param message  The text of the message. */
typedef B2LogCallbackFcn = (message:String) -> Void;
