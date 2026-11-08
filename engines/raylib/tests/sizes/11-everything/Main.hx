// helix-raylib's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one everything: every function of Raylib, Raymath, Rlgl, Raygui and helix.raylib.extras a program can call, and every file reader.
import helix.raylib.Raylib.*;
import helix.raylib.extras.Textures.*;
import helix.raylib.extras.Text.*;
import helix.raylib.extras.Models.*;
import helix.raylib.extras.Audio.*;

/** helix-raylib's high-water mark: a program calling every function of `Raylib`, `Raymath`, `Rlgl`, `Raygui` and `helix.raylib.extras` that compiles (`Everything.calls`
	writes them as the program builds), and each macro function that chooses a reader by a constant file name (DECISIONS 29) once for each
	reader, so nothing of helix-raylib can be left out. A game approaches it from below. It is built and measured, never run: its calls are
	given nothing, and its files aren't there. */
@:adds("helix.formats.deflate", "helix.formats.gif", "helix.formats.obj", "helix.formats.png", "helix.formats.qoa", "helix.formats.wav",
	"helix.geometry.Geometry2D", "helix.math.Bounds2D", "helix.math.DistanceField2D", "helix.platform.adapters.clipboard.dom",
	"helix.platform.adapters.export.download", "helix.platform.adapters.tilt.dom", "helix.math.Interpolate", "helix.raylib.internal.Automation",
	"helix.raylib.internal.DroppedFiles", "helix.raylib.internal.FontAtlases", "helix.raylib.internal.GuiIcons", "helix.raylib.internal.Mipmaps",
	"helix.raylib.internal.ObjModels", "helix.raylib.internal.ParShapes", "helix.raylib.internal.Stereo", "helix.raylib.internal.Waves",
	"helix.raylib.modules.RDebug", "helix.raylib.modules.RDevice", "helix.raylib.modules.RGui", "helix.raylib.modules.RGuiAsync",
	"helix.raylib.modules.RGuiControls", "helix.raylib.modules.RGuiSkins", "helix.raylib.modules.RModelsPosed", "helix.services.input.Tilt",
	"helix.services.input.TiltAxis", "helix.services.screenshots", "helix.raylib.internal.VirtualGamepads", "helix.raylib.modules.RVirtualGamepad",
	"helix.services.input.VirtualGamepad", "helix.services.input.VirtualGamepadOptions", "helix.services.input.VirtualStick",
	"helix.services.input.VirtualStickBase", "helix.services.input.VirtualStickOptions")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		InitAudioDevice();
		while (!WindowShouldClose()) {
			BeginDrawing();
			Everything.calls();
			// The readers chosen by a constant name as the program builds, each once: models, images, textures, fonts, animated images
			// and waves, from files and from memory.
			LoadModelAsync("a.glb", loaded -> Everything.result = loaded);
			LoadModelAsync("a.gltf", loaded -> Everything.result = loaded);
			LoadModelAsync("a.obj", loaded -> Everything.result = loaded);
			LoadImageAsync("a.png", loaded -> Everything.result = loaded);
			LoadImageAsync("a.gif", loaded -> Everything.result = loaded);
			LoadImageFromMemoryAsync(".png", Everything.value, 0, loaded -> Everything.result = loaded);
			LoadImageFromMemoryAsync(".gif", Everything.value, 0, loaded -> Everything.result = loaded);
			LoadTextureAsync("a.png", loaded -> Everything.result = loaded);
			LoadTextureAsync("a.gif", loaded -> Everything.result = loaded);
			LoadFontAsync("a.ttf", loaded -> Everything.result = loaded);
			LoadFontAsync("a.fnt", loaded -> Everything.result = loaded);
			LoadFontAsync("a.png", loaded -> Everything.result = loaded);
			LoadFontAsync("a.gif", loaded -> Everything.result = loaded);
			LoadImageAnimAsync("a.gif", [0], loaded -> Everything.result = loaded);
			LoadImageAnimAsync("a.png", [0], loaded -> Everything.result = loaded);
			LoadImageAnimFromMemoryAsync(".gif", Everything.value, 0, [0], loaded -> Everything.result = loaded);
			LoadImageAnimFromMemoryAsync(".png", Everything.value, 0, [0], loaded -> Everything.result = loaded);
			LoadWaveAsync("a.wav", loaded -> Everything.result = loaded);
			LoadWaveAsync("a.ogg", loaded -> Everything.result = loaded);
			LoadWaveAsync("a.mp3", loaded -> Everything.result = loaded);
			LoadWaveAsync("a.qoa", loaded -> Everything.result = loaded);
			LoadWaveFromMemoryAsync(".wav", Everything.value, 0, loaded -> Everything.result = loaded);
			LoadWaveFromMemoryAsync(".ogg", Everything.value, 0, loaded -> Everything.result = loaded);
			LoadWaveFromMemoryAsync(".mp3", Everything.value, 0, loaded -> Everything.result = loaded);
			LoadWaveFromMemoryAsync(".qoa", Everything.value, 0, loaded -> Everything.result = loaded);
			// An automation event list made in memory, as raylib's LoadAutomationEventList(NULL).
			Everything.result = LoadAutomationEventList(null);
			EndDrawing();
		}
		CloseWindow();
	}
}
