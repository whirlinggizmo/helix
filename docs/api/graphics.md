# helix.graphics

[Back to the index](README.md)

## AlphaMode

*abstract* in [`src/helix/graphics/AlphaMode.hx`](../../src/helix/graphics/AlphaMode.hx)

How a sprite or a particle uses its texels' alpha, the same in 2D and 3D (Sprite3D.alphaMode, Emitter.alphaMode). In 3D it also says when it's drawn among the models: with the opaque ones, among the see-through ones back to front, or after everything.

## BlendMode

*abstract* in [`src/helix/graphics/BlendMode.hx`](../../src/helix/graphics/BlendMode.hx)

How a pipeline's colors meet what the framebuffer has: replacing it, blended over it by their alpha (straight alpha), or added to it (times their alpha: light, fire, glows).

## ClipFlip

*abstract* in [`src/helix/graphics/PipelineDesc.hx`](../../src/helix/graphics/PipelineDesc.hx)

What uniform block 0 holds, so an adapter whose render targets are stored upside down (GL's bottom-left origin) can draw a target the right way up: nothing it touches, a clip scale it writes (x 1, y -1 in such a pass, else 1), or a view-projection matrix (column-major, its first 64 bytes) whose y row it negates in such a pass.

## Color

*class* in [`src/helix/graphics/Color.hx`](../../src/helix/graphics/Color.hx)

Colors as HeliX holds them: 0xAARRGGBB integers, alpha in the top byte, as Haxe's libraries write them and as an editor's color picker reads a literal. Each channel is 0 to 255. Text names a color the CSS way, #RRGGBB or #RRGGBBAA (a scene file, a color picker's field), converted by fromRgba and toRgba.

```haxe
static var fromChannels(inline, null):(red:Int, green:Int, blue:Int, ?alpha:Int) -> Int
static var getRed(inline, null):(color:Int) -> Int
static var getGreen(inline, null):(color:Int) -> Int
static var getBlue(inline, null):(color:Int) -> Int
static var getAlpha(inline, null):(color:Int) -> Int
static var withAlpha(inline, null):(color:Int, alpha:Int) -> Int
static var fromRgba(inline, null):(rgba:Int) -> Int
static var toRgba(inline, null):(color:Int) -> Int
```

- `fromChannels`: The color of these channels, each 0 to 255 (only its low 8 bits are taken), alpha opaque unless given.
- `getRed`: color's red, 0 to 255.
- `getGreen`: color's green, 0 to 255.
- `getBlue`: color's blue, 0 to 255.
- `getAlpha`: color's alpha, 0 (clear) to 255 (opaque).
- `withAlpha`: color with its alpha replaced by alpha, 0 to 255 (only its low 8 bits are taken).
- `fromRgba`: The color an 0xRRGGBBAA integer names (the CSS order, as text writes it).
- `toRgba`: color as an 0xRRGGBBAA integer (the CSS order, as text writes it).

## CullFace

*abstract* in [`src/helix/graphics/PipelineDesc.hx`](../../src/helix/graphics/PipelineDesc.hx)

Which faces of a pipeline's triangles aren't drawn.

## DepthTest

*abstract* in [`src/helix/graphics/PipelineDesc.hx`](../../src/helix/graphics/PipelineDesc.hx)

Which fragments a pipeline's depth test passes, against the depth already there.

## Graphics

*class* in [`src/helix/graphics/Graphics.hx`](../../src/helix/graphics/Graphics.hx)

The GPU: textures, buffers, shaders, pipelines, passes and draws. Shutting it down is the runner's, and so is the frame: the runner opens and closes it around the stage's drawing (docs/DISPLAY_MODEL.md), so beginFrame and endFrame aren't here; a pass into a texture (beginTargetPass) is drawn in init or update, before the frame opens. The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from IGraphics's public members with their doc comments.

```haxe
static function createTexture(width:Int, height:Int, levels:Array<haxe.io.Bytes>, ?format:TextureFormat = helix.texture.TextureFormat.Rgba8):Int
static function createCubeTexture(size:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat):Int
static function createDataTexture(width:Int, height:Int):Int
static function updateDataTexture(handle:Int, data:haxe.io.Bytes):Void
static function canSample(format:TextureFormat):Bool
static var msaaSamples(get, never):Int
static var maxMsaaSamples(get, never):Int
static function createRenderTarget(width:Int, height:Int, ?format:TextureFormat = helix.texture.TextureFormat.Rgba8, ?depth:Bool = true):Int
static function canRender(format:TextureFormat):Bool
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
static function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void
static function endTargetPass():Void
static function applyViewport(x:Int, y:Int, w:Int, h:Int):Void
static function applyScissor(x:Int, y:Int, w:Int, h:Int):Void
static function resetScissor():Void
static function draw(pipeline:Int, buffers:Array<Int>, indices:Int, first:Int, count:Int, firstInstance:Int, instanceCount:Int, textures:Array<Int>, samplings:Array<Sampling>, uniforms:Array<Null<haxe.io.Bytes>>):Void
static function readPixels(target:Int, done:ReadPixelsResult -> Void):Void
```

- `createTexture`: Uploads an image, rows top first, and returns its handle. levels is the image then, optionally, its mipmaps, each half the size of the last (at least 1; Mipmaps.build makes them for RGBA8), each format.levelBytes of its size. How it is sampled is each draw's (Sampling). Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample.
- `createCubeTexture`: Uploads a cubemap, each face size x size, and returns its handle, sampled at a texture slot like any texture (the samplings' filter applies, their wrap doesn't: a cube's faces meet). levels is mip 0 then, optionally, its mips, each half the size of the last (at least 1), each its six faces one after another (+X, -X, +Y, -Y, +Z, -Z, in GL's cube orientation: a face's first row is its t = 0), each face format.levelBytes of its size. Throws for a size of 0 or less, no levels, a level of the wrong byte count, or a format this GPU can't sample.
- `createDataTexture`: Makes a data texture width x height of RGBA 32-bit floats (16 bytes a texel), read texel by texel (texelFetch: never filtered, its samplings ignored), and returns its handle. Its contents are updateDataTexture's. Throws for a size of 0 or less or past this GPU's.
- `updateDataTexture`: Replaces a data texture's whole contents with data's first width * height * 16 bytes (rows top first, little-endian floats), for the draws after it; any number of times a frame. Throws for a handle that isn't a data texture or data too short.
- `canSample`: Whether this GPU samples textures of format: RGBA8 always; the compressed ones on GPUs that have them; half floats where it filters them.
- `msaaSamples`: Multisampling samples a pixel the screen is drawn with (WindowOptions.requestMsaaSamples): 1 for none, else what the platform gave, which may be fewer than asked. Render targets with depth are drawn with the same, resolved into the texture sampled.
- `maxMsaaSamples`: The most multisampling samples a pixel a window could ask for here, at most 8 (what requestMsaaSamples takes): for a settings menu to offer, applied at the next start. Natively the GPU's most; a browser only switches antialiasing on or off, choosing its own count, so there it's the count the canvas has when on (4 where the GPU has 4, else 1).
- `createRenderTarget`: Makes a render target width x height of format and returns its handle: a texture, sampled like any other and stored top row first like any other, that a target pass draws into. With depth, it has a depth buffer of its own and is multisampled as the screen is (msaaSamples, or single where this GPU can't multisample format), resolved into the texture at each pass's end; without, it has neither (a pass drawing over the whole target: a screen effect's). Throws for a size of 0 or less, or a format this GPU can't draw into (canRender).
- `canRender`: Whether this GPU draws into render targets of format, blends over them and filters them when sampled: RGBA8 always; RGBA16F where float targets exist (natively nearly always; in a browser through EXT_color_buffer_float, turned on by asking); never a compressed one.
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
- `beginTargetPass`: Starts a pass drawing into target (a createRenderTarget handle): clears it to red, green, blue and alpha, as its texels store them (0 to 1 in an RGBA8 target; a half-float one holds values past 1, as an HDR scene's light), and its depth (if it has one) to the farthest, and sets the viewport to all of it. Before the screen's pass, outside any other. Throws inside a pass or for a handle that isn't a render target.
- `endTargetPass`: Ends the pass beginTargetPass or beginShadowPass started; its target can be sampled from then on. Throws when no such pass is open.
- `applyViewport`: Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less.
- `applyScissor`: Draws from now on only inside x, y, w, h in framebuffer pixels from the bottom-left (as applyViewport), until resetScissor or the pass ends; a pass begins unclipped. Throws outside a pass or for a size below 0.
- `resetScissor`: Draws everywhere in the pass again. Throws outside a pass.
- `draw`: Draws through pipeline: count vertices from first of its buffers (or, for an indexed pipeline, count indices from first of indices, a static index buffer), whole primitives, as instanceCount instances whose records start at record firstInstance of its instanced buffers. buffers[i] is the buffer (createBuffer's, as this frame's upload left it, or createStaticBuffer's) for the pipeline's buffer i (0 for a gap); textures[i] is bound at the program's texture slot i (0 for a slot it doesn't sample), sampled as samplings[i] says (a shadow map or data texture as its kind is); uniforms[i] is the bytes of its uniform block at slot i (its declared size; null for a slot it lacks), block 0 flipped as the pipeline's clip flip says. A pipeline without buffers draws count vertices from nothing (one triangle over the viewport: three). Throws for anything invalid, before drawing.
- `readPixels`: Reads target back (a createRenderTarget handle; 0 for the frame endFrame just ended, read before the host's frame returns, as a browser presents it then and a GPU may swap it away); done runs once on the host thread, during this call or, on a GPU that reads back asynchronously, later: Read, or Failed when no frame has ended since the last beginFrame. Slow (it waits for the GPU): for screenshots and checks, not every frame. Throws inside a pass or for a handle that isn't an RGBA8 render target.

## GraphicsUnavailable

*class* in [`src/helix/graphics/GraphicsUnavailable.hx`](../../src/helix/graphics/GraphicsUnavailable.hx)

Thrown by a graphics adapter that can't get the GPU API it draws through (no WebGL2 in this browser, say), whichever API that is, so a host can tell the program's code failing from the platform lacking what it needs.

```haxe
function new(message:String, ?previous:haxe.Exception, ?native:Any)
```


## IGraphics

*class* in [`src/helix/graphics/IGraphics.hx`](../../src/helix/graphics/IGraphics.hx)

The GPU, as thin as HeliX can make it: a platform's graphics adapter implements it and nothing else. Resources (textures of a few kinds, buffers, programs built from a ShaderSource, pipelines made from a PipelineDesc), passes (the frame's screen pass after any passes into render targets and shadow maps) and one draw. An adapter knows no program, layout or pipeline of HeliX's own: shared code describes those (Pipelines, the generated program classes) and hands them over as data, so another adapter (another GPU API, another platform) implements this alone. A call that can't be done throws, before doing anything.

```haxe
function createTexture(width:Int, height:Int, levels:Array<haxe.io.Bytes>, ?format:TextureFormat = Rgba8):Int
function createCubeTexture(size:Int, levels:Array<haxe.io.Bytes>, format:TextureFormat):Int
function createDataTexture(width:Int, height:Int):Int
function updateDataTexture(handle:Int, data:haxe.io.Bytes):Void
function canSample(format:TextureFormat):Bool
var msaaSamples(get, never):Int
var maxMsaaSamples(get, never):Int
function createRenderTarget(width:Int, height:Int, ?format:TextureFormat = Rgba8, ?depth:Bool = true):Int
function canRender(format:TextureFormat):Bool
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
function beginTargetPass(target:Int, red:Float, green:Float, blue:Float, alpha:Float):Void
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
- `msaaSamples`: Multisampling samples a pixel the screen is drawn with (WindowOptions.requestMsaaSamples): 1 for none, else what the platform gave, which may be fewer than asked. Render targets with depth are drawn with the same, resolved into the texture sampled.
- `maxMsaaSamples`: The most multisampling samples a pixel a window could ask for here, at most 8 (what requestMsaaSamples takes): for a settings menu to offer, applied at the next start. Natively the GPU's most; a browser only switches antialiasing on or off, choosing its own count, so there it's the count the canvas has when on (4 where the GPU has 4, else 1).
- `createRenderTarget`: Makes a render target width x height of format and returns its handle: a texture, sampled like any other and stored top row first like any other, that a target pass draws into. With depth, it has a depth buffer of its own and is multisampled as the screen is (msaaSamples, or single where this GPU can't multisample format), resolved into the texture at each pass's end; without, it has neither (a pass drawing over the whole target: a screen effect's). Throws for a size of 0 or less, or a format this GPU can't draw into (canRender).
- `canRender`: Whether this GPU draws into render targets of format, blends over them and filters them when sampled: RGBA8 always; RGBA16F where float targets exist (natively nearly always; in a browser through EXT_color_buffer_float, turned on by asking); never a compressed one.
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
- `beginTargetPass`: Starts a pass drawing into target (a createRenderTarget handle): clears it to red, green, blue and alpha, as its texels store them (0 to 1 in an RGBA8 target; a half-float one holds values past 1, as an HDR scene's light), and its depth (if it has one) to the farthest, and sets the viewport to all of it. Before the screen's pass, outside any other. Throws inside a pass or for a handle that isn't a render target.
- `endTargetPass`: Ends the pass beginTargetPass or beginShadowPass started; its target can be sampled from then on. Throws when no such pass is open.
- `beginFrame`: Starts the frame's screen pass on a width x height framebuffer, after its target passes: clears it to clearColor (0xAARRGGBB) and the depth to the farthest, and sets the viewport to all of it. Throws inside a pass or for a size of 0 or less.
- `applyViewport`: Draws from now on into x, y, w, h in framebuffer pixels from the bottom-left. Throws outside a frame or for a size of 0 or less.
- `applyScissor`: Draws from now on only inside x, y, w, h in framebuffer pixels from the bottom-left (as applyViewport), until resetScissor or the pass ends; a pass begins unclipped. Throws outside a pass or for a size below 0.
- `resetScissor`: Draws everywhere in the pass again. Throws outside a pass.
- `draw`: Draws through pipeline: count vertices from first of its buffers (or, for an indexed pipeline, count indices from first of indices, a static index buffer), whole primitives, as instanceCount instances whose records start at record firstInstance of its instanced buffers. buffers[i] is the buffer (createBuffer's, as this frame's upload left it, or createStaticBuffer's) for the pipeline's buffer i (0 for a gap); textures[i] is bound at the program's texture slot i (0 for a slot it doesn't sample), sampled as samplings[i] says (a shadow map or data texture as its kind is); uniforms[i] is the bytes of its uniform block at slot i (its declared size; null for a slot it lacks), block 0 flipped as the pipeline's clip flip says. A pipeline without buffers draws count vertices from nothing (one triangle over the viewport: three). Throws for anything invalid, before drawing.
- `endFrame`: Ends the screen's pass and with it the frame, presenting it. Throws when no screen pass is open.
- `readPixels`: Reads target back (a createRenderTarget handle; 0 for the frame endFrame just ended, read before the host's frame returns, as a browser presents it then and a GPU may swap it away); done runs once on the host thread, during this call or, on a GPU that reads back asynchronously, later: Read, or Failed when no frame has ended since the last beginFrame. Slow (it waits for the GPU): for screenshots and checks, not every frame. Throws inside a pass or for a handle that isn't an RGBA8 render target.
- `shutdown`: Releases the adapter itself, after its handles are destroyed.

## IImageDecoder

*class* in [`src/helix/graphics/IImageDecoder.hx`](../../src/helix/graphics/IImageDecoder.hx)

Image decoding on a platform: PNG, JPEG, BMP, TGA and GIF (its first frame) to 8-bit RGBA, rows top to bottom, not premultiplied. Queuing, cancellation and shutdown are the shared ImageDecoding's.

```haxe
function decode(encoded:haxe.io.Bytes, done:ImageDecodeResult -> Void):Void
function poll():Void
```

- `decode`: Decodes encoded off the frame where the platform can; done runs once on the host thread, never during this call: Decoded or Failed.
- `poll`: Delivers what finished on the platform's threads since the last poll; the shared ImageDecoding calls it once a frame.

## ImageDecodeResult

*enum* in [`src/helix/graphics/ImageDecoding.hx`](../../src/helix/graphics/ImageDecoding.hx)

How a decode ended: the image as 8-bit RGBA, rows top to bottom, not premultiplied; or why not; or cancellation.

- `Decoded(width:Int, height:Int, rgba:haxe.io.Bytes)`
- `Failed(message:String)`
- `Cancelled`

## ImageDecoding

*class* in [`src/helix/graphics/ImageDecoding.hx`](../../src/helix/graphics/ImageDecoding.hx)

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

## PipelineDesc

*typedef* in [`src/helix/graphics/PipelineDesc.hx`](../../src/helix/graphics/PipelineDesc.hx)

A pipeline, everything a draw through it fixes: the program (an IGraphics.createShader handle), its vertex buffers' layout, what it draws, whether its draws are indexed (uint32 indices), how its colors meet the target's (blend), the depth test and write, which faces are culled and which winding is the front, whether it writes depth alone (a shadow pass's), and its block 0's clip flip. Shared code describes the framework's pipelines (Pipelines); an adapter only makes what the description says.

- `shader:Int`
- `primitive:Primitive`
- `indexed:Bool`
- `flip:ClipFlip`
- `depthWrite:Bool`
- `depthTest:DepthTest`
- `depthOnly:Bool`
- `cull:CullFace`
- `clockwise:Bool`
- `buffers:Array<VertexBuffer>`
- `blend:BlendMode`

## Pipelines

*class* in [`src/helix/graphics/Pipelines.hx`](../../src/helix/graphics/Pipelines.hx)

The framework's programs and pipelines on one GPU, shared by everything drawing on it: each framework program built once from its generated source (the program classes' source()), and each pipeline described here (its program, buffers' layout and state: PipelineDesc) and made the first time it's asked for, then kept. Drawing code asks for its pipeline at each draw and never keeps the handle, so a program built again (an app's shader reloaded, or in development a framework program whose source changed) has its pipelines made again behind it. This is the framework's knowledge of its pipelines; an adapter knows none of it.

```haxe
static function of(gpu:IGraphics):Pipelines
static function release(gpu:IGraphics):Void
function forgetShader(shader:Int):Void
function sprite2D(blend:BlendMode):Int
function color3D():Int
function lines3D():Int
function lit3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
function skinned3D(blend:BlendMode, doubleSided:Bool, clockwise:Bool):Int
function surface(shader:Int, blend:BlendMode, doubleSided:Bool, clockwise:Bool, skinned:Bool):Int
function surfaceCaster(shader:Int, skinned:Bool):Int
function flat3D(skinned:Bool, behind:Bool, clockwise:Bool):Int
function sprite3D(blend:BlendMode):Int
function spriteEffect3D(shader:Int, blend:BlendMode):Int
function particle3D(blend:BlendMode):Int
function depth3D():Int
function skinnedDepth3D():Int
function background3D():Int
function spriteEffect(shader:Int, blend:BlendMode):Int
function screen(shader:Int, blend:BlendMode):Int
```

- `of`: gpu's, made the first time it's asked for.
- `release`: Frees gpu's pipelines and framework programs, before the adapter shuts down.
- `forgetShader`: Destroys the pipelines made over shader (an app's, before it is destroyed or replaced); asked for again, they're made again.
- `sprite2D`: 2D sprites and shapes: Sprite2DProgram's vertices in clip space (its block the clip scale), no depth.
- `color3D`: Vertex-colored 3D triangles (Color3DProgram, the view-projection its block), depth tested and written.
- `lines3D`: Color3D's vertices as lines, two each.
- `lit3D`: Lit models (Lit3DProgram): blended or not, double sided or not, front faces clockwise (a mirrored placement's) or not.
- `skinned3D`: Skinned lit models (Skinned3DProgram: Lit3D's buffers and the skin), as lit3d's variants.
- `surface`: An app's surface shader (its handle; for a skinned model its skinned variant's, over Skinned3DProgram's buffers) drawing lit models, as lit3d's variants.
- `surfaceCaster`: A surface shader's shadow caster (its handle: Shader.caster's, or its skinned variant's caster for a skinned model, over Skinned3DProgram's buffers), from the lit models' records: depth only, nothing culled, as the framework's casters.
- `flat3D`: A model's flat pass (Flat3DProgram, or Skinnedflat3DProgram for a skinned model), from its mesh's pass vertices (Mesh3D.passVertices) and the lit models' instance records: an outline's shell (front faces culled, depth tested and written, opaque), or with behind, a silhouette (only where something nearer was drawn: depth greater, not written, blended, back faces culled); front faces clockwise (a mirrored placement's) or not.
- `sprite3D`: 3D sprites (Sprite3DProgram).
- `spriteEffect3D`: A sprite effect's Renderer3D variant (its handle: SpriteEffect.shader.sprite3D's) drawing 3D sprites (Sprite3DProgram), as sprite3D's.
- `particle3D`: Particles (Particle3DProgram).
- `depth3D`: Shadow-map casters (Depth3DProgram): depth only, nothing culled (a one-sided floor still casts).
- `skinnedDepth3D`: Skinned shadow-map casters (Skinneddepth3DProgram).
- `background3D`: An environment behind a 3D scene (Background3DProgram): one triangle at the far plane, depth tested (less or equal) and not written.
- `spriteEffect`: A sprite effect's shader (its handle: SpriteEffect.shader's) drawing 2D sprites: Effect2DProgram's vertices in clip space (block 0 the clip scale), no depth.
- `screen`: An app's screen effect (its handle): one triangle over the viewport, no depth.

## Png

*class* in [`src/helix/graphics/Png.hx`](../../src/helix/graphics/Png.hx)

PNG encoding in Haxe, the same bytes on every target: RGBA8 rows filtered as PNG suggests (the filter of the smallest sum, row by row), then deflated with LZ77 matching and the fixed Huffman codes. Smaller than stored data by about as much as a dynamic-code encoder for flat, synthetic images (a game's frame); larger for noisy ones.

```haxe
static function encode(width:Int, height:Int, rgba:haxe.io.Bytes):haxe.io.Bytes
```

- `encode`: The PNG file of a width x height RGBA8 image, rows top first (rgba holds at least width * height * 4 bytes). Throws for a size of 0 or less or rgba too short.

## PostProcess

*class* in [`src/helix/graphics/PostProcess.hx`](../../src/helix/graphics/PostProcess.hx)

Screen effects over a finished frame: the scene is drawn into a texture the screen's size (beginScene to endScene, a target pass), the enabled effects but the last draw in turn from one texture into another (target passes without depth, still before the screen's), and present draws the last over the screen's pass, or the frame as it is when no effect is on. Effects run in the order added, so turning one off and on (ScreenEffect.enabled) keeps its place. Its textures follow the screen's size; an effect's intermediates (ScreenEffect.intermediates) are made at their fractions of it. An HDR chain: when an enabled effect wants HDR (ScreenEffect.hdr) and the GPU draws half floats (IGraphics.canRender), the scene is drawn in RGBA16F, the 3D views drawing into it (View3D: the stage tells them, View) writing their light after the exposure with no tone mapping, as sRGB values running past 1 (the sRGB curve carried on past 1, so sprites, particles and text, whose colors are sRGB values already, blend into it as into the screen, and are tone mapped with it). The tone mapping then runs as an effect (helix.shader.Tonemap, Neutral unless the chain has its own), after the last effect wanting HDR, unless the chain has one of its own; the effects before it read and write half floats, the ones after it the tone-mapped frame in RGBA8. Without half floats every texture is RGBA8 as the screen is, the 3D views tone map as they draw, and a Tonemap in the chain is skipped. An HDR scene is cleared to what its tone mapping shows as the clear color (Tonemap.computeHdrColor), so a background of clear color alone looks the same with the chain HDR or not.

```haxe
function new(?gpu:IGraphics)
var hdr(default, null):Bool
var sceneTexture(get, never):Null<Texture2D>
function add(effect:ScreenEffect):Bool
function remove(effect:ScreenEffect):Bool
function beginScene(width:Int, height:Int, clearColor:Int):Void
function endScene(time:Float):Void
function present():Void
function destroy():Void
```

- `new`: Effects drawn on gpu (the program's, Graphics, when not given), over a scene (the stage's, Stage.postProcess, or a view's, View.postProcess).
- `hdr`: Whether this frame's scene (the last beginScene's) is drawn in half floats: an enabled effect wants HDR and the GPU draws them.
- `sceneTexture`: The texture the scene is drawn into (the last beginScene's), or null before one.
- `add`: Adds effect at the end of the chain. False, changing nothing, when it is in the chain already.
- `remove`: Takes effect out of the chain, freeing its intermediates (the effect stays its owner's). False when it isn't in the chain.
- `beginScene`: Starts the frame's scene: a target pass into a width x height texture (the screen's size; half floats in an HDR chain), cleared to clearColor (0xAARRGGBB; in an HDR chain to the light its tone mapping shows as clearColor). Draw it as the screen; endScene ends it. Which effects draw this frame is taken here. Throws inside another pass.
- `endScene`: Ends the scene's pass and draws the effects but the last (each that was enabled at beginScene, in order, with the tone mapping in an HDR chain), each its intermediates and then from the one before's result into a texture of the chain, at time seconds; the last's intermediates too, its last pass waiting for present.
- `present`: Draws the processed frame over the open screen pass's viewport: the last effect over the others' result, or the frame as it is.
- `destroy`: Frees its textures and buffer; the effects stay their owner's.

## Primitive

*abstract* in [`src/helix/graphics/PipelineDesc.hx`](../../src/helix/graphics/PipelineDesc.hx)

What a pipeline's draws make: triangles, three vertices (or indices) each, or lines, two each.

## ReadPixelsResult

*enum* in [`src/helix/graphics/IGraphics.hx`](../../src/helix/graphics/IGraphics.hx)

Pixels read back from the GPU: width x height RGBA8, rows top first; or why they couldn't be.

- `Read(width:Int, height:Int, rgba:haxe.io.Bytes)`
- `Failed(message:String)`

## ScreenEffect

*class* in [`src/helix/graphics/ScreenEffect.hx`](../../src/helix/graphics/ScreenEffect.hx)

A screen effect: a Shader of kind screen drawn over a whole frame (one triangle over the viewport), with its own parameters and textures set by name (parameters), kept across the shader's reloads. PostProcess chains them (PostProcess.add); drawPass draws its shader once into the open pass. An effect of several passes (a subclass: a blur, a bloom's downsample chain) asks for intermediates, draws into them before its last pass (drawIntermediates, each step a ScreenEffect of its own drawn with drawInto) and reads more than one of them through its own textures (parameters.setTexture).

```haxe
function new(shader:Shader, ?alpha:Bool = false, ?gpu:IGraphics)
var shader(default, null):Shader
var parameters(default, null):ShaderParameters
var enabled:Bool
var hdr:Bool
var intermediates(default, null):Array<Float>
function drawIntermediates(frame:ScreenFrame):Void
function draw(frame:ScreenFrame):Void
function drawInto(target:Texture2D, source:Texture2D, time:Float):Void
function drawPass(source:Texture2D, width:Int, height:Int, time:Float):Void
```

- `new`: An effect drawing with shader (kind screen), blended over what's there when alpha, else replacing it, on gpu (the program's, Graphics, when not given). Throws for a shader of another kind.
- `shader`: Its shader.
- `parameters`: Its shader's own parameters and textures, set by name.
- `enabled`: Whether PostProcess draws it.
- `hdr`: Whether it reads an HDR frame: in a chain with one, PostProcess draws the scene in half floats where the GPU can (IGraphics.canRender), its colors running past 1, and tone maps it after the last such effect (helix.shader.Tonemap). False (the default) for an effect that reads the frame as the screen shows it, tone mapped, 0 to 1.
- `intermediates`: The textures it draws through before its last pass, each its size as a fraction of the frame's each way (.5: half; at least a pixel): PostProcess makes them in the frame's format, without depth, and hands them over in ScreenFrame.intermediates. Empty (the default) for an effect of one pass.
- `drawIntermediates`: Draws its passes before the last into frame.intermediates, each a target pass (drawInto), before the screen's pass: nothing for an effect of one pass (the default).
- `draw`: Draws its last pass over the open pass's viewport, frame.width x frame.height pixels: by default its shader once, reading frame.source.
- `drawInto`: Draws its shader once into target in a target pass of its own (cleared to transparent black), reading source, time seconds since it began: one step of an effect of several passes. Before the screen's pass, outside any other.
- `drawPass`: Draws its shader once over the open pass's viewport, reading source (the frame it changes), width x height pixels, seconds since it began. A texture of its own that isn't set is drawn as source.

## ScreenFrame

*class* in [`src/helix/graphics/ScreenFrame.hx`](../../src/helix/graphics/ScreenFrame.hx)

What a screen effect draws from in a PostProcess chain, this frame: the frame it changes, its size, the time, and the intermediates it asked for (ScreenEffect.intermediates), made by PostProcess at their sizes in the frame's format.

```haxe
function new(source:Texture2D, width:Int, height:Int, time:Float, intermediates:Array<Texture2D>)
final source:Texture2D
final width:Int
final height:Int
final time:Float
final intermediates:Array<Texture2D>
```

- `new`: A frame for an effect: source, width x height framebuffer pixels, time seconds, its intermediates.
- `source`: The frame the effect changes: the scene, or the effect before's result.
- `width`: The size of the frame the effect draws, in framebuffer pixels.
- `height`: The size of the frame the effect draws, in framebuffer pixels.
- `time`: Seconds since the effect began (the time PostProcess.endScene was given).
- `intermediates`: The effect's intermediates, in the order of its ScreenEffect.intermediates: textures without depth, each that fraction of width and height (at least a pixel), half floats where source is.

## ScreenshotResult

*enum* in [`src/helix/graphics/ScreenshotService.hx`](../../src/helix/graphics/ScreenshotService.hx)

How a screenshot ended: where it was saved and its PNG file, or why it wasn't.

- `Saved(where:String, png:haxe.io.Bytes)`
- `Failed(message:String)`

## Screenshots

*class* in [`src/helix/graphics/Screenshots.hx`](../../src/helix/graphics/Screenshots.hx)

Screenshots of the frame, saved for the user (a download in a browser, a file natively; ScreenshotService). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from ScreenshotService's public members with their doc comments.

```haxe
static function take(?name:String, ?done:ScreenshotResult -> Void):Void
static function sample(points:Array<Array<Float>>, done:Array<Array<Int>> -> Void, ?failed:String -> Void):Void
```

- `take`: Takes a screenshot of the next frame the app ends, saved as name (a plain file name ending .png; by default prefix, the date and time, and a count, as "asteroids-2026-10-14-153012-1.png"). done, when given, runs once on the host thread after that frame. Failed after shutdown. Throws for a name that isn't a plain .png file name.
- `sample`: Reads the next frame the app ends at points, each [x, y] in the design's units (Screen's; the pixel under it): done runs once on the host thread with each point's color as [r, g, b, a], 0 to 255 (0, 0, 0, 0 off the frame), or failed (else the log) when the frame can't be read or after shutdown. For checks that compare a few pixels across targets (the autopilot's sample), not every frame.

## SdlGpuStages

*typedef* in [`src/helix/graphics/ShaderSource.hx`](../../src/helix/graphics/ShaderSource.hx)

A program in SDL_GPU's dialects (src/helix/tool/shader/GpuShaders.hx), laid out as SDL_GPU binds: SPIR-V for Vulkan (each stage base64), MSL for Metal (entry points main0) and HLSL for Direct3D 12 (shader model 5.1, entry points main).

- `spirv:ShaderStages`
- `msl:ShaderStages`
- `hlsl:ShaderStages`

## Shader

*class* in [`src/helix/graphics/Shader.hx`](../../src/helix/graphics/Shader.hx)

An app's shader loaded from a .hxshader (src/helix/tool/shader/ShaderPacker.hx; Shaders loads them, the shader library packs its own into the program): its program built on the GPU, its kind ("screen", "surface" or "sprite"), its uniform blocks' sizes, its own parameters by name and its own textures by name. A surface shader comes with its variants, each a Shader of its own over the same parameters: skinned (drawing skinned models) and caster (drawing its shadow, when it has a vertex hook or a discard); a sprite shader with sprite3D (drawing a Renderer3D's sprites). A hot reload replaces the programs in place and bumps reloadCount; their pipelines (Pipelines) are made again over the new programs as they're next asked for.

```haxe
static var FORMAT(inline, null):Int
static function fromText(text:String, ?gpu:IGraphics):Shader
var handle(default, null):Int
var kind(default, null):String
var skinned(default, null):Null<Shader>
var caster(default, null):Null<Shader>
var sprite3D(default, null):Null<Shader>
var reloadCount(get, never):Int
var blockSizes(get, never):Array<Int>
function getParameter(name:String):Null<ShaderParameter>
function getTextureSlot(name:String):Int
var textureSlots(get, never):Array<Int>
function destroy():Void
```

- `FORMAT`: The .hxshader format it reads (src/helix/tool/shader/ShaderPacker.hx's FORMAT).
- `fromText`: Builds a shader, and its variants, from a .hxshader's text on gpu (the program's, Graphics, when not given). Throws, saying why, for a file it can't read or a program that doesn't build. The caller destroys it.
- `handle`: The IGraphics shader handle.
- `kind`: Its kind: "screen" (a screen effect), "surface" (a Renderer3D material's) or "sprite" (a 2D sprite's: a SpriteEffect).
- `skinned`: The same surface shader drawing skinned models: its vertex stage moves each vertex by its joints (the stage's joint texture, at slot 5) before its vertex hook, its fragment stage, parameters and textures this one's. Null for a screen or sprite shader. Its caster draws skinned casters.
- `caster`: The program drawing its shadow casters into a shadow map: the depth pass with its vertex hook, its fragment stage run for what it discards. Null for a surface shader with neither a vertex hook nor a discard, whose shadow the framework's caster draws, and for a screen or sprite shader.
- `sprite3D`: The same sprite shader drawing a Renderer3D's sprites (Sprite3D.effect): its fragment stage over the framework's 3D sprite vertex stage (Sprite3DProgram's records, block 0 the sprites' uniforms), its output applying each sprite's alpha mode; its parameters and textures this one's. Null for a screen or surface shader.
- `reloadCount`: How many times it has been replaced by a reload: a pipeline made before the latest is stale.
- `blockSizes`: Its uniform blocks' sizes in bytes, by slot: 0 for a slot it lacks.
- `getParameter`: One of its own parameters by name, or null.
- `getTextureSlot`: One of its own textures' slot by name, or -1.
- `textureSlots`: The texture slots it samples, the framework's and its own, in order (there may be gaps: a slot it doesn't use).
- `destroy`: Frees the programs, its variants' too, and the pipelines made over them.

## ShaderBlock

*typedef* in [`src/helix/graphics/ShaderSource.hx`](../../src/helix/graphics/ShaderSource.hx)

A uniform block a program declares: its binding slot, its stage ("vertex" or "fragment"), its size in bytes, and its name in the GLSL, which flattens it to an array of vec4s.

- `vec4Count:Int`
- `stage:String`
- `slot:Int`
- `size:Int`
- `glslName:String`

## ShaderParameter

*typedef* in [`src/helix/graphics/Shader.hx`](../../src/helix/graphics/Shader.hx)

One of a shader's own parameters: its uniform block's slot, its byte offset there, its type (float, vec2, vec3, vec4, mat4) and how many (1 unless an array).

- `type:String`
- `slot:Int`
- `offset:Int`
- `elementCount:Int`

## ShaderParameters

*class* in [`src/helix/graphics/ShaderParameters.hx`](../../src/helix/graphics/ShaderParameters.hx)

An app's shader's own parameters and textures, set by name and kept across the shader's reloads (a name the reloaded shader lacks is kept and ignored), written into its uniform blocks at their std140 offsets when something draws with it. ScreenEffect and Material3D have one.

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
- `setColor`: Sets a vector parameter to a color 0xAARRGGBB, each channel 0..1 as it is (not decoded from sRGB). False, changing nothing, when the shader has no such parameter or it has fewer than 4 components.
- `getValues`: The values a parameter was set to, or null for one never set (its value is then 0).
- `setTexture`: Binds texture to the shader's own texture name (sampled as the texture's sampling says). False when the shader has no such texture of its own.
- `getTexture`: The texture bound to name, or null.
- `write`: Writes the values set into blocks (the shader's uniform blocks' bytes by slot, null for one it lacks).
- `textureSlots`: The textures set, by the shader's slot.

## ShaderSource

*typedef* in [`src/helix/graphics/ShaderSource.hx`](../../src/helix/graphics/ShaderSource.hx)

A compiled program: in every dialect HeliX's adapters use (GLSL 410 natively, GLSL ES 300 in the browser, and SDL_GPU's), its vertex attributes' names by slot, and the uniform blocks and textures it binds. The framework's are generated (each program class's source(); SDL_GPU's dialects only in SDL_GPU builds, which define helix_sdl3_gpu), an app's is a .hxshader (src/helix/tool/shader/ShaderPacker.hx, SDL_GPU's dialects only when packed for those builds); IGraphics.createShader builds either the same way.

- `uniformBlocks:Array<ShaderBlock>`
- `textures:Array<ShaderTexture>`
- `sdlGpu:Null<SdlGpuStages>`
- `glsl410:Null<ShaderStages>`: GLSL 410, natively; absent in a browser build (the webgl2 backend), which reads only glsl300es, so the generated programs leave it out.
- `glsl300es:ShaderStages`: GLSL ES 300, the browser's.
- `attributes:Array<String>`

## ShaderStages

*typedef* in [`src/helix/graphics/ShaderSource.hx`](../../src/helix/graphics/ShaderSource.hx)

One program's source for one backend dialect: its vertex and fragment stages.

- `vertex:String`
- `fragment:String`

## ShaderTexture

*typedef* in [`src/helix/graphics/ShaderSource.hx`](../../src/helix/graphics/ShaderSource.hx)

A texture a program samples: its binding slot (its sampler's too), its stage, the GLSL name of the pair, and its kind: a shadow map (a depth array read through a comparison sampler), a cubemap, a data texture (RGBA32F read texel by texel, never filtered), or a plain 2D texture when none of them.

- `stage:String`
- `slot:Int`
- `shadow:Bool`
- `glslName:String`
- `data:Bool`
- `cube:Bool`

## Shaders

*class* in [`src/helix/graphics/Shaders.hx`](../../src/helix/graphics/Shaders.hx)

Apps' shaders (.hxshader files, packed from GLSL by src/helix/tool/shader/ShaderPacker.hx; how one is written: docs/SHADERS.md) loaded through the assets and built on the GPU, and built again in place when a file changes during development. The caller releases what it loads.

```haxe
function new(?assets:IAssets, ?gpu:IGraphics)
function load(path:String, loaded:Shader -> Void, ?failed:String -> Void):IRequest
function release(shader:Shader):Void
function reloaded(path:String, bytes:haxe.io.Bytes):Void
```

- `new`: Loads through assets and builds on gpu: the program's (Assets, Graphics) for those not given, read as they're used, so a cache made before the program runs (a field's initial value) works.
- `load`: Loads path (a .hxshader) into a shader. One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded once its program is built; failed (else the log, with the path) for a load failure, a file it can't read or a program that doesn't build (with the compiler's log).
- `release`: Frees a shader this service loaded (after the pipelines made with it), and stops reloading it.
- `reloaded`: The file behind loaded shaders changed: they're built again in place. One that no longer builds stays as it was, its log traced.

## SpriteEffect

*class* in [`src/helix/graphics/SpriteEffect.hx`](../../src/helix/graphics/SpriteEffect.hx)

A sprite effect: a Shader of kind sprite (its fragment stage including helix_sprite) that sprites draw through (Node2D.effect: a sprite's, a shape's, a text's or a drawing's own drawing; Batch2D.effect; and a Renderer3D's Sprite3D.effect through its shader's sprite3D variant) in place of the framework's sprite programs, with its own parameters and textures set by name (parameters), kept across the shader's reloads. The library's are in helix.shader (SpriteOutline, SpriteFlash, SpriteDissolve, PaletteSwap); an app's own is a .hxshader (Shaders.load) made into one with new. An effect is shared, not a sprite's own: every sprite drawn with it in a frame draws with its parameters as they are when the batch ends, and the sprites drawn with one effect one after another, of one texture, are one draw. A sprite wanting values of its own (its own flash) has an effect of its own, a draw of its own.

```haxe
function new(shader:Shader)
var shader(default, null):Shader
var parameters(default, null):ShaderParameters
function prepare(time:Float):Void
```

- `new`: An effect drawing with shader (kind sprite). Throws for a shader of another kind.
- `shader`: Its shader.
- `parameters`: Its shader's own parameters and textures, set by name. A texture of its own that isn't set is drawn as the sprite's.
- `prepare`: Brings its parameters to time, seconds of the batch's clock (Batch2D.time), just before a batch draws with it (once for each draw): nothing by default; an effect changing over time (SpriteFlash's fade) overrides it.

## VertexAttribute

*typedef* in [`src/helix/graphics/PipelineDesc.hx`](../../src/helix/graphics/PipelineDesc.hx)

A vertex attribute a pipeline reads from one of its buffers: its shader's input slot, its float count (1 to 4) and its byte offset in each record.

- `slot:Int`
- `offset:Int`
- `componentCount:Int`

## VertexBuffer

*typedef* in [`src/helix/graphics/PipelineDesc.hx`](../../src/helix/graphics/PipelineDesc.hx)

A vertex buffer a pipeline reads, by its index in a draw's buffers: its record's bytes, whether a record is an instance's (stepped once an instance) or a vertex's, and the attributes read from it. A buffer with no attributes is a gap the draw skips.

- `stride:Int`
- `instanced:Bool`
- `attributes:Array<VertexAttribute>`
