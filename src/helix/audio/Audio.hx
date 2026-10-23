package helix.audio;

import haxe.Json;
import helix.asset.Failure;
import helix.asset.Saves;

/** Sounds: clips and streams loaded through the assets, decoded and played (AudioResources), through buses. The audio output under it
	(IAudio) is the adapter's. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from
	AudioResources' public members with their doc comments, but for the buses and what plays through them, written here: the bus tree is plain
	engine data, there from the program's start, before the runner binds instance. */
@:build(helix.macro.Facade.build(helix.audio.AudioResources, ["poll", "reloaded", "shutdown"]))
class Audio {
	/** The sounds forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again. */
	@:hot @:allow(helix) static var instance(default, null):AudioResources;

	/** The root bus, every other one under it. Kept across a hot reload (@:hot), as the buses a game holds are. */
	@:hot public static final master:Bus = new Bus("master", null);

	/** The music's bus, under master. Kept across a hot reload (@:hot). */
	@:hot public static final music:Bus = new Bus("music", master);

	/** The sound effects' bus, under master: what play plays through. Kept across a hot reload (@:hot). */
	@:hot public static final effects:Bus = new Bus("effects", master);

	/** A new bus named name under parent, at volume 1, held as a reference (`@:hot static final ambience = Audio.addBus("ambience",
		Audio.effects)`); its name is what saveBuses and loadBuses know it by. Null, adding none, for an empty name or one a bus has. */
	public static function addBus(name:String, parent:Bus):Null<Bus> {
		if (name == null || name == "" || parent == null || findBus(name) != null)
			return null;
		return new Bus(name, parent);
	}

	// The bus named name, or null.
	static function findBus(name:String):Null<Bus> {
		for (bus in master.all())
			if (bus.name == name)
				return bus;
		return null;
	}

	/** Plays sound through effects from the beginning at volume (0 to 1), looping if asked: effects.play. */
	public static function play(sound:AudioResource, loop = false, volume = 1.):AudioPlayback
		return effects.play(sound, loop, volume);

	/** Fades from to silence and stops it, and to from its volume up to toVolume (1 by default; the track's own level), both over seconds and
		linear in power (FadeCurve.Power), so the two together hold their loudness through the middle: start to at 0 (`Audio.crossfade(theme,
		Audio.music.play(next, true, 0), 2)`). */
	public static function crossfade(from:AudioPlayback, to:AudioPlayback, seconds:Float, toVolume = 1.):Void {
		from.fadeAlong(0, seconds, null, true, Power);
		to.fadeAlong(toVolume, seconds, null, false, Power);
	}

	/** Saves every bus's volume and mute by name as JSON, the save named key (Saves, kept apart from the asset cache, so clearing it keeps
		them); done runs once it's written, failed (else the log, with the key) for a failed write. */
	public static function saveBuses(key = "audio", ?done:Void->Void, ?failed:String->Void):Void {
		var saved:haxe.DynamicAccess<{volume:Float, muted:Bool}> = {};
		for (bus in master.all())
			saved[bus.name] = {volume: bus.volume, muted: bus.muted};
		Saves.write(key, Json.stringify(saved), () -> if (done != null) done(), message -> Failure.report(key, message, failed));
	}

	/** Loads the volumes and mutes saveBuses saved under key into the buses of their names, a name with no bus skipped; a volume is clamped,
		and assigning it ends a bus's fade. done runs once they're set, or nothing was saved; failed (else the log, with the key) for a failed
		read or a file that isn't the saved JSON. */
	public static function loadBuses(key = "audio", ?done:Void->Void, ?failed:String->Void):Void {
		Saves.read(key, text -> {
			var saved:Dynamic = try Json.parse(text) catch (_:Dynamic) null;
			if (saved == null || Type.typeof(saved) != TObject) {
				Failure.report(key, "Invalid saved buses", failed);
				return;
			}
			for (name in Reflect.fields(saved)) {
				var bus = findBus(name),
					entry:Dynamic = Reflect.field(saved, name);
				if (bus == null || entry == null || Type.typeof(entry) != TObject)
					continue;
				var volume:Dynamic = Reflect.field(entry, "volume"),
					muted:Dynamic = Reflect.field(entry, "muted");
				if (Std.isOfType(volume, Float))
					bus.volume = volume;
				if (Std.isOfType(muted, Bool))
					bus.muted = muted;
			}
			if (done != null)
				done();
		}, () -> if (done != null) done(),
			message -> Failure.report(key, message, failed));
	}
}
