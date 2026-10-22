import haxe.io.Bytes;
import helix.asset.IStore;
import helix.asset.SaveService;
import helix.asset.StorageService;

/** A store in memory that, given several operations at once, finishes the latest first, as threads writing files may. */
private class Unruly implements IStore {
	public var files:Map<String, Bytes> = [];
	public var mostAtOnce = 0;

	var pending:Array<Void->Void> = [];

	public function new() {}

	function queue(f:Void->Void):Void {
		pending.push(f);
		mostAtOnce = pending.length > mostAtOnce ? pending.length : mostAtOnce;
	}

	public function read(key:String, maxBytes:Int, done:StorageResult->Void):Void
		queue(() -> done(files.exists(key) ? Stored(files[key]) : Missing));

	public function write(key:String, bytes:Bytes, done:StorageWriteResult->Void):Void
		queue(() -> {
			files[key] = bytes;
			done(Written);
		});

	public function remove(key:String, done:StorageWriteResult->Void):Void
		queue(() -> {
			files.remove(key);
			done(Written);
		});

	public function clear(done:StorageWriteResult->Void):Void
		queue(() -> {
			files.clear();
			done(Written);
		});

	public function lease(key:String, done:StorageSourceResult->Void):Void
		queue(() -> done(Missing));

	public function poll():Void {
		var now = pending;
		pending = [];
		now.reverse();
		for (f in now)
			f();
	}

	public function shutdown():Void {}
}

/** Saves (helix.asset.SaveService): text written, read back, missing, removed; one operation at a time, so a later write of a save is the one
	kept on a store that would finish them out of order; a name that isn't an asset path refused; busy while any is under way. */
class SaveTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function settle(saves:SaveService):Void
		for (_ in 0...20)
			saves.poll();

	static function main():Void {
		var store = new Unruly(), saves = new SaveService(store);
		var order:Array<String> = [];
		saves.write("progress", '{"level":1}', () -> order.push("first"));
		saves.write("progress", '{"level":2}', () -> order.push("second"));
		check(saves.busy, "Busy while a write is under way");
		settle(saves);
		check(!saves.busy && order.join(",") == "first,second" && store.mostAtOnce == 1, "One at a time, completing in the order asked");
		var text:Null<String> = null;
		saves.read("progress", loaded -> text = loaded);
		settle(saves);
		check(text == '{"level":2}' && haxe.Json.parse(text).level == 2, "The later write is the one kept, read back as written");
		var missing = false, loadedMissing = false;
		saves.read("slots/9.json", _ -> loadedMissing = true, () -> missing = true);
		settle(saves);
		check(missing && !loadedMissing, "A save there isn't is missing, not loaded");
		var removed = false;
		saves.remove("progress", () -> removed = true);
		settle(saves);
		check(removed && !store.files.exists("progress"), "Removed");
		var failure:Null<String> = null;
		saves.write("../escape", "x", () -> {}, message -> failure = message);
		settle(saves);
		check(failure != null && failure.indexOf("../escape") >= 0, "A name that isn't an asset path is refused, named");
		var cancelled = true;
		var request = saves.write("late", "x", () -> cancelled = false);
		request.cancel();
		settle(saves);
		check(cancelled && !saves.busy, "A cancelled write runs nothing");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
