import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlights.*;
import helix.raylib.extras.Lighting.*;

class Main {
	static inline var GRASS_COUNT = 2000;
	static inline var HEDGE_CARDS = 10;

	static var camera:Camera3D;
	static var pbr:Shader;
	static var grassShader:Shader;
	static var ground:Model;
	static var crate:Model;
	static var leaf:Model;
	static var grass:Model;
	static var parts:Array<Model> = [];
	static var anims:Array<ModelAnimation>;
	static var anim:ModelAnimation;
	static var sun:Light;
	static var lantern:Light;
	static var crates:Array<Vector3> = [new Vector3(-2, 0.5, -1), new Vector3(-1, 0.5, -1), new Vector3(-1.5, 1.5, -1)];
	static var lanternPos = new Vector3(-3, 2.5, -1);
	static var frame = 0;
	static var hit = 0.0;
	static var ready = 0;
	static var angle = 0.0;

	static function makeLeafTexture():Texture2D {
		var img = GenImageColor(64, 64, BLANK);
		ImageDrawCircle(img, 32, 32, 22, new Color(50, 150, 50, 255));
		ImageDrawCircle(img, 32, 20, 14, new Color(50, 150, 50, 255));
		ImageDrawLine(img, 32, 4, 32, 60, new Color(20, 90, 20, 255));
		var tex = LoadTextureFromImage(img);
		UnloadImage(img);
		return tex;
	}

	static function makeGrassMesh():Mesh {
		var mesh = new Mesh();
		mesh.vertexCount = GRASS_COUNT * 3;
		mesh.triangleCount = GRASS_COUNT;
		var v:Array<Float> = [];
		var n:Array<Float> = [];
		var t:Array<Float> = [];
		for (i in 0...GRASS_COUNT) {
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
				n.push(-Math.sin(a)); n.push(0); n.push(Math.cos(a));
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

	static function drawScene(withGrass:Bool) {
		DrawModel(ground, new Vector3(0, 0, 0), 1, WHITE);
		for (c in crates)
			DrawModel(crate, c, 1, WHITE);
		for (i in 0...HEDGE_CARDS) {
			var x = -9 + i * 2.0;
			DrawModelEx(leaf, new Vector3(x, 0.8, -9.5), new Vector3(1, 0, 0), 90, new Vector3(1.8, 1, 1.6), WHITE);
		}
		for (p in parts)
			DrawModel(p, new Vector3(0, 0, 0), 1, WHITE);
		DrawModel(grass, new Vector3(0, 0, 0), 1, WHITE);
	}

	static function main() {
		InitWindow(1280, 720, "lantern-lit yard");
		SetTargetFPS(60);

		camera = new Camera3D();
		camera.position = new Vector3(12, 5, 0);
		camera.target = new Vector3(0, 1, 0);
		camera.up = new Vector3(0, 1, 0);
		camera.fovy = 45;
		camera.projection = CAMERA_PERSPECTIVE;

		pbr = LoadPbrShader();
		SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.12, 0.1, 0.15, 1.0], SHADER_UNIFORM_VEC4);

		sun = CreateLight(LIGHT_DIRECTIONAL, new Vector3(-6, 3, 4), Vector3Zero(), new Color(255, 140, 60, 255), pbr);
		lantern = CreateLight(LIGHT_POINT, lanternPos, Vector3Zero(), new Color(255, 210, 100, 255), pbr);
		SetShaderValue(pbr, GetShaderLocation(pbr, "lights[1].range"), [6.0], SHADER_UNIFORM_FLOAT);
		SetLightShadows(pbr, sun, {mapSize: 2048, distance: 30, cascades: 2, softness: 2});
		SetLightShadows(pbr, lantern, {mapSize: 1024});

		ground = LoadModelFromMesh(GenMeshPlane(20, 20, 1, 1));
		ground.materials[0].shader = pbr;
		ground.materials[0].maps[MATERIAL_MAP_ALBEDO].color = new Color(90, 80, 60, 255);

		crate = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		crate.materials[0].shader = pbr;
		crate.materials[0].maps[MATERIAL_MAP_ALBEDO].color = new Color(150, 105, 60, 255);

		var leafTex = makeLeafTexture();
		leaf = LoadModelFromMesh(GenMeshPlane(1.5, 1.5, 1, 1));
		leaf.materials[0].shader = pbr;
		leaf.materials[0].maps[MATERIAL_MAP_ALBEDO].texture = leafTex;
		SetMaterialAlphaCutoff(leaf.materials[0], 0.5);

		grass = LoadModelFromMesh(makeGrassMesh());
		LoadCompiledShaderAsync("shaders/grass.shader", function(s) {
			grassShader = s;
			grass.materials[0].shader = s;
			ready++;
		});
		for (name in ["Body", "Head", "Legs", "Feet"]) {
			LoadModelAsync("assets/characters/Adventurer_" + name + ".glb", function(m) {
				for (mat in m.materials)
					mat.shader = pbr;
				parts.push(m);
				ready++;
			});
		}
		LoadModelAnimationsAsync("assets/characters/Animations.glb", function(a) {
			anims = a;
			for (x in a)
				if (x.name == "CharacterArmature|Run")
					anim = x;
			ready++;
		});

		while (!WindowShouldClose()) {
			if (ready < 6) {
				BeginDrawing();
				ClearBackground(BLACK);
				DrawText("loading...", 10, 10, 20, WHITE);
				EndDrawing();
				continue;
			}
			var dt = GetFrameTime();
			angle += dt * 0.2;
			camera.position.x = Math.cos(angle) * 12;
			camera.position.z = Math.sin(angle) * 12;
			camera.position.y = 5;

			frame++;
			for (p in parts)
				UpdateModelAnimation(p, anim, frame % anim.frameCount);

			if (IsKeyPressed(KEY_SPACE))
				hit = 0.15;
			hit = Math.max(0, hit - dt);
			for (p in parts)
				for (mat in p.materials)
					SetMaterialEmissive(mat, WHITE, hit > 0 ? 1.0 : 0.0);

			SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
				SHADER_UNIFORM_VEC3);
			SetShaderValue(grassShader, GetShaderLocation(grassShader, "time"), [GetTime()], SHADER_UNIFORM_FLOAT);
			UpdateLightValues(pbr, sun);
			UpdateLightValues(pbr, lantern);

			BeginShadowMode(pbr, sun, camera);
			drawScene(true);
			EndShadowMode();
			BeginShadowMode(pbr, lantern, camera);
			drawScene(true);
			EndShadowMode();

			BeginDrawing();
			ClearBackground(new Color(40, 35, 60, 255));
			BeginMode3D(camera);
			drawScene(true);
			DrawSphere(lanternPos, 0.1, new Color(255, 210, 100, 255));
			EndMode3D();
			DrawFPS(10, 10);
			EndDrawing();
		}
		CloseWindow();
	}
}
