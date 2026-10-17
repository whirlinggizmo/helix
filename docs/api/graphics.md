# helix.graphics

[Back to the index](README.md)

## BlendMode

*abstract* in `src/helix/graphics/BlendMode.hx`

How a pipeline's colors meet what the framebuffer has: replacing it, blended over it by their alpha (straight alpha), or added to it (times their alpha: light, fire, glows).

## ClipFlip

*abstract* in `src/helix/graphics/PipelineDesc.hx`

What uniform block 0 holds, so an adapter whose render targets are stored upside down (GL's bottom-left origin) can draw a target the right way up: nothing it touches, a clip scale it writes (x 1, y -1 in such a pass, else 1), or a view-projection matrix (column-major, its first 64 bytes) whose y row it negates in such a pass.

## Graphics

*class* in `src/helix/graphics/Graphics.hx`

The GPU: textures, buffers, shaders, pipelines, passes and draws. Shutting it down is the runner's. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from IGraphics's public members with their doc comments.

```haxe
static var instance(default, null):IGraphics
static function createTexture(width:Int, height:Int, levels:Array<haxe.io.Bytes>, ?format:TextureFormat = helix.graphics.TextureFormat.Rgba8):Int
static function createCubeTexture(size:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat):Int
static function createDataTexture(width:Int, height:Int):Int
static function updateDataTexture(handle:Int, data:haxe.io.Bytes):Void
static function canSample(format:TextureFormat):Bool
static var msaaSamples(get, never):Int
static var maxMsaaSamples(get, never):Int
static function createRenderTarget(width:Int, height:Int):Int
static function createShadowMap(size:Int, layers:Int):Int
static function destroyTexture(handle:Int):Void
static function createBuffer(capacityBytes:Int):Int
static function createStaticBuffer(data:haxe.io.Bytes, bytes:Int, index:Bool):Int
static function updateBuffer(handle:Int, data:haxe.io.Bytes, usedBytes:Int):Void
static function destroyBuffer(handle:Int):Void
static function createShader(source:ShaderSource):Int
static function destroyShader(handle:Int):Void
static function createPipeline(desc:PipelineDesc):Int
static function destroyPipeline(handle:Int):Void
static function beginShadowPass(map:Int, layer:Int):Void
static function beginTargetPass(target:Int, clearColor:Int):Void
static function endTargetPass():Void
static function beginFrame(width:Int, height:Int, clearColor:Int):Void
static function applyViewport(x:Int, y:Int, w:Int, h:Int):Void
static function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
static function resetScissor():Void
static function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<haxe.io.Bytes>>):Void
static function endFrame():Void
static function readPixels(target:Int, done:ReadPixelsResult -> Void):Void
```

- `instance`: The GPU forwarded to: the profile's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `createTexture`: Uploads an image, rows top first, and returns its handle. levels is the image then, optionally, its mipmaps, each half the size of the last (at least 1; Mipmaps.build makes them for RGBA8), each format.levelBytes of its size. How it is sampled is each draw's (Sampling). Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample.
- `createCubeTexture`: Uploads a cubemap, each face size x size, and returns its handle, sampled at a texture slot like any texture (the samplings' filter applies, their wrap doesn't: a cube's faces meet). levels is mip 0 then, optionally, its mips, each half the size of the last (at least 1), each its six faces one after another (+X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation: a face's first row is its t = 0), each face format.levelBytes of its size. Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample.
- `createDataTexture`: Makes a data texture width x height of RGBA 32-bit floats (16 bytes a texel), read texel by texel (texelFetch: never filtered, its samplings ignored), and returns its handle. Its contents are updateDataTexture's. Throws for a size of 0 or less or past this GPU's.
- `updateDataTexture`: Replaces a data texture's whole contents with data's first width * height * 16 bytes (rows top first, little-endian floats), for the draws after it; any number of times a frame. Throws for a handle that isn't a data texture or data too short.
- `canSample`: Whether this GPU samples textures of format: RGBA8 always; the compressed ones on GPUs that have them; half floats where it filters them.
- `msaaSamples`: Multisampling samples a pixel the screen is drawn with (WindowOptions.requestMsaaSamples): 1 for none, else what the platform gave, which may be fewer than asked. Render targets are drawn with the same, resolved into the texture sampled.
- `maxMsaaSamples`: The most multisampling samples a pixel a window could ask for here, at most 8 (what requestMsaaSamples takes): for a settings menu to offer, applied at the next start. Natively the GPU's most; a browser only switches antialiasing on or off, choosing its own count, so there it's the count the canvas has when on (4 where the GPU has 4, else 1).
- `createRenderTarget`: Makes a render target width x height and returns its handle: a texture (8 bits a channel), sampled like any other and stored top row first like any other, that a target pass draws into, with a depth buffer of its own. Throws for a size of 0 or less.
- `createShadowMap`: Makes a shadow map: a depth texture of layers layers, each size x size, that shadow passes draw into (beginShadowPass), sampled through a comparison sampler (linear, less or equal, clamped to its edge; the slot's sampling is ignored) where a program declares a shadow texture. Its rows run bottom first, as GL's: clip space's -1..1 is its 0..1. Throws for a size or layer count of 0 or less, or past this GPU's.
- `destroyTexture`: Frees a texture of any kind. Whoever created a handle destroys it, once. Throws for an unknown handle.
- `createBuffer`: Allocates a stream vertex buffer of capacityBytes, a positive multiple of 4, filled each frame by updateBuffer, and returns its handle. Throws for another size.
- `createStaticBuffer`: Makes an immutable buffer of the first bytes of data (a positive multiple of 4) and returns its handle: vertices, or with index true uint32 indices (little-endian). Throws for a bad size.
- `updateBuffer`: Replaces a stream buffer's contents with the first usedBytes of data, for the draws after it; inside a pass, any number of times a frame (a buffer drawn into a target and then the screen is uploaded twice). Throws outside a pass, for an unknown handle or a size out of range.
- `destroyBuffer`: Frees a buffer. Whoever created a handle destroys it, once. Throws for an unknown handle.
- `createShader`: Builds a program from source (the dialect this adapter compiles, its attributes by slot, its uniform blocks and its textures, each declared as a plain, cube, shadow or data texture) and returns its handle, for pipelines. Throws, with the compiler's log, for one that doesn't build.
- `destroyShader`: Frees a program; the pipelines made with it are destroyed first. Throws for an unknown handle.
- `createPipeline`: Makes a pipeline as desc says (PipelineDesc) and returns its handle. Throws for an unknown shader or a description it can't make.
- `destroyPipeline`: Frees a pipeline. Whoever created a handle destroys it, once. Throws for an unknown handle.
- `beginShadowPass`: Starts a depth-only pass drawing into layer layer of map (a createShadowMap handle), for depth-only pipelines: clears it to the farthest and sets the viewport to all of it. Before the screen's pass, outside any other; endTargetPass ends it. Throws inside a pass, for a handle that isn't a shadow map or a layer it hasn't.
- `beginTargetPass`: Starts a pass drawing into target (a createRenderTarget handle): clears it to clearColor (0xRRGGBBAA) and its depth to the farthest, and sets the viewport to all of it. Before the screen's pass, outside any other. Throws inside a pass or for a handle that isn't a render target.
- `endTargetPass`: Ends the pass beginTargetPass or beginShadowPass started; its target can be sampled from then on. Throws when no such pass is open.
- `beginFrame`: Starts the frame's screen pass on a width x height framebuffer, after its target passes: clears it to clearColor (0xRRGGBBAA) and the depth to the farthest, and sets the viewport to all of it. Throws inside a pass or for a size of 0 or less.
- `applyViewport`: Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less.
- `applyScissor`: Draws from now on only inside x, y, w, h in framebuffer pixels from the bottom-left (as applyViewport), until resetScissor or the pass ends; a pass begins unclipped. Throws outside a pass or for a size below 0.
- `resetScissor`: Draws everywhere in the pass again. Throws outside a pass.
- `draw`: Draws through pipeline: count vertices from first of its buffers (or, for an indexed pipeline, count indices from first of indices, a static index buffer), whole primitives, as instanceCount instances whose records start at record firstInstance of its instanced buffers. buffers[i] is the buffer (createBuffer's, as this frame's upload left it, or createStaticBuffer's) for the pipeline's buffer i (0 for a gap); textures[i] is bound at the program's texture slot i (0 for a slot it doesn't sample), sampled as samplings[i] says (a shadow map or data texture as its kind is); uniforms[i] is the bytes of its uniform block at slot i (its declared size; null for a slot it lacks), block 0 flipped as the pipeline's clip flip says. A pipeline without buffers draws count vertices from nothing (one triangle over the viewport: three). Throws for anything invalid, before drawing.
- `endFrame`: Ends the screen's pass and with it the frame, presenting it. Throws when no screen pass is open.
- `readPixels`: Reads target back (a createRenderTarget handle; 0 for the frame endFrame just ended, read before the host's frame returns, as a browser presents it then and a GPU may swap it away); done runs once on the host thread, during this call or, on a GPU that reads back asynchronously, later: Read, or Failed when no frame has ended since the last beginFrame. Slow (it waits for the GPU): for screenshots and checks, not every frame. Throws inside a pass or for a handle that isn't a render target.

## GraphicsUnavailable

*class* in `src/helix/graphics/GraphicsUnavailable.hx`

Thrown by a graphics adapter that can't get the GPU API it draws through (no WebGL2 in this browser, say), whichever API that is, so a host can tell the program's code failing from the platform lacking what it needs.

```haxe
function new(message:String, ?previous:haxe.Exception, ?native:Any)
```


## IGraphics

*class* in `src/helix/graphics/IGraphics.hx`

The GPU, as thin as HeliX can make it: a platform's graphics adapter implements it and nothing else. Resources (textures of a few kinds, buffers, programs built from a ShaderSource, pipelines made from a PipelineDesc), passes (the frame's screen pass after any passes into render targets and shadow maps) and one draw. An adapter knows no program, layout or pipeline of HeliX's own: shared code describes those (Pipelines, the generated layouts) and hands them over as data, so another adapter (another GPU API, another platform) implements this alone. A call that can't be done throws, before doing anything.

```haxe
function createTexture(width:Int, height:Int, levels:Array<haxe.io.Bytes>, ?format:TextureFormat = Rgba8):Int
function createCubeTexture(size:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat):Int
function createDataTexture(width:Int, height:Int):Int
function updateDataTexture(handle:Int, data:haxe.io.Bytes):Void
function canSample(format:TextureFormat):Bool
var msaaSamples(get, never):Int
var maxMsaaSamples(get, never):Int
function createRenderTarget(width:Int, height:Int):Int
function createShadowMap(size:Int, layers:Int):Int
function destroyTexture(handle:Int):Void
function createBuffer(capacityBytes:Int):Int
function createStaticBuffer(data:haxe.io.Bytes, bytes:Int, index:Bool):Int
function updateBuffer(handle:Int, data:haxe.io.Bytes, usedBytes:Int):Void
function destroyBuffer(handle:Int):Void
function createShader(source:ShaderSource):Int
function destroyShader(handle:Int):Void
function createPipeline(desc:PipelineDesc):Int
function destroyPipeline(handle:Int):Void
function beginShadowPass(map:Int, layer:Int):Void
function beginTargetPass(target:Int, clearColor:Int):Void
function endTargetPass():Void
function beginFrame(width:Int, height:Int, clearColor:Int):Void
function applyViewport(x:Int, y:Int, w:Int, h:Int):Void
function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
function resetScissor():Void
function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<haxe.io.Bytes>>):Void
function endFrame():Void
function readPixels(target:Int, done:ReadPixelsResult -> Void):Void
function shutdown():Void
```

- `createTexture`: Uploads an image, rows top first, and returns its handle. levels is the image then, optionally, its mipmaps, each half the size of the last (at least 1; Mipmaps.build makes them for RGBA8), each format.levelBytes of its size. How it is sampled is each draw's (Sampling). Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample.
- `createCubeTexture`: Uploads a cubemap, each face size x size, and returns its handle, sampled at a texture slot like any texture (the samplings' filter applies, their wrap doesn't: a cube's faces meet). levels is mip 0 then, optionally, its mips, each half the size of the last (at least 1), each its six faces one after another (+X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation: a face's first row is its t = 0), each face format.levelBytes of its size. Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample.
- `createDataTexture`: Makes a data texture width x height of RGBA 32-bit floats (16 bytes a texel), read texel by texel (texelFetch: never filtered, its samplings ignored), and returns its handle. Its contents are updateDataTexture's. Throws for a size of 0 or less or past this GPU's.
- `updateDataTexture`: Replaces a data texture's whole contents with data's first width * height * 16 bytes (rows top first, little-endian floats), for the draws after it; any number of times a frame. Throws for a handle that isn't a data texture or data too short.
- `canSample`: Whether this GPU samples textures of format: RGBA8 always; the compressed ones on GPUs that have them; half floats where it filters them.
- `msaaSamples`: Multisampling samples a pixel the screen is drawn with (WindowOptions.requestMsaaSamples): 1 for none, else what the platform gave, which may be fewer than asked. Render targets are drawn with the same, resolved into the texture sampled.
- `maxMsaaSamples`: The most multisampling samples a pixel a window could ask for here, at most 8 (what requestMsaaSamples takes): for a settings menu to offer, applied at the next start. Natively the GPU's most; a browser only switches antialiasing on or off, choosing its own count, so there it's the count the canvas has when on (4 where the GPU has 4, else 1).
- `createRenderTarget`: Makes a render target width x height and returns its handle: a texture (8 bits a channel), sampled like any other and stored top row first like any other, that a target pass draws into, with a depth buffer of its own. Throws for a size of 0 or less.
- `createShadowMap`: Makes a shadow map: a depth texture of layers layers, each size x size, that shadow passes draw into (beginShadowPass), sampled through a comparison sampler (linear, less or equal, clamped to its edge; the slot's sampling is ignored) where a program declares a shadow texture. Its rows run bottom first, as GL's: clip space's -1..1 is its 0..1. Throws for a size or layer count of 0 or less, or past this GPU's.
- `destroyTexture`: Frees a texture of any kind. Whoever created a handle destroys it, once. Throws for an unknown handle.
- `createBuffer`: Allocates a stream vertex buffer of capacityBytes, a positive multiple of 4, filled each frame by updateBuffer, and returns its handle. Throws for another size.
- `createStaticBuffer`: Makes an immutable buffer of the first bytes of data (a positive multiple of 4) and returns its handle: vertices, or with index true uint32 indices (little-endian). Throws for a bad size.
- `updateBuffer`: Replaces a stream buffer's contents with the first usedBytes of data, for the draws after it; inside a pass, any number of times a frame (a buffer drawn into a target and then the screen is uploaded twice). Throws outside a pass, for an unknown handle or a size out of range.
- `destroyBuffer`: Frees a buffer. Whoever created a handle destroys it, once. Throws for an unknown handle.
- `createShader`: Builds a program from source (the dialect this adapter compiles, its attributes by slot, its uniform blocks and its textures, each declared as a plain, cube, shadow or data texture) and returns its handle, for pipelines. Throws, with the compiler's log, for one that doesn't build.
- `destroyShader`: Frees a program; the pipelines made with it are destroyed first. Throws for an unknown handle.
- `createPipeline`: Makes a pipeline as desc says (PipelineDesc) and returns its handle. Throws for an unknown shader or a description it can't make.
- `destroyPipeline`: Frees a pipeline. Whoever created a handle destroys it, once. Throws for an unknown handle.
- `beginShadowPass`: Starts a depth-only pass drawing into layer layer of map (a createShadowMap handle), for depth-only pipelines: clears it to the farthest and sets the viewport to all of it. Before the screen's pass, outside any other; endTargetPass ends it. Throws inside a pass, for a handle that isn't a shadow map or a layer it hasn't.
- `beginTargetPass`: Starts a pass drawing into target (a createRenderTarget handle): clears it to clearColor (0xRRGGBBAA) and its depth to the farthest, and sets the viewport to all of it. Before the screen's pass, outside any other. Throws inside a pass or for a handle that isn't a render target.
- `endTargetPass`: Ends the pass beginTargetPass or beginShadowPass started; its target can be sampled from then on. Throws when no such pass is open.
- `beginFrame`: Starts the frame's screen pass on a width x height framebuffer, after its target passes: clears it to clearColor (0xRRGGBBAA) and the depth to the farthest, and sets the viewport to all of it. Throws inside a pass or for a size of 0 or less.
- `applyViewport`: Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less.
- `applyScissor`: Draws from now on only inside x, y, w, h in framebuffer pixels from the bottom-left (as applyViewport), until resetScissor or the pass ends; a pass begins unclipped. Throws outside a pass or for a size below 0.
- `resetScissor`: Draws everywhere in the pass again. Throws outside a pass.
- `draw`: Draws through pipeline: count vertices from first of its buffers (or, for an indexed pipeline, count indices from first of indices, a static index buffer), whole primitives, as instanceCount instances whose records start at record firstInstance of its instanced buffers. buffers[i] is the buffer (createBuffer's, as this frame's upload left it, or createStaticBuffer's) for the pipeline's buffer i (0 for a gap); textures[i] is bound at the program's texture slot i (0 for a slot it doesn't sample), sampled as samplings[i] says (a shadow map or data texture as its kind is); uniforms[i] is the bytes of its uniform block at slot i (its declared size; null for a slot it lacks), block 0 flipped as the pipeline's clip flip says. A pipeline without buffers draws count vertices from nothing (one triangle over the viewport: three). Throws for anything invalid, before drawing.
- `endFrame`: Ends the screen's pass and with it the frame, presenting it. Throws when no screen pass is open.
- `readPixels`: Reads target back (a createRenderTarget handle; 0 for the frame endFrame just ended, read before the host's frame returns, as a browser presents it then and a GPU may swap it away); done runs once on the host thread, during this call or, on a GPU that reads back asynchronously, later: Read, or Failed when no frame has ended since the last beginFrame. Slow (it waits for the GPU): for screenshots and checks, not every frame. Throws inside a pass or for a handle that isn't a render target.
- `shutdown`: Releases the adapter itself, after its handles are destroyed.

## IImageDecoder

*class* in `src/helix/graphics/IImageDecoder.hx`

Image decoding on a platform: PNG, JPEG, BMP, TGA and GIF (its first frame) to 8-bit RGBA, rows top to bottom, not premultiplied. Queuing, cancellation and shutdown are the shared ImageDecoding's.

```haxe
function decode(encoded:haxe.io.Bytes, done:ImageDecodeResult -> Void):Void
function poll():Void
```

- `decode`: Decodes encoded off the frame where the platform can; done runs once on the host thread, never during this call: Decoded or Failed.
- `poll`: Delivers what finished on the platform's threads since the last poll; the shared ImageDecoding calls it once a frame.

## ImageDecodeResult

*enum* in `src/helix/graphics/ImageDecoding.hx`

How a decode ended: the image as 8-bit RGBA, rows top to bottom, not premultiplied; or why not; or cancellation.

- `Decoded(width:Int, height:Int, rgba:haxe.io.Bytes)`
- `Failed(message:String)`
- `Cancelled`

## ImageDecoding

*class* in `src/helix/graphics/ImageDecoding.hx`

Image decoding over a platform's IImageDecoder, the same on every platform: at most two at once, each completing exactly once on the host thread, cancelled ones and those still queued at shutdown completing Cancelled. A browser decodes with the page's own decoder (through a canvas, which stores pixels premultiplied, so a partly transparent pixel may come back a level or two from the file's exact value), native with stb_image, exactly. Textures and environments decode through it.

```haxe
function new(decoder:IImageDecoder)
function decode(encoded:haxe.io.Bytes, complete:ImageDecodeResult -> Void):IRequest
var busy(get, never):Bool
function poll():Void
function shutdown():Void
```

- `new`: Decodes with decoder.
- `decode`: Decodes encoded; complete runs exactly once on the host thread at a later poll. Failed for no bytes, a closed service, or bytes the decoder can't read.
- `busy`: Whether a decode is queued, under way, or its completion not yet run.
- `poll`: Delivers finished decodes, starts queued ones and runs completions. Call once per frame.
- `shutdown`: Cancels every pending decode (each completes Cancelled) and refuses later ones.

## Mipmaps

*class* in `src/helix/graphics/Mipmaps.hx`

Mipmap chains for IGraphics.createTexture, built the same on every target so their images match.

```haxe
static function build(width:Int, height:Int, rgba:haxe.io.Bytes):Array<haxe.io.Bytes>
```

- `build`: rgba (width x height RGBA8) and each level below it, half the size of the last (at least 1), down to 1x1: each texel the rounded average of the 2x2 above it, an odd edge repeating its last row or column.

## PipelineDesc

*typedef* in `src/helix/graphics/PipelineDesc.hx`

A pipeline, everything a draw through it fixes: the program (an IGraphics.createShader handle), its vertex buffers' layout, what it draws, whether its draws are indexed (uint32 indices), how its colors meet the target's (blend), the depth test (less or equal) and write, back-face culling and which winding is the front, whether it writes depth alone (a shadow pass's), and its block 0's clip flip. Shared code describes the framework's pipelines (Pipelines); an adapter only makes what the description says.

- `shader:Int`
- `primitive:Primitive`
- `indexed:Bool`
- `flip:ClipFlip`
- `depthWrite:Bool`
- `depthTest:Bool`
- `depthOnly:Bool`
- `cullBack:Bool`
- `clockwise:Bool`
- `buffers:Array<VertexBuffer>`
- `blend:BlendMode`

## Pipelines

*class* in `src/helix/graphics/Pipelines.hx`

The framework's programs and pipelines on one GPU, shared by everything drawing on it: each framework program built once from its generated source (the layouts' source()), and each pipeline described here (its program, buffers' layout and state: PipelineDesc) and made the first time it's asked for, then kept. Drawing code asks for its pipeline at each draw and never keeps the handle, so a program built again (an app's shader reloaded, or in development a framework program whose source changed) has its pipelines made again behind it. This is the framework's knowledge of its pipelines; an adapter knows none of it.

```haxe
static function of(gpu:IGraphics):Pipelines
static function release(gpu:IGraphics):Void
function forgetShader(shader:Int):Void
function sprite2D(blend:BlendMode):Int
function color3D():Int
function lines3D():Int
function lit3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
function skinned3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
function surface(shader:Int, blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
function sprite3D(blend:BlendMode):Int
function particle3D(blend:BlendMode):Int
function depth3D():Int
function skinnedDepth3D():Int
function background3D():Int
function screen(shader:Int, blend:BlendMode):Int
```

- `of`: gpu's, made the first time it's asked for.
- `release`: Frees gpu's pipelines and framework programs, before the adapter shuts down.
- `forgetShader`: Destroys the pipelines made over shader (an app's, before it is destroyed or replaced); asked for again, they're made again.
- `sprite2D`: 2D sprites and shapes: Sprite2DLayout's vertices in clip space (its block the clip scale), no depth.
- `color3D`: Vertex-colored 3D triangles (Color3DLayout, the view-projection its block), depth tested and written.
- `lines3D`: Color3D's vertices as lines, two each.
- `lit3D`: Lit models (Lit3DLayout): blended or not, double sided or not, front faces clockwise (a mirrored placement's) or not.
- `skinned3D`: Skinned lit models (Skinned3DLayout: Lit3D's buffers and the skin), as lit3d's variants.
- `surface`: An app's surface shader (its handle) drawing lit models, as lit3d's variants.
- `sprite3D`: 3D sprites (Sprite3DLayout).
- `particle3D`: Particles (Particle3DLayout).
- `depth3D`: Shadow-map casters (Depth3DLayout): depth only, nothing culled (a one-sided floor still casts).
- `skinnedDepth3D`: Skinned shadow-map casters (Skinneddepth3DLayout).
- `background3D`: An environment behind a 3D scene (Background3DLayout): one triangle at the far plane, depth tested (less or equal) and not written.
- `screen`: An app's screen effect (its handle): one triangle over the viewport, no depth.

## Png

*class* in `src/helix/graphics/Png.hx`

PNG encoding in Haxe, the same bytes on every target: RGBA8 rows filtered as PNG suggests (the filter of the smallest sum, row by row), then deflated with LZ77 matching and the fixed Huffman codes. Smaller than stored data by about as much as a dynamic-code encoder for flat, synthetic images (a game's frame); larger for noisy ones.

```haxe
static function encode(width:Int, height:Int, rgba:haxe.io.Bytes):haxe.io.Bytes
```

- `encode`: The PNG file of a width x height RGBA8 image, rows top first (rgba holds at least width * height * 4 bytes). Throws for a size of 0 or less or rgba too short.

## PostProcess

*class* in `src/helix/graphics/PostProcess.hx`

Screen effects over a finished frame: the scene is drawn into a texture the screen's size (beginScene to endScene, a target pass), the enabled effects but the last draw in turn from one texture into another (target passes, still before the screen's), and present draws the last over the screen's pass, or the frame as it is when no effect is on. Its textures follow the screen's size. Effects run in the order given, so turning one off and on keeps its place.

```haxe
function new(gpu:IGraphics)
var sceneTexture(get, never):Null<Texture2D>
function beginScene(width:Int, height:Int, clearColor:Int):Void
function endScene(effects:Array<ScreenEffect>, time:Float):Void
function present():Void
function destroy():Void
```

- `new`: Effects drawn on gpu.
- `sceneTexture`: The texture the scene is drawn into (the last beginScene's), or null before one.
- `beginScene`: Starts the frame's scene: a target pass into a width x height texture (the screen's size), cleared to clearColor. Draw it as the screen; endScene ends it. Throws inside another pass.
- `endScene`: Ends the scene's pass and draws effects (each that is enabled, in order) but the last, each from the one before's result into a texture of its own, at time seconds; the last waits for present.
- `present`: Draws the processed frame over the open screen pass's viewport: the last effect over the others' result, or the frame as it is.
- `destroy`: Frees its textures and buffer; the effects stay their owner's.

## Primitive

*abstract* in `src/helix/graphics/PipelineDesc.hx`

What a pipeline's draws make: triangles, three vertices (or indices) each, or lines, two each.

## ReadPixelsResult

*enum* in `src/helix/graphics/IGraphics.hx`

Pixels read back from the GPU: width x height RGBA8, rows top first; or why they couldn't be.

- `Read(width:Int, height:Int, rgba:haxe.io.Bytes)`
- `Failed(message:String)`

## Sampling

*abstract* in `src/helix/graphics/Sampling.hx`

How a draw samples a texture: its filter (linear, smooth and through its mipmaps when it has them; or nearest, sharp, for pixel art) and how it wraps along u and v. A small value, passed with each texture a draw uses; adapters keep one sampler for each that is used.

## ScreenEffect

*class* in `src/helix/graphics/ScreenEffect.hx`

A screen effect: a Shader of kind screen drawn over a whole frame (one triangle over the viewport), with its own parameters and textures set by name (parameters), kept across the shader's reloads. PostProcess chains them; draw draws one into the open pass.

```haxe
function new(gpu:IGraphics, shader:Shader, ?alpha:Bool = false)
var shader(default, null):Shader
var parameters(default, null):ShaderParameters
var enabled:Bool
function draw(source:Texture2D, width:Int, height:Int, time:Float):Void
```

- `new`: An effect drawing with shader (kind screen) on gpu, blended over what's there when alpha, else replacing it. Throws for a shader of another kind.
- `shader`: Its shader.
- `parameters`: Its shader's own parameters and textures, set by name.
- `enabled`: Whether PostProcess draws it.
- `draw`: Draws the effect over the open pass's viewport, reading source (the frame it changes), width x height pixels, seconds since it began. A texture of its own that isn't set is drawn as source.

## ScreenshotResult

*enum* in `src/helix/graphics/ScreenshotService.hx`

How a screenshot ended: where it was saved and its PNG file, or why it wasn't.

- `Saved(where:String, png:haxe.io.Bytes)`
- `Failed(message:String)`

## ScreenshotService

*class* in `src/helix/graphics/ScreenshotService.hx`

Screenshots, the same on every platform: the next frame the app ends is read back (IGraphics.readPixels), encoded as PNG (Png) and handed to the user (IExport: a download in a browser, a file natively). The Runner calls frameEnded after each of the app's frames. Encoding runs on the host thread, so the frame it's taken in is slower. The runner's is what the Screenshots static forwards to.

```haxe
function new(graphics:IGraphics, export:IExport, prefix:String)
function take(?name:String, ?done:ScreenshotResult -> Void):Void
function frameEnded():Void
function shutdown():Void
```

- `new`: Reads frames from graphics and saves them through export, named prefix (the product's name, say) and the time.
- `take`: Takes a screenshot of the next frame the app ends, saved as name (a plain file name ending .png; by default prefix, the date and time, and a count, as "asteroids-2026-10-14-153012-1.png"). done, when given, runs once on the host thread after that frame. Failed after shutdown. Throws for a name that isn't a plain .png file name.
- `frameEnded`: After the app's frame: takes the screenshots asked for, from the frame it just ended. Nothing when none were asked for.
- `shutdown`: Fails what was asked for and refuses more.

## Screenshots

*class* in `src/helix/graphics/Screenshots.hx`

Screenshots of the frame, saved for the user (a download in a browser, a file natively; ScreenshotService). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from ScreenshotService's public members with their doc comments.

```haxe
static var instance(default, null):ScreenshotService
static function take(?name:String, ?done:ScreenshotResult -> Void):Void
```

- `instance`: The screenshots forwarded to: the runner's from its init to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the runner, nothing would set it again.
- `take`: Takes a screenshot of the next frame the app ends, saved as name (a plain file name ending .png; by default prefix, the date and time, and a count, as "asteroids-2026-10-14-153012-1.png"). done, when given, runs once on the host thread after that frame. Failed after shutdown. Throws for a name that isn't a plain .png file name.

## SdlGpuStages

*typedef* in `src/helix/graphics/ShaderSource.hx`

A program in SDL_GPU's dialects (tools/gpu_shaders.py), laid out as SDL_GPU binds: SPIR-V for Vulkan (each stage base64), MSL for Metal (entry points main0) and HLSL for Direct3D 12 (shader model 5.1, entry points main).

- `spirv:ShaderStages`
- `msl:ShaderStages`
- `hlsl:ShaderStages`

## Shader

*class* in `src/helix/graphics/Shader.hx`

An app's shader loaded from a .hxshader (tools/pack_shader.py; Shaders loads them): its program built on the GPU, its kind ("screen"), its uniform blocks' sizes, its own parameters by name and its own textures by name. A hot reload replaces the program in place and bumps reloadCount; its pipelines (Pipelines) are made again over the new program as they're next asked for.

```haxe
static function fromText(gpu:IGraphics, text:String):Shader
var handle(default, null):Int
var kind(default, null):String
var reloadCount(get, never):Int
var blockSizes(get, never):Array<Int>
function getParameter(name:String):Null<ShaderParameter>
function getTextureSlot(name:String):Int
var textureSlots(get, never):Array<Int>
function destroy():Void
```

- `fromText`: Builds a shader from a .hxshader's text on gpu. Throws, saying why, for a file it can't read or a program that doesn't build. The caller destroys it.
- `handle`: The IGraphics shader handle.
- `kind`: Its kind: "screen" (a screen effect) or "surface" (a Stage3D material's).
- `reloadCount`: How many times it has been replaced by a reload: a pipeline made before the latest is stale.
- `blockSizes`: Its uniform blocks' sizes in bytes, by slot: 0 for a slot it lacks.
- `getParameter`: One of its own parameters by name, or null.
- `getTextureSlot`: One of its own textures' slot by name, or -1.
- `textureSlots`: The texture slots it samples, the framework's and its own, in order (there may be gaps: a slot it doesn't use).
- `destroy`: Frees the program and the pipelines made over it.

## ShaderBlock

*typedef* in `src/helix/graphics/ShaderSource.hx`

A uniform block a program declares: its binding slot, its stage ("vertex" or "fragment"), its size in bytes, and its name in the GLSL, which flattens it to an array of vec4s.

- `vec4Count:Int`
- `stage:String`
- `slot:Int`
- `size:Int`
- `glslName:String`

## ShaderLoadResult

*enum* in `src/helix/graphics/Shaders.hx`

How a shader load ended.

- `Ready(shader:Shader)`
- `Failed(message:String)`
- `Cancelled`

## ShaderParameter

*typedef* in `src/helix/graphics/Shader.hx`

One of a shader's own parameters: its uniform block's slot, its byte offset there, its type (float, vec2, vec3, vec4, mat4) and how many (1 unless an array).

- `type:String`
- `slot:Int`
- `offset:Int`
- `elementCount:Int`

## ShaderParameters

*class* in `src/helix/graphics/ShaderParameters.hx`

An app's shader's own parameters and textures, set by name and kept across the shader's reloads (a name the reloaded shader lacks is kept and ignored), written into its uniform blocks at their std140 offsets when something draws with it. ScreenEffect and Material have one.

```haxe
function new(shader:Shader)
function setValues(name:String, values:Array<Float>):Bool
function setFloat(name:String, value:Float):Bool
function setColor(name:String, color:Int):Bool
function getValues(name:String):Null<Array<Float>>
function setTexture(name:String, texture:Texture2D):Bool
function getTexture(name:String):Null<Texture2D>
function write(blocks:Array<Null<haxe.io.Bytes>>):Void
var textureSlots(get, never):Map<Int, Texture2D>
```

- `new`: The parameters of shader.
- `setValues`: Sets parameter name (a float, or a vector's or matrix's first components, an array's elements' in turn) to values; the rest keep theirs. False when the shader has no such parameter or the values don't fit it.
- `setFloat`: Sets a float parameter. False, changing nothing, when the shader has no such parameter.
- `setColor`: Sets a vector parameter to a color 0xRRGGBBAA, each channel 0..1 as it is (not decoded from sRGB). False, changing nothing, when the shader has no such parameter or it has fewer than 4 components.
- `getValues`: The values a parameter was set to, or null for one never set (its value is then 0).
- `setTexture`: Binds texture to the shader's own texture name (sampled as the texture's sampling says). False when the shader has no such texture of its own.
- `getTexture`: The texture bound to name, or null.
- `write`: Writes the values set into blocks (the shader's uniform blocks' bytes by slot, null for one it lacks).
- `textureSlots`: The textures set, by the shader's slot.

## ShaderSource

*typedef* in `src/helix/graphics/ShaderSource.hx`

A compiled program: in every dialect HeliX's adapters use (GLSL 410 natively, GLSL ES 300 in the browser, and SDL_GPU's), its vertex attributes' names by slot, and the uniform blocks and textures it binds. The framework's are generated (each layout's source(); SDL_GPU's dialects only in SDL_GPU builds, which define helix_sdl3_gpu), an app's is a .hxshader (tools/pack_shader.py, SDL_GPU's dialects only when packed for those builds); IGraphics.createShader builds either the same way.

- `uniformBlocks:Array<ShaderBlock>`
- `textures:Array<ShaderTexture>`
- `sdlGpu:Null<SdlGpuStages>`
- `glsl410:ShaderStages`
- `glsl300es:ShaderStages`
- `attributes:Array<String>`

## ShaderStages

*typedef* in `src/helix/graphics/ShaderSource.hx`

One program's source for one backend dialect: its vertex and fragment stages.

- `vertex:String`
- `fragment:String`

## ShaderTexture

*typedef* in `src/helix/graphics/ShaderSource.hx`

A texture a program samples: its binding slot (its sampler's too), its stage, the GLSL name of the pair, and its kind: a shadow map (a depth array read through a comparison sampler), a cubemap, a data texture (RGBA32F read texel by texel, never filtered), or a plain 2D texture when none of them.

- `stage:String`
- `slot:Int`
- `shadow:Bool`
- `glslName:String`
- `data:Bool`
- `cube:Bool`

## Shaders

*class* in `src/helix/graphics/Shaders.hx`

Apps' shaders (.hxshader files, packed from GLSL by tools/pack_shader.py) loaded through the assets and built on the GPU, and built again in place when a file changes during development. The caller releases what it loads.

```haxe
function new(assets:IAssets, gpu:IGraphics)
function load(path:String, complete:ShaderLoadResult -> Void):IRequest
function release(shader:Shader):Void
function reloaded(path:String, bytes:haxe.io.Bytes):Void
```

- `new`: Loads through assets and builds on gpu.
- `load`: Loads path (a .hxshader) into a shader. complete runs exactly once on the host thread: Ready once its program is built, Failed for a load failure, a file it can't read or a program that doesn't build (with the compiler's log).
- `release`: Frees a shader this service loaded (after the pipelines made with it), and stops reloading it.
- `reloaded`: The file behind loaded shaders changed: they're built again in place. One that no longer builds stays as it was, its log traced.

## TextureFormat

*abstract* in `src/helix/graphics/TextureFormat.hx`

What a texture's texels are: plain RGBA8, a GPU's compressed format (4x4 blocks of 16 bytes each), which only some GPUs sample (IGraphics.canSample), or half floats, linear light beyond 1 (an environment's cubes). The 8-bit and compressed ones' colors are sRGB values, as the shaders treat them.

## VertexAttribute

*typedef* in `src/helix/graphics/PipelineDesc.hx`

A vertex attribute a pipeline reads from one of its buffers: its shader's input slot, its float count (1 to 4) and its byte offset in each record.

- `slot:Int`
- `offset:Int`
- `componentCount:Int`

## VertexBuffer

*typedef* in `src/helix/graphics/PipelineDesc.hx`

A vertex buffer a pipeline reads, by its index in a draw's buffers: its record's bytes, whether a record is an instance's (stepped once an instance) or a vertex's, and the attributes read from it. A buffer with no attributes is a gap the draw skips.

- `stride:Int`
- `instanced:Bool`
- `attributes:Array<VertexAttribute>`

## Wrap

*abstract* in `src/helix/graphics/Sampling.hx`

How a texture's edges repeat past 0..1.
