package helix.render3d;

import haxe.ds.Vector;
import helix.render3d.Track3D;

/** A named animation: tracks moving nodes, by name, over its duration (its last key). Read from a glTF file (ModelFile3D.clips), whether or
	not the file has meshes: a file of animations alone plays on any skeleton with the joint names its tracks target (Animator3D). Read, never
	changed; shared by everything that plays it. */
class AnimationClip3D {
	var tracks:Array<Track3D>;

	/** A clip named name of tracks. */
	public function new(name:String, tracks:Array<Track3D>) {
		this.name = name;
		this.tracks = tracks.copy();
		for (track in tracks)
			duration = Math.max(duration, track.times[track.times.length - 1]);
	}

	/** Its name: its file's (a Blender export's is the armature's and the action's, "Armature|Walk"). */
	public var name(default, null):String;

	/** Its length in seconds: its last key's time. */
	public var duration(default, null):Float = 0.;

	/** How many tracks. */
	public var trackCount(get, never):Int;

	function get_trackCount():Int
		return tracks.length;

	/** Track index; null past them. */
	public function getTrack(index:Int):Null<Track3D>
		return index >= 0 && index < tracks.length ? tracks[index] : null;
}
