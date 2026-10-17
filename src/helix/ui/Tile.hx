package helix.ui;

import helix.render2d.Node2D;
import helix.render2d.Texture2D;

/** A picture with a caption under it, in a frame: an inventory's item, a character creator's choice, a level to pick. Clicked by the pointer,
	or activated with focus by Enter, Space or a pad's South; marked selected by the game (one of a group, as the game decides: clicked,
	then selected). Its picture can come later (a thumbnail still being made): until then, and with none, the frame shows the theme's face
	color. Ask clicked once a frame. */
class Tile extends Widget {
	var face:Node2D;
	var picture:Node2D;
	var label:Node2D;
	var edge:Node2D;

	@:allow(helix.ui.Ui)
	function new(ui:Ui, name:String, texture:Null<Texture2D>, caption:String, side:Float) {
		super(ui, name);
		this.side = side;
		var theme = ui.theme, pad = theme.padding;
		face = Node2D.rectangle(1, 1, theme.faceColor);
		face.setPivot(0, 0);
		face.setCornerRadius(theme.cornerRadius);
		edge = Node2D.rectangle(1, 1, theme.accentColor);
		edge.setPivot(0, 0);
		edge.setCornerRadius(theme.cornerRadius + 2);
		edge.pickable = false;
		edge.visible = false;
		picture = Node2D.sprite(texture);
		picture.setPivot(0, 0);
		picture.pickable = false;
		label = Node2D.text(caption, theme.textSize * .8, theme.textColor, Center, theme.font);
		label.pickable = false;
		for (n in [edge, face, picture, label])
			root.addChild(n);
		// The edge a little outside the face, the picture square inside it, the caption under the picture.
		box = Box.stack(edge);
		var inner = Box.column(face);
		inner.setPadding(pad, pad, pad, pad);
		inner.gap = pad / 2;
		inner.setAlign(Start, Center);
		var image = Box.of(picture);
		image.setSizing(Fixed(side), Fixed(side));
		inner.add(image);
		inner.add(Box.of(label));
		box.setPadding(3, 3, 3, 3);
		box.add(inner);
		picture.visible = texture != null;
	}

	/** Whether it was clicked or activated this frame. */
	public var clicked(default, null):Bool = false;

	/** Whether it's marked selected: drawn with an accent edge. */
	public var selected:Bool = false;

	/** Its picture, or null while it has none. */
	public var texture(get, set):Null<Texture2D>;

	function get_texture():Null<Texture2D>
		return picture.getTexture();

	function set_texture(texture:Null<Texture2D>):Null<Texture2D> {
		picture.setTexture(texture);
		picture.visible = texture != null;
		return texture;
	}

	/** Its caption, under the picture. */
	public var caption(get, set):String;

	function get_caption():String
		return label.getText();

	function set_caption(value:String):String {
		label.setText(value);
		return value;
	}

	/** The side of its picture's square, in units. */
	public var side(default, null):Float;

	override function get_focusable():Bool
		return true;

	override function target():Null<Node2D>
		return face;

	override function update(hovered:Bool, held:Bool, clicked:Bool, focused:Bool, activated:Bool, step:Int):Void {
		var theme = ui.theme;
		this.clicked = enabled && (clicked || activated);
		face.color = held ? theme.pressedColor : hovered ? theme.hoveredColor : theme.faceColor;
		edge.visible = selected;
		picture.color = enabled ? 0xffffffff : 0x808080ff;
		label.color = enabled ? theme.textColor : theme.disabledTextColor;
	}
}
