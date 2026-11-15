import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlights.*;
import helix.raylib.extras.Lighting.*;

class Main {
	static var camera:Camera3D;
	static var pbr:Shader;
	static var grassShader:Shader;
	static var sun:Light;
	static var lantern:Light;
	static var ground:Model;
	static var crates:Array<Model> = [];
	static var cratePos:Array<Vector3> = [];
	static var grass:Model;
	static var leaf:Model;
	static var leafPos:Array<Vector3> = [];
	static var parts:Array<Model> = [];
	static var anims:Array<ModelAnimation>;
	static var animFrame = 0;
	static var hitTime = 0.0;
	static var angle = 0.0;
	static var loadedCount = 0;
	static var grassTimeLoc:Int;

	static function main() {
		InitWindow(1280, 720, "lantern-lit yard");
		SetTargetFPS(60);
		camera = new Camera3D(new Vector3(12, 5, 0), new Vector3(0, 1, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);

		pbr = LoadPbrShader();
		SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.08, 0.07, 0.09, 1.0], SHADER_UNIFORM_VEC4);
		SetShaderValue(pbr, GetShaderLocation(pbr, "lights[0].intensity"), [1.0], SHADER_UNIFORM_FLOAT);
		SetShaderValue(pbr, GetShaderLocation(pbr, "lights[1].range"), [6.0], SHADER_UNIFORM_FLOAT);
		SetShaderValue(pbr, GetShaderLocation(pbr, "lights[1].intensity"), [1.5], SHADER_UNIFORM_FLOAT);

		sun = CreateLight(LIGHT_DIRECTIONAL, new Vector3(-8, 4, -6), Vector3Zero(), new Color(255, 140, 60, 255), pbr);
		lantern = CreateLight(LIGHT_POINT, new Vector3(2.5, 2.5, 2.5), Vector3Zero(), new Color(255, 210, 110, 255), pbr);
		SetLightShadows(pbr, sun, {mapSize: 2048, distance: 30, cascades: 2});
		SetLightShadows(pbr, lantern, {mapSize: 1024});

		// ground and crates
		ground = LoadModelFromMesh(GenMeshPlane(20, 20, 1, 1));
		ground.materials[0].shader = pbr;
		ground.materials[0].maps[MATERIAL_MAP_ALBEDO].color = new Color(90, 80, 60, 255);
		cratePos = [new Vector3(3, 0.5, 2), new Vector3(3, 0.5, 3.2), new Vector3(3.6, 1.5, 2.4)];
		for (i in 0...3) {
			var c = LoadModelFromMesh(GenMeshCube(1, 1, 1));
			c.materials[0].shader = pbr;
			c.materials[0].maps[MATERIAL_MAP_ALBEDO].color = new Color(150, 100, 50, 255);
			crates.push(c);
		}

		// warden
		var names = ["Body", "Head", "Legs", "Feet"];
		for (i in 0...names.length) {
			parts.push(null);
			LoadModelAsync("assets/characters/Adventurer_" + names[i] + ".glb", function(m) {
				for (mat in m.materials)
					mat.shader = pbr;
				parts[i] = m;
				loadedCount++;
			});
		}
		LoadModelAnimationsAsync("assets/characters/Animations.glb", function(a) {
			anims = a;
			loadedCount++;
		});

		// leaf hedge
		var img = GenImageColor(64, 64, BLANK);
		ImageDrawCircle(img, 32, 20, 18, new Color(40, 150, 50, 255));
		ImageDrawCircle(img, 32, 40, 18, new Color(40, 150, 50, 255));
		ImageDrawTriangle(img, new Vector2(32, 2), new Vector2(10, 32), new Vector2(54, 32), new Color(40, 150, 50, 255));
		var leafTex = LoadTextureFromImage(img);
		UnloadImage(img);
		leaf = LoadModelFromMesh(GenMeshPlane(1.2, 1.2, 1, 1));
		leaf.transform = MatrixRotateX(Math.PI / 2);
		leaf.materials[0].shader = pbr;
		leaf.materials[0].maps[MATERIAL_MAP_ALBEDO].texture = leafTex;
		SetMaterialAlphaCutoff(leaf.materials[0], 0.5);
		for (i in 0...12)
			leafPos.push(new Vector3(-9 + i * 1.0, 0.7, -9.5));

		// grass
		var grassMesh = buildGrass(2000);
		grass = LoadModelFromMesh(grassMesh);
		LoadCompiledShaderAsync("shaders/grass.shader", function(sh) {
			grassShader = sh;
			grassTimeLoc = GetShaderLocation(sh, "time");
			grass.materials[0].shader = sh;
			loadedCount++;
		});

		while (!WindowShouldClose()) {
			if (loadedCount < 6) {
				BeginDrawing();
				ClearBackground(BLACK);
				DrawText("loading...", 10, 10, 20, WHITE);
				EndDrawing();
				continue;
			}
			var dt = GetFrameTime();
			update(dt);
			draw();
		}
		CloseWindow();
	}

	static function buildGrass(count:Int):Mesh {
		var mesh = new Mesh();
		mesh.vertexCount = count * 3;
		mesh.triangleCount = count;
		var v:Array<Float> = [];
		var n:Array<Float> = [];
		var t:Array<Float> = [];
		for (i in 0...count) {
			var x = GetRandomValue(-1000, 1000) / 100.0;
			var z = GetRandomValue(-1000, 1000) / 100.0;
			var h = GetRandomValue(20, 40) / 100.0;
			var a = GetRandomValue(0, 628) / 100.0;
			var dx = Math.cos(a) * 0.015;
			var dz = Math.sin(a) * 0.015;
			v.push(x - dx); v.push(0); v.push(z - dz);
			v.push(x + dx); v.push(0); v.push(z + dz);
			v.push(x); v.push(h); v.push(z);
			for (k in 0...3) {
				n.push(0); n.push(1); n.push(0);
			}
			t.push(0); t.push(0);
			t.push(1); t.push(0);
			t.push(0.5); t.push(1);
		}
		mesh.vertices = v;
		mesh.normals = n;
		mesh.texcoords = t;
		UploadMesh(mesh, false);
		return mesh;
	}

	static function update(dt:Float) {
		angle += dt * 0.2;
		camera.position = new Vector3(Math.cos(angle) * 12, 5, Math.sin(angle) * 12);

		animFrame = (animFrame + 1) % anims[0].frameCount;
		for (p in parts)
			UpdateModelAnimation(p, anims[0], animFrame);

		if (IsKeyPressed(KEY_SPACE))
			hitTime = 0.15;
		hitTime = Math.max(0, hitTime - dt);
		for (p in parts)
			for (m in p.materials)
				SetMaterialEmissive(m, WHITE, hitTime > 0 ? 1.0 : 0.0);

		SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
			SHADER_UNIFORM_VEC3);
		SetShaderValue(grassShader, grassShader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
			SHADER_UNIFORM_VEC3);
		SetShaderValue(grassShader, grassTimeLoc, [GetTime()], SHADER_UNIFORM_FLOAT);
		UpdateLightValues(pbr, sun);
		UpdateLightValues(pbr, lantern);
	}

	static function drawScene() {
		DrawModel(ground, Vector3Zero(), 1, WHITE);
		for (i in 0...3)
			DrawModel(crates[i], cratePos[i], 1, WHITE);
		for (p in parts)
			DrawModel(p, Vector3Zero(), 1, WHITE);
		DrawModel(grass, Vector3Zero(), 1, WHITE);
		for (p in leafPos)
			DrawModel(leaf, p, 1, WHITE);
	}

	static function draw() {
		BeginShadowMode(pbr, sun, camera);
		drawScene();
		EndShadowMode();
		BeginShadowMode(pbr, lantern, camera);
		drawScene();
		EndShadowMode();

		BeginDrawing();
		ClearBackground(new Color(30, 25, 45, 255));
		BeginMode3D(camera);
		drawScene();
		DrawSphere(lantern.position, 0.1, new Color(255, 210, 110, 255));
		EndMode3D();
		DrawFPS(10, 10);
		EndDrawing();
	}
}
