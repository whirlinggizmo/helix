# Debug

[Back to the library](README.md)

## Debug

*class* in [`engines/raylib/src/helix/raylib/extras/Debug.hx`](../src/helix/raylib/extras/Debug.hx), `import helix.raylib.extras.Debug;`

Provides drawing for looking at what a program does: a model's skeleton as posed, its posed bounds, and the frame's cost. helix-raylib's own. raylib's DrawModelWires, DrawBoundingBox, DrawGrid and DrawFPS draw the rest. Imported apart: `import helix.raylib.extras.Debug.*;`. The example `engines/raylib/examples/extras/debug` uses it.

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

## FrameStats

*class* in [`engines/raylib/src/helix/raylib/extras/FrameStats.hx`](../src/helix/raylib/extras/FrameStats.hx), `import helix.raylib.extras.FrameStats;`

Represents the stats of a run of frames, as `GetFrameStats` and `StopFrameStatsRecording` (`helix.raylib.extras.Debug`) return them.

Each field is 0 for a run of no frames.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?frames:Int, ?fps:Float, ?meanFrameTime:Float, ?p95FrameTime:Float, ?slowestFrameTime:Float, ?drawCalls:Float, ?triangles:Float, ?stateChanges:Float, ?gpuTextureBytes:Float, ?gpuBufferBytes:Float, ?memoryBytes:Float}
```

```haxe
var frames:Int = 0
var fps:Float = 0
var meanFrameTime:Float = 0
var p95FrameTime:Float = 0
var slowestFrameTime:Float = 0
var drawCalls:Float = 0
var triangles:Float = 0
var stateChanges:Float = 0
var gpuTextureBytes:Float = 0
var gpuBufferBytes:Float = 0
var memoryBytes:Float = 0
```

- `frames`: Gets or sets the number of frames counted.
- `fps`: Gets or sets the frames a second: the frames counted over their total time.
- `meanFrameTime`: Gets or sets the frames' mean time, in seconds.
- `p95FrameTime`: Gets or sets the least of the slowest 5% of the frames' times (p95), in seconds.
- `slowestFrameTime`: Gets or sets the slowest frame's time, in seconds.
- `drawCalls`: Gets or sets the draw calls a frame sent the GPU, the mean over the frames.
- `triangles`: Gets or sets the triangles a frame drew, each instance counted, the mean over the frames.
- `stateChanges`: Gets or sets how often a frame's draws switched shader, render state or textures, the mean over the frames.
- `gpuTextureBytes`: Gets or sets the bytes of textures helix-raylib holds on the GPU. Counted as `FrameStatsStyle.gpuTextures` shows them.
- `gpuBufferBytes`: Gets or sets the bytes of buffers helix-raylib holds on the GPU. Counted as `FrameStatsStyle.gpuBuffers` shows them.
- `memoryBytes`: Gets or sets the bytes of memory the program holds.
  Natively, the process's resident memory.

  In a page, the script heap where the browser reports it, and 0 where it doesn't.

## FrameStatsStyle

*class* in [`engines/raylib/src/helix/raylib/extras/FrameStatsStyle.hx`](../src/helix/raylib/extras/FrameStatsStyle.hx), `import helix.raylib.extras.FrameStatsStyle;`

Represents how `DrawFrameStatsEx` (`helix.raylib.extras.Debug`) draws the frame's cost: which stats it shows, and their look.

Every field has a default, so a style sets only what it changes: `{fontSize: 24, triangles: true}`.

Each stat shown is a line of its own.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?fps:Bool, ?frameTime:Bool, ?drawCalls:Bool, ?triangles:Bool, ?stateChanges:Bool, ?gpuTextures:Bool, ?gpuBuffers:Bool, ?memory:Bool, ?targetFps:Int, ?onTargetColor:Color, ?belowTargetColor:Color, ?farBelowTargetColor:Color, ?font:Null<Font>, ?fontSize:Int, ?spacing:Float, ?padding:Int, ?backgroundColor:Color}
```

```haxe
var fps:Bool = true
var frameTime:Bool = true
var drawCalls:Bool = true
var triangles:Bool = false
var stateChanges:Bool = false
var gpuTextures:Bool = false
var gpuBuffers:Bool = false
var memory:Bool = false
var targetFps:Int = 0
var onTargetColor:Color = GREEN
var belowTargetColor:Color = YELLOW
var farBelowTargetColor:Color = RED
var font:Null<Font> = null
var fontSize:Null<Int> = null
var spacing:Float = 1
var padding:Int = 4
var backgroundColor:Color = BLANK
```

- `fps`: Gets or sets a value indicating whether the frames a second show. Defaults to true.
- `frameTime`: Gets or sets a value indicating whether the frame time shows: its mean and its slowest 5% (p95) over the last half second, in milliseconds. Defaults to true.
- `drawCalls`: Gets or sets a value indicating whether the last frame's draw calls show: how many draws it sent the GPU. Defaults to true.
- `triangles`: Gets or sets a value indicating whether the last frame's triangles drawn show. Defaults to false.
- `stateChanges`: Gets or sets a value indicating whether the last frame's state changes show: how often its draws switched shader, render state or textures. Defaults to false.
- `gpuTextures`: Gets or sets a value indicating whether the megabytes of textures helix-raylib holds on the GPU show. Defaults to false.
  Counts textures, cubemaps, render textures with their samples and depth, and the skinning palettes, as the graphics reports them, without the GPU's own padding. The screen's own aren't counted.
- `gpuBuffers`: Gets or sets a value indicating whether the megabytes of buffers helix-raylib holds on the GPU show. Defaults to false.
  Counts meshes' vertices and indices, the frame's batch and its quad indices, and a frame's instances, as the graphics reports them.
- `memory`: Gets or sets a value indicating whether the megabytes of memory the program holds show. Defaults to false.
  Natively, the process's resident memory.

  In a page, the script heap where the browser reports it, and nothing where it doesn't.
- `targetFps`: Gets or sets the frame rate that sets the stats' color, in frames a second. Defaults to 0, for the target `SetTargetFPS` set, or the monitor's refresh rate when none is set.
- `onTargetColor`: Gets or sets the text's color when the frame rate is at or above the target. Defaults to `GREEN`.
- `belowTargetColor`: Gets or sets the text's color when the frame rate is below the target. Defaults to `YELLOW`.
- `farBelowTargetColor`: Gets or sets the text's color when the frame rate is below half the target. Defaults to `RED`.
- `font`: Gets or sets the font. Defaults to null, for raylib's default font.
- `fontSize`: Gets or sets the text's height, in pixels. Defaults to null, which scales the text to the window.
  Null draws at a 36th of the screen's height (20 at 720 lines, as `DrawFPS` draws), so the stats read alike at any window size.

  A size provided is used unchanged. One under 1 is refused.
- `spacing`: Gets or sets the space between letters, in pixels at the font's size, as `DrawTextEx`'s. Defaults to 1.
- `padding`: Gets or sets the space around the text inside its background, in pixels. Defaults to 4.
- `backgroundColor`: Gets or sets the background's color behind the text and its padding. Defaults to `BLANK`, for none.
