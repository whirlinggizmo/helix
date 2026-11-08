# helix-platform: the interfaces

What the platform library is, interface by interface: each interface's members, what they mean, and what each adapter does beneath them.
The interfaces in `libs/platform/src/helix/platform/` are the authority; this is their specification, and an interface changes here first.

## Principles

- **Pumped, never driving.** Nothing in the platform runs the program or calls into it on its own; the one exception is
  `IWindow.onClose`, because a browser gives no frame in which to poll it. Everything that must be serviced once a frame is its own
  small `poll`, named for what it services and doing nothing else: input, http, the file system, each decoder, audio. Each of those
  interfaces extends `IPollable`, the one interface they share, so a program can hold them as one list. The platform never bundles them;
  whoever owns the program does, in its own order (raylib hides the same pumps inside `EndDrawing`).
- **Granular, for whoever builds on it.** The platform keeps the pieces separate (end the frame, read it back, present, poll) and
  leaves their order to the layer above. A smaller surface, like raylib's `EndDrawing` that flushes, captures, swaps, waits and polls in
  one call, is a layer on top.
- **No policy.** No queues, caches, buses, frame order, retries or asset model. The test for a member: would a different engine on the
  same hardware need it to draw, hear or read at all? If not, it isn't here.
- **The raw truth, as plain data.** A GPU program is a `ShaderSource`, a pipeline a `PipelineDesc`, a decoded image bytes and a size, an
  input event its arguments. Handles are `Int`. A completion is a callback per outcome (`decoded` and `failed`, `done` and `failed`),
  never a nullable error or a result to switch on; one of them is called, once, on the main thread, never during the call that took it.
  None is optional, as the platform never logs.
- **Reports, never logs.** A refusal or a failure reaches the caller through the API (a `failed` callback, a state, a result) and the
  caller decides whether it is worth a log line; the platform depends on no logger.
- **Fails before doing anything.** A call that can't be done throws, saying why; one that may be refused returns false or null and its
  doc says when.
- **One interface per thing, one adapter per API.** An adapter's public members are its constructor and its interface's, nothing else; the
  constructor takes nothing, or one `<Adapter>Options` holding the platform's own arguments (a canvas's id, a directory), named at the call:
  `new DomWindowAdapter({canvasId: "canvas"})`. `check_adapters` holds both.
- **One directory per interface, even when one library provides several.** SDL3 provides the window, the events and the system, and a
  page does the same: each still gets its own adapter in `adapters/<interface>/<api>/` (`adapters/window/sdl3/Sdl3WindowAdapter`,
  `adapters/events/sdl3/Sdl3EventsAdapter`), so a program chooses each interface's adapter on its own. What two adapters of one library
  share (the SDL window, the page's canvas, state seen by one and answered by another) lives in `adapters/shared/<api>/`, which both
  reach; no adapter reaches into another's directory, but a device's adapter is given the events adapter it is built over (Events).
- **Interfaces don't know each other.** No interface or its adapters imports another interface's (http never names graphics, the file
  system never names audio); only `adapters/shared/` is common to them. `check_layers` enforces it: an interface's files are its
  interface, the types it reaches and its adapters; anything else may name at most one interface. A shared interface (`IPollable`,
  which every interface extends; `IDecodedImage`, which the image decoder gives and the graphics take) is no interface's and names no
  other type. A device (`IKeyboard`, `IMouse`, `ITouch`, `IGamepads`, `ITilt`) is built
  over the events, and may name theirs.
- **Both targets, one interface.** Every interface has the same members on js and cpp; an adapter is for one API on one target.
- **Units** as CONVENTIONS: seconds, radians, framebuffer pixels for the pointer, logical pixels for the window, `0xAARRGGBB` colors.

## Window

`IWindow`: the drawing surface and the window around it. The graphics adapter is made after the window and draws into its surface
(natively through `surface.h`, which the window's C implements).

- `title`; `width`, `height` (logical pixels) and `framebufferWidth`, `framebufferHeight`, `pixelRatio`; `focused`. In a page the
  window is the canvas's box: its logical size is the canvas's CSS size (the viewport's where the page gives it none), and its drawing
  buffer is that size times 1, or times the device's pixel ratio with `DomWindowAdapterOptions.highDpi`, which `pixelRatio` reports.
- The safe area, `safeAreaX`, `safeAreaY`, `safeAreaWidth`, `safeAreaHeight` (logical pixels in the window): what no notch, rounded
  corner or system bar covers, the whole window where nothing does. Natively SDL's `SDL_GetWindowSafeArea`; in a page the viewport
  less CSS's `env(safe-area-inset-*)`, read through an unseen element's padding. A browser reports the insets only to a page whose
  viewport meta tag has `viewport-fit=cover`, as the libraries' page templates do
  (`<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">`); without it the browser keeps the page
  inside the safe area, and the safe area is the whole viewport. The window tests check it natively (a private display's is the whole
  window) and in Chromium with insets emulated (`tools/page_check.cjs`, a query's `safeArea`).
- `visible`, `requestVisible(visible, ?done, ?failed)`; `requestSize(width, height, ?done, ?failed)`, `canMove`, `x`, `y`,
  `requestPosition(x, y, ?done, ?failed)`; `canFullscreen`, `fullscreen`, `requestFullscreen(enabled, ?done, ?failed)`;
  `orientation`, `requestOrientation(orientation, ?done, ?failed)`.
- `maximized`, `requestMaximized(maximized, ?done, ?failed)`, `minimized`, `requestMinimized(minimized, ?done, ?failed)` (failing
  in a page); `requestFocus(?done, ?failed)` (natively raised, in a page the canvas taking the keyboard); `setIcon(width, height,
  pixels)` (in a page, the page's icon); `opacity`, `requestOpacity(opacity, ?done, ?failed)` (natively the compositor's, in a page
  the canvas's); `requestMinimumSize`, `requestMaximumSize(width, height, ?done, ?failed)` (failing in a page).
- The monitors: `monitorCount`, `monitorIndex`, `requestMonitorIndex(monitorIndex, ?done, ?failed)`, `getMonitorName`,
  `getMonitorX`, `getMonitorY`, `getMonitorWidth`, `getMonitorHeight`, `getMonitorRefreshRate` (0 in a page).
- `readDroppedFile(fileIndex, maxBytes, read(name, bytes), failed(message))`: a file the last `FilesDropped` counted, its name without
  its directory; answered never during the call, as a request is: natively read from its path at the next `IEvents.poll`, in a page
  the File the canvas's drop gave, once the browser has read it.
- `onClose`, a property: the call made once, the last before the window is gone (natively in `close`, in a page at pagehide). Not a
  place to save: a page's write started there isn't kept.
- `close()` natively destroys the window and in a page does nothing (a script can't close its tab); `canClose()` says whether `close`
  removes the window: true natively, false in a page, so a menu asks it before offering Quit.

A request asks; the getter answers on a later frame. Presenting the frame is graphics' (`IGraphics.present`), where every backend
actually swaps; the window only provides the surface.

- Each request answers once, never during the call: `done` once the window reflects it, or `failed` with the reason it wasn't
  done. It returns false, calling neither, only for what its doc names (a size under 1, a monitor that isn't there, fullscreen where
  `canFullscreen` says no).
- Natively the answer comes at a later `IEvents.poll`, as SDL reports the change: the window's event matching the request (resized,
  moved, maximized, minimized, restored, its display changed, focus gained, shown or hidden, fullscreen entered or left), or the
  window already as asked. SDL reports nothing when a window manager ignores a request, so one that hasn't answered within a second
  fails, saying the window manager didn't do it; SDL's own X11 sync waits as long, for a maximize. A request SDL refuses (a position
  where the compositor places windows, an opacity with no compositor) fails with its reason. Opacity and the size limits have no
  event: SDL applies them during the call, and they answer at the next poll.
- In a page, what a page can't do (its window's size, place, maximized, minimized, monitor or size limits) fails at the next
  `IEvents.poll`, saying why; what it can (the canvas shown, hidden, faded or given the keyboard) is done at the next poll. Fullscreen
  and the orientation answer as the browser does.

- Natively, a close asked for by the user or the OS (the close button, the OS quitting the program) is an event, `CloseRequested`,
  delivered by `IEvents.poll` like a key press: it happens once, and the owner decides, closing with `close()` or not (asking "quit
  without saving?" first).
- A page never gets `CloseRequested`: a tab closing or navigating away gives no frame to decide in. Its end is `onClose`, at
  pagehide, the one call the platform makes upward; nothing of the program runs after it, so work started there must not need a later
  frame. A browser drops a write that starts as its page goes (IndexedDB's, in Chromium every time), so a program keeps what it must
  as it changes.
- Quitting is the owner's loop ending, the same on both targets: natively the owner closes the window and ends its loop; in a page a
  program doesn't offer Quit, since `canClose()` is false and a stopped program would leave the page frozen.
- `visible` and `requestVisible` are the program's own choice to show or hide its window (in a page, the canvas). Whether the player
  can see it (not minimized, the tab not in the background) is a different thing, reported only as the `Shown` and `Hidden` events;
  whether it has the keyboard is `focused`. Not spinning while it can't be seen is the owner's loop's, with `IEvents.wait`.

## Events

`IEvents`: the window's events and the player's first press, and the one stream every device adds to. What happens (the window
resized, focused, shown, hidden or closed, its graphics lost, the first press) arrives as events from one `poll`. One stream, because
the OS has one queue: one pump drains it and one consumer walks it, and the order between devices (a key before a click) is kept. The
platform keeps no listeners; a state model (arrays of what's held) or a dispatch model (listeners) is a short walk over what a poll
delivers, built above.

Each device is an interface of its own, built over the events: `IKeyboard`, `IMouse`, `ITouch`, `IGamepads` and `ITilt`. Its adapter is
constructed over the events adapter of its API (`new DomKeyboardAdapter({events: events})`) and adds its events to the same stream,
delivered by the events' `poll`. A device that isn't constructed isn't listened to: a page installs none of its listeners and doesn't
read its gamepads; natively SDL's events for it are turned off, and SDL's gamepads aren't started, so a program links and runs only the
devices it makes. A device's interface may name the events' types and adapters, and nothing else of another interface's.

```haxe
interface IEvents {
	function poll():Void;                         // drains the OS queue into events: this frame's, in order, every device's
	var events(get, never):Array<Event>;          // valid until the next poll; the array is reused
	function wait(timeout:Float):Void;            // sleeps in the OS until an event or timeout seconds; does nothing in a page
	var unlocked(get, never):Bool;                // the player's first press has happened, on every target, with or without devices
	function dispose():Void;                      // after the devices built over it
}

interface IKeyboard {
	var textInput(get, set):Bool;                 // typed text only while on; a phone shows its keyboard then
	function dispose():Void;
}

interface IMouse {                             // a pen counts as the mouse
	var cursorVisible(get, set):Bool;             // hidden either way while locked
	var cursorShape(get, set):CursorShape;        // the system's cursor of each shape
	var locked(get, never):Bool;                  // cursor hidden and held; moves go on from where it was, past the edges
	function requestLock(locked:Bool, ?done:Void->Void, ?failed:String->Void):Bool; // a page: soon after a press, else at the next; Escape lets go
	function canSetPosition():Bool;               // false in a page
	function setPosition(x:Float, y:Float):Bool;  // framebuffer pixels; a MouseMove there at the next poll
	function dispose():Void;
}
interface ITouch { function dispose():Void; }    // a finger is never the mouse

interface IGamepads {
	function isConnected(slot:Int):Bool;          // slots 0..3
	function getName(slot:Int):String;
	function isButtonDown(slot:Int, button:GamepadButton):Bool;   // the W3C standard gamepad's buttons
	function getAxis(slot:Int, axis:GamepadAxis):Float;           // sticks -1..1, down and right positive; triggers 0..1
	function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool; // natively SDL's rumble; a page's vibrationActuator, none in Firefox
	function addMappings(mappings:String):Int;    // SDL's controller database lines; 0 in a page, whose browser maps gamepads
	function dispose():Void;
}

interface ITilt {
	function requestAccess(?done:Void->Void, ?failed:String->Void):Bool;   // device motion, asked of a page's player at a tap
	function releaseAccess():Void;
	function dispose():Void;
}

enum Event {
	KeyDown(key:Key, repeat:Bool);       // IKeyboard; by physical position
	KeyUp(key:Key);
	Text(text:String);                   // while IKeyboard.textInput
	MouseMove(x:Float, y:Float);         // IMouse; framebuffer pixels from the top-left
	MouseDown(button:MouseButton, x:Float, y:Float);
	MouseUp(button:MouseButton, x:Float, y:Float);
	MouseLeave;
	Wheel(dx:Float, dy:Float);
	TouchDown(id:Int, x:Float, y:Float); // ITouch
	TouchMove(id:Int, x:Float, y:Float);
	TouchUp(id:Int, x:Float, y:Float);
	Tilt(beta:Float, gamma:Float, screenAngle:Float);   // ITilt
	TiltState(status:TiltStatus);        // the tilt's status: Off, WaitingForTap, On, Refused, Unavailable, NeedsHttps
	Unlocked;                            // the player's first press (a key or mouse press, or a finger lift), before that event, on every target
	GamepadConnected(slot:Int);              // IGamepads
	GamepadDisconnected(slot:Int);
	GamepadButtonDown(slot:Int, button:GamepadButton);   // a trigger is a button too, down past half way
	GamepadButtonUp(slot:Int, button:GamepadButton);
	Resized(width:Int, height:Int);      // the framebuffer's
	FocusGained;
	FocusLost;                           // each key still down came up just before, a KeyUp each
	Shown;
	Hidden;
	CloseRequested;                      // natively; a page's end is IWindow.onClose
	FilesDropped(count:Int);             // files dropped since the last poll (SDL3's drop events; a page's canvas drop), read by IWindow.readDroppedFile
	GraphicsLost;                        // the GPU's context is gone (a page's WebGL context lost: a GPU reset, an evicted tab)
	GraphicsRestored;                    // it is back, the graphics remade under their handles but textures and static buffers (IGraphics)
}
```

- `poll` is the only pump for input and window state; `IWindow`'s getters and the gamepad reads answer as of it. `events` holds enum
  records in the order the OS gave them, cleared and reused each poll; the owner walks it with a `switch`. In a page the DOM pushes
  events into the adapters' listeners between frames, which only append to that buffer, and the poll then reads the gamepads; natively
  `poll` drains `SDL_PollEvent` into it, and the device adapters only say which of SDL's events are wanted.
- The first press is heard without a keyboard, mouse or touch adapter: in a page a listener on the window, ahead of the page's elements,
  until it comes; natively SDL's key, mouse button and finger-lift events stay on until it comes.
- What the adapters number, they name: `Key` (physical keys), `MouseButton`, `CursorShape` (the system cursors of each kind),
  `GamepadButton` (the W3C standard gamepad's buttons: the face buttons by position, the shoulders, the triggers as 6 and 7, back and start,
  the stick clicks, the d-pad, guide), `GamepadAxis`.
- Gamepad buttons: natively a button pressed and let go between two polls arrives as both events, in order, though its state reads up; a
  page reads its gamepads only at each poll (the Gamepad API has no events), so it sees a press only if the button is down then. Natively
  the Guide button's release arrives no sooner than a quarter second after its press: SDL holds it back that long. A trigger's analog
  value is `getAxis`; its button events come as it crosses half way.
- Focus and visibility are tracked once, by the events adapter: in a page it alone installs the blur, focus and visibility listeners;
  natively it alone sees SDL's focus and window events. They arrive as `FocusGained`, `FocusLost`, `Shown` and `Hidden`, and
  `IWindow.focused` answers from what the last poll saw. `Hidden` fires when the player stops being able to see the window: natively
  minimized or hidden (by the OS or by `requestVisible(false)`), in a page `visibilitychange` to hidden (a background tab, a minimized
  browser, a phone switched away or locked); `Shown` on the reverse. Another window covering it, or losing focus, fires neither.
- Dropped files arrive as one `FilesDropped(count)` a poll, counting every file dropped since the last; `IWindow.readDroppedFile`
  reads each by index until the next. Natively they are SDL3's drop events, a dropped directory skipped; in a page the events adapter
  listens for the canvas's dragover and drop, so the canvas takes a drop rather than the browser opening the file, and keeps the File
  objects of its files, not of directories, for the window adapter (`adapters/shared/dom/DomPage`).
- `requestLock` answers once, never during the call: natively SDL's relative mouse mode is set during the call and answers at the next
  `IEvents.poll`; in a page the browser's pointer lock answers as it changes or is refused, and a lock already as asked answers at the
  next poll.
- `wait` is how a native loop idles while the window can't be seen: the thread sleeps in the OS's event wait (`SDL_WaitEventTimeout`),
  using no CPU, and wakes for an event or at the timeout, so the owner can still pump what must not starve (a music stream, a
  download's completion) at an interval of its choosing: `if (hidden) events.wait(0.25); events.poll(); ...`. In a page the browser
  already withholds frames from a hidden tab.
- No policy: which finger is "the pointer", whether a shortcut swallows text, a stick's dead zone, which gamepad is the player's are above.
  An adapter reports what the platform said and nothing else.

## Graphics

`IGraphics`: resources, passes and one draw. The adapter knows no program or layout of its caller's.

- Textures: `createTexture(width, height, levels, format)`, `createTextureFromImage(image)` (a `IDecodedImage` as it is, one level of
  Rgba8: in a page the browser's bitmap with no premultiplying or color conversion, so its texels are the file's as the native decoder
  reads them) (2D, with its mip levels), `createCubeTexture`, `createDataTexture` (floats read texel by texel),
  `updateTexture(handle, x, y, width, height, data)` (a rectangle of a texture's top level, RGBA8 or half floats, outside a pass, the
  passes before it reading the old texels; a data texture whole, at any time; sokol writes through GL directly, SDL_GPU copies in the
  frame's command buffer, uncycled), `createRenderTarget(width, height, format, depth, msaaSampleCount)` (RGBA8 or half floats, with or
  without depth, and multisampled apart from its depth: 1 for no multisampling, 0 for the screen's count, a count rounded down to the
  nearest the GPU draws the format with, 1, 2, 4 or 8 up to `getMaxRenderTargetMsaaSampleCount(format)` (a GPU need not take every
  one: lavapipe takes 1 and 4), 1 where it can't multisample the format; a multisampled target is resolved into its texture at each
  pass's end, WebGL2 blitting its multisampled renderbuffers, sokol and SDL_GPU through a resolve attachment; SDL_GPU submits the frame's
  passes so far before a pass of fewer samples than one already in its command buffer, as NVIDIA's Vulkan driver loses the device on
  such a pair in one command buffer), `createShadowMap(size, layerCount)` (a depth array read through a comparison sampler, at least 24 layers on every backend), `disposeTexture`; `canSample(format)`
  and `canRender(format)` say what the GPU can.
- Buffers: `createBuffer(capacityBytes)`, `updateBuffer` (replaces a stream buffer's contents for the draws after it) and `appendBuffer`
  (adds bytes after the frame's earlier ones and returns their byte offset, the earlier bytes staying readable, so many draws' vertex data
  can share one stream buffer; a buffer is updated or appended to in a frame, not both; SDL_GPU sets aside the buffer's whole capacity of
  its upload space for the frame at the first append, as sokol and WebGL2 write at the offset in place), `createStaticBuffer(data, bytes, index)`, `disposeBuffer`.
- Programs and pipelines: `createShader(source:ShaderSource)`, `createPipeline(desc:PipelineDesc)` (a program, its buffers' layout,
  primitive (`Primitive`: triangles, lines, or points), indexing, blend, the color channels written, depth test and write, culling and winding, depth-only, the clip flip and the
  place of the uniform it flips, and what attributes no buffer feeds read), each with its `dispose`. A `Blend` is a factor for each side (`BlendFactor`: zero, one, the source's or destination's color or alpha and
  their one-minus forms, the saturated source alpha) and an operation (`BlendOperation`: add, subtract, reverse subtract, min, max), for
  the color and for the alpha apart, as every backend has them; `Blend.OPAQUE`, `ALPHA` (the alpha kept as `a + destination * (1 - a)`)
  and `ADDITIVE` are the common ones. No blend constant: no factor reads one. `colorWrite` (`ColorChannels`, all when omitted) masks the
  channels written; a pass's clear writes every channel.
- Vertex layouts: a pipeline reads at most 8 buffers (`VertexBuffer`: a stride, whether it steps per instance, its attributes) and 16
  attributes across them, each a slot from 0 to 15, a byte offset and a `VertexFormat`: floats (`Float1` to `Float4`), half floats
  (`Half2`, `Half4`), or integers read as normalized floats (`UByte4Norm`, `Byte4Norm`, `UShort2Norm`, `Short2Norm`, `UShort4Norm`,
  `Short4Norm`: unsigned over 255 or 65535, signed over 127 or 32767 with the lowest reading -1 and 0 reading 0). These are the formats
  sokol_gfx, SDL_GPU and WebGL2 all have (and WebGPU), each 4, 8, 12 or 16 bytes: none of 3 bytes or shorts, which only GL has, and no
  integers read unnormalized as floats ("scaled"), which only GL and WebGL2 have. Offsets and strides are multiples of 4, a stride at
  most 255 (WebGL's limit, the platform's on every backend), and each attribute's `bytes` end within its record. A format of fewer
  components than its input reads the rest as 0, 0, 1 as (0, 0, 0, 1) has them; one of more reads the first ones (a `Byte4Norm` normal
  into a `vec3`). A matrix input takes an attribute a column. Every format feeds a float input: `createPipeline` refuses a layout
  feeding an `int`, `uint`, `ivecN` or `uvecN` input (`ShaderSource.attributeTypes`). The rules are one check
  (`adapters/shared/PipelineLayout`) that the WebGL2 and native adapters both call; the native C keeps those guarding its memory.
- Points are one pixel on every backend, the one size each draws alike (Direct3D 12 draws no other; Vulkan's larger points are a device
  feature SDL_GPU doesn't ask for; WebGL2 promises only 1): a `Points` pipeline draws each vertex, or each index, as the pixel its
  position falls in, culling ignored, as a point has no face. Its program must be compiled with `ShaderCompileOptions.points`, which
  writes the size Vulkan and Metal require and GL leaves undefined unwritten (`ShaderSource.points`); a `Points` pipeline over any other
  program is refused. Larger points, sprites and attenuation are a layer's above, drawn as quads.
- Passes: `beginShadowPass(map, layerIndex)`; `beginTargetPass(target, r, g, b, a)`, `resumeTargetPass(target)` (no clear: a target keeps
  what passes leave in it, its samples and depth too, from pass to pass and frame to frame; a new one holds transparent black and the
  farthest depth) and `endTargetPass`; the screen's, `beginFrame(width,
  height, clearColor)` and `endFrame`; within a pass `applyViewport`, `applyScissor`, `resetScissor`.
- `draw(pipeline, buffers, bufferOffsets, indexBuffer, firstElementIndex, elementCount, firstInstanceIndex, instanceCount, textures, samplings, uniforms)`: whole
  primitives (three elements a triangle, two a line, one a point), buffers by the
  pipeline's buffer index, a byte offset into each (null for 0, a multiple of 4, vertex and instanced buffers alike; the elements and
  instances count from it and must end inside the buffer's bytes; an indexed draw has no base vertex, so an offset is how its vertices start
  elsewhere: sokol's `vertex_buffer_offsets`, SDL_GPU's `SDL_GPUBufferBinding.offset`, WebGL2's `vertexAttribPointer` offset), an index buffer for indexed pipelines, a range, instances, textures, samplings and uniform blocks by stage and
  slot (the vertex stage's slot n at n, the fragment stage's at 4 + n, a block both stages read at both). Each block's bytes are std140
  as its `ShaderBlock.members` place them, on every adapter: WebGL2 uploads them into a uniform buffer; sokol's GL sets each member by its
  type at its offset, through the names GL lists as active, as NVIDIA's driver also finds names GL doesn't list (sokol_gfx's own uniform layout computes offsets from a flat list of members, which can't hold a struct's padding,
  and has no `mat2`, `mat3`, `uint` or `bool`); SDL_GPU pushes the bytes whole (its Vulkan driver binds 4 KiB of each block, so a shader there reads no further into one). An attribute the program declares that no buffer feeds
  reads the pipeline's constant for its slot (`PipelineDesc.attributeConstants`), or (0, 0, 0, 1), a slot between fed ones too, so
  every backend takes the same layouts: WebGL2 and sokol set it as the attribute's current value, SDL_GPU reads it from a buffer of
  its own stepped per instance. sokol refuses a layout whose fed attributes leave a gap of slots, and without its validation enables
  none past the gap, so its adapter gives such a slot a stand-in from a fed buffer and unwires it once the pipeline is made. A draw refuses a texture that is the open
  pass's own target (the render target drawn into, the shadow map whose layer is drawn into), as sampling what a pass draws into is
  undefined on GL and an error on Vulkan.
  A `Sampling` is a filter, each axis's wrap, a `MipmapFilter` (None: the top level alone; Nearest: the nearest mipmap; Linear: the two
  nearest blended; it follows the filter when omitted) and an anisotropy of 1 to 16, used with linear filtering and linear mipmaps only
  (sokol takes it so; WebGL2 through EXT_texture_filter_anisotropic where the browser has it), each adapter keeping a sampler a value.
  Mipmaps come with a texture's levels; the platform makes none.
- `readPixels(handle, read(pixels, width, height), failed(message))`: an RGBA8 texture's top level, an RGBA8 render target, or the frame
  just ended (0); `msaaSampleCount` (the screen's), `maxMsaaSampleCount` (the most a window could ask for); `device` (a `GraphicsDevice`: the API, vendor, renderer, version and
  shading language as the API reports them, a page's unmasked through `WEBGL_debug_renderer_info` where the browser gives them); `dispose`.

`endFrame` ends the screen's pass and submits it; `present()` shows the frame and waits for the display's refresh, which paces the
owner's loop. Between the two the frame can still be read back (`readPixels(0)`), and the owner can do work in the time the display
would otherwise be waited for. GL natively swaps through the window's surface (`surface.h`), SDL_GPU presents its swapchain, and in a
page `present` does nothing, since the browser presents when the frame's callback returns. A native window opened without vsync (`Sdl3WindowAdapterOptions.vsync`)
presents at once and waits for nothing, and the frame may tear: GL swaps with interval 0, SDL_GPU presents IMMEDIATE, or MAILBOX where the
window has no IMMEDIATE, or VSYNC where it has neither. A page always waits.

Render targets are stored top row first on every backend: GL's adapters draw into a target flipped, through the uniform a pipeline
names (`PipelineDesc.flip`, `flipBlockSlot` and `flipOffset`): with `ClipScale` every adapter writes the vec4 there, (1, -1, 1, 1) in a GL
target pass and (1, 1, 1, 1) otherwise; with `ViewProjection` GL negates the y row of the matrix there in a target pass; each into its own
copy of the block, the caller's bytes unchanged, and with the winding reversed. A shadow pass is never flipped. A declared texture a draw leaves unbound gets a placeholder, so a shader may
declare more than a draw binds. Adapters: `graphics/webgl2` (`WebGl2GraphicsAdapter`), `graphics/sokol` (`SokolGraphicsAdapter`,
sokol_gfx on GL 4.1), `graphics/sdl3gpu` (`Sdl3GpuGraphicsAdapter`, SDL_GPU on Vulkan, Direct3D 12 or Metal). `libs/platform/tests/graphics`
draws on each and checks the pixels it reads back.

A handle carries its kind (a buffer, a texture of any kind, a program or a pipeline), and a call refuses a handle of another kind as
unknown.

Every adapter holds at least 2047 of each resource kind alive at once (buffers, textures, programs, pipelines, render targets, shadow
maps): the native adapters' tables are that size, the WebGL2 adapter's maps have no bound.

The WebGL2 adapter pays for a draw once. It sets only the GL state that differs from the last draw's; a layout over static buffers is
kept as a vertex array object and bound again when that mesh is drawn; and each draw's uniform blocks go into buffers of their own, taken
in turn over three frames, since a write into a buffer a draw in flight still reads makes the GL driver wait for it (over ANGLE's GL
backend that doubled a frame of 2000 draws, which ANGLE's Vulkan backend never showed, staging the write itself).

## Shader compiler

`helix.platform.tools.ShaderCompiler`: a program on `IGraphics` needs every backend's dialect, and gets them from standard GLSL.

**What a program writes:** one file a stage (`triangle.vert`, `triangle.frag`), both in one of two forms, told apart by `#version`:
Vulkan-style GLSL 450, where attributes may give `layout(location = n)` and blocks and textures `layout(binding = n)`; or GL's,
`#version 300 es` or 330 to 440, where nothing gives a location or a binding (one written is refused, as GLSL ES 3.0 has none). No
annotations. The build macro `ShaderCompiler.compile("triangle.vert", "triangle.frag")`, paths beside the calling file, compiles them
while Haxe builds the program and puts the `ShaderSource` in it as a literal; the program hands it to `IGraphics.createShader`. A third
argument, an object literal of `ShaderCompileOptions` written at the call, sets the rest
(`ShaderCompiler.compile("dots.vert", "dots.frag", {points: true})`): the dialects are the build's (GLSL ES 300 in a page, GLSL 410 and
SDL_GPU's natively), so it doesn't name them, and its include directories are relative to the calling file.
`ShaderCompiler.compileText(vertex, fragment, options)` compiles text a macro or a tool has (`ShaderCompileOptions`: the dialects, include
directories, defines, loose uniforms, gathered blocks, the clip-scale wrap and the point size). `#include` with a quoted name resolves beside the
including file, then in the include directories; the compiler enables `GL_GOOGLE_include_directive` for every stage, so no stage declares
it.

**The chain:** glslang preprocesses each stage (`-E`: includes and defines resolved), a strict text step over that output places what the
source leaves unplaced and gathers loose uniforms, each rewrite on the line it replaces so an error's line is the file's; glslang compiles
the result to SPIR-V (Vulkan 1.0, unoptimized, so nothing declared is trimmed; the drivers optimize) and reflects it (what the code
reads, and each member's GLSL type); SPIRV-Cross emits every dialect (GLSL ES 300 keeping each block a `std140` uniform block, GLSL 410
each block a uniform of its struct type, MSL and HLSL laid out as SDL_GPU binds them, HLSL's inputs named `TEXCOORD` and the location as
SDL_GPU's Direct3D 12 layout names them, a matrix's columns each its own, and SDL_GPU's fragment stage reading every value the vertex
stage writes, the ones its source doesn't read declared unread, as Direct3D links the stages by register in location order) and reflects
the layouts.

**Placement**, where the source gives none: blocks are numbered in each stage, 0 to 3 (as SDL_GPU binds four a stage); named blocks take
the lowest free bindings of their stages in the order declared, the vertex stage's first; a block both stages declare alike (the same
name, binding and members, as an include declares it) is one block at one slot in each (`ShaderBlock.stage` "both"), and two declarations
of one name that differ are refused. Textures are numbered across the program, 0 to 11, at the lowest free in the order declared.
Attributes take the lowest free locations in the order declared, a matrix a location a column; the values passed between the stages are
matched by name. Nothing about placement is the program's to keep: the reflection says where everything is.

**Loose uniforms** (`looseUniforms`): uniforms outside a block, in either form, both stages' gathered into one block, `helix_uniforms`,
read by both, the vertex stage's in declared order then the fragment stage's not already there, at the lowest slot free in both; named
ones go into `gatheredBlocks` of their own after it. A struct a gathered uniform names is copied into a stage that lacks it. One name
of two types, and an initializer (which the compiler would drop), are refused. With `clipScale` the vertex stage is wrapped: its `main`
renamed, a loose `uniform vec4 helix_clipScale`, and a `main` calling it and multiplying `gl_Position` by it, for `ClipFlip.ClipScale`.
With `points` the same wrap writes `gl_PointSize = 1.0` after the program's `main`, whatever the program wrote, and the result says so
(`ShaderSource.points`); SDL_GPU's HLSL is then made with SPIRV-Cross's `--hlsl-enable-compat`, as HLSL has no point size and refuses one
otherwise (Direct3D 12 draws 1 pixel whatever is written).

**What it refuses, saying why:** a uniform block bound past 3 or a texture past 11; two blocks at one binding of a stage, or two
textures at one binding; a sampler array, a separate texture and sampler, an array of arrays, an array inside an array of structs, a
`double`, a storage buffer; a loose uniform without `looseUniforms`; a vertex input array; attribute locations with a gap; and, for
SDL_GPU, a struct laid out so Direct3D's constant buffers can't hold it at its std140 offsets (a vector after a scalar in a struct,
which std140 starts on 16 bytes and Direct3D packs beside it; the vector first, or padding, fixes it). A `mat2`, `mat3` or `mat4` vertex
input takes a location a column, from its own, as GLSL, SPIR-V and every dialect place it: a pipeline feeds its columns as attributes
at consecutive slots (instanced matrices, say), each column a `VertexFormat`, and `ShaderSource.attributes` names it at its first slot, "" at the
rest. Errors name the source file's (or an include's) lines.

**What's reflected is what's declared:** every uniform block and texture the source declares, at its binding and its declared size
(rounded up to whole `vec4`s), whether or not the code reads it, so commenting out a line never changes what the program binds; what
the code reads is marked (`ShaderMember.active`, `ShaderTexture.active`, `ShaderSource.activeAttributes`), per member, not per element.
A block's members are its leaves (`ShaderMember`): a struct's fields by path (`material.roughness`), a field of an array of structs one
member whose elements are the array's (`lights.color`, its stride the struct's size), a member of a block with an instance name under
it (`camera.viewProjection`). Blocks hold `float`, `vecN`, `matN`, `int`, `ivecN`, `uint`, `uvecN`, `bool` and `bvecN` together. The
attributes' types are `ShaderSource.attributeTypes`. A texture's kind comes from its GLSL type (`sampler2D`, `sampler2DArray`,
`samplerCube`, `sampler2DArrayShadow` for a shadow map's comparison); a texture the shader reads only with `texelFetch` is never filtered
(`ShaderTexture.data`), since fetching reads one exact texel. What one stage passes to the next is reflected too: the vertex stage's
outputs and the fragment stage's inputs (`ShaderSource.vertexOutputs`, `fragmentInputs`, each a `ShaderVarying`: its name, type and
location), read from the compiled SPIR-V's interface variables, built-ins left out. A layer above decides from them what a stage
passes, as it decides its blocks from `uniformBlocks`, never by reading the GLSL's text.

**The tools,** pinned in `ShaderTools.hx` and made ready in the user's cache, checked by SHA-256, the first time a shader is compiled:
glslang's official release builds (Linux x86_64, macOS, Windows x64); SPIRV-Cross, which publishes source only, from the builds of the
pinned tag at github.com/whirlinggizmo/helix-tools (Linux x86_64 and ARM64, macOS universal, Windows x86_64), which also builds glslang
for Linux on ARM64. On a system without a build, SPIRV-Cross is built from its source by hxcpp. A shader author needs nothing but Haxe.
`HELIX_GLSLANG` and `HELIX_SPIRV_CROSS` name other builds of the tools.

## Audio

`IAudio`: output only.

- `available` (a device opened), `running` (producing sound now; in a page, after the user's first gesture), `playsUrls` (whether a
  stream can be a URL the platform plays itself).
- `createClip(samples, channelCount)` from float32 PCM at 44100 Hz, mono or stereo interleaved, `disposeClip`; `openStream(source, opened,
  failed)` returning an abort, `getStreamDuration` (seconds, 0 while unknown), `getStreamChannelCount`, `disposeStream`; `createQueue(channelCount, sampleRate)`,
  `queueSamples`, `getQueuedFrameCount` (not yet heard), `disposeQueue`.
- `playClip(clip, loop, volume)`, `playStream(stream, loop, volume)` and `playQueue(queue, volume)` giving a voice; `stop`, `pause`,
  `setVolume`, `setPitch`, `setPan` (equal power for a mono voice, a balance for a stereo one, as Web Audio's `StereoPannerNode`),
  `getPosition` and `setPosition` (seconds; a queue's voice isn't moved), `isPlaying`.
- `poll` (feeds the streams, delivers what the platform's threads finished, and in a page starts waiting voices); `dispose`.

A voice played in a page before audio runs waits, and starts when it does, in the order played: `play` returns its voice at once,
`stop`, `pause` and the setters work on it while it waits, and `isPlaying` is true. Buses' volumes, fades, ducking and what a player
hears are above. Effects on what plays are `IAudioEffects` (below).

A queue plays samples as they are added (raylib's `AudioStream`): back to back while they are added ahead, at the queue's own rate, which
the platform resamples. One that runs dry stays playing, silent, and goes on when fed; it has one voice, and stopping it drops what was
queued. A stream plays its file's channels.

A stream plays a `StreamSource`: `Local(location)` (a path natively, a Blob's URL in a page, as `IFileSystem.locate` gives it),
`Remote(url)` (only where `playsUrls`), or `Downloading(source)`, a `GrowingSource`: the file's room taken at the start, each part
appended as it arrives, `done` or `failure` at the end, written by whoever downloads it and read by the native output.

- **In a page, `audio/webaudio` (`WebAudioAdapter`):** clips are buffer sources, streams an `HTMLAudioElement` (which plays a URL itself,
  so `playsUrls` is true), each voice through a gain and a `StereoPannerNode`, a change approached by `setTargetAtTime`. A clip's
  position is counted from the context's clock; a stream's is the element's `currentTime`, its length the element's `duration`, and it
  moves only within the element's `seekable` ranges. A queue's blocks (one `queueSamples` each) are buffer sources scheduled back to back
  on the context's clock; its queued frames are counted from the scheduled end. Pitch is each source's playback rate, so a pitch change
  reschedules the blocks not yet started and the one playing finishes at its old rate.
- **Natively, `audio/sdl3mixer` (`Sdl3MixerAudioAdapter`):** SDL3_mixer on SDL3's default playback device. A voice is a track; a clip
  is audio loaded from its PCM; pitch is the track's frequency ratio. A stream is decoded by the adapter in `poll`, for up to 2 ms a
  frame and a second ahead, in its file's channels, into an audio stream the track plays, the track told to wait rather than stop when it
  runs dry. A clip's position is its track's; a stream's is counted from what was decoded less what the track hasn't taken, and it is
  moved by SDL3_mixer's own decoder seek (its internal header, as its API seeks only a track that decodes for itself); its length is the
  codec's, a download's once it has all arrived. A queue is an SDL audio stream bound to a track, SDL resampling it and locking it as
  the device's thread reads it. A download
  is copied into C as it arrives and read through an I/O stream whose size is what has arrived; it opens once 16 KiB have arrived,
  again each time that doubles while the codec can't yet, is decoded only while 16 KiB ahead of the decoder's reads (or complete), and
  its voice sounds once a second is decoded (a file's, a tenth). Volume and pan are equal power and ramped across each block, since SDL
  applies a gain at once; a stereo voice's pan is the same balance as a page's. `playsUrls` is false: a remote stream is downloaded above and handed over as `Downloading`. With no
  device, clips are still made, nothing plays, and `available` is false.

`libs/platform/tests/native/native_sdl3mixer_audio.c` renders the native adapter's C with no device (`MIX_CreateMixer`, `MIX_Generate`):
clips, pan, pitch, the ramps, pause, stereo balance, positions read and moved, streams' lengths, streams from a file and from a download
arriving slowly or stopping, looping, queues fed, run dry and fed again, and a render thread racing the main one;
`native_sdl3mixer_device.c` plays silence on the real device (`helix.py test --native --audio-device`). `libs/platform/tests/audio`
(`AudioTests`, run by `tools/platform_checks.py`) checks both adapters against the clock: natively on SDL3's dummy driver, which mixes in
time, and in a headless Chromium let start audio without a gesture: decoded channels, a stereo clip's position advancing and moved, a
stream's length and position, and a queue's frames falling, running dry and resuming.

### Audio effects

`IAudioEffects`: effects on what voices play, and reading what they play, over an `IAudio`. A program constructs it only when it uses
effects (`new WebAudioEffectsAdapter(audio)`, `new Sdl3MixerAudioEffectsAdapter(audio)`), so one that doesn't carries none of it.

- `mix`, the chain everything plays through last; `createChain(?output)`, a chain playing into another or the mix; `disposeChain` (its
  voices and chains to its output); `send(voice, chain)`.
- `addEffect(chain, effect)` at the chain's end, `setEffect` (ramped across the next block), `setBypassed`, `removeEffect`;
  `addAnalyser(chain, frameCount)`, which changes nothing and keeps the latest frames for `getSamples` (stereo, as heard), `getFramesPassed` and
  `getSpectrum` (decibels by band, as Web Audio's `AnalyserNode`).
- `AudioEffect`: `LowPass`, `HighPass`, `BandPass`, `Peaking`, `LowShelf`, `HighShelf`, `Delay`, `Reverb`, `RecordedReverb` (a room's
  impulse response), `Compressor`, `Distortion`, `PitchShift` (the pitch without the speed).
- `poll` (delivers what the audio thread kept); `dispose` (every voice straight to the output again).

Chains form a tree, as engines' buses do (Godot's buses, Unity's mixer groups): services' groups are a chain each when effects are used.
Nothing runs a program's code on the audio thread, which a page can't do.

Both targets compute each effect alike. The filters are the Audio EQ Cookbook's biquads, as Web Audio's `BiquadFilterNode` is, and natively
the same formulas in C. The reverbs are convolutions with a room's impulse response, as Web Audio's `ConvolverNode` is (its normalizing
off): `Reverb`'s response is made from its size and damping by the same Haxe code on both targets, `RecordedReverb`'s is the program's. The
delay, distortion, compressor and pitch shift (a phase vocoder) are the platform's own code: natively C, in a page an
`AudioWorkletProcessor` the adapter loads from its own source, the same algorithm.

- **In a page, `audioeffects/webaudio` (`WebAudioEffectsAdapter`):** a chain is a gain node its voices' panners and its chains connect to,
  through its effects to its output's, the mix's to the destination. The filters are `BiquadFilterNode`s, the reverbs `ConvolverNode`s, the
  platform's own effects one worklet node each, an analyser an `AnalyserNode` per channel (`getFloatTimeDomainData`,
  `getFloatFrequencyData`). Constructing it moves `WebAudioAdapter`'s voices from the destination to the mix.
- **Natively, `audioeffects/sdl3mixer` (`Sdl3MixerAudioEffectsAdapter`):** a chain is a `MIX_Group`. SDL3_mixer's groups don't nest, so each
  group's post-mix callback takes its voices' mix and leaves silence, and the mixer's (`MIX_SetPostMixCallback`), called after every
  group's, runs the tree: each chain's voices and chains summed, through its effects, into its output, the mix's into what is heard. A
  reverb is a partitioned FFT convolution. An analyser copies into a ring buffer there, which `poll` reads; the spectrum is computed on the
  main thread, as Web Audio specifies it. Its C is compiled only when the adapter is.

## Decoders

`IAudioDecoder`: `decode(encoded, sampleRate, decoded(samples, channelCount), failed(message))`, float32 in the file's channels (mono
or stereo interleaved; more mixed down to stereo, by SDL's channel conversion natively and Web Audio's speaker down-mix in a page) at the
rate asked, resampled to it unless it is the file's own; the platform reads no headers, so a layer keeping a file's own rate reads it
first (helix-formats' `AudioHeader.readSampleRate`). A clip plays at 44100 Hz, so a program decoding for `createClip` asks for 44100.
`poll`; `dispose`. It reads **WAV, Ogg Vorbis, MP3 and FLAC**. In a page, `audiodecoder/webaudio` (`WebAudioDecoderAdapter`,
`decodeAudioData` on an `OfflineAudioContext` made at the rate asked, which may read more). Chromium's decoders trim an MP3's LAME delay and padding
(and its Xing or Info frame), and end an Ogg Vorbis stream early: 32 and 81 frames before its last page's position in the two files
measured, where stb_vorbis and Firefox decode to it. Natively, `audiodecoder/sdl3mixer`
(`Sdl3MixerAudioDecoderAdapter`): SDL3_mixer's decoder on a worker thread, its output made at the rate asked (resampled by it), delivered
at `poll`. Its built-in decoders are stb_vorbis 1.22 and dr_mp3 0.7.4, which skips an MP3's Xing or
Info frame and trims its LAME delay and padding.

`IImageDecoder`: `decode(encoded, decoded(pixels, width, height), failed(message))`, the pixels 8-bit RGBA with rows top to bottom, not
premultiplied; `decodeForGpu(encoded, decoded(image), failed(message))`, a `IDecodedImage` for `IGraphics.createTextureFromImage`, so a
program draws a file without holding its pixels (its `width`, `height`, `bitmapHandle`: the browser's `ImageBitmap` in a page by handle,
kept by `adapters/shared/dom/DomImages` for the graphics adapter, and 0 natively, `pixels()` read when wanted after all and kept,
`dispose`); `poll`; `dispose`. It reads **PNG, JPEG, BMP, TGA and GIF** (the
first frame). In a page, `imagedecoder/canvas` (`CanvasImageDecoderAdapter`): `createImageBitmap` with no color conversion or
premultiplying, the bitmap itself for the GPU, and for pixels read back through an `OffscreenCanvas`, which stores pixels premultiplied,
so a partly transparent pixel may come back a level or two from the file's value. Natively, `imagedecoder/stb`
(`StbImageDecoderAdapter`): stb_image 2.30 (`libs/platform/vendor/stb`) on a worker thread, exact, delivered at `poll`; its
`decodeForGpu` is the pixels (`adapters/shared/PixelsImage`).

`IFontRasterizer`: `rasterize(encoded, size, codepoints, rasterized(glyphs, ascent, descent, lineGap), failed(message))` for coverage,
`rasterizeDistanceField` with the same arguments for signed distances, so a program rasterizing coverage carries no distance
transform; `poll`; `dispose`. It reads **TrueType and OpenType** fonts (not a collection's) and gives each codepoint's glyph (`RasterGlyph`): whether the font
has it, its bitmap (8-bit coverage, or signed distances: 4 pixels of padding, 128 on the outline, 64 a pixel), its offset from the pen and
the baseline, and its advance, with the font's ascent, descent and line gap. Sizes and lengths are stb_truetype's: the size is the pixel
height, ascent minus descent. Natively, `fontrasterizer/stb` (`StbFontRasterizerAdapter`): stb_truetype 1.26 (`libs/platform/vendor/stb`) on
a worker thread. In a page, `fontrasterizer/canvas` (`CanvasFontRasterizerAdapter`): the font's tables read as stb_truetype reads them
(which glyphs it has, the metrics, the advances, and a TrueType glyph's box), so glyphs are found, sized and placed the same, and the
glyphs drawn by the browser with `fillText`, whose coverage may differ by a level or so at the edges; a CFF glyph's box is what the canvas
measures, and signed distances come from a distance transform of the glyph drawn 8 times larger, within about a sixteenth of a pixel.

SDL3_mixer 3.2.4 is vendored in `libs/platform/vendor/sdl3_mixer` (its sources, pinned by a tree hash in `dependencies.json` that
`tools/sdl3.py` checks) and compiled with the program by hxcpp, with its built-in decoders only (WAV, stb_vorbis, dr_mp3, dr_flac). A
native program links no audio library but SDL3.

## Http

`IHttp`: `get(url, noCache, headers, head(status, headers), body(part), done(), failed(message), ?idleTimeout)` returning an abort;
`head` once (the status and the headers, names in lower case), `body` for each part as it arrives, then `done` when the body is all here
or `failed` when the transfer failed. An HTTP error status is a response, not a failure. After an abort nothing more is called. `poll`;
`dispose`, which aborts every transfer. Queues, concurrency limits, retries, manifests and caching are above.

A request that receives nothing for its idle timeout fails, on both targets: while it connects, while it waits for the head, or between
parts of the body; one that keeps receiving, however slowly, doesn't. It defaults to 30 seconds, which outlasts a slow mobile network's
connect (a lost SYN is sent again after 1, 3, 7 and 15 seconds) and a busy server's first byte, and fails a stalled download while
someone is still waiting on it. Natively the name's lookup isn't timed: the system's resolver has its own. In a page, a request queued
by the browser behind six others to the same server (HTTP/1.1's limit) isn't timed until its turn.

A body short of its `Content-Length` fails. Natively the adapter reads the response itself, and knows. In a page the browser fails most
of them, but Chromium takes a connection closed partway through the head as a whole head and an empty body, and Firefox a compressed
body cut short as a whole one; so a body that ends is checked against its `Content-Length` by the bytes the request's Resource Timing
entry says arrived, where the page may read it (its own origin, or a server sending `Timing-Allow-Origin`), or else, from the page's own
origin and uncompressed, by the bytes read. A response from another origin without `Timing-Allow-Origin` can't be checked, and calls
`done`: there a short body is caught only above, as helix-services' `ManifestCache` catches a listed file by its hash. A server that
sends `Timing-Allow-Origin` closes the gap. A status below 100, which Chromium makes of a status line cut short, fails without `head`.

A conditional request (`If-None-Match`, `If-Modified-Since`) may be answered 200 with the whole body on any target, as HTTP allows any
server to. In a page, `http/fetchapi` (`FetchApiHttpAdapter`, over `fetch`, the body read as it arrives, aborted through an
`AbortController`) leaves those headers out of a request to another origin, where they would need a CORS preflight the server may
refuse, and has the browser revalidate its own copy instead. Natively, `http/haxehttp` (`HaxeHttpAdapter`, over `sys.Http`, a worker
thread a transfer) sends the headers as given; it fetches http and https URLs only, `noCache` has no cache to bypass, and an abort stops
a transfer at its next part of the body, not while it connects. Its sockets connect without blocking and wait out the idle timeout
themselves, as hxcpp's connect ignores a socket's timeout. Native HTTPS compiles but hasn't been checked against a server.

## File system

`IFileSystem`: files that reside on this machine, under one root given at construction (natively a directory, in a page an IndexedDB
database), read and written whole by path. A path is plain names joined by `/` (`audio/music.ogg`): letters, digits, `_`, `-` and `.`,
at most 256 characters, none empty, `.` or `..`; every adapter checks it, by `FilePath.isValid`, which a layer above may hold its other
sources to as well (helix-services' `Assets` does). A directory is there while a file is under it, as a page's are: there is no call
that makes or deletes one, and no seeking.

- `root`, the root as given; `canWrite`, whether it can be written.
- `read(path, maxBytes, loaded(bytes), missing(), failed(message))`, a file over `maxBytes` failing, returning an abort;
- `write(path, bytes, written(), failed(message))`, replacing what is there, never leaving half a file;
- `deleteFile(path, deleted(), failed(message))`, deleted also when there was none;
- `deleteFiles(deleted(), failed(message))`;
- `getInfo(path, found(size, modified), missing(), failed(message))`: a file's size in bytes and when it was last written, in seconds
  since the Unix epoch (natively its stat; in a page the File it is kept as, a Blob kept before write times were giving 0); a
  directory is missing;
- `list(directory, listed(names), missing(), failed(message))`: a directory's own entries, sorted, its files' names and its
  subdirectories' ending in `/` (`["1.json", "bonus/"]`); "" is the root, which lists nothing before it is written; a path that is a
  file, or nothing, is missing (in a page, the keys under `directory/`);
- `locate(path, located(location, release), missing(), failed(message))`: the file for reading as a stream without reading it whole
  (a path natively, a Blob's URL in a page), held until `release` is called, once;
- `poll`, delivering what finished on the platform's threads; `dispose`.

Natively `filesystem/native` (`NativeFileSystemAdapter({directory: ..., readOnly: ...})`: each operation on a worker thread, each write whole or not
at all; opened read-only over `ISystem.getProgramDirectory()` for the files a program ships with); in a page `filesystem/browser`
(`BrowserFileSystemAdapter({name: ...})`, IndexedDB, each file a File keyed by its path). A file system holds only what is on this machine: fetching from a server is `IHttp`, and
bringing a file in when it isn't there or is out of date is above.

## Clipboard

`IClipboard`: the system's clipboard, its text and an image as PNG. `requestText(read, ?failed)` and `requestImage(read, ?failed)`;
`setText(text, ?done, ?failed)` and `setImage(png, ?done, ?failed)`; `dispose`. Each answers once, never during the call.

- **In a page, `clipboard/dom` (`DomClipboardAdapter`):** the Clipboard API. A read needs the player's permission, which the browser
  may ask for; a write needs the keyboard, soon after a press; a page served without HTTPS (but localhost) has no clipboard. Chromium
  re-encodes an image put on it, so one read back is the same picture in another PNG. A page without a clipboard fails at the next
  `IEvents.poll`.
- **Natively, `clipboard/sdl3` (`Sdl3ClipboardAdapter`):** SDL3's clipboard, made after the window; an image is offered as
  `image/png` and handed over when another program pastes. SDL reads and writes during the call, and the answer comes at the next
  `IEvents.poll`.

## Export

`IExport`: `export(name, mimeType, bytes, exported(where), failed(message))` hands a finished file to the user: in a page a download
(`export/download`, `where` its file name), natively a file in the directory the adapter was made with (`export/filesystem`, `where` its
path, written whole or not at all). A name that isn't a plain file name throws. What is exported, what it's called and which directory it
goes to are the caller's.

## System

`ISystem`: facts about where the program runs, no meaning attached.

```haxe
interface ISystem {
	var company(default, null):String;               // helix-company, or DefaultCompany
	var product(default, null):String;               // helix-product, or the executable's name natively and Game in a page
	var device(get, never):Device;                  // what it runs on: browser, OS, architecture, touch screen, fine pointer
	function getOption(name:String):Null<String>;   // natively --name=value or HELIX_<NAME>; in a page the URL's query parameter
	function getTime():Float;                       // seconds on a monotonic clock: performance.now in a page, SDL's natively
	function getMemoryBytes():Float;                // the process's resident memory natively, the script heap in a page (Chromium), else 0
	function getProgramDirectory():String;    // the files shipped with the program; "./" in a page, a URL
	function getDataDirectory():String;     // where lasting files go; a database's name in a page
	function getCacheDirectory():String;    // where what can be fetched again goes; a database's name in a page
	function openUrl(url:String):Bool;      // http, https or mailto in the system's browser; a page's new tab at a fresh press
}
```

- `getTime` never goes back or jumps when the system's clock is set; a pause in the program (a debugger, a hidden page) is time that
  passed.
- `getMemoryBytes` is a reading for a stats line, not an accounting: natively the process's resident memory (Linux's `/proc/self/statm`,
  macOS's task resident size, Windows' working set), in a page `performance.memory.usedJSHeapSize` where the browser has it (Chromium)
  and 0 where it doesn't. What it counts differs by platform, so readings compare on one platform only.
- `getProgramDirectory` is the executable's directory natively (in a macOS app bundle, its `Contents/Resources`); in a page `"./"`,
  the page's own directory on its server, a URL `IHttp` fetches from.
- `getDataDirectory` is the user's data directory (`$XDG_DATA_HOME` or `~/.local/share` on Linux, `~/Library/Application Support` on
  macOS, `%APPDATA%` on Windows), then `<company>/<product>`, the names the `helix-company` and `helix-product` defines give
  ("DefaultCompany", and the executable's name natively or "Game" in a page, by default; the build fails for one that can't be a
  directory's name); `getCacheDirectory` the cache's (`$XDG_CACHE_HOME` or `~/.cache`,
  `~/Library/Caches`, `%LOCALAPPDATA%\<company>\<product>\cache`). Each comes from its environment variable when that's set (empty
  counts as unset) and from the OS when it isn't (the user database's home directory, Windows' shell folders); a variable set to a path
  that isn't absolute throws, naming it, where XDG would ignore it, since writing elsewhere would hide the mistake. In a page each is the
  name of a database, `<company>/<product>/data` and `/cache`, which a `BrowserFileSystemAdapter` opens. The SDL3 adapter keeps these
  rules itself rather than asking `SDL_GetPrefPath`: SDL has no cache directory, and it makes the directory as a side effect of the
  question.

## Page errors

An uncaught script error or an unhandled rejection in a page is not the platform's: catching it, stopping the frames and telling the
player are the owner's choices. A lost GPU context is the platform's. The owner reads `GraphicsLost` at its next poll. While the context
is lost, the graphics take every call and draw nothing. When the browser gives the context back, the owner reads `GraphicsRestored`.
By then the graphics adapter has remade its programs, pipelines, render targets, shadow maps, data textures and stream buffers under
their old handles, from the descriptions it was given. Textures and static buffers are gone, because it had only their contents: their
owner makes them again from what it keeps (`IGraphics`). The events adapter cancels the loss event so the browser restores the
context, and so does the graphics adapter.

## Not in the platform

What's above it: logging (helix-log, beside the platform); the loop and the frame's order; input state, edges and actions; audio buses
and fades; download queues and limits; caches, manifests and assets; saves; config; a game clock; every renderer and its programs and
pipelines. `adapters/shared/Mailbox` is an implementation helper behind the native adapters' `poll`, not an interface.
