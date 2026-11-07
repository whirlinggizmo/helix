# helix.render.effects

[Back to the library](README.md)

## BloomEffect

*class* in [`libs/render/src/helix/render/effects/BloomEffect.hx`](../src/helix/render/effects/BloomEffect.hx), `import helix.render.effects.BloomEffect;`, extends `ScreenEffect`

Represents bloom: light past a threshold spread around it, as a bright light glows in a lens or an eye. It works on linear light.

The light past `threshold`, eased in over a soft knee, is drawn into half the frame's size and down a chain of halving targets through a 13-tap filter, each level then added to the one above through a 3 x 3 tent filter, and the result added to the frame times `intensity`. In an RGBA8 frame it blooms what the tone mapping left, past the threshold of display colors.

```haxe
function new()
var threshold(default, set):Float
var intensity(default, set):Float
var radius(default, set):Float
```

- `new`: Creates bloom at a threshold of 1, an intensity of 0.5 and a radius of 0.5.
- `threshold`: Gets or sets the brightness past which light blooms, in linear light: 1 until set. Below 0 is clamped to 0.
- `intensity`: Gets or sets how much of the bloom is added: 0.5 until set. Below 0 is clamped to 0.
- `radius`: Gets or sets how far it spreads, 0 to 1, the levels' blend: 0.5 until set. Clamped to 0 to 1.

## ColorGradeEffect

*class* in [`libs/render/src/helix/render/effects/ColorGradeEffect.hx`](../src/helix/render/effects/ColorGradeEffect.hx), `import helix.render.effects.ColorGradeEffect;`, extends `ScreenEffect`

Represents color grading on encoded colors, after the resolve: brightness, contrast and saturation, then a look-up table.

The table is a strip of square slices, its height the size of each (16 or 32 a side as editors export them): red across a slice, green down it, blue from slice to slice, each texel the color its place maps to.

```haxe
function new()
var brightness(default, set):Float
var contrast(default, set):Float
var saturation(default, set):Float
var lut:Null<Texture2D>
var lutIntensity(default, set):Float
```

- `new`: Creates grading that changes nothing until set.
- `brightness`: Gets or sets the brightness added: 0 until set, -1 to 1. Clamped to -1 to 1.
- `contrast`: Gets or sets the contrast, a multiplier about mid grey: 1 until set. Below 0 is clamped to 0.
- `saturation`: Gets or sets the saturation, a multiplier: 1 until set, 0 grey. Below 0 is clamped to 0.
- `lut`: Gets or sets the look-up table, or null for none.
- `lutIntensity`: Gets or sets how much of the table's color replaces the color: 1 until set. Clamped to 0 to 1.

## FxaaEffect

*class* in [`libs/render/src/helix/render/effects/FxaaEffect.hx`](../src/helix/render/effects/FxaaEffect.hx), `import helix.render.effects.FxaaEffect;`, extends `ScreenEffect`

Represents FXAA: edges smoothed by their contrast in the encoded frame, an antialiasing for a frame drawn without multisampling.

A render target is multisampled as the screen is unless made with another count (`RenderTarget2D.msaaSampleCount`), so a frame drawn into one needs FXAA only where its count is 1: a phone, a program asking for no multisampling, a target made with 1. It works after the resolve, best last.

```haxe
function new()
```

- `new`: Creates the effect.

## PostProcess

*class* in [`libs/render/src/helix/render/effects/PostProcess.hx`](../src/helix/render/effects/PostProcess.hx), `import helix.render.effects.PostProcess;`

Provides post-processing: a frame drawn into a texture, carried through a chain of screen effects and resolved into the current pass.

A program draws its scene into a render target, an RGBA16F one for HDR (`Renderer.createRenderTarget(width, height, Rgba16f)`), whose 3D is then linear light neither exposed nor tone mapped (`Batch3D`), and calls `draw` with it where the result belongs: the screen's pass, usually, before the HUD. The chain runs in three steps:

1. its **linear** effects (`ScreenEffect.linear`: `BloomEffect`, a linear `ShaderEffect`), in their order in `effects`, on linear light; 2. the **resolve**: the renderer's `exposure`, then its `toneMapping`, then the sRGB encode, every chain's, so a chain with no effects is the resolve alone; the same pair `Batch3D` applies drawing straight into an sRGB target, read at each `draw`; 3. its **display** effects (`ColorGradeEffect`, `FxaaEffect`, a `ShaderEffect`), in their order, on encoded colors, the last drawn into the current pass.

An RGBA8 source is display colors already: it is decoded for the linear effects and not tone mapped. Each step but the last draws into an intermediate target the chain keeps, sized to the source, as a target pass recorded before the current one, so `draw` may be called in the middle of the screen's pass. It runs no loop and reads no clock: the time it is given is what effects animate by.

```haxe
var scene = renderer.createRenderTarget(width, height, Rgba16f);
var post = new PostProcess(renderer);
post.effects.push(new BloomEffect());
renderer.toneMapping = AgX;
// each frame:
renderer.beginFrame(width, height, 0xff000000);
renderer.beginTarget(scene, 0xff000000);
batch3D.begin(camera);
drawWorld();
batch3D.end();
renderer.endTarget();
post.draw(scene, time.elapsed);
batch2D.begin(); // the HUD, after the resolve, untouched by it
drawHud();
batch2D.end();
renderer.endFrame();
```

```haxe
function new(renderer:Renderer)
final effects:Array<ScreenEffect>
function draw(source:Texture2D, ?time:Float = 0.):Void
function dispose():Void
```

- `new`: Creates a chain of no effects over a renderer: the resolve alone.
  - `renderer`: The renderer it records into.
- `effects`: Gets the effects, in order; the program adds, removes and reorders them. Each is drawn while its `enabled` is set.
- `draw`: Carries a frame through the chain and draws the result over the current pass's viewport.
  - `source`: The frame: a render target drawn this frame, or any texture.
  - `time`: Optional. Seconds the effects animate by; defaults to 0.
  - throws `String`: No frame being recorded, a batch open, or the source being the current pass's target.
- `dispose`: Frees its intermediate targets; the effects stay their owner's.

## ScreenEffect

*class* in [`libs/render/src/helix/render/effects/ScreenEffect.hx`](../src/helix/render/effects/ScreenEffect.hx), `import helix.render.effects.ScreenEffect;`

Represents an effect over a whole frame in a `PostProcess` chain: `BloomEffect`, `ColorGradeEffect`, `FxaaEffect`, a `ShaderEffect`, or a program's own.

An effect of its own extends this, says whether it works on linear light (`linear`) and what intermediate targets it needs (`intermediates`), draws into them in `drawIntermediates`, and draws its result in `draw`, both through its `ScreenFrame`.

**A screen shader** (`ShaderEffect`, `ScreenFrame.drawPass`) is compiled by `compileShader` (a fragment stage over the screen triangle) or `compileShaderStages`. The chain fills, by name, what it declares: `sourceTexture` (sampler2D, the frame it reads), `sourceSize` (vec2, its size in texels) and `time` (float, `PostProcess.draw`'s seconds); the view's `linearTarget` (`View3D`) when it includes `<helix/render/shaders/view.glsl>`.

```haxe
static macro function compileShader(fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
static macro function compileShaderStages(vertex:String, fragment:String, ?options:haxe.macro.Expr.ExprOf<ShaderOptions>):haxe.macro.Expr.ExprOf<Shader>
var enabled:Bool
final linear:Bool
final intermediates:Array<Float>
function drawIntermediates(frame:ScreenFrame):Void
function draw(frame:ScreenFrame):Void
```

- `compileShader`: Compiles a fragment stage over the screen triangle, for a pass over a whole frame (`ShaderEffect`, `ScreenFrame.drawPass`).
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch, as `Shader.compile` takes them.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. The fragment stage is GLSL as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440 (GL's form), or `#version 450` (Vulkan's), the screen triangle's vertex stage given in the same form; GLSL ES 100 is not taken. The vertex stage passes `texCoord` (vec2), 0 to 1 across the frame, v down, read by name.
- `compileShaderStages`: Compiles a vertex and a fragment stage, both the program's, for a pass over a whole frame (`ShaderEffect`, `ScreenFrame.drawPass`).
  - `vertex`: The vertex stage's file, relative to the file holding the call.
  - `fragment`: The fragment stage's file, relative to the file holding the call.
  - `options`: Optional. Defines, includes and a file to watch.
  - returns: The shader, for a `ShaderValues` over it.

  It compiles while the program builds, as helix-services' `Shader.compile` compiles one, and returns it as a value in the program: its vertex stage drawn the right way up into a render target whatever it writes (`ShaderOptions.clipScale`) and able to draw one-pixel points (`ShaderOptions.points`), helix-render's includes found (`#include <helix/render/shaders/color.glsl>`). A name the class lists declared with another type stops the build at the call. Both stages are GLSL in one form, as helix-services' `Shader.compile` takes it: `#version 300 es` or 330 to 440, or `#version 450`. The vertex stage is drawn for the three corners of one triangle covering the frame.
- `enabled`: Gets or sets a value indicating whether the chain draws it: true until set.
- `linear`: Gets a value indicating whether it works on linear light, before the chain's resolve, rather than on encoded colors after it.
- `intermediates`: Gets the intermediate targets it draws through before its result, each its size as a fraction of the frame's each way (0.5 half, at least a pixel): empty for an effect of one pass. The chain makes them RGBA16F for a linear effect, RGBA8 otherwise.
- `drawIntermediates`: Draws its passes before its result into the frame's intermediates; nothing for an effect of one pass.
  - `frame`: What it draws from and into.
- `draw`: Draws its result over the target the chain gives it, reading the frame's source and its intermediates.
  - `frame`: What it draws from.

## ScreenFrame

*class* in [`libs/render/src/helix/render/effects/ScreenFrame.hx`](../src/helix/render/effects/ScreenFrame.hx), `import helix.render.effects.ScreenFrame;`

Represents what a screen effect draws from in a `PostProcess` chain, this frame: the frame it changes, its size, the time, and the intermediate targets it asked for.

```haxe
final source:Texture2D
final width:Int
final height:Int
final time:Float
final intermediates:Array<RenderTarget2D>
function drawPass(values:ShaderValues, source:Texture2D, ?target:RenderTarget2D):Void
```

- `source`: Gets the frame the effect changes: the source, or the step before's result.
- `width`: Gets the frame's width, in pixels.
- `height`: Gets the frame's height, in pixels.
- `time`: Gets the seconds `PostProcess.draw` was given.
- `intermediates`: Gets the effect's intermediate targets, in the order of its `ScreenEffect.intermediates`.
- `drawPass`: Draws a screen shader once over a whole target, reading a texture as `sourceTexture` (its size, in texels, as `sourceSize`) and `time`, filled by name over the values given.
  - `values`: The values over the shader: a shader from `ScreenEffect.compileShader`, and its own uniforms.
  - `source`: The texture it reads.
  - `target`: Optional. The intermediate to draw into; the effect's result when omitted.

  Into an intermediate it is a target pass of its own, cleared to transparent black; omitted, it draws the effect's result where the chain draws it (only in `ScreenEffect.draw`).

## ShaderEffect

*class* in [`libs/render/src/helix/render/effects/ShaderEffect.hx`](../src/helix/render/effects/ShaderEffect.hx), `import helix.render.effects.ShaderEffect;`, extends `ScreenEffect`

Represents a screen effect of one pass through a program's own shader, drawn over the whole frame: a fragment stage reading `sourceTexture`, `sourceSize` and `time` (filled by the chain), and its own values.

```haxe
var vignetteShader = ScreenEffect.compileShader("vignette.frag");
var vignette = new ShaderEffect(new ShaderValues(vignetteShader));
vignette.values.writeFloat(vignetteShader.getUniform("strength"), .4);
post.effects.push(vignette);
```

```haxe
function new(values:ShaderValues, ?linear:Bool = false)
final values:ShaderValues
```

- `new`: Creates an effect drawing through a shader.
  - `values`: The values over the shader.
  - `linear`: Optional. Whether it works on linear light, before the resolve; defaults to false.
- `values`: Gets the values it draws with: its shader, from `ScreenEffect.compileShader` or `compileShaderStages`, and the shader's own uniforms and textures, read at each `PostProcess.draw`.
