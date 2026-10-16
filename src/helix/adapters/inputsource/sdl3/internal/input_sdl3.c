#include "input.h"
#include "gamepad.h"
#include "lock.h"
#include <SDL3/SDL.h>

/* The SDL3 input source: an event watch puts SDL's window events in the shared queue as they arrive (input.h's codes: Key's numbers by
   physical position, framebuffer pixels, MouseButton's), and SDL's gamepads give gamepad.h's W3C standard layout. The watch runs where
   SDL adds the event (the host's event pump, on the main thread, for the window's events), so the queue's pushes take the lock. */

/* Key's number for each SDL scancode (a key's physical position on a US layout, as Key's are), 0 for one HeliX doesn't name. Right-hand
   modifiers keep their own numbers (344-347); NativeInputSource folds them. SDL's non-US backslash, the key beside left shift, is World1, as
   on X11; Windows' sokol_app calls it World2, which has no SDL scancode. */
static const short keys[SDL_SCANCODE_COUNT]={
 [SDL_SCANCODE_SPACE]=32,[SDL_SCANCODE_APOSTROPHE]=39,[SDL_SCANCODE_COMMA]=44,[SDL_SCANCODE_MINUS]=45,[SDL_SCANCODE_PERIOD]=46,
 [SDL_SCANCODE_SLASH]=47,[SDL_SCANCODE_0]=48,[SDL_SCANCODE_1]=49,[SDL_SCANCODE_2]=50,[SDL_SCANCODE_3]=51,[SDL_SCANCODE_4]=52,
 [SDL_SCANCODE_5]=53,[SDL_SCANCODE_6]=54,[SDL_SCANCODE_7]=55,[SDL_SCANCODE_8]=56,[SDL_SCANCODE_9]=57,[SDL_SCANCODE_SEMICOLON]=59,
 [SDL_SCANCODE_EQUALS]=61,[SDL_SCANCODE_A]=65,[SDL_SCANCODE_B]=66,[SDL_SCANCODE_C]=67,[SDL_SCANCODE_D]=68,[SDL_SCANCODE_E]=69,
 [SDL_SCANCODE_F]=70,[SDL_SCANCODE_G]=71,[SDL_SCANCODE_H]=72,[SDL_SCANCODE_I]=73,[SDL_SCANCODE_J]=74,[SDL_SCANCODE_K]=75,
 [SDL_SCANCODE_L]=76,[SDL_SCANCODE_M]=77,[SDL_SCANCODE_N]=78,[SDL_SCANCODE_O]=79,[SDL_SCANCODE_P]=80,[SDL_SCANCODE_Q]=81,
 [SDL_SCANCODE_R]=82,[SDL_SCANCODE_S]=83,[SDL_SCANCODE_T]=84,[SDL_SCANCODE_U]=85,[SDL_SCANCODE_V]=86,[SDL_SCANCODE_W]=87,
 [SDL_SCANCODE_X]=88,[SDL_SCANCODE_Y]=89,[SDL_SCANCODE_Z]=90,[SDL_SCANCODE_LEFTBRACKET]=91,[SDL_SCANCODE_BACKSLASH]=92,
 [SDL_SCANCODE_RIGHTBRACKET]=93,[SDL_SCANCODE_GRAVE]=96,[SDL_SCANCODE_NONUSBACKSLASH]=161,[SDL_SCANCODE_ESCAPE]=256,
 [SDL_SCANCODE_RETURN]=257,[SDL_SCANCODE_TAB]=258,[SDL_SCANCODE_BACKSPACE]=259,[SDL_SCANCODE_INSERT]=260,[SDL_SCANCODE_DELETE]=261,
 [SDL_SCANCODE_RIGHT]=262,[SDL_SCANCODE_LEFT]=263,[SDL_SCANCODE_DOWN]=264,[SDL_SCANCODE_UP]=265,[SDL_SCANCODE_PAGEUP]=266,
 [SDL_SCANCODE_PAGEDOWN]=267,[SDL_SCANCODE_HOME]=268,[SDL_SCANCODE_END]=269,[SDL_SCANCODE_CAPSLOCK]=280,[SDL_SCANCODE_SCROLLLOCK]=281,
 [SDL_SCANCODE_NUMLOCKCLEAR]=282,[SDL_SCANCODE_PRINTSCREEN]=283,[SDL_SCANCODE_PAUSE]=284,[SDL_SCANCODE_F1]=290,[SDL_SCANCODE_F2]=291,
 [SDL_SCANCODE_F3]=292,[SDL_SCANCODE_F4]=293,[SDL_SCANCODE_F5]=294,[SDL_SCANCODE_F6]=295,[SDL_SCANCODE_F7]=296,[SDL_SCANCODE_F8]=297,
 [SDL_SCANCODE_F9]=298,[SDL_SCANCODE_F10]=299,[SDL_SCANCODE_F11]=300,[SDL_SCANCODE_F12]=301,[SDL_SCANCODE_F13]=302,[SDL_SCANCODE_F14]=303,
 [SDL_SCANCODE_F15]=304,[SDL_SCANCODE_F16]=305,[SDL_SCANCODE_F17]=306,[SDL_SCANCODE_F18]=307,[SDL_SCANCODE_F19]=308,[SDL_SCANCODE_F20]=309,
 [SDL_SCANCODE_F21]=310,[SDL_SCANCODE_F22]=311,[SDL_SCANCODE_F23]=312,[SDL_SCANCODE_F24]=313,[SDL_SCANCODE_KP_0]=320,[SDL_SCANCODE_KP_1]=321,
 [SDL_SCANCODE_KP_2]=322,[SDL_SCANCODE_KP_3]=323,[SDL_SCANCODE_KP_4]=324,[SDL_SCANCODE_KP_5]=325,[SDL_SCANCODE_KP_6]=326,
 [SDL_SCANCODE_KP_7]=327,[SDL_SCANCODE_KP_8]=328,[SDL_SCANCODE_KP_9]=329,[SDL_SCANCODE_KP_PERIOD]=330,[SDL_SCANCODE_KP_DIVIDE]=331,
 [SDL_SCANCODE_KP_MULTIPLY]=332,[SDL_SCANCODE_KP_MINUS]=333,[SDL_SCANCODE_KP_PLUS]=334,[SDL_SCANCODE_KP_ENTER]=335,
 [SDL_SCANCODE_KP_EQUALS]=336,[SDL_SCANCODE_LSHIFT]=340,[SDL_SCANCODE_LCTRL]=341,[SDL_SCANCODE_LALT]=342,[SDL_SCANCODE_LGUI]=343,
 [SDL_SCANCODE_RSHIFT]=344,[SDL_SCANCODE_RCTRL]=345,[SDL_SCANCODE_RALT]=346,[SDL_SCANCODE_RGUI]=347,[SDL_SCANCODE_APPLICATION]=348,
 [SDL_SCANCODE_MENU]=348,
};

static helix_lock_t lock=HELIX_LOCK_INIT;
static int pads_changed=1,text_started;

/* The event's window's framebuffer pixels per window unit (1 unless the window has a high pixel density). */
static float density(SDL_WindowID id){
 SDL_Window *w=SDL_GetWindowFromID(id);float d=w?SDL_GetWindowPixelDensity(w):1;return d>0?d:1;
}
static void push(int type,int code,int value,float x,float y){helix_lock(&lock);helix_input_push(type,code,value,x,y);helix_unlock(&lock);}

/* A touch's finger, by SDL's 64-bit id, as a small number for the queue: its slot among the fingers down. */
static SDL_FingerID fingers[16];
static int finger(SDL_FingerID id,int down){
 for(int i=0;i<16;i++)if(fingers[i]==id){if(!down)fingers[i]=0;return i;}
 if(!down)return -1;
 for(int i=0;i<16;i++)if(!fingers[i]){fingers[i]=id;return i;}
 return -1;
}

/* UTF-8 text as code points, control characters dropped. */
static void text(const char *s){
 while(*s){
  Uint32 c=SDL_StepUTF8(&s,NULL);
  if(c>=32&&c!=127)push(HELIX_EVENT_CHAR,(int)c,0,0,0);
 }
}

static bool SDLCALL watch(void *userdata,SDL_Event *e){
 (void)userdata;
 switch(e->type){
  case SDL_EVENT_KEY_DOWN:case SDL_EVENT_KEY_UP:{
   int key=e->key.scancode<SDL_SCANCODE_COUNT?keys[e->key.scancode]:0;
   if(key)push(HELIX_EVENT_KEY,key,e->type==SDL_EVENT_KEY_DOWN,0,0);
   break;}
  case SDL_EVENT_TEXT_INPUT:text(e->text.text);break;
  /* Touch makes its own events (the hint below keeps SDL from making mouse events of it); a pen's mouse events are kept. */
  case SDL_EVENT_MOUSE_BUTTON_DOWN:case SDL_EVENT_MOUSE_BUTTON_UP:{
   if(e->button.which==SDL_TOUCH_MOUSEID)break;
   int b=e->button.button==SDL_BUTTON_LEFT?0:e->button.button==SDL_BUTTON_RIGHT?1:e->button.button==SDL_BUTTON_MIDDLE?2:-1;
   float d=density(e->button.windowID);
   if(b>=0)push(HELIX_EVENT_MOUSE_BUTTON,b,e->type==SDL_EVENT_MOUSE_BUTTON_DOWN,e->button.x*d,e->button.y*d);
   break;}
  case SDL_EVENT_MOUSE_MOTION:{
   if(e->motion.which==SDL_TOUCH_MOUSEID)break;
   float d=density(e->motion.windowID);push(HELIX_EVENT_MOUSE_MOVE,0,0,e->motion.x*d,e->motion.y*d);
   break;}
  /* SDL's wheel has right and away positive, as Key's wheel does; natural scrolling is already applied. */
  case SDL_EVENT_MOUSE_WHEEL:if(e->wheel.which!=SDL_TOUCH_MOUSEID)push(HELIX_EVENT_WHEEL,0,0,e->wheel.x,e->wheel.y);break;
  case SDL_EVENT_WINDOW_MOUSE_LEAVE:push(HELIX_EVENT_MOUSE_LEAVE,0,0,0,0);break;
  case SDL_EVENT_FINGER_DOWN:case SDL_EVENT_FINGER_MOTION:case SDL_EVENT_FINGER_UP:case SDL_EVENT_FINGER_CANCELED:{
   /* Fingers are in 0..1 of the window: framebuffer pixels by its size in pixels. */
   const int down=e->type==SDL_EVENT_FINGER_DOWN||e->type==SDL_EVENT_FINGER_MOTION;
   SDL_Window *w=SDL_GetWindowFromID(e->tfinger.windowID);int pw=0,ph=0;if(w)SDL_GetWindowSizeInPixels(w,&pw,&ph);
   int id=finger(e->tfinger.fingerID,down);
   if(id>=0)push(HELIX_EVENT_TOUCH,id,down,e->tfinger.x*pw,e->tfinger.y*ph);
   break;}
  case SDL_EVENT_WINDOW_FOCUS_LOST:case SDL_EVENT_WINDOW_MINIMIZED:case SDL_EVENT_WINDOW_HIDDEN:push(HELIX_EVENT_FOCUS,0,0,0,0);break;
  case SDL_EVENT_WINDOW_FOCUS_GAINED:case SDL_EVENT_WINDOW_RESTORED:push(HELIX_EVENT_FOCUS,0,1,0,0);break;
  case SDL_EVENT_GAMEPAD_ADDED:case SDL_EVENT_GAMEPAD_REMOVED:helix_lock(&lock);pads_changed=1;helix_unlock(&lock);break;
  default:break;
 }
 return true;
}

void helix_input_setup(void){
 SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS,"0");
 /* Gamepads are read whether the window has the keyboard or not, as evdev and XInput are; the input router clears input on focus loss. */
 SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS,"1");
 SDL_InitSubSystem(SDL_INIT_GAMEPAD);
 SDL_AddEventWatch(watch,NULL);
 helix_gamepad_setup();
}
void helix_input_shutdown(void){
 SDL_RemoveEventWatch(watch,NULL);
 helix_gamepad_shutdown();
 SDL_QuitSubSystem(SDL_INIT_GAMEPAD);
}
/* Text arrives once the window asks for it (SDL3 doesn't send it by default), asked once the window exists. */
void helix_input_poll(void){
 if(!text_started){
  int n=0;SDL_Window **windows=SDL_GetWindows(&n);
  if(windows&&n>0)text_started=SDL_StartTextInput(windows[0]);
  SDL_free(windows);
 }
 helix_gamepad_poll();
}

/* Gamepads: the first four SDL knows, each kept in its slot while connected. */
static SDL_Gamepad *pads[HELIX_GAMEPADS];

void helix_gamepad_setup(void){}
void helix_gamepad_shutdown(void){
 for(int i=0;i<HELIX_GAMEPADS;i++)if(pads[i]){SDL_CloseGamepad(pads[i]);pads[i]=NULL;}
}
void helix_gamepad_poll(void){
 helix_lock(&lock);int changed=pads_changed;pads_changed=0;helix_unlock(&lock);
 if(!changed)return;
 for(int i=0;i<HELIX_GAMEPADS;i++)if(pads[i]&&!SDL_GamepadConnected(pads[i])){SDL_CloseGamepad(pads[i]);pads[i]=NULL;}
 int n=0;SDL_JoystickID *ids=SDL_GetGamepads(&n);
 for(int k=0;ids&&k<n;k++){
  int open=0;
  for(int i=0;i<HELIX_GAMEPADS;i++)if(pads[i]&&SDL_GetGamepadID(pads[i])==ids[k])open=1;
  if(open)continue;
  for(int i=0;i<HELIX_GAMEPADS;i++)if(!pads[i]){pads[i]=SDL_OpenGamepad(ids[k]);break;}
 }
 SDL_free(ids);
}
int helix_gamepad_connected(int pad){return pad>=0&&pad<HELIX_GAMEPADS&&pads[pad]!=NULL;}
const char *helix_gamepad_name(int pad){const char *n=helix_gamepad_connected(pad)?SDL_GetGamepadName(pads[pad]):NULL;return n?n:"";}

/* The W3C standard layout's buttons, by index; 6 and 7, the triggers, are read from their axes. SDL's face buttons are by position, as
   W3C's are (south is 0 whatever its label). */
static const SDL_GamepadButton buttons[17]={
 SDL_GAMEPAD_BUTTON_SOUTH,SDL_GAMEPAD_BUTTON_EAST,SDL_GAMEPAD_BUTTON_WEST,SDL_GAMEPAD_BUTTON_NORTH,
 SDL_GAMEPAD_BUTTON_LEFT_SHOULDER,SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,SDL_GAMEPAD_BUTTON_INVALID,SDL_GAMEPAD_BUTTON_INVALID,
 SDL_GAMEPAD_BUTTON_BACK,SDL_GAMEPAD_BUTTON_START,SDL_GAMEPAD_BUTTON_LEFT_STICK,SDL_GAMEPAD_BUTTON_RIGHT_STICK,
 SDL_GAMEPAD_BUTTON_DPAD_UP,SDL_GAMEPAD_BUTTON_DPAD_DOWN,SDL_GAMEPAD_BUTTON_DPAD_LEFT,SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
 SDL_GAMEPAD_BUTTON_GUIDE,
};
int helix_gamepad_button(int pad,int button){
 if(!helix_gamepad_connected(pad)||button<0||button>16)return 0;
 if(button==6||button==7)return helix_gamepad_axis(pad,button==6?4:5)>0.5f;
 return SDL_GetGamepadButton(pads[pad],buttons[button]);
}
/* Sticks -1..1 with down and right positive (SDL's, and W3C's), triggers 0..1. */
float helix_gamepad_axis(int pad,int axis){
 static const SDL_GamepadAxis axes[6]={SDL_GAMEPAD_AXIS_LEFTX,SDL_GAMEPAD_AXIS_LEFTY,SDL_GAMEPAD_AXIS_RIGHTX,SDL_GAMEPAD_AXIS_RIGHTY,
  SDL_GAMEPAD_AXIS_LEFT_TRIGGER,SDL_GAMEPAD_AXIS_RIGHT_TRIGGER};
 if(!helix_gamepad_connected(pad)||axis<0||axis>5)return 0;
 float v=SDL_GetGamepadAxis(pads[pad],axes[axis])/32767.0f;
 return v<-1?-1:v>1?1:v;
}
