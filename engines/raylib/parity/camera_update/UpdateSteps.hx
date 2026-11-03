import helix.ray.Camera3D;
import helix.ray.Raylib.*;
import helix.ray.Vector3;
import helix.ray.internal.Automation;
import helix.ray.internal.Runtime;

// helix-ray's UpdateCamera in each mode over scripted input frames (frames.txt, compiled in), each frame 1/60 s, its input played as
// automation state: the camera after each, as ref.c prints raylib's rcamera for the same frames. A Z-up start is camera_update_62's.
@:access(helix.ray.internal.Automation)
@:access(helix.services.time.Time)
class UpdateSteps {
	static function out(s:String)
		Parity.line(s);

	static function main() {
		var time = Type.createEmptyInstance(helix.services.time.Time);
		time.realDelta = 1 / 60;
		Runtime.time = time;
		var frames = haxe.Resource.getString("frames").split("\n").filter(l -> l != "");
		var modes = [
			CAMERA_FREE,
			CAMERA_FIRST_PERSON,
			CAMERA_THIRD_PERSON,
			CAMERA_ORBITAL,
			CAMERA_CUSTOM
		];
		var starts = [
			[[0., 2., 4.], [0., 2., 0.], [0., 1., 0.]],
			[[3., -1., 2.], [-1., .5, -4.], [.2, .9, .1]]
		];
		var s = 0;
		for (start in starts) {
			for (mode in modes) {
				var c = new Camera3D(new Vector3(start[0][0], start[0][1], start[0][2]), new Vector3(start[1][0], start[1][1], start[1][2]),
					new Vector3(start[2][0], start[2][1], start[2][2]), 60, CAMERA_PERSPECTIVE);
				var a = new Automation();
				Automation.active = a;
				for (round in 0...2)
					for (i in 0...frames.length) {
						var t = frames[i].split(" ");
						for (k in 0...512) {
							a.previousKeys[k] = a.keys[k];
							a.keys[k] = false;
						}
						for (b in 0...8)
							a.buttons[b] = false;
						a.previousMouseX = a.mouseX;
						a.previousMouseY = a.mouseY;
						a.wheelX = 0;
						a.wheelY = 0;
						a.pads[0] = false;
						for (x in 0...8)
							a.padAxes[x] = 0;
						switch t[0] {
							case "mouse" | "pan":
								a.mouseX += Std.parseFloat(t[1]);
								a.mouseY += Std.parseFloat(t[2]);
								if (t[0] == "pan")
									a.buttons[MOUSE_BUTTON_MIDDLE] = true;
							case "keys" | "press":
								for (k in t.slice(1))
									a.keys[Std.parseInt(k)] = true;
							case "wheel":
								a.wheelY = Std.parseFloat(t[1]);
							case "pad":
								a.pads[0] = true;
								a.padAxes[GAMEPAD_AXIS_RIGHT_X] = Std.parseFloat(t[1]);
								a.padAxes[GAMEPAD_AXIS_RIGHT_Y] = Std.parseFloat(t[2]);
								a.padAxes[GAMEPAD_AXIS_LEFT_Y] = Std.parseFloat(t[3]);
								a.padAxes[GAMEPAD_AXIS_LEFT_X] = Std.parseFloat(t[4]);
						}
						UpdateCamera(c, mode);
						var p = c.position, g = c.target, u = c.up;
						out('s$s.m$mode.r$round.f$i ${[p.x, p.y, p.z, g.x, g.y, g.z, u.x, u.y, u.z].join(" ")}');
					}
			}
			s++;
		}
		Parity.save();
	}
}
