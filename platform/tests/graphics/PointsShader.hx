import haxe.macro.Context;
import haxe.macro.Expr;

/** Provides the points cases' program: two stages compiled as `ShaderCompiler.compile` compiles them, with the point size written
	(`ShaderCompileOptions.points`), which that macro doesn't ask for. */
class PointsShader {
	/** Compiles two stages with the point size written, and returns the `ShaderSource` as a value in the program.

		@param vertex  The vertex stage's file, relative to this one.
		@param fragment  The fragment stage's file, relative to this one.
		@return  The program, as `IGraphics.createShader` takes it. */
	public static macro function compile(vertex:String, fragment:String):ExprOf<helix.platform.ShaderSource> {
		var pos = Context.currentPos();
		var here = haxe.io.Path.directory(Context.getPosInfos(pos).file);
		var js = Context.defined("js");
		var stages = [
			for (name in [vertex, fragment]) {
				var path = haxe.io.Path.join([here, name]);
				Context.registerModuleDependency(Context.getLocalModule(), path);
				{name: path, text: sys.io.File.getContent(path)};
			}
		];
		var source = helix.platform.tools.ShaderCompiler.compileText(stages[0], stages[1], {glsl410: !js, sdlGpu: !js, points: true});
		return macro(${Context.makeExpr(source, pos)} : helix.platform.ShaderSource);
	}
}
