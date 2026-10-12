package helix.adapters.audio.webaudio;
import helix.audio.Wav;
import helix.audio.IAudio;
import helix.audio.IAudio.StreamResult;
import helix.audio.IAudio.ClipDecodeResult;
import helix.assets.IAssets.AudioLocation;
import helix.assets.IRequest;
import helix.assets.Request;
import helix.core.WorkQueue;
import helix.audio.Pcm;
import haxe.io.Bytes;
class WebAudioAdapter implements IAudio {
 var context:Dynamic;var nextClip=1;var nextPlayback=1;var clips:Map<Int,Bytes>=[];var buffers:Map<Int,Dynamic>=[];var streams:Map<Int,Dynamic>=[];var playbacks:Map<Int,Dynamic>=[];var queue=new WorkQueue();var requests:Array<IRequest>=[];var live=true;
 public var played(default,null)=0;public var stopped(default,null)=0;
 public function new(){}
 public function decodeClip(encoded:Bytes,complete:ClipDecodeResult->Void):IRequest {
  var request:Request=null;
  function finish(result:ClipDecodeResult){if(request.finish()){requests.remove(request);queue.add(()->complete(result));}}
  request=new Request(()->{requests.remove(request);queue.add(()->complete(Cancelled));});requests.push(request);
  queue.add(()->{
   if(request.settled)return;
   if(!live||encoded.length>8*1024*1024){finish(Failed("Closed decoder or encoded audio exceeds byte limit"));return;}
   try {
    if(encoded.length>=4&&encoded.getString(0,4)=="RIFF"){finish(Decoded(helix.audio.Wav.decode(encoded)));return;}
    if(encoded.length<4||encoded.getString(0,4)!="OggS")throw "Unsupported encoded audio; expected WAV or Ogg";
    if(context==null)context=js.Syntax.code("new (window.AudioContext || window.webkitAudioContext)({sampleRate:44100})");
    // decodeAudioData consumes/detaches its input. Cache bytes remain caller-owned.
    var data:js.lib.ArrayBuffer=encoded.getData().slice(0,encoded.length);
    context.decodeAudioData(data).then(buffer->{
     if(request.settled)return null;
     try {
      var frames=Std.int(Math.ceil(buffer.length*44100/buffer.sampleRate));
      if(buffer.sampleRate<=0||buffer.numberOfChannels<1||buffer.numberOfChannels>2||frames<=0||frames>2*1024*1024)throw "Unsupported decoded rate/channels or PCM byte limit";
      var samples=Bytes.alloc(frames*4),channels:Array<js.lib.Float32Array>=[];
      for(c in 0...buffer.numberOfChannels)channels.push(buffer.getChannelData(c));
      for(i in 0...frames){var at=i*buffer.sampleRate/44100,a=Std.int(at),b=Std.int(Math.min(a+1,buffer.length-1)),fraction=at-a,value=0.;for(channel in channels)value+=channel[a]+(channel[b]-channel[a])*fraction;value/=channels.length;if(!Math.isFinite(value))throw "Invalid decoded PCM";samples.setFloat(i*4,Math.max(-1,Math.min(1,value)));}
      finish(Decoded(samples));
     }catch(error:Dynamic)finish(Failed(Std.string(error)));return null;
    },error->{finish(Failed("Ogg decode failed: "+Std.string(error)));return null;});
   }catch(error:Dynamic)finish(Failed(Std.string(error)));
  });return request;
 }
 public function unlock():Void {if(context==null)context=js.Syntax.code("new (window.AudioContext || window.webkitAudioContext)()");context.resume();}
 public function suspend():Void {if(context!=null&&context.state=="running")context.suspend();}
 public function createClip(samples:Bytes):Int {Pcm.validate(samples);var id=nextClip++;clips[id]=samples.sub(0,samples.length);return id;}
 public function createStream(location:AudioLocation,complete:StreamResult->Void):IRequest {
  var url=switch location {case Stored(value):value.location;case Remote(url):url;},element=js.Browser.document.createAudioElement(),request:Request=null;
  function detach(){element.onloadedmetadata=null;element.onerror=null;}
  function dispose(){detach();element.pause();element.removeAttribute("src");element.load();}
  var timer=0;
  function finish(result:StreamResult){if(request.finish()){requests.remove(request);js.Browser.window.clearTimeout(timer);detach();queue.add(()->complete(result));}}
  request=new Request(()->{requests.remove(request);js.Browser.window.clearTimeout(timer);dispose();queue.add(()->complete(Cancelled));});requests.push(request);
  if(!live){queue.add(()->finish(Failed("Closed audio backend")));return request;}
  element.preload="metadata";element.crossOrigin="anonymous";
  element.onloadedmetadata=_-> {var id=nextClip++;streams[id]={url:url,element:element};finish(Created(id));};
  element.onerror=_-> {dispose();finish(Failed("Streamed audio failed: "+url));};
  timer=js.Browser.window.setTimeout(()->{dispose();finish(Failed("Streamed audio metadata timeout"));},15000);
  element.src=url;element.load();return request;
 }
 function clipSource(id:Int,v:Dynamic):Void {
  var source:Dynamic=context.createBufferSource();source.buffer=v.buffer;source.loop=v.loop;source.connect(v.gain);v.source=source;v.started=context.currentTime;v.paused=false;
  source.onended=_-> {if(playbacks[id]==v&&!v.paused){playbacks.remove(id);source.disconnect();v.gain.disconnect();}};
  source.start(0,v.offset);
 }
 public function play(resource:Int,loop:Bool=false,volume:Float=1):Int {
  if((!clips.exists(resource)&&!streams.exists(resource))||!Math.isFinite(volume)||volume<0||volume>1)throw "Invalid audio playback";
  if(!live||context==null||context.state!="running")return 0;
  var id=nextPlayback++,gain:Dynamic=context.createGain();gain.gain.value=volume;gain.connect(context.destination);
  if(streams.exists(resource)){
   var entry=streams[resource],element:js.html.AudioElement=entry.element;if(element==null){element=js.Browser.document.createAudioElement();element.crossOrigin="anonymous";element.src=entry.url;}entry.element=null;
   element.loop=loop;var source:Dynamic=context.createMediaElementSource(element);source.connect(gain);
   var v:Dynamic={kind:"stream",source:element,node:source,gain:gain,resource:resource,paused:false};playbacks[id]=v;
   element.onended=_->finishStream(id,v);element.onerror=_->finishStream(id,v);
   element.play().catchError(error->{finishStream(id,v);return null;});
  }else {
   var buffer=buffers[resource];if(buffer==null){var data=clips[resource];buffer=context.createBuffer(1,Std.int(data.length/4),44100);buffer.copyToChannel(new js.lib.Float32Array(data.getData()),0);buffers[resource]=buffer;}
   var v:Dynamic={kind:"clip",source:null,gain:gain,resource:resource,buffer:buffer,loop:loop,offset:0.,started:0.,paused:false};playbacks[id]=v;clipSource(id,v);
  }played++;return id;
 }
 function finishStream(id:Int,v:Dynamic):Void {if(playbacks[id]!=v)return;playbacks.remove(id);v.source.onended=null;v.source.onerror=null;v.source.pause();v.source.removeAttribute("src");v.source.load();v.node.disconnect();v.gain.disconnect();}
 public function stop(id:Int):Void {
  var v=playbacks[id];if(v==null)return;if(v.kind=="stream")finishStream(id,v);else {playbacks.remove(id);v.source.onended=null;if(!v.paused)v.source.stop();v.source.disconnect();v.gain.disconnect();}stopped++;
 }
 public function pause(id:Int,paused:Bool):Void {
  var v=playbacks[id];if(v==null||v.paused==paused)return;
  if(v.kind=="stream"){v.paused=paused;if(paused)v.source.pause();else v.source.play().then(_->null,error->{finishStream(id,v);return null;});}
  else if(paused){v.offset+=context.currentTime-v.started;if(v.loop)v.offset%=v.buffer.duration;v.paused=true;v.source.onended=null;v.source.stop();v.source.disconnect();}
  else {if(v.offset>=v.buffer.duration){stop(id);return;}clipSource(id,v);}
 }
 public function setVolume(id:Int,volume:Float):Void {if(!Math.isFinite(volume)||volume<0||volume>1)throw "Invalid volume";var v=playbacks[id];if(v!=null)v.gain.gain.value=volume;}
 public function isPlaying(id:Int):Bool return playbacks.exists(id);
 public function destroyClip(id:Int):Void {if(!clips.exists(id))throw "Invalid audio clip";for(playback in [for(p in playbacks.keys())if(playbacks[p].resource==id)p])stop(playback);clips.remove(id);buffers.remove(id);}
 public function destroyStream(id:Int):Void {var entry=streams[id];if(entry==null)throw "Invalid audio stream";for(playback in [for(p in playbacks.keys())if(playbacks[p].resource==id)p])stop(playback);if(entry.element!=null){entry.element.removeAttribute("src");entry.element.load();}streams.remove(id);}
 public function poll():Void queue.poll();
 public function shutdown():Void {live=false;for(request in requests.copy())request.cancel();for(id in [for(p in playbacks.keys())p])stop(id);for(id in [for(s in streams.keys())s])destroyStream(id);clips.clear();buffers.clear();queue.poll();if(context!=null){context.close();context=null;}}
 public function info():Dynamic {var loops=0;for(v in playbacks)if(v.kind=="stream"?v.source.loop:v.loop)loops++;return {audioAvailable:context!=null&&context.state=="running",audioPlayed:played,audioStopped:stopped,audioLoops:loops};}
}
