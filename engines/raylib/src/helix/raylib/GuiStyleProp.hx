package helix.raylib;

/** One property of raygui's style, as raygui's `GuiStyleProp` holds it for a style written as code: the control, the property and its
	value, as `GuiSetStyle` takes them. */
class GuiStyleProp {
	/** The control (`DEFAULT`, `BUTTON` and the rest). */
	public var controlId:Int;

	/** The property (`BORDER_COLOR_NORMAL`, `TEXT_SIZE` and the rest). */
	public var propertyId:Int;

	/** Its value: a color as 0xRRGGBBAA, a size in pixels, or one of the property's values. */
	public var propertyValue:Int;

	/** Makes one.

		@param controlId  The control.
		@param propertyId  The property.
		@param propertyValue  Its value. */
	public function new(controlId:Int = 0, propertyId:Int = 0, propertyValue:Int = 0) {
		this.controlId = controlId;
		this.propertyId = propertyId;
		this.propertyValue = propertyValue;
	}
}
