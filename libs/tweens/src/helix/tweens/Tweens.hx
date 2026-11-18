package helix.tweens;

/** Provides a set of tweens stepped together. A tween leaves the set when it is done, so a program can add one and keep nothing.

	```haxe
	var tweens = new Tweens();
	var pop = tweens.add(new Vector3Tween(coin.position, hud, 0.6, Ease.inBack, coin.position));
	pop.onComplete = () -> score++;
	// each frame
	tweens.update(dt);
	``` */
class Tweens {
	/** Gets how many tweens the set holds. */
	public var tweenCount(get, never):Int;

	final tweens:Array<Tween> = [];

	// Counts each time the set was stepped or emptied, by which a step under way knows a callback did either.
	var changes = 0;

	/** Creates an empty set. */
	public function new() {}

	/** Adds a tween to the set. A tween added during `update` is first stepped by the next `update`.

		@param tween  The tween, of any kind, or a sequence.
		@return  The tween.
		@throws String  A tween placed in a sequence, which the sequence steps. */
	public function add<T:Tween>(tween:T):T {
		if (@:privateAccess tween.owned)
			throw "The tween is placed in a sequence, which steps it";
		tweens.push(tween);
		return tween;
	}

	/** Steps each tween by some seconds, in the order added, and drops the ones that are done.

		@param dt  The seconds to step by. */
	public function update(dt:Float):Void {
		var stepped = tweens.length, before = changes;
		for (index in 0...stepped) {
			tweens[index].update(dt);
			// A callback that emptied the set or stepped it leaves this step nothing to go on with.
			if (changes != before)
				return;
		}
		var kept = 0;
		for (index in 0...tweens.length)
			if (!tweens[index].done)
				tweens[kept++] = tweens[index];
		tweens.resize(kept);
		changes++;
	}

	/** Cancels every tween in the set and empties the set. */
	public function cancelAll():Void {
		for (tween in tweens)
			tween.cancel();
		tweens.resize(0);
		changes++;
	}

	function get_tweenCount():Int
		return tweens.length;
}
