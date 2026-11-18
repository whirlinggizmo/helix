package helix.raylib.extras.tweens;

/** Represents a play along an easing curve, from 0 to 1, for a value the program mixes itself by `amount`. It is helix-tweens'
	`EasedTween`.

	The easing curves are `Ease`'s: `Ease.outCubic`, `Ease.inOutSine`, `Ease.outBounce` and the rest of its thirty, or a function
	of the program's own through `Ease.of`. */
typedef EasedTween = helix.tweens.EasedTween;
