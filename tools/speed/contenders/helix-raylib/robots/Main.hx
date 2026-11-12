import helix.raylib.*;
import helix.raylib.Raylib.*;

// raylib's models_animation, many at once: N robots each posed by UpdateModelAnimation at its own frame, drawn with DrawModel, for
// tools/gen_speed.py. count=N run option. Natively, gc-min=MB sets hxcpp's minimum working memory (cpp.vm.Gc.setMinimumWorkingMemory)
// at start, to measure whether that collector setting changes the frame time or the collector's share of it.
class Main {
	static function emit(line:String):Void {
		Sys.println(line);
	}

	// A run option as gen_speed.py passes it, --count=N on the command line (a page's URL query, ?count=N, is its command line).
	static function option(name:String):Null<String> {
		for (arg in Sys.args())
			if (StringTools.startsWith(arg, '--$name='))
				return arg.substr(name.length + 3);
		return null;
	}

	static function main():Void {
		var target = #if js "page" #elseif sdl_gpu "native-sdlgpu" #else "native-gl" #end;
		var opt = option("count");
		var count = opt == null ? 100 : Std.parseInt(opt);
		var copt = option("chunk");
		#if cpp
		var gcMin = option("gc-min");
		if (gcMin != null)
			cpp.vm.Gc.setMinimumWorkingMemory(Std.parseInt(gcMin) * 1024 * 1024);
		#end
		var chunk = copt == null ? count : Std.parseInt(copt); // robots a raylib frame draws; a measured frame is count of them
		InitWindow(1280, 720, "skin helix");
		var cols = Math.ceil(Math.sqrt(count));
		var w = cols * 4.0;
		var camera = new Camera(new Vector3(0, 0.9 * w, 0.9 * w), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		LoadModelAsync("robot.glb", m -> models.push(m));
		LoadModelAnimationsAsync("robot.glb", a -> anims = a);
		var frame = -1;
		var last = 0.0;
		var deltas:Array<Float> = [];
		var upds = 0.0;
		var done = false;
		// The robots drawn so far in the measured frame, chunk of them a raylib frame, and their animation updates' time.
		var i = 0;
		var u = 0.0;
		while (!done && !WindowShouldClose()) {
			BeginDrawing();
			if (models.length < 1 || anims == null) {
				ClearBackground(RAYWHITE);
				EndDrawing();
				continue;
			}
			if (i == 0) {
				var now = GetTime() * 1000;
				if (frame >= 120)
					deltas.push(now - last);
				last = now;
				ClearBackground(RAYWHITE);
			}
			var anim = anims[0];
			BeginMode3D(camera);
			var stop = i + chunk < count ? i + chunk : count;
			while (i < stop) {
				var t0 = GetTime();
				UpdateModelAnimation(models[0], anim, (frame + 1 + i * 5) % anim.frameCount);
				u += GetTime() - t0;
				DrawModel(models[0], new Vector3(((i % cols) - (cols - 1) / 2.0) * 4.0, 0, (Std.int(i / cols) - (cols - 1) / 2.0) * 4.0), 1, WHITE);
				i++;
			}
			EndMode3D();
			EndDrawing();
			if (i < count)
				continue;
			i = 0;
			if (frame >= 120)
				upds += u * 1000;
			u = 0;
			frame++;
			if (frame >= 720) {
				var sorted = deltas.copy();
				sorted.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
				var sum = 0.0;
				for (d in deltas)
					sum += d;
				var v = 0;
				for (m in models[0].meshes)
					v += m.vertexCount;
				emit('{"contender":"helix-raylib","target":"$target","count":$count,"verts":$v,"bones":${models[0].boneCount},"mean_ms":${sum / 600},"p95_ms":${sorted[570]},"upd_ms":${upds / 600}}');
				done = true;
			}
		}
		CloseWindow();
	}
}
