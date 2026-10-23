import helix.adapter.audio.sdl3.Sdl3AudioAdapter;
import helix.adapter.audiodecoder.libsndfile.LibsndfileAudioDecoderAdapter;
import helix.adapter.audiodecoder.libsndfile.LibsndfilePcmFiles;
import helix.adapter.http.haxehttp.HaxeHttpAdapter;
import helix.adapter.shared.MixerBridge;
import helix.adapter.store.filesystem.FileSystemStoreAdapter;
import helix.asset.AssetService;
import helix.asset.FetchService;
import helix.asset.FetchResult;
import helix.asset.GrowingSource;
import helix.asset.IAssets;
import helix.asset.StorageService;
import helix.asset.StorageResult;
import helix.asset.StorageWriteResult;
import helix.asset.StorageSourceResult;
import helix.audio.AudioDecoding;
import helix.audio.AudioPlayback;
import helix.audio.AudioResources;

/** Native network streaming (tests/streaming/streaming_test.py serves the files slowly, 32 KiB each 100 ms, the Ogg 4 KiB): a remote stream located through the
	asset service plays while it downloads, to its end, and is kept in the cache; one without a Content-Length is answered whole; one the server
	drops halfway ends its voice and is logged. Args: the server's URL, the cache directory. Played through SDL3's dummy driver (no sound): its
	device thread pulls the mixer in real time, as a device would. Prints one JSON line. */
@:access(helix)
class StreamingTests {
	static var checks = 0;
	static var logged:Array<String> = [];
	static var assets:AssetService;
	static var backend:Sdl3AudioAdapter;
	static var audio:AudioResources;
	static var decoding:AudioDecoding;
	static var steps:Array<Void->Void> = [];
	// What runs each poll until the step it belongs to moves on.
	static var watch:Null<Void->Void> = null;
	static var finished = false;
	static var report:Dynamic = {};

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function next():Void {
		watch = null;
		if (steps.length > 0)
			steps.shift()();
		else
			finished = true;
	}

	// The download of path, answered as Downloading (fails otherwise).
	static function download(path:String, then:GrowingSource->Void):Void
		assets.streamSource(path, location -> switch location {
			case Downloading(source): then(source);
			case _: throw '$path was not answered as a download: $location';
		}, message -> throw '$path failed: $message', true);

	// Runs then once the assets are idle: the download ended and was kept (or failed).
	static function idle(then:Void->Void):Void
		watch = () -> if (!assets.busy) {
			watch = null;
			then();
		};

	// Whether voice is playing with decoded samples in its ring.
	static function sounding(voice:Int):Bool
		return backend.isPlaying(voice) && MixerBridge.audioStreamQueued(voice) > 0;

	// Opens source on the backend and starts it: its stream and voice.
	static function play(source:GrowingSource, then:(Int, Int) -> Void):Void
		backend.openStream(Downloading(source), result -> switch result {
			case Opened(stream):
				var voice = backend.playStream(stream, false, 1);
				check(voice > 0, "A download's voice starts");
				then(stream, voice);
			case Failed(message): throw 'A download did not open: $message';
		});

	// Locates path again: the copy kept in the cache, without a request.
	static function kept(path:String, then:Void->Void):Void
		assets.streamSource(path, location -> switch location {
			case Stored(lease):
				lease.release();
				check(true, '$path is kept: the next play is local');
				then();
			case _: throw '$path was not kept: $location';
		}, message -> throw '$path failed: $message', true);

	static function main():Void {
		haxe.Log.trace = (value, ?infos) -> logged.push(Std.string(value));
		var args = Sys.args(), base = args[0];
		assets = new AssetService(new FetchService(new HaxeHttpAdapter()), new StorageService(new FileSystemStoreAdapter(args[1])),
			new StorageService(new FileSystemStoreAdapter(args[1] + "-unused"), true), base + "/assets/");
		backend = new Sdl3AudioAdapter(new LibsndfilePcmFiles());
		decoding = new AudioDecoding(new LibsndfileAudioDecoderAdapter());
		audio = new AudioResources(assets, backend, decoding);
		steps = [
			() -> {
				check(backend.available && !backend.playsUrls, "The output runs (SDL3's dummy driver) and plays no URL");
				next();
			},
			// A WAV, three seconds: playing before its last byte arrives, to its end, then kept.
			() -> download("slow.wav", source -> {
				check(!source.done && source.received < source.total, "A remote stream is answered before it's whole");
				play(source, (stream, voice) -> {
					var started = 0., at = 0;
					watch = () -> {
						if (started == 0 && sounding(voice)) {
							started = Sys.time();
							at = source.received;
							check(at < source.total, "slow.wav plays before the last byte arrives");
						}
						if (!backend.isPlaying(voice)) {
							var played = Sys.time() - started;
							check(started > 0 && source.done && played > 2.7, 'slow.wav plays to its end (${played} s of 3)');
							report.wav = {
								startedAt: started,
								receivedAtStart: at,
								total: source.total,
								played: played
							};
							backend.destroyStream(stream);
							idle(() -> kept("slow.wav", next));
						}
					};
				});
			}),
			// Ogg Vorbis, ten seconds at twice the speed, through the audio resources as a game plays it: opened before its end, its length
			// unknown, it plays to the end of its stream.
			() -> audio.loadStream("slow.ogg", stream -> {
				var playback = audio.play(stream, false, 1);
				playback.pitch = 2;
				stream.release();
				var started = 0.;
				watch = () -> {
					if (started == 0 && sounding(playback.id)) {
						started = Sys.time();
						report.ogg = {startedAt: started};
					}
					if (playback.finished) {
						var played = Sys.time() - started;
						check(started > 0 && played > 4.5, 'slow.ogg plays to its end (${played} s of 5)');
						report.ogg.played = played;
						idle(() -> kept("slow.ogg", next));
					}
				};
			}, message -> throw 'slow.ogg failed: $message'),
			// No Content-Length: answered once whole.
			() -> download("whole.wav", source -> {
				check(source.done && source.received == source.total && source.total > 0, "Without a Content-Length, answered whole");
				play(source, (stream, voice) -> {
					backend.destroyStream(stream);
					idle(() -> kept("whole.wav", next));
				});
			}),
			// Dropped after 96 KiB: the voice plays what came, ends, and the failure is logged; nothing is kept.
			() -> download("dropped.wav", source -> {
				var opened = Sys.time();
				play(source, (stream, voice) -> {
					watch = () -> if (!backend.isPlaying(voice)) {
						var played = Sys.time() - opened;
						check(source.failure != null && !source.done && played < 2.5, 'A dropped download ends its voice early (${played} s)');
						check(Lambda.exists(logged, line -> line.indexOf("dropped.wav") >= 0), "and the failure is logged with the path");
						report.dropped = {received: source.received, total: source.total, failure: source.failure};
						backend.destroyStream(stream);
						idle(() -> download("dropped.wav", again -> {
							check(true, "and nothing was kept: it downloads again");
							idle(next);
						}));
					};
				});
			})
		];
		var started = haxe.Timer.stamp(), last = started;
		try {
			next();
			while (!finished) {
				var now = haxe.Timer.stamp();
				assets.poll();
				decoding.poll();
				audio.poll(now - last);
				last = now;
				if (watch != null)
					watch();
				if (now - started > 60)
					throw "Streaming test timeout";
				Sys.sleep(.005);
			}
			audio.shutdown();
			backend.shutdown();
			assets.shutdown();
			report.passed = true;
			report.checks = checks;
			Sys.println(haxe.Json.stringify(report));
		} catch (error:Dynamic) {
			Sys.println(haxe.Json.stringify({passed: false, error: Std.string(error), logged: logged}));
			Sys.exit(1);
		}
	}
}
