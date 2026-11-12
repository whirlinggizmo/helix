# rcore: the window and frame, input, files, cameras and shaders

[Back to the library](README.md)


```haxe
static function InitWindow(width:Int, height:Int, title:String):Void
static function CloseWindow():Void
static function WindowShouldClose():Bool
static function IsWindowReady():Bool
static function IsWindowResized():Bool
static function SetWindowTitle(title:String):Void
static function SetWindowSize(width:Int, height:Int):Void
static function IsWindowFullscreen():Bool
static function IsWindowHidden():Bool
static function IsWindowMinimized():Bool
static function IsWindowMaximized():Bool
static function MaximizeWindow():Void
static function MinimizeWindow():Void
static function RestoreWindow():Void
static function SetWindowFocused():Void
static function SetWindowIcon(image:Image):Void
static function SetWindowIcons(images:Array<Image>, count:Int):Void
static function SetWindowOpacity(opacity:Float):Void
static function SetWindowMinSize(width:Int, height:Int):Void
static function SetWindowMaxSize(width:Int, height:Int):Void
static function GetMonitorRefreshRate(monitor:Int):Int
static function OpenURL(url:String):Void
static function IsWindowFocused():Bool
static function ToggleFullscreen():Void
static function ToggleBorderlessWindowed():Void
static function SetWindowPosition(x:Int, y:Int):Void
static function SetWindowMonitor(monitor:Int):Void
static function GetWindowPosition():Vector2
static function GetWindowScaleDPI():Vector2
static function GetMonitorCount():Int
static function GetCurrentMonitor():Int
static function GetMonitorPosition(monitor:Int):Vector2
static function GetMonitorWidth(monitor:Int):Int
static function GetMonitorHeight(monitor:Int):Int
static function GetMonitorName(monitor:Int):String
static function GetScreenWidth():Int
static function GetScreenHeight():Int
static function GetRenderWidth():Int
static function GetRenderHeight():Int
static function SetConfigFlags(flags:Int):Void
static function SetWindowState(flags:Int):Void
static function ClearWindowState(flags:Int):Void
static function IsWindowState(flag:Int):Bool
static function SetTargetFPS(fps:Int):Void
static function GetFPS():Int
static function GetFrameTime():Float
static function WaitTime(seconds:Float):Void
static function GetTime():Float
static function SetExitKey(key:Int):Void
static function BeginDrawing():Void
static function SwapScreenBuffer():Void
static function PollInputEvents():Void
static function EnableEventWaiting():Void
static function DisableEventWaiting():Void
static function ClearBackground(color:Color):Void
static function GetRandomValue(min:Int, max:Int):Int
static function SetRandomSeed(seed:Int):Void
static function LoadRandomSequence(count:Int, min:Int, max:Int):Null<Array<Int>>
static function UnloadRandomSequence(sequence:Null<Array<Int>>):Void
static function IsKeyPressed(key:Int):Bool
static function IsKeyDown(key:Int):Bool
static function IsKeyReleased(key:Int):Bool
static function IsKeyUp(key:Int):Bool
static function GetKeyPressed():Int
static function IsKeyPressedRepeat(key:Int):Bool
static function GetCharPressed():Int
static function IsMouseButtonPressed(button:Int):Bool
static function IsMouseButtonDown(button:Int):Bool
static function IsMouseButtonReleased(button:Int):Bool
static function IsMouseButtonUp(button:Int):Bool
static function GetMouseX():Int
static function GetMouseY():Int
static function GetMousePosition():Vector2
static function SetMousePosition(x:Int, y:Int):Void
static function SetMouseOffset(offsetX:Int, offsetY:Int):Void
static function SetMouseScale(scaleX:Float, scaleY:Float):Void
static function GetMouseWheelMoveV():Vector2
static function ShowCursor():Void
static function HideCursor():Void
static function IsCursorHidden():Bool
static function EnableCursor():Void
static function DisableCursor():Void
static function IsCursorOnScreen():Bool
static function SetMouseCursor(cursor:Int):Void
static function GetMouseWheelMove():Float
static function GetTouchPointCount():Int
static function GetTouchPosition(index:Int):Vector2
static function GetTouchPointId(index:Int):Int
static function GetTouchX():Int
static function GetTouchY():Int
static function SetGesturesEnabled(flags:Int):Void
static function IsGestureDetected(gesture:Int):Bool
static function GetGestureDetected():Int
static function GetGestureHoldDuration():Float
static function GetGestureDragVector():Vector2
static function GetGestureDragAngle():Float
static function GetGesturePinchVector():Vector2
static function GetGesturePinchAngle():Float
static function SetGamepadVibration(gamepad:Int, leftMotor:Float, rightMotor:Float, duration:Float):Void
static function SetGamepadMappings(mappings:String):Int
static function IsGamepadAvailable(gamepad:Int):Bool
static function GetGamepadName(gamepad:Int):String
static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool
static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool
static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool
static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool
static function GetGamepadButtonPressed():Int
static function GetGamepadAxisCount(gamepad:Int):Int
static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float
static function UnloadFileText(text:Null<String>):Void
static function UnloadFileData(data:Null<haxe.io.Bytes>):Void
static function GetWorkingDirectory():String
static function GetApplicationDirectory():String
static function ChangeDirectory(dir:String):Bool
static function IsFileExtension(fileName:String, ext:String):Bool
static function GetFileExtension(fileName:String):String
static function GetFileName(filePath:String):String
static function GetFileNameWithoutExt(filePath:String):String
static function GetDirectoryPath(filePath:String):String
static function GetPrevDirectoryPath(dirPath:String):String
static function IsFileNameValid(fileName:String):Bool
static function MakeDirectory(dirPath:String):Int
static function UnloadDirectoryFiles(files:FilePathList):Void
static function IsFileDropped():Bool
static function LoadDroppedFiles():FilePathList
static function UnloadDroppedFiles(files:FilePathList):Void
static function CompressData(data:haxe.io.Bytes, dataSize:Int, compDataSize:Array<Int>):haxe.io.Bytes
static function DecompressData(compData:haxe.io.Bytes, compDataSize:Int, dataSize:Array<Int>):haxe.io.Bytes
static function EncodeDataBase64(data:haxe.io.Bytes, dataSize:Int, outputSize:Array<Int>):String
static function DecodeDataBase64(data:haxe.io.Bytes, outputSize:Array<Int>):haxe.io.Bytes
static function ComputeCRC32(data:haxe.io.Bytes, dataSize:Int):Int
static function ComputeMD5(data:haxe.io.Bytes, dataSize:Int):Array<Int>
static function ComputeSHA1(data:haxe.io.Bytes, dataSize:Int):Array<Int>
static function SetLoadFileDataCallback(callback:Null<(fileName:String) -> Null<haxe.io.Bytes>>):Void
static function SetSaveFileDataCallback(callback:Null<(fileName:String, data:haxe.io.Bytes, dataSize:Int) -> Bool>):Void
static function SetLoadFileTextCallback(callback:Null<(fileName:String) -> Null<String>>):Void
static function SetSaveFileTextCallback(callback:Null<(fileName:String, text:String) -> Bool>):Void
static function UnloadAutomationEventList(list:AutomationEventList):Void
static function SetAutomationEventList(list:AutomationEventList):Void
static function SetAutomationEventBaseFrame(frame:Int):Void
static function StartAutomationEventRecording():Void
static function StopAutomationEventRecording():Void
static function PlayAutomationEvent(event:AutomationEvent):Void
static function TraceLog(logLevel:Int, text:String):Void
static function SetTraceLogLevel(logLevel:Int):Void
static function SetTraceLogCallback(callback:Null<(logLevel:Int, text:String) -> Void>):Void
static function BeginMode2D(camera:Camera2D):Void
static function EndMode2D():Void
static function GetCameraMatrix2D(camera:Camera2D):Matrix
static function GetWorldToScreen2D(position:Vector2, camera:Camera2D):Vector2
static function GetScreenToWorld2D(position:Vector2, camera:Camera2D):Vector2
static function BeginMode3D(camera:Camera3D):Void
static function EndMode3D():Void
static function UpdateCamera(camera:Camera3D, mode:Int):Void
static function UpdateCameraPro(camera:Camera, movement:Vector3, rotation:Vector3, zoom:Float):Void
static function GetCameraMatrix(camera:Camera3D):Matrix
static function GetScreenToWorldRay(position:Vector2, camera:Camera3D):Ray
static function GetScreenToWorldRayEx(position:Vector2, camera:Camera3D, width:Int, height:Int):Ray
static function GetMouseRay(position:Vector2, camera:Camera3D):Ray
static function GetWorldToScreen(position:Vector3, camera:Camera3D):Vector2
static function GetWorldToScreenEx(position:Vector3, camera:Camera3D, width:Int, height:Int):Vector2
static function GetMouseDelta():Vector2
static function BeginVrStereoMode(config:VrStereoConfig):Void
static function EndVrStereoMode():Void
static function LoadVrStereoConfig(device:VrDeviceInfo):VrStereoConfig
static function UnloadVrStereoConfig(config:VrStereoConfig):Void
static function IsShaderValid(shader:Shader):Bool
static function UnloadShader(shader:Shader):Void
static function GetShaderLocation(shader:Shader, uniformName:String):Int
static function GetShaderLocationAttrib(shader:Shader, attribName:String):Int
static function SetShaderValue(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int):Void
static function SetShaderValueV(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void
static function SetShaderValueMatrix(shader:Shader, locIndex:Int, mat:Matrix):Void
static function SetShaderValueTexture(shader:Shader, locIndex:Int, texture:Texture2D):Void
static function BeginShaderMode(shader:Shader):Void
static function EndShaderMode():Void
static function BeginBlendMode(mode:Int):Void
static function EndBlendMode():Void
static function BeginScissorMode(x:Int, y:Int, width:Int, height:Int):Void
static function EndScissorMode():Void
static macro function SetClipboardText(text:String):Void
static macro function GetClipboardText():String
static macro function GetClipboardImage():Image
static macro function FileExists(fileName:String):Bool
static macro function LoadFileText(fileName:String):Null<String>
static macro function SaveFileText(fileName:String, text:String):Bool
static macro function LoadFileData(fileName:String):Null<haxe.io.Bytes>
static macro function SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int):Bool
static macro function ExportDataAsCode(data:haxe.io.Bytes, dataSize:Int, fileName:String):Bool
static macro function DirectoryExists(dirPath:String):Bool
static macro function GetFileLength(fileName:String):Int
static macro function IsPathFile(path:String):Bool
static macro function LoadDirectoryFiles(dirPath:String):FilePathList
static macro function LoadDirectoryFilesEx(basePath:String, filter:String, scanSubdirs:Bool):FilePathList
static macro function GetFileModTime(fileName:String):Int
static macro function ExportAutomationEventList(list:AutomationEventList, fileName:String):Bool
static macro function EndDrawing():Void
```

- `InitWindow`: Opens the window and its graphics.
  - `width`: The window's width, in pixels.
  - `height`: The window's height, in pixels.
  - `title`: The window's title.

  Seeds `GetRandomValue` from the time, unless `SetRandomSeed` was called first.
- `CloseWindow`: Closes the window, after keeping what `SaveFileTextAsync` wrote. The program goes on after it: the code after the call runs.
  The window shows nothing after it, and its keys, mouse, touch and gamepads are no longer read.
- `WindowShouldClose`: Returns whether the window should close, after the exit key is pressed or the window is asked to close.
  - returns: True once the window should close.

  The exit key is Escape unless `SetExitKey` changed it.
- `IsWindowReady`: Returns whether the window is open.
  - returns: True after `InitWindow`, until `CloseWindow`.
- `IsWindowResized`: Returns whether the window changed size since the last frame.
  - returns: True for the frame after a resize.
- `SetWindowTitle`: Sets the window's title.
  - `title`: The title.
- `SetWindowSize`: Asks for the window's size, and returns at once. See `SetWindowMinSize` and `SetWindowMaxSize` for limiting how small or large it can be.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.

  The window manager may give another size. `GetScreenWidth` and `GetScreenHeight` report it once it has.

  Refused while the window is fullscreen or maximized, where the system doesn't allow it, and under 1 pixel. A refusal is logged.
- `IsWindowFullscreen`: Returns whether the window is fullscreen, false for a borderless window (`ToggleBorderlessWindowed`).
  - returns: True while it is.
- `IsWindowHidden`: Returns whether the window is hidden (`FLAG_WINDOW_HIDDEN`).
  - returns: True while it is.
- `IsWindowMinimized`: Returns whether the window is minimized.
  - returns: True while it is.
- `IsWindowMaximized`: Returns whether the window is maximized.
  - returns: True while it is.
- `MaximizeWindow`: Asks for the window maximized, and returns at once. See `RestoreWindow` for bringing it back.
  `IsWindowMaximized` reports it once the window is. Refused where the system can't maximize the window. A refusal is logged.
- `MinimizeWindow`: Asks for the window minimized, and returns at once. See `RestoreWindow` for bringing it back.
  `IsWindowMinimized` reports it once the window is. Refused where the system can't minimize the window. A refusal is logged.
- `RestoreWindow`: Asks for the window back to its size from minimized or maximized, and returns at once. See `MaximizeWindow` and `MinimizeWindow` for changing it.
  A minimized window is restored from minimized, any other from maximized. A refusal is logged.
- `SetWindowFocused`: Asks for the window brought to the front with the keyboard, and returns at once.
  `IsWindowFocused` reports it once the window has the keyboard. A window manager may only flash it. A refusal is logged.
- `SetWindowIcon`: Sets the window's icon. See `SetWindowIcons` for giving several sizes.
  - `image`: The icon.

  The image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`. Another format logs a warning and changes nothing.

  An image with no data is ignored.
- `SetWindowIcons`: Sets the window's icon from several sizes, using the largest.
  - `images`: The icons.
  - `count`: How many of them.

  Each image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`. One in another format logs a warning and changes nothing.
- `SetWindowOpacity`: Asks for the window's opacity, and returns at once.
  - `opacity`: From 0 (clear) to 1 (opaque).

  A desktop without a compositor refuses it. A refusal is logged.
- `SetWindowMinSize`: Asks for the smallest size the window may take, and returns at once. See `SetWindowMaxSize` for setting the largest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.

  Refused where the system doesn't allow it, and under 0 pixels. A refusal is logged.
- `SetWindowMaxSize`: Asks for the largest size the window may take, and returns at once. See `SetWindowMinSize` for setting the smallest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.

  Refused where the system doesn't allow it, and under 0 pixels. A refusal is logged.
- `GetMonitorRefreshRate`: Returns how many times a second a monitor shows a new picture.
  - `monitor`: The monitor.
  - returns: The refresh rate in hertz, or 0 when it isn't known.
- `OpenURL`: Opens a URL in the system's browser.
  - `url`: The URL.

  Opens only http, https and mailto URLs.

  A URL with `'` or `"` logs a warning and doesn't open.

  A URL that fails to open logs a warning.
- `IsWindowFocused`: Returns whether the window has the keyboard.
  - returns: True while it has.
- `ToggleFullscreen`: Asks for fullscreen, or for the window back at the size and place it had, and returns at once.
  In a page, the browser grants fullscreen only after a key press, click or tap: asked for outside one, it waits for the next. A refusal is logged.

  `IsWindowFullscreen` reports the new state once the window has changed, not when the call returns.
- `ToggleBorderlessWindowed`: Asks for the window to fill the screen without borders, or back to the window, and returns at once. See `ToggleFullscreen` for fullscreen.
  Called while fullscreen, it only switches to borderless. In a page, the browser grants it only after a key press, click or tap: asked for outside one, it waits for the next. A refusal is logged.

  As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it is, and `IsWindowFullscreen` false.
- `SetWindowPosition`: Asks for the window's place on the desktop, and returns at once. See `SetWindowMonitor` for moving it to another monitor.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.

  `GetWindowPosition` reports it once the window has moved. Refused while the window is fullscreen or maximized, and where the system doesn't allow it, as Wayland doesn't. A refusal is logged.
- `SetWindowMonitor`: Asks for the window on another monitor, and returns at once. See `SetWindowPosition` for placing it on the desktop.
  - `monitor`: The monitor, 0 to `GetMonitorCount() - 1`.

  `GetCurrentMonitor` reports it once the window is there. Where the window can't be moved, a monitor other than its own is refused. A refusal is logged.
- `GetWindowPosition`: Returns the window's place on the desktop.
  - returns: Its left and top edges, in pixels.
- `GetWindowScaleDPI`: Returns how many of the display's pixels a pixel drawn takes, across and down, 2 on most phones and high-density displays.
  - returns: The scale.
- `GetMonitorCount`: Returns the number of monitors.
  - returns: The count, at least 1.
- `GetCurrentMonitor`: Returns the monitor holding the window.
  - returns: Its index.
- `GetMonitorPosition`: Returns a monitor's top-left corner on the desktop.
  - `monitor`: The monitor.
  - returns: The corner, in pixels.
- `GetMonitorWidth`: Returns a monitor's width.
  - `monitor`: The monitor.
  - returns: The width, in pixels.
- `GetMonitorHeight`: Returns a monitor's height.
  - `monitor`: The monitor.
  - returns: The height, in pixels.
- `GetMonitorName`: Returns a monitor's name.
  - `monitor`: The monitor.
  - returns: The name.
- `GetScreenWidth`: Returns the screen's width, in the pixels drawing is in. See `GetRenderWidth` for reading the framebuffer's width.
  - returns: The width.
- `GetScreenHeight`: Returns the screen's height, in the pixels drawing is in. See `GetRenderHeight` for reading the framebuffer's height.
  - returns: The height.
- `GetRenderWidth`: Returns the framebuffer's width, in the display's pixels. See `GetScreenWidth` for reading the width drawing is in.
  - returns: The width.
- `GetRenderHeight`: Returns the framebuffer's height, in the display's pixels. See `GetScreenHeight` for reading the height drawing is in.
  - returns: The height.
- `SetConfigFlags`: Sets flags for the window before `InitWindow` (`FLAG_*`).
  - `flags`: The flags, or'd together.

  `FLAG_MSAA_4X_HINT` asks for 4 samples a pixel.

  `FLAG_VSYNC_HINT` shows frames at the display's refresh. Without it, frames show as soon as they are drawn.

  The window is resizable whatever the flags.
- `SetWindowState`: Sets flags on the open window (`FLAG_*`).
  - `flags`: The flags, or'd together.

  Changes nothing on the window itself, which stays resizable. `IsWindowState` reads the flags back.
- `ClearWindowState`: Clears flags on the open window (`FLAG_*`).
  - `flags`: The flags, or'd together.
- `IsWindowState`: Returns whether flags are set on the window.
  - `flag`: The flags, or'd together.
  - returns: True when all of them are.

  `FLAG_FULLSCREEN_MODE` and `FLAG_BORDERLESS_WINDOWED_MODE` read what the window is now, as `IsWindowFullscreen` does.
- `SetTargetFPS`: Sets the most frames a second, for `EndDrawing` to wait out the rest of each frame.
  - `fps`: The frames a second, or 0 for no limit.
- `GetFPS`: Returns the frames a second, averaged over the last half second or so.
  - returns: The frames a second.
- `GetFrameTime`: Returns the seconds the last frame took.
  - returns: The seconds.
- `WaitTime`: Stops the program for a time, drawing nothing and reading no input until it ends.
  - `seconds`: How long.
- `GetTime`: Returns the seconds since `InitWindow`.
  - returns: The seconds.
- `SetExitKey`: Sets the key that closes the window, or `KEY_NULL` for none.
  - `key`: The key.

  Escape until set.
- `BeginDrawing`: Begins a frame's drawing.
- `SwapScreenBuffer`: Shows the frame `EndDrawing` ended, for a program built with `-D helix-raylib-custom-frame-control`.
  Does nothing without the define, as `EndDrawing` has shown the frame already.

  A frame not shown by the next `EndDrawing` is shown then.
- `PollInputEvents`: Reads the input that came since the last read: each key's, button's and finger's state, and the window's events.
  `EndDrawing` reads the input already, unless the program is built with `-D helix-raylib-custom-frame-control`.

  A second read starts a new frame of input, so a key pressed before it reads as held.

  With `EnableEventWaiting`, waits for an event first.
- `EnableEventWaiting`: Makes each frame wait for an event before the next is read. See `DisableEventWaiting` for going back to reading the events there are.
  An event is a key, a mouse button, the mouse moving or the window changing, from a device the program reads.

  The program draws nothing while waiting, and uses little time.

  The platform and helix-raylib's async loads are still served, so a load answers while waiting and is drawn after the next event.
- `DisableEventWaiting`: Makes each frame read the events there are and go on, the default until `EnableEventWaiting`.
- `ClearBackground`: Clears the frame to a color, dropping what was drawn before it.
  - `color`: The color.
- `GetRandomValue`: Returns a random whole number from min to max, both included, from raylib's generator. See `LoadRandomSequence` for drawing several numbers with none twice.
  - `min`: The least.
  - `max`: The most.
  - returns: The number.

  The generator is xoshiro128** (helix-math's `Random`), so a seed gives the numbers raylib's gives.

  min and max are swapped when min is more.
- `SetRandomSeed`: Seeds `GetRandomValue` and `LoadRandomSequence`.
  - `seed`: The seed, read as unsigned.

  The numbers repeat from the same seed, and are the ones raylib's give.

  Until called, `InitWindow` seeds from the time.
- `LoadRandomSequence`: Returns numbers from min to max, both included, none twice, from `GetRandomValue`'s generator.
  - `count`: How many.
  - `min`: The least.
  - `max`: The most.
  - returns: The numbers, or null when there are fewer than count in the range.

  A seed gives the numbers raylib's gives.

  min and max aren't swapped. When min is more, the numbers run from min up by the range's size.
- `UnloadRandomSequence`: Frees numbers `LoadRandomSequence` gave.
  - `sequence`: The numbers.

  Has nothing to free.
- `IsKeyPressed`: Returns whether a key went down this frame.
  - `key`: The key (`KEY_*`).
  - returns: True for that frame alone.
- `IsKeyDown`: Returns whether a key is held.
  - `key`: The key (`KEY_*`).
  - returns: True while it is down.
- `IsKeyReleased`: Returns whether a key went up this frame.
  - `key`: The key (`KEY_*`).
  - returns: True for that frame alone.
- `IsKeyUp`: Returns whether a key isn't held.
  - `key`: The key (`KEY_*`).
  - returns: True while it is up.
- `GetKeyPressed`: Returns the next key pressed this frame, each key once. See `GetCharPressed` for reading typed text.
  - returns: The key (`KEY_*`), or `KEY_NULL` when no more were pressed.

  A loop calling it until it returns `KEY_NULL` reads every key pressed.
- `IsKeyPressedRepeat`: Returns whether the system repeated a held key this frame.
  - `key`: The key (`KEY_*`).
  - returns: True for the frames it repeated.

  The system starts repeating a key after a moment, at its own rate.
- `GetCharPressed`: Returns the next character typed this frame, each once. See `GetKeyPressed` for reading keys.
  - returns: The character's codepoint, or 0 when no more were typed.

  A loop calling it until it returns 0 reads every character typed.

  Typed text is read from the first call on, so a phone's keyboard shows from then.
- `IsMouseButtonPressed`: Returns whether a mouse button went down this frame.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True for that frame alone.

  A free finger (`EnableVirtualGamepad`) touching counts as the left button.
- `IsMouseButtonDown`: Returns whether a mouse button is held.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True while it is down.

  A finger down counts as the left button.
- `IsMouseButtonReleased`: Returns whether a mouse button went up this frame.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True for that frame alone.

  The last finger lifting counts as the left button.
- `IsMouseButtonUp`: Returns whether a mouse button isn't held.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True while it is up.
- `GetMouseX`: Returns the mouse's x, in the screen's pixels, the first finger's while one is down.
  - returns: The x.
- `GetMouseY`: Returns the mouse's y, in the screen's pixels, the first finger's while one is down.
  - returns: The y.
- `GetMousePosition`: Returns the mouse's position, in the screen's pixels, the first finger's while one is down.
  - returns: The position.

  `SetMouseOffset`'s offset is added first, then `SetMouseScale`'s scale applied.
- `SetMousePosition`: Moves the mouse to a place on the screen.
  - `x`: The place across, in the screen's pixels.
  - `y`: The place down.

  `GetMouseDelta` this frame includes the move.

  Where the system refuses, as Wayland does, the cursor stays. The position reads the place given until the mouse moves, and a warning says why, once a run for each reason.
- `SetMouseOffset`: Sets what `GetMousePosition` adds to the mouse's position, before its scale.
  - `offsetX`: Added across.
  - `offsetY`: Added down.
- `SetMouseScale`: Sets what `GetMousePosition` multiplies the mouse's position by, after its offset.
  - `scaleX`: The scale across.
  - `scaleY`: The scale down.
- `GetMouseWheelMoveV`: Returns how far the wheel turned this frame, in both directions, right and forward positive. See `GetMouseWheelMove` for reading the larger direction alone.
  - returns: The notches.
- `ShowCursor`: Shows the cursor.
- `HideCursor`: Hides the cursor over the window.
- `IsCursorHidden`: Returns whether the cursor is hidden, by `HideCursor` or `DisableCursor`.
  - returns: True while it is.
- `EnableCursor`: Lets go of the mouse that `DisableCursor` locked and shows the cursor, and returns at once.
  `IsCursorHidden` is false from the call.
- `DisableCursor`: Locks the mouse to the window and hides the cursor, for looking around, and returns at once. See `EnableCursor` for letting it go.
  `GetMouseDelta` keeps coming while the position goes on past the window's edges. `IsCursorHidden` is true from the call.

  In a page, the browser grants the lock only after a click or key press: asked for outside one, it waits for the next. A refusal is logged.
- `IsCursorOnScreen`: Returns whether the mouse is over the window.
  - returns: True from its first move over the window until it leaves.
- `SetMouseCursor`: Sets the cursor's shape, the system's own cursor of each kind.
  - `cursor`: The shape (`MOUSE_CURSOR_*`). `MOUSE_CURSOR_DEFAULT` and `MOUSE_CURSOR_ARROW` are both the arrow.
- `GetMouseWheelMove`: Returns how far the wheel turned this frame, the larger of its two directions, forward positive. See `GetMouseWheelMoveV` for reading both directions.
  - returns: The notches.
- `GetTouchPointCount`: Returns the number of fingers down, leaving out those a virtual gamepad (`EnableVirtualGamepad`) captured.
  - returns: The count.
- `GetTouchPosition`: Returns a finger's position, in the screen's pixels.
  - `index`: Which finger, 0 for the first down.
  - returns: The position, or (0, 0) when fewer are down.

  While no finger is down, the first is where the mouse is. See `EnableVirtualGamepad` (`import helix.raylib.extras.VirtualGamepad.*;`) for on-screen sticks read as a gamepad's.
- `GetTouchPointId`: Returns a finger's id, which stays the same while it is down.
  - `index`: Which finger, 0 for the first down.
  - returns: The id, or -1 when fewer are down.
- `GetTouchX`: Returns the first finger's x, in the screen's pixels, the mouse's while no finger is down.
  - returns: The x.
- `GetTouchY`: Returns the first finger's y, in the screen's pixels, the mouse's while no finger is down.
  - returns: The y.
- `SetGesturesEnabled`: Sets which gestures are detected.
  - `flags`: The gestures (`GESTURE_*`), or'd together.

  All gestures until called.
- `IsGestureDetected`: Returns whether a gesture is the one detected now.
  - `gesture`: The gesture (`GESTURE_*`).
  - returns: True while it is the gesture, and enabled.

  A mouse button counts as a finger.

  A tap or double tap lasts a frame, then becomes a hold. A swipe lasts a frame.
- `GetGestureDetected`: Returns the gesture detected now.
  - returns: The gesture (`GESTURE_*`), or `GESTURE_NONE` when it isn't enabled.
- `GetGestureHoldDuration`: Returns how long the hold has lasted.
  - returns: The seconds, or 0 when the gesture isn't `GESTURE_HOLD`.
- `GetGestureDragVector`: Returns the drag, from where the finger landed to where it is, in fractions of the screen.
  - returns: The vector.
- `GetGestureDragAngle`: Returns the last swipe's angle.
  - returns: The degrees, counterclockwise from right.
- `GetGesturePinchVector`: Returns the pinch, from the first finger to the second, in fractions of the screen.
  - returns: The vector.
- `GetGesturePinchAngle`: Returns the pinch's angle.
  - returns: The degrees, counterclockwise from right.
- `SetGamepadVibration`: Shakes a gamepad, its left motor the heavy one and its right the light one.
  - `gamepad`: The gamepad, 0 to 3.
  - `leftMotor`: The heavy motor's strength, 0 to 1.
  - `rightMotor`: The light motor's strength, 0 to 1.
  - `duration`: How long, in seconds.

  Shaking lasts at most 2 seconds.

  An empty slot is passed over.

  A gamepad that can't shake stays still and logs a warning, once a run.
- `SetGamepadMappings`: Adds mappings for gamepads the system doesn't know, in SDL's controller database format.
  - `mappings`: The mappings, one a line.
  - returns: How many were added or updated, or 0 where the system maps gamepads itself.
- `IsGamepadAvailable`: Returns whether a gamepad is connected.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: True while one is connected there.

  A virtual gamepad (`EnableVirtualGamepad`) counts. `IsGamepadVirtual` tells it from a physical one.
- `GetGamepadName`: Returns a gamepad's name.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: Its name, or "" when none is connected.
- `IsGamepadButtonPressed`: Returns whether a gamepad's button went down this frame. A virtual gamepad's buttons (`EnableVirtualGamepad`) count.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True for that frame alone.
- `IsGamepadButtonDown`: Returns whether a gamepad's button is held. A virtual gamepad's buttons (`EnableVirtualGamepad`) count.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True while it is down.
- `IsGamepadButtonReleased`: Returns whether a gamepad's button went up this frame. A virtual gamepad's buttons (`EnableVirtualGamepad`) count.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True for that frame alone.
- `IsGamepadButtonUp`: Returns whether a gamepad's button isn't held.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True while it is up.
- `GetGamepadButtonPressed`: Returns the last button held, polling the buttons as raylib does.
  - returns: The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held.

  The poll runs over gamepads 0 to 3, each's buttons in the platform's order.
- `GetGamepadAxisCount`: Returns the number of axes a gamepad has.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: 6 while one is connected, else 0.
- `GetGamepadAxisMovement`: Returns how far a gamepad's axis is pushed.
  - `gamepad`: The gamepad, 0 to 3.
  - `axis`: The axis (`GAMEPAD_AXIS_*`).
  - returns: The value.

  A physical gamepad's axis reads raw. A virtual gamepad's sticks (`EnableVirtualGamepad`) read past their dead zone.

  A stick runs from -1 to 1, down and right positive.

  A trigger runs from -1 released to 1 pulled.
- `UnloadFileText`: Frees text `LoadFileText` or `LoadFileTextAsync` gave.
  - `text`: The text.

  Has nothing to free.
- `UnloadFileData`: Frees bytes `LoadFileData` or `LoadFileDataAsync` gave.
  - `data`: The bytes.

  Has nothing to free.
- `GetWorkingDirectory`: Returns the working directory. See `GetApplicationDirectory` for finding the program's files.
  - returns: The directory, without a slash at its end.

  `TakeScreenshotAsync` writes to it.

  helix-raylib's loads don't read from it. A file's name is under the program's files wherever the working directory is.
- `GetApplicationDirectory`: Returns the directory the program's files are read from.
  - returns: The directory, with a slash at its end.

  A load given a path in it reads the file the path names, so `GetApplicationDirectory() + "resources/a.png"` loads "resources/a.png".
- `ChangeDirectory`: Changes the working directory.
  - `dir`: The directory.
  - returns: True when the working directory is it now.

  `TakeScreenshotAsync` writes to the new directory from then on.

  helix-raylib's loads are unchanged, reading the program's files wherever the working directory is.

  A failure logs a warning.
- `IsFileExtension`: Returns whether a file name ends in one of some extensions, ignoring the case of A to Z.
  - `fileName`: The file name.
  - `ext`: The extensions, `;` between them: ".png;.jpg".
  - returns: True when its extension, from its last dot, is one of them.

  Up to 15 characters of the file's extension are compared, and the list's first 32 extensions.

  An extension in the list without its dot matches as well ("png" as ".png").
- `GetFileExtension`: Returns a file name's extension, from its last dot: "file.tar.gz" gives ".gz".
  - `fileName`: The file name, or a path.
  - returns: The extension with its dot, or null when there is no dot or the name starts with its only one.
- `GetFileName`: Returns a path's file name, what follows its last `/` or `\`.
  - `filePath`: The path.
  - returns: The file name with its extension, or the path itself when it has no slash.
- `GetFileNameWithoutExt`: Returns a path's file name without its extension, up to its last dot unless that dot is its first character.
  - `filePath`: The path.
  - returns: The file name, or "" for null.
- `GetDirectoryPath`: Returns the directory of a path, up to its last `/` or `\`.
  - `filePath`: The path.
  - returns: The directory, without a slash at its end.

  A relative path's directory starts "./": "dir/file.png" gives "./dir", "file.png" gives "./", and "/file.png" gives "/".
- `GetPrevDirectoryPath`: Returns the directory a path is in, up to its last `/` or `\` but one at its end, keeping a root's ("/", "C:\").
  - `dirPath`: The path.
  - returns: The directory above it, or "" when there is none.

  "/a/b/" gives "/a", "/a" gives "/" and "abc" gives "".

  Every path is taken as a directory's, so a path naming a file gives the file's directory.
- `IsFileNameValid`: Returns whether a file name could name a file on any system: none of `< > : " / \ | ? *` or a control character, and not only dots.
  - `fileName`: The file name, without a directory.
  - returns: True when it could, and true for null or "".
- `MakeDirectory`: Makes a directory, succeeding for any path that could name one.
  - `dirPath`: The directory.
  - returns: 0 for success, 1 for null or "", and -1 for a path that can't name a directory.

  Nothing is made, as a directory is there once a file is written under it.
- `UnloadDirectoryFiles`: Frees a listing `LoadDirectoryFilesAsync` or `LoadDirectoryFilesExAsync` gave.
  - `files`: The listing.

  Has nothing to free, and the list is unchanged.
- `IsFileDropped`: Returns whether files were dropped on the window. See `LoadDroppedFiles` for reading their paths.
  - returns: True while dropped files are held.

  Stays true until `UnloadDroppedFiles`.

  A new drop's files replace the last one's.

  A dropped file counts once its bytes are read, a frame or so after the drop.
- `LoadDroppedFiles`: Returns the paths of the files last dropped.
  - returns: The paths, `count` of them, with `capacity` 0.

  Each path is helix-raylib's own, `helix-raylib-dropped/<n>/<name>`, which every load reads, as `LoadTextureAsync(path)` does.

  The file's name is the path's last part, with `_` for a character a path can't hold.

  A directory dropped isn't listed.
- `UnloadDroppedFiles`: Lets go of the list of files last dropped, so `IsFileDropped` is false until the next drop.
  - `files`: The list `LoadDroppedFiles` gave. A list of no files changes nothing.

  The files stay. A load of one of their paths, started before or after, reads the file until the next drop's files replace them.
- `CompressData`: Compresses bytes as raylib's `CompressData` does, byte for byte, raw DEFLATE with no zlib header at sdefl's level 8. See `DecompressData` for reading them back.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `compDataSize`: Its first element is set to the compressed size.
  - returns: The compressed bytes.
- `DecompressData`: Returns DEFLATE data decompressed, a raw stream with no zlib header as `CompressData` makes.
  - `compData`: The compressed bytes.
  - `compDataSize`: How many of them.
  - `dataSize`: Its first element is set to how many bytes it gives.
  - returns: The bytes.

  Gives at most 64 MB.

  Data that isn't DEFLATE, or stops short, gives the bytes read before it, perhaps none, and logs a warning.
- `EncodeDataBase64`: Returns some bytes as Base64 text, padded with `=` to a multiple of 4 characters. See `DecodeDataBase64` for reading them back.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `outputSize`: Its first element is set to the text's length.
  - returns: The text.
- `DecodeDataBase64`: Returns the bytes of Base64 text.
  - `data`: The text's bytes.
  - `outputSize`: Its first element is set to how many bytes it gives: 3 for every 4 characters, less one for each `=` at the end.
  - returns: The bytes.

  The text runs to a zero byte or the end, read 4 characters at a time.

  A character that isn't Base64's reads as 0.

  Text whose length isn't a multiple of 4 logs a warning and is read up to its last 4 characters.
- `ComputeCRC32`: Returns the CRC-32 of some bytes, as zlib and PNG compute it.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 32 bits, one above 0x7fffffff negative.
- `ComputeMD5`: Returns the MD5 hash of some bytes.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 4 words, as raylib gives them: each read from 4 bytes of the hash, the first the lowest, and one above 0x7fffffff is negative.
- `ComputeSHA1`: Returns the standard SHA-1 hash of some bytes.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Its 5 words, the first the hash's first 4 bytes, the highest first. One above 0x7fffffff is negative.
- `SetLoadFileDataCallback`: Reads files through the program from now on.
  - `callback`: Returns a file's bytes or null, or is null for none.

  Every load raylib makes of a file (textures, models, sounds, music, data) asks the callback first. A null answer reads the file as it would be read without the callback.

  A texture's or model's images decode asynchronously, so `LoadTextureAsync` and `LoadModelAsync` load the ones the callback gives.
- `SetSaveFileDataCallback`: Writes files through the program from now on (`SaveFileDataAsync`).
  - `callback`: Writes a file's bytes, returning whether it did, or is null for none.
- `SetLoadFileTextCallback`: Reads text files through the program from now on (`LoadFileTextAsync`).
  - `callback`: Returns a file's text or null, or is null for none.
- `SetSaveFileTextCallback`: Writes text files through the program from now on (`SaveFileTextAsync`).
  - `callback`: Writes a file's text, returning whether it did, or is null for none.
- `UnloadAutomationEventList`: Frees a list's events.
  - `list`: The list.

  Has nothing to free, and the list is unchanged.
- `SetAutomationEventList`: Sets the list `StartAutomationEventRecording` records into.
  - `list`: The list, made by `LoadAutomationEventList(null)` or `LoadAutomationEventListAsync`.

  From the first call, the input functions read the input as automation keeps it, so an event `PlayAutomationEvent` plays reads as real input.
- `SetAutomationEventBaseFrame`: Sets the frame the next event recorded is stamped with, each frame after counting up from it.
  - `frame`: The frame.

  The frames since `InitWindow` until set.
- `StartAutomationEventRecording`: Starts recording into the list `SetAutomationEventList` set. See `StopAutomationEventRecording` for stopping.
  Records as each frame ends, before the next frame's input is read. Each event recorded is logged.

  Records:

  - every key, mouse button and finger held. - the mouse's moves, the wheel's and the fingers'. - the gamepads' buttons held and axes off rest. - the gesture.

  A full list (16384 events) records no more.
- `StopAutomationEventRecording`: Stops recording.
- `PlayAutomationEvent`: Plays an event, making its input the input the functions read now.
  - `event`: The event.

  The input stays until the devices change it or another event does.

  A window event or an action is done. raylib's `WINDOW_CLOSE` event makes `WindowShouldClose` true.

  Plays nothing while recording.

  A program plays each event in its frame, after the frame's input is read. A key held is an event every frame, so a frame's events are played together.
- `TraceLog`: Writes a message to the log when its level is at least `SetTraceLogLevel`'s.
  - `logLevel`: The level (`LOG_*`).
  - `text`: The message.

  The text is written as it is, with no printf formatting. Haxe's string interpolation builds it.
- `SetTraceLogLevel`: Sets the least level the log writes.
  - `logLevel`: The level (`LOG_*`).

  `LOG_INFO` until set.
- `SetTraceLogCallback`: Writes the log through the program from now on, helix-raylib's own messages among it.
  - `callback`: Receives each message's level and text, or is null for helix-raylib's own log.
- `BeginMode2D`: Draws through a 2D camera until `EndMode2D`.
  - `camera`: The camera.
- `EndMode2D`: Goes back to drawing in the screen's pixels.
- `GetCameraMatrix2D`: Returns a 2D camera's transform, from the world to the screen.
  - `camera`: The camera.
  - returns: The matrix.
- `GetWorldToScreen2D`: Returns where a point in a 2D camera's world is on the screen.
  - `position`: The point.
  - `camera`: The camera.
  - returns: The screen position.
- `GetScreenToWorld2D`: Returns where a screen position is in a 2D camera's world.
  - `position`: The screen position.
  - `camera`: The camera.
  - returns: The point, or NaN at zoom 0.
- `BeginMode3D`: Draws in 3D through a camera until `EndMode3D`, testing depth (rlgl's `rlEnableDepthTest`).
  - `camera`: The camera.
- `EndMode3D`: Goes back to drawing in 2D, in the screen's pixels, without testing depth.
- `UpdateCamera`: Moves a camera by the keyboard, the mouse and the first gamepad, as one of rcamera's modes does. See `UpdateCameraPro` for moving it by amounts.
  - `camera`: The camera, changed.
  - `mode`: The mode (`CAMERA_*`).

  `CAMERA_ORBITAL` turns the camera about its target, half a radian a second.

  `CAMERA_FREE`, `CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON`:

  - turn by the mouse, the right stick and the arrow keys, the look stopping short of straight up and down. - roll by Q and E. - move by WASD and the left stick, 5.4 units a second.

  `CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON` move along the ground, and `CAMERA_THIRD_PERSON` turns about its target.

  `CAMERA_FREE` also moves up and down by space and left control, and pans while the middle button is held.

  `CAMERA_FREE`, `CAMERA_ORBITAL` and `CAMERA_THIRD_PERSON` move toward the target by the wheel and the keypad's plus and minus.

  `CAMERA_CUSTOM` leaves the camera unchanged.
- `UpdateCameraPro`: Moves and turns a camera by amounts, as rcamera does. See `UpdateCamera` for moving it by input.
  - `camera`: The camera, changed.
  - `movement`: The distances it moves: forward (x), right (y) and up (z), in world units.
  - `rotation`: The angles it turns: yaw to the right (x), pitch down (y) and roll (z), in degrees.
  - `zoom`: How much further from its target it moves, in world units. A negative zoom moves it closer.

  Pitches first, no further up or down than straight, then yaws and rolls about the camera's own position.

  Then moves forward and right along the ground and up along the camera's up, then toward its target, the distance kept above 0.
- `GetCameraMatrix`: Returns a camera's view, as `BeginMode3D` uses it.
  - `camera`: The camera.
  - returns: The matrix.
- `GetScreenToWorldRay`: Returns the ray from a camera through a screen position, for picking. See `GetScreenToWorldRayEx` for casting through a view of another size.
  - `position`: The screen position.
  - `camera`: The camera.
  - returns: The ray.
- `GetScreenToWorldRayEx`: Returns the ray from a camera through a position in a view of a size, such as a render texture's.
  - `position`: The position in the view.
  - `camera`: The camera.
  - `width`: The view's width.
  - `height`: The view's height.
  - returns: The ray.
- `GetMouseRay`: Returns the ray from a camera through a screen position, under raylib's old name for `GetScreenToWorldRay`.
  - `position`: The screen position.
  - `camera`: The camera.
  - returns: The ray.
- `GetWorldToScreen`: Returns where a point in the world is on the screen. See `GetWorldToScreenEx` for placing it in a view of another size.
  - `position`: The point.
  - `camera`: The camera.
  - returns: The screen position.
- `GetWorldToScreenEx`: Returns where a point in the world is in a view of a size.
  - `position`: The point.
  - `camera`: The camera.
  - `width`: The view's width.
  - `height`: The view's height.
  - returns: The position in the view, or infinite or NaN for a point level with a perspective camera's position.
- `GetMouseDelta`: Returns how far the mouse moved since the last frame, in the screen's pixels times the mouse's scale (`SetMouseScale`).
  - returns: The movement.

  A `SetMousePosition` this frame is part of the movement.
- `BeginVrStereoMode`: Starts drawing for both eyes of a head-mounted display, with the config's projections and view offsets (`rlEnableStereoRender`).
  - `config`: The config, from `LoadVrStereoConfig`.

  Until `EndVrStereoMode`, each flush of the batch and each mesh draws twice, into the left half of what is drawn into for the first eye and the right half for the second.

  Each eye's projection replaces `BeginMode3D`'s.

  raylib's VR simulator draws the eyes into a render texture, then draws that to the screen through a distortion shader.
- `EndVrStereoMode`: Stops drawing for both eyes (`rlDisableStereoRender`), from the next flush of the batch and the next mesh drawn.
  Shapes drawn in stereo and not flushed yet draw once. `EndMode3D` flushes them.
- `LoadVrStereoConfig`: Returns the stereo config of a head-mounted display, as raylib 5.5 computes it.
  - `device`: The display's parameters.
  - returns: The config.

  The config holds:

  - each eye's projection, from the field of view the lenses' distortion widens, shifted by the lenses' offset from the eyes' halves of the screen, between the clip planes (`rlSetClipPlanes`). - each eye's view offset, half the interpupillary distance to its side, 0.075 up and 0.045 forward. - the lens and screen centers and scales a distortion shader reads (raylib's `distortion330.fs`).
- `UnloadVrStereoConfig`: Frees a stereo config.
  - `config`: The config.

  Has nothing to free, and logs that, as raylib 5.5 does.
- `IsShaderValid`: Returns whether a shader was made.
  - `shader`: The shader.
  - returns: True when it was.
- `UnloadShader`: Lets go of the program's hold on a shader, setting its id to 0.
  - `shader`: The shader.

  The shader is freed when no material holds it too, else when the last material holding it lets go.

  Given a material's shader (`material.shader`), lets go of one hold and leaves the material drawing with it while anything holds it.

  The default shader stays.
- `GetShaderLocation`: Returns the location of a shader's uniform or texture, by its name. See `GetShaderLocationAttrib` for finding an attribute.
  - `shader`: The shader.
  - `uniformName`: The name.
  - returns: Its location, or -1 when the shader doesn't declare it.
- `GetShaderLocationAttrib`: Returns the location of a shader's attribute, by its name.
  - `shader`: The shader.
  - `attribName`: The name.
  - returns: Its location, or -1 when the shader doesn't declare it.
- `SetShaderValue`: Sets a shader's uniform, for the models drawn after the call and the shapes in rlgl's batch when the batch is next drawn. See `SetShaderValueV` for setting an array's elements.
  - `shader`: The shader.
  - `locIndex`: The uniform's location.
  - `value`: The value: a number, an array of numbers, or a `Vector2`, `Vector3`, `Vector4` or `Color`.
  - `uniformType`: Its type (`SHADER_UNIFORM_*`).

  Shapes drawn before the call but not yet flushed take the value too. `BeginShaderMode`, `EndShaderMode`, a mode changing and `rlDrawRenderBatchActive` flush them.

  A texture's location takes the texture unit its sampler reads. `DrawMesh` binds the material's map of that index there, as raylib's skybox sets its `samplerCube` to `MATERIAL_MAP_CUBEMAP`.
- `SetShaderValueV`: Sets elements of a shader's array uniform, for the draws after the call.
  - `shader`: The shader.
  - `locIndex`: The uniform's location.
  - `value`: The values, in order.
  - `uniformType`: Each element's type (`SHADER_UNIFORM_*`).
  - `count`: The elements set.
- `SetShaderValueMatrix`: Sets a shader's matrix uniform, for the draws after the call.
  - `shader`: The shader.
  - `locIndex`: The uniform's location.
  - `mat`: The matrix.
- `SetShaderValueTexture`: Sets a shader's texture for the draws after the call, a `Texture2D` at a `sampler2D` or a cubemap (`LoadTextureCubemap`) at a `samplerCube`.
  - `shader`: The shader.
  - `locIndex`: The texture's location.
  - `texture`: The texture.

  A texture at a sampler of the other kind binds nothing.
- `BeginShaderMode`: Draws shapes, text and textures with a shader until `EndShaderMode`.
  - `shader`: The shader.
- `EndShaderMode`: Goes back to the default shader.
- `BeginBlendMode`: Blends what is drawn until `EndBlendMode` another way, as rlgl sets GL's blending.
  - `mode`: The mode (`BLEND_*`).

  The modes:

  - `BLEND_ALPHA`, alpha blended by the same factors as the color. - `BLEND_ADDITIVE`, `BLEND_MULTIPLIED`, `BLEND_ADD_COLORS`, `BLEND_SUBTRACT_COLORS` and `BLEND_ALPHA_PREMULTIPLY`. - `BLEND_CUSTOM` and `BLEND_CUSTOM_SEPARATE`, with the factors `rlSetBlendFactors` and `rlSetBlendFactorsSeparate` last set.

  Changing the mode draws the batch first, as does setting a custom mode again after its factors changed. Setting the mode already set changes nothing.

  A mode raylib doesn't have changes nothing but the mode remembered.
- `EndBlendMode`: Goes back to blending by alpha, as `BeginBlendMode(BLEND_ALPHA)` does.
- `BeginScissorMode`: Draws only within a rectangle of the screen, or of the render texture drawn into, until `EndScissorMode`.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.
  - `width`: The width.
  - `height`: The height.
- `EndScissorMode`: Draws everywhere again.
- `SetClipboardText`: Puts text on the system's clipboard, and returns once it is there. See `GetClipboardText` for reading it.
  - `text`: The text.

  A page may refuse it unless it comes soon after a key press. A refusal is logged.
- `GetClipboardText`: Reads the clipboard's text. See `GetClipboardImage` for reading an image.
  - returns: The text, or "" when the clipboard holds none or can't be read. Why it couldn't is logged.

  A page may need permission, which the browser may ask the user for.
- `GetClipboardImage`: Reads the clipboard's image. See `GetClipboardText` for reading text.
  - returns: The image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`, or an empty one when the clipboard holds none or can't be read. Why it couldn't is logged.

  A page may need permission, which the browser may ask the user for.
- `FileExists`: Returns whether a file exists, as `FileExistsAsync` answers it. See `DirectoryExists` for a directory.
  - `fileName`: The file.
  - returns: True when it exists.
- `LoadFileText`: Reads a text file, as `LoadFileTextAsync` reads it, and returns its text. See `LoadFileData` for reading a file's bytes.
  - `fileName`: The file.
  - returns: Its text, or null when it couldn't be read. Why it couldn't is logged.
- `SaveFileText`: Writes a text file, as `SaveFileTextAsync` writes it, and returns once it is written. See `SaveFileData` for writing bytes.
  - `fileName`: The file.
  - `text`: Its text.
  - returns: Whether it was written. Why it wasn't is logged.

  `LoadFileText` reads it back.
- `LoadFileData`: Reads a file's bytes, as `LoadFileDataAsync` reads them, and returns them. See `LoadFileText` for reading a text file.
  - `fileName`: The file.
  - returns: Its bytes, or null when it couldn't be read. Why it couldn't is logged.
- `SaveFileData`: Writes a file's bytes, as `SaveFileDataAsync` writes them, and returns once they are written. See `SaveFileText` for writing text.
  - `fileName`: The file.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - returns: Whether they were written. Why they weren't is logged.

  `LoadFileData` reads them back.
- `ExportDataAsCode`: Writes bytes as a C header, as `ExportDataAsCodeAsync` writes it, and returns once it is written.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `fileName`: The file; its name, upper case, names the define and the array.
  - returns: Whether it was written. Why it wasn't is logged.
- `DirectoryExists`: Returns whether a directory exists, as `DirectoryExistsAsync` answers it. See `FileExists` for a file.
  - `dirPath`: The directory.
  - returns: True when it exists.
- `GetFileLength`: Returns a file's size, as `GetFileLengthAsync` answers it.
  - `fileName`: The file.
  - returns: Its size in bytes; 0 when there is no file, as raylib's.
- `IsPathFile`: Returns whether a path is a file, not a directory, as `IsPathFileAsync` answers it. See `DirectoryExists` for a directory.
  - `path`: The path.
  - returns: True for a file; false for a directory or nothing there.
- `LoadDirectoryFiles`: Lists a directory's files and subdirectories, as `LoadDirectoryFilesAsync` lists them. See `LoadDirectoryFilesEx` for a filter by extension and the subdirectories' files.
  - `dirPath`: The directory.
  - returns: The list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as raylib's.
- `LoadDirectoryFilesEx`: Lists a directory's files with some extensions, and with `scanSubdirs` its subdirectories' too, as `LoadDirectoryFilesExAsync` lists them. See `LoadDirectoryFiles` for listing one directory's every file and subdirectory.
  - `basePath`: The directory.
  - `filter`: The extensions kept, such as ".png;.jpg;DIR", or null for every file.
  - `scanSubdirs`: Whether the subdirectories' files are listed too.
  - returns: The list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning.
- `GetFileModTime`: Returns when a file was last written, as `GetFileModTimeAsync` answers it.
  - `fileName`: The file.
  - returns: The time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's.
- `ExportAutomationEventList`: Writes a list's events as text, as `ExportAutomationEventListAsync` writes it, and returns once it is written. See `LoadAutomationEventList` for reading it back.
  - `list`: The list.
  - `fileName`: The file.
  - returns: Whether it was written. Why it wasn't is logged.
- `EndDrawing`: Ends a frame's drawing and shows it, then waits out the rest of the frame (`SetTargetFPS`) and reads the next frame's input. In a page the wait is for the browser's next frame.
  Built with `-D helix-raylib-custom-frame-control`, raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`, only ends the drawing. The program then calls `SwapScreenBuffer` to show the frame, `WaitTime` to wait and `PollInputEvents` to read the input.


```haxe
static function ToggleFullscreenAsync(?done:() -> Void, ?failed:String -> Void):Void
static function ToggleBorderlessWindowedAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowSizeAsync(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowPositionAsync(x:Int, y:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowMonitorAsync(monitor:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function MaximizeWindowAsync(?done:() -> Void, ?failed:String -> Void):Void
static function MinimizeWindowAsync(?done:() -> Void, ?failed:String -> Void):Void
static function RestoreWindowAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowFocusedAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowOpacityAsync(opacity:Float, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowMinSizeAsync(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SetWindowMaxSizeAsync(width:Int, height:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function DisableCursorAsync(?done:() -> Void, ?failed:String -> Void):Void
static function EnableCursorAsync(?done:() -> Void, ?failed:String -> Void):Void
static function SetClipboardTextAsync(text:String, ?done:() -> Void, ?failed:String -> Void):Void
static function GetClipboardTextAsync(read:String -> Void, ?failed:String -> Void):Void
static function GetClipboardImageAsync(loaded:Image -> Void, ?failed:String -> Void):Void
static function TakeScreenshotAsync(fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `ToggleFullscreenAsync`: Asynchronously asks for fullscreen, or for the window back at the size and place it had. See `ToggleBorderlessWindowedAsync` for the borderless window, replacing raylib's `ToggleFullscreen`.
  - `done`: Optional. Called once the window has changed, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  It may wait for the next key press, click or tap, or be refused.

  Called while borderless, it only switches to fullscreen.

  `IsWindowFullscreen` reports the new state once the window has changed, not when the call returns.
- `ToggleBorderlessWindowedAsync`: Asynchronously asks for the window to fill the screen without borders, or back to the window. See `ToggleFullscreenAsync` for fullscreen, replacing raylib's `ToggleBorderlessWindowed`.
  - `done`: Optional. Called once the window has changed, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it was refused; when omitted, it is logged.

  The window fills the screen without borders.

  It may wait for the next key press, click or tap, as `ToggleFullscreenAsync` may.

  Called while fullscreen, it only switches to borderless.

  As in raylib, `IsWindowState(FLAG_BORDERLESS_WINDOWED_MODE)` is true while it is, and `IsWindowFullscreen` false.
- `SetWindowSizeAsync`: Asynchronously asks for the window's size, replacing raylib's `SetWindowSize`. See `SetWindowMinSizeAsync` and `SetWindowMaxSizeAsync` for limiting how small or large it can be.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
  - `done`: Optional. Called once the window has a size from the request, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't resized; when omitted, it is logged.

  The window manager may give another size. `GetScreenWidth` and `GetScreenHeight` report it once it has.

  Refused while the window is fullscreen or maximized, and where the system doesn't allow it.

  A size under 1 pixel is refused.
- `SetWindowPositionAsync`: Asynchronously asks for the window's place on the desktop, replacing raylib's `SetWindowPosition`. See `SetWindowMonitorAsync` for moving it to another monitor.
  - `x`: The left edge, in pixels.
  - `y`: The top edge, in pixels.
  - `done`: Optional. Called once the window has moved, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it didn't move; when omitted, it is logged.

  Refused while the window is fullscreen or maximized, and where the system doesn't allow it, as Wayland doesn't.
- `SetWindowMonitorAsync`: Asynchronously asks for the window on another monitor, replacing raylib's `SetWindowMonitor`. See `SetWindowPositionAsync` for placing it on the desktop.
  - `monitor`: The monitor, 0 to `GetMonitorCount() - 1`.
  - `done`: Optional. Called once the window is on the monitor, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it isn't, such as a monitor that isn't there; when omitted, it is logged.

  Where the window can't be moved, a monitor other than its own is refused.
- `MaximizeWindowAsync`: Asynchronously asks for the window maximized, replacing raylib's `MaximizeWindow`. See `RestoreWindowAsync` for bringing it back.
  - `done`: Optional. Called once the window is maximized, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  Refused where the system can't maximize the window.
- `MinimizeWindowAsync`: Asynchronously asks for the window minimized, replacing raylib's `MinimizeWindow`. See `RestoreWindowAsync` for bringing it back.
  - `done`: Optional. Called once the window is minimized, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  Refused where the system can't minimize the window.
- `RestoreWindowAsync`: Asynchronously asks for the window back to its size from minimized or maximized, replacing raylib's `RestoreWindow`. See `MaximizeWindowAsync` and `MinimizeWindowAsync` for changing it.
  - `done`: Optional. Called once the window is restored, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  A minimized window is restored from minimized, any other from maximized.
- `SetWindowFocusedAsync`: Asynchronously asks for the window brought to the front with the keyboard, replacing raylib's `SetWindowFocused`.
  - `done`: Optional. Called once the window has the keyboard or the window manager keeps it elsewhere, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  A window manager may only flash it.
- `SetWindowOpacityAsync`: Asynchronously asks for the window's opacity, replacing raylib's `SetWindowOpacity`.
  - `opacity`: From 0 (clear) to 1 (opaque).
  - `done`: Optional. Called once the window has the opacity, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  A desktop without a compositor refuses it.
- `SetWindowMinSizeAsync`: Asynchronously asks for the smallest size the window may take, replacing raylib's `SetWindowMinSize`. See `SetWindowMaxSizeAsync` for setting the largest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  Refused where the system doesn't allow it.

  A size under 0 pixels is refused.
- `SetWindowMaxSizeAsync`: Asynchronously asks for the largest size the window may take, replacing raylib's `SetWindowMaxSize`. See `SetWindowMinSizeAsync` for setting the smallest.
  - `width`: The width, in the screen's pixels.
  - `height`: The height.
  - `done`: Optional. Called once the window has the limit, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it hasn't; when omitted, it is logged.

  Refused where the system doesn't allow it.

  A size under 0 pixels is refused.
- `DisableCursorAsync`: Asynchronously locks the mouse to the window and hides the cursor, for looking around, replacing raylib's `DisableCursor`. See `EnableCursorAsync` for letting it go.
  - `done`: Optional. Called once the mouse is locked, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  `GetMouseDelta` keeps coming while the position goes on past the window's edges.

  `IsCursorHidden` is true from the call.

  The lock may wait for the next click or key press, or be refused.
- `EnableCursorAsync`: Asynchronously lets go of the mouse that `DisableCursorAsync` locked and shows the cursor, replacing raylib's `EnableCursor`.
  - `done`: Optional. Called once the mouse is let go, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  `IsCursorHidden` is false from the call.
- `SetClipboardTextAsync`: Asynchronously puts text on the system's clipboard, replacing raylib's `SetClipboardText`. See `GetClipboardTextAsync` for reading it.
  - `text`: The text.
  - `done`: Optional. Called once the text is on the clipboard, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it isn't; when omitted, it is logged.

  It may be refused unless it comes soon after a key press.
- `GetClipboardTextAsync`: Asynchronously reads the clipboard's text, replacing raylib's `GetClipboardText`. See `GetClipboardImageAsync` for reading an image.
  - `read`: Receives the text at a later poll; "" when the clipboard holds none.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  It may need permission, which the system may ask for.
- `GetClipboardImageAsync`: Asynchronously reads the clipboard's image, replacing raylib's `GetClipboardImage`. See `GetClipboardTextAsync` for reading text.
  - `loaded`: Receives the image once it is decoded, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
  - `failed`: Optional. Receives why there is none, or why it couldn't be read; when omitted, it is logged.

  It may need permission, which the system may ask for.
- `TakeScreenshotAsync`: Asynchronously takes a screenshot of the next frame and saves it as a file, replacing raylib's `TakeScreenshot`. See `LoadImageFromScreenAsync` for the screen as an `Image`.
  - `fileName`: The file's name, or its path; a name with `'` is refused, as raylib's is.
  - `done`: Optional. Called once the file is written or downloaded, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The name's extension picks the format, as `ExportImageAsync` does: ".png", ".qoi" or ".raw". Any other is refused.

  It is written where the name says, as raylib 6.2 writes it. A relative name is under the working directory, its directories kept. An absolute one is where it is.

  A directory that isn't there isn't made, and the screenshot is refused.

  Taken as the next frame ends, not from the frame drawn last as raylib's is.

  The image\'s alpha is opaque, as raylib's is.

  Refused before `InitWindow`.


```haxe
static function LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):Void
static function LoadFileTextAsync(fileName:String, loaded:String -> Void, ?failed:String -> Void):Void
static function LoadSavedFileDataAsync(fileName:String, loaded:haxe.io.Bytes -> Void, ?failed:String -> Void):Void
static function LoadSavedFileTextAsync(fileName:String, loaded:String -> Void, ?failed:String -> Void):Void
static function SaveFileDataAsync(fileName:String, data:haxe.io.Bytes, dataSize:Int, ?done:() -> Void, ?failed:String -> Void):Void
static function SaveFileTextAsync(fileName:String, text:String, ?done:() -> Void, ?failed:String -> Void):Void
static function FileExistsAsync(fileName:String, answer:Bool -> Void):Void
static function SavedFileExistsAsync(fileName:String, answer:Bool -> Void):Void
static function DirectoryExistsAsync(dirPath:String, answer:Bool -> Void):Void
static function IsPathFileAsync(path:String, answer:Bool -> Void):Void
static function GetFileLengthAsync(fileName:String, answer:Int -> Void):Void
static function GetFileModTimeAsync(fileName:String, answer:Int -> Void):Void
static function LoadDirectoryFilesAsync(dirPath:String, loaded:FilePathList -> Void):Void
static function LoadDirectoryFilesExAsync(basePath:String, filter:String, scanSubdirs:Bool, loaded:FilePathList -> Void):Void
static function ExportDataAsCodeAsync(data:haxe.io.Bytes, dataSize:Int, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
static function LoadAutomationEventListAsync(fileName:String, loaded:AutomationEventList -> Void, ?failed:String -> Void):Void
static function ExportAutomationEventListAsync(list:AutomationEventList, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadFileDataAsync`: Asynchronously reads a file's bytes, replacing raylib's `LoadFileData`. See `LoadFileTextAsync` for reading a text file.
  - `fileName`: The file.
  - `loaded`: Receives its bytes.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  Reads the first of these that has the file: - the program's `SetLoadFileDataCallback` - what `SaveFileData` wrote - the program's files
- `LoadFileTextAsync`: Asynchronously reads a text file, replacing raylib's `LoadFileText`. See `LoadFileDataAsync` for reading a file's bytes.
  - `fileName`: The file.
  - `loaded`: Receives its text.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  Reads the first of these that has the file: - the program's `SetLoadFileTextCallback` - what `SaveFileText` wrote - the program's files

  The text ends at the file's first NUL byte, as raylib's C string does.

  A byte that isn't UTF-8 is read as U+FFFD. A file is never refused for what it holds.
- `LoadSavedFileDataAsync`: Asynchronously reads a saved file's bytes: one `SaveFileData` or `SaveFileText` wrote. See `LoadFileDataAsync` for any other file.
  - `fileName`: The file.
  - `loaded`: Receives its bytes.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  Reads the program's `SetLoadFileDataCallback` first when it has one. A file that wasn't saved fails, at a later frame.
- `LoadSavedFileTextAsync`: Asynchronously reads a saved text file: one `SaveFileText` or `SaveFileData` wrote. See `LoadFileTextAsync` for any other file.
  - `fileName`: The file.
  - `loaded`: Receives its text.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  Reads the program's `SetLoadFileTextCallback` first when it has one. A file that wasn't saved fails, at a later frame.

  The text ends at the file's first NUL byte, and a byte that isn't UTF-8 is read as U+FFFD, as `LoadFileTextAsync` reads it.
- `SaveFileDataAsync`: Asynchronously writes a file's bytes, replacing raylib's `SaveFileData`. See `SaveFileTextAsync` for writing text.
  - `fileName`: The file.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  They are written through the program's `SetSaveFileDataCallback` when it has one. Otherwise they are kept across runs, as `SaveFileTextAsync`'s are.

  `LoadFileDataAsync` reads them back.
- `SaveFileTextAsync`: Asynchronously writes a text file, replacing raylib's `SaveFileText`. See `SaveFileDataAsync` for writing bytes.
  - `fileName`: The file.
  - `text`: Its text.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  Written through the program's `SetSaveFileTextCallback` when it has one, during the call, and answered by what that returned.

  Otherwise it is kept across runs, and answered once the write has finished.

  `LoadFileTextAsync` reads it back.
- `FileExistsAsync`: Asynchronously answers whether a file exists, replacing raylib's `FileExists`. See `DirectoryExistsAsync` for a directory.
  - `fileName`: The file.
  - `answer`: Receives true when it exists.

  The answer comes at a later frame, never during the call.

  A file exists when `SaveFileText` or `SaveFileData` wrote it, or when it is one of the program's.

  Finding one of the program's files reads it, so a load of it after answers at once.
- `SavedFileExistsAsync`: Asynchronously answers whether a saved file exists: one `SaveFileText` or `SaveFileData` wrote. See `FileExistsAsync` for any other file.
  - `fileName`: The file.
  - `answer`: Receives true when it was saved.

  The answer comes at a later frame, never during the call.
- `DirectoryExistsAsync`: Asynchronously answers whether a directory exists, replacing raylib's `DirectoryExists`. See `FileExistsAsync` for a file.
  - `dirPath`: The directory.
  - `answer`: Receives true when it exists.

  The answer comes at a later frame, never during the call.

  A directory exists when a file `SaveFileText` or `SaveFileData` wrote is in it. The root ("", "." or "./") always exists.

  `helix-raylib-dropped` and the directories under it hold the dropped files.

  The program's own files aren't in directories: a program names each one it loads.
- `IsPathFileAsync`: Asynchronously answers whether a path is a file, not a directory, replacing raylib's `IsPathFile`. See `DirectoryExistsAsync` for a directory.
  - `path`: The path.
  - `answer`: Receives true for a file; false for a directory or nothing there.

  The answer comes at a later frame, never during the call.

  These are files, as `FileExistsAsync` finds them: - a file `SaveFileText` or `SaveFileData` wrote - a dropped file - a file the program has
- `GetFileLengthAsync`: Asynchronously answers a file's size, replacing raylib's `GetFileLength`.
  - `fileName`: The file.
  - `answer`: Receives its size in bytes; 0 when there is no file, as raylib's.

  The answer comes at a later frame, never during the call.

  The size is: - for a file `SaveFileText` or `SaveFileData` wrote, or the program's `SetLoadFileDataCallback` gives, its bytes' size - for a dropped file, its own - for a file of the program's, its size
- `GetFileModTimeAsync`: Asynchronously answers when a file was last written, replacing raylib's `GetFileModTime`.
  - `fileName`: The file.
  - `answer`: Receives the time, in whole seconds since the Unix epoch; 0 when there is no file or no time, as raylib's.

  The answer comes at a later frame, never during the call.

  The time is: - for a file of the program's, its time on disk - for a file `SaveFileText` or `SaveFileData` wrote, when it was saved - for a dropped file, the time kept for it - 0 for a file whose time isn't kept, such as one the program's load callback gives
- `LoadDirectoryFilesAsync`: Asynchronously lists a directory's files and subdirectories, replacing raylib's `LoadDirectoryFiles`. See `LoadDirectoryFilesExAsync` for a filter by extension and the subdirectories' files.
  - `dirPath`: The directory.
  - `loaded`: Receives the list, its `capacity` its `count`; empty, with a warning, when the directory can't be listed, as raylib's.

  The answer comes at a later frame, never during the call.

  Each path is the directory's followed by `/` and the name (`dirPath` "levels" gives "levels/1.json"). A subdirectory's has no slash at its end.

  The paths are sorted by name.

  The files listed are those `SaveFileText` and `SaveFileData` wrote, and the dropped files, in `DirectoryExistsAsync`'s directories. The program's own files aren't listed: a program names each one it loads.
- `LoadDirectoryFilesExAsync`: Asynchronously lists a directory's files with some extensions, and with `scanSubdirs` its subdirectories' too, replacing raylib's `LoadDirectoryFilesEx`. See `LoadDirectoryFilesAsync` for listing one directory's every file and subdirectory.
  - `basePath`: The directory.
  - `filter`: The extensions kept, such as ".png;.jpg;DIR", or null for every file.
  - `scanSubdirs`: Whether the subdirectories' files are listed too.
  - `loaded`: Receives the list, its `capacity` 8192; a directory that can't be listed adds nothing, with a warning.

  The answer comes at a later frame, never during the call.

  The paths are `LoadDirectoryFilesAsync`'s, a subdirectory's files right after it.

  A filter is `IsFileExtension`'s list. "DIR" in it keeps the subdirectories.

  A null filter keeps every file, and without `scanSubdirs` every subdirectory too.

  At most 8192 paths are listed (raylib's `MAX_FILEPATH_CAPACITY`), with a warning when there are more.
- `ExportDataAsCodeAsync`: Asynchronously writes bytes as a C header, the text raylib's `ExportDataAsCode` writes. See `SaveFileDataAsync` for the bytes as they are.
  - `data`: The bytes.
  - `dataSize`: How many of them.
  - `fileName`: The file; its name, upper case, names the define and the array, with `_` for `.`, `-`, `?`, `!` and `+`.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The header is raylib's, byte for byte: - the bytes' count, as a define - the bytes, as an array in hexadecimal, 20 a line

  Written through `SaveFileTextAsync`.
- `LoadAutomationEventListAsync`: Asynchronously loads an automation events list from a text file, replacing raylib's `LoadAutomationEventList` given a file. See `ExportAutomationEventListAsync` for writing one.
  - `fileName`: The file, as `ExportAutomationEventList` writes it.
  - `loaded`: Receives the list, its capacity 16384.
  - `failed`: Optional. Receives why it couldn't be read; when omitted, it is logged.

  The file is read as `LoadFileTextAsync` reads it.

  Reads these lines, as raylib's does: - a line starting `c`, the count - a line starting `e`, an event: its frame, type and four parameters

  Other lines are skipped. So is a last line with no newline at its end, as raylib's reading skips it. A line is read 255 characters at most, as raylib's `fgets` reads it.

  A count that isn't the number of events read warns, and the count becomes the events read.
- `ExportAutomationEventListAsync`: Asynchronously writes a list's events as text, the text raylib's `ExportAutomationEventList` writes. See `LoadAutomationEventListAsync` for reading it back.
  - `list`: The list.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The text is raylib's, byte for byte: - a header of comments - `c` and the count - a line for each event: `e`, its frame, type and four parameters, and its type's name

  Written through `SaveFileTextAsync`.


```haxe
static function LoadCompiledShaderAsync(compiledShaderFileName:String, loaded:Shader -> Void, ?failed:String -> Void):Void
static function LoadCompiledShaderFromData(compiledShaderData:haxe.io.Bytes):Shader
static macro function LoadCompiledShader(compiledShaderFileName:String):Shader
```

- `LoadCompiledShaderAsync`: Asynchronously loads a shader compiled ahead of time by `CompileShaderFile`, replacing raylib's `LoadShader`. See `LoadCompiledShaderFromData` for making one from compiled data in memory.
  - `compiledShaderFileName`: The compiled shader's file.
  - `loaded`: Receives the shader.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  Its stages are raylib's GLSL (`#version 330`), and may include helix-raylib's shader includes, such as `<helix/raylib/shaders/skinning.glsl>`. Compile each shader with a line in the build's hxml:

  ```hxml
  --macro helix.raylib.Raylib.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
  ```
- `LoadCompiledShaderFromData`: Returns a shader made from a compiled shader's data, replacing raylib's `LoadShaderFromMemory`. See `LoadCompiledShader` for loading one from a file.
  - `compiledShaderData`: The compiled shader, as `CompileShaderFile` writes it.
  - returns: The shader, or an empty one (id 0) when the data isn't a compiled shader, with a warning.
- `LoadCompiledShader`: Loads a shader compiled ahead of time by `CompileShaderFile`, and returns it, in place of raylib's `LoadShader`. See `LoadCompiledShaderFromData` for making one from compiled data in memory.
  - `compiledShaderFileName`: The compiled shader's file.
  - returns: The shader, or an empty one (id 0) when it couldn't be loaded. Why it couldn't is logged.

  Its stages are raylib's GLSL (`#version 330`), and may include helix-raylib's shader includes, such as `<helix/raylib/shaders/skinning.glsl>`. Compile each shader with a line in the build's hxml:

  ```hxml
  --macro helix.raylib.Raylib.CompileShaderFile("shaders/glow.vs", "shaders/glow.fs", "web/glow.shader")
  ```
