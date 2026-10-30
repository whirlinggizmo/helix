# helix.ray

[Back to the index](README.md)

## Color

*class* in [`ray/src/helix/ray/Color.hx`](../../ray/src/helix/ray/Color.hx), `import helix.ray.Color;`

Represents raylib's `Color`: red, green, blue and alpha, each 0 to 255.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?r:Int, ?g:Int, ?b:Int, ?a:Int}
```

```haxe
var r:Int
var g:Int
var b:Int
var a:Int
```

- `r`: Gets or sets the red, 0 to 255.
- `g`: Gets or sets the green, 0 to 255.
- `b`: Gets or sets the blue, 0 to 255.
- `a`: Gets or sets the alpha, 0 (clear) to 255 (opaque).

## Raylib

*class* in [`ray/src/helix/ray/Raylib.hx`](../../ray/src/helix/ray/Raylib.hx), `import helix.ray.Raylib;`

Provides raylib 5.5's API, as `raylib.h` names it, over helix-platform and helix-services: a program writes raylib, and it runs in a page and natively.

A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`; in a page its body runs once a frame. The files under the program's directory are loaded before its `main` runs, so `LoadTexture` and `LoadSound` answer at once. `SaveFileText` writes are kept across runs. This is the 2D part of raylib: no 3D, shaders, fonts other than the default, or images on the CPU yet.

```haxe
static inline var KEY_NULL:Int
static inline var KEY_APOSTROPHE:Int
static inline var KEY_COMMA:Int
static inline var KEY_MINUS:Int
static inline var KEY_PERIOD:Int
static inline var KEY_SLASH:Int
static inline var KEY_ZERO:Int
static inline var KEY_ONE:Int
static inline var KEY_TWO:Int
static inline var KEY_THREE:Int
static inline var KEY_FOUR:Int
static inline var KEY_FIVE:Int
static inline var KEY_SIX:Int
static inline var KEY_SEVEN:Int
static inline var KEY_EIGHT:Int
static inline var KEY_NINE:Int
static inline var KEY_SEMICOLON:Int
static inline var KEY_EQUAL:Int
static inline var KEY_A:Int
static inline var KEY_B:Int
static inline var KEY_C:Int
static inline var KEY_D:Int
static inline var KEY_E:Int
static inline var KEY_F:Int
static inline var KEY_G:Int
static inline var KEY_H:Int
static inline var KEY_I:Int
static inline var KEY_J:Int
static inline var KEY_K:Int
static inline var KEY_L:Int
static inline var KEY_M:Int
static inline var KEY_N:Int
static inline var KEY_O:Int
static inline var KEY_P:Int
static inline var KEY_Q:Int
static inline var KEY_R:Int
static inline var KEY_S:Int
static inline var KEY_T:Int
static inline var KEY_U:Int
static inline var KEY_V:Int
static inline var KEY_W:Int
static inline var KEY_X:Int
static inline var KEY_Y:Int
static inline var KEY_Z:Int
static inline var KEY_LEFT_BRACKET:Int
static inline var KEY_BACKSLASH:Int
static inline var KEY_RIGHT_BRACKET:Int
static inline var KEY_GRAVE:Int
static inline var KEY_SPACE:Int
static inline var KEY_ESCAPE:Int
static inline var KEY_ENTER:Int
static inline var KEY_TAB:Int
static inline var KEY_BACKSPACE:Int
static inline var KEY_INSERT:Int
static inline var KEY_DELETE:Int
static inline var KEY_RIGHT:Int
static inline var KEY_LEFT:Int
static inline var KEY_DOWN:Int
static inline var KEY_UP:Int
static inline var KEY_PAGE_UP:Int
static inline var KEY_PAGE_DOWN:Int
static inline var KEY_HOME:Int
static inline var KEY_END:Int
static inline var KEY_CAPS_LOCK:Int
static inline var KEY_SCROLL_LOCK:Int
static inline var KEY_NUM_LOCK:Int
static inline var KEY_PRINT_SCREEN:Int
static inline var KEY_PAUSE:Int
static inline var KEY_F1:Int
static inline var KEY_F2:Int
static inline var KEY_F3:Int
static inline var KEY_F4:Int
static inline var KEY_F5:Int
static inline var KEY_F6:Int
static inline var KEY_F7:Int
static inline var KEY_F8:Int
static inline var KEY_F9:Int
static inline var KEY_F10:Int
static inline var KEY_F11:Int
static inline var KEY_F12:Int
static inline var KEY_LEFT_SHIFT:Int
static inline var KEY_LEFT_CONTROL:Int
static inline var KEY_LEFT_ALT:Int
static inline var KEY_LEFT_SUPER:Int
static inline var KEY_RIGHT_SHIFT:Int
static inline var KEY_RIGHT_CONTROL:Int
static inline var KEY_RIGHT_ALT:Int
static inline var KEY_RIGHT_SUPER:Int
static inline var KEY_KB_MENU:Int
static inline var KEY_KP_0:Int
static inline var KEY_KP_1:Int
static inline var KEY_KP_2:Int
static inline var KEY_KP_3:Int
static inline var KEY_KP_4:Int
static inline var KEY_KP_5:Int
static inline var KEY_KP_6:Int
static inline var KEY_KP_7:Int
static inline var KEY_KP_8:Int
static inline var KEY_KP_9:Int
static inline var KEY_KP_DECIMAL:Int
static inline var KEY_KP_DIVIDE:Int
static inline var KEY_KP_MULTIPLY:Int
static inline var KEY_KP_SUBTRACT:Int
static inline var KEY_KP_ADD:Int
static inline var KEY_KP_ENTER:Int
static inline var KEY_KP_EQUAL:Int
static inline var KEY_BACK:Int
static inline var KEY_MENU:Int
static inline var KEY_VOLUME_UP:Int
static inline var KEY_VOLUME_DOWN:Int
static inline var MOUSE_BUTTON_LEFT:Int
static inline var MOUSE_BUTTON_RIGHT:Int
static inline var MOUSE_BUTTON_MIDDLE:Int
static inline var MOUSE_BUTTON_SIDE:Int
static inline var MOUSE_BUTTON_EXTRA:Int
static inline var MOUSE_BUTTON_FORWARD:Int
static inline var MOUSE_BUTTON_BACK:Int
static inline var GAMEPAD_BUTTON_UNKNOWN:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_UP:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_RIGHT:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_DOWN:Int
static inline var GAMEPAD_BUTTON_LEFT_FACE_LEFT:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_UP:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_RIGHT:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_DOWN:Int
static inline var GAMEPAD_BUTTON_RIGHT_FACE_LEFT:Int
static inline var GAMEPAD_BUTTON_LEFT_TRIGGER_1:Int
static inline var GAMEPAD_BUTTON_LEFT_TRIGGER_2:Int
static inline var GAMEPAD_BUTTON_RIGHT_TRIGGER_1:Int
static inline var GAMEPAD_BUTTON_RIGHT_TRIGGER_2:Int
static inline var GAMEPAD_BUTTON_MIDDLE_LEFT:Int
static inline var GAMEPAD_BUTTON_MIDDLE:Int
static inline var GAMEPAD_BUTTON_MIDDLE_RIGHT:Int
static inline var GAMEPAD_BUTTON_LEFT_THUMB:Int
static inline var GAMEPAD_BUTTON_RIGHT_THUMB:Int
static inline var GAMEPAD_AXIS_LEFT_X:Int
static inline var GAMEPAD_AXIS_LEFT_Y:Int
static inline var GAMEPAD_AXIS_RIGHT_X:Int
static inline var GAMEPAD_AXIS_RIGHT_Y:Int
static inline var GAMEPAD_AXIS_LEFT_TRIGGER:Int
static inline var GAMEPAD_AXIS_RIGHT_TRIGGER:Int
static inline var FLAG_VSYNC_HINT:Int
static inline var FLAG_FULLSCREEN_MODE:Int
static inline var FLAG_WINDOW_RESIZABLE:Int
static inline var FLAG_WINDOW_UNDECORATED:Int
static inline var FLAG_WINDOW_HIDDEN:Int
static inline var FLAG_WINDOW_MINIMIZED:Int
static inline var FLAG_WINDOW_MAXIMIZED:Int
static inline var FLAG_WINDOW_UNFOCUSED:Int
static inline var FLAG_WINDOW_TOPMOST:Int
static inline var FLAG_WINDOW_ALWAYS_RUN:Int
static inline var FLAG_WINDOW_TRANSPARENT:Int
static inline var FLAG_WINDOW_HIGHDPI:Int
static inline var FLAG_WINDOW_MOUSE_PASSTHROUGH:Int
static inline var FLAG_BORDERLESS_WINDOWED_MODE:Int
static inline var FLAG_MSAA_4X_HINT:Int
static inline var FLAG_INTERLACED_HINT:Int
static inline var GESTURE_NONE:Int
static inline var GESTURE_TAP:Int
static inline var GESTURE_DOUBLETAP:Int
static inline var GESTURE_HOLD:Int
static inline var GESTURE_DRAG:Int
static inline var GESTURE_SWIPE_RIGHT:Int
static inline var GESTURE_SWIPE_LEFT:Int
static inline var GESTURE_SWIPE_UP:Int
static inline var GESTURE_SWIPE_DOWN:Int
static inline var GESTURE_PINCH_IN:Int
static inline var GESTURE_PINCH_OUT:Int
static final LIGHTGRAY(default, null):Color
static final GRAY(default, null):Color
static final DARKGRAY(default, null):Color
static final YELLOW(default, null):Color
static final GOLD(default, null):Color
static final ORANGE(default, null):Color
static final PINK(default, null):Color
static final RED(default, null):Color
static final MAROON(default, null):Color
static final GREEN(default, null):Color
static final LIME(default, null):Color
static final DARKGREEN(default, null):Color
static final SKYBLUE(default, null):Color
static final BLUE(default, null):Color
static final DARKBLUE(default, null):Color
static final PURPLE(default, null):Color
static final VIOLET(default, null):Color
static final DARKPURPLE(default, null):Color
static final BEIGE(default, null):Color
static final BROWN(default, null):Color
static final DARKBROWN(default, null):Color
static final WHITE(default, null):Color
static final BLACK(default, null):Color
static final BLANK(default, null):Color
static final MAGENTA(default, null):Color
static final RAYWHITE(default, null):Color
static inline var PIXELFORMAT_UNCOMPRESSED_R8G8B8A8:Int
static inline var PI:Float
static inline var DEG2RAD:Float
static inline var RAD2DEG:Float
static function InitWindow(width:Int, height:Int, title:String):Void
static function CloseWindow():Void
static function WindowShouldClose():Bool
static function IsWindowReady():Bool
static function IsWindowResized():Bool
static function SetWindowTitle(title:String):Void
static function SetWindowSize(width:Int, height:Int):Void
static function GetScreenWidth():Int
static function GetScreenHeight():Int
static function GetRenderWidth():Int
static function GetRenderHeight():Int
static function SetConfigFlags(flags:Int):Void
static function SetTargetFPS(fps:Int):Void
static function GetFPS():Int
static function GetFrameTime():Float
static function GetTime():Float
static function SetExitKey(key:Int):Void
static function BeginDrawing():Void
static function EndDrawing():Void
static function ClearBackground(color:Color):Void
static function GetRandomValue(min:Int, max:Int):Int
static function SetRandomSeed(seed:Int):Void
static function IsKeyPressed(key:Int):Bool
static function IsKeyDown(key:Int):Bool
static function IsKeyReleased(key:Int):Bool
static function IsKeyUp(key:Int):Bool
static function GetKeyPressed():Int
static function IsMouseButtonPressed(button:Int):Bool
static function IsMouseButtonDown(button:Int):Bool
static function IsMouseButtonReleased(button:Int):Bool
static function IsMouseButtonUp(button:Int):Bool
static function GetMouseX():Int
static function GetMouseY():Int
static function GetMousePosition():Vector2
static function GetMouseWheelMove():Float
static function GetTouchPointCount():Int
static function GetTouchPosition(index:Int):Vector2
static function GetTouchX():Int
static function GetTouchY():Int
static function IsGestureDetected(gesture:Int):Bool
static function IsGamepadAvailable(gamepad:Int):Bool
static function GetGamepadName(gamepad:Int):String
static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool
static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool
static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool
static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool
static function GetGamepadButtonPressed():Int
static function GetGamepadAxisCount(gamepad:Int):Int
static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float
static function DrawPixel(posX:Int, posY:Int, color:Color):Void
static function DrawPixelV(position:Vector2, color:Color):Void
static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void
static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void
static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void
static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void
static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void
static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void
static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void
static function DrawRectangleRec(rec:Rectangle, color:Color):Void
static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void
static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void
static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void
static function CheckCollisionRecs(rec1:Rectangle, rec2:Rectangle):Bool
static function CheckCollisionCircles(center1:Vector2, radius1:Float, center2:Vector2, radius2:Float):Bool
static function CheckCollisionCircleRec(center:Vector2, radius:Float, rec:Rectangle):Bool
static function CheckCollisionPointRec(point:Vector2, rec:Rectangle):Bool
static function CheckCollisionPointCircle(point:Vector2, center:Vector2, radius:Float):Bool
static function LoadTexture(fileName:String):Texture2D
static function UnloadTexture(texture:Texture2D):Void
static function IsTextureValid(texture:Texture2D):Bool
static function DrawTexture(texture:Texture2D, posX:Int, posY:Int, tint:Color):Void
static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void
static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void
static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void
static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void
static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function MeasureText(text:String, fontSize:Int):Int
static function DrawFPS(posX:Int, posY:Int):Void
static function InitAudioDevice():Void
static function CloseAudioDevice():Void
static function IsAudioDeviceReady():Bool
static function SetMasterVolume(volume:Float):Void
static function LoadSound(fileName:String):Sound
static function UnloadSound(sound:Sound):Void
static function IsSoundValid(sound:Sound):Bool
static function PlaySound(sound:Sound):Void
static function StopSound(sound:Sound):Void
static function IsSoundPlaying(sound:Sound):Bool
static function SetSoundVolume(sound:Sound, volume:Float):Void
static function FileExists(fileName:String):Bool
static function LoadFileText(fileName:String):Null<String>
static function UnloadFileText(text:Null<String>):Void
static function SaveFileText(fileName:String, text:String):Bool
static function Fade(color:Color, alpha:Float):Color
static function ColorAlpha(color:Color, alpha:Float):Color
static function Clamp(value:Float, min:Float, max:Float):Float
static function Lerp(start:Float, end:Float, amount:Float):Float
static function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float
static function Vector2Zero():Vector2
static function Vector2One():Vector2
static function Vector2Add(v1:Vector2, v2:Vector2):Vector2
static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2
static function Vector2Scale(v:Vector2, scale:Float):Vector2
static function Vector2Multiply(v1:Vector2, v2:Vector2):Vector2
static function Vector2Length(v:Vector2):Float
static function Vector2LengthSqr(v:Vector2):Float
static function Vector2Distance(v1:Vector2, v2:Vector2):Float
static function Vector2Normalize(v:Vector2):Vector2
static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2
static function Vector2ClampValue(v:Vector2, min:Float, max:Float):Vector2
```

- `KEY_NULL`: Key: NULL, used for no key pressed.
- `KEY_APOSTROPHE`: Key: '.
- `KEY_COMMA`: Key: ,.
- `KEY_MINUS`: Key: -.
- `KEY_PERIOD`: Key: .
- `KEY_SLASH`: Key: /.
- `KEY_ZERO`: Key: 0.
- `KEY_ONE`: Key: 1.
- `KEY_TWO`: Key: 2.
- `KEY_THREE`: Key: 3.
- `KEY_FOUR`: Key: 4.
- `KEY_FIVE`: Key: 5.
- `KEY_SIX`: Key: 6.
- `KEY_SEVEN`: Key: 7.
- `KEY_EIGHT`: Key: 8.
- `KEY_NINE`: Key: 9.
- `KEY_SEMICOLON`: Key: ;.
- `KEY_EQUAL`: Key: =.
- `KEY_A`: Key: A | a.
- `KEY_B`: Key: B | b.
- `KEY_C`: Key: C | c.
- `KEY_D`: Key: D | d.
- `KEY_E`: Key: E | e.
- `KEY_F`: Key: F | f.
- `KEY_G`: Key: G | g.
- `KEY_H`: Key: H | h.
- `KEY_I`: Key: I | i.
- `KEY_J`: Key: J | j.
- `KEY_K`: Key: K | k.
- `KEY_L`: Key: L | l.
- `KEY_M`: Key: M | m.
- `KEY_N`: Key: N | n.
- `KEY_O`: Key: O | o.
- `KEY_P`: Key: P | p.
- `KEY_Q`: Key: Q | q.
- `KEY_R`: Key: R | r.
- `KEY_S`: Key: S | s.
- `KEY_T`: Key: T | t.
- `KEY_U`: Key: U | u.
- `KEY_V`: Key: V | v.
- `KEY_W`: Key: W | w.
- `KEY_X`: Key: X | x.
- `KEY_Y`: Key: Y | y.
- `KEY_Z`: Key: Z | z.
- `KEY_LEFT_BRACKET`: Key: [.
- `KEY_BACKSLASH`: Key: '\'.
- `KEY_RIGHT_BRACKET`: Key: ].
- `KEY_GRAVE`: Key: `.
- `KEY_SPACE`: Key: Space.
- `KEY_ESCAPE`: Key: Esc.
- `KEY_ENTER`: Key: Enter.
- `KEY_TAB`: Key: Tab.
- `KEY_BACKSPACE`: Key: Backspace.
- `KEY_INSERT`: Key: Ins.
- `KEY_DELETE`: Key: Del.
- `KEY_RIGHT`: Key: Cursor right.
- `KEY_LEFT`: Key: Cursor left.
- `KEY_DOWN`: Key: Cursor down.
- `KEY_UP`: Key: Cursor up.
- `KEY_PAGE_UP`: Key: Page up.
- `KEY_PAGE_DOWN`: Key: Page down.
- `KEY_HOME`: Key: Home.
- `KEY_END`: Key: End.
- `KEY_CAPS_LOCK`: Key: Caps lock.
- `KEY_SCROLL_LOCK`: Key: Scroll down.
- `KEY_NUM_LOCK`: Key: Num lock.
- `KEY_PRINT_SCREEN`: Key: Print screen.
- `KEY_PAUSE`: Key: Pause.
- `KEY_F1`: Key: F1.
- `KEY_F2`: Key: F2.
- `KEY_F3`: Key: F3.
- `KEY_F4`: Key: F4.
- `KEY_F5`: Key: F5.
- `KEY_F6`: Key: F6.
- `KEY_F7`: Key: F7.
- `KEY_F8`: Key: F8.
- `KEY_F9`: Key: F9.
- `KEY_F10`: Key: F10.
- `KEY_F11`: Key: F11.
- `KEY_F12`: Key: F12.
- `KEY_LEFT_SHIFT`: Key: Shift left.
- `KEY_LEFT_CONTROL`: Key: Control left.
- `KEY_LEFT_ALT`: Key: Alt left.
- `KEY_LEFT_SUPER`: Key: Super left.
- `KEY_RIGHT_SHIFT`: Key: Shift right.
- `KEY_RIGHT_CONTROL`: Key: Control right.
- `KEY_RIGHT_ALT`: Key: Alt right.
- `KEY_RIGHT_SUPER`: Key: Super right.
- `KEY_KB_MENU`: Key: KB menu.
- `KEY_KP_0`: Key: Keypad 0.
- `KEY_KP_1`: Key: Keypad 1.
- `KEY_KP_2`: Key: Keypad 2.
- `KEY_KP_3`: Key: Keypad 3.
- `KEY_KP_4`: Key: Keypad 4.
- `KEY_KP_5`: Key: Keypad 5.
- `KEY_KP_6`: Key: Keypad 6.
- `KEY_KP_7`: Key: Keypad 7.
- `KEY_KP_8`: Key: Keypad 8.
- `KEY_KP_9`: Key: Keypad 9.
- `KEY_KP_DECIMAL`: Key: Keypad .
- `KEY_KP_DIVIDE`: Key: Keypad /.
- `KEY_KP_MULTIPLY`: Key: Keypad *.
- `KEY_KP_SUBTRACT`: Key: Keypad -.
- `KEY_KP_ADD`: Key: Keypad +.
- `KEY_KP_ENTER`: Key: Keypad Enter.
- `KEY_KP_EQUAL`: Key: Keypad =.
- `KEY_BACK`: Key: Android back button.
- `KEY_MENU`: Key: Android menu button.
- `KEY_VOLUME_UP`: Key: Android volume up button.
- `KEY_VOLUME_DOWN`: Key: Android volume down button.
- `MOUSE_BUTTON_LEFT`: Mouse button left.
- `MOUSE_BUTTON_RIGHT`: Mouse button right.
- `MOUSE_BUTTON_MIDDLE`: Mouse button middle (pressed wheel).
- `MOUSE_BUTTON_SIDE`: Mouse button side (advanced mouse device).
- `MOUSE_BUTTON_EXTRA`: Mouse button extra (advanced mouse device).
- `MOUSE_BUTTON_FORWARD`: Mouse button forward (advanced mouse device).
- `MOUSE_BUTTON_BACK`: Mouse button back (advanced mouse device).
- `GAMEPAD_BUTTON_UNKNOWN`: Unknown button, just for error checking.
- `GAMEPAD_BUTTON_LEFT_FACE_UP`: Gamepad left DPAD up button.
- `GAMEPAD_BUTTON_LEFT_FACE_RIGHT`: Gamepad left DPAD right button.
- `GAMEPAD_BUTTON_LEFT_FACE_DOWN`: Gamepad left DPAD down button.
- `GAMEPAD_BUTTON_LEFT_FACE_LEFT`: Gamepad left DPAD left button.
- `GAMEPAD_BUTTON_RIGHT_FACE_UP`: Gamepad right button up (i.e. PS3: Triangle, Xbox: Y).
- `GAMEPAD_BUTTON_RIGHT_FACE_RIGHT`: Gamepad right button right (i.e. PS3: Circle, Xbox: B).
- `GAMEPAD_BUTTON_RIGHT_FACE_DOWN`: Gamepad right button down (i.e. PS3: Cross, Xbox: A).
- `GAMEPAD_BUTTON_RIGHT_FACE_LEFT`: Gamepad right button left (i.e. PS3: Square, Xbox: X).
- `GAMEPAD_BUTTON_LEFT_TRIGGER_1`: Gamepad top/back trigger left (first), it could be a trailing button.
- `GAMEPAD_BUTTON_LEFT_TRIGGER_2`: Gamepad top/back trigger left (second), it could be a trailing button.
- `GAMEPAD_BUTTON_RIGHT_TRIGGER_1`: Gamepad top/back trigger right (first), it could be a trailing button.
- `GAMEPAD_BUTTON_RIGHT_TRIGGER_2`: Gamepad top/back trigger right (second), it could be a trailing button.
- `GAMEPAD_BUTTON_MIDDLE_LEFT`: Gamepad center buttons, left one (i.e. PS3: Select).
- `GAMEPAD_BUTTON_MIDDLE`: Gamepad center buttons, middle one (i.e. PS3: PS, Xbox: XBOX).
- `GAMEPAD_BUTTON_MIDDLE_RIGHT`: Gamepad center buttons, right one (i.e. PS3: Start).
- `GAMEPAD_BUTTON_LEFT_THUMB`: Gamepad joystick pressed button left.
- `GAMEPAD_BUTTON_RIGHT_THUMB`: Gamepad joystick pressed button right.
- `GAMEPAD_AXIS_LEFT_X`: Gamepad left stick X axis.
- `GAMEPAD_AXIS_LEFT_Y`: Gamepad left stick Y axis.
- `GAMEPAD_AXIS_RIGHT_X`: Gamepad right stick X axis.
- `GAMEPAD_AXIS_RIGHT_Y`: Gamepad right stick Y axis.
- `GAMEPAD_AXIS_LEFT_TRIGGER`: Gamepad back trigger left, pressure level: [1..-1].
- `GAMEPAD_AXIS_RIGHT_TRIGGER`: Gamepad back trigger right, pressure level: [1..-1].
- `FLAG_VSYNC_HINT`: Set to try enabling V-Sync on GPU.
- `FLAG_FULLSCREEN_MODE`: Set to run program in fullscreen.
- `FLAG_WINDOW_RESIZABLE`: Set to allow resizable window.
- `FLAG_WINDOW_UNDECORATED`: Set to disable window decoration (frame and buttons).
- `FLAG_WINDOW_HIDDEN`: Set to hide window.
- `FLAG_WINDOW_MINIMIZED`: Set to minimize window (iconify).
- `FLAG_WINDOW_MAXIMIZED`: Set to maximize window (expanded to monitor).
- `FLAG_WINDOW_UNFOCUSED`: Set to window non focused.
- `FLAG_WINDOW_TOPMOST`: Set to window always on top.
- `FLAG_WINDOW_ALWAYS_RUN`: Set to allow windows running while minimized.
- `FLAG_WINDOW_TRANSPARENT`: Set to allow transparent framebuffer.
- `FLAG_WINDOW_HIGHDPI`: Set to support HighDPI.
- `FLAG_WINDOW_MOUSE_PASSTHROUGH`: Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED.
- `FLAG_BORDERLESS_WINDOWED_MODE`: Set to run program in borderless windowed mode.
- `FLAG_MSAA_4X_HINT`: Set to try enabling MSAA 4X.
- `FLAG_INTERLACED_HINT`: Set to try enabling interlaced video format (for V3D).
- `GESTURE_NONE`: No gesture.
- `GESTURE_TAP`: Tap gesture.
- `GESTURE_DOUBLETAP`: Double tap gesture.
- `GESTURE_HOLD`: Hold gesture.
- `GESTURE_DRAG`: Drag gesture.
- `GESTURE_SWIPE_RIGHT`: Swipe right gesture.
- `GESTURE_SWIPE_LEFT`: Swipe left gesture.
- `GESTURE_SWIPE_UP`: Swipe up gesture.
- `GESTURE_SWIPE_DOWN`: Swipe down gesture.
- `GESTURE_PINCH_IN`: Pinch in gesture.
- `GESTURE_PINCH_OUT`: Pinch out gesture.
- `LIGHTGRAY`: Light Gray.
- `GRAY`: Gray.
- `DARKGRAY`: Dark Gray.
- `YELLOW`: Yellow.
- `GOLD`: Gold.
- `ORANGE`: Orange.
- `PINK`: Pink.
- `RED`: Red.
- `MAROON`: Maroon.
- `GREEN`: Green.
- `LIME`: Lime.
- `DARKGREEN`: Dark Green.
- `SKYBLUE`: Sky Blue.
- `BLUE`: Blue.
- `DARKBLUE`: Dark Blue.
- `PURPLE`: Purple.
- `VIOLET`: Violet.
- `DARKPURPLE`: Dark Purple.
- `BEIGE`: Beige.
- `BROWN`: Brown.
- `DARKBROWN`: Dark Brown.
- `WHITE`: White.
- `BLACK`: Black.
- `BLANK`: Blank (Transparent).
- `MAGENTA`: Magenta.
- `RAYWHITE`: My own White (raylib logo).
- `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`: The pixel format of every texture loaded here: 8-bit red, green, blue and alpha.
- `PI`: Pi.
- `DEG2RAD`: Degrees to radians.
- `RAD2DEG`: Radians to degrees.
- `InitWindow`: Opens the window and its graphics. In a page the canvas fills the page, and width and height are ignored.
  - `width`: The window's width, in pixels.
  - `height`: The window's height, in pixels.
  - `title`: The window's title.
- `CloseWindow`: Closes the window, after keeping what `SaveFileText` wrote.
- `WindowShouldClose`: Returns whether the window should close: the exit key was pressed (Escape unless `SetExitKey` changed it) or it was asked to close. In a page it is always false; the loop that reads it runs once a frame there.
  - returns: True once the window should close.
- `IsWindowReady`: Returns whether the window is open.
  - returns: True after `InitWindow`.
- `IsWindowResized`: Returns whether the window changed size since the last frame.
  - returns: True for the frame after a resize.
- `SetWindowTitle`: Sets the window's title.
  - `title`: The title.
- `SetWindowSize`: Asks for the window's size. A page's canvas follows the page instead.
  - `width`: The width, in pixels.
  - `height`: The height, in pixels.
- `GetScreenWidth`: Returns the screen's width, in the pixels drawing is in.
  - returns: The width.
- `GetScreenHeight`: Returns the screen's height, in the pixels drawing is in.
  - returns: The height.
- `GetRenderWidth`: Returns the framebuffer's width, in the display's pixels.
  - returns: The width.
- `GetRenderHeight`: Returns the framebuffer's height, in the display's pixels.
  - returns: The height.
- `SetConfigFlags`: Sets flags for the window before `InitWindow` (`FLAG_*`). The window is resizable here whatever they say.
  - `flags`: The flags, or'd together.
- `SetTargetFPS`: Sets the frame rate aimed for. Frames here follow the display's refresh, whatever it is set to.
  - `fps`: The frames a second.
- `GetFPS`: Returns the frames a second, averaged over the last half second or so.
  - returns: The frames a second.
- `GetFrameTime`: Returns the seconds the last frame took.
  - returns: The seconds.
- `GetTime`: Returns the seconds since `InitWindow`.
  - returns: The seconds.
- `SetExitKey`: Sets the key that closes the window natively, or `KEY_NULL` for none. It is Escape until set.
  - `key`: The key.
- `BeginDrawing`: Begins a frame's drawing.
- `EndDrawing`: Ends a frame's drawing: shows it, then reads the next frame's input.
- `ClearBackground`: Clears the frame to a color, dropping what was drawn before it.
  - `color`: The color.
- `GetRandomValue`: Returns a random whole number from min to max, both included.
  - `min`: The least.
  - `max`: The most.
  - returns: The number.
- `SetRandomSeed`: Seeds `GetRandomValue`, so its numbers repeat from the same seed.
  - `seed`: The seed.
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
- `GetKeyPressed`: Returns the next key pressed this frame, each once; call it until it returns `KEY_NULL`.
  - returns: The key (`KEY_*`), or `KEY_NULL` when no more were pressed.
- `IsMouseButtonPressed`: Returns whether a mouse button went down this frame. A finger touching counts as the left button, as in raylib.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True for that frame alone.
- `IsMouseButtonDown`: Returns whether a mouse button is held. A finger down counts as the left button.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True while it is down.
- `IsMouseButtonReleased`: Returns whether a mouse button went up this frame. The last finger lifting counts as the left button.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True for that frame alone.
- `IsMouseButtonUp`: Returns whether a mouse button isn't held.
  - `button`: The button (`MOUSE_BUTTON_*`).
  - returns: True while it is up.
- `GetMouseX`: Returns the mouse's x, in the screen's pixels; the first finger's while one is down.
  - returns: The x.
- `GetMouseY`: Returns the mouse's y, in the screen's pixels; the first finger's while one is down.
  - returns: The y.
- `GetMousePosition`: Returns the mouse's position, in the screen's pixels; the first finger's while one is down.
  - returns: The position.
- `GetMouseWheelMove`: Returns how far the wheel turned this frame, the larger of its two directions; away from the player is positive.
  - returns: The notches.
- `GetTouchPointCount`: Returns the number of fingers down.
  - returns: The count.
- `GetTouchPosition`: Returns a finger's position, in the screen's pixels.
  - `index`: Which finger, 0 for the first down.
  - returns: The position, or (0, 0) when fewer are down.
- `GetTouchX`: Returns the first finger's x, in the screen's pixels.
  - returns: The x.
- `GetTouchY`: Returns the first finger's y, in the screen's pixels.
  - returns: The y.
- `IsGestureDetected`: Returns whether a gesture happened this frame. Only `GESTURE_TAP` is read here: a finger touching, or the left mouse button pressed, as raylib counts it.
  - `gesture`: The gesture (`GESTURE_*`).
  - returns: True for the frame it happened.
- `IsGamepadAvailable`: Returns whether a gamepad is connected.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: True while one is connected there.
- `GetGamepadName`: Returns a gamepad's name.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: Its name, or "" when none is connected.
- `IsGamepadButtonPressed`: Returns whether a gamepad's button went down this frame.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True for that frame alone.
- `IsGamepadButtonDown`: Returns whether a gamepad's button is held.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True while it is down.
- `IsGamepadButtonReleased`: Returns whether a gamepad's button went up this frame.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True for that frame alone.
- `IsGamepadButtonUp`: Returns whether a gamepad's button isn't held.
  - `gamepad`: The gamepad, 0 to 3.
  - `button`: The button (`GAMEPAD_BUTTON_*`).
  - returns: True while it is up.
- `GetGamepadButtonPressed`: Returns a button held on any gamepad, as raylib's last button pressed is: set while it is held, not only as it goes down.
  - returns: The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held.
- `GetGamepadAxisCount`: Returns the number of axes a gamepad has.
  - `gamepad`: The gamepad, 0 to 3.
  - returns: 6 while one is connected, else 0.
- `GetGamepadAxisMovement`: Returns how far a gamepad's axis is pushed, with no dead zone. A stick is -1 to 1, down and right positive; a trigger is -1 released to 1 pulled, as raylib's are.
  - `gamepad`: The gamepad, 0 to 3.
  - `axis`: The axis (`GAMEPAD_AXIS_*`).
  - returns: The value.
- `DrawPixel`: Draws one pixel.
  - `posX`: The x.
  - `posY`: The y.
  - `color`: The color.
- `DrawPixelV`: Draws one pixel.
  - `position`: The position.
  - `color`: The color.
- `DrawLine`: Draws a line one pixel wide.
  - `startPosX`: The start's x.
  - `startPosY`: The start's y.
  - `endPosX`: The end's x.
  - `endPosY`: The end's y.
  - `color`: The color.
- `DrawLineV`: Draws a line one pixel wide.
  - `startPos`: The start.
  - `endPos`: The end.
  - `color`: The color.
- `DrawLineEx`: Draws a line of a thickness.
  - `startPos`: The start.
  - `endPos`: The end.
  - `thick`: The thickness, in pixels.
  - `color`: The color.
- `DrawCircle`: Draws a filled circle.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleV`: Draws a filled circle.
  - `center`: The center.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleLines`: Draws a circle's outline, one pixel wide.
  - `centerX`: The center's x.
  - `centerY`: The center's y.
  - `radius`: The radius.
  - `color`: The color.
- `DrawCircleLinesV`: Draws a circle's outline, one pixel wide.
  - `center`: The center.
  - `radius`: The radius.
  - `color`: The color.
- `DrawRectangle`: Draws a filled rectangle.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
- `DrawRectangleV`: Draws a filled rectangle.
  - `position`: The top-left corner.
  - `size`: The width and height.
  - `color`: The color.
- `DrawRectangleRec`: Draws a filled rectangle.
  - `rec`: The rectangle.
  - `color`: The color.
- `DrawRectangleLines`: Draws a rectangle's outline, one pixel wide.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `width`: The width.
  - `height`: The height.
  - `color`: The color.
- `DrawRectangleLinesEx`: Draws a rectangle's outline, its lines inside it.
  - `rec`: The rectangle.
  - `lineThick`: The lines' thickness.
  - `color`: The color.
- `DrawTriangle`: Draws a filled triangle; its points go counterclockwise, as raylib's do.
  - `v1`: The first point.
  - `v2`: The second point.
  - `v3`: The third point.
  - `color`: The color.
- `CheckCollisionRecs`: Returns whether two rectangles overlap.
  - `rec1`: One rectangle.
  - `rec2`: The other.
  - returns: True when they overlap.
- `CheckCollisionCircles`: Returns whether two circles overlap.
  - `center1`: One circle's center.
  - `radius1`: Its radius.
  - `center2`: The other's center.
  - `radius2`: Its radius.
  - returns: True when they overlap.
- `CheckCollisionCircleRec`: Returns whether a circle and a rectangle overlap.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - `rec`: The rectangle.
  - returns: True when they overlap.
- `CheckCollisionPointRec`: Returns whether a point is inside a rectangle.
  - `point`: The point.
  - `rec`: The rectangle.
  - returns: True when it is inside.
- `CheckCollisionPointCircle`: Returns whether a point is inside a circle.
  - `point`: The point.
  - `center`: The circle's center.
  - `radius`: Its radius.
  - returns: True when it is inside.
- `LoadTexture`: Loads an image file as a texture. The program's files are loaded before `main`, so it is ready at once.
  - `fileName`: The file, as the program names it, such as "assets/player.png".
  - returns: The texture; its `id` is 0 when the file couldn't be read.
- `UnloadTexture`: Frees a texture.
  - `texture`: The texture.
- `IsTextureValid`: Returns whether a texture was loaded.
  - `texture`: The texture.
  - returns: True when it holds an image.
- `DrawTexture`: Draws a texture, its top-left corner at a point.
  - `texture`: The texture.
  - `posX`: The x.
  - `posY`: The y.
  - `tint`: The color it is multiplied by; `WHITE` keeps it as it is.
- `DrawTextureV`: Draws a texture, its top-left corner at a point.
  - `texture`: The texture.
  - `position`: The point.
  - `tint`: The color it is multiplied by.
- `DrawTextureEx`: Draws a texture turned about its top-left corner and scaled.
  - `texture`: The texture.
  - `position`: The top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `scale`: The scale.
  - `tint`: The color it is multiplied by.
- `DrawTextureRec`: Draws part of a texture. A negative source width or height flips it.
  - `texture`: The texture.
  - `source`: The part, in the texture's pixels.
  - `position`: Where its top-left corner goes.
  - `tint`: The color it is multiplied by.
- `DrawTexturePro`: Draws part of a texture into a rectangle, turned about an origin. A negative source width or height flips it.
  - `texture`: The texture.
  - `source`: The part, in the texture's pixels.
  - `dest`: Where it goes; its x and y are where the origin lands.
  - `origin`: The point it turns about, from dest's top-left corner.
  - `rotation`: Clockwise, in degrees.
  - `tint`: The color it is multiplied by.
- `DrawText`: Draws text in raylib's default font. A size under 10 is drawn at 10, and letters are a tenth of the size apart.
  - `text`: The text; "\n" starts a line.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `fontSize`: The height of a line, in pixels.
  - `color`: The color.
- `MeasureText`: Returns the width text is drawn at by `DrawText`, its widest line's.
  - `text`: The text.
  - `fontSize`: The height of a line, in pixels.
  - returns: The width, in pixels.
- `DrawFPS`: Draws the frames a second, as "60 FPS", in green.
  - `posX`: The left edge.
  - `posY`: The top edge.
- `InitAudioDevice`: Opens the audio output. In a page it plays once the player's first press lets it.
- `CloseAudioDevice`: Closes the audio output, stopping every sound.
- `IsAudioDeviceReady`: Returns whether the audio output is open.
  - returns: True after `InitAudioDevice`.
- `SetMasterVolume`: Sets the volume of every sound.
  - `volume`: 0 (silent) to 1.
- `LoadSound`: Loads a sound file whole. It decodes in the background; played before then, it starts once decoded.
  - `fileName`: The file, as the program names it, such as "assets/coin.wav".
  - returns: The sound.
- `UnloadSound`: Frees a sound, stopping it.
  - `sound`: The sound.
- `IsSoundValid`: Returns whether a sound was loaded.
  - `sound`: The sound.
  - returns: True once it is decoded.
- `PlaySound`: Plays a sound from its start, restarting it when it is already playing.
  - `sound`: The sound.
- `StopSound`: Stops a sound.
  - `sound`: The sound.
- `IsSoundPlaying`: Returns whether a sound is playing.
  - `sound`: The sound.
  - returns: True while it plays.
- `SetSoundVolume`: Sets a sound's volume, for its next play and the one playing.
  - `sound`: The sound.
  - `volume`: 0 (silent) to 1.
- `FileExists`: Returns whether a file exists: one `SaveFileText` wrote, or one of the program's.
  - `fileName`: The file.
  - returns: True when it exists.
- `LoadFileText`: Reads a text file: one `SaveFileText` wrote, or one of the program's.
  - `fileName`: The file.
  - returns: Its text, or null when it doesn't exist.
- `UnloadFileText`: Frees text `LoadFileText` returned. There is nothing to free here.
  - `text`: The text.
- `SaveFileText`: Writes a text file, kept across runs: in a page, in the page's storage; natively, in the program's data directory. It is kept at the end of the frame.
  - `fileName`: The file.
  - `text`: Its text.
  - returns: True, or false when the saves weren't read.
- `Fade`: Returns a color with its alpha scaled.
  - `color`: The color.
  - `alpha`: 0 (clear) to 1 (as it is).
  - returns: The new color.
- `ColorAlpha`: Returns a color with an alpha.
  - `color`: The color.
  - `alpha`: 0 (clear) to 1 (opaque).
  - returns: The new color.
- `Clamp`: Returns a value kept between two others.
  - `value`: The value.
  - `min`: The least.
  - `max`: The most.
  - returns: The value, at least min and at most max.
- `Lerp`: Returns a value part of the way from one to another.
  - `start`: The start.
  - `end`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The value.
- `Remap`: Returns a value moved from one range to another.
  - `value`: The value.
  - `inputStart`: The first range's start.
  - `inputEnd`: Its end.
  - `outputStart`: The second range's start.
  - `outputEnd`: Its end.
  - returns: The value in the second range.
- `Vector2Zero`: Returns (0, 0).
  - returns: The vector.
- `Vector2One`: Returns (1, 1).
  - returns: The vector.
- `Vector2Add`: Returns the sum of two vectors.
  - `v1`: One.
  - `v2`: The other.
  - returns: The sum.
- `Vector2Subtract`: Returns one vector less another.
  - `v1`: The first.
  - `v2`: The one taken from it.
  - returns: The difference.
- `Vector2Scale`: Returns a vector scaled.
  - `v`: The vector.
  - `scale`: The scale.
  - returns: The scaled vector.
- `Vector2Multiply`: Returns two vectors multiplied component by component.
  - `v1`: One.
  - `v2`: The other.
  - returns: The product.
- `Vector2Length`: Returns a vector's length.
  - `v`: The vector.
  - returns: The length.
- `Vector2LengthSqr`: Returns a vector's length squared.
  - `v`: The vector.
  - returns: The length squared.
- `Vector2Distance`: Returns the distance between two points.
  - `v1`: One.
  - `v2`: The other.
  - returns: The distance.
- `Vector2Normalize`: Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).
  - `v`: The vector.
  - returns: The direction.
- `Vector2Lerp`: Returns a point part of the way from one to another.
  - `v1`: The start.
  - `v2`: The end.
  - `amount`: 0 for the start, 1 for the end.
  - returns: The point.
- `Vector2ClampValue`: Returns a vector with its length kept between two values.
  - `v`: The vector.
  - `min`: The least length.
  - `max`: The most length.
  - returns: The vector.

## Rectangle

*class* in [`ray/src/helix/ray/Rectangle.hx`](../../ray/src/helix/ray/Rectangle.hx), `import helix.ray.Rectangle;`

Represents raylib's `Rectangle`: its top-left corner and its size.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float, ?width:Float, ?height:Float}
```

```haxe
var x:Float
var y:Float
var width:Float
var height:Float
```

- `x`: Gets or sets the left edge.
- `y`: Gets or sets the top edge.
- `width`: Gets or sets the width.
- `height`: Gets or sets the height.

## Sound

*class* in [`ray/src/helix/ray/Sound.hx`](../../ray/src/helix/ray/Sound.hx), `import helix.ray.Sound;`

Represents raylib's `Sound`: a sound held whole, played by `Raylib.PlaySound`.

```haxe
var frameCount(default, null):Int
```

- `frameCount`: Gets the number of frames, 0 until it is decoded.

## Texture2D

*class* in [`ray/src/helix/ray/Texture2D.hx`](../../ray/src/helix/ray/Texture2D.hx), `import helix.ray.Texture2D;`

Represents raylib's `Texture2D`: an image on the GPU.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?id:Int, ?width:Int, ?height:Int, ?mipmaps:Int, ?format:Int}
```

```haxe
var id:Int
var width:Int
var height:Int
var mipmaps:Int
var format:Int
```

- `id`: Gets the texture's handle, 0 for none.
- `width`: Gets the width, in pixels.
- `height`: Gets the height, in pixels.
- `mipmaps`: Gets the number of mipmap levels, 1 for none.
- `format`: Gets the pixel format, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` for every texture loaded here.

## Vector2

*class* in [`ray/src/helix/ray/Vector2.hx`](../../ray/src/helix/ray/Vector2.hx), `import helix.ray.Vector2;`

Represents raylib's `Vector2`: a point or a direction in two dimensions.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?x:Float, ?y:Float}
```

```haxe
var x:Float
var y:Float
```

- `x`: Gets or sets the x component.
- `y`: Gets or sets the y component.
