package helix.adapters.audio.sokol;

import helix.adapters.audio.sokol.internal.AudioBridge;
import helix.adapters.audio.libsndfile.internal.CodecBridge;
import helix.audio.Wav;
import helix.audio.IAudio;
import helix.audio.IAudio.StreamResult;
import helix.audio.IAudio.ClipDecodeResult;
import helix.assets.IAssets.AudioLocation;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import helix.audio.WavStream;
import helix.audio.Pcm;
import haxe.io.Bytes;
import sys.thread.Deque;
import sys.thread.Thread;

private typedef StreamFile = {var path:String; var bytes:Int; var ogg:Bool;}
private typedef StreamPlayback = {var file:Null<sys.io.FileInput>; var codec:Int; var stream:StreamFile; var remaining:Int; var loop:Bool;}

class SokolAudioAdapter implements IAudio {
	var streams:Map<Int, StreamFile> = [];
	var streaming:Map<Int, StreamPlayback> = [];
	var nextStream = 1;
	var done = new Deque<Void->Void>();
	var queue = new WorkQueue();
	var requests:Array<IRequest> = [];
	var live = true;
	var decodeJobs:Array<Void->Void> = [];
	var decoding = 0;

	public function new() {
		AudioBridge.audioSetup();
	}

	public function decodeClip(encoded:Bytes, complete:ClipDecodeResult->Void):IRequest {
		var request:Request = null;
		function finish(result:ClipDecodeResult) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> complete(result));
			}
		}
		request = new Request(() -> {
			requests.remove(request);
			queue.add(() -> complete(Cancelled));
		});
		requests.push(request);
		decodeJobs.push(() -> {
			if (request.isSettled())
				return;
			if (!live || encoded.length < 4 || encoded.length > 8 * 1024 * 1024) {
				finish(Failed("Closed decoder or invalid encoded audio byte length"));
				return;
			}
			decoding++;
			Thread.create(() -> {
				var result:ClipDecodeResult, codec = 0;
				try {
					if (encoded.length >= 4 && encoded.getString(0, 4) == "RIFF")
						result = Decoded(helix.audio.Wav.decode(encoded));
					else {
						codec = CodecBridge.codecMemory(cpp.Pointer.arrayElem(encoded.getData(), 0).raw, encoded.length);
						if (codec == 0)
							throw "Ogg decode failed; expected mono/stereo Vorbis or Opus";
						var frames = CodecBridge.codecFrames(codec);
						if (frames <= 0 || frames > 2 * 1024 * 1024)
							throw "Decoded PCM exceeds byte limit";
						var samples = Bytes.alloc(Std.int(frames) * 4), chunk = Bytes.alloc(2048 * 4), count = 0;
						while (true) {
							var n = CodecBridge.codecRead(codec, cpp.Pointer.arrayElem(chunk.getData(), 0).raw, 2048);
							if (n < 0)
								throw "Ogg decode failed";
							if (n == 0)
								break;
							if (count + n > 2 * 1024 * 1024)
								throw "Decoded PCM exceeds byte limit";
							if ((count + n) * 4 > samples.length)
								throw "Ogg sample count changed during decode";
							samples.blit(count * 4, chunk, 0, n * 4);
							count += n;
						}
						if (count == 0)
							throw "Empty decoded Ogg";
						result = Decoded(samples.sub(0, count * 4));
					}
				} catch (error:Dynamic) {
					result = Failed(Std.string(error));
				}
				if (codec != 0)
					CodecBridge.codecClose(codec);
				done.add(() -> {
					decoding--;
					finish(result);
				});
			});
		});
		return request;
	}

	public function createClip(samples:Bytes):Int {
		Pcm.validate(samples);
		var id = AudioBridge.audioClip(cpp.Pointer.arrayElem(samples.getData(), 0).raw, samples.length);
		if (id == 0)
			throw "Audio clip creation failed";
		return id;
	}

	public function createStream(source:AudioLocation, complete:StreamResult->Void):IRequest {
		var request:Request = null;
		function finish(result:StreamResult) {
			if (request.finish()) {
				requests.remove(request);
				queue.add(() -> complete(result));
			}
		}
		request = new Request(() -> {
			requests.remove(request);
			queue.add(() -> complete(Cancelled));
		});
		requests.push(request);
		switch source {
			case Remote(_):
				queue.add(() -> finish(Failed("Sokol remote audio streaming is unsupported; ensure the audio asset first")));
			case Stored(value):
				if (!live) {
					queue.add(() -> finish(Failed("Closed audio backend")));
					return request;
				}
				var path = value.location;
				Thread.create(() -> {
					var file:sys.io.FileInput = null;
					var stream:StreamFile = null, error:String = null;
					try {
						file = sys.io.File.read(path, true);
						var magic = file.read(4).toString();
						file.seek(0, sys.io.FileSeek.SeekBegin);
						if (magic == "OggS") {
							var codec = CodecBridge.codecFile(path);
							if (codec == 0)
								throw "Unsupported Ogg stream; expected mono/stereo Vorbis or Opus";
							CodecBridge.codecClose(codec);
							stream = {path: path, bytes: 0, ogg: true};
						} else
							stream = {path: path, bytes: WavStream.header(file.read(44), sys.FileSystem.stat(path).size), ogg: false};
					} catch (e:Dynamic) {
						error = Std.string(e);
					}
					if (file != null)
						file.close();
					done.add(() -> {
						if (request.isSettled())
							return;
						if (error != null)
							finish(Failed(error));
						else {
							var id = -(nextStream++);
							streams[id] = stream;
							finish(Created(id));
						}
					});
				});
		}
		return request;
	}

	public function play(resource:Int, loop:Bool = false, volume:Float = 1):Int {
		if (!Math.isFinite(volume) || volume < 0 || volume > 1)
			throw "Invalid volume";
		if (resource >= 0) {
			var id = AudioBridge.audioPlay(resource, loop ? 1 : 0, volume);
			if (id < 0)
				throw "Invalid audio clip";
			return id;
		}
		var stream = streams[resource];
		if (stream == null)
			throw "Invalid audio stream";
		var file:sys.io.FileInput = null, codec = 0, path:String = stream.path;
		if (stream.ogg) {
			codec = CodecBridge.codecFile(path);
			if (codec == 0)
				throw "Ogg stream open failed";
		} else {
			file = sys.io.File.read(path, true);
			file.seek(44, sys.io.FileSeek.SeekBegin);
		}
		var id = AudioBridge.audioStream(volume);
		if (id == 0) {
			if (file != null)
				file.close();
			if (codec != 0)
				CodecBridge.codecClose(codec);
			return 0;
		}
		streaming[id] = {
			file: file,
			codec: codec,
			stream: stream,
			remaining: stream.bytes,
			loop: loop
		};
		try {
			fill(id, streaming[id]);
		} catch (error:Dynamic) {
			stop(id);
			throw error;
		}
		return id;
	}

	function closeProducer(id:Int, value:StreamPlayback):Void {
		if (value.file != null)
			value.file.close();
		if (value.codec != 0)
			CodecBridge.codecClose(value.codec);
		streaming.remove(id);
	}

	function fill(id:Int, value:StreamPlayback):Void {
		var start = haxe.Timer.stamp();
		while ((haxe.Timer.stamp() - start) * 1000 < .002 * 1000) {
			var queued = AudioBridge.audioStreamQueued(id);
			if (queued < 0) {
				closeProducer(id, value);
				return;
			}
			var frames = Std.int(Math.min(2048, 8192 - queued));
			if (frames == 0)
				return;
			if (value.codec != 0) {
				var pcm = Bytes.alloc(frames * 4),
					count = CodecBridge.codecRead(value.codec, cpp.Pointer.arrayElem(pcm.getData(), 0).raw, frames);
				if (count < 0)
					throw "Ogg stream decode failed";
				if (count == 0) {
					if (value.loop) {
						if (CodecBridge.codecRewind(value.codec) != 1)
							throw "Ogg stream rewind failed";
						continue;
					}
					AudioBridge.audioStreamPush(id, null, 0, 1);
					closeProducer(id, value);
					return;
				}
				if (AudioBridge.audioStreamPush(id, cpp.Pointer.arrayElem(pcm.getData(), 0).raw, count * 4, 0) != count)
					throw "Sokol stream queue rejected samples";
				continue;
			}
			if (value.remaining == 0) {
				if (value.loop) {
					value.file.seek(44, sys.io.FileSeek.SeekBegin);
					value.remaining = value.stream.bytes;
				} else {
					AudioBridge.audioStreamPush(id, null, 0, 1);
					closeProducer(id, value);
					return;
				}
			}
			var count = Std.int(Math.min(value.remaining, frames * 2)),
				bytes = value.file.read(count);
			if (bytes.length != count)
				throw "Truncated streamed WAV";
			var pcm = WavStream.decode(bytes),
				accepted = AudioBridge.audioStreamPush(id, cpp.Pointer.arrayElem(pcm.getData(), 0).raw, pcm.length, 0);
			if (accepted != count / 2)
				throw "Sokol stream queue rejected samples";
			value.remaining -= count;
		}
	}

	public function stop(id:Int):Void {
		var value = streaming[id];
		if (value != null)
			closeProducer(id, value);
		AudioBridge.audioStop(id);
	}

	public function pause(id:Int, paused:Bool):Void
		AudioBridge.audioPause(id, paused ? 1 : 0);

	public function setVolume(id:Int, volume:Float):Void {
		if (!Math.isFinite(volume) || volume < 0 || volume > 1)
			throw "Invalid volume";
		AudioBridge.audioVolume(id, volume);
	}

	public function isPlaying(id:Int):Bool
		return AudioBridge.audioIsPlaying(id) != 0;

	public function destroyClip(id:Int):Void {
		if (AudioBridge.audioDestroyClip(id) != 1)
			throw "Invalid audio clip";
	}

	public function destroyStream(id:Int):Void {
		if (!streams.exists(id))
			throw "Invalid audio stream";
		streams.remove(id);
	}

	public function poll():Void {
		while (true) {
			var work = done.pop(false);
			if (work == null)
				break;
			queue.add(work);
		}
		while (live && decoding < 2 && decodeJobs.length > 0)
			decodeJobs.shift()();
		queue.poll();
		for (id in [for (id in streaming.keys()) id])
			try {
				fill(id, streaming[id]);
			} catch (error:Dynamic) {
				stop(id);
				Sys.println("Audio stream failed: " + Std.string(error));
			}
	}

	public function shutdown():Void {
		live = false;
		for (request in requests.copy())
			request.cancel();
		decodeJobs = [];
		for (id in [for (id in streaming.keys()) id])
			stop(id);
		streams.clear();
		queue.poll();
		AudioBridge.audioShutdown();
	}

	public function info():Dynamic {
		var loops = AudioBridge.audioLoops();
		for (value in streaming)
			if (value.loop)
				loops++;
		return {
			audioBackend: "sokol-audio",
			audioAvailable: AudioBridge.audioAvailable() != 0,
			audioPlayed: AudioBridge.audioPlayed(),
			audioStopped: AudioBridge.audioStopped(),
			audioLoops: loops,
			audioCallbacks: AudioBridge.audioCallbacks(),
			audioSampleRate: AudioBridge.audioSampleRate(),
			audioChannels: AudioBridge.audioChannels()
		};
	}
}
