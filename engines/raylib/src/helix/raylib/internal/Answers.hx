package helix.raylib.internal;

#if !macro
import helix.raylib.Raylib.LOG_INFO;
import helix.raylib.modules.RCore;

/** Answers helix-raylib's async calls: a refusal to the program's `failed` or logged, a request asked of the platform, and an export's
	file written. The async sections share it. */
@:noCompletion
class Answers {
	/** Writes an export's text as `SaveFileTextAsync` writes it, logging raylib's line once it is written, as raylib's export does.

		@param name  The call, named in a refusal.
		@param fileName  The file.
		@param text  Its text.
		@param success  What raylib logs once it is written, or null for nothing.
		@param done  Called once it is written, or null.
		@param failed  Receives why it wasn't, or null to log it. */
	public static function exportText(name:String, fileName:String, text:String, success:Null<String>, done:Null<Void->Void>, failed:Null<String->Void>):Void {
		RCore.writeText(fileName, text, () -> {
			if (success != null)
				Runtime.log(LOG_INFO, 'FILEIO: [$fileName] $success');
			if (done != null)
				done();
		}, error -> refuse(name, error, failed));
	}

	/** Writes an export's file as `SaveFileDataAsync` writes it, as `exportText` does. A file that couldn't be made is refused.

		@param name  The call, named in a refusal.
		@param fileName  The file.
		@param file  Its bytes, or null when they couldn't be made.
		@param success  What raylib logs once it is written.
		@param failure  What the refusal says when there are no bytes.
		@param done  Called once it is written, or null.
		@param failed  Receives why it wasn't, or null to log it. */
	public static function exportData(name:String, fileName:String, file:Null<haxe.io.Bytes>, success:String, failure:String, done:Null<Void->Void>,
			failed:Null<String->Void>):Void {
		if (file == null) {
			Runtime.later(() -> refuse(name, '$fileName: $failure', failed));
			return;
		}
		RCore.writeData(fileName, file, file.length, () -> {
			Runtime.log(LOG_INFO, 'FILEIO: [$fileName] $success');
			if (done != null)
				done();
		}, error -> refuse(name, error, failed));
	}

	/** Asks the platform, answering as it does, at a later poll. A request it can't ask is refused at a later poll, saying why not.

		@param name  The call, named in a refusal.
		@param asking  Asks the platform, given what to call once it is granted or refused; returns false when it can't be asked.
		@param why  Why it can't be asked.
		@param done  Called once it is granted, or null.
		@param failed  Receives why it was refused, or null to log it. */
	public static function ask(name:String, asking:(granted:Void->Void, refused:String->Void)->Bool, why:String, done:Null<Void->Void>,
			failed:Null<String->Void>):Void {
		if (!asking(answered(done), error -> refuse(name, error, failed)))
			Runtime.later(() -> refuse(name, why, failed));
	}

	/** Returns a call's `done`, which may be omitted, as a function to call.

		@param done  The program's `done`, or null.
		@return  A function calling it, or doing nothing. */
	public static function answered(done:Null<Void->Void>):Void->Void {
		return () -> if (done != null) done();
	}

	/** Returns the `failed` of a call that waits for its answer: why it failed is logged, and the call's answer is `empty`, as raylib's
		call returns its empty value.

		@param name  The call, named when it is logged.
		@param answer  The call's answer.
		@param empty  The value of a call that failed.
		@return  The function receiving why it failed. */
	public static function failing<T>(name:String, answer:T->Void, empty:T):String->Void {
		return error -> {
			refuse(name, error, null);
			answer(empty);
		};
	}

	/** Returns the `failed` of a call that waits and has no value: why it failed is logged, and the call ends.

		@param name  The call, named when it is logged.
		@param answer  Ends the call.
		@return  The function receiving why it failed. */
	public static function ended(name:String, answer:Void->Void):String->Void {
		return error -> {
			refuse(name, error, null);
			answer();
		};
	}

	/** Answers a load, a request or a write that failed: to the program's `failed`, or logged. Every error names the file, as the services'
		do.

		@param name  The call, named when it is logged.
		@param error  Why it failed.
		@param failed  The program's `failed`, or null to log it. */
	public static function refuse(name:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			Runtime.log(4, '$name: $error');
	}
}
#end
