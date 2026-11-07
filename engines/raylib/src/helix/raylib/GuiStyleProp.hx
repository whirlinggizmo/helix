package helix.raylib;

/** Represents one property of raygui's style, as raygui's `GuiStyleProp` holds it for a style written as code: the control, the property
	and its value, as `GuiSetStyle` takes them. */
class GuiStyleProp {
	/** Gets or sets the control (`DEFAULT`, `BUTTON` and the rest). */
	public var controlId:Int;

	/** Gets or sets the property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE` and the rest). */
	public var propertyId:Int;

	/** Gets or sets the property's value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values. */
	public var propertyValue:Int;

	/** Creates a style property.

		@param controlId  The control.
		@param propertyId  The property.
		@param propertyValue  Its value. */
	public function new(controlId:Int = 0, propertyId:Int = 0, propertyValue:Int = 0) {
		this.controlId = controlId;
		this.propertyId = propertyId;
		this.propertyValue = propertyValue;
	}
}
