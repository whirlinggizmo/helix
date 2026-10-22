package helix.assets;

import haxe.io.Bytes;

/** The game's saves: text by name (JSON, as haxe.Json writes it, or anything), kept apart from the asset cache, which a game may clear: in the
	user's data directory natively (the profile's, by the game's identity), an IndexedDB database of its own in a browser. A name is an asset
	path ("progress", "slots/2.json"); a save is at most 8 MiB. Reads, writes and removals complete in the order asked. A save is kept once written runs: quitting before it
	may lose it, so a game saves at a checkpoint, not as it quits. */
@:build(helix.macro.Facade.record())
class SaveService {
	var storage:StorageService;
	var pending = 0;

	// The program's saves, opened at their first use and closed at the end; Saves installs them, so a program that saves nothing opens no store.

	@:allow(helix.assets.Saves)
	static function install():SaveService {
		return helix.host.Host.installPart(runner -> {
			var service = new SaveService(runner.platform.saves());
			runner.install({
				poll: service.poll,
				busy: () -> service.busy,
				shutdown: () -> {
					service.shutdown();
					Saves.bind(null);
				}
			});
			service;
		});
	}

	/** Saves in store, one operation at a time, so they complete in the order asked: a later write of a save is the one kept. */
	public function new(store:IStore)
		storage = new StorageService(store, false, 1);

	/** Whether a read, write or removal hasn't completed yet. */
	public var busy(get, never):Bool;

	function get_busy():Bool
		return pending > 0;

	/** Reads the save named name: loaded gets its text, missing runs when there is none (else loaded isn't called), failed (else the log)
		for a name that isn't an asset path or a store that fails. None runs once the request is cancelled. */
	public function read(name:String, loaded:String->Void, ?missing:Void->Void, ?failed:String->Void):IRequest {
		pending++;
		return storage.read(name, result -> {
			pending--;
			switch result {
				case Stored(bytes): loaded(bytes.toString());
				case Missing: if (missing != null) missing();
				case Failed(message): Failure.report(name, Failure.named(name, message), failed);
				case Cancelled:
			}
		});
	}

	/** Writes text as the save named name, in place of what it was: written runs once it's kept, failed (else the log) for a name that isn't
		an asset path, text over 8 MiB or a store that fails. */
	public function write(name:String, text:String, ?written:Void->Void, ?failed:String->Void):IRequest {
		pending++;
		return storage.write(name, Bytes.ofString(text), result -> {
			pending--;
			switch result {
				case Written: if (written != null) written();
				case Failed(message): Failure.report(name, Failure.named(name, message), failed);
				case Cancelled:
			}
		});
	}

	/** Removes the save named name (none is no failure): removed runs once it's gone, failed (else the log) for a name that isn't an asset
		path or a store that fails. */
	public function remove(name:String, ?removed:Void->Void, ?failed:String->Void):IRequest {
		pending++;
		return storage.remove(name, result -> {
			pending--;
			switch result {
				case Written: if (removed != null) removed();
				case Failed(message): Failure.report(name, Failure.named(name, message), failed);
				case Cancelled:
			}
		});
	}

	/** Delivers what completed. The runner calls it each frame; a program without one (a test) calls it itself. */
	public function poll():Void
		storage.poll();

	/** Cancels what hasn't completed and closes the store. */
	public function shutdown():Void
		storage.shutdown();
}
