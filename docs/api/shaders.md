# helix.shaders

[Back to the index](README.md)

## ShaderLibrary

*class* in `src/helix/shaders/ShaderLibrary.hx`

The shader library's programs on each GPU. A library shader's source (src/helix/shaders/*.glsl) is packed at build time into generated Haxe holding its .hxshader (tools/pack_shader.py: <Name>Packed.text()), so a class in helix.shaders gets its shader at once, with no load and no asset, and a shader nothing uses is left out of the build. Each is built the first time it's asked for on a GPU and kept, shared by everything drawing with it, until the runner releases the GPU's. In development a hot reload brings the shaders packed again from changed sources, and each built is built again in place, as Shaders does an app's.

```haxe
static function get(gpu:IGraphics, name:String, text:String):Shader
static function release(gpu:IGraphics):Void
```

- `get`: The library shader name (its source's file stem: "unlit") on gpu, built from text (its packed .hxshader, <Name>Packed.text()) the first time it's asked for there. Throws, saying why, for a program that doesn't build.
- `release`: Frees gpu's library shaders and the pipelines made over them, before the adapter shuts down.

## Tonemap

*class* in `src/helix/shaders/Tonemap.hx`

An HDR chain's tone mapping, a screen effect of the library: the frame's light (a stage's after its exposure, drawn into a half-float scene as sRGB values running past 1) brought into the screen's 0..1 by mode, as Stage3D does drawing straight to the screen, and written as the screen's sRGB. It wants HDR itself (ScreenEffect.hdr). PostProcess adds one after the last effect wanting HDR, with its stage's mode, to a chain that has none; one added by hand runs where it's added, with its own mode, and only in an HDR chain. Built on the program's GPU (Graphics) the first time one is made.

```haxe
function new()
var mode(default, set):Tonemap
```

- `new`: A tone mapping by Khronos PBR Neutral.
- `mode`: How the light comes into 0..1 (helix.render3d.Tonemap's modes, as Stage3D.tonemap): Khronos PBR Neutral to start.

## Unlit

*class* in `src/helix/shaders/Unlit.hx`

A library surface shader: a material drawn without light, its base color and texture times color, and its emission, under the stage's exposure and tone mapping as a material that isn't lit is. Made on a material, it is that material's surface shader from then on (Material.setShader), built on the program's GPU (Graphics) the first time a material asks for it.

```haxe
function new(material:Material)
var material(default, null):Material
var color(default, set):Int
```

- `new`: Makes Unlit material's surface shader, color white.
- `material`: The material it draws.
- `color`: What the material's base color and texture are multiplied by, 0xRRGGBBAA, its color sRGB as the material's are: white (the material as it is) by default. Written into the shader's parameters (Material.shaderParameters); with another shader on the material since, it changes nothing there.
