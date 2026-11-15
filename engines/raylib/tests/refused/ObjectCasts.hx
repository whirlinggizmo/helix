import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.VirtualButtonOptions;

/** A program casting objects to classes and to `Color`, which doesn't build on any target: `helix.py test` builds it for JS and natively and checks
	that each cast is refused with the way to write it, and that writing the object where the class is expected, or casting a value
	that isn't an object, isn't refused. */
class ObjectCasts {
	static function main():Void {
		var buttons:Array<VirtualButtonOptions> = [];
		buttons.push(cast {button: GAMEPAD_BUTTON_MIDDLE_RIGHT, label: "II"});
		var at:Vector2 = cast {x: 1.0, y: 2.0};
		var image:Image = cast {width: 2, height: 2};
		var tint:Color = cast {
			r: 230,
			g: 41,
			b: 55,
			a: 255
		};
		var maybe:Null<Vector2> = cast {x: 1.0, y: 2.0};
		var red:Color = {r: 230, g: 41, b: 55};
		var written:Array<VirtualButtonOptions> = [{button: GAMEPAD_BUTTON_MIDDLE_RIGHT, label: "II"}];
		var value:Dynamic = 3;
		var count:Int = cast value;
	}
}
