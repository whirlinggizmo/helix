package helix.raylib.extras.tweens;

/** Provides a set of tweens stepped together, each leaving the set when it is done. It is helix-tweens' `Tweens`.

	```haxe
	var tweens = new Tweens();
	var fade = tweens.add(new ColorTween(WHITE, BLANK, 0.5));
	// each frame
	tweens.update(GetFrameTime());
	DrawTexture(logo, 0, 0, fade.value);
	``` */
typedef Tweens = helix.tweens.Tweens;
