package helix.scene;

import helix.assets.IRequest;
import helix.audio.AudioClip;
import helix.audio.AudioResources.AudioLoadResult;
import helix.audio.AudioStream;
import helix.assets.Assets;
import helix.audio.Audio;
import helix.render2d.Textures;
import helix.render3d.Environments;
import helix.render2d.TextureCache.TextureLoadResult;
import helix.render3d.EnvironmentCache.EnvironmentLoadResult;
import helix.render3d.ModelFile;
import helix.render3d.ModelCache;
import helix.render3d.ModelCache.ModelLoadResult;

/** A group of loads with one progress: a scene's files gathered so a loading screen shows how far they are (progress, from how many
	have ended) and the scene starts once they're done (done), with what failed by name (failures). Each load goes through the service
	it always did, its own callback kept; the loader only counts. wrap counts any other load the game makes. Nothing here cancels: a scene
	that exits early cancels its own requests. */
class Loader {
	var total = 0;
	var finished = 0;
	var failureList:Array<String> = [];

	/** No loads yet: done, at progress 1. */
	public function new() {}

	/** How many loads were added. */
	public var count(get, never):Int;

	function get_count():Int
		return total;

	/** How many have ended, failed ones included. */
	public var doneCount(get, never):Int;

	function get_doneCount():Int
		return finished;

	/** How far along, 0 to 1 (1 with nothing to load). */
	public var progress(get, never):Float;

	function get_progress():Float
		return total == 0 ? 1 : finished / total;

	/** Whether every load has ended. */
	public var done(get, never):Bool;

	function get_done():Bool
		return finished >= total;

	/** What failed, each as its name and the reason. */
	public var failures(get, never):Array<String>;

	function get_failures():Array<String>
		return failureList.copy();

	/** Counts a load the game makes itself: wrap its completion, naming it; failed gives the reason for a result that failed, or null. */
	public function wrap<T>(name:String, complete:T->Void, failed:T->Null<String>):T->Void {
		total++;
		return result -> {
			finished++;
			var reason = failed(result);
			if (reason != null)
				failureList.push('$name: $reason');
			complete(result);
		};
	}

	/** An asset's bytes through Assets. */
	public function asset(path:String, complete:helix.assets.IAssets.AssetResult->Void):IRequest
		return Assets.ensure(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A texture through Textures (linear: not sRGB, for data such as normal maps). */
	public function texture(path:String, linear:Bool, complete:TextureLoadResult->Void):IRequest
		return Textures.load(path, linear, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A sound clip through Audio. */
	public function clip(path:String, complete:AudioLoadResult<AudioClip>->Void):IRequest
		return Audio.loadClip(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A sound stream through Audio. */
	public function stream(path:String, complete:AudioLoadResult<AudioStream>->Void):IRequest
		return Audio.loadStream(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** An environment through Environments (ready once it's prepared). */
	public function environment(path:String, complete:EnvironmentLoadResult->Void):IRequest
		return Environments.load(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A model file through models (Models.instance, or a ModelCache of the test's). */
	public function model(models:ModelCache, path:String, complete:ModelLoadResult->Void):IRequest
		return models.load(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));
}
