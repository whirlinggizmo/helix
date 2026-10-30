package helix.ray;

#if macro
import haxe.macro.Expr;
#else
import helix.ray.internal.DefaultFont;
import helix.math.Matrix3D;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
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
		program builds, for every target, so their names are constants; the files are found under `-D helix-ray-files` (default `web`), as the
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

	// ---- raylib's functions helix-ray doesn't have yet: each refuses to compile, saying so ----

	/** raylib's `IsWindowFullscreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsWindowFullscreen(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsWindowFullscreen", "raylib.h");

	/** raylib's `IsWindowHidden` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsWindowHidden(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsWindowHidden", "raylib.h");

	/** raylib's `IsWindowMinimized` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsWindowMinimized(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsWindowMinimized", "raylib.h");

	/** raylib's `IsWindowMaximized` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsWindowMaximized(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsWindowMaximized", "raylib.h");

	/** raylib's `IsWindowFocused` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsWindowFocused(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsWindowFocused", "raylib.h");

	/** raylib's `ToggleFullscreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ToggleFullscreen(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ToggleFullscreen", "raylib.h");

	/** raylib's `ToggleBorderlessWindowed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ToggleBorderlessWindowed(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ToggleBorderlessWindowed", "raylib.h");

	/** raylib's `MaximizeWindow` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MaximizeWindow(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MaximizeWindow", "raylib.h");

	/** raylib's `MinimizeWindow` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MinimizeWindow(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MinimizeWindow", "raylib.h");

	/** raylib's `RestoreWindow` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function RestoreWindow(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("RestoreWindow", "raylib.h");

	/** raylib's `SetWindowIcon` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowIcon(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowIcon", "raylib.h");

	/** raylib's `SetWindowIcons` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowIcons(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowIcons", "raylib.h");

	/** raylib's `SetWindowPosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowPosition(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowPosition", "raylib.h");

	/** raylib's `SetWindowMonitor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowMonitor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowMonitor", "raylib.h");

	/** raylib's `SetWindowMinSize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowMinSize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowMinSize", "raylib.h");

	/** raylib's `SetWindowMaxSize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowMaxSize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowMaxSize", "raylib.h");

	/** raylib's `SetWindowOpacity` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowOpacity(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowOpacity", "raylib.h");

	/** raylib's `SetWindowFocused` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetWindowFocused(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetWindowFocused", "raylib.h");

	/** raylib's `GetWindowHandle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetWindowHandle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetWindowHandle", "raylib.h");

	/** raylib's `GetMonitorCount` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorCount(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorCount", "raylib.h");

	/** raylib's `GetCurrentMonitor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetCurrentMonitor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetCurrentMonitor", "raylib.h");

	/** raylib's `GetMonitorPosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorPosition(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorPosition", "raylib.h");

	/** raylib's `GetMonitorWidth` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorWidth(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorWidth", "raylib.h");

	/** raylib's `GetMonitorHeight` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorHeight(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorHeight", "raylib.h");

	/** raylib's `GetMonitorPhysicalWidth` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorPhysicalWidth(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorPhysicalWidth", "raylib.h");

	/** raylib's `GetMonitorPhysicalHeight` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorPhysicalHeight(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorPhysicalHeight", "raylib.h");

	/** raylib's `GetMonitorRefreshRate` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorRefreshRate(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorRefreshRate", "raylib.h");

	/** raylib's `GetWindowPosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetWindowPosition(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetWindowPosition", "raylib.h");

	/** raylib's `GetWindowScaleDPI` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetWindowScaleDPI(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetWindowScaleDPI", "raylib.h");

	/** raylib's `GetMonitorName` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMonitorName(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMonitorName", "raylib.h");

	/** raylib's `SetClipboardText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetClipboardText(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetClipboardText", "raylib.h");

	/** raylib's `GetClipboardText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetClipboardText(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetClipboardText", "raylib.h");

	/** raylib's `GetClipboardImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetClipboardImage(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetClipboardImage", "raylib.h");

	/** raylib's `EnableEventWaiting` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function EnableEventWaiting(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("EnableEventWaiting", "raylib.h");

	/** raylib's `DisableEventWaiting` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DisableEventWaiting(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DisableEventWaiting", "raylib.h");

	/** raylib's `ShowCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ShowCursor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ShowCursor", "raylib.h");

	/** raylib's `HideCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function HideCursor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("HideCursor", "raylib.h");

	/** raylib's `IsCursorHidden` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsCursorHidden(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsCursorHidden", "raylib.h");

	/** raylib's `EnableCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function EnableCursor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("EnableCursor", "raylib.h");

	/** raylib's `DisableCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DisableCursor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DisableCursor", "raylib.h");

	/** raylib's `IsCursorOnScreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsCursorOnScreen(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsCursorOnScreen", "raylib.h");

	/** raylib's `BeginBlendMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function BeginBlendMode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("BeginBlendMode", "raylib.h");

	/** raylib's `EndBlendMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function EndBlendMode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("EndBlendMode", "raylib.h");

	/** raylib's `BeginScissorMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function BeginScissorMode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("BeginScissorMode", "raylib.h");

	/** raylib's `EndScissorMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function EndScissorMode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("EndScissorMode", "raylib.h");

	/** raylib's `BeginVrStereoMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function BeginVrStereoMode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("BeginVrStereoMode", "raylib.h");

	/** raylib's `EndVrStereoMode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function EndVrStereoMode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("EndVrStereoMode", "raylib.h");

	/** raylib's `LoadVrStereoConfig` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadVrStereoConfig(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadVrStereoConfig", "raylib.h");

	/** raylib's `UnloadVrStereoConfig` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadVrStereoConfig(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadVrStereoConfig", "raylib.h");

	/** raylib's `SwapScreenBuffer` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SwapScreenBuffer(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SwapScreenBuffer", "raylib.h");

	/** raylib's `PollInputEvents` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function PollInputEvents(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("PollInputEvents", "raylib.h");

	/** raylib's `WaitTime` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function WaitTime(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("WaitTime", "raylib.h");

	/** raylib's `LoadRandomSequence` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadRandomSequence(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadRandomSequence", "raylib.h");

	/** raylib's `UnloadRandomSequence` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadRandomSequence(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadRandomSequence", "raylib.h");

	/** raylib's `TakeScreenshot` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TakeScreenshot(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TakeScreenshot", "raylib.h");

	/** raylib's `OpenURL` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function OpenURL(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("OpenURL", "raylib.h");

	/** raylib's `TraceLog` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TraceLog(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TraceLog", "raylib.h");

	/** raylib's `SetTraceLogLevel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetTraceLogLevel(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetTraceLogLevel", "raylib.h");

	/** raylib's `MemAlloc` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MemAlloc(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MemAlloc", "raylib.h");

	/** raylib's `MemRealloc` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MemRealloc(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MemRealloc", "raylib.h");

	/** raylib's `MemFree` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MemFree(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MemFree", "raylib.h");

	/** raylib's `SetTraceLogCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetTraceLogCallback(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetTraceLogCallback", "raylib.h");

	/** raylib's `SetLoadFileDataCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetLoadFileDataCallback(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetLoadFileDataCallback", "raylib.h");

	/** raylib's `SetSaveFileDataCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetSaveFileDataCallback(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetSaveFileDataCallback", "raylib.h");

	/** raylib's `SetLoadFileTextCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetLoadFileTextCallback(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetLoadFileTextCallback", "raylib.h");

	/** raylib's `SetSaveFileTextCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetSaveFileTextCallback(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetSaveFileTextCallback", "raylib.h");

	/** raylib's `LoadFileData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadFileData(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadFileData", "raylib.h");

	/** raylib's `UnloadFileData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadFileData(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadFileData", "raylib.h");

	/** raylib's `SaveFileData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SaveFileData(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SaveFileData", "raylib.h");

	/** raylib's `ExportDataAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportDataAsCode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportDataAsCode", "raylib.h");

	/** raylib's `DirectoryExists` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DirectoryExists(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DirectoryExists", "raylib.h");

	/** raylib's `IsFileExtension` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsFileExtension(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsFileExtension", "raylib.h");

	/** raylib's `GetFileLength` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetFileLength(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetFileLength", "raylib.h");

	/** raylib's `GetFileExtension` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetFileExtension(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetFileExtension", "raylib.h");

	/** raylib's `GetFileName` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetFileName(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetFileName", "raylib.h");

	/** raylib's `GetFileNameWithoutExt` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetFileNameWithoutExt(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetFileNameWithoutExt", "raylib.h");

	/** raylib's `GetDirectoryPath` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetDirectoryPath(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetDirectoryPath", "raylib.h");

	/** raylib's `GetPrevDirectoryPath` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetPrevDirectoryPath(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetPrevDirectoryPath", "raylib.h");

	/** raylib's `GetWorkingDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetWorkingDirectory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetWorkingDirectory", "raylib.h");

	/** raylib's `GetApplicationDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetApplicationDirectory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetApplicationDirectory", "raylib.h");

	/** raylib's `MakeDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MakeDirectory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MakeDirectory", "raylib.h");

	/** raylib's `ChangeDirectory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ChangeDirectory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ChangeDirectory", "raylib.h");

	/** raylib's `IsPathFile` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsPathFile(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsPathFile", "raylib.h");

	/** raylib's `IsFileNameValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsFileNameValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsFileNameValid", "raylib.h");

	/** raylib's `LoadDirectoryFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadDirectoryFiles(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadDirectoryFiles", "raylib.h");

	/** raylib's `LoadDirectoryFilesEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadDirectoryFilesEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadDirectoryFilesEx", "raylib.h");

	/** raylib's `UnloadDirectoryFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadDirectoryFiles(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadDirectoryFiles", "raylib.h");

	/** raylib's `IsFileDropped` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsFileDropped(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsFileDropped", "raylib.h");

	/** raylib's `LoadDroppedFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadDroppedFiles(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadDroppedFiles", "raylib.h");

	/** raylib's `UnloadDroppedFiles` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadDroppedFiles(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadDroppedFiles", "raylib.h");

	/** raylib's `GetFileModTime` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetFileModTime(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetFileModTime", "raylib.h");

	/** raylib's `CompressData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function CompressData(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("CompressData", "raylib.h");

	/** raylib's `DecompressData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DecompressData(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DecompressData", "raylib.h");

	/** raylib's `EncodeDataBase64` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function EncodeDataBase64(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("EncodeDataBase64", "raylib.h");

	/** raylib's `DecodeDataBase64` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DecodeDataBase64(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DecodeDataBase64", "raylib.h");

	/** raylib's `ComputeCRC32` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ComputeCRC32(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ComputeCRC32", "raylib.h");

	/** raylib's `ComputeMD5` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ComputeMD5(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ComputeMD5", "raylib.h");

	/** raylib's `ComputeSHA1` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ComputeSHA1(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ComputeSHA1", "raylib.h");

	/** raylib's `LoadAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadAutomationEventList(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadAutomationEventList", "raylib.h");

	/** raylib's `UnloadAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadAutomationEventList(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadAutomationEventList", "raylib.h");

	/** raylib's `ExportAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportAutomationEventList(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportAutomationEventList", "raylib.h");

	/** raylib's `SetAutomationEventList` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetAutomationEventList(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetAutomationEventList", "raylib.h");

	/** raylib's `SetAutomationEventBaseFrame` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetAutomationEventBaseFrame(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetAutomationEventBaseFrame", "raylib.h");

	/** raylib's `StartAutomationEventRecording` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function StartAutomationEventRecording(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("StartAutomationEventRecording", "raylib.h");

	/** raylib's `StopAutomationEventRecording` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function StopAutomationEventRecording(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("StopAutomationEventRecording", "raylib.h");

	/** raylib's `PlayAutomationEvent` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function PlayAutomationEvent(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("PlayAutomationEvent", "raylib.h");

	/** raylib's `IsKeyPressedRepeat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsKeyPressedRepeat(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsKeyPressedRepeat", "raylib.h");

	/** raylib's `GetCharPressed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetCharPressed(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetCharPressed", "raylib.h");

	/** raylib's `SetGamepadMappings` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetGamepadMappings(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetGamepadMappings", "raylib.h");

	/** raylib's `SetGamepadVibration` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetGamepadVibration(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetGamepadVibration", "raylib.h");

	/** raylib's `SetMousePosition` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetMousePosition(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetMousePosition", "raylib.h");

	/** raylib's `SetMouseOffset` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetMouseOffset(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetMouseOffset", "raylib.h");

	/** raylib's `SetMouseScale` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetMouseScale(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetMouseScale", "raylib.h");

	/** raylib's `GetMouseWheelMoveV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMouseWheelMoveV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMouseWheelMoveV", "raylib.h");

	/** raylib's `SetMouseCursor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetMouseCursor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetMouseCursor", "raylib.h");

	/** raylib's `GetTouchPointId` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetTouchPointId(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetTouchPointId", "raylib.h");

	/** raylib's `SetGesturesEnabled` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetGesturesEnabled(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetGesturesEnabled", "raylib.h");

	/** raylib's `GetGestureHoldDuration` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGestureHoldDuration(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGestureHoldDuration", "raylib.h");

	/** raylib's `GetGestureDragVector` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGestureDragVector(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGestureDragVector", "raylib.h");

	/** raylib's `GetGestureDragAngle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGestureDragAngle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGestureDragAngle", "raylib.h");

	/** raylib's `GetGesturePinchVector` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGesturePinchVector(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGesturePinchVector", "raylib.h");

	/** raylib's `GetGesturePinchAngle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGesturePinchAngle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGesturePinchAngle", "raylib.h");

	/** raylib's `UpdateCameraPro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateCameraPro(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateCameraPro", "raylib.h");

	/** raylib's `SetShapesTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetShapesTexture(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetShapesTexture", "raylib.h");

	/** raylib's `GetShapesTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetShapesTexture(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetShapesTexture", "raylib.h");

	/** raylib's `GetShapesTextureRectangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetShapesTextureRectangle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetShapesTextureRectangle", "raylib.h");

	/** raylib's `DrawLineStrip` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawLineStrip(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawLineStrip", "raylib.h");

	/** raylib's `DrawLineBezier` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawLineBezier(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawLineBezier", "raylib.h");

	/** raylib's `DrawCircleSector` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCircleSector(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCircleSector", "raylib.h");

	/** raylib's `DrawCircleSectorLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCircleSectorLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCircleSectorLines", "raylib.h");

	/** raylib's `DrawCircleGradient` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCircleGradient(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCircleGradient", "raylib.h");

	/** raylib's `DrawEllipse` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawEllipse(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawEllipse", "raylib.h");

	/** raylib's `DrawEllipseLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawEllipseLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawEllipseLines", "raylib.h");

	/** raylib's `DrawRing` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRing(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRing", "raylib.h");

	/** raylib's `DrawRingLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRingLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRingLines", "raylib.h");

	/** raylib's `DrawRectanglePro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRectanglePro(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRectanglePro", "raylib.h");

	/** raylib's `DrawRectangleGradientV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRectangleGradientV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRectangleGradientV", "raylib.h");

	/** raylib's `DrawRectangleGradientH` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRectangleGradientH(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRectangleGradientH", "raylib.h");

	/** raylib's `DrawRectangleGradientEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRectangleGradientEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRectangleGradientEx", "raylib.h");

	/** raylib's `DrawRectangleRounded` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRectangleRounded(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRectangleRounded", "raylib.h");

	/** raylib's `DrawRectangleRoundedLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRectangleRoundedLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRectangleRoundedLines", "raylib.h");

	/** raylib's `DrawRectangleRoundedLinesEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRectangleRoundedLinesEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRectangleRoundedLinesEx", "raylib.h");

	/** raylib's `DrawTriangleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTriangleLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTriangleLines", "raylib.h");

	/** raylib's `DrawTriangleFan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTriangleFan(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTriangleFan", "raylib.h");

	/** raylib's `DrawTriangleStrip` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTriangleStrip(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTriangleStrip", "raylib.h");

	/** raylib's `DrawPoly` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawPoly(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawPoly", "raylib.h");

	/** raylib's `DrawPolyLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawPolyLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawPolyLines", "raylib.h");

	/** raylib's `DrawPolyLinesEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawPolyLinesEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawPolyLinesEx", "raylib.h");

	/** raylib's `DrawSplineLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineLinear(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineLinear", "raylib.h");

	/** raylib's `DrawSplineBasis` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineBasis(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineBasis", "raylib.h");

	/** raylib's `DrawSplineCatmullRom` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineCatmullRom(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineCatmullRom", "raylib.h");

	/** raylib's `DrawSplineBezierQuadratic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineBezierQuadratic(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineBezierQuadratic", "raylib.h");

	/** raylib's `DrawSplineBezierCubic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineBezierCubic(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineBezierCubic", "raylib.h");

	/** raylib's `DrawSplineSegmentLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineSegmentLinear(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineSegmentLinear", "raylib.h");

	/** raylib's `DrawSplineSegmentBasis` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineSegmentBasis(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineSegmentBasis", "raylib.h");

	/** raylib's `DrawSplineSegmentCatmullRom` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineSegmentCatmullRom(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineSegmentCatmullRom", "raylib.h");

	/** raylib's `DrawSplineSegmentBezierQuadratic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineSegmentBezierQuadratic(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineSegmentBezierQuadratic", "raylib.h");

	/** raylib's `DrawSplineSegmentBezierCubic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawSplineSegmentBezierCubic(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawSplineSegmentBezierCubic", "raylib.h");

	/** raylib's `GetSplinePointLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetSplinePointLinear(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetSplinePointLinear", "raylib.h");

	/** raylib's `GetSplinePointBasis` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetSplinePointBasis(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetSplinePointBasis", "raylib.h");

	/** raylib's `GetSplinePointCatmullRom` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetSplinePointCatmullRom(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetSplinePointCatmullRom", "raylib.h");

	/** raylib's `GetSplinePointBezierQuad` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetSplinePointBezierQuad(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetSplinePointBezierQuad", "raylib.h");

	/** raylib's `GetSplinePointBezierCubic` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetSplinePointBezierCubic(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetSplinePointBezierCubic", "raylib.h");

	/** raylib's `CheckCollisionCircleLine` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function CheckCollisionCircleLine(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("CheckCollisionCircleLine", "raylib.h");

	/** raylib's `CheckCollisionPointTriangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function CheckCollisionPointTriangle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("CheckCollisionPointTriangle", "raylib.h");

	/** raylib's `CheckCollisionPointLine` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function CheckCollisionPointLine(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("CheckCollisionPointLine", "raylib.h");

	/** raylib's `CheckCollisionPointPoly` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function CheckCollisionPointPoly(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("CheckCollisionPointPoly", "raylib.h");

	/** raylib's `CheckCollisionLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function CheckCollisionLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("CheckCollisionLines", "raylib.h");

	/** raylib's `GetCollisionRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetCollisionRec(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetCollisionRec", "raylib.h");

	/** raylib's `LoadImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImage(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImage", "raylib.h");

	/** raylib's `LoadImageRaw` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImageRaw(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImageRaw", "raylib.h");

	/** raylib's `LoadImageAnim` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImageAnim(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImageAnim", "raylib.h");

	/** raylib's `LoadImageAnimFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImageAnimFromMemory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImageAnimFromMemory", "raylib.h");

	/** raylib's `LoadImageFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImageFromMemory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImageFromMemory", "raylib.h");

	/** raylib's `LoadImageFromTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImageFromTexture(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImageFromTexture", "raylib.h");

	/** raylib's `LoadImageFromScreen` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImageFromScreen(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImageFromScreen", "raylib.h");

	/** raylib's `IsImageValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsImageValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsImageValid", "raylib.h");

	/** raylib's `UnloadImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadImage(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadImage", "raylib.h");

	/** raylib's `ExportImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportImage(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportImage", "raylib.h");

	/** raylib's `ExportImageToMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportImageToMemory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportImageToMemory", "raylib.h");

	/** raylib's `ExportImageAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportImageAsCode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportImageAsCode", "raylib.h");

	/** raylib's `GenImageColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageColor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageColor", "raylib.h");

	/** raylib's `GenImageGradientLinear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageGradientLinear(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageGradientLinear", "raylib.h");

	/** raylib's `GenImageGradientRadial` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageGradientRadial(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageGradientRadial", "raylib.h");

	/** raylib's `GenImageGradientSquare` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageGradientSquare(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageGradientSquare", "raylib.h");

	/** raylib's `GenImageChecked` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageChecked(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageChecked", "raylib.h");

	/** raylib's `GenImageWhiteNoise` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageWhiteNoise(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageWhiteNoise", "raylib.h");

	/** raylib's `GenImagePerlinNoise` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImagePerlinNoise(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImagePerlinNoise", "raylib.h");

	/** raylib's `GenImageCellular` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageCellular(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageCellular", "raylib.h");

	/** raylib's `GenImageText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageText(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageText", "raylib.h");

	/** raylib's `ImageCopy` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageCopy(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageCopy", "raylib.h");

	/** raylib's `ImageFromImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageFromImage(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageFromImage", "raylib.h");

	/** raylib's `ImageFromChannel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageFromChannel(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageFromChannel", "raylib.h");

	/** raylib's `ImageText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageText(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageText", "raylib.h");

	/** raylib's `ImageTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageTextEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageTextEx", "raylib.h");

	/** raylib's `ImageFormat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageFormat(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageFormat", "raylib.h");

	/** raylib's `ImageToPOT` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageToPOT(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageToPOT", "raylib.h");

	/** raylib's `ImageCrop` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageCrop(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageCrop", "raylib.h");

	/** raylib's `ImageAlphaCrop` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageAlphaCrop(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageAlphaCrop", "raylib.h");

	/** raylib's `ImageAlphaClear` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageAlphaClear(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageAlphaClear", "raylib.h");

	/** raylib's `ImageAlphaMask` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageAlphaMask(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageAlphaMask", "raylib.h");

	/** raylib's `ImageAlphaPremultiply` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageAlphaPremultiply(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageAlphaPremultiply", "raylib.h");

	/** raylib's `ImageBlurGaussian` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageBlurGaussian(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageBlurGaussian", "raylib.h");

	/** raylib's `ImageKernelConvolution` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageKernelConvolution(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageKernelConvolution", "raylib.h");

	/** raylib's `ImageResize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageResize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageResize", "raylib.h");

	/** raylib's `ImageResizeNN` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageResizeNN(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageResizeNN", "raylib.h");

	/** raylib's `ImageResizeCanvas` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageResizeCanvas(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageResizeCanvas", "raylib.h");

	/** raylib's `ImageMipmaps` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageMipmaps(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageMipmaps", "raylib.h");

	/** raylib's `ImageDither` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDither(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDither", "raylib.h");

	/** raylib's `ImageFlipVertical` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageFlipVertical(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageFlipVertical", "raylib.h");

	/** raylib's `ImageFlipHorizontal` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageFlipHorizontal(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageFlipHorizontal", "raylib.h");

	/** raylib's `ImageRotate` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageRotate(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageRotate", "raylib.h");

	/** raylib's `ImageRotateCW` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageRotateCW(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageRotateCW", "raylib.h");

	/** raylib's `ImageRotateCCW` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageRotateCCW(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageRotateCCW", "raylib.h");

	/** raylib's `ImageColorTint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageColorTint(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageColorTint", "raylib.h");

	/** raylib's `ImageColorInvert` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageColorInvert(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageColorInvert", "raylib.h");

	/** raylib's `ImageColorGrayscale` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageColorGrayscale(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageColorGrayscale", "raylib.h");

	/** raylib's `ImageColorContrast` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageColorContrast(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageColorContrast", "raylib.h");

	/** raylib's `ImageColorBrightness` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageColorBrightness(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageColorBrightness", "raylib.h");

	/** raylib's `ImageColorReplace` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageColorReplace(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageColorReplace", "raylib.h");

	/** raylib's `LoadImageColors` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImageColors(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImageColors", "raylib.h");

	/** raylib's `LoadImagePalette` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadImagePalette(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadImagePalette", "raylib.h");

	/** raylib's `UnloadImageColors` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadImageColors(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadImageColors", "raylib.h");

	/** raylib's `UnloadImagePalette` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadImagePalette(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadImagePalette", "raylib.h");

	/** raylib's `GetImageAlphaBorder` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetImageAlphaBorder(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetImageAlphaBorder", "raylib.h");

	/** raylib's `GetImageColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetImageColor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetImageColor", "raylib.h");

	/** raylib's `ImageClearBackground` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageClearBackground(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageClearBackground", "raylib.h");

	/** raylib's `ImageDrawPixel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawPixel(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawPixel", "raylib.h");

	/** raylib's `ImageDrawPixelV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawPixelV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawPixelV", "raylib.h");

	/** raylib's `ImageDrawLine` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawLine(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawLine", "raylib.h");

	/** raylib's `ImageDrawLineV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawLineV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawLineV", "raylib.h");

	/** raylib's `ImageDrawLineEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawLineEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawLineEx", "raylib.h");

	/** raylib's `ImageDrawCircle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawCircle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawCircle", "raylib.h");

	/** raylib's `ImageDrawCircleV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawCircleV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawCircleV", "raylib.h");

	/** raylib's `ImageDrawCircleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawCircleLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawCircleLines", "raylib.h");

	/** raylib's `ImageDrawCircleLinesV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawCircleLinesV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawCircleLinesV", "raylib.h");

	/** raylib's `ImageDrawRectangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawRectangle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawRectangle", "raylib.h");

	/** raylib's `ImageDrawRectangleV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawRectangleV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawRectangleV", "raylib.h");

	/** raylib's `ImageDrawRectangleRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawRectangleRec(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawRectangleRec", "raylib.h");

	/** raylib's `ImageDrawRectangleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawRectangleLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawRectangleLines", "raylib.h");

	/** raylib's `ImageDrawTriangle` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawTriangle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawTriangle", "raylib.h");

	/** raylib's `ImageDrawTriangleEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawTriangleEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawTriangleEx", "raylib.h");

	/** raylib's `ImageDrawTriangleLines` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawTriangleLines(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawTriangleLines", "raylib.h");

	/** raylib's `ImageDrawTriangleFan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawTriangleFan(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawTriangleFan", "raylib.h");

	/** raylib's `ImageDrawTriangleStrip` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawTriangleStrip(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawTriangleStrip", "raylib.h");

	/** raylib's `ImageDraw` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDraw(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDraw", "raylib.h");

	/** raylib's `ImageDrawText` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawText(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawText", "raylib.h");

	/** raylib's `ImageDrawTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ImageDrawTextEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ImageDrawTextEx", "raylib.h");

	/** raylib's `LoadTextureFromImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadTextureFromImage(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadTextureFromImage", "raylib.h");

	/** raylib's `LoadTextureCubemap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadTextureCubemap(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadTextureCubemap", "raylib.h");

	/** raylib's `UpdateTexture` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateTexture(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateTexture", "raylib.h");

	/** raylib's `UpdateTextureRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateTextureRec(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateTextureRec", "raylib.h");

	/** raylib's `GenTextureMipmaps` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenTextureMipmaps(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenTextureMipmaps", "raylib.h");

	/** raylib's `SetTextureWrap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetTextureWrap(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetTextureWrap", "raylib.h");

	/** raylib's `DrawTextureNPatch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTextureNPatch(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTextureNPatch", "raylib.h");

	/** raylib's `ColorIsEqual` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorIsEqual(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorIsEqual", "raylib.h");

	/** raylib's `ColorToInt` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorToInt(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorToInt", "raylib.h");

	/** raylib's `ColorToHSV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorToHSV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorToHSV", "raylib.h");

	/** raylib's `ColorFromHSV` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorFromHSV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorFromHSV", "raylib.h");

	/** raylib's `ColorTint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorTint(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorTint", "raylib.h");

	/** raylib's `ColorBrightness` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorBrightness(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorBrightness", "raylib.h");

	/** raylib's `ColorContrast` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorContrast(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorContrast", "raylib.h");

	/** raylib's `ColorAlphaBlend` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorAlphaBlend(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorAlphaBlend", "raylib.h");

	/** raylib's `ColorLerp` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ColorLerp(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ColorLerp", "raylib.h");

	/** raylib's `GetColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetColor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetColor", "raylib.h");

	/** raylib's `GetPixelColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetPixelColor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetPixelColor", "raylib.h");

	/** raylib's `SetPixelColor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetPixelColor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetPixelColor", "raylib.h");

	/** raylib's `GetPixelDataSize` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetPixelDataSize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetPixelDataSize", "raylib.h");

	/** raylib's `GetFontDefault` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetFontDefault(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetFontDefault", "raylib.h");

	/** raylib's `LoadFont` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadFont(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadFont", "raylib.h");

	/** raylib's `LoadFontEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadFontEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadFontEx", "raylib.h");

	/** raylib's `LoadFontFromImage` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadFontFromImage(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadFontFromImage", "raylib.h");

	/** raylib's `LoadFontFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadFontFromMemory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadFontFromMemory", "raylib.h");

	/** raylib's `IsFontValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsFontValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsFontValid", "raylib.h");

	/** raylib's `LoadFontData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadFontData(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadFontData", "raylib.h");

	/** raylib's `GenImageFontAtlas` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenImageFontAtlas(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenImageFontAtlas", "raylib.h");

	/** raylib's `UnloadFontData` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadFontData(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadFontData", "raylib.h");

	/** raylib's `UnloadFont` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadFont(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadFont", "raylib.h");

	/** raylib's `ExportFontAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportFontAsCode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportFontAsCode", "raylib.h");

	/** raylib's `DrawTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTextEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTextEx", "raylib.h");

	/** raylib's `DrawTextPro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTextPro(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTextPro", "raylib.h");

	/** raylib's `DrawTextCodepoint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTextCodepoint(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTextCodepoint", "raylib.h");

	/** raylib's `DrawTextCodepoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTextCodepoints(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTextCodepoints", "raylib.h");

	/** raylib's `SetTextLineSpacing` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetTextLineSpacing(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetTextLineSpacing", "raylib.h");

	/** raylib's `MeasureTextEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MeasureTextEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MeasureTextEx", "raylib.h");

	/** raylib's `GetGlyphIndex` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGlyphIndex(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGlyphIndex", "raylib.h");

	/** raylib's `GetGlyphInfo` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGlyphInfo(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGlyphInfo", "raylib.h");

	/** raylib's `GetGlyphAtlasRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetGlyphAtlasRec(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetGlyphAtlasRec", "raylib.h");

	/** raylib's `LoadUTF8` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadUTF8(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadUTF8", "raylib.h");

	/** raylib's `UnloadUTF8` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadUTF8(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadUTF8", "raylib.h");

	/** raylib's `LoadCodepoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadCodepoints(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadCodepoints", "raylib.h");

	/** raylib's `UnloadCodepoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadCodepoints(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadCodepoints", "raylib.h");

	/** raylib's `GetCodepointCount` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetCodepointCount(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetCodepointCount", "raylib.h");

	/** raylib's `GetCodepoint` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetCodepoint(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetCodepoint", "raylib.h");

	/** raylib's `GetCodepointNext` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetCodepointNext(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetCodepointNext", "raylib.h");

	/** raylib's `GetCodepointPrevious` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetCodepointPrevious(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetCodepointPrevious", "raylib.h");

	/** raylib's `CodepointToUTF8` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function CodepointToUTF8(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("CodepointToUTF8", "raylib.h");

	/** raylib's `TextCopy` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextCopy(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextCopy", "raylib.h");

	/** raylib's `TextIsEqual` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextIsEqual(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextIsEqual", "raylib.h");

	/** raylib's `TextLength` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextLength(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextLength", "raylib.h");

	/** raylib's `TextFormat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextFormat(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextFormat", "raylib.h");

	/** raylib's `TextSubtext` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextSubtext(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextSubtext", "raylib.h");

	/** raylib's `TextReplace` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextReplace(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextReplace", "raylib.h");

	/** raylib's `TextInsert` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextInsert(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextInsert", "raylib.h");

	/** raylib's `TextJoin` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextJoin(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextJoin", "raylib.h");

	/** raylib's `TextSplit` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextSplit(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextSplit", "raylib.h");

	/** raylib's `TextAppend` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextAppend(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextAppend", "raylib.h");

	/** raylib's `TextFindIndex` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextFindIndex(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextFindIndex", "raylib.h");

	/** raylib's `TextToUpper` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextToUpper(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextToUpper", "raylib.h");

	/** raylib's `TextToLower` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextToLower(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextToLower", "raylib.h");

	/** raylib's `TextToPascal` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextToPascal(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextToPascal", "raylib.h");

	/** raylib's `TextToSnake` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextToSnake(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextToSnake", "raylib.h");

	/** raylib's `TextToCamel` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextToCamel(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextToCamel", "raylib.h");

	/** raylib's `TextToInteger` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextToInteger(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextToInteger", "raylib.h");

	/** raylib's `TextToFloat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function TextToFloat(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("TextToFloat", "raylib.h");

	/** raylib's `DrawPoint3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawPoint3D(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawPoint3D", "raylib.h");

	/** raylib's `DrawCircle3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCircle3D(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCircle3D", "raylib.h");

	/** raylib's `DrawTriangle3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTriangle3D(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTriangle3D", "raylib.h");

	/** raylib's `DrawTriangleStrip3D` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawTriangleStrip3D(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawTriangleStrip3D", "raylib.h");

	/** raylib's `DrawCylinder` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCylinder(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCylinder", "raylib.h");

	/** raylib's `DrawCylinderEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCylinderEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCylinderEx", "raylib.h");

	/** raylib's `DrawCylinderWires` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCylinderWires(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCylinderWires", "raylib.h");

	/** raylib's `DrawCylinderWiresEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCylinderWiresEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCylinderWiresEx", "raylib.h");

	/** raylib's `DrawCapsule` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCapsule(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCapsule", "raylib.h");

	/** raylib's `DrawCapsuleWires` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawCapsuleWires(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawCapsuleWires", "raylib.h");

	/** raylib's `DrawRay` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawRay(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawRay", "raylib.h");

	/** raylib's `DrawModelWires` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawModelWires(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawModelWires", "raylib.h");

	/** raylib's `DrawModelWiresEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawModelWiresEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawModelWiresEx", "raylib.h");

	/** raylib's `DrawModelPoints` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawModelPoints(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawModelPoints", "raylib.h");

	/** raylib's `DrawModelPointsEx` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawModelPointsEx(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawModelPointsEx", "raylib.h");

	/** raylib's `DrawBillboard` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawBillboard(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawBillboard", "raylib.h");

	/** raylib's `DrawBillboardRec` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawBillboardRec(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawBillboardRec", "raylib.h");

	/** raylib's `DrawBillboardPro` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawBillboardPro(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawBillboardPro", "raylib.h");

	/** raylib's `UpdateMeshBuffer` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateMeshBuffer(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateMeshBuffer", "raylib.h");

	/** raylib's `DrawMeshInstanced` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DrawMeshInstanced(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DrawMeshInstanced", "raylib.h");

	/** raylib's `GenMeshTangents` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshTangents(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshTangents", "raylib.h");

	/** raylib's `ExportMesh` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportMesh(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportMesh", "raylib.h");

	/** raylib's `ExportMeshAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportMeshAsCode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportMeshAsCode", "raylib.h");

	/** raylib's `GenMeshPoly` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshPoly(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshPoly", "raylib.h");

	/** raylib's `GenMeshHemiSphere` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshHemiSphere(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshHemiSphere", "raylib.h");

	/** raylib's `GenMeshCylinder` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshCylinder(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshCylinder", "raylib.h");

	/** raylib's `GenMeshCone` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshCone(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshCone", "raylib.h");

	/** raylib's `GenMeshTorus` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshTorus(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshTorus", "raylib.h");

	/** raylib's `GenMeshKnot` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshKnot(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshKnot", "raylib.h");

	/** raylib's `GenMeshHeightmap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshHeightmap(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshHeightmap", "raylib.h");

	/** raylib's `GenMeshCubicmap` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GenMeshCubicmap(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GenMeshCubicmap", "raylib.h");

	/** raylib's `LoadMaterials` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadMaterials(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadMaterials", "raylib.h");

	/** raylib's `IsMaterialValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsMaterialValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsMaterialValid", "raylib.h");

	/** raylib's `UnloadMaterial` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadMaterial(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadMaterial", "raylib.h");

	/** raylib's `LoadModelAnimations` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadModelAnimations(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadModelAnimations", "raylib.h");

	/** raylib's `UpdateModelAnimation` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateModelAnimation(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateModelAnimation", "raylib.h");

	/** raylib's `UpdateModelAnimationBones` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateModelAnimationBones(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateModelAnimationBones", "raylib.h");

	/** raylib's `UnloadModelAnimation` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadModelAnimation(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadModelAnimation", "raylib.h");

	/** raylib's `UnloadModelAnimations` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadModelAnimations(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadModelAnimations", "raylib.h");

	/** raylib's `IsModelAnimationValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsModelAnimationValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsModelAnimationValid", "raylib.h");

	/** raylib's `GetRayCollisionQuad` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetRayCollisionQuad(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetRayCollisionQuad", "raylib.h");

	/** raylib's `LoadWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadWave(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadWave", "raylib.h");

	/** raylib's `LoadWaveFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadWaveFromMemory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadWaveFromMemory", "raylib.h");

	/** raylib's `IsWaveValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsWaveValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsWaveValid", "raylib.h");

	/** raylib's `LoadSoundFromWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadSoundFromWave(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadSoundFromWave", "raylib.h");

	/** raylib's `LoadSoundAlias` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadSoundAlias(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadSoundAlias", "raylib.h");

	/** raylib's `UpdateSound` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateSound(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateSound", "raylib.h");

	/** raylib's `UnloadWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadWave(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadWave", "raylib.h");

	/** raylib's `UnloadSoundAlias` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadSoundAlias(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadSoundAlias", "raylib.h");

	/** raylib's `ExportWave` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportWave(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportWave", "raylib.h");

	/** raylib's `ExportWaveAsCode` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ExportWaveAsCode(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ExportWaveAsCode", "raylib.h");

	/** raylib's `PauseSound` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function PauseSound(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("PauseSound", "raylib.h");

	/** raylib's `ResumeSound` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ResumeSound(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ResumeSound", "raylib.h");

	/** raylib's `SetSoundPitch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetSoundPitch(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetSoundPitch", "raylib.h");

	/** raylib's `SetSoundPan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetSoundPan(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetSoundPan", "raylib.h");

	/** raylib's `WaveCopy` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function WaveCopy(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("WaveCopy", "raylib.h");

	/** raylib's `WaveCrop` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function WaveCrop(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("WaveCrop", "raylib.h");

	/** raylib's `WaveFormat` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function WaveFormat(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("WaveFormat", "raylib.h");

	/** raylib's `LoadWaveSamples` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadWaveSamples(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadWaveSamples", "raylib.h");

	/** raylib's `UnloadWaveSamples` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadWaveSamples(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadWaveSamples", "raylib.h");

	/** raylib's `LoadMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadMusicStream", "raylib.h");

	/** raylib's `LoadMusicStreamFromMemory` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadMusicStreamFromMemory(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadMusicStreamFromMemory", "raylib.h");

	/** raylib's `IsMusicValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsMusicValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsMusicValid", "raylib.h");

	/** raylib's `UnloadMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadMusicStream", "raylib.h");

	/** raylib's `PlayMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function PlayMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("PlayMusicStream", "raylib.h");

	/** raylib's `IsMusicStreamPlaying` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsMusicStreamPlaying(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsMusicStreamPlaying", "raylib.h");

	/** raylib's `UpdateMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateMusicStream", "raylib.h");

	/** raylib's `StopMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function StopMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("StopMusicStream", "raylib.h");

	/** raylib's `PauseMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function PauseMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("PauseMusicStream", "raylib.h");

	/** raylib's `ResumeMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ResumeMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ResumeMusicStream", "raylib.h");

	/** raylib's `SeekMusicStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SeekMusicStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SeekMusicStream", "raylib.h");

	/** raylib's `SetMusicVolume` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetMusicVolume(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetMusicVolume", "raylib.h");

	/** raylib's `SetMusicPitch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetMusicPitch(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetMusicPitch", "raylib.h");

	/** raylib's `SetMusicPan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetMusicPan(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetMusicPan", "raylib.h");

	/** raylib's `GetMusicTimeLength` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMusicTimeLength(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMusicTimeLength", "raylib.h");

	/** raylib's `GetMusicTimePlayed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function GetMusicTimePlayed(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("GetMusicTimePlayed", "raylib.h");

	/** raylib's `LoadAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function LoadAudioStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("LoadAudioStream", "raylib.h");

	/** raylib's `IsAudioStreamValid` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsAudioStreamValid(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsAudioStreamValid", "raylib.h");

	/** raylib's `UnloadAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UnloadAudioStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UnloadAudioStream", "raylib.h");

	/** raylib's `UpdateAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function UpdateAudioStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("UpdateAudioStream", "raylib.h");

	/** raylib's `IsAudioStreamProcessed` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsAudioStreamProcessed(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsAudioStreamProcessed", "raylib.h");

	/** raylib's `PlayAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function PlayAudioStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("PlayAudioStream", "raylib.h");

	/** raylib's `PauseAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function PauseAudioStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("PauseAudioStream", "raylib.h");

	/** raylib's `ResumeAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function ResumeAudioStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("ResumeAudioStream", "raylib.h");

	/** raylib's `IsAudioStreamPlaying` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function IsAudioStreamPlaying(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("IsAudioStreamPlaying", "raylib.h");

	/** raylib's `StopAudioStream` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function StopAudioStream(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("StopAudioStream", "raylib.h");

	/** raylib's `SetAudioStreamVolume` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetAudioStreamVolume(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetAudioStreamVolume", "raylib.h");

	/** raylib's `SetAudioStreamPitch` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetAudioStreamPitch(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetAudioStreamPitch", "raylib.h");

	/** raylib's `SetAudioStreamPan` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetAudioStreamPan(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetAudioStreamPan", "raylib.h");

	/** raylib's `SetAudioStreamBufferSizeDefault` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetAudioStreamBufferSizeDefault(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetAudioStreamBufferSizeDefault", "raylib.h");

	/** raylib's `SetAudioStreamCallback` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function SetAudioStreamCallback(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("SetAudioStreamCallback", "raylib.h");

	/** raylib's `AttachAudioStreamProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function AttachAudioStreamProcessor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("AttachAudioStreamProcessor", "raylib.h");

	/** raylib's `DetachAudioStreamProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DetachAudioStreamProcessor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DetachAudioStreamProcessor", "raylib.h");

	/** raylib's `AttachAudioMixedProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function AttachAudioMixedProcessor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("AttachAudioMixedProcessor", "raylib.h");

	/** raylib's `DetachAudioMixedProcessor` (raylib.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function DetachAudioMixedProcessor(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("DetachAudioMixedProcessor", "raylib.h");

	/** raylib's `Normalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Normalize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Normalize", "raymath.h");

	/** raylib's `Wrap` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Wrap(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Wrap", "raymath.h");

	/** raylib's `FloatEquals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function FloatEquals(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("FloatEquals", "raymath.h");

	/** raylib's `Vector2AddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2AddValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2AddValue", "raymath.h");

	/** raylib's `Vector2SubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2SubtractValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2SubtractValue", "raymath.h");

	/** raylib's `Vector2DotProduct` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2DotProduct(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2DotProduct", "raymath.h");

	/** raylib's `Vector2DistanceSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2DistanceSqr(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2DistanceSqr", "raymath.h");

	/** raylib's `Vector2Angle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Angle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Angle", "raymath.h");

	/** raylib's `Vector2LineAngle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2LineAngle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2LineAngle", "raymath.h");

	/** raylib's `Vector2Negate` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Negate(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Negate", "raymath.h");

	/** raylib's `Vector2Divide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Divide(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Divide", "raymath.h");

	/** raylib's `Vector2Transform` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Transform(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Transform", "raymath.h");

	/** raylib's `Vector2Reflect` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Reflect(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Reflect", "raymath.h");

	/** raylib's `Vector2Min` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Min(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Min", "raymath.h");

	/** raylib's `Vector2Max` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Max(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Max", "raymath.h");

	/** raylib's `Vector2Rotate` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Rotate(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Rotate", "raymath.h");

	/** raylib's `Vector2MoveTowards` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2MoveTowards(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2MoveTowards", "raymath.h");

	/** raylib's `Vector2Invert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Invert(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Invert", "raymath.h");

	/** raylib's `Vector2Clamp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Clamp(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Clamp", "raymath.h");

	/** raylib's `Vector2Equals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Equals(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Equals", "raymath.h");

	/** raylib's `Vector2Refract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector2Refract(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector2Refract", "raymath.h");

	/** raylib's `Vector3AddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3AddValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3AddValue", "raymath.h");

	/** raylib's `Vector3SubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3SubtractValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3SubtractValue", "raymath.h");

	/** raylib's `Vector3Perpendicular` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Perpendicular(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Perpendicular", "raymath.h");

	/** raylib's `Vector3DistanceSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3DistanceSqr(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3DistanceSqr", "raymath.h");

	/** raylib's `Vector3Angle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Angle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Angle", "raymath.h");

	/** raylib's `Vector3Divide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Divide(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Divide", "raymath.h");

	/** raylib's `Vector3Project` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Project(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Project", "raymath.h");

	/** raylib's `Vector3Reject` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Reject(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Reject", "raymath.h");

	/** raylib's `Vector3OrthoNormalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3OrthoNormalize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3OrthoNormalize", "raymath.h");

	/** raylib's `Vector3RotateByQuaternion` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3RotateByQuaternion(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3RotateByQuaternion", "raymath.h");

	/** raylib's `Vector3MoveTowards` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3MoveTowards(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3MoveTowards", "raymath.h");

	/** raylib's `Vector3CubicHermite` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3CubicHermite(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3CubicHermite", "raymath.h");

	/** raylib's `Vector3Reflect` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Reflect(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Reflect", "raymath.h");

	/** raylib's `Vector3Min` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Min(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Min", "raymath.h");

	/** raylib's `Vector3Max` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Max(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Max", "raymath.h");

	/** raylib's `Vector3Barycenter` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Barycenter(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Barycenter", "raymath.h");

	/** raylib's `Vector3Unproject` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Unproject(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Unproject", "raymath.h");

	/** raylib's `Vector3ToFloatV` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3ToFloatV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3ToFloatV", "raymath.h");

	/** raylib's `Vector3Invert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Invert(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Invert", "raymath.h");

	/** raylib's `Vector3Clamp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Clamp(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Clamp", "raymath.h");

	/** raylib's `Vector3ClampValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3ClampValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3ClampValue", "raymath.h");

	/** raylib's `Vector3Equals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Equals(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Equals", "raymath.h");

	/** raylib's `Vector3Refract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector3Refract(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector3Refract", "raymath.h");

	/** raylib's `Vector4Zero` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Zero(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Zero", "raymath.h");

	/** raylib's `Vector4One` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4One(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4One", "raymath.h");

	/** raylib's `Vector4Add` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Add(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Add", "raymath.h");

	/** raylib's `Vector4AddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4AddValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4AddValue", "raymath.h");

	/** raylib's `Vector4Subtract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Subtract(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Subtract", "raymath.h");

	/** raylib's `Vector4SubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4SubtractValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4SubtractValue", "raymath.h");

	/** raylib's `Vector4Length` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Length(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Length", "raymath.h");

	/** raylib's `Vector4LengthSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4LengthSqr(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4LengthSqr", "raymath.h");

	/** raylib's `Vector4DotProduct` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4DotProduct(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4DotProduct", "raymath.h");

	/** raylib's `Vector4Distance` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Distance(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Distance", "raymath.h");

	/** raylib's `Vector4DistanceSqr` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4DistanceSqr(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4DistanceSqr", "raymath.h");

	/** raylib's `Vector4Scale` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Scale(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Scale", "raymath.h");

	/** raylib's `Vector4Multiply` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Multiply(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Multiply", "raymath.h");

	/** raylib's `Vector4Negate` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Negate(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Negate", "raymath.h");

	/** raylib's `Vector4Divide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Divide(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Divide", "raymath.h");

	/** raylib's `Vector4Normalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Normalize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Normalize", "raymath.h");

	/** raylib's `Vector4Min` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Min(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Min", "raymath.h");

	/** raylib's `Vector4Max` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Max(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Max", "raymath.h");

	/** raylib's `Vector4Lerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Lerp(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Lerp", "raymath.h");

	/** raylib's `Vector4MoveTowards` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4MoveTowards(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4MoveTowards", "raymath.h");

	/** raylib's `Vector4Invert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Invert(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Invert", "raymath.h");

	/** raylib's `Vector4Equals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function Vector4Equals(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("Vector4Equals", "raymath.h");

	/** raylib's `MatrixDeterminant` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixDeterminant(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixDeterminant", "raymath.h");

	/** raylib's `MatrixTrace` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixTrace(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixTrace", "raymath.h");

	/** raylib's `MatrixAdd` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixAdd(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixAdd", "raymath.h");

	/** raylib's `MatrixSubtract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixSubtract(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixSubtract", "raymath.h");

	/** raylib's `MatrixRotateZYX` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixRotateZYX(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixRotateZYX", "raymath.h");

	/** raylib's `MatrixFrustum` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixFrustum(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixFrustum", "raymath.h");

	/** raylib's `MatrixToFloatV` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixToFloatV(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixToFloatV", "raymath.h");

	/** raylib's `QuaternionAdd` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionAdd(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionAdd", "raymath.h");

	/** raylib's `QuaternionAddValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionAddValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionAddValue", "raymath.h");

	/** raylib's `QuaternionSubtract` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionSubtract(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionSubtract", "raymath.h");

	/** raylib's `QuaternionSubtractValue` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionSubtractValue(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionSubtractValue", "raymath.h");

	/** raylib's `QuaternionLength` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionLength(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionLength", "raymath.h");

	/** raylib's `QuaternionNormalize` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionNormalize(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionNormalize", "raymath.h");

	/** raylib's `QuaternionInvert` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionInvert(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionInvert", "raymath.h");

	/** raylib's `QuaternionMultiply` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionMultiply(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionMultiply", "raymath.h");

	/** raylib's `QuaternionScale` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionScale(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionScale", "raymath.h");

	/** raylib's `QuaternionDivide` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionDivide(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionDivide", "raymath.h");

	/** raylib's `QuaternionLerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionLerp(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionLerp", "raymath.h");

	/** raylib's `QuaternionNlerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionNlerp(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionNlerp", "raymath.h");

	/** raylib's `QuaternionSlerp` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionSlerp(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionSlerp", "raymath.h");

	/** raylib's `QuaternionCubicHermiteSpline` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionCubicHermiteSpline(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionCubicHermiteSpline", "raymath.h");

	/** raylib's `QuaternionFromVector3ToVector3` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionFromVector3ToVector3(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionFromVector3ToVector3", "raymath.h");

	/** raylib's `QuaternionFromMatrix` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionFromMatrix(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionFromMatrix", "raymath.h");

	/** raylib's `QuaternionToAxisAngle` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionToAxisAngle(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionToAxisAngle", "raymath.h");

	/** raylib's `QuaternionToEuler` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionToEuler(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionToEuler", "raymath.h");

	/** raylib's `QuaternionTransform` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionTransform(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionTransform", "raymath.h");

	/** raylib's `QuaternionEquals` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function QuaternionEquals(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("QuaternionEquals", "raymath.h");

	/** raylib's `MatrixDecompose` (raymath.h): not in helix-ray yet, so a call to it doesn't compile. */
	public static macro function MatrixDecompose(args:Array<Expr>):Expr
		return helix.ray.internal.Missing.refuse("MatrixDecompose", "raymath.h");

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

	/** Loads an image file as a texture: in a page from the files loaded before `main`, natively read now. A file loaded again shares
		its first load's texture, and the image goes to the GPU when first drawn.

		@param fileName  The file, as the program names it, such as "assets/player.png".
		@return  The texture; its `id` is 0 when the file couldn't be read. */
	public static function LoadTexture(fileName:String):Texture2D {
		var path = normalize(fileName);
		var image = Runtime.imageNow(path);
		if (image == null) {
			trace(Runtime.notLoaded("LoadTexture", path));
			return new Texture2D();
		}
		return new Texture2D(Textures.fromImage(path, image), image.width, image.height);
	}

	/** Frees a texture: one load of its file, the GPU's copy with the last.

		@param texture  The texture. */
	public static function UnloadTexture(texture:Texture2D):Void {
		if (texture.id != 0)
			Textures.release(texture.id);
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
		var handle = Textures.handle(texture.id);
		var corner = (i:Int, j:Int, u:Float, v:Float) -> flat(handle, dest.x + xs[i] * c - ys[j] * s, dest.y + xs[i] * s + ys[j] * c, u, v, tint);
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

	/** Loads a sound file whole. It decodes in the background; played before then, it starts once decoded. A file loaded again shares
		its first load's decoded sound.

		@param fileName  The file, as the program names it, such as "assets/coin.wav".
		@return  The sound. */
	public static function LoadSound(fileName:String):Sound {
		var sound = new Sound();
		if (Runtime.audio == null) {
			trace('LoadSound: InitAudioDevice first');
			return sound;
		}
		var path = normalize(fileName);
		sound.path = path;
		var entry = sounds.get(path);
		if (entry == null) {
			var made = {
				loaded: null,
				refs: 0,
				waiting: [],
				cancel: null,
				answers: []
			};
			entry = made;
			sounds.set(path, made);
			made.cancel = Runtime.audio.load(path, loaded -> {
				made.cancel = null;
				made.loaded = loaded;
				for (s in made.waiting)
					arrived(s, loaded);
				made.waiting = [];
				for (answer in made.answers)
					answer(null);
				made.answers = [];
			}, error -> {
				made.cancel = null;
				if (made.answers.length == 0)
					trace('LoadSound: $fileName: $error');
				for (answer in made.answers)
					answer(error);
				made.answers = [];
			});
		}
		entry.refs++;
		if (entry.loaded != null)
			sound.sound = entry.loaded;
		else
			entry.waiting.push(sound);
		return sound;
	}

	/** Frees a sound, stopping it: one load of its file, the decoded sound with the last.

		@param sound  The sound. */
	public static function UnloadSound(sound:Sound):Void {
		StopSound(sound);
		sound.unloaded = true;
		var entry = sounds.get(sound.path);
		sound.sound = null;
		if (entry == null)
			return;
		entry.waiting.remove(sound);
		if (--entry.refs > 0)
			return;
		sounds.remove(sound.path);
		if (entry.cancel != null)
			entry.cancel();
		if (entry.loaded != null && Runtime.audio != null)
			Runtime.audio.unload(entry.loaded);
	}

	// A sound's file decoded: it plays as often as it was asked to meanwhile.
	static function arrived(sound:Sound, loaded:helix.services.audio.Sound):Void {
		if (sound.unloaded)
			return;
		sound.sound = loaded;
		for (_ in 0...sound.waiting)
			PlaySound(sound);
		sound.waiting = 0;
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
		var bytes = Runtime.fileNow(path);
		if (bytes == null) {
			trace(Runtime.notLoaded("LoadFileText", path));
			return null;
		}
		return bytes.toString();
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

	// ---- Loading in a page: helix-ray's own, not raylib's ----

	/** Loads an image file as a texture, answering when it is ready: helix-ray's own, for a page, where `LoadTexture` answers only for a
		file already loaded (one the program names, so it was loaded before `main`, or one loaded this way). Natively the file is read
		at once. Either way the answer comes at a later frame, never during the call, and `LoadTexture` of the file answers at once after.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the texture.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	public static function LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(LoadTexture(path)) : refuse("LoadTextureAsync", path, error, failed));
	}

	/** Loads a model from a glTF or GLB file, with its images and the files it points to, answering when it is ready: helix-ray's own, as
		`LoadTextureAsync` is for textures.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the model.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	public static function LoadModelAsync(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(LoadModel(path)) : refuse("LoadModelAsync", path, error, failed));
	}

	/** Loads a sound file and decodes it, answering when it is ready to play at once: helix-ray's own, as `LoadTextureAsync` is for
		textures. `InitAudioDevice` comes first.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the sound.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	public static function LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Runtime.audio == null) {
			Runtime.later(() -> refuse("LoadSoundAsync", path, "InitAudioDevice first", failed));
			return;
		}
		var sound = LoadSound(path);
		var entry = sounds.get(path);
		if (entry.loaded != null)
			Runtime.later(() -> loaded(sound));
		else
			entry.answers.push(error -> error == null ? loaded(sound) : refuse("LoadSoundAsync", path, error, failed));
	}

	/** Reads a text file, answering when it is read: helix-ray's own, as `LoadTextureAsync` is for textures. A file `SaveFileText`
		wrote is answered from the saves.

		@param fileName  The file.
		@param loaded  Receives its text.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	public static function LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Runtime.saves != null && Runtime.saves.hasKey(SAVED + path)) {
			var text = Runtime.saves.getString(SAVED + path, "");
			Runtime.later(() -> loaded(text));
			return;
		}
		Runtime.fetch(path, error -> error == null ? loaded(Runtime.files.get(path).toString()) : refuse("LoadFileTextAsync", path, error, failed));
	}

	static function refuse(name:String, path:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			trace('$name: $path: $error');
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
		font = new Texture2D(Textures.fromHandle(Runtime.graphics.createTexture(size, size, [pixels])), size, size);
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
		Runtime.frame.view = toMatrix3D(GetCameraMatrix2D(camera));
	}

	/** Goes back to drawing in the screen's pixels. */
	public static function EndMode2D():Void {
		Runtime.frame.screen2D();
	}

	/** Returns a 2D camera's transform, from the world to the screen.

		@param camera  The camera.
		@return  The matrix. */
	public static function GetCameraMatrix2D(camera:Camera2D):Matrix {
		var m = new Matrix3D().makeTranslation(-camera.target.x, -camera.target.y, 0);
		m = new Matrix3D().compose(m, new Matrix3D().makeRotation(0, 0, 1, camera.rotation * DEG2RAD));
		m = new Matrix3D().compose(m, new Matrix3D().makeScale(camera.zoom, camera.zoom, 1));
		m = new Matrix3D().compose(m, new Matrix3D().makeTranslation(camera.offset.x, camera.offset.y, 0));
		return toMatrix(m);
	}

	/** Returns where a point in a 2D camera's world is on the screen.

		@param position  The point.
		@param camera  The camera.
		@return  The screen position. */
	public static function GetWorldToScreen2D(position:Vector2, camera:Camera2D):Vector2 {
		var p = toMatrix3D(GetCameraMatrix2D(camera)).transformPoint(position.x, position.y, 0);
		return new Vector2(p.x, p.y);
	}

	/** Returns where a screen position is in a 2D camera's world.

		@param position  The screen position.
		@param camera  The camera.
		@return  The point. */
	public static function GetScreenToWorld2D(position:Vector2, camera:Camera2D):Vector2 {
		var inverse = toMatrix3D(GetCameraMatrix2D(camera));
		inverse.invert();
		var p = inverse.transformPoint(position.x, position.y, 0);
		return new Vector2(p.x, p.y);
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
		return toMatrix(cameraView(camera));
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
		var inverse = new Matrix3D().compose(cameraView(camera), cameraProjection(camera, width / height));
		inverse.invert();
		function unproject(z:Float):Array<Float> {
			var p = [
				inverse.values[0] * x + inverse.values[4] * y + inverse.values[8] * z + inverse.values[12],
				inverse.values[1] * x + inverse.values[5] * y + inverse.values[9] * z + inverse.values[13],
				inverse.values[2] * x + inverse.values[6] * y + inverse.values[10] * z + inverse.values[14],
				inverse.values[3] * x + inverse.values[7] * y + inverse.values[11] * z + inverse.values[15]
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
		var m = new Matrix3D().compose(cameraView(camera), cameraProjection(camera, width / height)).values;
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

	/** Loads a model from a glTF or GLB file: its meshes, their materials and its images; in a page from the files loaded before `main`,
		natively read now. A file loaded again shares its first load's meshes and textures, with materials of its own; meshes go to the
		GPU when first drawn.

		@param fileName  The file, as the program names it, such as "assets/trophy.glb".
		@return  The model; with no meshes when the file couldn't be read. */
	public static function LoadModel(fileName:String):Model {
		var path = normalize(fileName);
		var lower = path.toLowerCase();
		if (!(StringTools.endsWith(lower, ".glb") || StringTools.endsWith(lower, ".gltf"))) {
			trace('LoadModel: $fileName: only glTF and GLB are read here');
			return new Model([], [Models.defaultMaterial(defaultShader())], []);
		}
		try {
			var model = Models.load(path, () -> Runtime.fileNow(path), defaultShader());
			if (model != null)
				return model;
			trace(Runtime.notLoaded("LoadModel", path));
		} catch (e:Dynamic) {
			trace('LoadModel: $fileName: $e');
		}
		return new Model([], [Models.defaultMaterial(defaultShader())], []);
	}

	/** Makes a model of one mesh, with the default material.

		@param mesh  The mesh.
		@return  The model. */
	public static function LoadModelFromMesh(mesh:Mesh):Model {
		return new Model([mesh], [Models.defaultMaterial(defaultShader())], [0]);
	}

	/** Returns whether a model has meshes.

		@param model  The model.
		@return  True when it has. */
	public static function IsModelValid(model:Model):Bool {
		return model.meshCount > 0;
	}

	/** Frees a model: one load of its file, its meshes and textures with the last; a model of a mesh, its meshes and its materials'
		textures at once.

		@param model  The model. */
	public static function UnloadModel(model:Model):Void {
		if (model.path != "") {
			Models.release(model);
			model.path = "";
			return;
		}
		for (mesh in model.meshes)
			Models.unload(mesh);
		for (m in model.materials)
			for (map in m.maps)
				if (map.texture.id != 0) {
					Textures.release(map.texture.id);
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
		var m = new Matrix3D().makeScale(scale.x, scale.y, scale.z);
		m = new Matrix3D().compose(m, new Matrix3D().makeRotation(rotationAxis.x, rotationAxis.y, rotationAxis.z, rotationAngle * DEG2RAD));
		m = new Matrix3D().compose(m, new Matrix3D().makeTranslation(position.x, position.y, position.z));
		var transform = new Matrix3D().compose(toMatrix3D(model.transform), m);
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
		drawMesh(mesh, material, toMatrix3D(transform), WHITE);
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
		var t = toMatrix3D(model.transform);
		var min = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
		var max = [Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];
		for (mesh in model.meshes) {
			var b = Models.bounds(mesh);
			for (x in [b.min.x, b.max.x])
				for (y in [b.min.y, b.max.y])
					for (z in [b.min.z, b.max.z]) {
						var p = t.transformPoint(x, y, z), q = [p.x, p.y, p.z];
						for (c in 0...3) {
							if (q[c] < min[c])
								min[c] = q[c];
							if (q[c] > max[c])
								max[c] = q[c];
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
		var t = toMatrix3D(transform);
		function corner(i:Int):Vector3 {
			var p = t.transformPoint(v[i * 3], v[i * 3 + 1], v[i * 3 + 2]);
			return new Vector3(p.x, p.y, p.z);
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
		var texture = new Texture2D(Textures.fromHandle(target), width, height);
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
		if (target.texture.id != 0)
			Textures.release(target.texture.id);
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
		shader.program.write(locIndex, toMatrix3D(mat).values);
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
			shader.program.textures[slot] = Textures.handle(texture.id);
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
		var p = toMatrix3D(mat).transformPoint(v.x, v.y, v.z);
		return new Vector3(p.x, p.y, p.z);
	}

	/** Returns a vector turned about an axis.

		@param v  The vector.
		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The turned vector. */
	public static function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float):Vector3 {
		var m = new Matrix3D().makeRotation(axis.x, axis.y, axis.z, angle);
		var p = m.transformPoint(v.x, v.y, v.z);
		return new Vector3(p.x, p.y, p.z);
	}

	// ---- raymath: Matrix and Quaternion ----

	/** Returns the identity matrix.

		@return  The matrix. */
	public static function MatrixIdentity():Matrix {
		return toMatrix(new Matrix3D());
	}

	/** Returns two matrices multiplied: left, then right.

		@param left  The first.
		@param right  The second.
		@return  The product. */
	public static function MatrixMultiply(left:Matrix, right:Matrix):Matrix {
		return toMatrix(new Matrix3D().compose(toMatrix3D(left), toMatrix3D(right)));
	}

	/** Returns a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	public static function MatrixTranslate(x:Float, y:Float, z:Float):Matrix {
		return toMatrix(new Matrix3D().makeTranslation(x, y, z));
	}

	/** Returns a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	public static function MatrixScale(x:Float, y:Float, z:Float):Matrix {
		return toMatrix(new Matrix3D().makeScale(x, y, z));
	}

	/** Returns a rotation about an axis.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotate(axis:Vector3, angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(axis.x, axis.y, axis.z, angle));
	}

	/** Returns a rotation about x.

		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotateX(angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(1, 0, 0, angle));
	}

	/** Returns a rotation about y.

		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotateY(angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(0, 1, 0, angle));
	}

	/** Returns a rotation about z.

		@param angle  The angle, in radians.
		@return  The matrix. */
	public static function MatrixRotateZ(angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(0, 0, 1, angle));
	}

	/** Returns rotations about x, then y, then z.

		@param angle  The angles, in radians.
		@return  The matrix. */
	public static function MatrixRotateXYZ(angle:Vector3):Matrix {
		var m = new Matrix3D().compose(new Matrix3D().makeRotation(1, 0, 0, angle.x), new Matrix3D().makeRotation(0, 1, 0, angle.y));
		return toMatrix(new Matrix3D().compose(m, new Matrix3D().makeRotation(0, 0, 1, angle.z)));
	}

	/** Returns a matrix inverted.

		@param mat  The matrix.
		@return  Its inverse. */
	public static function MatrixInvert(mat:Matrix):Matrix {
		var inverse = toMatrix3D(mat);
		inverse.invert();
		return toMatrix(inverse);
	}

	/** Returns a matrix transposed.

		@param mat  The matrix.
		@return  Its transpose. */
	public static function MatrixTranspose(mat:Matrix):Matrix {
		return toMatrix(new Matrix3D().copyFrom(toMatrix3D(mat)).transpose());
	}

	/** Returns a view looking from eye at target.

		@param eye  Where from.
		@param target  What at.
		@param up  Up.
		@return  The matrix. */
	public static function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix {
		return toMatrix(new Matrix3D().makeLookAt(eye.x, eye.y, eye.z, target.x, target.y, target.z, up.x, up.y, up.z));
	}

	/** Returns a perspective projection.

		@param fovY  The field of view, top to bottom, in radians.
		@param aspect  Width over height.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@return  The matrix. */
	public static function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float):Matrix {
		return toMatrix(new Matrix3D().makePerspective(fovY, aspect, nearPlane, farPlane));
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
		return toMatrix(new Matrix3D().makeOrthographic(left, right, bottom, top, nearPlane, farPlane));
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
		return toMatrix(new Matrix3D().makeQuaternionRotation(q.x, q.y, q.z, q.w));
	}

	// ---- What the 3D functions share ----
	static var shaderDefault:Null<Shader> = null;
	static final sounds = new Map<String, {
		loaded:Null<helix.services.audio.Sound>,
		refs:Int,
		waiting:Array<Sound>,
		cancel:Null<Void->Void>,
		answers:Array<Null<String>->Void>
	}>();
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
			return toMatrix3D(value).values;
		return [(value : Float)];
	}

	// raylib's Matrix, named by rows, and helix-math's, stored by columns: m0 to m3 the first column in both.
	static function toMatrix3D(m:Matrix):Matrix3D {
		var out = new Matrix3D(), v = out.values;
		var all = [
			m.m0, m.m1, m.m2, m.m3, m.m4, m.m5, m.m6, m.m7, m.m8, m.m9, m.m10, m.m11, m.m12, m.m13, m.m14, m.m15
		];
		for (i in 0...16)
			v[i] = all[i];
		return out;
	}

	static function toMatrix(m:Matrix3D):Matrix {
		var a = m.values;
		return new Matrix(a[0], a[4], a[8], a[12], a[1], a[5], a[9], a[13], a[2], a[6], a[10], a[14], a[3], a[7], a[11], a[15]);
	}

	static function cameraView(camera:Camera3D):Matrix3D {
		var p = camera.position, t = camera.target, u = camera.up;
		return new Matrix3D().makeLookAt(p.x, p.y, p.z, t.x, t.y, t.z, u.x, u.y, u.z);
	}

	// raylib's near and far planes, 0.01 and 1000.
	static function cameraProjection(camera:Camera3D, aspect:Float):Matrix3D {
		if (camera.projection == CAMERA_ORTHOGRAPHIC) {
			var top = camera.fovy / 2, right = top * aspect;
			return new Matrix3D().makeOrthographic(-right, right, -top, top, .01, 1000);
		}
		return new Matrix3D().makePerspective(camera.fovy * DEG2RAD, aspect, .01, 1000);
	}

	static function drawMesh(mesh:Mesh, material:Material, transform:Matrix3D, tint:Color):Void {
		if (mesh.gpu.buffers == null)
			Models.upload(mesh);
		if (mesh.gpu.buffers == null)
			return;
		var shader = material.shader == null || material.shader.program == null ? defaultShader() : material.shader;
		var c = material.maps[MATERIAL_MAP_DIFFUSE].color;
		var diffuse = [
			c.r / 255 * tint.r / 255,
			c.g / 255 * tint.g / 255,
			c.b / 255 * tint.b / 255,
			c.a / 255 * tint.a / 255
		];
		var textures = [for (i in 0...3) Textures.handle(material.maps[i].texture.id)];
		Runtime.frame.mesh(mesh, shader.program, transform, diffuse, textures);
	}
	#end
}
