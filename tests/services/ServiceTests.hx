import helix.assets.IFetch;
import helix.assets.IStorage;
import helix.assets.IAssets;
import helix.assets.AssetService;
import helix.audio.AudioResources;
import helix.audio.AudioResources.AudioLoadResult;
import helix.audio.AudioClip;
import helix.audio.AudioStream;
import helix.audio.AudioPlayback;
import haxe.io.Bytes;

/** Same asynchronous behavior checks run under JS/browser and hxcpp/native. */
class ServiceTests {
	static var checks = 0;
	static var env:ServiceEnvironment;
	static var fetcher:helix.assets.IFetch;
	static var assets:AssetService;
	static var audio:AudioResources;
	static var steps:Array<Void->Void> = [];
	static var finished = false;
	static var delay = 0.;
	static var delayed:Void->Void;
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
		fetcher = env.fetcher;
		assets = new AssetService(fetcher, env.storage, env.packaged, env.base + "/assets/");
		audio = new AudioResources(assets, env.audio);
		steps = [
			() -> {
				var returned = false;
				fetcher.fetch({url: env.base + "/bytes"}, result -> {
					check(returned, "Fetch completed synchronously");
					switch result {
						case Response(value): check(value.status == 200 && value.bytes.length == 131072, "Whole response bytes/status");
						case _: fail(result);
					}
					next();
				},
					value -> check(value.received >= 0 && (value.total == null || value.total == 131072), "Byte progress"));
				returned = true;
			},
			() -> {
				var pending = 3;
				for (_ in 0...3)
					fetcher.fetch({url: env.base + "/concurrent"}, result -> {
						switch result {
							case Response(value): check(value.bytes.length == 131072, "Concurrent bounded downloads finish");
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
			() -> env.storage.read("marker", result -> {
				switch result {
					case Stored(bytes):
						persisted = true;
						check(bytes.toString() == "persisted", "Persistent storage content");
					case Missing: check(true, "Initially empty storage");
					case _: fail(result);
				}
				env.storage.write("marker", Bytes.ofString("persisted"), result -> {
					switch result {
						case Written: check(true, "Committed storage write");
						case _: fail(result);
					}
					next();
				});
			}),
			() -> env.storage.read("../escape", result -> {
				switch result {
					case Failed(_): check(true, "Storage rejects escaping path");
					case _: fail(result);
				}
				next();
			}),
			() -> env.storage.write("remove-me", Bytes.ofString("temporary"), result -> {
				switch result {
					case Written: env.storage.remove("remove-me", result -> {
							switch result {
								case Written: env.storage.read("remove-me", result -> {
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
			() -> assets.streamSource("uncached.wav", result -> {
				switch result {
					case Located(Remote(url)): check(url == env.base + "/assets/uncached.wav", "Uncached stream resolves remotely without ensuring");
					case _: fail(result);
				}
				next();
			}),
			() -> audio.loadStream("uncached.wav", result -> {
				if (env.remoteStreams) {
					switch result {
						case Ready(value):
							var playing = audio.play(value);
							value.release();
							check(playing.getId() > 0, "Browser remote stream starts without ensure");
							wait(.6, () -> {
								check(playing.isFinished() && value.isDisposed(), "Remote playback finishes");
								assets.streamSource("uncached.wav", source -> {
									switch source {
										case Located(Remote(_)): check(true, "Remote playback did not persist audio");
										case _: fail(source);
									}
									next();
								});
							});
						case _: fail(result);
					}
				} else {
					switch result {
						case Failed(message): check(message.indexOf("ensure") >= 0, "Native remote stream capability is explicit");
						case _: fail(result);
					}
					next();
				}
			}),
			() -> assets.ensure("fixture.wav", result -> {
				switch result {
					case Loaded(bytes): check(bytes.getString(0, 4) == "RIFF", "Ensured encoded audio asset");
					case _: fail(result);
				}
				next();
			}),
			() -> assets.ensure("fixture.wav", result -> {
				switch result {
					case Loaded(bytes): check(bytes.getString(0, 4) == "RIFF" && bytes.getInt32(4) == bytes.length - 8,
							"Second ensure reads stored copy: "
							+ bytes.length
							+ "/"
							+ bytes.getInt32(4));
					case _: fail(result);
				}
				next();
			}),
			() -> assets.streamSource("fixture.wav", result -> {
				switch result {
					case Located(Stored(value)):
						check(value.location != env.base + "/assets/fixture.wav", "Stream prefers stored copy");
						value.release();
					case _: fail(result);
				}
				next();
			}),
			() -> audio.loadClip("fixture.wav", result -> {
				switch result {
					case Ready(value):
						clip = value;
						playback = audio.play(clip, true, .5);
						check(playback.getId() > 0, "Clip playback starts");
						secondPlayback = audio.play(clip, true, .2);
						check(secondPlayback.getId() > 0
							&& secondPlayback.getId() != playback.getId(), "Shared clip supports independent playbacks");
						clip.release();
						check(!clip.isDisposed(), "Active playback retains released resource");
						playback.pause();
						playback.setVolume(.25);
					case _: fail(result);
				}
				wait(.1, () -> {
					check(!playback.isFinished(), "Paused playback remains alive");
					playback.resume();
					wait(.05, () -> {
						playback.stop();
						check(!clip.isDisposed() && !secondPlayback.isFinished(), "Stopping one playback retains shared resource");
						secondPlayback.stop();
						check(clip.isDisposed(), "Stop releases final resource reference");
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
			}),
			() -> audio.loadStream("fixture.wav", result -> {
				switch result {
					case Ready(value):
						stream = value;
						playback = audio.play(stream, true, .4);
						check(playback.getId() > 0, "Stored stream playback starts");
						stream.release();
						playback.pause();
						check(!stream.isDisposed(), "Paused stream retains source lease");
					case _: fail(result);
				}
				wait(.1, () -> {
					playback.resume();
					wait(.1, () -> {
						playback.stop();
						check(stream.isDisposed(), "Stopped stream releases source lease");
						next();
					});
				});
			}),
			() -> audio.loadStream("fixture.wav", result -> {
				switch result {
					case Ready(value):
						stream = value;
						playback = audio.play(stream);
						stream.release();
					case _: fail(result);
				}
				wait(.6, () -> {
					check(playback.isFinished() && stream.isDisposed(), "Natural stream finish releases resource");
					next();
				});
			}),
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
				() -> assets.ensure(path, result -> {
					switch result {
						case Loaded(bytes): env.audio.decodeClip(bytes, result -> {
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
							});
						case _: fail(result);
					}
				}),
				() -> audio.loadClip(path, result -> {
					switch result {
						case Ready(value):
							clip = value;
							playback = audio.play(clip, true, .4);
							check(playback.getId() > 0, "Ogg clip plays: " + extension);
							clip.release();
							playback.pause();
						case _: fail(result);
					}
					wait(.05, () -> {
						check(!playback.isFinished() && !clip.isDisposed(), "Paused Ogg clip retains resource");
						playback.resume();
						wait(.05, () -> {
							playback.stop();
							check(clip.isDisposed(), "Ogg clip final release");
							next();
						});
					});
				}),
				() -> audio.loadStream(path, result -> {
					switch result {
						case Ready(value):
							stream = value;
							playback = audio.play(stream, true, .3);
							check(playback.getId() > 0, "Stored Ogg stream starts: " + extension);
							stream.release();
							playback.pause();
						case _: fail(result);
					}
					wait(.05, () -> {
						check(!stream.isDisposed(), "Paused Ogg source lease");
						playback.resume();
						wait(.2, () -> {
							check(!playback.isFinished(), "Ogg stream loops beyond one duration");
							playback.stop();
							check(stream.isDisposed(), "Stopped Ogg source lease released");
							next();
						});
					});
				}),
				() -> audio.loadStream(path, result -> {
					switch result {
						case Ready(value):
							stream = value;
							playback = audio.play(stream);
							stream.release();
						case _: fail(result);
					}
					wait(.6, () -> {
						check(playback.isFinished() && stream.isDisposed(), "Natural Ogg EOF releases resource: " + extension);
						next();
					});
				}),
				() -> audio.loadStream("uncached." + extension, result -> {
					if (env.remoteStreams) {
						switch result {
							case Ready(value):
								var playing = audio.play(value);
								value.release();
								check(playing.getId() > 0, "Remote Ogg starts: " + extension);
								wait(.6, () -> {
									check(playing.isFinished() && value.isDisposed(), "Remote Ogg EOF");
									assets.streamSource("uncached." + extension, source -> {
										switch source {
											case Located(Remote(_)): check(true, "Remote Ogg did not persist");
											case _: fail(source);
										}
										next();
									});
								});
							case _: fail(result);
						}
					} else {
						switch result {
							case Failed(message): check(message.indexOf("ensure") >= 0, "Native remote Ogg capability explicit");
							case _: fail(result);
						}
						next();
					}
				})
			];
			for (step in codecSteps)
				steps.insert(steps.length - 1, step);
		}
		steps.insert(steps.length - 1, () -> audio.loadClip("broken.ogg", result -> {
			switch result {
				case Failed(_): check(true, "Malformed Ogg fails explicitly");
				case _: fail(result);
			}
			next();
		}));
		steps.insert(steps.length - 1, () -> env.audio.decodeClip(Bytes.alloc(0), result -> {
			switch result {
				case Failed(_): check(true, "Empty encoded audio fails explicitly");
				case _: fail(result);
			}
			next();
		}));
		steps.insert(steps.length - 1, () -> assets.ensure("fixture.opus", result -> {
			switch result {
				case Loaded(bytes):
					var callbacks = 0, request = env.audio.decodeClip(bytes, result -> {
						callbacks++;
						switch result {
							case Cancelled: check(true, "Encoded decode cancellation");
							case _: fail(result);
						}
					});
					env.audio.poll();
					request.cancel();
					wait(.15, () -> {
						check(callbacks == 1, "Late codec completion suppressed");
						next();
					});
				case _: fail(result);
			}
		}));
		next();
		env.start(() -> {
			assets.poll();
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
