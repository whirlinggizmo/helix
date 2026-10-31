#include "events_sdl3.h"
#include "sdl3.h"
#include <SDL3/SDL.h>
#include <string.h>

/* SDL3's events, drained from SDL's one queue at each poll into records the Haxe adapters read (events_sdl3.h's kinds): the window's
   focus, visibility, size and close, and the player's first press, always; keys by physical position as Key numbers them, the mouse and
   fingers in framebuffer pixels, and gamepads connecting, only while their device is wanted. A device not wanted has its events turned off
   in SDL, and the gamepads' subsystem starts only when they are wanted. Gamepads' buttons and axes are read as state, in the W3C standard
   layout. */

/* Key's number for each SDL scancode (a key's physical position on a US layout, as Key's are), 0 for one Key doesn't name. Right-hand
   modifiers (344-347) are reported as the left-hand ones. SDL's non-US backslash, the key beside left shift, is World1, as on X11. */
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

typedef struct {int kind,code,value;float x,y;} record;
static record records[1024],current;
static int count,read_at,text_started,text_wanted;
/* The devices wanted (events_sdl3.h), whether the first press has come, and the devices whose events SDL was last told to deliver (-1:
   never told). */
static int wanted,unlocked,applied=-1;

/* Where the mouse last was, in framebuffer pixels; while locked, where its moves have taken it. */
static float mouse_x,mouse_y;
static int locked_mouse(void){SDL_Window *w=(SDL_Window*)helix_sdl3_window();return w&&SDL_GetWindowRelativeMouseMode(w);}

/* The cursor's shapes, made by SDL as first shown: CursorShape's order. */
static SDL_Cursor *cursors[12];
static const SDL_SystemCursor shapes[12]={SDL_SYSTEM_CURSOR_DEFAULT,SDL_SYSTEM_CURSOR_TEXT,SDL_SYSTEM_CURSOR_CROSSHAIR,SDL_SYSTEM_CURSOR_POINTER,
 SDL_SYSTEM_CURSOR_EW_RESIZE,SDL_SYSTEM_CURSOR_NS_RESIZE,SDL_SYSTEM_CURSOR_NWSE_RESIZE,SDL_SYSTEM_CURSOR_NESW_RESIZE,SDL_SYSTEM_CURSOR_MOVE,
 SDL_SYSTEM_CURSOR_NOT_ALLOWED,SDL_SYSTEM_CURSOR_WAIT,SDL_SYSTEM_CURSOR_PROGRESS};
void helix_mouse_set_cursor_visible(int on){if(on)SDL_ShowCursor();else SDL_HideCursor();}
int helix_mouse_cursor_visible(void){return SDL_CursorVisible();}
void helix_mouse_set_cursor_shape(int shape){
 if(shape<0||shape>=12)return;
 if(!cursors[shape])cursors[shape]=SDL_CreateSystemCursor(shapes[shape]);
 if(cursors[shape])SDL_SetCursor(cursors[shape]);
}
int helix_mouse_set_locked(int on){SDL_Window *w=(SDL_Window*)helix_sdl3_window();return w&&SDL_SetWindowRelativeMouseMode(w,on!=0);}
int helix_mouse_locked(void){return locked_mouse();}
int helix_mouse_warp(float x,float y){
 SDL_Window *w=(SDL_Window*)helix_sdl3_window();if(!w)return 0;
 float d=SDL_GetWindowPixelDensity(w);if(d<=0)d=1;
 SDL_WarpMouseInWindow(w,x/d,y/d);return 1;
}
void helix_mouse_dispose(void){
 SDL_Window *w=(SDL_Window*)helix_sdl3_window();if(w)SDL_SetWindowRelativeMouseMode(w,false);
 SDL_SetCursor(SDL_GetDefaultCursor());SDL_ShowCursor();
 for(int i=0;i<12;i++)if(cursors[i]){SDL_DestroyCursor(cursors[i]);cursors[i]=NULL;}
}

/* A full frame drops its newest events: a frame that long is already lost. */
static void add(int kind,int code,int value,float x,float y){if(count<1024)records[count++]=(record){kind,code,value,x,y};}

/* The event's window's framebuffer pixels per window unit (1 unless the window has a high pixel density). */
static float density(SDL_WindowID id){
 SDL_Window *w=SDL_GetWindowFromID(id);float d=w?SDL_GetWindowPixelDensity(w):1;return d>0?d:1;
}

/* A touch's finger, by SDL's 64-bit id, as a small number: its slot among the fingers down. */
static SDL_FingerID fingers[16];
static int finger(SDL_FingerID id,int down){
 for(int i=0;i<16;i++)if(fingers[i]==id){if(!down)fingers[i]=0;return i;}
 if(!down)return -1;
 for(int i=0;i<16;i++)if(!fingers[i]){fingers[i]=id;return i;}
 return -1;
}

/* Gamepads in four slots, each kept while connected; whether each one's triggers are down as buttons (past half way). */
static SDL_Gamepad *pads[4];
static int triggers[4][2];
static int pad_button(SDL_GamepadButton button);
/* The slot of the gamepad SDL knows by id, or -1. */
static int pad_slot(SDL_JoystickID id){
 for(int i=0;i<4;i++)if(pads[i]&&SDL_GetGamepadID(pads[i])==id)return i;
 return -1;
}
static void pad_added(SDL_JoystickID id){
 for(int i=0;i<4;i++)if(pads[i]&&SDL_GetGamepadID(pads[i])==id)return;
 for(int i=0;i<4;i++)if(!pads[i]){if((pads[i]=SDL_OpenGamepad(id))){triggers[i][0]=triggers[i][1]=0;add(HELIX_EVENTS_PAD_CONNECTED,i,0,0,0);}return;}
}
static void pad_removed(SDL_JoystickID id){
 for(int i=0;i<4;i++)if(pads[i]&&SDL_GetGamepadID(pads[i])==id){SDL_CloseGamepad(pads[i]);pads[i]=NULL;add(HELIX_EVENTS_PAD_DISCONNECTED,i,0,0,0);}
}

/* Typed text comes only while the window's text input is started (SDL3's design: on a phone that shows the keyboard, and Windows with a
   pad plugged in pops its touch keyboard for a started one). */
static void apply_text(void){
 SDL_Window *w=(SDL_Window*)helix_sdl3_window();
 if(!w||text_wanted==text_started)return;
 if(text_wanted)text_started=SDL_StartTextInput(w);
 else{SDL_StopTextInput(w);text_started=0;}
}

/* The first press, a key or a mouse button going down or a finger lifting, comes before that press's own record, once. */
static void press(void){if(!unlocked){unlocked=1;add(HELIX_EVENTS_UNLOCKED,0,0,0,0);}}

/* Turns SDL's events on for the devices wanted, and keeps the first press's on until it has come. */
static void apply_events(void){
 const int state=wanted|(unlocked?0:16);
 if(state==applied)return;
 applied=state;
 const int keys=wanted&HELIX_EVENTS_KEYBOARD,mouse=wanted&HELIX_EVENTS_MOUSE,touch=wanted&HELIX_EVENTS_TOUCH,locked=!unlocked;
 SDL_SetEventEnabled(SDL_EVENT_KEY_DOWN,keys||locked);SDL_SetEventEnabled(SDL_EVENT_KEY_UP,keys);SDL_SetEventEnabled(SDL_EVENT_TEXT_INPUT,keys);
 SDL_SetEventEnabled(SDL_EVENT_MOUSE_BUTTON_DOWN,mouse||locked);SDL_SetEventEnabled(SDL_EVENT_MOUSE_BUTTON_UP,mouse);
 SDL_SetEventEnabled(SDL_EVENT_MOUSE_MOTION,mouse);SDL_SetEventEnabled(SDL_EVENT_MOUSE_WHEEL,mouse);
 SDL_SetEventEnabled(SDL_EVENT_FINGER_UP,touch||locked);SDL_SetEventEnabled(SDL_EVENT_FINGER_DOWN,touch);
 SDL_SetEventEnabled(SDL_EVENT_FINGER_MOTION,touch);SDL_SetEventEnabled(SDL_EVENT_FINGER_CANCELED,touch);
}

static void text(const char *s){
 while(*s){
  Uint32 c=SDL_StepUTF8(&s,NULL);
  if(c>=32&&c!=127)add(HELIX_EVENTS_TEXT,(int)c,0,0,0);
 }
}

static void translate(SDL_Event *e){
 switch(e->type){
  case SDL_EVENT_KEY_DOWN:case SDL_EVENT_KEY_UP:{
   if(e->type==SDL_EVENT_KEY_DOWN&&!e->key.repeat)press();
   if(!(wanted&HELIX_EVENTS_KEYBOARD))break;
   int key=e->key.scancode<SDL_SCANCODE_COUNT?keys[e->key.scancode]:0;
   if(key>=344&&key<=347)key-=4;
   if(key)add(e->type==SDL_EVENT_KEY_DOWN?HELIX_EVENTS_KEY_DOWN:HELIX_EVENTS_KEY_UP,key,e->key.repeat,0,0);
   break;}
  case SDL_EVENT_TEXT_INPUT:if(wanted&HELIX_EVENTS_KEYBOARD)text(e->text.text);break;
  /* Touch makes its own events (the hint at setup keeps SDL from making mouse events of it); a pen's mouse events are kept. */
  case SDL_EVENT_MOUSE_BUTTON_DOWN:case SDL_EVENT_MOUSE_BUTTON_UP:{
   if(e->button.which==SDL_TOUCH_MOUSEID)break;
   if(e->type==SDL_EVENT_MOUSE_BUTTON_DOWN)press();
   if(!(wanted&HELIX_EVENTS_MOUSE))break;
   int b=e->button.button==SDL_BUTTON_LEFT?0:e->button.button==SDL_BUTTON_RIGHT?1:e->button.button==SDL_BUTTON_MIDDLE?2:-1;
   float d=density(e->button.windowID);
   /* A locked mouse's button is where its moves have taken it, the cursor being held still. */
   if(!locked_mouse()){mouse_x=e->button.x*d;mouse_y=e->button.y*d;}
   if(b>=0)add(e->type==SDL_EVENT_MOUSE_BUTTON_DOWN?HELIX_EVENTS_MOUSE_DOWN:HELIX_EVENTS_MOUSE_UP,b,0,mouse_x,mouse_y);
   break;}
  case SDL_EVENT_MOUSE_MOTION:{
   if(e->motion.which==SDL_TOUCH_MOUSEID||!(wanted&HELIX_EVENTS_MOUSE))break;
   float d=density(e->motion.windowID);
   /* A locked mouse moves on from where it was by each move's own distance, past the window's edges. */
   if(locked_mouse()){mouse_x+=e->motion.xrel*d;mouse_y+=e->motion.yrel*d;}else{mouse_x=e->motion.x*d;mouse_y=e->motion.y*d;}
   add(HELIX_EVENTS_MOUSE_MOVE,0,0,mouse_x,mouse_y);
   break;}
  /* SDL's wheel has right and away positive; natural scrolling is already applied. */
  case SDL_EVENT_MOUSE_WHEEL:if(e->wheel.which!=SDL_TOUCH_MOUSEID&&(wanted&HELIX_EVENTS_MOUSE))add(HELIX_EVENTS_WHEEL,0,0,e->wheel.x,e->wheel.y);break;
  case SDL_EVENT_WINDOW_MOUSE_LEAVE:if(wanted&HELIX_EVENTS_MOUSE)add(HELIX_EVENTS_MOUSE_LEAVE,0,0,0,0);break;
  case SDL_EVENT_FINGER_DOWN:case SDL_EVENT_FINGER_MOTION:case SDL_EVENT_FINGER_UP:case SDL_EVENT_FINGER_CANCELED:{
   /* Fingers are in 0..1 of the window: framebuffer pixels by its size in pixels. */
   const int down=e->type==SDL_EVENT_FINGER_DOWN||e->type==SDL_EVENT_FINGER_MOTION;
   if(e->type==SDL_EVENT_FINGER_UP)press();
   if(!(wanted&HELIX_EVENTS_TOUCH))break;
   SDL_Window *w=SDL_GetWindowFromID(e->tfinger.windowID);int pw=0,ph=0;if(w)SDL_GetWindowSizeInPixels(w,&pw,&ph);
   int known=0;for(int i=0;i<16;i++)if(fingers[i]==e->tfinger.fingerID)known=1;
   int id=finger(e->tfinger.fingerID,down);
   if(id>=0)add(!down?HELIX_EVENTS_TOUCH_UP:known?HELIX_EVENTS_TOUCH_MOVE:HELIX_EVENTS_TOUCH_DOWN,id,0,e->tfinger.x*pw,e->tfinger.y*ph);
   break;}
  case SDL_EVENT_WINDOW_FOCUS_LOST:helix_sdl3_set_focused(0);add(HELIX_EVENTS_FOCUS_LOST,0,0,0,0);break;
  case SDL_EVENT_WINDOW_FOCUS_GAINED:helix_sdl3_set_focused(1);add(HELIX_EVENTS_FOCUS_GAINED,0,0,0,0);break;
  case SDL_EVENT_WINDOW_MINIMIZED:case SDL_EVENT_WINDOW_HIDDEN:add(HELIX_EVENTS_HIDDEN,0,0,0,0);break;
  case SDL_EVENT_WINDOW_RESTORED:case SDL_EVENT_WINDOW_SHOWN:add(HELIX_EVENTS_SHOWN,0,0,0,0);break;
  case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:add(HELIX_EVENTS_RESIZED,e->window.data1,e->window.data2,0,0);break;
  case SDL_EVENT_QUIT:case SDL_EVENT_WINDOW_CLOSE_REQUESTED:add(HELIX_EVENTS_CLOSE_REQUESTED,0,0,0,0);break;
  case SDL_EVENT_GAMEPAD_ADDED:pad_added(e->gdevice.which);break;
  case SDL_EVENT_GAMEPAD_REMOVED:pad_removed(e->gdevice.which);break;
  case SDL_EVENT_GAMEPAD_BUTTON_DOWN:case SDL_EVENT_GAMEPAD_BUTTON_UP:{
   int slot=pad_slot(e->gbutton.which),button=pad_button((SDL_GamepadButton)e->gbutton.button);
   if(slot>=0&&button>=0)add(e->type==SDL_EVENT_GAMEPAD_BUTTON_DOWN?HELIX_EVENTS_PAD_BUTTON_DOWN:HELIX_EVENTS_PAD_BUTTON_UP,slot,button,0,0);
   break;}
  /* A trigger is a button too (W3C's 6 and 7), down past half way. */
  case SDL_EVENT_GAMEPAD_AXIS_MOTION:{
   int t=e->gaxis.axis==SDL_GAMEPAD_AXIS_LEFT_TRIGGER?0:e->gaxis.axis==SDL_GAMEPAD_AXIS_RIGHT_TRIGGER?1:-1,slot=pad_slot(e->gaxis.which);
   if(t<0||slot<0)break;
   int down=e->gaxis.value/32767.0f>0.5f;
   if(down!=triggers[slot][t]){triggers[slot][t]=down;add(down?HELIX_EVENTS_PAD_BUTTON_DOWN:HELIX_EVENTS_PAD_BUTTON_UP,slot,6+t,0,0);}
   break;}
  default:break;
 }
}

void helix_events_setup(void){
 SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS,"0");
 /* Gamepads are read whether the window has the keyboard or not; what focus loss releases is the caller's. */
 SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS,"1");
 wanted=0;applied=-1;
}
void helix_events_dispose(void){
 helix_events_want(HELIX_EVENTS_KEYBOARD|HELIX_EVENTS_MOUSE|HELIX_EVENTS_TOUCH|HELIX_EVENTS_GAMEPADS,0);
}
void helix_events_want(int device,int on){
 const int had=wanted&HELIX_EVENTS_GAMEPADS;
 wanted=on?wanted|device:wanted&~device;
 if((wanted&HELIX_EVENTS_GAMEPADS)&&!had)SDL_InitSubSystem(SDL_INIT_GAMEPAD);
 else if(!(wanted&HELIX_EVENTS_GAMEPADS)&&had){
  for(int i=0;i<4;i++)if(pads[i]){SDL_CloseGamepad(pads[i]);pads[i]=NULL;}
  SDL_QuitSubSystem(SDL_INIT_GAMEPAD);
 }
 if(!(wanted&HELIX_EVENTS_KEYBOARD))helix_events_set_text(0);
}
void helix_events_poll(void){
 count=0;read_at=0;
 apply_text();
 apply_events();
 SDL_Event e;
 while(SDL_PollEvent(&e))translate(&e);
 apply_events();
}
void helix_events_wait(int milliseconds){SDL_WaitEventTimeout(NULL,milliseconds);}
void helix_events_set_text(int on){text_wanted=on!=0;apply_text();}
int helix_events_next(void){if(read_at>=count)return 0;current=records[read_at++];return 1;}
int helix_events_kind(void){return current.kind;}
int helix_events_code(void){return current.code;}
int helix_events_value(void){return current.value;}
float helix_events_x(void){return current.x;}
float helix_events_y(void){return current.y;}

int helix_pad_rumble(int pad,float low,float high,int milliseconds){
 if(!helix_pad_connected(pad))return 0;
 float l=low<0?0:low>1?1:low,h=high<0?0:high>1?1:high;
 return SDL_RumbleGamepad(pads[pad],(Uint16)(l*65535),(Uint16)(h*65535),(Uint32)(milliseconds<0?0:milliseconds));
}
/* Each line SDL takes counts, whether it added a mapping or updated one. */
int helix_pad_add_mappings(const char *mappings){
 if(!mappings)return 0;
 int added=0;const char *line=mappings;
 while(*line){
  const char *end=strchr(line,'\n');size_t n=end?(size_t)(end-line):strlen(line);
  if(n>0&&line[0]!='#'){
   char *copy=SDL_malloc(n+1);
   if(copy){memcpy(copy,line,n);copy[n]=0;if(n&&copy[n-1]=='\r')copy[n-1]=0;if(copy[0]&&SDL_AddGamepadMapping(copy)>=0)added++;SDL_free(copy);}
  }
  line=end?end+1:line+n;
 }
 return added;
}
int helix_pad_connected(int pad){return pad>=0&&pad<4&&pads[pad]!=NULL;}
const char *helix_pad_name(int pad){const char *n=helix_pad_connected(pad)?SDL_GetGamepadName(pads[pad]):NULL;return n?n:"";}

/* The W3C standard layout's buttons, by index; 6 and 7, the triggers, are read from their axes. SDL's face buttons are by position, as
   W3C's are (south is 0 whatever its label). */
static const SDL_GamepadButton buttons[17]={
 SDL_GAMEPAD_BUTTON_SOUTH,SDL_GAMEPAD_BUTTON_EAST,SDL_GAMEPAD_BUTTON_WEST,SDL_GAMEPAD_BUTTON_NORTH,
 SDL_GAMEPAD_BUTTON_LEFT_SHOULDER,SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER,SDL_GAMEPAD_BUTTON_INVALID,SDL_GAMEPAD_BUTTON_INVALID,
 SDL_GAMEPAD_BUTTON_BACK,SDL_GAMEPAD_BUTTON_START,SDL_GAMEPAD_BUTTON_LEFT_STICK,SDL_GAMEPAD_BUTTON_RIGHT_STICK,
 SDL_GAMEPAD_BUTTON_DPAD_UP,SDL_GAMEPAD_BUTTON_DPAD_DOWN,SDL_GAMEPAD_BUTTON_DPAD_LEFT,SDL_GAMEPAD_BUTTON_DPAD_RIGHT,
 SDL_GAMEPAD_BUTTON_GUIDE,
};
/* The W3C index of an SDL button, or -1 for one the layout hasn't. */
static int pad_button(SDL_GamepadButton button){
 if(button==SDL_GAMEPAD_BUTTON_INVALID)return -1;
 for(int i=0;i<17;i++)if(buttons[i]==button)return i;
 return -1;
}
/* Sticks -1..1 with down and right positive (SDL's, and W3C's), triggers 0..1. */
float helix_pad_axis(int pad,int axis){
 static const SDL_GamepadAxis axes[6]={SDL_GAMEPAD_AXIS_LEFTX,SDL_GAMEPAD_AXIS_LEFTY,SDL_GAMEPAD_AXIS_RIGHTX,SDL_GAMEPAD_AXIS_RIGHTY,
  SDL_GAMEPAD_AXIS_LEFT_TRIGGER,SDL_GAMEPAD_AXIS_RIGHT_TRIGGER};
 if(!helix_pad_connected(pad)||axis<0||axis>5)return 0;
 float v=SDL_GetGamepadAxis(pads[pad],axes[axis])/32767.0f;
 return v<-1?-1:v>1?1:v;
}
int helix_pad_button(int pad,int button){
 if(!helix_pad_connected(pad)||button<0||button>16)return 0;
 if(button==6||button==7)return helix_pad_axis(pad,button==6?4:5)>0.5f;
 return SDL_GetGamepadButton(pads[pad],buttons[button]);
}
