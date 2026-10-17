package helix.render3d;

import helix.assets.IRequest;
import helix.render3d.Models.ModelLoadResult;

/** Part files (gear, clothing, held items) loaded once and shared by every character wearing them (Outfit): a file asked for again is the one
	already loaded, and asking while it loads waits on the same load. Each Outfit instantiates its own copy of a file's nodes, so characters
	share meshes, materials and textures but not nodes. */
class Wardrobe {
	var load:(String, ModelLoadResult->Void) -> IRequest;
	var files:Map<String, ModelFile> = [];
	var failures:Map<String, String> = [];
	var waiting:Map<String, Array<ModelLoadResult->Void>> = [];
	var loads:Map<String, IRequest> = [];

	/** Loads parts through load: a model loader's (Models.load), or any that answers the same way. */
	public function new(load:(String, ModelLoadResult->Void) -> IRequest)
		this.load = load;

	/** The file at path: during this call when it's loaded (or failed before), else on the host thread when its load ends. complete runs
		exactly once: Ready, Failed (a failure is remembered, so asking again fails at once; forget clears it), or Cancelled when the wardrobe
		is closed. */
	public function get(path:String, complete:ModelLoadResult->Void):Void {
		if (files.exists(path)) {
			complete(Ready(files[path]));
			return;
		}
		if (failures.exists(path)) {
			complete(Failed(failures[path]));
			return;
		}
		if (waiting.exists(path)) {
			waiting[path].push(complete);
			return;
		}
		waiting[path] = [complete];
		loads[path] = load(path, result -> {
			loads.remove(path);
			switch result {
				case Ready(file): files[path] = file;
				case Failed(message): failures[path] = message;
				case Cancelled:
			}
			var callers = waiting[path];
			waiting.remove(path);
			if (callers != null)
				for (caller in callers)
					caller(result);
		});
	}

	/** The file at path if it's loaded, else null. */
	public function find(path:String):Null<ModelFile>
		return files[path];

	/** Whether path is loaded. */
	public function isLoaded(path:String):Bool
		return files.exists(path);

	/** Whether path is loading. */
	public function isLoading(path:String):Bool
		return waiting.exists(path);

	/** How many files are loading. */
	public function getLoadingCount():Int {
		var n = 0;
		for (_ in waiting)
			n++;
		return n;
	}

	/** Adds a file loaded some other way under path, as if loaded from there. */
	public function put(path:String, file:ModelFile):Void {
		files[path] = file;
		failures.remove(path);
	}

	/** Forgets path: its file (the characters wearing it keep their copies) or its failure, so it's loaded again when next asked for. */
	public function forget(path:String):Void {
		files.remove(path);
		failures.remove(path);
	}

	/** Cancels every load (each waiting caller gets Cancelled) and forgets every file. */
	public function close():Void {
		for (load in [for (l in loads) l])
			load.cancel();
		files.clear();
		failures.clear();
	}
}
