package helix.audio;

/** Fully decoded, reusable audio resource. */
class AudioClip extends AudioResource {
 /** The asset it was loaded from, which a reload replaces in place. */
 public var path(default,null):Null<String>;
 public function new(id:Int,backend:IAudio,?path:String){super(id,backend,null);this.path=path;}
 // The current backend clip: a reload may have replaced the one it was made with.
 override function dispose():Void backend.destroyClip(id);
}
