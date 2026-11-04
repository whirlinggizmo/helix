import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Window.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.Rlgl.*;

// scene.c's cubemaps, drawn by helix-raylib: the third frame after the skybox's image loads saved as helix.png. Its files (web/) are raylib's
// skybox example's image and shaders.
class Main {
	static final CUBE_VS = "#version 330
in vec3 vertexPosition;
uniform mat4 mvp;
out vec3 fragPosition;
void main() {
    fragPosition = vertexPosition;
    gl_Position = mvp*vec4(vertexPosition, 1.0);
}
";

	static final CUBE_FS = "#version 330
in vec3 fragPosition;
uniform samplerCube cubeMap;
uniform vec4 colDiffuse;
out vec4 finalColor;
void main() {
    finalColor = texture(cubeMap, fragPosition)*colDiffuse;
}
";

	// Face i painted at (x, y): its color, and a white bar along its top from its left, so a face turned or mirrored shows.
	static function paint(image:Image, x:Int, y:Int, size:Int, i:Int):Void {
		var colors = [RED, LIME, BLUE, GOLD, PURPLE, ORANGE];
		ImageDrawRectangle(image, x, y, size, size, colors[i]);
		ImageDrawRectangle(image, x + 1, y + 1, Std.int(size / 2), Std.int(size / 5), WHITE);
		ImageDrawRectangle(image, x + size - 3, y + size - 3, 2, 2, BLACK);
	}

	static function main():Void {
		InitWindow(640, 360, "cubemaps");
		var camera = new Camera(new Vector3(0, 0, 12), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var s = 16;
		var column = GenImageColor(s, s * 6, BLANK),
			row = GenImageColor(s * 6, s, BLANK);
		for (i in 0...6) {
			paint(column, 0, s * i, s, i);
			paint(row, s * i, 0, s, i);
		}
		ImageFormat(row, PIXELFORMAT_UNCOMPRESSED_GRAYSCALE);
		var threeByFour = [[1, 1], [1, 3], [1, 0], [1, 2], [0, 1], [2, 1]];
		var fourByThree = [[2, 1], [0, 1], [1, 0], [1, 2], [1, 1], [3, 1]];
		var tall = GenImageColor(s * 3, s * 4, DARKGRAY),
			wide = GenImageColor(s * 4, s * 3, DARKGRAY);
		for (i in 0...6) {
			paint(tall, threeByFour[i][0] * s, threeByFour[i][1] * s, s, i);
			paint(wide, fourByThree[i][0] * s, fourByThree[i][1] * s, s, i);
		}
		ImageDrawRectangle(wide, 3 * s, s, s, Std.int(s / 2), new Color(0, 200, 255, 128));
		var square = GenImageColor(32, 32, RED);
		var cubes = [
			LoadTextureCubemap(column, CUBEMAP_LAYOUT_LINE_VERTICAL),
			LoadTextureCubemap(row, CUBEMAP_LAYOUT_AUTO_DETECT),
			LoadTextureCubemap(tall, CUBEMAP_LAYOUT_AUTO_DETECT),
			LoadTextureCubemap(wide, CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE),
			LoadTextureCubemap(wide, CUBEMAP_LAYOUT_LINE_VERTICAL),
			LoadTextureCubemap(tall, CUBEMAP_LAYOUT_CROSS_FOUR_BY_THREE)
		];
		var none = LoadTextureCubemap(square, CUBEMAP_LAYOUT_AUTO_DETECT);
		var skyCube:TextureCubemap = null;
		var skybox = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		skybox.materials[0].shader = LoadShader("skybox.vs", "skybox.fs");
		var shader = skybox.materials[0].shader;
		SetShaderValue(shader, GetShaderLocation(shader, "environmentMap"), [MATERIAL_MAP_CUBEMAP], SHADER_UNIFORM_INT);
		SetShaderValue(shader, GetShaderLocation(shader, "doGamma"), [0], SHADER_UNIFORM_INT);
		SetShaderValue(shader, GetShaderLocation(shader, "vflipped"), [0], SHADER_UNIFORM_INT);
		LoadImageAsync("skybox.png", sky -> {
			skyCube = LoadTextureCubemap(sky, CUBEMAP_LAYOUT_AUTO_DETECT);
			skybox.materials[0].maps[MATERIAL_MAP_CUBEMAP].texture = skyCube;
		});
		var sampling = LoadShaderFromMemory(CUBE_VS, CUBE_FS);
		sampling.locs[SHADER_LOC_MAP_CUBEMAP] = GetShaderLocation(sampling, "cubeMap");
		var models = [
			for (i in 0...6) {
				var model = LoadModelFromMesh(GenMeshCube(1.6, 1.6, 1.6));
				model.materials[0].shader = sampling;
				model.materials[0].maps[MATERIAL_MAP_CUBEMAP].texture = cubes[i];
				model;
			}
		];
		var frame = -1;
		while (!WindowShouldClose()) {
			if (skyCube != null && frame < 0)
				frame = 0;
			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (frame >= 0) {
				BeginMode3D(camera);
				rlDisableBackfaceCulling();
				rlDisableDepthMask();
				DrawModel(skybox, new Vector3(0, 0, 0), 1, WHITE);
				rlEnableBackfaceCulling();
				rlEnableDepthMask();
				for (i in 0...6) {
					var x = -6.5 + 2.6 * i;
					DrawModelEx(models[i], new Vector3(x, 1.4, 0), new Vector3(1, -1, 0), 54.7356, new Vector3(1, 1, 1), WHITE);
					DrawModelEx(models[i], new Vector3(x, -1.4, 0), new Vector3(1, -1, 0), -125.2644, new Vector3(1, 1, 1), WHITE);
				}
				EndMode3D();
				for (i in 0...8) {
					var c = i < 6 ? cubes[i] : i == 6 ? skyCube : none;
					DrawText('${c.id > 0 ? 1 : 0} ${c.width} ${c.height} ${c.mipmaps} ${c.format}', 8 + 78 * i, 340, 10, BLACK);
				}
			}
			if (frame == 2)
				TakeScreenshotAsync("helix.png");
			EndDrawing();
			if (frame >= 0)
				frame++;
		}
		CloseWindow();
	}
}
