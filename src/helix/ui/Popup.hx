package helix.ui;

import helix.render2d.Node2D;

/** What a widget opens over everything else (Ui.popup): a dropdown's list, and later a menu or a tooltip. Its owner makes it (its nodes under
	root, their layout, the anchor it hangs from) and opens it through its Ui, which then draws it above every widget, panel and focus ring,
	clipped by none of its owner's clips, and places it by its anchor each frame: below the anchor, or above when the visible area has no room
	for it below and more above, and moved in to keep it on screen across. While it's open it has the pointer and the keys: a press anywhere
	off it closes it and does nothing else, Escape or a pad's East closes it, and focus stays on its owner, which takes the keys. One is open
	at a time; it closes too when its owner is hidden, disabled, loses focus or is taken out, and when the Ui is reset. */
@:allow(helix.ui.Ui)
class Popup {
	// Its nodes, under the Ui's popup layer while it's open, moved there to where it's placed: its content is laid out from 0, 0.
	@:allow(helix.ui)
	var root(default, null):Node2D = new Node2D();

	@:allow(helix.ui)
	function new(owner:Widget, layout:Layout2D) {
		this.owner = owner;
		this.layout = layout;
	}

	/** The widget it belongs to: focus stays on it while it's open, and its update drives it. */
	public var owner(default, null):Widget;

	/** Its content's layout, arranged by the Ui from 0, 0 in its own units each frame it's open: its size is the layout's. */
	public var layout(default, null):Layout2D;

	/** Whether it's open: from the Ui opening it until anything closes it (Ui.closePopup). */
	public var open(default, null):Bool = false;

	/** Where it was last placed: its left edge, in the units of the Ui's root (the stage's world, unless the game moved the root). */
	public var x(default, null):Float = 0.;

	/** Where it was last placed: its top edge, in the units of the Ui's root. */
	public var y(default, null):Float = 0.;

	/** Whether it was last placed above its anchor, there being no room for it below. */
	public var placedAbove(default, null):Bool = false;

	/** Its anchor's left edge, in the units of the Ui's root (setAnchor). */
	public var anchorX(default, null):Float = 0.;

	/** Its anchor's top edge, in the units of the Ui's root. */
	public var anchorY(default, null):Float = 0.;

	/** Its anchor's width in units. */
	public var anchorWidth(default, null):Float = 0.;

	/** Its anchor's height in units. */
	public var anchorHeight(default, null):Float = 0.;

	/** The rectangle it hangs from, in the units of the Ui's root (its owner's face, as drawn): left x, top y, width x height. Its owner sets it
		each frame, so it follows its owner (a scroll area scrolling under it). */
	public function setAnchor(x:Float, y:Float, width:Float, height:Float):Void {
		anchorX = x;
		anchorY = y;
		anchorWidth = width;
		anchorHeight = height;
	}

	// Placed at left, top, above its anchor or not (by the Ui).
	function place(left:Float, top:Float, above:Bool):Void {
		x = left;
		y = top;
		placedAbove = above;
		root.setPosition(left, top);
	}
}
