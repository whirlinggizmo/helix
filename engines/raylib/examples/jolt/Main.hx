import helix.jolt.*;
import helix.jolt.Jolt.*;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raygui.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.extras.Lighting.*;

/** Jolt Physics: a stack of cubes on a floor, stepped by helix-jolt and drawn with raylib's models, a sphere dropped onto it each second
	until there are 30. Dragging turns the camera about the stack, a tap or click fires a sphere from the camera at the point under it,
	and Reset (or R) builds the stack again. A body Jolt has put to sleep is drawn darker: the stack starts asleep, and wakes where it is
	hit. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static inline final NON_MOVING = 0;
	static inline final MOVING = 1;
	static inline final SIDE = 5;
	static inline final LAYERS = 4;
	static inline final DROPPED = 30;
	static inline final MOST_FIRED = 30;

	/** How far the pointer moves, in design pixels, before a press turns the camera rather than firing. */
	static inline final TURN_AFTER = 8.0;

	static final COLORS = [
		new Color(230, 120, 80, 255),
		new Color(240, 190, 80, 255),
		new Color(120, 190, 110, 255),
		new Color(90, 160, 220, 255),
		new Color(170, 120, 210, 255)
	];

	/** The colors a body asleep is drawn in: each of `COLORS` darker. */
	static final ASLEEP = [
		for (color in COLORS)
			new Color(Std.int(color.r * 0.45), Std.int(color.g * 0.45), Std.int(color.b * 0.45), 255)
	];

	static var jolt:JoltInterface;
	static var bodies:BodyInterface;
	static var cubes:Array<BodyID> = [];
	static var spheres:Array<BodyID> = [];
	static var fired:Array<BodyID> = [];
	static var everyBody = [cubes, spheres, fired];
	static var step = 0;

	static function main():Void {
		InitWindow(800, 450, "helix-raylib: jolt");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		GuiSetStyle(DEFAULT, TEXT_SIZE, 20);
		var ready = false;
		Jolt.loadAsync(() -> {
			build();
			ready = true;
		});
		// Lit by a sun from above and to one side and a dim light from the other, so a cube's faces read apart from every side
		// (helix.raylib.extras.Lighting).
		var shader = LoadPbrShader();
		SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.35, 0.35, 0.4, 1.0], SHADER_UNIFORM_VEC4);
		CreateLight(LIGHT_DIRECTIONAL, new Vector3(4, 10, 6), new Vector3(0, 0, 0), WHITE, shader);
		CreateLight(LIGHT_DIRECTIONAL, new Vector3(-6, 3, -4), new Vector3(0, 0, 0), new Color(110, 110, 130, 255), shader);
		var cube = LoadModelFromMesh(GenMeshCube(0.94, 0.94, 0.94));
		var ball = LoadModelFromMesh(GenMeshSphere(0.5, 16, 16));
		for (model in [cube, ball]) {
			model.materials[0].shader = shader;
			model.materials[0].maps[MATERIAL_MAP_ROUGHNESS].value = 1;
		}
		var camera = new Camera3D(new Vector3(0, 0, 0), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var yaw = 0.6, pressedAt = new Vector2(0, 0), last = new Vector2(0, 0), turning = false;
		var visible = new Rectangle(0, 0, 0, 0),
			reset = new Rectangle(0, 0, 120, 48),
			mouse = new Vector2(0, 0),
			ray = new Ray();
		var position = new RVec3(),
			rotation = new Quat(0, 0, 0, 1),
			at = new Vector3(0, 0, 0),
			axis = new Vector3(0, 1, 0),
			one = new Vector3(1, 1, 1);
		var floor = new Vector2(24, 24);
		while (!WindowShouldClose()) {
			GetScreenVisibleArea(visible);
			reset.x = visible.x + visible.width - reset.width - 10;
			reset.y = visible.y + 10;
			GetMousePosition(mouse);
			var onReset = CheckCollisionPointRec(mouse, reset);
			if (IsMouseButtonPressed(MOUSE_BUTTON_LEFT) && !onReset) {
				pressedAt.x = last.x = mouse.x;
				pressedAt.y = last.y = mouse.y;
				turning = false;
			}
			if (IsMouseButtonDown(MOUSE_BUTTON_LEFT) && !onReset) {
				if (!turning
					&& Math.sqrt((mouse.x - pressedAt.x) * (mouse.x - pressedAt.x) + (mouse.y - pressedAt.y) * (mouse.y - pressedAt.y)) > TURN_AFTER)
					turning = true;
				if (turning)
					yaw -= (mouse.x - last.x) * 0.01;
				last.x = mouse.x;
				last.y = mouse.y;
			}
			camera.position.x = Math.sin(yaw) * 14;
			camera.position.y = 7;
			camera.position.z = Math.cos(yaw) * 14;
			camera.fovy = GetScreenFitFovy(45);
			SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			if (ready) {
				if (IsMouseButtonReleased(MOUSE_BUTTON_LEFT) && !turning && !onReset) {
					GetScreenToWorldRay(mouse, camera, ray);
					fire(ray);
				}
				if (step % 60 == 59 && spheres.length < DROPPED)
					drop(spheres.length);
				jolt.Step(1 / 60, 1);
				step++;
			}

			BeginDrawing();
			ClearBackground(new Color(24, 28, 38, 255));
			BeginMode3D(camera);
			DrawPlane(new Vector3(0, 0, 0), floor, new Color(70, 76, 92, 255));
			DrawGrid(24, 1);
			if (ready) {
				for (list in everyBody)
					for (i in 0...list.length) {
						var id = list[i];
						bodies.GetPositionAndRotation(id, position, rotation);
						at.x = position.GetX();
						at.y = position.GetY();
						at.z = position.GetZ();
						var angle = axisAngle(rotation, axis);
						// The stack's colors run diagonally through it, across its rows, columns and layers.
						var shade = list == cubes ? (i + Std.int(i / SIDE) * 2 + Std.int(i / (SIDE * SIDE))) % COLORS.length : i % COLORS.length;
						var color = bodies.IsActive(id) ? COLORS[shade] : ASLEEP[shade];
						DrawModelEx(list == cubes ? cube : ball, at, axis, angle, one, color);
					}
			}
			EndMode3D();
			if (!ready)
				DrawText("Loading Jolt Physics...", 290, 200, 20, LIGHTGRAY);
			else {
				var awake = 0;
				for (list in everyBody)
					for (id in list)
						if (bodies.IsActive(id))
							awake++;
				var count = cubes.length + spheres.length + fired.length;
				DrawText('$count bodies, $awake awake, ${GetFPS()} fps', Std.int(visible.x) + 10, Std.int(visible.y) + 10, 20, LIGHTGRAY);
				DrawText("Drag to turn. Tap to fire a sphere.", Std.int(visible.x) + 10, Std.int(visible.y + visible.height) - 28, 20, LIGHTGRAY);
				if (GuiButton(reset, "Reset") == 1 || IsKeyPressed(KEY_R))
					build();
			}
			EndDrawing();
		}
		UnloadModel(cube);
		UnloadModel(ball);
		UnloadShader(shader);
		if (ready)
			Jolt.destroy(jolt);
		CloseWindow();
	}

	/** Builds the world again: the floor and the stack, its cubes asleep until something hits them. */
	static function build():Void {
		if (jolt != null)
			Jolt.destroy(jolt);
		cubes.resize(0);
		spheres.resize(0);
		fired.resize(0);
		step = 0;
		var objectFilter = new ObjectLayerPairFilterTable(2);
		objectFilter.EnableCollision(NON_MOVING, MOVING);
		objectFilter.EnableCollision(MOVING, MOVING);
		var broadPhaseLayers = new BroadPhaseLayerInterfaceTable(2, 2);
		broadPhaseLayers.MapObjectToBroadPhaseLayer(NON_MOVING, new BroadPhaseLayer(0));
		broadPhaseLayers.MapObjectToBroadPhaseLayer(MOVING, new BroadPhaseLayer(1));
		var settings = new JoltSettings();
		settings.mObjectLayerPairFilter = objectFilter;
		settings.mBroadPhaseLayerInterface = broadPhaseLayers;
		settings.mObjectVsBroadPhaseLayerFilter = new ObjectVsBroadPhaseLayerFilterTable(broadPhaseLayers, 2, objectFilter, 2);
		jolt = new JoltInterface(settings);
		bodies = jolt.GetPhysicsSystem().GetBodyInterface();

		bodies.CreateAndAddBody(new BodyCreationSettings(new BoxShape(new Vec3(12, 0.5, 12)), new RVec3(0, -0.5, 0), Quat.sIdentity(), EMotionType_Static,
			NON_MOVING),
			EActivation_DontActivate);
		var box = new BoxShape(new Vec3(0.5, 0.5, 0.5));
		for (layer in 0...LAYERS)
			for (x in 0...SIDE)
				for (z in 0...SIDE) {
					var settings = new BodyCreationSettings(box, new RVec3(x - (SIDE - 1) / 2, 0.5 + layer, z - (SIDE - 1) / 2), Quat.sIdentity(),
						EMotionType_Dynamic, MOVING);
					cubes.push(bodies.CreateAndAddBody(settings, EActivation_DontActivate));
				}
	}

	/** Drops the nth sphere from above the stack, each at its own place on a spiral, so every run drops the same. */
	static function drop(n:Int):Void {
		var angle = n * 2.39996, radius = 0.4 + (n % 5) * 0.4;
		var settings = new BodyCreationSettings(heavySphere(), new RVec3(Math.cos(angle) * radius, 10, Math.sin(angle) * radius), Quat.sIdentity(),
			EMotionType_Dynamic, MOVING);
		spheres.push(bodies.CreateAndAddBody(settings, EActivation_Activate));
	}

	/** Fires a sphere along a ray, from a meter in front of the camera, the oldest fired one removed past `MOST_FIRED`. */
	static function fire(ray:Ray):Void {
		if (fired.length == MOST_FIRED) {
			var oldest = fired.shift();
			bodies.RemoveBody(oldest);
			bodies.DestroyBody(oldest);
		}
		var start = new RVec3(ray.position.x + ray.direction.x, ray.position.y + ray.direction.y, ray.position.z + ray.direction.z);
		var settings = new BodyCreationSettings(heavySphere(), start, Quat.sIdentity(), EMotionType_Dynamic, MOVING);
		var id = bodies.CreateAndAddBody(settings, EActivation_Activate);
		bodies.SetLinearVelocity(id, new Vec3(ray.direction.x * 25, ray.direction.y * 25, ray.direction.z * 25));
		fired.push(id);
	}

	/** A sphere ten times a cube's density, so it breaks the stack rather than bouncing off it. */
	static function heavySphere():SphereShape {
		var sphere = new SphereShape(0.5);
		sphere.SetDensity(10000);
		return sphere;
	}

	/** A rotation's axis, into `axis`, and its angle in degrees: `DrawModelEx`'s rotation. */
	static function axisAngle(rotation:Quat, axis:Vector3):Float {
		var w = Math.max(-1, Math.min(1, rotation.GetW()));
		var s = Math.sqrt(1 - w * w);
		if (s < 1e-6) {
			axis.x = 0;
			axis.y = 1;
			axis.z = 0;
			return 0;
		}
		axis.x = rotation.GetX() / s;
		axis.y = rotation.GetY() / s;
		axis.z = rotation.GetZ() / s;
		return 2 * Math.acos(w) * RAD2DEG;
	}
}
