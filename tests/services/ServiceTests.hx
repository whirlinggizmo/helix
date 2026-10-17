import helix.assets.FetchService;
import helix.assets.StorageService;
import helix.assets.IAssets;
import helix.assets.AssetService;
import helix.audio.AudioResources;
import helix.audio.AudioClip;
import helix.audio.AudioStream;
import helix.audio.AudioPlayback;
import haxe.io.Bytes;

/** Same asynchronous behavior checks run under JS/browser and hxcpp/native. */
class ServiceTests {
	static var checks = 0;
	static var env:ServiceEnvironment;
	static var fetcher:FetchService;
	static var storage:StorageService;
	static var assets:AssetService;
	static var audio:AudioResources;
	static var decoding:helix.audio.AudioDecoding;
	static var steps:Array<Void->Void> = [];
	static var finished = false;
	static var delay = 0.;
	static var delayed:Void->Void;
	// The test server's /bytes and /concurrent body, 128 KiB (tools/services.py's BODY_BYTES).
	static inline var BODY_BYTES = 128 * 1024;
	static var persisted = false;
	static var clip:AudioClip;
	static var stream:AudioStream;
	static var playback:AudioPlayback;
	static var secondPlayback:AudioPlayback;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function next():Void {
		if (steps.length > 0)
			steps.shift()();
		else
			finished = true;
	}

	static function wait(seconds:Float, then:Void->Void):Void {
		delay = haxe.Timer.stamp() + seconds;
		delayed = then;
	}

	static function fail(value:Dynamic):Void
		throw Std.string(value);

	static function main():Void {
		env = new ServiceEnvironment();
		fetcher = new FetchService(env.fetcher);
		storage = new StorageService(env.storage);
		assets = new AssetService(fetcher, storage, new StorageService(env.packaged, true), env.base + "/assets/");
		decoding = new helix.audio.AudioDecoding(env.decoder);
		audio = new AudioResources(assets, env.audio, decoding);
		steps = [
			() -> {
				var returned = false;
				// Progress reports come coalesced between polls, as many as the bytes' arrival makes: kept, and checked once at completion,
				// so the run's count of checks is the same every time.
				var progress:Array<{receivedBytes:Int, totalBytes:Null<Int>}> = [];
				fetcher.fetch({url: env.base + "/bytes"}, result -> {
					check(returned, "Fetch completed synchronously");
					switch result {
						case Response(value): check(value.status == 200 && value.bytes.length == BODY_BYTES, "Whole response bytes/status");
						case _: fail(result);
					}
					var ordered = true, last = 0;
					for (p in progress) {
						ordered = ordered
							&& p.receivedBytes >= last
							&& p.receivedBytes <= BODY_BYTES
							&& (p.totalBytes == null || p.totalBytes == BODY_BYTES);
						last = p.receivedBytes;
					}
					check(ordered, "Byte progress within the body's size, never going back");
					next();
				},
					value -> progress.push({receivedBytes: value.receivedBytes, totalBytes: value.totalBytes}));
				returned = true;
			},
			() -> {
				var pending = 3;
				for (_ in 0...3)
					fetcher.fetch({url: env.base + "/concurrent"}, result -> {
						switch result {
							case Response(value): check(value.bytes.length == BODY_BYTES, "Concurrent bounded downloads finish");
							case _: fail(result);
						}
						if (--pending == 0)
							next();
					});
			},
			() -> fetcher.fetch({url: env.base + "/missing"}, result -> {
				switch result {
					case Response(value): check(value.status == 404, "HTTP error status is a response");
					case _: fail(result);
				}
				next();
			}),
			() -> fetcher.fetch({url: env.base + "/bytes", maxBytes: 100}, result -> {
				switch result {
					case Failed(message): check(message.indexOf("limit") >= 0, "Byte limit rejects overflow");
					case _: fail(result);
				}
				next();
			}),
			() -> fetcher.fetch({url: env.base + "/stall", timeoutSeconds: .05}, result -> {
				switch result {
					case Failed(_): check(true, "Timeout");
					case _: fail(result);
				}
				next();
			}),
			() -> {
				var callbacks = 0, request = fetcher.fetch({url: env.base + "/stall"}, result -> {
					callbacks++;
					switch result {
						case Cancelled: check(true, "Cancelled fetch");
						case _: fail(result);
					}
				});
				request.cancel();
				request.cancel();
				wait(.1, () -> {
					check(callbacks == 1, "Cancellation completes exactly once");
					next();
				});
			},
			() -> storage.read("marker", result -> {
				switch result {
					case Stored(bytes):
						persisted = true;
						check(bytes.toString() == "persisted", "Persistent storage content");
					case Missing: check(true, "Initially empty storage");
					case _: fail(result);
				}
				storage.write("marker", Bytes.ofString("persisted"), result -> {
					switch result {
						case Written: check(true, "Committed storage write");
						case _: fail(result);
					}
					next();
				});
			}),
			() -> storage.read("../escape", result -> {
				switch result {
					case Failed(_): check(true, "Storage rejects escaping path");
					case _: fail(result);
				}
				next();
			}),
			() -> storage.write("remove-me", Bytes.ofString("temporary"), result -> {
				switch result {
					case Written: storage.remove("remove-me", result -> {
							switch result {
								case Written: storage.read("remove-me", result -> {
										switch result {
											case Missing: check(true, "Removed storage entry");
											case _: fail(result);
										}
										next();
									});
								case _: fail(result);
							}
						});
					case _: fail(result);
				}
			}),
			() -> assets.streamSource("uncached.wav", location -> {
				switch location {
					case Remote(url): check(url == env.base + "/assets/uncached.wav", "Uncached stream resolves remotely without ensuring");
					case _: fail(location);
				}
				next();
			}, message -> fail(message)),
			() -> audio.loadStream("uncached.wav", value -> {
				if (!env.remoteStreams)
					fail("A remote stream opened natively");
				var playing = audio.play(value);
				value.release();
				check(playing.id > 0, "Browser remote stream starts without ensure");
				wait(.6, () -> {
					check(playing.finished && value.disposed, "Remote playback finishes");
					assets.streamSource("uncached.wav", source -> {
						switch source {
							case Remote(_): check(true, "Remote playback did not persist audio");
							case _: fail(source);
						}
						next();
					}, message -> fail(message));
				});
			}, message -> {
				if (env.remoteStreams)
					fail(message);
				check(message.indexOf("ensure") >= 0, "Native remote stream capability is explicit");
				next();
			}),
			() -> assets.ensure("fixture.wav", bytes -> {
				check(bytes.getString(0, 4) == "RIFF", "Ensured encoded audio asset");
				next();
			}, message -> fail(message)),
			() -> assets.ensure("fixture.wav", bytes -> {
				check(bytes.getString(0, 4) == "RIFF" && bytes.getInt32(4) == bytes.length - 8,
					"Second ensure reads stored copy: "
					+ bytes.length
					+ "/"
					+ bytes.getInt32(4));
				next();
			},
				message -> fail(message)),
			// The host answers this one's ETag with 304 on the second visit (tools/services.py counts it): the copy kept.
			() -> assets.ensure("revalidated.wav", bytes -> {
				check(bytes.getString(0, 4) == "RIFF", "A revalidated asset loads, kept or downloaded");
				next();
			}, message -> fail(message)),
			() -> assets.streamSource("fixture.wav", location -> {
				switch location {
					case Stored(value):
						check(value.location != env.base + "/assets/fixture.wav", "Stream prefers stored copy");
						value.release();
					case _: fail(location);
				}
				next();
			}, message -> fail(message)),
			() -> audio.loadClip("fixture.wav", value -> {
				clip = value;
				playback = audio.play(clip, true, .5);
				check(playback.id > 0, "Clip playback starts");
				secondPlayback = audio.play(clip, true, .2);
				check(secondPlayback.id > 0 && secondPlayback.id != playback.id, "Shared clip supports independent playbacks");
				clip.release();
				check(!clip.disposed, "Active playback retains released resource");
				playback.pause();
				playback.volume = .25;
				wait(.1, () -> {
					check(!playback.finished, "Paused playback remains alive");
					playback.resume();
					wait(.05, () -> {
						playback.stop();
						check(!clip.disposed && !secondPlayback.finished, "Stopping one playback retains shared resource");
						secondPlayback.stop();
						check(clip.disposed, "Stop releases final resource reference");
						var rejected = false;
						try {
							audio.play(clip);
						} catch (_:Dynamic) {
							rejected = true;
						}
						check(rejected, "Released resource cannot start another playback");
						next();
					});
				});
			}, message -> fail(message)),
			() -> audio.loadStream("fixture.wav", value -> {
				stream = value;
				playback = audio.play(stream, true, .4);
				check(playback.id > 0, "Stored stream playback starts");
				stream.release();
				playback.pause();
				check(!stream.disposed, "Paused stream retains source lease");
				wait(.1, () -> {
					playback.resume();
					wait(.1, () -> {
						playback.stop();
						check(stream.disposed, "Stopped stream releases source lease");
						next();
					});
				});
			}, message -> fail(message)),
			() -> audio.loadStream("fixture.wav", value -> {
				stream = value;
				playback = audio.play(stream);
				stream.release();
				wait(.6, () -> {
					check(playback.finished && stream.disposed, "Natural stream finish releases resource");
					next();
				});
			}, message -> fail(message)),
			() -> {
				var callbacks = 0;
				var request = fetcher.fetch({url: env.base + "/stall"}, result -> {
					callbacks++;
					switch result {
						case Cancelled: check(true, "Shutdown cancels pending transfer");
						case _: fail(result);
					}
				});
				fetcher.poll();
				fetcher.shutdown();
				wait(.65, () -> {
					check(callbacks == 1, "Late transport completion is suppressed");
					audio.shutdown();
					assets.shutdown();
					env.audio.shutdown();
					next();
				});
			}
		];
		for (format in ["ogg", "opus"]) {
			var extension = format, path = "fixture." + format;
			var codecSteps:Array<Void->Void> = [
				() -> assets.ensure(path, bytes -> decoding.decode(bytes, result -> {
					switch result {
						case Decoded(samples):
							helix.audio.Pcm.validate(samples);
							check(samples.length > 4000 * 4 && samples.length < 7000 * 4, "Ogg duration/rate normalization: " + extension);
							var peak = 0.;
							for (i in 0...Std.int(samples.length / 4))
								peak = Math.max(peak, Math.abs(samples.getFloat(i * 4)));
							check(peak > .02, "Ogg decode contains signal: " + extension);
							next();
						case _: fail(result);
					}
				}), message -> fail(message)),
				() -> audio.loadClip(path, value -> {
					clip = value;
					playback = audio.play(clip, true, .4);
					check(playback.id > 0, "Ogg clip plays: " + extension);
					clip.release();
					playback.pause();
					wait(.05, () -> {
						check(!playback.finished && !clip.disposed, "Paused Ogg clip retains resource");
						playback.resume();
						wait(.05, () -> {
							playback.stop();
							check(clip.disposed, "Ogg clip final release");
							next();
						});
					});
				}, message -> fail(message)),
				() -> audio.loadStream(path, value -> {
					stream = value;
					playback = audio.play(stream, true, .3);
					check(playback.id > 0, "Stored Ogg stream starts: " + extension);
					stream.release();
					playback.pause();
					wait(.05, () -> {
						check(!stream.disposed, "Paused Ogg source lease");
						playback.resume();
						wait(.2, () -> {
							check(!playback.finished, "Ogg stream loops beyond one duration");
							playback.stop();
							check(stream.disposed, "Stopped Ogg source lease released");
							next();
						});
					});
				}, message -> fail(message)),
				() -> audio.loadStream(path, value -> {
					stream = value;
					playback = audio.play(stream);
					stream.release();
					wait(.6, () -> {
						check(playback.finished && stream.disposed, "Natural Ogg EOF releases resource: " + extension);
						next();
					});
				}, message -> fail(message)),
				() -> audio.loadStream("uncached." + extension, value -> {
					if (!env.remoteStreams)
						fail("A remote Ogg stream opened natively");
					var playing = audio.play(value);
					value.release();
					check(playing.id > 0, "Remote Ogg starts: " + extension);
					wait(.6, () -> {
						check(playing.finished && value.disposed, "Remote Ogg EOF");
						assets.streamSource("uncached." + extension, source -> {
							switch source {
								case Remote(_): check(true, "Remote Ogg did not persist");
								case _: fail(source);
							}
							next();
						}, message -> fail(message));
					});
				}, message -> {
					if (env.remoteStreams)
						fail(message);
					check(message.indexOf("ensure") >= 0, "Native remote Ogg capability explicit");
					next();
				})
			];
			for (step in codecSteps)
				steps.insert(steps.length - 1, step);
		}
		steps.insert(steps.length - 1, () -> audio.loadClip("broken.ogg", clip -> fail(clip), _ -> {
			check(true, "Malformed Ogg fails explicitly");
			next();
		}));
		steps.insert(steps.length - 1, () -> decoding.decode(Bytes.alloc(0), result -> {
			switch result {
				case Failed(_): check(true, "Empty encoded audio fails explicitly");
				case _: fail(result);
			}
			next();
		}));
		steps.insert(steps.length - 1, () -> assets.ensure("fixture.opus", bytes -> {
			var callbacks = 0, request = decoding.decode(bytes, result -> {
				callbacks++;
				switch result {
					case Cancelled: check(true, "Encoded decode cancellation");
					case _: fail(result);
				}
			});
			decoding.poll();
			request.cancel();
			wait(.15, () -> {
				check(callbacks == 1, "Late codec completion suppressed");
				next();
			});
		}, message -> fail(message)));
		next();
		env.start(() -> {
			assets.poll();
			decoding.poll();
			audio.poll();
			if (delayed != null && haxe.Timer.stamp() >= delay) {
				var callback = delayed;
				delayed = null;
				callback();
			}
		}, () -> finished, () -> ({
			passed: true,
			checks: checks,
			persisted: persisted,
			audio: "Lifecycle/output callback checks; no audible-output claim"
		}));
	}
}
