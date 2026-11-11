# helix.raylib.extras

[Back to the library](README.md)

## Debug

*class* in [`engines/raylib/src/helix/raylib/extras/Debug.hx`](../src/helix/raylib/extras/Debug.hx), `import helix.raylib.extras.Debug;`

Provides drawing for looking at what a program does: a model's skeleton as posed, its posed bounds, and the frame's cost. helix-raylib's own. raylib's DrawModelWires, DrawBoundingBox, DrawGrid and DrawFPS draw the rest. Imported apart: `import helix.raylib.extras.Debug.*;`.

### debug: a model's skeleton and bounds as posed, and the frame's cost

```haxe
static function DrawModelSkeleton(model:Model, position:Vector3, scale:Float, color:Color):Void
static function DrawModelBoundingBoxPosed(model:Model, position:Vector3, scale:Float, color:Color):Void
static function DrawFrameStats(posX:Int, posY:Int, fontSize:Int):Void
static function DrawFrameStatsEx(position:Vector2, style:FrameStatsStyle):Void
static function MeasureFrameStats(style:FrameStatsStyle):Vector2
static function GetFrameStats():FrameStats
static function StartFrameStatsRecording():Void
static function StopFrameStatsRecording():FrameStats
```

- `DrawModelSkeleton`: Draws a model's skeleton in the pose it has at the call, placed as DrawModel places the model. See `DrawModelBoundingBoxPosed` for drawing its bounds.
  - `model`: The model.
  - `position`: Where the model is drawn, as DrawModel's.
  - `scale`: Its scale, as DrawModel's.
  - `color`: The lines' color.

  Each bone is a line to its parent, and each joint a small cross.

  A model never posed draws its bind pose. A model without bones draws nothing.

  Draws in 3D mode (BeginMode3D) with depth, as DrawLine3D draws, so the model's surface hides the bones inside it.

  A model drawn as several copies, each posed apart, is posed and drawn copy by copy:

  ```haxe
  for (i in 0...copies) {
  UpdateModelAnimation(model, anim, frame + i * 10);
  var at = new Vector3(i * 2, 0, 0);
  DrawModel(model, at, 1, WHITE);
  DrawModelSkeleton(model, at, 1, YELLOW);
  DrawModelBoundingBoxPosed(model, at, 1, RED);
  }
  ```
- `DrawModelBoundingBoxPosed`: Draws a model's bounds in the pose it has at the call, placed as DrawModel places the model. See `DrawModelSkeleton` for drawing its bones.
  - `model`: The model.
  - `position`: Where the model is drawn, as DrawModel's.
  - `scale`: Its scale, as DrawModel's.
  - `color`: The box's color.

  The box is GetModelBoundingBoxPosed's (helix.raylib.extras.Models).

  Draws in 3D mode, as DrawBoundingBox does.
- `DrawFrameStats`: Draws the frame's cost at a point on the screen in FrameStatsStyle's default look at a size, as DrawFPS draws the rate. See `DrawFrameStatsEx` for choosing the stats and their look.
  - `posX`: The text's left, in pixels.
  - `posY`: The text's top, in pixels.
  - `fontSize`: The text's height, in pixels, as DrawText's; DrawFPS draws at 20.

  Draws a line each for: - the frames a second - the frame time's mean and its slowest 5% (p95) over the last half second, in milliseconds - the last frame's draw calls

  The text's color is judged against SetTargetFPS's target, or the monitor's refresh rate without one.

  The same as `DrawFrameStatsEx(new Vector2(posX, posY), {fontSize: fontSize})`, every other field the style's default.
- `DrawFrameStatsEx`: Draws the frame's cost at a point on the screen in a style's stats, font, size, spacing, colors and background. See `DrawFrameStats` for drawing the default look at a size.
  - `position`: The text's top left, in pixels (its background's, padding around the text).
  - `style`: What to show and how; each field left out takes its default.

  Each stat is a line, so the text's height follows the stats shown. `MeasureFrameStats` returns the size.

  Each number is right-aligned in a slot of a fixed width, so the stats stay in place as the numbers change.

  ```haxe
  DrawFrameStatsEx(new Vector2(10, 10), {fontSize: 24, backgroundColor: Fade(BLACK, 0.5), triangles: true});
  ```
- `MeasureFrameStats`: Returns the size DrawFrameStatsEx draws a style's stats in, for placing them (at a corner, say).
  - `style`: What to show and how.
  - returns: The width and height, in pixels.

  The size includes the padding.

  Sized for the widest values, so it is the same from frame to frame.
- `GetFrameStats`: Returns the stats of the last half second's frames, the half second DrawFrameStats shows the frame time over. See `StartFrameStatsRecording` for recording the frames of the program's choosing.
  - returns: The frames' time, rate, draws and the memory held.

  A frame is counted as its EndDrawing returns, and its time runs from the EndDrawing before it.

  The frames are counted from the first call of GetFrameStats or StartFrameStatsRecording. So the first call returns all zero, and the next ones cover the frames drawn since, up to the last half second.

  Recording the frames doesn't change the last half second's stats.
- `StartFrameStatsRecording`: Starts recording the frames' stats, until `StopFrameStatsRecording`. See `GetFrameStats` for the last half second's.
  The first frame recorded starts at the next EndDrawing, and each frame from there is recorded as its EndDrawing returns.

  A second call starts again, dropping the frames recorded.

  A recording keeps its latest 65536 frames.
- `StopFrameStatsRecording`: Stops recording the frames' stats and returns the stats of the frames recorded since `StartFrameStatsRecording`: those whose EndDrawing returned before this call.
  - returns: The frames' time, rate, draws and the memory held. All zero without a StartFrameStatsRecording, or before a frame is recorded.

  The GPU's and the program's memory are as they are at this call.

## Device

*class* in [`engines/raylib/src/helix/raylib/extras/Device.hx`](../src/helix/raylib/extras/Device.hx), `import helix.raylib.extras.Device;`

Provides what a game needs from the device that raylib 5.5 has no call for, helix-raylib's own: the safe area around a notch, what the device is, whether the window can close or go fullscreen, the screen's orientation, and the device's tilt. Imported apart: `import helix.raylib.extras.Device.*;`.

Each answers on every target. Where a target has no such thing the answer says so (no tilt natively, the whole window as the safe area on a desktop) rather than the call failing to compile. Each `...Async` call answers at a later poll, never during the call. A program that calls none of them links none of them.

```haxe
static inline var ORIENTATION_ANY:Int
static inline var ORIENTATION_LANDSCAPE:Int
static inline var ORIENTATION_PORTRAIT:Int
static inline var TILT_STATUS_OFF:Int
static inline var TILT_STATUS_WAITING_FOR_TAP:Int
static inline var TILT_STATUS_STARTING:Int
static inline var TILT_STATUS_ON:Int
static inline var TILT_STATUS_REFUSED:Int
static inline var TILT_STATUS_UNAVAILABLE:Int
static inline var TILT_STATUS_NEEDS_HTTPS:Int
static function IsPlatformWeb():Bool
```

- `ORIENTATION_ANY`: The screen held as the device is held, or released.
- `ORIENTATION_LANDSCAPE`: The screen held wider than tall.
- `ORIENTATION_PORTRAIT`: The screen held taller than wide.
- `TILT_STATUS_OFF`: The tilt isn't read: it was never asked for (`EnableTiltAsync`), or it was turned off (`DisableTilt`).
- `TILT_STATUS_WAITING_FOR_TAP`: The tilt waits for the next tap, where the system asks for permission.
- `TILT_STATUS_STARTING`: The tilt was asked for (`EnableTiltAsync`), and the first reading is awaited. The first reading turns the tilt on. After a second and a half without a reading, the tilt is unavailable.
- `TILT_STATUS_ON`: The tilt is read.
- `TILT_STATUS_REFUSED`: Permission was refused.
- `TILT_STATUS_UNAVAILABLE`: The device gives no readings: there is no sensor, or none answered.
- `TILT_STATUS_NEEDS_HTTPS`: The program isn't served securely, and the system gives no readings.
- `IsPlatformWeb`: Returns whether the program is built for a browser page rather than natively. See `GetPlatformOS` for naming the operating system.
  - returns: True in a page.

  It is known as the program builds, so the code for the other target drops out of the build, as `#if js` does.

### device: the safe area, the device, the window's abilities, orientation and tilt

```haxe
static function GetWindowSafeArea():Rectangle
static function GetPlatformOS():String
static function IsTouchAvailable():Bool
static function IsFinePointerAvailable():Bool
static function IsWindowCloseable():Bool
static function IsFullscreenAvailable():Bool
static function SetScreenOrientationAsync(orientation:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function GetScreenOrientation():Int
static function EnableTiltAsync(?done:() -> Void, ?failed:String -> Void):Void
static function DisableTilt():Void
static function GetTilt():Vector2
static function SetTiltRange(degrees:Float):Void
static function GetTiltStatus():Int
static function IsTiltCalibrating():Bool
static function IsTiltReady():Bool
static function CalibrateTilt():Void
```

- `GetWindowSafeArea`: Returns the part of the window no notch, rounded corner or system bar covers, in the screen's coordinates as `GetScreenWidth` measures them.
  - returns: The safe area.

  A HUD and buttons go inside it.

  Where nothing covers the window, as on a desktop, it is the whole window.
- `GetPlatformOS`: Returns the operating system's name in lowercase, or "" where the platform names none. See `IsPlatformWeb` for whether the program is built for a page.
  - returns: The system's name.

  The names are "windows", "macos", "linux", "android", "ios" and "chromeos".
- `IsTouchAvailable`: Returns whether the device has touch. A trackpad isn't touch. See `IsFinePointerAvailable` for whether there is a mouse, a trackpad or a pen.
  - returns: True with touch.

  A laptop may have both touch and a mouse.
- `IsFinePointerAvailable`: Returns whether the device has a fine pointer, such as a mouse, a trackpad or a pen. See `IsTouchAvailable` for whether there is touch.
  - returns: True with a fine pointer.

  False on a phone or a tablet alone.
- `IsWindowCloseable`: Returns whether `CloseWindow` removes the window. Where it doesn't, the window stays, cleared, and a game may hide its Quit.
  - returns: True where `CloseWindow` removes the window.
- `IsFullscreenAvailable`: Returns whether the window can go fullscreen. See `ToggleFullscreenAsync` for asking for it.
  - returns: True where `ToggleFullscreenAsync` can be granted.

  False where the system doesn't allow it, as on an iPhone.
- `SetScreenOrientationAsync`: Asynchronously asks for the screen to be held one way up, or released. See `GetScreenOrientation` for reading how it is held.
  - `orientation`: `ORIENTATION_LANDSCAPE`, `ORIENTATION_PORTRAIT`, or `ORIENTATION_ANY` to release a lock.
  - `done`: Optional. Called once the screen is held, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  Refused where the system doesn't hold the screen, as natively and on iOS. Some systems hold it only in fullscreen, so a program asks in `ToggleFullscreenAsync`'s `done`.

  Where the lock is refused, a game shows "turn your device" when the shape is wrong (`GetScreenWidth() < GetScreenHeight()`).

  A value that isn't an `ORIENTATION_` value is refused.
- `GetScreenOrientation`: Returns how the screen is held for the program, as `SetScreenOrientationAsync` asked, or `ORIENTATION_ANY` when it isn't held.
  - returns: `ORIENTATION_ANY`, `ORIENTATION_LANDSCAPE` or `ORIENTATION_PORTRAIT`.

  The screen is let go as the window leaves fullscreen.
- `EnableTiltAsync`: Asynchronously asks for the device's tilt readings, for a game steered by tilting a phone. See `GetTilt` for reading them and `DisableTilt` for stopping them.
  - `done`: Optional. Called once readings arrive, at a later poll.
  - `failed`: Optional. Receives why there will be none: refused, not served securely, or no sensor; when omitted, it is logged.

  Refused where the device has no tilt sensor, as natively.

  The system may ask for permission at the next tap. A game asks before the tap that starts play, and that tap also asks for permission.
- `DisableTilt`: Stops the tilt's readings. See `EnableTiltAsync` for asking for them.
  A permission granted stays granted.
- `GetTilt`: Returns the tilt from level, turned with the screen, each axis -1 to 1. See `CalibrateTilt` for setting what reads as level.
  - returns: The tilt.

  x is across the screen and y is down it.

  A full tilt of 1 is `SetTiltRange`'s angle.

  The tilt is 0 until readings arrive, and while level is being taken (`IsTiltCalibrating`).
- `SetTiltRange`: Sets the angle, in degrees, that reads as a full tilt of 1. It defaults to 30.
  - `degrees`: The angle.
- `GetTiltStatus`: Returns the tilt's status: `TILT_STATUS_OFF`, `TILT_STATUS_WAITING_FOR_TAP`, `TILT_STATUS_STARTING`, `TILT_STATUS_ON`, `TILT_STATUS_REFUSED`, `TILT_STATUS_UNAVAILABLE` or `TILT_STATUS_NEEDS_HTTPS`. A game shows "tap to allow tilt" while the tilt waits for a tap.
  - returns: The status.
- `IsTiltCalibrating`: Returns whether level is being taken: the tilt is on, and reads 0 until the device is held steady for half a second. Level is taken when the readings start, after the screen turns, and after `CalibrateTilt`. A game shows "hold steady" meanwhile.
  - returns: True while level is being taken.
- `IsTiltReady`: Returns whether the tilt steers: the tilt is on (`TILT_STATUS_ON`) and level is taken (`IsTiltCalibrating` is false). A game starts a race, or resumes one, while this is true.
  - returns: True while the tilt steers.
- `CalibrateTilt`: Takes level again: the tilt reads 0 until the device is held steady for half a second, and how the device is held then becomes level (`IsTiltCalibrating`). A game's "Level" button is this call. See `GetTilt` for reading the tilt from level.

## GuiSkins

*class* in [`engines/raylib/src/helix/raylib/extras/GuiSkins.hx`](../src/helix/raylib/extras/GuiSkins.hx), `import helix.raylib.extras.GuiSkins;`

Provides skins for raygui's controls, helix-raylib's own: a part of a control drawn from a texture, stretched as a nine-patch so its corners keep their shape, in place of its style's flat colors. The controls keep raygui's signatures, so a skinned button is still `GuiButton(bounds, text)`, and its text is still drawn in the style's text colors and font. Imported apart: `import helix.raylib.extras.GuiSkins.*;`. The skin's type, `GuiSkin`, is `helix.raylib`'s, with raylib's.

```haxe
// button.png: a cell of 190 x 49 for each state, top down (normal, focused, pressed, disabled), borders of 14.
LoadTextureAsync("assets/button.png", sheet -> GuiSetSkin(BUTTON, GUI_SKIN_BASE, GuiSkinFromSheet(sheet, 190, 49, 14, 14, 14, 14)));
...
if (GuiButton(new Rectangle(20, 20, 190, 49), "Play") != 0) ...
```

The parts each control draws:

| control | `GUI_SKIN_BASE` | `GUI_SKIN_FILL` | `GUI_SKIN_HANDLE` | `GUI_SKIN_ITEM` | |---|---|---|---|---| | `DEFAULT` | `GuiPanel`'s, `GuiWindowBox`'s and `GuiScrollPanel`'s body | | | | | `BUTTON` | `GuiButton`, and `GuiSpinner`'s arrows | | | | | `TOGGLE` | a toggle, each of a toggle group's, a toggle slider's box | a toggle slider's selection | | | | `SLIDER` | the box | `GuiSliderBar`'s bar | `GuiSlider`'s handle | | | `PROGRESSBAR` | the box | the progress | | | | `CHECKBOX` | the box | the check | | | | `COMBOBOX`, `TEXTBOX`, `VALUEBOX`, `STATUSBAR` | the box | | | | | `DROPDOWNBOX` | the box | | | an open list's focused and chosen items | | `LISTVIEW` | the box | | | the focused and active items | | `SCROLLBAR` | the bar and its track | | the thumb | |

A control draws its state's patch: `STATE_FOCUSED` with the pointer over it, `STATE_PRESSED` held down (and a toggle on), `STATE_DISABLED` between `GuiDisable` and `GuiEnable` or under `GuiSetState(STATE_DISABLED)`. A program that sets no skin links none of this.

```haxe
static inline var GUI_SKIN_BASE:Int
static inline var GUI_SKIN_FILL:Int
static inline var GUI_SKIN_HANDLE:Int
static inline var GUI_SKIN_ITEM:Int
```

- `GUI_SKIN_BASE`: A control's box: its border and background. Every control has one.
- `GUI_SKIN_FILL`: The part a control fills to show its value: a slider's or progress bar's bar, a check box's check.
- `GUI_SKIN_HANDLE`: The part a control is dragged by: a slider's handle, a scroll bar's thumb.
- `GUI_SKIN_ITEM`: One item of a list: a list view's row, a drop-down box's choice, a toggle group's toggle.

### gui skins: raygui's controls drawn from textures

```haxe
static function GuiSkinFromTexture(texture:Texture2D, normal:NPatchInfo, ?focused:NPatchInfo, ?pressed:NPatchInfo, ?disabled:NPatchInfo, ?tint:Color):GuiSkin
static function GuiSkinFromSheet(texture:Texture2D, cellWidth:Int, cellHeight:Int, left:Int, top:Int, right:Int, bottom:Int):GuiSkin
static function GuiSetSkin(control:Int, part:Int, skin:Null<GuiSkin>):Void
static function GuiGetSkin(control:Int, part:Int):Null<GuiSkin>
static function GuiClearSkins():Void
```

- `GuiSkinFromTexture`: Returns a skin cut from a texture by one patch for each state. See `GuiSkinFromSheet` for cutting the patches from a sheet of equal cells.
  - `texture`: The texture the patches are cut from.
  - `normal`: The patch drawn in `STATE_NORMAL`.
  - `focused`: Optional. The patch drawn in `STATE_FOCUSED`; `normal` when omitted.
  - `pressed`: Optional. The patch drawn in `STATE_PRESSED`; `focused` when omitted, or `normal` without it.
  - `disabled`: Optional. The patch drawn in `STATE_DISABLED`; `normal` when omitted.
  - `tint`: Optional. The color the patches are multiplied by; `WHITE` when omitted.
  - returns: The skin.
- `GuiSkinFromSheet`: Returns a skin cut from a sheet of a control's states, one cell of one size each. See `GuiSkinFromTexture` for cutting a patch per state from one texture.
  - `texture`: The sheet.
  - `cellWidth`: A cell's width, in texels.
  - `cellHeight`: A cell's height, in texels.
  - `left`: The left border's width, in texels, kept unstretched.
  - `top`: The top border's height.
  - `right`: The right border's width.
  - `bottom`: The bottom border's height.
  - returns: The skin.

  The cells are in raygui's order of states: normal, focused, pressed, disabled.

  They run from the top down, or from the left across when the sheet is less than two cells high.

  A sheet of fewer than four cells leaves the rest to their fallbacks (`GuiSkin`).

  Each cell is cut as a nine-patch by the same borders.
- `GuiSetSkin`: Sets the skin a part of a control is drawn with, in place of its style's border and base colors. See `GuiGetSkin` for reading the skin set, and `GuiClearSkins` for removing every one.
  - `control`: The control: `DEFAULT`, `BUTTON`, `SLIDER` and the rest of raygui's.
  - `part`: `GUI_SKIN_BASE`, `GUI_SKIN_FILL`, `GUI_SKIN_HANDLE` or `GUI_SKIN_ITEM`.
  - `skin`: The skin, or null to draw the part flat in its style's colors again.

  A skin set on `DEFAULT` is set on every control too, as `GuiSetStyle` sets `DEFAULT`'s base properties. Set `DEFAULT`'s first and each control's own after.

  The skin is read as each control draws. A skin set before one call and put back after it changes that call's control alone.

  `GuiPanel`, `GuiWindowBox` and `GuiScrollPanel` draw their body with `DEFAULT`'s own `GUI_SKIN_BASE`.
- `GuiGetSkin`: Returns the skin a part of a control is drawn with, to put back after a change. See `GuiSetSkin` for setting it.
  - `control`: The control.
  - `part`: The part.
  - returns: The skin, or null when the part is drawn flat.
- `GuiClearSkins`: Removes every skin, so every control is drawn flat in its style's colors again. See `GuiSetSkin` with null for removing one.
  Loading a style leaves the skins unchanged.

## Lighting

*class* in [`engines/raylib/src/helix/raylib/extras/Lighting.hx`](../src/helix/raylib/extras/Lighting.hx), `import helix.raylib.extras.Lighting;`

Provides lit shaders, built in, that rlights' lights light (`helix.raylib.Rlights`): `LoadLightingShader`, raylib's lighting examples' `lighting.vs` and `lighting.fs`, which shine every material alike, and `LoadPbrShader`, which draws a glTF's materials as authored, metallic-roughness. Imported apart: `import helix.raylib.extras.Lighting.*;`.

```haxe
var shader = LoadLightingShader();
SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
model.materials[0].shader = shader;
// each frame
SetShaderValue(shader, shader.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
SHADER_UNIFORM_VEC3);
UpdateLightValues(shader, light);
```

A model posed by `UpdateModelAnimation` under either is skinned on the GPU. A program's own shader lights as the lit one does by including `<helix/raylib/shaders/lights.glsl>`: rlights' uniforms and `vec4 helixLight(vec4 texelColor, vec4 tint, vec3 fragPosition, vec3 fragNormal)`, called as `helixLight(texture(texture0, fragTexCoord), colDiffuse*fragColor, fragPosition, fragNormal)`; and as the PBR one does by including `<helix/raylib/shaders/pbr.glsl>`, `vec4 helixPbr(vec4 baseColor, float metallic, float roughness, float occlusion, vec3 emissive, vec3 fragPosition, vec3 normal)`. A program that calls none of this links none of it.

### lighting: the lit and PBR shaders rlights' lights light

```haxe
static function LoadLightingShader():Shader
static function LoadPbrShader():Shader
```

- `LoadLightingShader`: Returns raylib's examples' lighting shader (`lighting.vs` and `lighting.fs`), built in. It shines every material alike, one Phong highlight whatever the material says. See `LoadPbrShader` for drawing a glTF's materials as authored.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as raylib's lighting example does: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from rlights' `CreateLight`. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A program's own shader lights the same way by including `<helix/raylib/shaders/lights.glsl>`.

  ```haxe
  var shader = LoadLightingShader();
  SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
  model.materials[0].shader = shader;
  var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
  ```
- `LoadPbrShader`: Returns helix-raylib's PBR shader, built in: a glTF's materials drawn as authored, metallic-roughness under the same lights as `LoadLightingShader`, which shines every material alike.
  - returns: The shader, the program's until `UnloadShader`.

  Set up as that one: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color; lights come from rlights' `CreateLight`, a light's color what a white surface facing it shows. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. A material marked `unlit` (glTF's `KHR_materials_unlit`) draws its base color and no light.

  Each light also has a range and an intensity, set with `SetShaderValue` at `GetShaderLocation(shader, "lights[0].range")` and `"lights[0].intensity"` (and the next light's at `lights[1]`). A point light with a range dims with distance, fading to nothing at the range, and 0, the default, is no falloff. Intensity is a multiple of the light's color, 1 until set. Light brighter than white rolls off toward white instead of clipping, and colors in the usual range come out as authored.

  Each draw reads the material's maps `MATERIAL_MAP_ALBEDO`, `MATERIAL_MAP_METALNESS`, `MATERIAL_MAP_ROUGHNESS`, `MATERIAL_MAP_NORMAL`, `MATERIAL_MAP_OCCLUSION` and `MATERIAL_MAP_EMISSION`. Their samplers are `albedoMap`, `metalnessMap`, `roughnessMap`, `normalMap`, `occlusionMap` and `emissiveMap`, found at `locs[SHADER_LOC_MAP_ALBEDO]` and the five after it. A missing map reads white, and a missing normal map reads a flat normal.

  Each draw also reads the material's values. `maps[MATERIAL_MAP_ALBEDO].color` times the tint is `colDiffuse`. `maps[MATERIAL_MAP_METALNESS].value` is `metallicValue`, `maps[MATERIAL_MAP_ROUGHNESS].value` is `roughnessValue`, and `maps[MATERIAL_MAP_EMISSION].color` is `emissiveColor`. Colors are taken as linear, as a glTF's factors are. An image's texels are decoded from sRGB. A material from `LoadMaterialDefault` is a smooth non-metal, both values 0, until set.

  A mesh without tangents under a normal map gets them with its first draw (`GenMeshTangents`). A program's own shader draws the same way by including `<helix/raylib/shaders/pbr.glsl>`.

  ```haxe
  var pbr = LoadPbrShader();
  SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.2, 0.2, 0.2, 1.0], SHADER_UNIFORM_VEC4);
  CreateLight(LIGHT_DIRECTIONAL, new Vector3(2, 4, 2), Vector3Zero(), WHITE, pbr);
  for (m in model.materials)
  m.shader = pbr;
  // each frame
  SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
  SHADER_UNIFORM_VEC3);
  ```

## Models

*class* in [`engines/raylib/src/helix/raylib/extras/Models.hx`](../src/helix/raylib/extras/Models.hx), `import helix.raylib.extras.Models;`

Provides what raylib has no call for on models: a model's bounds as posed, which raylib's `GetModelBoundingBox` leaves at the bind pose (`GetModelBoundingBoxPosed`), and models merged into one (`LoadModelFromModels`). Imported apart: `import helix.raylib.extras.Models.*;`.

### models: a skinned model's bounds as posed

```haxe
static function GetModelBoundingBoxPosed(model:Model):BoundingBox
```

- `GetModelBoundingBoxPosed`: Returns a model's bounds as its last `UpdateModelAnimation` (or `UpdateModelAnimationEx`) posed it: `GetModelBoundingBox`'s box, each skinned mesh bounded by its vertices where its bones put them rather than where the skin was bound. A mesh never posed, or without bones, counts as it is, and so does a vertex no bone weights. It is exact whatever shader draws the mesh, as it works the positions out from the pose itself, allocating nothing; that is each skinned vertex moved by its bones, on the CPU, each call. As `GetModelBoundingBox`, its least and most corners are then moved by the model's transform (a turned model's box is not its bounds).
  - `model`: The model.
  - returns: The box.

### models: models merged into one

```haxe
static function LoadModelFromModels(models:Array<Model>, ?skeleton:Model):Null<Model>
```

- `LoadModelFromModels`: Returns a new model with the provided models' meshes merged where possible. The provided models are unchanged. For example, a character's head, body, legs and feet models, whose materials differ only in color, are merged into one character model with one mesh.
  - `models`: The models.
  - `skeleton`: Optional. The model whose bones, bind pose and transform the new model takes. Usually one of the provided models.
  - returns: The new model, or null when refused.

  Meshes whose materials differ only in diffuse color are merged into one mesh. Each material's diffuse color is multiplied into the vertex colors, and the merged mesh has one material, the same material with a white diffuse color. Meshes whose materials differ in anything else (the shader, a texture, `unlit`, or another map's color or value) stay separate meshes.

  A shader that ignores the vertex color draws a merged mesh without the materials' colors.

  A mesh lacking normals, texture coordinates or colors that another merged mesh has gets normals (0, 0, 1), texture coordinates (0, 0) and white colors. Tangents are kept when every merged mesh has them. `texcoords2` is dropped.

  With `skeleton`, the new model has the bones, bind pose and transform of `skeleton`, and an animation that poses `skeleton` poses the new model. Each provided model's bones are matched to the bones of `skeleton` by name. A vertex following a bone that `skeleton` lacks follows the nearest ancestor of that bone that `skeleton` has. A vertex with no such ancestor stays where it is when the new model is posed. A provided model bound in another bind pose is rebound to the bind pose of `skeleton`. A vertex following several bones whose bind poses differ by different amounts is rebound approximately. A provided model without bones is placed where its transform put it.

  Without `skeleton`, the new model has no bones and the identity transform. Each provided model's transform is multiplied into the model's vertices, and a provided model with bones is merged at its bind pose.

  The merged meshes are uploaded. Refused, with the reason logged, for an empty list, for a provided model with bones whose transform differs from the transform of `skeleton`, and for a `skeleton` of more than 256 bones.

## Sprites

*class* in [`engines/raylib/src/helix/raylib/extras/Sprites.hx`](../src/helix/raylib/extras/Sprites.hx), `import helix.raylib.extras.Sprites;`

Provides helix-raylib's instanced texture draw, `DrawTextureInstanced`: many copies of one part of a texture, each placed by a matrix, in one call, as three.js's InstancedMesh, Godot's MultiMesh and Unity's instancing draw many of one thing (docs/DECISIONS.md 47). Imported apart: `import helix.raylib.extras.Sprites.*;`.

```haxe
var copies = [for (i in 0...100) MatrixMultiply(MatrixRotateZ(i * 0.1), MatrixTranslate(i * 8, 100, 0))];
DrawTextureInstanced(texture, new Rectangle(0, 0, 32, 32), copies, WHITE);
```

### sprites: many copies of one part of a texture, each placed by a matrix, in one call

```haxe
static function DrawTextureInstanced(texture:Texture2D, source:Rectangle, transforms:Array<Matrix>, tint:Color):Void
```

- `DrawTextureInstanced`: Draws one part of a texture many times in one call, each copy placed by its own matrix. See `DrawTexturePro` for drawing a single copy.
  - `texture`: The texture.
  - `source`: The part of it, in pixels.
  - `transforms`: Each copy's matrix.
  - `tint`: The tint, every copy's.

  Each copy is what `DrawTexturePro` draws, in the batch's order, so the copies join the frame's sprite run and cost what the same draws would.

  A copy is the part, `source.width` by `source.height` pixels with its top left at the origin, taken through its matrix as `Vector2Transform` applies one. The fields read are `m0`, `m4` and `m12` across, and `m1`, `m5` and `m13` down.

  `MatrixTranslate` places a copy, `MatrixRotateZ` turns it about its top left and `MatrixScale` sizes it. Their products do all three.

  A negative `source.width` or `source.height` flips the part.

  Nothing is drawn when the texture's id, width or height is 0.

## VirtualGamepad

*class* in [`engines/raylib/src/helix/raylib/extras/VirtualGamepad.hx`](../src/helix/raylib/extras/VirtualGamepad.hx), `import helix.raylib.extras.VirtualGamepad;`

Provides on-screen gamepads for phones: sticks and buttons a finger works, read through raylib's gamepad functions. Imported apart, with its constants: `import helix.raylib.extras.VirtualGamepad.*;`.

The first touch anywhere on the screen plugs an enabled virtual gamepad in, and so does the tilt once it's on, for a tilt stick (`VirtualStickOptions.tilt`). A mouse click leaves the virtual gamepad unplugged. Once the virtual gamepad is plugged in, `IsGamepadAvailable` is true for its slot, and its sticks read through `GetGamepadAxisMovement` and its buttons through `IsGamepadButtonDown`, `IsGamepadButtonPressed` and `IsGamepadButtonReleased`. `IsGamepadVirtual` tells a virtual gamepad from a physical one.

A physical gamepad plugged into the virtual gamepad's slot replaces the virtual gamepad. The first physical gamepad plugged in takes slot 0. The next touch after the physical gamepad is unplugged plugs the virtual gamepad in again.

A free finger is a finger that is not currently captured. A stick captures a finger landing in its touch zone, and the buttons a finger landing on one of them. A free finger counts as the mouse, and as a touch point, as every finger does without a virtual gamepad. A captured finger is neither: the touch functions list the free fingers.

The virtual gamepad is drawn at `EndDrawing`, over everything the frame drew. On a device with touch, its buttons and fixed sticks are drawn from the moment it's enabled, and every other stick while it has captured a finger. A program drawing its own controls sets their `visible` to false and draws from `IsVirtualGamepadVisible`, `IsVirtualStickHeld`, `GetVirtualStickBase` and `GetVirtualStickKnob`. The virtual gamepad is hidden while a physical gamepad is in its slot.

```haxe
InitWindow(800, 450, "twin stick");
EnableVirtualGamepad(0);
while (!WindowShouldClose()) {
var moveX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_LEFT_X);
var aimX = GetGamepadAxisMovement(0, GAMEPAD_AXIS_RIGHT_X);
// ...
}
```

```haxe
static inline var VIRTUAL_STICK_BASE_FLOATING:Int
static inline var VIRTUAL_STICK_BASE_FOLLOWING:Int
static inline var VIRTUAL_STICK_BASE_FIXED:Int
static inline var VIRTUAL_STICK_LEFT:Int
static inline var VIRTUAL_STICK_RIGHT:Int
```

- `VIRTUAL_STICK_BASE_FLOATING`: A stick whose base is where the finger lands. The base stays there while the stick is held.
- `VIRTUAL_STICK_BASE_FOLLOWING`: A stick whose base is where the finger lands. The base is pulled along when the finger moves past the radius.
- `VIRTUAL_STICK_BASE_FIXED`: A stick whose base stays at the fixed base position. A finger landing anywhere in the stick's touch zone pushes the stick from the base toward the finger. While no finger holds the stick, the stick is drawn at the base, the knob at rest.
- `VIRTUAL_STICK_LEFT`: The left stick, read as `GAMEPAD_AXIS_LEFT_X` and `GAMEPAD_AXIS_LEFT_Y`.
- `VIRTUAL_STICK_RIGHT`: The right stick, read as `GAMEPAD_AXIS_RIGHT_X` and `GAMEPAD_AXIS_RIGHT_Y`.

### virtual gamepad: on-screen sticks read as a gamepad's

```haxe
static function EnableVirtualGamepad(gamepad:Int, ?options:VirtualGamepadOptions):Void
static function DisableVirtualGamepad(gamepad:Int):Void
static function IsGamepadVirtual(gamepad:Int):Bool
static function IsVirtualGamepadVisible(gamepad:Int):Bool
static function IsVirtualStickHeld(gamepad:Int, stick:Int):Bool
static function GetVirtualStickBase(gamepad:Int, stick:Int):Vector2
static function GetVirtualStickKnob(gamepad:Int, stick:Int):Vector2
```

- `EnableVirtualGamepad`: Enables a virtual gamepad in a slot. The first touch after enabling plugs the virtual gamepad in, and so does the tilt once it's on, for a tilt stick. Enabling it again applies the new options. Its held sticks and buttons, and whether it's plugged in, stay as they were.
  - `gamepad`: The slot, 0 to 3.
  - `options`: Optional. Its sticks, its buttons and their look. Two floating sticks, on the screen's left and right halves, when omitted.

  ```haxe
  EnableVirtualGamepad(0, {
  right: {enabled: false},
  buttons: [{button: GAMEPAD_BUTTON_RIGHT_FACE_DOWN}, {button: GAMEPAD_BUTTON_RIGHT_FACE_RIGHT}]
  });
  ```
- `DisableVirtualGamepad`: Disables the virtual gamepad in a slot, unplugging it. A physical gamepad in that slot is unaffected.
  - `gamepad`: The slot, 0 to 3.
- `IsGamepadVirtual`: Returns whether the gamepad in a slot is a virtual one (`EnableVirtualGamepad`).
  - `gamepad`: The slot, 0 to 3.
  - returns: True while a virtual gamepad is plugged in there. False for a physical one or an empty slot.
- `IsVirtualGamepadVisible`: Returns whether the virtual gamepad in a slot is drawn: enabled, on a device with touch, with no physical gamepad in its slot. A program drawing its own sticks (`visible: false`) draws them while this is true.
  - `gamepad`: The slot, 0 to 3.
  - returns: True while drawn.
- `IsVirtualStickHeld`: Returns whether a finger holds a stick of the virtual gamepad in a slot.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: True while held.
- `GetVirtualStickBase`: Returns where a stick's base is, in the screen's pixels. While the stick isn't held, and for a tilt stick, the base is at the stick's home: the fixed base position, or one and a half radii in from the touch zone's bottom outer corner.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: The base's center. (0, 0) without a virtual gamepad in the slot.
- `GetVirtualStickKnob`: Returns where a stick's knob is, in the screen's pixels: under the finger, held within the radius of the base. A tilt stick's knob is pushed from the base by the tilt, a full tilt at the radius. While a stick read by fingers isn't held, the knob is at the base.
  - `gamepad`: The slot, 0 to 3.
  - `stick`: `VIRTUAL_STICK_LEFT` or `VIRTUAL_STICK_RIGHT`.
  - returns: The knob's center. (0, 0) without a virtual gamepad in the slot.
