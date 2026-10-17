package helix.scene;

import helix.assets.IRequest;
import helix.audio.AudioClip;
import helix.audio.AudioResources.AudioLoadResult;
import helix.audio.AudioStream;
import helix.host.Services;
import helix.render2d.Textures.TextureLoadResult;
import helix.render3d.Environments.EnvironmentLoadResult;
import helix.render3d.ModelFile;
import helix.render3d.Models;
import helix.render3d.Models.ModelLoadResult;

/** A group of loads with one progress: a scene's files gathered so a loading screen shows how far they are (getProgress, from how many
	have ended) and the scene starts once they're done (isDone), with what failed by name (getFailures). Each load goes through the service
	it always did, its own callback kept; the loader only counts. wrap counts any other load the game makes. Nothing here cancels: a scene
	that exits early cancels its own requests. */
class Loader {
	var total = 0;
	var done = 0;
	var failures:Array<String> = [];

	/** No loads yet: done, at progress 1. */
	public function new() {}

	/** How many loads were added. */
	public function getCount():Int
		return total;

	/** How many have ended, failed ones included. */
	public function getDoneCount():Int
		return done;

	/** How far along, 0 to 1 (1 with nothing to load). */
	public function getProgress():Float
		return total == 0 ? 1 : done / total;

	/** Whether every load has ended. */
	public function isDone():Bool
		return done >= total;

	/** What failed, each as its name and the reason. */
	public function getFailures():Array<String>
		return failures.copy();

	/** Counts a load the game makes itself: wrap its completion, naming it; failed gives the reason for a result that failed, or null. */
	public function wrap<T>(name:String, complete:T->Void, failed:T->Null<String>):T->Void {
		total++;
		return result -> {
			done++;
			var reason = failed(result);
			if (reason != null)
				failures.push('$name: $reason');
			complete(result);
		};
	}

	/** An asset's bytes through Services.assets. */
	public function asset(path:String, complete:helix.assets.IAssets.AssetResult->Void):IRequest
		return Services.assets.ensure(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A texture through Services.textures (linear: not sRGB, for data such as normal maps). */
	public function texture(path:String, linear:Bool, complete:TextureLoadResult->Void):IRequest
		return Services.textures.load(path, linear, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A sound clip through Services.audioResources. */
	public function clip(path:String, complete:AudioLoadResult<AudioClip>->Void):IRequest
		return Services.audioResources.loadClip(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A sound stream through Services.audioResources. */
	public function stream(path:String, complete:AudioLoadResult<AudioStream>->Void):IRequest
		return Services.audioResources.loadStream(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** An environment through Services.environments (ready once it's prepared). */
	public function environment(path:String, complete:EnvironmentLoadResult->Void):IRequest
		return Services.environments.load(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));

	/** A model file through models (a game's Models over the services). */
	public function model(models:Models, path:String, complete:ModelLoadResult->Void):IRequest
		return models.load(path, wrap(path, complete, r -> switch r {
			case Failed(message): message;
			case Cancelled: "cancelled";
			case _: null;
		}));
}
