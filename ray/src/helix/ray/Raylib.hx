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
	frame. Natively a load reads its file when called, as raylib's does; a page loads before `main` the files its program names, and
	the `...Async` loads, helix-ray's own, bring in the rest. A file loaded twice is shared, and goes to the GPU when first drawn.
	`SaveFileText` writes are kept across runs. Shaders are raylib's GLSL, compiled as the program builds, so `LoadShader` names its
	files with constants. Its members are kept in files by raylib's modules (`helix.ray.raylib`); what raylib has and helix-ray doesn't
	refuses to compile, naming itself. */
#if !macro
@:build(helix.ray.internal.Sections.merge([
	{name: "RCore", id: "core"},
	{name: "RShapes", id: "shapes"},
	{name: "RTextures", id: "textures"},
	{name: "RText", id: "text"},
	{name: "RModels", id: "models"},
	{name: "RAudio", id: "audio"},
	{name: "RMath", id: "math"},
	{name: "HelixRay", id: "helix"}
]))
#end
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
	@:section("core", "rcore: the window and frame, input, files, cameras and shaders")
	public static macro function LoadShader(vsFileName:ExprOf<Null<String>>, fsFileName:ExprOf<Null<String>>):ExprOf<Shader> {
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
	@:section("core", "rcore: the window and frame, input, files, cameras and shaders")
	public static macro function LoadShaderFromMemory(vsCode:ExprOf<Null<String>>, fsCode:ExprOf<Null<String>>):ExprOf<Shader> {
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
}
