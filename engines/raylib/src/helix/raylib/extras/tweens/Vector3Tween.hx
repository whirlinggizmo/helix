package helix.raylib.extras.tweens;

/** Represents a `Vector3` moving from one point to another, written in place. It is helix-tweens' `Vector3Tween`.

	```haxe
	var rise = new Vector3Tween(door, new Vector3(0, 3, 0), 1.5, Ease.inOutCubic, door);
	// each frame
	rise.update(GetFrameTime()); // moves door
	DrawCubeV(door, size, BROWN);
	``` */
typedef Vector3Tween = helix.tweens.Vector3Tween;
