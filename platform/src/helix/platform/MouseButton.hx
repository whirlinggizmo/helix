package helix.platform;

/** Specifies a mouse button. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract MouseButton(Int) to Int {
	var Left = 0;
	var Right = 1;
	var Middle = 2;

	/** Every button. */
	public static final all:Array<MouseButton> = [Left, Right, Middle];
}
