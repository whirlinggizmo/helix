# rcore: the window and frame, input, files, cameras and shaders

[Back to the library](README.md)


```haxe
static function InitWindow(width:Int, height:Int, title:String):Void
static function CloseWindow():Void
static function WindowShouldClose():Bool
static function IsWindowReady():Bool
static function IsWindowResized():Bool
static function SetWindowTitle(title:String):Void
static function IsWindowFullscreen():Bool
static function IsWindowHidden():Bool
static function IsWindowMinimized():Bool
static function IsWindowMaximized():Bool
static function SetWindowIcon(image:Image):Void
static function SetWindowIcons(images:Array<Image>, count:Int):Void
static function GetMonitorRefreshRate(monitor:Int):Int
static function OpenURL(url:String):Void
static function IsWindowFocused():Bool
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
static function EndDrawing():Void
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
```

- `InitWindow`: Opens the window and its graphics.
  - `width`: The window's width, in pixels.
  - `height`: The window's height, in pixels.
  - `title`: The window's title.

  In a page the canvas fills the page, and width and height are ignored.

  Seeds `GetRandomValue` from the time, unless `SetRandomSeed` was called first.
- `CloseWindow`: Closes the window, after keeping what `SaveFileTextAsync` wrote.
- `WindowShouldClose`: Returns whether the window should close, after the exit key is pressed or the window is asked to close.
  - returns: True once the window should close.

  The exit key is Escape unless `SetExitKey` changed it.

  Always false in a page, where the loop that reads it runs once a frame.

  In a page, the program's loop must be a `while` or `do`-`while` in the main class, a statement of a function's own block. A call in a loop that never lets the page draw throws.
- `IsWindowReady`: Returns whether the window is open.
  - returns: True after `InitWindow`.
- `IsWindowResized`: Returns whether the window changed size since the last frame.
  - returns: True for the frame after a resize.
- `SetWindowTitle`: Sets the window's title.
  - `title`: The title.
- `IsWindowFullscreen`: Returns whether the window is fullscreen, false for a borderless window (`ToggleBorderlessWindowedAsync`).
  - returns: True while it is.

  In a page, whether the canvas is fullscreen.
- `IsWindowHidden`: Returns whether the window is hidden (`FLAG_WINDOW_HIDDEN`).
  - returns: True while it is.

  In a page, whether the canvas is hidden.
- `IsWindowMinimized`: Returns whether the window is minimized, or in a page whether its tab is in the background.
  - returns: True while it is.
- `IsWindowMaximized`: Returns whether the window is maximized.
  - returns: True while it is.

  Always false in a page.
- `SetWindowIcon`: Sets the window's icon, in a page the page's icon. See `SetWindowIcons` for giving several sizes.
  - `image`: The icon.

  The image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`. Another format logs a warning and changes nothing.

  An image with no data is ignored.
- `SetWindowIcons`: Sets the window's icon from several sizes, using the largest.
  - `images`: The icons.
  - `count`: How many of them.

  Each image must be `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`. One in another format logs a warning and changes nothing.
- `GetMonitorRefreshRate`: Returns how many times a second a monitor shows a new picture.
  - `monitor`: The monitor.
  - returns: The refresh rate in hertz, or 0 in a page, which can't tell.
- `OpenURL`: Opens a URL in the system's browser, in a page a new tab.
  - `url`: The URL.

  Opens only http, https and mailto URLs.

  A URL with `'` or `"` logs a warning and doesn't open.

  In a page, a URL opens at the next key press, click or tap when none came just before.

  A URL that fails to open logs a warning.
- `IsWindowFocused`: Returns whether the window has the keyboard.
  - returns: True while it has.
- `GetWindowPosition`: Returns the window's place on the desktop.
  - returns: Its left and top edges, in pixels.
- `GetWindowScaleDPI`: Returns how many of the display's pixels a pixel drawn takes, across and down, 2 on most phones and high-density displays.
  - returns: The scale.

  Natively, the display's scale whatever the flags.

  In a page, 1 unless `FLAG_WINDOW_HIGHDPI` was set before `InitWindow`. The flag draws the canvas at the device's pixel ratio.
- `GetMonitorCount`: Returns the number of monitors.
  - returns: The count, at least 1.

  Always 1 in a page.
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

  `FLAG_VSYNC_HINT` shows frames at the display's refresh. Without it, frames natively show as soon as they are drawn. A page's frames always follow the display.

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

  Natively, `EndDrawing` waits.

  In a page, where frames follow the display's refresh, a frame is skipped until it is time. A rate above the display's changes nothing there.
- `GetFPS`: Returns the frames a second, averaged over the last half second or so.
  - returns: The frames a second.
- `GetFrameTime`: Returns the seconds the last frame took.
  - returns: The seconds.
- `WaitTime`: Stops the program for a time, drawing nothing and reading no input until it ends.
  - `seconds`: How long.

  Spins in a page, so the page doesn't respond meanwhile.
- `GetTime`: Returns the seconds since `InitWindow`.
  - returns: The seconds.
- `SetExitKey`: Sets the key that closes the window natively, or `KEY_NULL` for none.
  - `key`: The key.

  Escape until set.
- `BeginDrawing`: Begins a frame's drawing.
- `EndDrawing`: Ends a frame's drawing and shows it, then natively waits out the rest of the frame (`SetTargetFPS`) and reads the next frame's input.
  Built with `-D helix-raylib-custom-frame-control`, raylib's `SUPPORT_CUSTOM_FRAME_CONTROL`, only ends the drawing. The program then calls `SwapScreenBuffer` to show the frame, `WaitTime` to wait and `PollInputEvents` to read the input.
- `SwapScreenBuffer`: Shows the frame `EndDrawing` ended, for a program built with `-D helix-raylib-custom-frame-control`.
  Does nothing without the define, as `EndDrawing` has shown the frame already.

  A frame not shown by the next `EndDrawing` is shown then.

  In a page, the browser shows the frame when the loop's body returns, wherever the call is.
- `PollInputEvents`: Reads the input that came since the last read: each key's, button's and finger's state, and the window's events.
  `EndDrawing` reads the input already, unless the program is built with `-D helix-raylib-custom-frame-control`.

  A second read starts a new frame of input, so a key pressed before it reads as held.

  With `EnableEventWaiting`, waits natively for an event first.
- `EnableEventWaiting`: Makes each frame natively wait for an event before the next is read. See `DisableEventWaiting` for going back to reading the events there are.
  An event is a key, a mouse button, the mouse moving or the window changing, from a device the program reads.

  The program draws nothing while waiting, and uses little time.

  The platform and helix-raylib's async loads are still served, so a load answers while waiting and is drawn after the next event.

  Changes nothing in a page, where the browser runs each frame.
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

  A free finger (`EnableVirtualGamepad`) down counts as the left button.
- `IsMouseButtonReleased`: Returns whether a mouse button went up this frame.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True for that frame alone.

  The last free finger (`EnableVirtualGamepad`) lifting counts as the left button.
- `IsMouseButtonUp`: Returns whether a mouse button isn't held.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True while it is up.
- `GetMouseX`: Returns the mouse's x, in the screen's pixels, the first free finger's (`EnableVirtualGamepad`) while one is down.
  - returns: The x.
- `GetMouseY`: Returns the mouse's y, in the screen's pixels, the first free finger's (`EnableVirtualGamepad`) while one is down.
  - returns: The y.
- `GetMousePosition`: Returns the mouse's position, in the screen's pixels, the first free finger's (`EnableVirtualGamepad`) while one is down.
  - returns: The position.

  `SetMouseOffset`'s offset is added first, then `SetMouseScale`'s scale applied.
- `SetMousePosition`: Moves the mouse to a place on the screen.
  - `x`: The place across, in the screen's pixels.
  - `y`: The place down.

  `GetMouseDelta` this frame includes the move.

  In a page, and natively where the system refuses as Wayland does, the cursor stays. The position reads the place given until the mouse moves, and a warning says why, once a run for each reason.
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
- `IsCursorOnScreen`: Returns whether the mouse is over the window.
  - returns: True from its first move over the window until it leaves.
- `SetMouseCursor`: Sets the cursor's shape, the system's own cursor of each kind.
  - `cursor`: The shape (`MOUSE_CURSOR_*`). `MOUSE_CURSOR_DEFAULT` and `MOUSE_CURSOR_ARROW` are both the arrow.
- `GetMouseWheelMove`: Returns how far the wheel turned this frame, the larger of its two directions, forward positive. See `GetMouseWheelMoveV` for reading both directions.
  - returns: The notches.
- `GetTouchPointCount`: Returns the number of fingers down.
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

  A gamepad that can't shake, one without motors or any in a browser without vibration (Firefox), stays still and logs a warning, once a run.
- `SetGamepadMappings`: Adds mappings for gamepads the system doesn't know, in SDL's controller database format.
  - `mappings`: The mappings, one a line.
  - returns: How many were added or updated, or 0 in a page, whose browser maps gamepads itself.
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

  The poll runs over gamepads 0 to 3, each's buttons in the browser's order in a page, else GLFW's.

  In a page, the second triggers are among the buttons and the middle button never is.

  Natively, the middle button is among them, and the left and right second triggers count as held while their axis (`GetGamepadAxisMovement`) is over 0.1.
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
- `UnloadFileText`: Frees text `LoadFileTextAsync` gave.
  - `text`: The text.

  Has nothing to free.
- `UnloadFileData`: Frees bytes `LoadFileDataAsync` gave.
  - `data`: The bytes.

  Has nothing to free.
- `GetWorkingDirectory`: Returns the working directory, natively the process's and in a page ".", the page's own. See `GetApplicationDirectory` for finding the program's files.
  - returns: The directory, without a slash at its end.

  Natively, `TakeScreenshotAsync` writes to it.

  helix-raylib's loads don't read from it. A file's name is under the program's files wherever the working directory is.
- `GetApplicationDirectory`: Returns the directory the program's files are read from.
  - returns: The directory, with a slash at its end.

  Natively, `-D helix-raylib-native-root` from the executable's directory, `../web` unless set.

  In a page, "./", the page's own directory.

  A load given a path in it reads the file the path names, so `GetApplicationDirectory() + "resources/a.png"` loads "resources/a.png".
- `ChangeDirectory`: Changes the working directory, natively the process's.
  - `dir`: The directory.
  - returns: True when the working directory is it now.

  `TakeScreenshotAsync` writes to the new directory from then on.

  helix-raylib's loads are unchanged, reading the program's files wherever the working directory is.

  In a page, only "." or "./" succeeds, changing nothing.

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
- `IsFileDropped`: Returns whether files were dropped on the window, natively from the desktop and in a page on the canvas. See `LoadDroppedFiles` for reading their paths.
  - returns: True while dropped files are held.

  Stays true until `UnloadDroppedFiles`.

  A new drop's files replace the last one's.

  A dropped file counts once its bytes are read, natively in the frame after the drop and in a page a frame or so after.
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

  In a page, a texture's or model's images still decode only asynchronously, so `LoadTextureAsync` and `LoadModelAsync` load the ones the callback gives.
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
