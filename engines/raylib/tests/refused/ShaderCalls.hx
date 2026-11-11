import helix.raylib.Raylib.*;

/** A program loading shaders as raylib does in C, which doesn't build on any target: `helix.py test` builds it for JS and natively and
	checks that `LoadShader` and `LoadShaderFromMemory` are refused naming `CompileShaderFile`'s parameters, and that its result can't be
	passed on, as it only writes the compiled shader's file. */
class ShaderCalls {
	static function main():Void {
		InitWindow(320, 200, "refused");
		var lit = LoadShader("lit.vs", "lit.fs");
		var glow = LoadShaderFromMemory("void main() {}", "void main() {}");
		var compiled = LoadCompiledShaderFromData(CompileShaderFile(null, null, "build/tests/ShaderCalls.shader"));
		CloseWindow();
	}
}
