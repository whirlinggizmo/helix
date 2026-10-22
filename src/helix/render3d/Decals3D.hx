package helix.render3d;

import helix.decal.DecalPool;
import helix.texture.Texture2D;

/** Marks left on the ground: skid marks, footsteps, scorch marks, a target ring under a spell. A fixed pool of a texture's sprites lying flat
	(SpriteFacing3D.Ground), drawn in one draw: each place puts one down, and once the pool is full the oldest is taken up and put down again,
	so a trail never grows past its capacity. Given a life (lifeSeconds), each mark fades out over fadeSeconds once it has lived it, on the
	game's clock (a paused game's marks stay as they are), and is taken up; without one it stays until the pool comes round to it. Either
	way the ones next to be taken up for reuse (fadeCount) fade by how soon, so a full pool's trail thins out where it ends instead of losing
	a mark at a time. place puts one in its own space, the ground its x-z plane: place it on a level's floor. placeOn puts one on what a
	pick hit (a bullet hole in a wall, a scorch on a crate), on its face there and carried by its node as it moves. A decal lies flat,
	lifted a little (lift) off what it's put on, so it doesn't flicker into it; over an edge or a curve it shows sunk or standing off.
	Decals are never picked: a click passes to what's under them. */
class Decals3D extends Node3D {
	/** A pool of capacity (at least 1) decals of texture. */
	public function new(texture:Texture2D, capacity = 64) {
		super();
		this.texture = texture;
		pool = new DecalPool<Sprite3D>(capacity, (mark, tint) -> mark.tint = tint, mark -> {
			// Off whatever it's on: this pool, or a node a hit put it on.
			var on = mark.parent;
			if (on != null)
				on.removeChild(mark);
		});
	}

	var pool:DecalPool<Sprite3D>;
	// What placeOn reads the hit node's world transform into, and its inverse.
	var onWorld = new Mat4();
	var onInverse = new Mat4();

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
		var mark = take(size);
		addChild(mark);
		mark.setPosition(x, y + lift, z);
		mark.setRotation(0, angle, 0);
		pool.add(mark, tint != null ? tint : this.tint);
		return mark;
	}

	/** Puts a decal on what hit hit (a pick's: Pointer.hit3D, View3D's or Renderer3D's pick), lying on its face there (along the hit's
		normal, lifted lift off it), turned angle radians about the normal, size world units across as placed (0, the default, for the pool's
		size; whatever the node's scale), tinted (0xAARRGGBB; null for the pool's tint). It's put under the node hit, so it moves with it; on a
		skinned model, under the joint moving the surface there (hit.joint), so it rides the pose. Returns its sprite, as place does; null,
		putting nothing down, for a hit of nothing. */
	public function placeOn(hit:PickHit3D, angle = 0., size = 0., ?tint:Int):Null<Sprite3D> {
		var on = hit.joint != null ? hit.joint : hit.node;
		// The node's world transform in onWorld, its inverse in onInverse: the point (lifted along the normal) and the normal into its space.
		if (on == null)
			return null;
		on.computeWorld(onWorld);
		if (!onInverse.makeInverse(onWorld))
			return null;
		var nx = hit.getNormal(0),
			ny = hit.getNormal(1),
			nz = hit.getNormal(2);
		var px = hit.getPoint(0) + nx * lift,
			py = hit.getPoint(1) + ny * lift,
			pz = hit.getPoint(2) + nz * lift;
		inline function into(row:Int):Float
			return onInverse.get(row) * px + onInverse.get(4 + row) * py + onInverse.get(8 + row) * pz + onInverse.get(12 + row);
		// A normal goes into the node's space by the transpose of its world transform's turn (and scale), then made unit again.
		inline function turned(row:Int):Float
			return onWorld.get(row * 4) * nx + onWorld.get(row * 4 + 1) * ny + onWorld.get(row * 4 + 2) * nz;
		var lx = turned(0),
			ly = turned(1),
			lz = turned(2),
			length = Math.sqrt(lx * lx + ly * ly + lz * lz);
		if (!(length > 0))
			return null;
		lx /= length;
		ly /= length;
		lz /= length;
		var mark = take(size);
		on.addChild(mark);
		mark.setPosition(into(0), into(1), into(2));
		// Its up (+y, as it lies) turned onto the normal, by the shortest turn (half the way round for one facing down), then turned angle
		// about it.
		var qx = lz, qz = -lx, qw = 1 + ly;
		if (qw < 1e-6) {
			qx = 1;
			qz = 0;
			qw = 0;
		}
		var qLength = Math.sqrt(qx * qx + qz * qz + qw * qw);
		qx /= qLength;
		qz /= qLength;
		qw /= qLength;
		var s = Math.sin(angle / 2), c = Math.cos(angle / 2);
		mark.setQuaternion(qx * c - qz * s, qw * s, qx * s + qz * c, qw * c);
		// Its size the world's, the node's scale taken out: what its x and z come to in the world, as placed.
		var across = size > 0 ? size : this.size,
			placed = mark.computeWorld(onWorld);
		inline function stretch(column:Int):Float
			return Math.sqrt(placed.get(column) * placed.get(column) + placed.get(column + 1) * placed.get(column + 1)
				+ placed.get(column + 2) * placed.get(column + 2));
		var wide = stretch(0), deep = stretch(8);
		if (wide > 0 && deep > 0)
			mark.setSpriteSize(across / wide, across / deep);
		pool.add(mark, tint != null ? tint : this.tint);
		return mark;
	}

	// The decal to put down next, sized (0 for the pool's size), off whatever it was on: a new one, a spare, or the oldest.
	function take(size:Float):Sprite3D {
		var mark = pool.next();
		if (mark == null) {
			mark = new Sprite3D(texture);
			mark.facing = Ground;
			mark.pickable = false;
		} else {
			var on = mark.parent;
			if (on != null)
				on.removeChild(mark);
			mark.setRegion(0, 0, 0, 0);
			mark.effect = null;
		}
		var across = size > 0 ? size : this.size;
		mark.setSpriteSize(across, across);
		return mark;
	}

	/** Takes every decal up. */
	public function clear():Void
		pool.clear();
}
