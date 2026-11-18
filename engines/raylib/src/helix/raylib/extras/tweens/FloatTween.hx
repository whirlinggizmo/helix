package helix.raylib.extras.tweens;

/** Represents a number moving from one value to another. It is helix-tweens' `FloatTween`.

	```haxe
	var zoom = new FloatTween(1, 2, 0.3, Ease.outCubic);
	// each frame
	zoom.update(GetFrameTime());
	camera.zoom = zoom.value;
	``` */
typedef FloatTween = helix.tweens.FloatTween;
