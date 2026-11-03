package helix.platform;

/** Specifies the cursor's shape over the canvas or window (`IMouse.cursorShape`): the system's own cursor of each kind. */
@:build(helix.platform.macros.EnumNames.build())
enum abstract CursorShape(Int) to Int {
	var Arrow = 0;
	var Text = 1;
	var Crosshair = 2;
	var Pointer = 3;
	var ResizeHorizontal = 4;
	var ResizeVertical = 5;
	var ResizeDiagonalDown = 6;
	var ResizeDiagonalUp = 7;
	var Move = 8;
	var NotAllowed = 9;
	var Wait = 10;
	var Progress = 11;

	/** Every shape. */
	public static final all:Array<CursorShape> = [
		Arrow,
		Text,
		Crosshair,
		Pointer,
		ResizeHorizontal,
		ResizeVertical,
		ResizeDiagonalDown,
		ResizeDiagonalUp,
		Move,
		NotAllowed,
		Wait,
		Progress
	];
}
