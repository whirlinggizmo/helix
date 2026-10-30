package helix.ray;

#if macro
import haxe.macro.Expr;
#else
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Matrices;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
#end

/** Provides raylib 5.5's API, as `raylib.h` names it, over helix-platform and helix-services: a program writes raylib, and it runs in
	a page and natively.

	A program's loop is raylib's, `while (!WindowShouldClose()) { BeginDrawing(); ...; EndDrawing(); }`; in a page its body runs once a
	frame. The files under the program's directory are loaded before its `main` runs, so `LoadTexture`, `LoadSound` and `LoadModel`
	answer at once. `SaveFileText` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so
	`LoadShader` names its files with constants. Not here yet: skinned models and animations, fonts other than the default, images on the
	CPU, and the rest of raylib's less used corners. */
class Raylib {
	// ---- Keys (KeyboardKey) ----

	/** Key: NULL, used for no key pressed. */
	public static inline final KEY_NULL = 0;

	/** Key: '. */
	public static inline final KEY_APOSTROPHE = 39;

	/** Key: ,. */
	public static inline final KEY_COMMA = 44;

	/** Key: -. */
	public static inline final KEY_MINUS = 45;

	/** Key: . */
	public static inline final KEY_PERIOD = 46;

	/** Key: /. */
	public static inline final KEY_SLASH = 47;

	/** Key: 0. */
	public static inline final KEY_ZERO = 48;

	/** Key: 1. */
	public static inline final KEY_ONE = 49;

	/** Key: 2. */
	public static inline final KEY_TWO = 50;

	/** Key: 3. */
	public static inline final KEY_THREE = 51;

	/** Key: 4. */
	public static inline final KEY_FOUR = 52;

	/** Key: 5. */
	public static inline final KEY_FIVE = 53;

	/** Key: 6. */
	public static inline final KEY_SIX = 54;

	/** Key: 7. */
	public static inline final KEY_SEVEN = 55;

	/** Key: 8. */
	public static inline final KEY_EIGHT = 56;

	/** Key: 9. */
	public static inline final KEY_NINE = 57;

	/** Key: ;. */
	public static inline final KEY_SEMICOLON = 59;

	/** Key: =. */
	public static inline final KEY_EQUAL = 61;

	/** Key: A | a. */
	public static inline final KEY_A = 65;

	/** Key: B | b. */
	public static inline final KEY_B = 66;

	/** Key: C | c. */
	public static inline final KEY_C = 67;

	/** Key: D | d. */
	public static inline final KEY_D = 68;

	/** Key: E | e. */
	public static inline final KEY_E = 69;

	/** Key: F | f. */
	public static inline final KEY_F = 70;

	/** Key: G | g. */
	public static inline final KEY_G = 71;

	/** Key: H | h. */
	public static inline final KEY_H = 72;

	/** Key: I | i. */
	public static inline final KEY_I = 73;

	/** Key: J | j. */
	public static inline final KEY_J = 74;

	/** Key: K | k. */
	public static inline final KEY_K = 75;

	/** Key: L | l. */
	public static inline final KEY_L = 76;

	/** Key: M | m. */
	public static inline final KEY_M = 77;

	/** Key: N | n. */
	public static inline final KEY_N = 78;

	/** Key: O | o. */
	public static inline final KEY_O = 79;

	/** Key: P | p. */
	public static inline final KEY_P = 80;

	/** Key: Q | q. */
	public static inline final KEY_Q = 81;

	/** Key: R | r. */
	public static inline final KEY_R = 82;

	/** Key: S | s. */
	public static inline final KEY_S = 83;

	/** Key: T | t. */
	public static inline final KEY_T = 84;

	/** Key: U | u. */
	public static inline final KEY_U = 85;

	/** Key: V | v. */
	public static inline final KEY_V = 86;

	/** Key: W | w. */
	public static inline final KEY_W = 87;

	/** Key: X | x. */
	public static inline final KEY_X = 88;

	/** Key: Y | y. */
	public static inline final KEY_Y = 89;

	/** Key: Z | z. */
	public static inline final KEY_Z = 90;

	/** Key: [. */
	public static inline final KEY_LEFT_BRACKET = 91;

	/** Key: '\'. */
	public static inline final KEY_BACKSLASH = 92;

	/** Key: ]. */
	public static inline final KEY_RIGHT_BRACKET = 93;

	/** Key: `. */
	public static inline final KEY_GRAVE = 96;

	/** Key: Space. */
	public static inline final KEY_SPACE = 32;

	/** Key: Esc. */
	public static inline final KEY_ESCAPE = 256;

	/** Key: Enter. */
	public static inline final KEY_ENTER = 257;

	/** Key: Tab. */
	public static inline final KEY_TAB = 258;

	/** Key: Backspace. */
	public static inline final KEY_BACKSPACE = 259;

	/** Key: Ins. */
	public static inline final KEY_INSERT = 260;

	/** Key: Del. */
	public static inline final KEY_DELETE = 261;

	/** Key: Cursor right. */
	public static inline final KEY_RIGHT = 262;

	/** Key: Cursor left. */
	public static inline final KEY_LEFT = 263;

	/** Key: Cursor down. */
	public static inline final KEY_DOWN = 264;

	/** Key: Cursor up. */
	public static inline final KEY_UP = 265;

	/** Key: Page up. */
	public static inline final KEY_PAGE_UP = 266;

	/** Key: Page down. */
	public static inline final KEY_PAGE_DOWN = 267;

	/** Key: Home. */
	public static inline final KEY_HOME = 268;

	/** Key: End. */
	public static inline final KEY_END = 269;

	/** Key: Caps lock. */
	public static inline final KEY_CAPS_LOCK = 280;

	/** Key: Scroll down. */
	public static inline final KEY_SCROLL_LOCK = 281;

	/** Key: Num lock. */
	public static inline final KEY_NUM_LOCK = 282;

	/** Key: Print screen. */
	public static inline final KEY_PRINT_SCREEN = 283;

	/** Key: Pause. */
	public static inline final KEY_PAUSE = 284;

	/** Key: F1. */
	public static inline final KEY_F1 = 290;

	/** Key: F2. */
	public static inline final KEY_F2 = 291;

	/** Key: F3. */
	public static inline final KEY_F3 = 292;

	/** Key: F4. */
	public static inline final KEY_F4 = 293;

	/** Key: F5. */
	public static inline final KEY_F5 = 294;

	/** Key: F6. */
	public static inline final KEY_F6 = 295;

	/** Key: F7. */
	public static inline final KEY_F7 = 296;

	/** Key: F8. */
	public static inline final KEY_F8 = 297;

	/** Key: F9. */
	public static inline final KEY_F9 = 298;

	/** Key: F10. */
	public static inline final KEY_F10 = 299;

	/** Key: F11. */
	public static inline final KEY_F11 = 300;

	/** Key: F12. */
	public static inline final KEY_F12 = 301;

	/** Key: Shift left. */
	public static inline final KEY_LEFT_SHIFT = 340;

	/** Key: Control left. */
	public static inline final KEY_LEFT_CONTROL = 341;

	/** Key: Alt left. */
	public static inline final KEY_LEFT_ALT = 342;

	/** Key: Super left. */
	public static inline final KEY_LEFT_SUPER = 343;

	/** Key: Shift right. */
	public static inline final KEY_RIGHT_SHIFT = 344;

	/** Key: Control right. */
	public static inline final KEY_RIGHT_CONTROL = 345;

	/** Key: Alt right. */
	public static inline final KEY_RIGHT_ALT = 346;

	/** Key: Super right. */
	public static inline final KEY_RIGHT_SUPER = 347;

	/** Key: KB menu. */
	public static inline final KEY_KB_MENU = 348;

	/** Key: Keypad 0. */
	public static inline final KEY_KP_0 = 320;

	/** Key: Keypad 1. */
	public static inline final KEY_KP_1 = 321;

	/** Key: Keypad 2. */
	public static inline final KEY_KP_2 = 322;

	/** Key: Keypad 3. */
	public static inline final KEY_KP_3 = 323;

	/** Key: Keypad 4. */
	public static inline final KEY_KP_4 = 324;

	/** Key: Keypad 5. */
	public static inline final KEY_KP_5 = 325;

	/** Key: Keypad 6. */
	public static inline final KEY_KP_6 = 326;

	/** Key: Keypad 7. */
	public static inline final KEY_KP_7 = 327;

	/** Key: Keypad 8. */
	public static inline final KEY_KP_8 = 328;

	/** Key: Keypad 9. */
	public static inline final KEY_KP_9 = 329;

	/** Key: Keypad . */
	public static inline final KEY_KP_DECIMAL = 330;

	/** Key: Keypad /. */
	public static inline final KEY_KP_DIVIDE = 331;

	/** Key: Keypad *. */
	public static inline final KEY_KP_MULTIPLY = 332;

	/** Key: Keypad -. */
	public static inline final KEY_KP_SUBTRACT = 333;

	/** Key: Keypad +. */
	public static inline final KEY_KP_ADD = 334;

	/** Key: Keypad Enter. */
	public static inline final KEY_KP_ENTER = 335;

	/** Key: Keypad =. */
	public static inline final KEY_KP_EQUAL = 336;

	/** Key: Android back button. */
	public static inline final KEY_BACK = 4;

	/** Key: Android menu button. */
	public static inline final KEY_MENU = 5;

	/** Key: Android volume up button. */
	public static inline final KEY_VOLUME_UP = 24;

	/** Key: Android volume down button. */
	public static inline final KEY_VOLUME_DOWN = 25;

	// ---- Mouse buttons (MouseButton) ----

	/** Mouse button left. */
	public static inline final MOUSE_BUTTON_LEFT = 0;

	/** Mouse button right. */
	public static inline final MOUSE_BUTTON_RIGHT = 1;

	/** Mouse button middle (pressed wheel). */
	public static inline final MOUSE_BUTTON_MIDDLE = 2;

	/** Mouse button side (advanced mouse device). */
	public static inline final MOUSE_BUTTON_SIDE = 3;

	/** Mouse button extra (advanced mouse device). */
	public static inline final MOUSE_BUTTON_EXTRA = 4;

	/** Mouse button forward (advanced mouse device). */
	public static inline final MOUSE_BUTTON_FORWARD = 5;

	/** Mouse button back (advanced mouse device). */
	public static inline final MOUSE_BUTTON_BACK = 6;

	// ---- Gamepad buttons (GamepadButton) ----

	/** Unknown button, just for error checking. */
	public static inline final GAMEPAD_BUTTON_UNKNOWN = 0;

	/** Gamepad left DPAD up button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_UP = 1;

	/** Gamepad left DPAD right button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_RIGHT = 2;

	/** Gamepad left DPAD down button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_DOWN = 3;

	/** Gamepad left DPAD left button. */
	public static inline final GAMEPAD_BUTTON_LEFT_FACE_LEFT = 4;

	/** Gamepad right button up (i.e. PS3: Triangle, Xbox: Y). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_UP = 5;

	/** Gamepad right button right (i.e. PS3: Circle, Xbox: B). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_RIGHT = 6;

	/** Gamepad right button down (i.e. PS3: Cross, Xbox: A). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_DOWN = 7;

	/** Gamepad right button left (i.e. PS3: Square, Xbox: X). */
	public static inline final GAMEPAD_BUTTON_RIGHT_FACE_LEFT = 8;

	/** Gamepad top/back trigger left (first), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_LEFT_TRIGGER_1 = 9;

	/** Gamepad top/back trigger left (second), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_LEFT_TRIGGER_2 = 10;

	/** Gamepad top/back trigger right (first), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_RIGHT_TRIGGER_1 = 11;

	/** Gamepad top/back trigger right (second), it could be a trailing button. */
	public static inline final GAMEPAD_BUTTON_RIGHT_TRIGGER_2 = 12;

	/** Gamepad center buttons, left one (i.e. PS3: Select). */
	public static inline final GAMEPAD_BUTTON_MIDDLE_LEFT = 13;

	/** Gamepad center buttons, middle one (i.e. PS3: PS, Xbox: XBOX). */
	public static inline final GAMEPAD_BUTTON_MIDDLE = 14;

	/** Gamepad center buttons, right one (i.e. PS3: Start). */
	public static inline final GAMEPAD_BUTTON_MIDDLE_RIGHT = 15;

	/** Gamepad joystick pressed button left. */
	public static inline final GAMEPAD_BUTTON_LEFT_THUMB = 16;

	/** Gamepad joystick pressed button right. */
	public static inline final GAMEPAD_BUTTON_RIGHT_THUMB = 17;

	// ---- Gamepad axes (GamepadAxis) ----

	/** Gamepad left stick X axis. */
	public static inline final GAMEPAD_AXIS_LEFT_X = 0;

	/** Gamepad left stick Y axis. */
	public static inline final GAMEPAD_AXIS_LEFT_Y = 1;

	/** Gamepad right stick X axis. */
	public static inline final GAMEPAD_AXIS_RIGHT_X = 2;

	/** Gamepad right stick Y axis. */
	public static inline final GAMEPAD_AXIS_RIGHT_Y = 3;

	/** Gamepad back trigger left, pressure level: [1..-1]. */
	public static inline final GAMEPAD_AXIS_LEFT_TRIGGER = 4;

	/** Gamepad back trigger right, pressure level: [1..-1]. */
	public static inline final GAMEPAD_AXIS_RIGHT_TRIGGER = 5;

	// ---- Window flags (ConfigFlags) ----

	/** Set to try enabling V-Sync on GPU. */
	public static inline final FLAG_VSYNC_HINT = 64;

	/** Set to run program in fullscreen. */
	public static inline final FLAG_FULLSCREEN_MODE = 2;

	/** Set to allow resizable window. */
	public static inline final FLAG_WINDOW_RESIZABLE = 4;

	/** Set to disable window decoration (frame and buttons). */
	public static inline final FLAG_WINDOW_UNDECORATED = 8;

	/** Set to hide window. */
	public static inline final FLAG_WINDOW_HIDDEN = 128;

	/** Set to minimize window (iconify). */
	public static inline final FLAG_WINDOW_MINIMIZED = 512;

	/** Set to maximize window (expanded to monitor). */
	public static inline final FLAG_WINDOW_MAXIMIZED = 1024;

	/** Set to window non focused. */
	public static inline final FLAG_WINDOW_UNFOCUSED = 2048;

	/** Set to window always on top. */
	public static inline final FLAG_WINDOW_TOPMOST = 4096;

	/** Set to allow windows running while minimized. */
	public static inline final FLAG_WINDOW_ALWAYS_RUN = 256;

	/** Set to allow transparent framebuffer. */
	public static inline final FLAG_WINDOW_TRANSPARENT = 16;

	/** Set to support HighDPI. */
	public static inline final FLAG_WINDOW_HIGHDPI = 8192;

	/** Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED. */
	public static inline final FLAG_WINDOW_MOUSE_PASSTHROUGH = 16384;

	/** Set to run program in borderless windowed mode. */
	public static inline final FLAG_BORDERLESS_WINDOWED_MODE = 32768;

	/** Set to try enabling MSAA 4X. */
	public static inline final FLAG_MSAA_4X_HINT = 32;

	/** Set to try enabling interlaced video format (for V3D). */
	public static inline final FLAG_INTERLACED_HINT = 65536;

	// ---- Gestures (Gesture) ----

	/** No gesture. */
	public static inline final GESTURE_NONE = 0;

	/** Tap gesture. */
	public static inline final GESTURE_TAP = 1;

	/** Double tap gesture. */
	public static inline final GESTURE_DOUBLETAP = 2;

	/** Hold gesture. */
	public static inline final GESTURE_HOLD = 4;

	/** Drag gesture. */
	public static inline final GESTURE_DRAG = 8;

	/** Swipe right gesture. */
	public static inline final GESTURE_SWIPE_RIGHT = 16;

	/** Swipe left gesture. */
	public static inline final GESTURE_SWIPE_LEFT = 32;

	/** Swipe up gesture. */
	public static inline final GESTURE_SWIPE_UP = 64;

	/** Swipe down gesture. */
	public static inline final GESTURE_SWIPE_DOWN = 128;

	/** Pinch in gesture. */
	public static inline final GESTURE_PINCH_IN = 256;

	/** Pinch out gesture. */
	public static inline final GESTURE_PINCH_OUT = 512;

	// ---- Material maps (MaterialMapIndex) ----

	/** Albedo material (same as: MATERIAL_MAP_DIFFUSE). */
	public static inline final MATERIAL_MAP_ALBEDO = 0;

	/** Metalness material (same as: MATERIAL_MAP_SPECULAR). */
	public static inline final MATERIAL_MAP_METALNESS = 1;

	/** Normal material. */
	public static inline final MATERIAL_MAP_NORMAL = 2;

	/** Roughness material. */
	public static inline final MATERIAL_MAP_ROUGHNESS = 3;

	/** Ambient occlusion material. */
	public static inline final MATERIAL_MAP_OCCLUSION = 4;

	/** Emission material. */
	public static inline final MATERIAL_MAP_EMISSION = 5;

	/** Heightmap material. */
	public static inline final MATERIAL_MAP_HEIGHT = 6;

	/** Cubemap material (NOTE: Uses GL_TEXTURE_CUBE_MAP). */
	public static inline final MATERIAL_MAP_CUBEMAP = 7;

	/** Irradiance material (NOTE: Uses GL_TEXTURE_CUBE_MAP). */
	public static inline final MATERIAL_MAP_IRRADIANCE = 8;

	/** Prefilter material (NOTE: Uses GL_TEXTURE_CUBE_MAP). */
	public static inline final MATERIAL_MAP_PREFILTER = 9;

	/** Brdf material. */
	public static inline final MATERIAL_MAP_BRDF = 10;

	// ---- Shader locations (ShaderLocationIndex) ----

	/** Shader location: vertex attribute: position. */
	public static inline final SHADER_LOC_VERTEX_POSITION = 0;

	/** Shader location: vertex attribute: texcoord01. */
	public static inline final SHADER_LOC_VERTEX_TEXCOORD01 = 1;

	/** Shader location: vertex attribute: texcoord02. */
	public static inline final SHADER_LOC_VERTEX_TEXCOORD02 = 2;

	/** Shader location: vertex attribute: normal. */
	public static inline final SHADER_LOC_VERTEX_NORMAL = 3;

	/** Shader location: vertex attribute: tangent. */
	public static inline final SHADER_LOC_VERTEX_TANGENT = 4;

	/** Shader location: vertex attribute: color. */
	public static inline final SHADER_LOC_VERTEX_COLOR = 5;

	/** Shader location: matrix uniform: model-view-projection. */
	public static inline final SHADER_LOC_MATRIX_MVP = 6;

	/** Shader location: matrix uniform: view (camera transform). */
	public static inline final SHADER_LOC_MATRIX_VIEW = 7;

	/** Shader location: matrix uniform: projection. */
	public static inline final SHADER_LOC_MATRIX_PROJECTION = 8;

	/** Shader location: matrix uniform: model (transform). */
	public static inline final SHADER_LOC_MATRIX_MODEL = 9;

	/** Shader location: matrix uniform: normal. */
	public static inline final SHADER_LOC_MATRIX_NORMAL = 10;

	/** Shader location: vector uniform: view. */
	public static inline final SHADER_LOC_VECTOR_VIEW = 11;

	/** Shader location: vector uniform: diffuse color. */
	public static inline final SHADER_LOC_COLOR_DIFFUSE = 12;

	/** Shader location: vector uniform: specular color. */
	public static inline final SHADER_LOC_COLOR_SPECULAR = 13;

	/** Shader location: vector uniform: ambient color. */
	public static inline final SHADER_LOC_COLOR_AMBIENT = 14;

	/** Shader location: sampler2d texture: albedo (same as: SHADER_LOC_MAP_DIFFUSE). */
	public static inline final SHADER_LOC_MAP_ALBEDO = 15;

	/** Shader location: sampler2d texture: metalness (same as: SHADER_LOC_MAP_SPECULAR). */
	public static inline final SHADER_LOC_MAP_METALNESS = 16;

	/** Shader location: sampler2d texture: normal. */
	public static inline final SHADER_LOC_MAP_NORMAL = 17;

	/** Shader location: sampler2d texture: roughness. */
	public static inline final SHADER_LOC_MAP_ROUGHNESS = 18;

	/** Shader location: sampler2d texture: occlusion. */
	public static inline final SHADER_LOC_MAP_OCCLUSION = 19;

	/** Shader location: sampler2d texture: emission. */
	public static inline final SHADER_LOC_MAP_EMISSION = 20;

	/** Shader location: sampler2d texture: height. */
	public static inline final SHADER_LOC_MAP_HEIGHT = 21;

	/** Shader location: samplerCube texture: cubemap. */
	public static inline final SHADER_LOC_MAP_CUBEMAP = 22;

	/** Shader location: samplerCube texture: irradiance. */
	public static inline final SHADER_LOC_MAP_IRRADIANCE = 23;

	/** Shader location: samplerCube texture: prefilter. */
	public static inline final SHADER_LOC_MAP_PREFILTER = 24;

	/** Shader location: sampler2d texture: brdf. */
	public static inline final SHADER_LOC_MAP_BRDF = 25;

	/** Shader location: vertex attribute: boneIds. */
	public static inline final SHADER_LOC_VERTEX_BONEIDS = 26;

	/** Shader location: vertex attribute: boneWeights. */
	public static inline final SHADER_LOC_VERTEX_BONEWEIGHTS = 27;

	/** Shader location: array of matrices uniform: boneMatrices. */
	public static inline final SHADER_LOC_BONE_MATRICES = 28;

	// ---- Shader value types (ShaderUniformDataType) ----

	/** Shader uniform type: float. */
	public static inline final SHADER_UNIFORM_FLOAT = 0;

	/** Shader uniform type: vec2 (2 float). */
	public static inline final SHADER_UNIFORM_VEC2 = 1;

	/** Shader uniform type: vec3 (3 float). */
	public static inline final SHADER_UNIFORM_VEC3 = 2;

	/** Shader uniform type: vec4 (4 float). */
	public static inline final SHADER_UNIFORM_VEC4 = 3;

	/** Shader uniform type: int. */
	public static inline final SHADER_UNIFORM_INT = 4;

	/** Shader uniform type: ivec2 (2 int). */
	public static inline final SHADER_UNIFORM_IVEC2 = 5;

	/** Shader uniform type: ivec3 (3 int). */
	public static inline final SHADER_UNIFORM_IVEC3 = 6;

	/** Shader uniform type: ivec4 (4 int). */
	public static inline final SHADER_UNIFORM_IVEC4 = 7;

	/** Shader uniform type: sampler2d. */
	public static inline final SHADER_UNIFORM_SAMPLER2D = 8;

	// ---- Camera modes (CameraMode) ----

	/** Camera custom, controlled by user (UpdateCamera() does nothing). */
	public static inline final CAMERA_CUSTOM = 0;

	/** Camera free mode. */
	public static inline final CAMERA_FREE = 1;

	/** Camera orbital, around target, zoom supported. */
	public static inline final CAMERA_ORBITAL = 2;

	/** Camera first person. */
	public static inline final CAMERA_FIRST_PERSON = 3;

	/** Camera third person. */
	public static inline final CAMERA_THIRD_PERSON = 4;

	// ---- Camera projections (CameraProjection) ----

	/** Perspective projection. */
	public static inline final CAMERA_PERSPECTIVE = 0;

	/** Orthographic projection. */
	public static inline final CAMERA_ORTHOGRAPHIC = 1;

	// ---- Texture filters (TextureFilter) ----

	/** No filter, just pixel approximation. */
	public static inline final TEXTURE_FILTER_POINT = 0;

	/** Linear filtering. */
	public static inline final TEXTURE_FILTER_BILINEAR = 1;

	/** Trilinear filtering (linear with mipmaps). */
	public static inline final TEXTURE_FILTER_TRILINEAR = 2;

	/** Anisotropic filtering 4x. */
	public static inline final TEXTURE_FILTER_ANISOTROPIC_4X = 3;

	/** Anisotropic filtering 8x. */
	public static inline final TEXTURE_FILTER_ANISOTROPIC_8X = 4;

	/** Anisotropic filtering 16x. */
	public static inline final TEXTURE_FILTER_ANISOTROPIC_16X = 5;

	// ---- Colors ----

	/** Light Gray. */
	public static final LIGHTGRAY:Color = new Color(200, 200, 200, 255);

	/** Gray. */
	public static final GRAY:Color = new Color(130, 130, 130, 255);

	/** Dark Gray. */
	public static final DARKGRAY:Color = new Color(80, 80, 80, 255);

	/** Yellow. */
	public static final YELLOW:Color = new Color(253, 249, 0, 255);

	/** Gold. */
	public static final GOLD:Color = new Color(255, 203, 0, 255);

	/** Orange. */
	public static final ORANGE:Color = new Color(255, 161, 0, 255);

	/** Pink. */
	public static final PINK:Color = new Color(255, 109, 194, 255);

	/** Red. */
	public static final RED:Color = new Color(230, 41, 55, 255);

	/** Maroon. */
	public static final MAROON:Color = new Color(190, 33, 55, 255);

	/** Green. */
	public static final GREEN:Color = new Color(0, 228, 48, 255);

	/** Lime. */
	public static final LIME:Color = new Color(0, 158, 47, 255);

	/** Dark Green. */
	public static final DARKGREEN:Color = new Color(0, 117, 44, 255);

	/** Sky Blue. */
	public static final SKYBLUE:Color = new Color(102, 191, 255, 255);

	/** Blue. */
	public static final BLUE:Color = new Color(0, 121, 241, 255);

	/** Dark Blue. */
	public static final DARKBLUE:Color = new Color(0, 82, 172, 255);

	/** Purple. */
	public static final PURPLE:Color = new Color(200, 122, 255, 255);

	/** Violet. */
	public static final VIOLET:Color = new Color(135, 60, 190, 255);

	/** Dark Purple. */
	public static final DARKPURPLE:Color = new Color(112, 31, 126, 255);

	/** Beige. */
	public static final BEIGE:Color = new Color(211, 176, 131, 255);

	/** Brown. */
	public static final BROWN:Color = new Color(127, 106, 79, 255);

	/** Dark Brown. */
	public static final DARKBROWN:Color = new Color(76, 63, 47, 255);

	/** White. */
	public static final WHITE:Color = new Color(255, 255, 255, 255);

	/** Black. */
	public static final BLACK:Color = new Color(0, 0, 0, 255);

	/** Blank (Transparent). */
	public static final BLANK:Color = new Color(0, 0, 0, 0);

	/** Magenta. */
	public static final MAGENTA:Color = new Color(255, 0, 255, 255);

	/** My own White (raylib logo). */
	public static final RAYWHITE:Color = new Color(245, 245, 245, 255);

	/** The diffuse map, the same as `MATERIAL_MAP_ALBEDO`. */
	public static inline final MATERIAL_MAP_DIFFUSE = 0;

	/** The specular map, the same as `MATERIAL_MAP_METALNESS`. */
	public static inline final MATERIAL_MAP_SPECULAR = 1;

	/** The diffuse texture's location, the same as `SHADER_LOC_MAP_ALBEDO`. */
	public static inline final SHADER_LOC_MAP_DIFFUSE = 15;

	/** The specular texture's location, the same as `SHADER_LOC_MAP_METALNESS`. */
	public static inline final SHADER_LOC_MAP_SPECULAR = 16;

	/** The number of a material's maps. */
	public static inline final MAX_MATERIAL_MAPS = 12;

	/** The pixel format of every texture loaded here: 8-bit red, green, blue and alpha. */
	public static inline final PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 = 7;

	/** Pi. */
	public static inline final PI = 3.14159265358979323846;

	/** Degrees to radians. */
	public static inline final DEG2RAD = PI / 180;

	/** Radians to degrees. */
	public static inline final RAD2DEG = 180 / PI;

	// ---- Shaders, compiled as the program builds ----

	/** Loads a shader from raylib GLSL files (330, or 100 for the web), either null for raylib's default stage. They are compiled as the
		program builds, for every target, so their names are constants; the files are found under `-D ray-files` (default `web`), as the
		program's other files are.

		@param vsFileName  The vertex stage's file, or null.
		@param fsFileName  The fragment stage's file, or null.
		@return  The shader. */
	public static macro function LoadShader(vsFileName:Expr, fsFileName:Expr):Expr {
		var vs = helix.ray.internal.ShaderMacro.text(vsFileName, true),
			fs = helix.ray.internal.ShaderMacro.text(fsFileName, true);
		var program = helix.ray.internal.ShaderMacro.program(vs == null ? "default vertex" : vs.name, vs == null ? null : vs.text,
			fs == null ? "default fragment" : fs.name, fs == null ? null : fs.text, haxe.macro.Context.currentPos());
		return macro helix.ray.Raylib.makeShader($program);
	}

	/** Loads a shader from raylib GLSL text, either null for raylib's default stage. It is compiled as the program builds, so the text is
		a constant.

		@param vsCode  The vertex stage's text, or null.
		@param fsCode  The fragment stage's text, or null.
		@return  The shader. */
	public static macro function LoadShaderFromMemory(vsCode:Expr, fsCode:Expr):Expr {
		var vs = helix.ray.internal.ShaderMacro.text(vsCode, false),
			fs = helix.ray.internal.ShaderMacro.text(fsCode, false);
		var program = helix.ray.internal.ShaderMacro.program("vertex text", vs == null ? null : vs.text, "fragment text", fs == null ? null : fs.text,
			haxe.macro.Context.currentPos());
		return macro helix.ray.Raylib.makeShader($program);
	}

	#if !macro
	// ---- Window and frame ----

	/** Opens the window and its graphics. In a page the canvas fills the page, and width and height are ignored.

		@param width  The window's width, in pixels.
		@param height  The window's height, in pixels.
		@param title  The window's title. */
	public static function InitWindow(width:Int, height:Int, title:String):Void {
		Runtime.open(width, height, title);
		start = Runtime.system.getTime();
		// raylib seeds its random numbers from the time, unless SetRandomSeed says otherwise.
		if (!seeded)
			SetRandomSeed(Std.int(Date.now().getTime() % 0x7fffffff));
	}

	/** Closes the window, after keeping what `SaveFileText` wrote. */
	public static function CloseWindow():Void {
		Runtime.close();
	}

	/** Returns whether the window should close: the exit key was pressed (Escape unless `SetExitKey` changed it) or it was asked to close.
		In a page it is always false; the loop that reads it runs once a frame there.

		@return  True once the window should close. */
	public static function WindowShouldClose():Bool {
		return Runtime.shouldClose;
	}

	/** Returns whether the window is open.

		@return  True after `InitWindow`. */
	public static function IsWindowReady():Bool {
		return Runtime.window != null;
	}

	/** Returns whether the window changed size since the last frame.

		@return  True for the frame after a resize. */
	public static function IsWindowResized():Bool {
		return Runtime.resized;
	}

	/** Sets the window's title.

		@param title  The title. */
	public static function SetWindowTitle(title:String):Void {
		Runtime.window.title = title;
	}

	/** Asks for the window's size. A page's canvas follows the page instead.

		@param width  The width, in pixels.
		@param height  The height, in pixels. */
	public static function SetWindowSize(width:Int, height:Int):Void {
		Runtime.window.requestSize(width, height);
	}

	/** Returns the screen's width, in the pixels drawing is in.

		@return  The width. */
	public static function GetScreenWidth():Int {
		return Std.int(Runtime.window.framebufferWidth / Runtime.window.pixelRatio);
	}

	/** Returns the screen's height, in the pixels drawing is in.

		@return  The height. */
	public static function GetScreenHeight():Int {
		return Std.int(Runtime.window.framebufferHeight / Runtime.window.pixelRatio);
	}

	/** Returns the framebuffer's width, in the display's pixels.

		@return  The width. */
	public static function GetRenderWidth():Int {
		return Runtime.window.framebufferWidth;
	}

	/** Returns the framebuffer's height, in the display's pixels.

		@return  The height. */
	public static function GetRenderHeight():Int {
		return Runtime.window.framebufferHeight;
	}

	/** Sets flags for the window before `InitWindow` (`FLAG_*`). The window is resizable here whatever they say.

		@param flags  The flags, or'd together. */
	public static function SetConfigFlags(flags:Int):Void {
		configFlags = flags;
	}

	/** Sets flags on the open window (`FLAG_*`). A window here is resizable whatever they say, and the others aren't read.

		@param flags  The flags, or'd together. */
	public static function SetWindowState(flags:Int):Void {
		configFlags |= flags;
	}

	/** Clears flags on the open window (`FLAG_*`).

		@param flags  The flags, or'd together. */
	public static function ClearWindowState(flags:Int):Void {
		configFlags &= ~flags;
	}

	/** Returns whether flags are set on the window.

		@param flag  The flags, or'd together.
		@return  True when all of them are. */
	public static function IsWindowState(flag:Int):Bool {
		return configFlags & flag == flag;
	}

	/** Sets the frame rate aimed for. Frames here follow the display's refresh, whatever it is set to.

		@param fps  The frames a second. */
	public static function SetTargetFPS(fps:Int):Void {
		targetFps = fps;
	}

	/** Returns the frames a second, averaged over the last half second or so.

		@return  The frames a second. */
	public static function GetFPS():Int {
		var delta = Runtime.time == null ? 0. : Runtime.time.realDelta;
		if (delta > 0)
			fps += (1 / delta - fps) * .1;
		return Math.round(fps);
	}

	/** Returns the seconds the last frame took.

		@return  The seconds. */
	public static function GetFrameTime():Float {
		return Runtime.time == null ? 0 : Runtime.time.realDelta;
	}

	/** Returns the seconds since `InitWindow`.

		@return  The seconds. */
	public static function GetTime():Float {
		return Runtime.system.getTime() - start;
	}

	/** Sets the key that closes the window natively, or `KEY_NULL` for none. It is Escape until set.

		@param key  The key. */
	public static function SetExitKey(key:Int):Void {
		Runtime.exitKey = key;
	}

	/** Begins a frame's drawing. */
	public static function BeginDrawing():Void {
		Runtime.frame.begin(GetScreenWidth(), GetScreenHeight());
	}

	/** Ends a frame's drawing: shows it, then reads the next frame's input. */
	public static function EndDrawing():Void {
		Runtime.endFrame();
	}

	/** Clears the frame to a color, dropping what was drawn before it.

		@param color  The color. */
	public static function ClearBackground(color:Color):Void {
		Runtime.frame.clear((color.a << 24) | (color.r << 16) | (color.g << 8) | color.b);
	}

	/** Returns a random whole number from min to max, both included.

		@param min  The least.
		@param max  The most.
		@return  The number. */
	public static function GetRandomValue(min:Int, max:Int):Int {
		if (min > max) {
			var t = min;
			min = max;
			max = t;
		}
		seed ^= seed << 13;
		seed ^= seed >>> 17;
		seed ^= seed << 5;
		var span = max - min + 1;
		var r = (seed >>> 1) % span;
		return min + r;
	}

	/** Seeds `GetRandomValue`, so its numbers repeat from the same seed.

		@param seed  The seed. */
	public static function SetRandomSeed(seed:Int):Void {
		Raylib.seed = seed == 0 ? 1 : seed;
		seeded = true;
	}

	// ---- Keyboard ----

	/** Returns whether a key went down this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	public static function IsKeyPressed(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyPressed(cast k);
	}

	/** Returns whether a key is held.

		@param key  The key (`KEY_*`).
		@return  True while it is down. */
	public static function IsKeyDown(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyDown(cast k);
	}

	/** Returns whether a key went up this frame.

		@param key  The key (`KEY_*`).
		@return  True for that frame alone. */
	public static function IsKeyReleased(key:Int):Bool {
		var k = toKey(key);
		return k >= 0 && Runtime.keyboard().isKeyReleased(cast k);
	}

	/** Returns whether a key isn't held.

		@param key  The key (`KEY_*`).
		@return  True while it is up. */
	public static function IsKeyUp(key:Int):Bool {
		return !IsKeyDown(key);
	}

	/** Returns the next key pressed this frame, each once; call it until it returns `KEY_NULL`.

		@return  The key (`KEY_*`), or `KEY_NULL` when no more were pressed. */
	public static function GetKeyPressed():Int {
		Runtime.keyboard();
		return Runtime.keysPressed.length == 0 ? KEY_NULL : Runtime.keysPressed.shift();
	}

	// ---- Mouse and touch ----

	/** Returns whether a mouse button went down this frame. A finger touching counts as the left button, as in raylib.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsMouseButtonPressed(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT
			&& Runtime.touch().pressed.length > 0
			&& Runtime.touch().fingers.length == Runtime.touch().pressed.length)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonPressed(cast button);
	}

	/** Returns whether a mouse button is held. A finger down counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True while it is down. */
	public static function IsMouseButtonDown(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT && Runtime.touch().fingers.length > 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonDown(cast button);
	}

	/** Returns whether a mouse button went up this frame. The last finger lifting counts as the left button.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsMouseButtonReleased(button:Int):Bool {
		var mouse = Runtime.mouse();
		if (button == MOUSE_BUTTON_LEFT && Runtime.touch().released.length > 0 && Runtime.touch().fingers.length == 0)
			return true;
		return button >= 0 && button <= 2 && mouse.isButtonReleased(cast button);
	}

	/** Returns whether a mouse button isn't held.

		@param button  The button (`MOUSE_BUTTON_*`).
		@return  True while it is up. */
	public static function IsMouseButtonUp(button:Int):Bool {
		return !IsMouseButtonDown(button);
	}

	/** Returns the mouse's x, in the screen's pixels; the first finger's while one is down.

		@return  The x. */
	public static function GetMouseX():Int {
		return Std.int(GetMousePosition().x);
	}

	/** Returns the mouse's y, in the screen's pixels; the first finger's while one is down.

		@return  The y. */
	public static function GetMouseY():Int {
		return Std.int(GetMousePosition().y);
	}

	/** Returns the mouse's position, in the screen's pixels; the first finger's while one is down.

		@return  The position. */
	public static function GetMousePosition():Vector2 {
		var mouse = Runtime.mouse(),
			touch = Runtime.touch(),
			ratio = Runtime.window.pixelRatio;
		var fingers = touch.fingers.length > 0 ? touch.fingers : touch.released;
		if (fingers.length > 0) {
			lastPointerX = touch.getX(fingers[0]) / ratio;
			lastPointerY = touch.getY(fingers[0]) / ratio;
		} else if (mouse.x != lastMouseX || mouse.y != lastMouseY) {
			lastMouseX = mouse.x;
			lastMouseY = mouse.y;
			lastPointerX = mouse.x / ratio;
			lastPointerY = mouse.y / ratio;
		}
		return new Vector2(lastPointerX, lastPointerY);
	}

	/** Returns how far the wheel turned this frame, the larger of its two directions; away from the player is positive.

		@return  The notches. */
	public static function GetMouseWheelMove():Float {
		var mouse = Runtime.mouse();
		return Math.abs(mouse.wheelX) > Math.abs(mouse.wheelY) ? mouse.wheelX : mouse.wheelY;
	}

	/** Returns the number of fingers down.

		@return  The count. */
	public static function GetTouchPointCount():Int {
		return Runtime.touch().fingers.length;
	}

	/** Returns a finger's position, in the screen's pixels.

		@param index  Which finger, 0 for the first down.
		@return  The position, or (0, 0) when fewer are down. */
	public static function GetTouchPosition(index:Int):Vector2 {
		var touch = Runtime.touch(), ratio = Runtime.window.pixelRatio;
		if (index < 0 || index >= touch.fingers.length)
			return new Vector2();
		var id = touch.fingers[index];
		return new Vector2(touch.getX(id) / ratio, touch.getY(id) / ratio);
	}

	/** Returns the first finger's x, in the screen's pixels.

		@return  The x. */
	public static function GetTouchX():Int {
		return Std.int(GetTouchPosition(0).x);
	}

	/** Returns the first finger's y, in the screen's pixels.

		@return  The y. */
	public static function GetTouchY():Int {
		return Std.int(GetTouchPosition(0).y);
	}

	/** Returns whether a gesture happened this frame. Only `GESTURE_TAP` is read here: a finger touching, or the left mouse button
		pressed, as raylib counts it.

		@param gesture  The gesture (`GESTURE_*`).
		@return  True for the frame it happened. */
	public static function IsGestureDetected(gesture:Int):Bool {
		if (gesture != GESTURE_TAP)
			return false;
		return Runtime.touch().pressed.length > 0 || Runtime.mouse().isButtonPressed(Left);
	}

	/** Returns the gesture this frame: `GESTURE_TAP` for a finger touching or the left mouse button pressed, else `GESTURE_NONE`. Only
		taps are read here.

		@return  The gesture (`GESTURE_*`). */
	public static function GetGestureDetected():Int {
		return IsGestureDetected(GESTURE_TAP) ? GESTURE_TAP : GESTURE_NONE;
	}

	// ---- Gamepads ----

	/** Returns whether a gamepad is connected.

		@param gamepad  The gamepad, 0 to 3.
		@return  True while one is connected there. */
	public static function IsGamepadAvailable(gamepad:Int):Bool {
		return gamepad >= 0 && gamepad < 4 && Runtime.gamepads().isConnected(gamepad);
	}

	/** Returns a gamepad's name.

		@param gamepad  The gamepad, 0 to 3.
		@return  Its name, or "" when none is connected. */
	public static function GetGamepadName(gamepad:Int):String {
		return IsGamepadAvailable(gamepad) ? Runtime.gamepads().getName(gamepad) : "";
	}

	/** Returns whether a gamepad's button went down this frame.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsGamepadButtonPressed(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonPressed(gamepad, cast b);
	}

	/** Returns whether a gamepad's button is held.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is down. */
	public static function IsGamepadButtonDown(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonDown(gamepad, cast b);
	}

	/** Returns whether a gamepad's button went up this frame.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True for that frame alone. */
	public static function IsGamepadButtonReleased(gamepad:Int, button:Int):Bool {
		var b = toPadButton(button);
		return b >= 0 && IsGamepadAvailable(gamepad) && Runtime.gamepads().isButtonReleased(gamepad, cast b);
	}

	/** Returns whether a gamepad's button isn't held.

		@param gamepad  The gamepad, 0 to 3.
		@param button  The button (`GAMEPAD_BUTTON_*`).
		@return  True while it is up. */
	public static function IsGamepadButtonUp(gamepad:Int, button:Int):Bool {
		return !IsGamepadButtonDown(gamepad, button);
	}

	/** Returns a button held on any gamepad, as raylib's last button pressed is: set while it is held, not only as it goes down.

		@return  The button (`GAMEPAD_BUTTON_*`), or `GAMEPAD_BUTTON_UNKNOWN` when none is held. */
	public static function GetGamepadButtonPressed():Int {
		for (pad in 0...4)
			if (IsGamepadAvailable(pad))
				for (button in 1...18)
					if (IsGamepadButtonDown(pad, button))
						return button;
		return GAMEPAD_BUTTON_UNKNOWN;
	}

	/** Returns the number of axes a gamepad has.

		@param gamepad  The gamepad, 0 to 3.
		@return  6 while one is connected, else 0. */
	public static function GetGamepadAxisCount(gamepad:Int):Int {
		return IsGamepadAvailable(gamepad) ? 6 : 0;
	}

	/** Returns how far a gamepad's axis is pushed, with no dead zone. A stick is -1 to 1, down and right positive; a trigger is -1
		released to 1 pulled, as raylib's are.

		@param gamepad  The gamepad, 0 to 3.
		@param axis  The axis (`GAMEPAD_AXIS_*`).
		@return  The value. */
	public static function GetGamepadAxisMovement(gamepad:Int, axis:Int):Float {
		if (axis < 0 || axis > 5 || !IsGamepadAvailable(gamepad))
			return 0;
		var value = Runtime.gamepads().getAxis(gamepad, cast axis);
		return axis >= GAMEPAD_AXIS_LEFT_TRIGGER ? value * 2 - 1 : value;
	}

	// ---- Shapes ----

	/** Draws one pixel.

		@param posX  The x.
		@param posY  The y.
		@param color  The color. */
	public static function DrawPixel(posX:Int, posY:Int, color:Color):Void {
		quad(posX, posY, 1, 1, color);
	}

	/** Draws one pixel.

		@param position  The position.
		@param color  The color. */
	public static function DrawPixelV(position:Vector2, color:Color):Void {
		quad(position.x, position.y, 1, 1, color);
	}

	/** Draws a line one pixel wide.

		@param startPosX  The start's x.
		@param startPosY  The start's y.
		@param endPosX  The end's x.
		@param endPosY  The end's y.
		@param color  The color. */
	public static function DrawLine(startPosX:Int, startPosY:Int, endPosX:Int, endPosY:Int, color:Color):Void {
		line(startPosX + .5, startPosY + .5, endPosX + .5, endPosY + .5, 1, color);
	}

	/** Draws a line one pixel wide.

		@param startPos  The start.
		@param endPos  The end.
		@param color  The color. */
	public static function DrawLineV(startPos:Vector2, endPos:Vector2, color:Color):Void {
		line(startPos.x, startPos.y, endPos.x, endPos.y, 1, color);
	}

	/** Draws a line of a thickness.

		@param startPos  The start.
		@param endPos  The end.
		@param thick  The thickness, in pixels.
		@param color  The color. */
	public static function DrawLineEx(startPos:Vector2, endPos:Vector2, thick:Float, color:Color):Void {
		line(startPos.x, startPos.y, endPos.x, endPos.y, thick, color);
	}

	/** Draws a filled circle.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircle(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		circle(centerX, centerY, radius, color);
	}

	/** Draws a filled circle.

		@param center  The center.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircleV(center:Vector2, radius:Float, color:Color):Void {
		circle(center.x, center.y, radius, color);
	}

	/** Draws a circle's outline, one pixel wide.

		@param centerX  The center's x.
		@param centerY  The center's y.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircleLines(centerX:Int, centerY:Int, radius:Float, color:Color):Void {
		ring(centerX, centerY, radius, color);
	}

	/** Draws a circle's outline, one pixel wide.

		@param center  The center.
		@param radius  The radius.
		@param color  The color. */
	public static function DrawCircleLinesV(center:Vector2, radius:Float, color:Color):Void {
		ring(center.x, center.y, radius, color);
	}

	/** Draws a filled rectangle.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	public static function DrawRectangle(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		quad(posX, posY, width, height, color);
	}

	/** Draws a filled rectangle.

		@param position  The top-left corner.
		@param size  The width and height.
		@param color  The color. */
	public static function DrawRectangleV(position:Vector2, size:Vector2, color:Color):Void {
		quad(position.x, position.y, size.x, size.y, color);
	}

	/** Draws a filled rectangle.

		@param rec  The rectangle.
		@param color  The color. */
	public static function DrawRectangleRec(rec:Rectangle, color:Color):Void {
		quad(rec.x, rec.y, rec.width, rec.height, color);
	}

	/** Draws a rectangle's outline, one pixel wide.

		@param posX  The left edge.
		@param posY  The top edge.
		@param width  The width.
		@param height  The height.
		@param color  The color. */
	public static function DrawRectangleLines(posX:Int, posY:Int, width:Int, height:Int, color:Color):Void {
		frame(posX, posY, width, height, 1, color);
	}

	/** Draws a rectangle's outline, its lines inside it.

		@param rec  The rectangle.
		@param lineThick  The lines' thickness.
		@param color  The color. */
	public static function DrawRectangleLinesEx(rec:Rectangle, lineThick:Float, color:Color):Void {
		frame(rec.x, rec.y, rec.width, rec.height, lineThick, color);
	}

	/** Draws a filled triangle; its points go counterclockwise, as raylib's do.

		@param v1  The first point.
		@param v2  The second point.
		@param v3  The third point.
		@param color  The color. */
	public static function DrawTriangle(v1:Vector2, v2:Vector2, v3:Vector2, color:Color):Void {
		var w = Runtime.frame.white;
		flat(w, v1.x, v1.y, 0, 0, color);
		flat(w, v2.x, v2.y, 0, 0, color);
		flat(w, v3.x, v3.y, 0, 0, color);
	}

	/** Returns whether two rectangles overlap.

		@param rec1  One rectangle.
		@param rec2  The other.
		@return  True when they overlap. */
	public static function CheckCollisionRecs(rec1:Rectangle, rec2:Rectangle):Bool {
		return rec1.x < rec2.x + rec2.width && rec1.x + rec1.width > rec2.x && rec1.y < rec2.y + rec2.height && rec1.y + rec1.height > rec2.y;
	}

	/** Returns whether two circles overlap.

		@param center1  One circle's center.
		@param radius1  Its radius.
		@param center2  The other's center.
		@param radius2  Its radius.
		@return  True when they overlap. */
	public static function CheckCollisionCircles(center1:Vector2, radius1:Float, center2:Vector2, radius2:Float):Bool {
		var dx = center2.x - center1.x, dy = center2.y - center1.y;
		return dx * dx + dy * dy <= (radius1 + radius2) * (radius1 + radius2);
	}

	/** Returns whether a circle and a rectangle overlap.

		@param center  The circle's center.
		@param radius  Its radius.
		@param rec  The rectangle.
		@return  True when they overlap. */
	public static function CheckCollisionCircleRec(center:Vector2, radius:Float, rec:Rectangle):Bool {
		var x = Math.max(rec.x, Math.min(center.x, rec.x + rec.width)),
			y = Math.max(rec.y, Math.min(center.y, rec.y + rec.height));
		var dx = center.x - x, dy = center.y - y;
		return dx * dx + dy * dy <= radius * radius;
	}

	/** Returns whether a point is inside a rectangle.

		@param point  The point.
		@param rec  The rectangle.
		@return  True when it is inside. */
	public static function CheckCollisionPointRec(point:Vector2, rec:Rectangle):Bool {
		return point.x >= rec.x && point.x < rec.x + rec.width && point.y >= rec.y && point.y < rec.y + rec.height;
	}

	/** Returns whether a point is inside a circle.

		@param point  The point.
		@param center  The circle's center.
		@param radius  Its radius.
		@return  True when it is inside. */
	public static function CheckCollisionPointCircle(point:Vector2, center:Vector2, radius:Float):Bool {
		return CheckCollisionCircles(point, 0, center, radius);
	}

	// ---- Textures ----

	/** Loads an image file as a texture. The program's files are loaded before `main`, so it is ready at once.

		@param fileName  The file, as the program names it, such as "assets/player.png".
		@return  The texture; its `id` is 0 when the file couldn't be read. */
	public static function LoadTexture(fileName:String):Texture2D {
		var image = Runtime.images.get(normalize(fileName));
		if (image == null) {
			trace('LoadTexture: $fileName was not loaded');
			return new Texture2D();
		}
		return new Texture2D(Runtime.graphics.createTexture(image.width, image.height, [image.pixels]), image.width, image.height);
	}

	/** Frees a texture.

		@param texture  The texture. */
	public static function UnloadTexture(texture:Texture2D):Void {
		if (texture.id != 0)
			Runtime.graphics.disposeTexture(texture.id);
		texture.id = 0;
	}

	/** Returns whether a texture was loaded.

		@param texture  The texture.
		@return  True when it holds an image. */
	public static function IsTextureValid(texture:Texture2D):Bool {
		return texture.id != 0;
	}

	/** Draws a texture, its top-left corner at a point.

		@param texture  The texture.
		@param posX  The x.
		@param posY  The y.
		@param tint  The color it is multiplied by; `WHITE` keeps it as it is. */
	public static function DrawTexture(texture:Texture2D, posX:Int, posY:Int, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height), new Rectangle(posX, posY, texture.width, texture.height), new Vector2(),
			0, tint);
	}

	/** Draws a texture, its top-left corner at a point.

		@param texture  The texture.
		@param position  The point.
		@param tint  The color it is multiplied by. */
	public static function DrawTextureV(texture:Texture2D, position:Vector2, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height), new Rectangle(position.x, position.y, texture.width, texture.height),
			new Vector2(), 0, tint);
	}

	/** Draws a texture turned about its top-left corner and scaled.

		@param texture  The texture.
		@param position  The top-left corner.
		@param rotation  Clockwise, in degrees.
		@param scale  The scale.
		@param tint  The color it is multiplied by. */
	public static function DrawTextureEx(texture:Texture2D, position:Vector2, rotation:Float, scale:Float, tint:Color):Void {
		DrawTexturePro(texture, new Rectangle(0, 0, texture.width, texture.height),
			new Rectangle(position.x, position.y, texture.width * scale, texture.height * scale), new Vector2(), rotation, tint);
	}

	/** Draws part of a texture. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param position  Where its top-left corner goes.
		@param tint  The color it is multiplied by. */
	public static function DrawTextureRec(texture:Texture2D, source:Rectangle, position:Vector2, tint:Color):Void {
		DrawTexturePro(texture, source, new Rectangle(position.x, position.y, Math.abs(source.width), Math.abs(source.height)), new Vector2(), 0, tint);
	}

	/** Draws part of a texture into a rectangle, turned about an origin. A negative source width or height flips it.

		@param texture  The texture.
		@param source  The part, in the texture's pixels.
		@param dest  Where it goes; its x and y are where the origin lands.
		@param origin  The point it turns about, from dest's top-left corner.
		@param rotation  Clockwise, in degrees.
		@param tint  The color it is multiplied by. */
	public static function DrawTexturePro(texture:Texture2D, source:Rectangle, dest:Rectangle, origin:Vector2, rotation:Float, tint:Color):Void {
		if (texture.id == 0 || texture.width == 0 || texture.height == 0)
			return;
		var u0 = source.x / texture.width, v0 = source.y / texture.height;
		var u1 = (source.x + Math.abs(source.width)) / texture.width,
			v1 = (source.y + Math.abs(source.height)) / texture.height;
		if (source.width < 0) {
			var t = u0;
			u0 = u1;
			u1 = t;
		}
		if (source.height < 0) {
			var t = v0;
			v0 = v1;
			v1 = t;
		}
		var angle = rotation * Math.PI / 180,
			c = Math.cos(angle),
			s = Math.sin(angle);
		var xs = [-origin.x, dest.width - origin.x],
			ys = [-origin.y, dest.height - origin.y];
		if (texture.flipped) {
			v0 = 1 - v0;
			v1 = 1 - v1;
		}
		var corner = (i:Int, j:Int, u:Float, v:Float) -> flat(texture.id, dest.x + xs[i] * c - ys[j] * s, dest.y + xs[i] * s + ys[j] * c, u, v, tint);
		corner(0, 0, u0, v0);
		corner(0, 1, u0, v1);
		corner(1, 1, u1, v1);
		corner(0, 0, u0, v0);
		corner(1, 1, u1, v1);
		corner(1, 0, u1, v0);
	}

	// ---- Text ----

	/** Draws text in raylib's default font. A size under 10 is drawn at 10, and letters are a tenth of the size apart.

		@param text  The text; "\n" starts a line.
		@param posX  The left edge.
		@param posY  The top edge.
		@param fontSize  The height of a line, in pixels.
		@param color  The color. */
	public static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void {
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var font = defaultFont();
		var x = 0., y = 0.;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			if (code == "\n".code) {
				y += fontSize + 2;
				x = 0;
				continue;
			}
			var index = glyph(code);
			var w = DefaultFont.WIDTHS[index];
			if (code != " ".code && code != "\t".code) {
				var gx = fontRecs[index * 2], gy = fontRecs[index * 2 + 1];
				DrawTexturePro(font, new Rectangle(gx, gy, w, DefaultFont.HEIGHT), new Rectangle(posX + x, posY + y, w * scale, fontSize), new Vector2(), 0,
					color);
			}
			x += w * scale + spacing;
		}
	}

	/** Returns the width text is drawn at by `DrawText`, its widest line's.

		@param text  The text.
		@param fontSize  The height of a line, in pixels.
		@return  The width, in pixels. */
	public static function MeasureText(text:String, fontSize:Int):Int {
		if (text.length == 0)
			return 0;
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		var spacing = Std.int(fontSize / DefaultFont.HEIGHT),
			scale = fontSize / DefaultFont.HEIGHT;
		var width = 0., widest = 0., count = 0, most = 0;
		for (code in new haxe.iterators.StringIteratorUnicode(text)) {
			count++;
			if (code == "\n".code) {
				if (width > widest)
					widest = width;
				width = 0;
				count = 0;
			} else
				width += DefaultFont.WIDTHS[glyph(code)];
			if (count > most)
				most = count;
		}
		if (width > widest)
			widest = width;
		return Std.int(widest * scale + (most - 1) * spacing);
	}

	/** Draws the frames a second, as "60 FPS", in green.

		@param posX  The left edge.
		@param posY  The top edge. */
	public static function DrawFPS(posX:Int, posY:Int):Void {
		var fps = GetFPS();
		var color = fps < 15 ? RED : fps < 30 ? ORANGE : LIME;
		DrawText('${fps < 10 ? " " : ""}$fps FPS', posX, posY, 20, color);
	}

	// ---- Audio ----

	/** Opens the audio output, with helix-services' `Audio` over it. In a page it plays once the player's first press lets it. */
	public static function InitAudioDevice():Void {
		if (Runtime.audio != null)
			return;
		#if js
		var output = new helix.platform.adapters.audio.webaudio.WebAudioAdapter();
		var decoder = new helix.platform.adapters.audiodecoder.webaudio.WebAudioDecoderAdapter();
		#else
		var output = new helix.platform.adapters.audio.sdl3mixer.Sdl3MixerAudioAdapter();
		var decoder = new helix.platform.adapters.audiodecoder.sdl3mixer.Sdl3MixerAudioDecoderAdapter();
		#end
		Runtime.polled.push(output);
		Runtime.polled.push(decoder);
		var assets = Runtime.assets != null ? Runtime.assets : new helix.services.assets.Assets({sources: []});
		var audio = new helix.services.audio.Audio(output, decoder, assets, Runtime.system);
		Runtime.polled.push(audio);
		Runtime.output = output;
		Runtime.audioDecoder = decoder;
		Runtime.audio = audio;
	}

	/** Closes the audio output, stopping and unloading every sound. */
	public static function CloseAudioDevice():Void {
		if (Runtime.audio == null)
			return;
		for (p in ([Runtime.audio, Runtime.audioDecoder, Runtime.output] : Array<helix.platform.IPollable>))
			Runtime.polled.remove(p);
		Runtime.audio.dispose();
		Runtime.audioDecoder.dispose();
		Runtime.output.dispose();
		Runtime.audio = null;
		Runtime.audioDecoder = null;
		Runtime.output = null;
	}

	/** Returns whether the audio output is open.

		@return  True after `InitAudioDevice`, where the platform has an output. */
	public static function IsAudioDeviceReady():Bool {
		return Runtime.audio != null && Runtime.output.available;
	}

	/** Sets the volume of every sound.

		@param volume  0 (silent) to 1. */
	public static function SetMasterVolume(volume:Float):Void {
		if (Runtime.audio != null)
			Runtime.audio.master.volume = volume;
	}

	/** Returns the volume of every sound.

		@return  0 (silent) to 1. */
	public static function GetMasterVolume():Float {
		return Runtime.audio == null ? 1 : Runtime.audio.master.volume;
	}

	/** Loads a sound file whole. It decodes in the background; played before then, it starts once decoded.

		@param fileName  The file, as the program names it, such as "assets/coin.wav".
		@return  The sound. */
	public static function LoadSound(fileName:String):Sound {
		var sound = new Sound();
		if (Runtime.audio == null) {
			trace('LoadSound: InitAudioDevice first');
			return sound;
		}
		sound.cancel = Runtime.audio.load(normalize(fileName), loaded -> {
			sound.cancel = null;
			sound.sound = loaded;
			for (_ in 0...sound.waiting)
				PlaySound(sound);
			sound.waiting = 0;
		}, error -> {
			sound.cancel = null;
			trace('LoadSound: $fileName: $error');
		});
		return sound;
	}

	/** Frees a sound, stopping it.

		@param sound  The sound. */
	public static function UnloadSound(sound:Sound):Void {
		StopSound(sound);
		if (sound.cancel != null)
			sound.cancel();
		if (sound.sound != null && Runtime.audio != null)
			Runtime.audio.unload(sound.sound);
		sound.cancel = null;
		sound.sound = null;
		sound.unloaded = true;
	}

	/** Returns whether a sound was loaded.

		@param sound  The sound.
		@return  True once it is decoded. */
	public static function IsSoundValid(sound:Sound):Bool {
		return sound.sound != null;
	}

	/** Plays a sound from its start, restarting it when it is already playing.

		@param sound  The sound. */
	public static function PlaySound(sound:Sound):Void {
		if (Runtime.audio == null || sound.unloaded)
			return;
		if (sound.sound == null) {
			sound.waiting++;
			return;
		}
		StopSound(sound);
		sound.voice = Runtime.audio.play(sound.sound, null, false, sound.volume);
	}

	/** Stops a sound.

		@param sound  The sound. */
	public static function StopSound(sound:Sound):Void {
		if (sound.voice != null)
			sound.voice.stop();
		sound.voice = null;
	}

	/** Returns whether a sound is playing.

		@param sound  The sound.
		@return  True while it plays. */
	public static function IsSoundPlaying(sound:Sound):Bool {
		return sound.voice != null && sound.voice.playing;
	}

	/** Sets a sound's volume, for its next play and the one playing.

		@param sound  The sound.
		@param volume  0 (silent) to 1. */
	public static function SetSoundVolume(sound:Sound, volume:Float):Void {
		sound.volume = volume;
		if (sound.voice != null)
			sound.voice.volume = volume;
	}

	// ---- Files ----

	/** Returns whether a file exists: one `SaveFileText` wrote, or one of the program's.

		@param fileName  The file.
		@return  True when it exists. */
	public static function FileExists(fileName:String):Bool {
		var path = normalize(fileName);
		return Runtime.saves.hasKey(SAVED + path) || Runtime.files.exists(path) || Runtime.images.exists(path);
	}

	/** Reads a text file: one `SaveFileText` wrote, or one of the program's.

		@param fileName  The file.
		@return  Its text, or null when it doesn't exist. */
	public static function LoadFileText(fileName:String):Null<String> {
		var path = normalize(fileName);
		if (Runtime.saves.hasKey(SAVED + path))
			return Runtime.saves.getString(SAVED + path, "");
		var bytes = Runtime.files.get(path);
		return bytes == null ? null : bytes.toString();
	}

	/** Frees text `LoadFileText` returned. There is nothing to free here.

		@param text  The text. */
	public static function UnloadFileText(text:Null<String>):Void {}

	/** Writes a text file, kept across runs: in a page, in the page's storage; natively, in the program's data directory. It is kept at
		the end of the frame.

		@param fileName  The file.
		@param text  Its text.
		@return  True. */
	public static function SaveFileText(fileName:String, text:String):Bool {
		Runtime.saves.setString(SAVED + normalize(fileName), text);
		return true;
	}

	// ---- Colors ----

	/** Returns a color as four numbers, 0 to 1 each.

		@param color  The color.
		@return  Red, green, blue and alpha as x, y, z and w. */
	public static function ColorNormalize(color:Color):Vector4 {
		return new Vector4(color.r / 255, color.g / 255, color.b / 255, color.a / 255);
	}

	/** Returns a color from four numbers, 0 to 1 each.

		@param normalized  Red, green, blue and alpha as x, y, z and w.
		@return  The color. */
	public static function ColorFromNormalized(normalized:Vector4):Color {
		return new Color(Std.int(normalized.x * 255), Std.int(normalized.y * 255), Std.int(normalized.z * 255), Std.int(normalized.w * 255));
	}

	/** Returns a color with its alpha scaled.

		@param color  The color.
		@param alpha  0 (clear) to 1 (as it is).
		@return  The new color. */
	public static function Fade(color:Color, alpha:Float):Color {
		return ColorAlpha(color, alpha);
	}

	/** Returns a color with an alpha.

		@param color  The color.
		@param alpha  0 (clear) to 1 (opaque).
		@return  The new color. */
	public static function ColorAlpha(color:Color, alpha:Float):Color {
		var a = alpha < 0 ? 0. : alpha > 1 ? 1. : alpha;
		return new Color(color.r, color.g, color.b, Std.int(255 * a));
	}

	// ---- raymath ----

	/** Returns a value kept between two others.

		@param value  The value.
		@param min  The least.
		@param max  The most.
		@return  The value, at least min and at most max. */
	public static function Clamp(value:Float, min:Float, max:Float):Float {
		var r = value < min ? min : value;
		return r > max ? max : r;
	}

	/** Returns a value part of the way from one to another.

		@param start  The start.
		@param end  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The value. */
	public static function Lerp(start:Float, end:Float, amount:Float):Float {
		return start + amount * (end - start);
	}

	/** Returns a value moved from one range to another.

		@param value  The value.
		@param inputStart  The first range's start.
		@param inputEnd  Its end.
		@param outputStart  The second range's start.
		@param outputEnd  Its end.
		@return  The value in the second range. */
	public static function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float {
		return (value - inputStart) / (inputEnd - inputStart) * (outputEnd - outputStart) + outputStart;
	}

	/** Returns (0, 0).

		@return  The vector. */
	public static function Vector2Zero():Vector2 {
		return new Vector2(0, 0);
	}

	/** Returns (1, 1).

		@return  The vector. */
	public static function Vector2One():Vector2 {
		return new Vector2(1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@return  The sum. */
	public static function Vector2Add(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x + v2.x, v1.y + v2.y);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	public static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x - v2.x, v1.y - v2.y);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scale  The scale.
		@return  The scaled vector. */
	public static function Vector2Scale(v:Vector2, scale:Float):Vector2 {
		return new Vector2(v.x * scale, v.y * scale);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	public static function Vector2Multiply(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x * v2.x, v1.y * v2.y);
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	public static function Vector2Length(v:Vector2):Float {
		return Math.sqrt(v.x * v.x + v.y * v.y);
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	public static function Vector2LengthSqr(v:Vector2):Float {
		return v.x * v.x + v.y * v.y;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	public static function Vector2Distance(v1:Vector2, v2:Vector2):Float {
		var dx = v2.x - v1.x, dy = v2.y - v1.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	/** Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).

		@param v  The vector.
		@return  The direction. */
	public static function Vector2Normalize(v:Vector2):Vector2 {
		var length = Vector2Length(v);
		return length > 0 ? new Vector2(v.x / length, v.y / length) : new Vector2(0, 0);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	public static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2 {
		return new Vector2(v1.x + amount * (v2.x - v1.x), v1.y + amount * (v2.y - v1.y));
	}

	/** Returns a vector with its length kept between two values.

		@param v  The vector.
		@param min  The least length.
		@param max  The most length.
		@return  The vector. */
	public static function Vector2ClampValue(v:Vector2, min:Float, max:Float):Vector2 {
		var length = Vector2Length(v);
		if (length == 0)
			return new Vector2(0, 0);
		var clamped = Clamp(length, min, max);
		return Vector2Scale(v, clamped / length);
	}

	// ---- What the functions share ----
	static inline final SAVED = "file:";
	static var start = 0.;
	static var configFlags = 0;
	static var targetFps = 0;
	static var fps = 60.;
	static var seed = 0x2545f491;
	static var seeded = false;
	static var lastMouseX = 0.;
	static var lastMouseY = 0.;
	static var lastPointerX = 0.;
	static var lastPointerY = 0.;
	static var font:Null<Texture2D> = null;
	static var fontRecs:Array<Int> = [];

	static function normalize(path:String):String {
		while (StringTools.startsWith(path, "./"))
			path = path.substr(2);
		return path;
	}

	// raylib's KEY_* as the platform's keys: the same numbers, a right-hand modifier as the left-hand one.
	static function toKey(key:Int):Int {
		return switch key {
			case 344 | 345 | 346 | 347: key - 4;
			case k if (k > 0 && k < 349): k;
			case _: -1;
		}
	}

	// raylib's GAMEPAD_BUTTON_* as the platform's buttons, by position.
	static function toPadButton(button:Int):Int {
		return switch button {
			case 1: 12;
			case 2: 15;
			case 3: 13;
			case 4: 14;
			case 5: 3;
			case 6: 1;
			case 7: 0;
			case 8: 2;
			case 9: 4;
			case 10: 6;
			case 11: 5;
			case 12: 7;
			case 13: 8;
			case 14: 16;
			case 15: 9;
			case 16: 10;
			case 17: 11;
			case _: -1;
		}
	}

	static function glyph(code:Int):Int {
		return code >= 32 && code < 256 ? code - 32 : "?".code - 32;
	}

	// The default font's texture, made at its first use, and each glyph's place on it, as raylib lays them out.
	static function defaultFont():Texture2D {
		if (font != null)
			return font;
		var size = 128, pixels = haxe.io.Bytes.alloc(size * size * 4);
		for (i in 0...size * size >> 5) {
			var word = DefaultFont.BITS[i];
			for (j in 0...32) {
				var at = (i * 32 + j) * 4;
				pixels.set(at, 255);
				pixels.set(at + 1, 255);
				pixels.set(at + 2, 255);
				pixels.set(at + 3, (word >>> j) & 1 == 1 ? 255 : 0);
			}
		}
		font = new Texture2D(Runtime.graphics.createTexture(size, size, [pixels]), size, size);
		var line = 0, x = 1, test = 1;
		for (i in 0...DefaultFont.WIDTHS.length) {
			var w = DefaultFont.WIDTHS[i];
			var gx = x, gy = 1 + line * (DefaultFont.HEIGHT + 1);
			test += w + 1;
			if (test >= size) {
				line++;
				x = 2 + w;
				test = x;
				gx = 1;
				gy = 1 + line * (DefaultFont.HEIGHT + 1);
			} else
				x = test;
			fontRecs.push(gx);
			fontRecs.push(gy);
		}
		return font;
	}

	// An immediate vertex in 2D, at z 0.
	static inline function flat(texture:Int, x:Float, y:Float, u:Float, v:Float, color:Color):Void {
		Runtime.frame.vertex(texture, false, x, y, 0, u, v, color);
	}

	static function quad(x:Float, y:Float, w:Float, h:Float, color:Color):Void {
		var t = Runtime.frame.white;
		flat(t, x, y, 0, 0, color);
		flat(t, x, y + h, 0, 0, color);
		flat(t, x + w, y + h, 0, 0, color);
		flat(t, x, y, 0, 0, color);
		flat(t, x + w, y + h, 0, 0, color);
		flat(t, x + w, y, 0, 0, color);
	}

	static function line(x1:Float, y1:Float, x2:Float, y2:Float, thick:Float, color:Color):Void {
		var dx = x2 - x1, dy = y2 - y1, length = Math.sqrt(dx * dx + dy * dy);
		if (length == 0)
			return;
		var nx = -dy / length * thick / 2, ny = dx / length * thick / 2;
		var t = Runtime.frame.white;
		flat(t, x1 + nx, y1 + ny, 0, 0, color);
		flat(t, x1 - nx, y1 - ny, 0, 0, color);
		flat(t, x2 - nx, y2 - ny, 0, 0, color);
		flat(t, x1 + nx, y1 + ny, 0, 0, color);
		flat(t, x2 - nx, y2 - ny, 0, 0, color);
		flat(t, x2 + nx, y2 + ny, 0, 0, color);
	}

	static function frame(x:Float, y:Float, w:Float, h:Float, thick:Float, color:Color):Void {
		quad(x, y, w, thick, color);
		quad(x, y + h - thick, w, thick, color);
		quad(x, y + thick, thick, h - thick * 2, color);
		quad(x + w - thick, y + thick, thick, h - thick * 2, color);
	}

	static function segments(radius:Float):Int {
		var n = Math.ceil(radius * Math.PI / 2);
		return n < 12 ? 12 : n > 96 ? 96 : n;
	}

	static function circle(cx:Float, cy:Float, radius:Float, color:Color):Void {
		var n = segments(radius), t = Runtime.frame.white;
		for (i in 0...n) {
			var a0 = i / n * Math.PI * 2, a1 = (i + 1) / n * Math.PI * 2;
			flat(t, cx, cy, 0, 0, color);
			flat(t, cx + Math.cos(a0) * radius, cy + Math.sin(a0) * radius, 0, 0, color);
			flat(t, cx + Math.cos(a1) * radius, cy + Math.sin(a1) * radius, 0, 0, color);
		}
	}

	static function ring(cx:Float, cy:Float, radius:Float, color:Color):Void {
		var n = segments(radius);
		for (i in 0...n) {
			var a0 = i / n * Math.PI * 2, a1 = (i + 1) / n * Math.PI * 2;
			line(cx + Math.cos(a0) * radius, cy + Math.sin(a0) * radius, cx + Math.cos(a1) * radius, cy + Math.sin(a1) * radius, 1, color);
		}
	}

	// ---- 2D camera ----

	/** Draws through a 2D camera until `EndMode2D`.

		@param camera  The camera. */
	public static function BeginMode2D(camera:Camera2D):Void {
		Runtime.frame.cut();
		Runtime.frame.view = Matrices.of(GetCameraMatrix2D(camera));
	}

	/** Goes back to drawing in the screen's pixels. */
	public static function EndMode2D():Void {
		Runtime.frame.screen2D();
	}

	/** Returns a 2D camera's transform, from the world to the screen.

		@param camera  The camera.
		@return  The matrix. */
	public static function GetCameraMatrix2D(camera:Camera2D):Matrix {
		var m = Matrices.translate(-camera.target.x, -camera.target.y, 0);
		m = Matrices.multiply(m, Matrices.rotate(0, 0, 1, camera.rotation * DEG2RAD));
		m = Matrices.multiply(m, Matrices.scale(camera.zoom, camera.zoom, 1));
		m = Matrices.multiply(m, Matrices.translate(camera.offset.x, camera.offset.y, 0));
		return Matrices.to(m);
	}

	/** Returns where a point in a 2D camera's world is on the screen.

		@param position  The point.
		@param camera  The camera.
		@return  The screen position. */
	public static function GetWorldToScreen2D(position:Vector2, camera:Camera2D):Vector2 {
		var p = Matrices.point(Matrices.of(GetCameraMatrix2D(camera)), position.x, position.y, 0);
		return new Vector2(p[0], p[1]);
	}

	/** Returns where a screen position is in a 2D camera's world.

		@param position  The screen position.
		@param camera  The camera.
		@return  The point. */
	public static function GetScreenToWorld2D(position:Vector2, camera:Camera2D):Vector2 {
		var p = Matrices.point(Matrices.invert(Matrices.of(GetCameraMatrix2D(camera))), position.x, position.y, 0);
		return new Vector2(p[0], p[1]);
	}

	// ---- 3D camera ----

	/** Draws in 3D through a camera until `EndMode3D`, with depth.

		@param camera  The camera. */
	public static function BeginMode3D(camera:Camera3D):Void {
		var f = Runtime.frame;
		f.cut();
		f.in3D = true;
		f.view = cameraView(camera);
		f.projection = cameraProjection(camera, f.width / f.height);
	}

	/** Goes back to drawing in 2D, in the screen's pixels. */
	public static function EndMode3D():Void {
		Runtime.frame.screen2D();
		Runtime.frame.in3D = false;
	}

	/** Moves a camera as one of raylib's modes does: `CAMERA_ORBITAL` turns it about its target, half a radian a second, and the
		wheel moves it closer; `CAMERA_FREE`, `CAMERA_FIRST_PERSON` and `CAMERA_THIRD_PERSON` move it by WASD, and turn it by the mouse;
		`CAMERA_CUSTOM` leaves it.

		@param camera  The camera, changed.
		@param mode  The mode (`CAMERA_*`). */
	public static function UpdateCamera(camera:Camera3D, mode:Int):Void {
		var dt = GetFrameTime();
		switch mode {
			case CAMERA_ORBITAL:
				var offset = Vector3Subtract(camera.position, camera.target);
				offset = Vector3RotateByAxisAngle(offset, camera.up, .5 * dt);
				var wheel = GetMouseWheelMove();
				if (wheel != 0) {
					var d = Vector3Length(offset) - wheel;
					if (d > .1)
						offset = Vector3Scale(Vector3Normalize(offset), d);
				}
				camera.position = Vector3Add(camera.target, offset);
			case CAMERA_FREE | CAMERA_FIRST_PERSON | CAMERA_THIRD_PERSON:
				var forward = Vector3Normalize(Vector3Subtract(camera.target, camera.position));
				if (mode != CAMERA_FREE)
					forward = Vector3Normalize(new Vector3(forward.x, 0, forward.z));
				var right = Vector3Normalize(Vector3CrossProduct(forward, camera.up));
				var move = new Vector3();
				var speed = 5.4 * dt;
				if (IsKeyDown(KEY_W))
					move = Vector3Add(move, Vector3Scale(forward, speed));
				if (IsKeyDown(KEY_S))
					move = Vector3Subtract(move, Vector3Scale(forward, speed));
				if (IsKeyDown(KEY_D))
					move = Vector3Add(move, Vector3Scale(right, speed));
				if (IsKeyDown(KEY_A))
					move = Vector3Subtract(move, Vector3Scale(right, speed));
				camera.position = Vector3Add(camera.position, move);
				camera.target = Vector3Add(camera.target, move);
				var delta = GetMouseDelta();
				var look = Vector3Subtract(camera.target, camera.position);
				look = Vector3RotateByAxisAngle(look, camera.up, -delta.x * .003);
				look = Vector3RotateByAxisAngle(look, right, -delta.y * .003);
				camera.target = Vector3Add(camera.position, look);
			case _:
		}
	}

	/** Returns a camera's view, as `BeginMode3D` uses it.

		@param camera  The camera.
		@return  The matrix. */
	public static function GetCameraMatrix(camera:Camera3D):Matrix {
		return Matrices.to(cameraView(camera));
	}

	/** Returns the ray from a camera through a screen position, as raylib's picking uses it.

		@param position  The screen position.
		@param camera  The camera.
		@return  The ray. */
	public static function GetScreenToWorldRay(position:Vector2, camera:Camera3D):Ray {
		return GetScreenToWorldRayEx(position, camera, GetScreenWidth(), GetScreenHeight());
	}

	/** Returns the ray from a camera through a position in a view of a size, such as a render texture's.

		@param position  The position in the view.
		@param camera  The camera.
		@param width  The view's width.
		@param height  The view's height.
		@return  The ray. */
	public static function GetScreenToWorldRayEx(position:Vector2, camera:Camera3D, width:Int, height:Int):Ray {
		var x = 2 * position.x / width - 1, y = 1 - 2 * position.y / height;
		var inverse = Matrices.invert(Matrices.multiply(cameraView(camera), cameraProjection(camera, width / height)));
		function unproject(z:Float):Array<Float> {
			var p = [
				inverse[0] * x + inverse[4] * y + inverse[8] * z + inverse[12],
				inverse[1] * x + inverse[5] * y + inverse[9] * z + inverse[13],
				inverse[2] * x + inverse[6] * y + inverse[10] * z + inverse[14],
				inverse[3] * x + inverse[7] * y + inverse[11] * z + inverse[15]
			];
			return [p[0] / p[3], p[1] / p[3], p[2] / p[3]];
		}
		var near = unproject(-1), far = unproject(1);
		var origin = camera.projection == CAMERA_ORTHOGRAPHIC ? new Vector3(near[0], near[1], near[2]) : camera.position;
		return new Ray(new Vector3(origin.x, origin.y, origin.z), Vector3Normalize(new Vector3(far[0] - near[0], far[1] - near[1], far[2] - near[2])));
	}

	/** Returns the ray from a camera through a screen position: raylib's old name for `GetScreenToWorldRay`.

		@param position  The screen position.
		@param camera  The camera.
		@return  The ray. */
	public static function GetMouseRay(position:Vector2, camera:Camera3D):Ray {
		return GetScreenToWorldRay(position, camera);
	}

	/** Returns where a point in the world is on the screen.

		@param position  The point.
		@param camera  The camera.
		@return  The screen position. */
	public static function GetWorldToScreen(position:Vector3, camera:Camera3D):Vector2 {
		return GetWorldToScreenEx(position, camera, GetScreenWidth(), GetScreenHeight());
	}

	/** Returns where a point in the world is in a view of a size.

		@param position  The point.
		@param camera  The camera.
		@param width  The view's width.
		@param height  The view's height.
		@return  The position in the view. */
	public static function GetWorldToScreenEx(position:Vector3, camera:Camera3D, width:Int, height:Int):Vector2 {
		var m = Matrices.multiply(cameraView(camera), cameraProjection(camera, width / height));
		var x = m[0] * position.x + m[4] * position.y + m[8] * position.z + m[12];
		var y = m[1] * position.x + m[5] * position.y + m[9] * position.z + m[13];
		var w = m[3] * position.x + m[7] * position.y + m[11] * position.z + m[15];
		if (w == 0)
			w = 1;
		return new Vector2((x / w + 1) / 2 * width, (1 - y / w) / 2 * height);
	}

	/** Returns how far the mouse moved since the last frame, in the screen's pixels.

		@return  The movement. */
	public static function GetMouseDelta():Vector2 {
		var now = GetMousePosition();
		var frame = Runtime.frames;
		if (frame != deltaFrame) {
			deltaFrame = frame;
			deltaX = now.x - previousX;
			deltaY = now.y - previousY;
			previousX = now.x;
			previousY = now.y;
		}
		return new Vector2(deltaX, deltaY);
	}

	// ---- 3D shapes ----

	/** Draws a line in 3D.

		@param startPos  The start.
		@param endPos  The end.
		@param color  The color. */
	public static function DrawLine3D(startPos:Vector3, endPos:Vector3, color:Color):Void {
		var t = Runtime.frame.white;
		Runtime.frame.vertex(t, true, startPos.x, startPos.y, startPos.z, 0, 0, color);
		Runtime.frame.vertex(t, true, endPos.x, endPos.y, endPos.z, 0, 0, color);
	}

	/** Draws a filled box.

		@param position  Its center.
		@param width  Its size along x.
		@param height  Along y.
		@param length  Along z.
		@param color  The color. */
	public static function DrawCube(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void {
		var x = position.x, y = position.y, z = position.z, w = width / 2, h = height / 2, l = length / 2;
		var f = Runtime.frame, t = f.white;
		function face(nx:Float, ny:Float, nz:Float, corners:Array<Float>):Void {
			f.nx = nx;
			f.ny = ny;
			f.nz = nz;
			for (i in [0, 1, 2, 0, 2, 3])
				f.vertex(t, false, x + corners[i * 3], y + corners[i * 3 + 1], z + corners[i * 3 + 2], 0, 0, color);
		}
		face(0, 0, 1, [-w, -h, l, w, -h, l, w, h, l, -w, h, l]);
		face(0, 0, -1, [-w, -h, -l, -w, h, -l, w, h, -l, w, -h, -l]);
		face(0, 1, 0, [-w, h, -l, -w, h, l, w, h, l, w, h, -l]);
		face(0, -1, 0, [-w, -h, -l, w, -h, -l, w, -h, l, -w, -h, l]);
		face(1, 0, 0, [w, -h, -l, w, h, -l, w, h, l, w, -h, l]);
		face(-1, 0, 0, [-w, -h, -l, -w, -h, l, -w, h, l, -w, h, -l]);
		f.nx = 0;
		f.ny = 0;
		f.nz = 1;
	}

	/** Draws a filled box.

		@param position  Its center.
		@param size  Its size.
		@param color  The color. */
	public static function DrawCubeV(position:Vector3, size:Vector3, color:Color):Void {
		DrawCube(position, size.x, size.y, size.z, color);
	}

	/** Draws a box's edges.

		@param position  Its center.
		@param width  Its size along x.
		@param height  Along y.
		@param length  Along z.
		@param color  The color. */
	public static function DrawCubeWires(position:Vector3, width:Float, height:Float, length:Float, color:Color):Void {
		var w = width / 2, h = height / 2, l = length / 2;
		var min = new Vector3(position.x - w, position.y - h, position.z - l),
			max = new Vector3(position.x + w, position.y + h, position.z + l);
		DrawBoundingBox(new BoundingBox(min, max), color);
	}

	/** Draws a box's edges.

		@param position  Its center.
		@param size  Its size.
		@param color  The color. */
	public static function DrawCubeWiresV(position:Vector3, size:Vector3, color:Color):Void {
		DrawCubeWires(position, size.x, size.y, size.z, color);
	}

	/** Draws a bounding box's edges.

		@param box  The box.
		@param color  The color. */
	public static function DrawBoundingBox(box:BoundingBox, color:Color):Void {
		var a = box.min, b = box.max;
		var c = [
			[a.x, a.y, a.z], [b.x, a.y, a.z], [b.x, b.y, a.z], [a.x, b.y, a.z],
			[a.x, a.y, b.z], [b.x, a.y, b.z], [b.x, b.y, b.z], [a.x, b.y, b.z]
		];
		for (e in [
			[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4], [0, 4], [1, 5], [2, 6], [3, 7]])
			DrawLine3D(new Vector3(c[e[0]][0], c[e[0]][1], c[e[0]][2]), new Vector3(c[e[1]][0], c[e[1]][1], c[e[1]][2]), color);
	}

	/** Draws a filled sphere, 16 rings and 16 slices.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param color  The color. */
	public static function DrawSphere(centerPos:Vector3, radius:Float, color:Color):Void {
		DrawSphereEx(centerPos, radius, 16, 16, color);
	}

	/** Draws a filled sphere.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param rings  Rings top to bottom.
		@param slices  Slices around.
		@param color  The color. */
	public static function DrawSphereEx(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void {
		var f = Runtime.frame, t = f.white;
		function at(r:Int, s:Int):Array<Float> {
			var phi = Math.PI * r / rings, theta = Math.PI * 2 * s / slices;
			return [Math.sin(phi) * Math.cos(theta), Math.cos(phi), Math.sin(phi) * Math.sin(theta)];
		}
		function put(p:Array<Float>):Void {
			f.nx = p[0];
			f.ny = p[1];
			f.nz = p[2];
			f.vertex(t, false, centerPos.x + p[0] * radius, centerPos.y + p[1] * radius, centerPos.z + p[2] * radius, 0, 0, color);
		}
		for (r in 0...rings)
			for (s in 0...slices) {
				var a = at(r, s), b = at(r, s + 1), c = at(r + 1, s), d = at(r + 1, s + 1);
				for (p in [a, b, c, c, b, d])
					put(p);
			}
		f.nx = 0;
		f.ny = 0;
		f.nz = 1;
	}

	/** Draws a sphere's wires.

		@param centerPos  Its center.
		@param radius  Its radius.
		@param rings  Rings top to bottom.
		@param slices  Slices around.
		@param color  The color. */
	public static function DrawSphereWires(centerPos:Vector3, radius:Float, rings:Int, slices:Int, color:Color):Void {
		function at(r:Int, s:Int):Vector3 {
			var phi = Math.PI * r / rings, theta = Math.PI * 2 * s / slices;
			return new Vector3(centerPos.x
				+ Math.sin(phi) * Math.cos(theta) * radius, centerPos.y
				+ Math.cos(phi) * radius,
				centerPos.z
				+ Math.sin(phi) * Math.sin(theta) * radius);
		}
		for (r in 0...rings)
			for (s in 0...slices) {
				DrawLine3D(at(r, s), at(r + 1, s), color);
				DrawLine3D(at(r, s), at(r, s + 1), color);
			}
	}

	/** Draws a flat rectangle on the XZ plane, facing up.

		@param centerPos  Its center.
		@param size  Its size along x and z.
		@param color  The color. */
	public static function DrawPlane(centerPos:Vector3, size:Vector2, color:Color):Void {
		var f = Runtime.frame, t = f.white, x = size.x / 2, z = size.y / 2;
		f.nx = 0;
		f.ny = 1;
		f.nz = 0;
		var c = [[-x, z], [x, z], [x, -z], [-x, z], [x, -z], [-x, -z]];
		for (p in c)
			f.vertex(t, false, centerPos.x + p[0], centerPos.y, centerPos.z + p[1], 0, 0, color);
		f.nz = 1;
		f.ny = 0;
	}

	/** Draws a grid on the XZ plane, centered on the origin: its center lines darker, as raylib's.

		@param slices  The lines each way.
		@param spacing  The space between them. */
	public static function DrawGrid(slices:Int, spacing:Float):Void {
		var half = slices / 2;
		for (i in 0...slices + 1) {
			var p = (i - half) * spacing, e = half * spacing;
			var color = i == Std.int(half) ? new Color(128, 128, 128, 255) : new Color(191, 191, 191, 255);
			DrawLine3D(new Vector3(p, 0, -e), new Vector3(p, 0, e), color);
			DrawLine3D(new Vector3(-e, 0, p), new Vector3(e, 0, p), color);
		}
	}

	// ---- Models and meshes ----

	/** Loads a model from a glTF or GLB file: its meshes, their materials and its images. The program's files are loaded before `main`,
		so it is ready at once.

		@param fileName  The file, as the program names it, such as "assets/trophy.glb".
		@return  The model; with no meshes when the file couldn't be read. */
	public static function LoadModel(fileName:String):Model {
		var path = normalize(fileName);
		var bytes = Runtime.files.get(path);
		var lower = path.toLowerCase();
		if (bytes == null || !(StringTools.endsWith(lower, ".glb") || StringTools.endsWith(lower, ".gltf"))) {
			trace(bytes == null ? 'LoadModel: $fileName was not loaded' : 'LoadModel: $fileName: only glTF and GLB are read here');
			return new Model([], [Models.defaultMaterial(defaultShader())], []);
		}
		try {
			return Models.gltf(path, bytes, defaultShader());
		} catch (e:Dynamic) {
			trace('LoadModel: $fileName: $e');
			return new Model([], [Models.defaultMaterial(defaultShader())], []);
		}
	}

	/** Makes a model of one mesh, with the default material.

		@param mesh  The mesh.
		@return  The model. */
	public static function LoadModelFromMesh(mesh:Mesh):Model {
		Models.upload(mesh);
		return new Model([mesh], [Models.defaultMaterial(defaultShader())], [0]);
	}

	/** Returns whether a model has meshes.

		@param model  The model.
		@return  True when it has. */
	public static function IsModelValid(model:Model):Bool {
		return model.meshCount > 0;
	}

	/** Frees a model's meshes, and the textures of its materials.

		@param model  The model. */
	public static function UnloadModel(model:Model):Void {
		for (mesh in model.meshes)
			Models.unload(mesh);
		for (m in model.materials)
			for (map in m.maps)
				if (map.texture.id != 0) {
					Runtime.graphics.disposeTexture(map.texture.id);
					map.texture.id = 0;
				}
	}

	/** Draws a model at a position and a scale, its materials' colors times a tint.

		@param model  The model.
		@param position  Where.
		@param scale  The scale, the same on each axis.
		@param tint  The tint. */
	public static function DrawModel(model:Model, position:Vector3, scale:Float, tint:Color):Void {
		DrawModelEx(model, position, new Vector3(0, 1, 0), 0, new Vector3(scale, scale, scale), tint);
	}

	/** Draws a model scaled, turned about an axis and moved, after its own transform.

		@param model  The model.
		@param position  Where.
		@param rotationAxis  The axis.
		@param rotationAngle  The angle, in degrees.
		@param scale  The scale on each axis.
		@param tint  The tint. */
	public static function DrawModelEx(model:Model, position:Vector3, rotationAxis:Vector3, rotationAngle:Float, scale:Vector3, tint:Color):Void {
		var m = Matrices.scale(scale.x, scale.y, scale.z);
		m = Matrices.multiply(m, Matrices.rotate(rotationAxis.x, rotationAxis.y, rotationAxis.z, rotationAngle * DEG2RAD));
		m = Matrices.multiply(m, Matrices.translate(position.x, position.y, position.z));
		var transform = Matrices.multiply(Matrices.of(model.transform), m);
		for (i in 0...model.meshCount) {
			var material = model.materials[model.meshMaterial[i]];
			if (material == null)
				material = model.materials[0];
			drawMesh(model.meshes[i], material, transform, tint);
		}
	}

	/** Draws a mesh with a material and a transform.

		@param mesh  The mesh.
		@param material  The material.
		@param transform  The transform. */
	public static function DrawMesh(mesh:Mesh, material:Material, transform:Matrix):Void {
		drawMesh(mesh, material, Matrices.of(transform), WHITE);
	}

	/** Sends a mesh's vertices to the GPU, so it can be drawn. The `GenMesh*` functions and `LoadModel` do it themselves.

		@param mesh  The mesh.
		@param isDynamic  Whether it will change (raylib names it `dynamic`, a Haxe keyword); meshes here can't, so it is ignored. */
	public static function UploadMesh(mesh:Mesh, isDynamic:Bool):Void {
		Models.upload(mesh);
	}

	/** Frees a mesh's GPU buffers.

		@param mesh  The mesh. */
	public static function UnloadMesh(mesh:Mesh):Void {
		Models.unload(mesh);
	}

	/** Makes a box mesh, centered on the origin.

		@param width  Along x.
		@param height  Along y.
		@param length  Along z.
		@return  The mesh. */
	public static function GenMeshCube(width:Float, height:Float, length:Float):Mesh {
		return Models.cube(width, height, length);
	}

	/** Makes a flat mesh on the XZ plane, facing up.

		@param width  Along x.
		@param length  Along z.
		@param resX  Divisions along x.
		@param resZ  Divisions along z.
		@return  The mesh. */
	public static function GenMeshPlane(width:Float, length:Float, resX:Int, resZ:Int):Mesh {
		return Models.plane(width, length, resX, resZ);
	}

	/** Makes a sphere mesh, centered on the origin.

		@param radius  Its radius.
		@param rings  Rings top to bottom.
		@param slices  Slices around.
		@return  The mesh. */
	public static function GenMeshSphere(radius:Float, rings:Int, slices:Int):Mesh {
		return Models.sphere(radius, rings, slices);
	}

	/** Returns raylib's default material: the default shader, white.

		@return  The material. */
	public static function LoadMaterialDefault():Material {
		return Models.defaultMaterial(defaultShader());
	}

	/** Sets a texture on a material's map.

		@param material  The material.
		@param mapType  The map (`MATERIAL_MAP_*`).
		@param texture  The texture. */
	public static function SetMaterialTexture(material:Material, mapType:Int, texture:Texture2D):Void {
		material.maps[mapType].texture = texture;
	}

	/** Sets the material a model's mesh draws with.

		@param model  The model.
		@param meshId  The mesh.
		@param materialId  The material. */
	public static function SetModelMeshMaterial(model:Model, meshId:Int, materialId:Int):Void {
		model.meshMaterial[meshId] = materialId;
	}

	/** Returns a mesh's bounds.

		@param mesh  The mesh.
		@return  The box. */
	public static function GetMeshBoundingBox(mesh:Mesh):BoundingBox {
		return Models.bounds(mesh);
	}

	/** Returns a model's bounds, its transform applied.

		@param model  The model.
		@return  The box. */
	public static function GetModelBoundingBox(model:Model):BoundingBox {
		var t = Matrices.of(model.transform);
		var min = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
		var max = [Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];
		for (mesh in model.meshes) {
			var b = Models.bounds(mesh);
			for (x in [b.min.x, b.max.x])
				for (y in [b.min.y, b.max.y])
					for (z in [b.min.z, b.max.z]) {
						var p = Matrices.point(t, x, y, z);
						for (c in 0...3) {
							if (p[c] < min[c])
								min[c] = p[c];
							if (p[c] > max[c])
								max[c] = p[c];
						}
					}
		}
		if (model.meshes.length == 0)
			return new BoundingBox(new Vector3(), new Vector3());
		return new BoundingBox(new Vector3(min[0], min[1], min[2]), new Vector3(max[0], max[1], max[2]));
	}

	// ---- Collisions in 3D ----

	/** Returns whether two boxes overlap.

		@param box1  One.
		@param box2  The other.
		@return  True when they overlap. */
	public static function CheckCollisionBoxes(box1:BoundingBox, box2:BoundingBox):Bool {
		return box1.max.x >= box2.min.x && box1.min.x <= box2.max.x && box1.max.y >= box2.min.y && box1.min.y <= box2.max.y && box1.max.z >= box2.min.z
			&& box1.min.z <= box2.max.z;
	}

	/** Returns whether two spheres overlap.

		@param center1  One's center.
		@param radius1  Its radius.
		@param center2  The other's center.
		@param radius2  Its radius.
		@return  True when they overlap. */
	public static function CheckCollisionSpheres(center1:Vector3, radius1:Float, center2:Vector3, radius2:Float):Bool {
		return Vector3Distance(center1, center2) <= radius1 + radius2;
	}

	/** Returns whether a box and a sphere overlap.

		@param box  The box.
		@param center  The sphere's center.
		@param radius  Its radius.
		@return  True when they overlap. */
	public static function CheckCollisionBoxSphere(box:BoundingBox, center:Vector3, radius:Float):Bool {
		var x = Clamp(center.x, box.min.x, box.max.x),
			y = Clamp(center.y, box.min.y, box.max.y),
			z = Clamp(center.z, box.min.z, box.max.z);
		return Vector3Distance(new Vector3(x, y, z), center) <= radius;
	}

	/** Returns where a ray hits a sphere.

		@param ray  The ray.
		@param center  The sphere's center.
		@param radius  Its radius.
		@return  The hit. */
	public static function GetRayCollisionSphere(ray:Ray, center:Vector3, radius:Float):RayCollision {
		var result = new RayCollision(false, 0, new Vector3(), new Vector3());
		var oc = Vector3Subtract(ray.position, center);
		var b = Vector3DotProduct(oc, ray.direction),
			c = Vector3DotProduct(oc, oc) - radius * radius;
		var d = b * b - c;
		if (d < 0)
			return result;
		var t = -b - Math.sqrt(d);
		if (t < 0)
			t = -b + Math.sqrt(d);
		if (t < 0)
			return result;
		result.hit = true;
		result.distance = t;
		result.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
		result.normal = Vector3Normalize(Vector3Subtract(result.point, center));
		return result;
	}

	/** Returns where a ray hits a box.

		@param ray  The ray.
		@param box  The box.
		@return  The hit. */
	public static function GetRayCollisionBox(ray:Ray, box:BoundingBox):RayCollision {
		var result = new RayCollision(false, 0, new Vector3(), new Vector3());
		var o = [ray.position.x, ray.position.y, ray.position.z],
			d = [ray.direction.x, ray.direction.y, ray.direction.z];
		var lo = [box.min.x, box.min.y, box.min.z],
			hi = [box.max.x, box.max.y, box.max.z];
		var tmin = Math.NEGATIVE_INFINITY, tmax = Math.POSITIVE_INFINITY, axis = 0, sign = 1.;
		for (i in 0...3) {
			if (d[i] == 0) {
				if (o[i] < lo[i] || o[i] > hi[i])
					return result;
				continue;
			}
			var t1 = (lo[i] - o[i]) / d[i], t2 = (hi[i] - o[i]) / d[i];
			var near = Math.min(t1, t2), far = Math.max(t1, t2);
			if (near > tmin) {
				tmin = near;
				axis = i;
				sign = t1 < t2 ? -1 : 1;
			}
			if (far < tmax)
				tmax = far;
		}
		if (tmax < 0 || tmin > tmax)
			return result;
		var t = tmin >= 0 ? tmin : tmax;
		result.hit = true;
		result.distance = t;
		result.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
		var n = [0., 0, 0];
		n[axis] = sign;
		result.normal = new Vector3(n[0], n[1], n[2]);
		return result;
	}

	/** Returns where a ray hits a triangle.

		@param ray  The ray.
		@param p1  A corner.
		@param p2  A corner.
		@param p3  A corner.
		@return  The hit. */
	public static function GetRayCollisionTriangle(ray:Ray, p1:Vector3, p2:Vector3, p3:Vector3):RayCollision {
		var result = new RayCollision(false, 0, new Vector3(), new Vector3());
		var e1 = Vector3Subtract(p2, p1), e2 = Vector3Subtract(p3, p1);
		var p = Vector3CrossProduct(ray.direction, e2),
			det = Vector3DotProduct(e1, p);
		if (Math.abs(det) < 1e-6)
			return result;
		var inv = 1 / det, t0 = Vector3Subtract(ray.position, p1);
		var u = Vector3DotProduct(t0, p) * inv;
		if (u < 0 || u > 1)
			return result;
		var q = Vector3CrossProduct(t0, e1),
			v = Vector3DotProduct(ray.direction, q) * inv;
		if (v < 0 || u + v > 1)
			return result;
		var t = Vector3DotProduct(e2, q) * inv;
		if (t <= 1e-6)
			return result;
		result.hit = true;
		result.distance = t;
		result.point = Vector3Add(ray.position, Vector3Scale(ray.direction, t));
		result.normal = Vector3Normalize(Vector3CrossProduct(e1, e2));
		return result;
	}

	/** Returns where a ray hits a mesh drawn with a transform: its nearest triangle.

		@param ray  The ray.
		@param mesh  The mesh.
		@param transform  The transform.
		@return  The hit. */
	public static function GetRayCollisionMesh(ray:Ray, mesh:Mesh, transform:Matrix):RayCollision {
		var best = new RayCollision(false, 0, new Vector3(), new Vector3());
		var v = mesh.vertices;
		if (v == null)
			return best;
		var t = Matrices.of(transform);
		function corner(i:Int):Vector3 {
			var p = Matrices.point(t, v[i * 3], v[i * 3 + 1], v[i * 3 + 2]);
			return new Vector3(p[0], p[1], p[2]);
		}
		for (k in 0...mesh.triangleCount) {
			var a = mesh.indices == null ? k * 3 : mesh.indices[k * 3],
				b = mesh.indices == null ? k * 3 + 1 : mesh.indices[k * 3 + 1],
				c = mesh.indices == null ? k * 3 + 2 : mesh.indices[k * 3 + 2];
			var hit = GetRayCollisionTriangle(ray, corner(a), corner(b), corner(c));
			if (hit.hit && (!best.hit || hit.distance < best.distance))
				best = hit;
		}
		return best;
	}

	// ---- Render textures ----

	/** Makes a texture to draw into, with depth.

		@param width  Its width, in pixels.
		@param height  Its height.
		@return  The render texture. */
	public static function LoadRenderTexture(width:Int, height:Int):RenderTexture2D {
		var target = Runtime.graphics.createRenderTarget(width, height);
		var texture = new Texture2D(target, width, height);
		texture.flipped = true;
		return new RenderTexture(target, texture, new Texture2D(0, width, height));
	}

	/** Returns whether a render texture was made.

		@param target  The render texture.
		@return  True when it was. */
	public static function IsRenderTextureValid(target:RenderTexture2D):Bool {
		return target.id != 0;
	}

	/** Frees a render texture.

		@param target  The render texture. */
	public static function UnloadRenderTexture(target:RenderTexture2D):Void {
		if (target.id != 0)
			Runtime.graphics.disposeTexture(target.id);
		target.id = 0;
		target.texture.id = 0;
	}

	/** Draws into a render texture until `EndTextureMode`. Unlike raylib's, what was drawn into it in an earlier frame isn't kept: each
		frame's drawing into it starts cleared, to clear black unless `ClearBackground` gives a color.

		@param target  The render texture. */
	public static function BeginTextureMode(target:RenderTexture2D):Void {
		Runtime.frame.toTarget(target.id, target.texture.width, target.texture.height);
	}

	/** Goes back to drawing on the screen. */
	public static function EndTextureMode():Void {
		Runtime.frame.toScreen();
	}

	/** Sets how a texture is sampled when drawn larger or smaller. Textures here are sampled as `TEXTURE_FILTER_POINT`, whatever is set.

		@param texture  The texture.
		@param filter  The filter (`TEXTURE_FILTER_*`). */
	public static function SetTextureFilter(texture:Texture2D, filter:Int):Void {}

	// ---- Shaders ----

	/** Returns raylib's default shader.

		@return  The shader. */
	public static function LoadShaderDefault():Shader {
		return defaultShader();
	}

	/** Returns whether a shader was made.

		@param shader  The shader.
		@return  True when it was. */
	public static function IsShaderValid(shader:Shader):Bool {
		return shader.id != 0;
	}

	/** Frees a shader; the default one stays.

		@param shader  The shader. */
	public static function UnloadShader(shader:Shader):Void {
		if (shader.program != null && shader.program != Runtime.frame.defaultProgram) {
			shader.program.dispose();
			shader.program = null;
			shader.id = 0;
		}
	}

	/** Returns the location of a shader's uniform or texture, by its name.

		@param shader  The shader.
		@param uniformName  The name.
		@return  Its location, or -1 when the shader doesn't declare it. */
	public static function GetShaderLocation(shader:Shader, uniformName:String):Int {
		return shader.program == null ? -1 : shader.program.locate(uniformName);
	}

	/** Returns the location of a shader's attribute, by its name.

		@param shader  The shader.
		@param attribName  The name.
		@return  Its location, or -1 when the shader doesn't declare it. */
	public static function GetShaderLocationAttrib(shader:Shader, attribName:String):Int {
		return shader.program == null ? -1 : shader.program.attributes.indexOf(attribName);
	}

	/** Sets a shader's uniform, for the draws after it.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param value  The value: a number, an array of numbers, or a `Vector2`, `Vector3`, `Vector4` or `Color`.
		@param uniformType  Its type (`SHADER_UNIFORM_*`). */
	public static function SetShaderValue(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int):Void {
		SetShaderValueV(shader, locIndex, value, uniformType, 1);
	}

	/** Sets elements of a shader's array uniform, for the draws after it.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param value  The values, in order.
		@param uniformType  Each element's type (`SHADER_UNIFORM_*`).
		@param count  The elements set. */
	public static function SetShaderValueV(shader:Shader, locIndex:Int, value:Dynamic, uniformType:Int, count:Int):Void {
		if (shader.program == null)
			return;
		var slot = shader.program.textureSlot(locIndex);
		if (slot >= 0)
			return;
		Runtime.frame.cut();
		shader.program.write(locIndex, numbers(value));
	}

	/** Sets a shader's matrix uniform, for the draws after it.

		@param shader  The shader.
		@param locIndex  The uniform's location.
		@param mat  The matrix. */
	public static function SetShaderValueMatrix(shader:Shader, locIndex:Int, mat:Matrix):Void {
		if (shader.program == null)
			return;
		Runtime.frame.cut();
		shader.program.write(locIndex, Matrices.of(mat));
	}

	/** Sets a shader's texture, for the draws after it.

		@param shader  The shader.
		@param locIndex  The texture's location.
		@param texture  The texture. */
	public static function SetShaderValueTexture(shader:Shader, locIndex:Int, texture:Texture2D):Void {
		if (shader.program == null)
			return;
		var slot = shader.program.textureSlot(locIndex);
		if (slot >= 0) {
			Runtime.frame.cut();
			shader.program.textures[slot] = texture.id;
		}
	}

	/** Draws shapes, text and textures with a shader until `EndShaderMode`.

		@param shader  The shader. */
	public static function BeginShaderMode(shader:Shader):Void {
		if (shader.program == null)
			return;
		Runtime.frame.cut();
		Runtime.frame.program = shader.program;
	}

	/** Goes back to the default shader. */
	public static function EndShaderMode():Void {
		Runtime.frame.cut();
		Runtime.frame.program = Runtime.frame.defaultProgram;
	}

	// ---- raymath: Vector3 ----

	/** Returns (0, 0, 0).

		@return  The vector. */
	public static function Vector3Zero():Vector3 {
		return new Vector3(0, 0, 0);
	}

	/** Returns (1, 1, 1).

		@return  The vector. */
	public static function Vector3One():Vector3 {
		return new Vector3(1, 1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@return  The sum. */
	public static function Vector3Add(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	public static function Vector3Subtract(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scalar  The scale.
		@return  The scaled vector. */
	public static function Vector3Scale(v:Vector3, scalar:Float):Vector3 {
		return new Vector3(v.x * scalar, v.y * scalar, v.z * scalar);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	public static function Vector3Multiply(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z);
	}

	/** Returns the cross product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	public static function Vector3CrossProduct(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x);
	}

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	public static function Vector3DotProduct(v1:Vector3, v2:Vector3):Float {
		return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	public static function Vector3Length(v:Vector3):Float {
		return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	public static function Vector3LengthSqr(v:Vector3):Float {
		return v.x * v.x + v.y * v.y + v.z * v.z;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	public static function Vector3Distance(v1:Vector3, v2:Vector3):Float {
		return Vector3Length(Vector3Subtract(v1, v2));
	}

	/** Returns a vector of length 1 in the same direction, or the vector itself when its length is 0.

		@param v  The vector.
		@return  The direction. */
	public static function Vector3Normalize(v:Vector3):Vector3 {
		var l = Vector3Length(v);
		return l == 0 ? new Vector3(v.x, v.y, v.z) : new Vector3(v.x / l, v.y / l, v.z / l);
	}

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@return  The negated vector. */
	public static function Vector3Negate(v:Vector3):Vector3 {
		return new Vector3(-v.x, -v.y, -v.z);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	public static function Vector3Lerp(v1:Vector3, v2:Vector3, amount:Float):Vector3 {
		return new Vector3(v1.x + amount * (v2.x - v1.x), v1.y + amount * (v2.y - v1.y), v1.z + amount * (v2.z - v1.z));
	}

	/** Returns a point transformed by a matrix.

		@param v  The point.
		@param mat  The matrix.
		@return  The transformed point. */
	public static function Vector3Transform(v:Vector3, mat:Matrix):Vector3 {
		var p = Matrices.point(Matrices.of(mat), v.x, v.y, v.z);
		return new Vector3(p[0], p[1], p[2]);
	}

	/** Returns a vector turned about an axis.

		@param v  The vector.
		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The turned vector. */
	public static function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float):Vector3 {
		var m = Matrices.rotate(axis.x, axis.y, axis.z, angle);
		var p = Matrices.point(m, v.x, v.y, v.z);
		return new Vector3(p[0], p[1], p[2]);
	}

	// ---- raymath: Matrix and Quaternion ----

	/** Returns the identity matrix.

		@return  The matrix. */
	public static function MatrixIdentity():Matrix {
		return Matrices.to(Matrices.identity());
	}

	/** Returns two matrices multiplied: left, then right.

		@param left  The first.
		@param right  The second.
		@return  The product. */
	public static function MatrixMultiply(left:Matrix, right:Matrix):Matrix {
		return Matrices.to(Matrices.multiply(Matrices.of(left), Matrices.of(right)));
	}

	/** Returns a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	public static function MatrixTranslate(x:Float, y:Float, z:Float):Matrix {
		return Matrices.to(Matrices.translate(x, y, z));
	}

	/** Returns a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	public static function MatrixScale(x:Float, y:Float, z:Float):Matrix {
		return Matrices.to(Matrices.scale(x, y, z));
	}

	/** Returns a rotation about an axis.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotate(axis:Vector3, angle:Float):Matrix {
		return Matrices.to(Matrices.rotate(axis.x, axis.y, axis.z, angle));
	}

	/** Returns a rotation about x.

		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotateX(angle:Float):Matrix {
		return Matrices.to(Matrices.rotate(1, 0, 0, angle));
	}

	/** Returns a rotation about y.

		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotateY(angle:Float):Matrix {
		return Matrices.to(Matrices.rotate(0, 1, 0, angle));
	}

	/** Returns a rotation about z.

		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotateZ(angle:Float):Matrix {
		return Matrices.to(Matrices.rotate(0, 0, 1, angle));
	}

	/** Returns rotations about x, then y, then z.

		@param angle  The angles, in radians.
		@return  The matrix. */
	public static function MatrixRotateXYZ(angle:Vector3):Matrix {
		var m = Matrices.multiply(Matrices.rotate(1, 0, 0, angle.x), Matrices.rotate(0, 1, 0, angle.y));
		return Matrices.to(Matrices.multiply(m, Matrices.rotate(0, 0, 1, angle.z)));
	}

	/** Returns a matrix inverted.

		@param mat  The matrix.
		@return  Its inverse. */
	public static function MatrixInvert(mat:Matrix):Matrix {
		return Matrices.to(Matrices.invert(Matrices.of(mat)));
	}

	/** Returns a matrix transposed.

		@param mat  The matrix.
		@return  Its transpose. */
	public static function MatrixTranspose(mat:Matrix):Matrix {
		return Matrices.to(Matrices.transpose(Matrices.of(mat)));
	}

	/** Returns a view looking from eye at target.

		@param eye  Where from.
		@param target  What at.
		@param up  Up.
		@return  The matrix. */
	public static function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix {
		return Matrices.to(Matrices.lookAt(eye.x, eye.y, eye.z, target.x, target.y, target.z, up.x, up.y, up.z));
	}

	/** Returns a perspective projection.

		@param fovY  The field of view, top to bottom, in radians.
		@param aspect  Width over height.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@return  The matrix. */
	public static function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float):Matrix {
		return Matrices.to(Matrices.perspective(fovY, aspect, nearPlane, farPlane));
	}

	/** Returns an orthographic projection.

		@param left  Left.
		@param right  Right.
		@param bottom  Bottom.
		@param top  Top.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@return  The matrix. */
	public static function MatrixOrtho(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix {
		return Matrices.to(Matrices.ortho(left, right, bottom, top, nearPlane, farPlane));
	}

	/** Returns the identity quaternion.

		@return  The quaternion. */
	public static function QuaternionIdentity():Quaternion {
		return new Vector4(0, 0, 0, 1);
	}

	/** Returns the rotation about an axis as a quaternion.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The quaternion. */
	public static function QuaternionFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
		var a = Vector3Normalize(axis), s = Math.sin(angle / 2);
		return new Vector4(a.x * s, a.y * s, a.z * s, Math.cos(angle / 2));
	}

	/** Returns a rotation by Euler angles as a quaternion.

		@param pitch  About x, in radians.
		@param yaw  About y.
		@param roll  About z.
		@return  The quaternion. */
	public static function QuaternionFromEuler(pitch:Float, yaw:Float, roll:Float):Quaternion {
		var x0 = Math.cos(pitch * .5),
			x1 = Math.sin(pitch * .5),
			y0 = Math.cos(yaw * .5),
			y1 = Math.sin(yaw * .5),
			z0 = Math.cos(roll * .5),
			z1 = Math.sin(roll * .5);
		return new Vector4(x1 * y0 * z0 - x0 * y1 * z1, x0 * y1 * z0 + x1 * y0 * z1, x0 * y0 * z1 - x1 * y1 * z0, x0 * y0 * z0 + x1 * y1 * z1);
	}

	/** Returns a quaternion's rotation as a matrix.

		@param q  The quaternion.
		@return  The matrix. */
	public static function QuaternionToMatrix(q:Quaternion):Matrix {
		return Matrices.to(Matrices.quaternion(q.x, q.y, q.z, q.w));
	}

	// ---- What the 3D functions share ----
	static var shaderDefault:Null<Shader> = null;
	static var deltaFrame = -1;
	static var deltaX = 0.;
	static var deltaY = 0.;
	static var previousX = 0.;
	static var previousY = 0.;

	static function defaultShader():Shader {
		if (shaderDefault == null) {
			var p = Runtime.frame.defaultProgram;
			shaderDefault = new Shader(p.handle, locations(p), p);
		}
		return shaderDefault;
	}

	/** Makes a shader from a program compiled as the program built (`LoadShader`).

		@param source  The compiled program.
		@return  The shader. */
	@:noCompletion
	public static function makeShader(source:helix.ray.internal.ProgramSource):Shader {
		var p = new helix.ray.internal.Program(Runtime.graphics, source);
		return new Shader(p.handle, locations(p), p);
	}

	// raylib's SHADER_LOC_* locations of a program.
	static function locations(p:helix.ray.internal.Program):Array<Int> {
		var locs = [for (_ in 0...32) -1];
		locs[SHADER_LOC_VERTEX_POSITION] = p.attributes.indexOf("vertexPosition");
		locs[SHADER_LOC_VERTEX_TEXCOORD01] = p.attributes.indexOf("vertexTexCoord");
		locs[SHADER_LOC_VERTEX_NORMAL] = p.attributes.indexOf("vertexNormal");
		locs[SHADER_LOC_VERTEX_COLOR] = p.attributes.indexOf("vertexColor");
		locs[SHADER_LOC_MATRIX_MVP] = p.locate("mvp");
		locs[SHADER_LOC_MATRIX_VIEW] = p.locate("matView");
		locs[SHADER_LOC_MATRIX_PROJECTION] = p.locate("matProjection");
		locs[SHADER_LOC_MATRIX_MODEL] = p.locate("matModel");
		locs[SHADER_LOC_MATRIX_NORMAL] = p.locate("matNormal");
		locs[SHADER_LOC_VECTOR_VIEW] = p.locate("viewPos");
		locs[SHADER_LOC_COLOR_DIFFUSE] = p.locate("colDiffuse");
		locs[SHADER_LOC_MAP_ALBEDO] = p.locate("texture0");
		locs[SHADER_LOC_MAP_METALNESS] = p.locate("texture1");
		locs[SHADER_LOC_MAP_NORMAL] = p.locate("texture2");
		return locs;
	}

	// The numbers of a shader value as a program writes them.
	static function numbers(value:Dynamic):Array<Float> {
		if (Std.isOfType(value, Array))
			return [for (x in (value : Array<Dynamic>)) (x : Float)];
		if (Std.isOfType(value, Vector2))
			return [value.x, value.y];
		if (Std.isOfType(value, Vector3))
			return [value.x, value.y, value.z];
		if (Std.isOfType(value, Vector4))
			return [value.x, value.y, value.z, value.w];
		if (Std.isOfType(value, Color))
			return [value.r / 255, value.g / 255, value.b / 255, value.a / 255];
		if (Std.isOfType(value, Matrix))
			return Matrices.of(value);
		return [(value : Float)];
	}

	static function cameraView(camera:Camera3D):Array<Float> {
		var p = camera.position, t = camera.target, u = camera.up;
		return Matrices.lookAt(p.x, p.y, p.z, t.x, t.y, t.z, u.x, u.y, u.z);
	}

	// raylib's near and far planes, 0.01 and 1000.
	static function cameraProjection(camera:Camera3D, aspect:Float):Array<Float> {
		if (camera.projection == CAMERA_ORTHOGRAPHIC) {
			var top = camera.fovy / 2, right = top * aspect;
			return Matrices.ortho(-right, right, -top, top, .01, 1000);
		}
		return Matrices.perspective(camera.fovy * DEG2RAD, aspect, .01, 1000);
	}

	static function drawMesh(mesh:Mesh, material:Material, transform:Array<Float>, tint:Color):Void {
		if (mesh.buffers == null)
			Models.upload(mesh);
		if (mesh.buffers == null)
			return;
		var shader = material.shader == null || material.shader.program == null ? defaultShader() : material.shader;
		var c = material.maps[MATERIAL_MAP_DIFFUSE].color;
		var diffuse = [
			c.r / 255 * tint.r / 255,
			c.g / 255 * tint.g / 255,
			c.b / 255 * tint.b / 255,
			c.a / 255 * tint.a / 255
		];
		var textures = [for (i in 0...3) material.maps[i].texture.id];
		Runtime.frame.mesh(mesh, shader.program, transform, diffuse, textures);
	}
	#end
}
