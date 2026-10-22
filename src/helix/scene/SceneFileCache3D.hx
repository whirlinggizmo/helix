package helix.scene;

import helix.assets.Failure;
import helix.assets.IAssets;
import helix.assets.IRequest;
import helix.assets.Request;

/** Scene files (.scene3d) loaded through the assets into SceneFiles3D, parsed once and shared by path, as ModelCache is for models: a path
	asked for again is the file already parsed (or its refusal, remembered), and asking while it loads joins the load. A file's models,
	prefabs, textures and environments are loaded through their own caches as the file is instantiated, so a level's models aren't fetched
	twice. The runner's is what the SceneFiles3D static forwards to. */
@:build(helix.macro.Facade.record())
class SceneFileCache3D {
	var assets:IAssets;
	var files:Map<String, SceneFile3D> = [];
	var failures:Map<String, String> = [];
	var waiting:Map<String, Array<{request:Request, loaded:SceneFile3D->Void, failed:Null<String->Void>}>> = [];
	var loads:Map<String, IRequest> = [];

	/** Loads through assets. */
	public function new(assets:IAssets) {
		this.assets = assets;
	}

	/** Loads path (a .scene3d) into a SceneFile3D, parsed with SceneFile3D.parse under its path. One of loaded or failed runs once: during this
		call when the file is loaded already (or failed before; forget clears a failure), else on the host thread when its load ends; failed
		(else the log, with the path) for a load failure or a file the parser refuses, with its reason (each problem the parser found is
		logged as well). Neither runs once the request is cancelled (the shared load goes on for the others) or the cache shuts down. */
	public function load(path:String, loaded:SceneFile3D->Void, ?failed:String->Void):IRequest {
		var settled = new Request(() -> {});
		if (files.exists(path)) {
			settled.finish();
			loaded(files[path]);
			return settled;
		}
		if (failures.exists(path)) {
			settled.finish();
			Failure.report(path, failures[path], failed);
			return settled;
		}
		var request:Request = null;
		request = new Request(() -> {
			var callers = waiting[path];
			if (callers != null)
				for (caller in callers.copy())
					if (caller.request == request)
						callers.remove(caller);
		});
		var caller = {request: request, loaded: loaded, failed: failed};
		if (waiting.exists(path)) {
			waiting[path].push(caller);
			return request;
		}
		waiting[path] = [caller];
		var read:Request = null;
		function done(file:Null<SceneFile3D>, message:Null<String>):Void {
			loads.remove(path);
			if (file != null)
				files[path] = file;
			else if (message != null)
				failures[path] = message;
			var callers = waiting[path];
			waiting.remove(path);
			if (callers != null)
				for (caller in callers)
					if (caller.request.finish())
						if (file != null)
							caller.loaded(file);
						else if (message != null)
							Failure.report(path, message, caller.failed);
		}
		var loading:IRequest = null;
		read = new Request(() -> {
			if (loading != null)
				loading.cancel();
			done(null, null);
		});
		loading = assets.load(path, bytes -> {
			if (read.settled)
				return;
			var file = SceneFile3D.parse(bytes, path);
			if (read.finish())
				done(file, file == null ? Failure.named(path, "the parser refused it (its problems are logged)") : null);
		}, message -> if (read.finish()) done(null, Failure.named(path, message)));
		if (!read.settled)
			loads[path] = read;
		return request;
	}

	/** The file at path if it's loaded, else null. */
	public function find(path:String):Null<SceneFile3D>
		return files[path];

	/** Whether path is loaded. */
	public function isLoaded(path:String):Bool
		return files.exists(path);

	/** Whether path is loading. */
	public function isLoading(path:String):Bool
		return waiting.exists(path);

	/** How many files are loading. */
	public var loadingCount(get, never):Int;

	function get_loadingCount():Int {
		var n = 0;
		for (_ in waiting)
			n++;
		return n;
	}

	/** Adds a file parsed some other way under path, as if loaded from there (a test's, a generated one). */
	public function put(path:String, file:SceneFile3D):Void {
		files[path] = file;
		failures.remove(path);
	}

	/** Forgets path: its file (the instances made from it stay) or its failure, so it's loaded again when next asked for. */
	public function forget(path:String):Void {
		files.remove(path);
		failures.remove(path);
	}

	/** Cancels every load (telling none of its callers) and forgets every file. */
	public function shutdown():Void {
		for (load in [for (l in loads) l])
			load.cancel();
		files.clear();
		failures.clear();
	}
}
