import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Device.*;
import helix.raylib.extras.Lights.*;
import helix.raylib.extras.Models.*;

// The retained graph's cost: the robots contender's scene drawn four ways, count=N mode=direct|direct-pbr|graph|graph-pbr|graph-math|graph-math-pbr.
// direct: UpdateModelAnimation and DrawModel, as the contender. direct-pbr: the same under LoadPbrShader, four fixed lights.
// graph: a tree (root, group of 10, robot, one node a mesh) with world matrices by raymath each frame, culled by six planes, sorted
// front to back, drawn by DrawMesh. graph-pbr: that under LoadPbrShader, six scene lights, the four nearest refilled per robot.
class Node {
	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var yaw:Float;
	public var scale:Float = 1;
	public var world:Matrix;
	public var children:Array<Node> = [];
	public var mesh = -1;
	public var robot = -1;
	public var depth = 0.0;
	final worldMath = new helix.math.Matrix3D();
	static final scaleMath = new helix.math.Matrix3D();
	static final turnMath = new helix.math.Matrix3D();
	static final moveMath = new helix.math.Matrix3D();
	static final localMath = new helix.math.Matrix3D();

	public function new(x:Float, y:Float, z:Float, yaw:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.yaw = yaw;
	}

	// update through helix-math's matrices, written in place, world then copied into the one Matrix a node keeps for DrawMesh.
	public function updateMath(parent:Null<helix.math.Matrix3D>):Void {
		helix.math.Matrix3D.fromScale(scale, scale, scale, scaleMath);
		helix.math.Matrix3D.fromRotation(0, 1, 0, yaw, turnMath);
		helix.math.Matrix3D.fromTranslation(x, y, z, moveMath);
		helix.math.Matrix3D.compose(scaleMath, turnMath, localMath);
		helix.math.Matrix3D.compose(localMath, moveMath, parent == null ? worldMath : localMath);
		if (parent == null) {} else
			helix.math.Matrix3D.compose(localMath, parent, worldMath);
		if (world == null)
			world = MatrixIdentity();
		var v = worldMath.values;
		world.m0 = v[0]; world.m1 = v[1]; world.m2 = v[2]; world.m3 = v[3];
		world.m4 = v[4]; world.m5 = v[5]; world.m6 = v[6]; world.m7 = v[7];
		world.m8 = v[8]; world.m9 = v[9]; world.m10 = v[10]; world.m11 = v[11];
		world.m12 = v[12]; world.m13 = v[13]; world.m14 = v[14]; world.m15 = v[15];
		for (c in children)
			c.updateMath(worldMath);
	}

	public function update(parent:Matrix):Void {
		var local = MatrixMultiply(MatrixMultiply(MatrixScale(scale, scale, scale), QuaternionToMatrix(QuaternionFromAxisAngle(new Vector3(0, 1, 0), yaw))),
			MatrixTranslate(x, y, z));
		world = parent == null ? local : MatrixMultiply(local, parent);
		for (c in children)
			c.update(world);
	}
}

class Main {
	static function emit(line:String):Void {
		#if js
		js.Browser.console.log(line);
		#else
		Sys.println(line);
		#end
	}

	static function main():Void {
		var target = #if js "page" #elseif sdl_gpu "native-sdlgpu" #else "native-gl" #end;
		var opt = GetRunOption("count");
		var count = opt == null ? 100 : Std.parseInt(opt);
		var mopt = GetRunOption("mode");
		var mode = mopt == null ? "direct" : mopt;
		var graph = StringTools.startsWith(mode, "graph"), pbr = StringTools.endsWith(mode, "pbr");
		InitWindow(1280, 720, "graph");
		var cols = Math.ceil(Math.sqrt(count));
		var w = cols * 4.0;
		var camera = new Camera(new Vector3(0, 0.9 * w, 0.9 * w), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var models:Array<Model> = [];
		var anims:Array<ModelAnimation> = null;
		LoadModelAsync("robot.glb", m -> models.push(m));
		LoadModelAnimationsAsync("robot.glb", a -> anims = a);
		var shader:Null<Shader> = null;
		var slots:Array<Light> = [];
		var scene = [
			{x: -w, z: -w, c: new Color(255, 240, 220, 255)},
			{x: w, z: -w, c: new Color(220, 230, 255, 255)},
			{x: -w, z: w, c: new Color(255, 220, 220, 255)},
			{x: w, z: w, c: new Color(220, 255, 220, 255)},
			{x: 0.0, z: -w, c: new Color(255, 255, 255, 255)},
			{x: 0.0, z: w, c: new Color(255, 255, 255, 255)}
		];
		if (pbr) {
			shader = LoadPbrShader();
			SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.4, 0.4, 0.45, 1.0], SHADER_UNIFORM_VEC4);
			for (i in 0...4)
				slots.push(CreateLight(LIGHT_POINT, new Vector3(scene[i].x, 6, scene[i].z), Vector3Zero(), scene[i].c, shader));
		}
		var root:Node = new Node(0, 0, 0);
		var drawn:Array<Node> = [];
		var ready = false, frame = -1, last = 0.0, done = false;
		var deltas:Array<Float> = [];
		var nodes = 0;
		var planes:Array<Array<Float>> = [for (_ in 0...6) [0.0, 0, 0, 0]];
		var near = [for (i in 0...scene.length) {i: i, d: 0.0}];
		while (!done && !WindowShouldClose()) {
			if (models.length < 1 || anims == null) {
				BeginDrawing();
				ClearBackground(RAYWHITE);
				EndDrawing();
				continue;
			}
			var model = models[0];
			if (!ready) {
				ready = true;
				if (pbr)
					for (m in model.materials)
						m.shader = shader;
				var group:Node = null;
				for (i in 0...count) {
					if (i % 10 == 0) {
						group = new Node(0, 0, 0);
						root.children.push(group);
						nodes++;
					}
					var robot = new Node(((i % cols) - (cols - 1) / 2.0) * 4.0, 0, (Std.int(i / cols) - (cols - 1) / 2.0) * 4.0);
					robot.robot = i;
					group.children.push(robot);
					nodes++;
					for (m in 0...model.meshCount) {
						var part = new Node(0, 0, 0);
						part.mesh = m;
						robot.children.push(part);
						nodes++;
					}
				}
			}
			var now = GetTime() * 1000;
			if (frame >= 120)
				deltas.push(now - last);
			last = now;
			var anim = anims[0];
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			if (pbr)
				SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z], SHADER_UNIFORM_VEC3);
			if (!graph) {
				for (i in 0...count) {
					UpdateModelAnimation(model, anim, (frame + 1 + i * 5) % anim.frameCount);
					DrawModel(model, new Vector3(((i % cols) - (cols - 1) / 2.0) * 4.0, 0, (Std.int(i / cols) - (cols - 1) / 2.0) * 4.0), 1, WHITE);
				}
			} else {
				if (mode.indexOf("-math") >= 0)
					root.updateMath(null);
				else
					root.update(null);
				// The six planes of the view and projection.
				var m = MatrixMultiply(rlGetMatrixModelview(), rlGetMatrixProjection());
				var r0 = [m.m0, m.m4, m.m8, m.m12], r1 = [m.m1, m.m5, m.m9, m.m13], r2 = [m.m2, m.m6, m.m10, m.m14], r3 = [m.m3, m.m7, m.m11, m.m15];
				for (k in 0...4) {
					planes[0][k] = r3[k] + r0[k];
					planes[1][k] = r3[k] - r0[k];
					planes[2][k] = r3[k] + r1[k];
					planes[3][k] = r3[k] - r1[k];
					planes[4][k] = r3[k] + r2[k];
					planes[5][k] = r3[k] - r2[k];
				}
				drawn.resize(0);
				for (g in root.children)
					for (robot in g.children) {
						var wm = robot.world, cx = wm.m12, cy = wm.m13 + 1.5, cz = wm.m14, inside = true;
						for (p in planes) {
							var len = Math.sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]);
							if ((p[0] * cx + p[1] * cy + p[2] * cz + p[3]) / len < -3) {
								inside = false;
								break;
							}
						}
						if (inside) {
							var dx = cx - camera.position.x, dy = cy - camera.position.y, dz = cz - camera.position.z;
							robot.depth = dx * dx + dy * dy + dz * dz;
							drawn.push(robot);
						}
					}
				drawn.sort((a, b) -> a.depth < b.depth ? -1 : a.depth > b.depth ? 1 : 0);
				for (robot in drawn) {
					if (pbr) {
						var wm = robot.world;
						for (n in near) {
							var l = scene[n.i], dx = l.x - wm.m12, dz = l.z - wm.m14;
							n.d = dx * dx + dz * dz;
						}
						near.sort((a, b) -> a.d < b.d ? -1 : a.d > b.d ? 1 : 0);
						for (s in 0...4) {
							var l = scene[near[s].i], slot = slots[s];
							slot.position.x = l.x;
							slot.position.z = l.z;
							slot.color = l.c;
							UpdateLightValues(shader, slot);
						}
					}
					UpdateModelAnimation(model, anim, (frame + 1 + robot.robot * 5) % anim.frameCount);
					for (part in robot.children)
						DrawMesh(model.meshes[part.mesh], model.materials[model.meshMaterial[part.mesh]], part.world);
				}
			}
			EndMode3D();
			EndDrawing();
			frame++;
			if (frame >= 720) {
				var sorted = deltas.copy();
				sorted.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
				var sum = 0.0;
				for (d in deltas)
					sum += d;
				emit('{"contender":"graph","mode":"$mode","target":"$target","count":$count,"nodes":$nodes,"drawn":${graph ? drawn.length : count},"mean_ms":${sum / deltas.length},"p95_ms":${sorted[Std.int(sorted.length * .95)]}}');
				done = true;
			}
		}
		CloseWindow();
	}
}
