package helix.render3d;

import helix.decal.DecalPool;
import helix.texture.Texture2D;

/** Marks left on the ground: skid marks, footsteps, scorch marks, a target ring under a spell. A fixed pool of a texture's sprites lying flat
	(SpriteFacing3D.Ground), drawn in one draw: each place puts one down, and once the pool is full the oldest is taken up and put down again,
	so a trail never grows past its capacity. Given a life (lifeSeconds), each mark fades out over fadeSeconds once it has lived it, on the
	game's clock (a paused game's marks stay as they are), and is taken up; without one it stays until the pool comes round to it. Either
	way the ones next to be taken up for reuse (fadeCount) fade by how soon, so a full pool's trail thins out where it ends instead of losing
	a mark at a time. In its own space, the ground its x-z plane: place it on a level's floor. A decal lies flat, lifted a little (lift) over
	the ground it's put on, so it doesn't flicker into it; on a slope it shows its edge sunk or floating. Decals are never picked: a click
	passes to the ground. */
class Decals3D extends Node3D {
	/** A pool of capacity (at least 1) decals of texture. */
	public function new(texture:Texture2D, capacity = 64) {
		super();
		this.texture = texture;
		pool = new DecalPool<Sprite3D>(capacity, (mark, tint) -> mark.tint = tint, mark -> removeChild(mark));
	}

	var pool:DecalPool<Sprite3D>;

	/** Their texture. */
	public var texture(default, null):Texture2D;

	/** How many it holds before the oldest is put down again. */
	public var capacity(get, never):Int;

	function get_capacity():Int
		return pool.capacity;

	/** How many are down now: up to capacity. */
	public var count(get, never):Int;

	function get_count():Int
		return pool.marks.length;

	/** Each decal's size, world units, square (place may give its own): 1 to start. */
	public var size:Float = 1;

	/** Their tint, 0xAARRGGBB (sRGB): white (the texture as it is) to start. place may give its own. */
	public var tint:Int = 0xffffffff;

	/** How far over the ground each lies, world units: .01 to start. More if far views flicker; 0 for none. */
	public var lift:Float = .01;

	/** How many of the decals next to be taken up for reuse fade, by how soon: the next at 1 in fadeCount + 1 of its alpha (none fade while
		the pool has that many places free). A quarter of the capacity to start; 0 for none. Clamped to 0..capacity. Takes effect at the next
		place. */
	public var fadeCount(get, set):Int;

	function get_fadeCount():Int
		return pool.fadeCount;

	function set_fadeCount(value:Int):Int
		return pool.fadeCount = value;

	/** Seconds on the game's clock each decal stays as placed before it fades out (over fadeSeconds) and is taken up: 0 (the default, and for
		less) for as long as the pool lets it. Applies to every decal down, as old as each is. */
	public var lifeSeconds(get, set):Float;

	function get_lifeSeconds():Float
		return pool.lifeSeconds;

	function set_lifeSeconds(value:Float):Float
		return pool.lifeSeconds = value;

	/** Seconds a decal takes to fade out once it has lived its life (lifeSeconds): .5 to start; 0 (and for less) to vanish at once. */
	public var fadeSeconds(get, set):Float;

	function get_fadeSeconds():Float
		return pool.fadeSeconds;

	function set_fadeSeconds(value:Float):Float
		return pool.fadeSeconds = value;

	/** Puts a decal down at x, y, z (its own space; y the ground's height there), turned angle radians about y (its texture's top toward
		-z at 0), size world units across (0, the default, for the pool's size), tinted (0xAARRGGBB; null for the pool's tint). Returns its
		sprite, to set its region (a variant from an atlas) or effect now: it's the pool's, put down again once taken up, its region and
		effect cleared then. */
	public function place(x:Float, y:Float, z:Float, angle = 0., size = 0., ?tint:Int):Sprite3D {
		var mark = pool.next();
		if (mark == null) {
			mark = new Sprite3D(texture);
			mark.facing = Ground;
			mark.pickable = false;
		} else {
			mark.setRegion(0, 0, 0, 0);
			mark.effect = null;
		}
		addChild(mark);
		var across = size > 0 ? size : this.size;
		mark.setSpriteSize(across, across);
		mark.setPosition(x, y + lift, z);
		mark.setRotation(0, angle, 0);
		pool.add(mark, tint != null ? tint : this.tint);
		return mark;
	}

	/** Takes every decal up. */
	public function clear():Void
		pool.clear();
}
