package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Texture2D;

/** A picture with a caption under it, in a frame: an inventory's item, a character creator's choice, a level to pick. Clicked by the pointer,
	or activated with focus by Enter, Space or a pad's South; marked selected by the game (one of a group, as the game decides: isClicked,
	then setSelected). Its picture can come later (a thumbnail still being made): until then, and with none, the frame shows the theme's face
	color. Ask isClicked once a frame. */
class Tile extends Widget {
	var face:Node2D;
	var picture:Node2D;
	var label:Node2D;
	var edge:Node2D;
	var selected = false;
	var clicked = false;
	var side:Float;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, texture:Null<Texture2D>, caption:String, side:Float) {
		super(ui, name);
		this.side = side;
		var theme = ui.getTheme(), pad = theme.getPadding();
		face = Node2D.rectangle(1, 1, theme.getFaceColor());
		face.setPivot(0, 0);
		face.setCornerRadius(theme.getCornerRadius());
		edge = Node2D.rectangle(1, 1, theme.getAccentColor());
		edge.setPivot(0, 0);
		edge.setCornerRadius(theme.getCornerRadius() + 2);
		edge.setPickable(false);
		edge.setVisible(false);
		picture = Node2D.sprite(texture);
		picture.setPivot(0, 0);
		picture.setPickable(false);
		label = Node2D.text(caption, theme.getTextSize() * .8, theme.getTextColor(), Center, theme.getFont());
		label.setPickable(false);
		for (n in [edge, face, picture, label])
			root.add(n);
		// The edge a little outside the face, the picture square inside it, the caption under the picture.
		box = Box.stack(edge);
		var inner = Box.column(face);
		inner.setPadding(pad, pad, pad, pad);
		inner.setGap(pad / 2);
		inner.setAlign(Start, Center);
		var image = Box.of(picture);
		image.setSizing(Fixed(side), Fixed(side));
		inner.add(image);
		inner.add(Box.of(label));
		box.setPadding(3, 3, 3, 3);
		box.add(inner);
		picture.setVisible(texture != null);
	}

	/** Whether it was clicked or activated this frame. */
	public function isClicked():Bool
		return clicked;

	/** Whether it's marked selected: drawn with an accent edge. */
	public function isSelected():Bool
		return selected;

	/** Marks it selected, or not. */
	public function setSelected(value:Bool):Void
		selected = value;

	/** Its picture, or null while it has none. */
	public function getTexture():Null<Texture2D>
		return picture.getTexture();

	/** Shows texture as its picture, scaled into its square (null: none, the frame's face showing). */
	public function setTexture(texture:Null<Texture2D>):Void {
		picture.setTexture(texture);
		picture.setVisible(texture != null);
	}

	/** Its caption. */
	public function getCaption():String
		return label.getText();

	/** Reads caption under the picture. */
	public function setCaption(value:String):Void
		label.setText(value);

	/** The side of its picture's square, in units. */
	public function getSide():Float
		return side;

	override public function isFocusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.getTheme();
		this.clicked = enabled && (clicked || activated);
		face.setColor(held ? theme.getPressedColor() : hovered ? theme.getHoveredColor() : theme.getFaceColor());
		edge.setVisible(selected);
		picture.setColor(enabled ? 0xffffffff : 0x808080ff);
		label.setColor(enabled ? theme.getTextColor() : theme.getDisabledTextColor());
	}
}
