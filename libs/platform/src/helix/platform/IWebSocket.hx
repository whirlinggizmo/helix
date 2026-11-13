package helix.platform;

import haxe.io.Bytes;

/** Defines connections to servers over WebSocket: messages of text or bytes, each delivered whole and in the order sent, with the time
	it arrived. */
interface IWebSocket extends IPollable {
	/** Opens a connection to a server.

		The callbacks are called on the main thread, at `poll`, never during this call. `opened` is called once, when the server accepts
		the connection; then `text` or `bytes` for each message, in the order the server sent them; then one of `closed` or `failed`. A
		connection the program closes calls `closed` once the server answers the close, or `failed` if it never does. After `failed` or
		`closed`, nothing more is called, and the connection's id is no longer one.

		A message's time is when it arrived: taken as the platform received it, on `ISystem.getTime`'s clock, not when `poll` delivered
		it, which waits for the frame.

		A binary message is lent for the call: its bytes are the first `messageLength` of a buffer the platform reuses, so a program copies
		what it keeps, and a steady stream of messages allocates nothing natively.

		@param url  The server's URL, ws or wss, whole.
		@param protocols  The subprotocols offered, the preferred first; empty for none.
		@param opened  Receives the subprotocol the server chose, or empty for none.
		@param text  Receives each text message and the time it arrived, in seconds.
		@param bytes  Receives each binary message: the buffer holding it, its size in bytes, and the time it arrived, in seconds.
		@param closed  Receives the close's code and its reason, whichever side closed first.
		@param failed  Receives why the connection failed: the server refused it or couldn't be reached, or it dropped without a close.
		@return  The connection's id. */
	function open(url:String, protocols:Array<String>, opened:String->Void, text:(message:String, arrivalTime:Float) -> Void,
		bytes:(buffer:Bytes, messageLength:Int, arrivalTime:Float) -> Void, closed:(code:Int, reason:String) -> Void, failed:String->Void):Int;

	/** Sends a text message, after the ones sent before it. Nothing for a connection not open yet, or closed.

		@param connectionId  The connection.
		@param message  The text. */
	function sendText(connectionId:Int, message:String):Void;

	/** Sends a binary message, after the ones sent before it: a buffer's first bytes, copied as it is called, so a program can send from
		one buffer it reuses. Nothing for a connection not open yet, or closed.

		@param connectionId  The connection.
		@param buffer  The buffer holding the message.
		@param messageLength  The message's length in bytes, from the buffer's start. */
	function sendBytes(connectionId:Int, buffer:Bytes, messageLength:Int):Void;

	/** Gets how many bytes sent on a connection haven't gone out yet, for a program sending faster than the network takes them; 0 for
		a connection not open, or closed.

		@param connectionId  The connection.
		@return  The bytes not yet sent. */
	function getOutgoingByteCount(connectionId:Int):Int;

	/** Gets how many bytes received on a connection the next `poll` delivers, for a program that polls late, or watches a server
		outpacing it; 0 for a connection not open, or closed.

		@param connectionId  The connection.
		@return  The bytes not yet delivered. */
	function getIncomingByteCount(connectionId:Int):Int;

	/** Closes a connection: the messages sent before it go first, then the close. `closed` is called once the server answers.

		@param connectionId  The connection.
		@param code  The close's code: 1000 for a normal close, or 3000 to 4999 for a program's own.
		@param reason  Why, at most 123 bytes as UTF-8. */
	function close(connectionId:Int, code:Int = 1000, reason:String = ""):Void;

	/** Delivers, in order, everything that had arrived when the call began: each connection's opening, messages and close or failure.
		One arriving during the call waits for the next. The program calls it once a frame. */
	function poll():Void;

	/** Closes every connection at once, without waiting for the servers, and calls nothing more. */
	function dispose():Void;
}
