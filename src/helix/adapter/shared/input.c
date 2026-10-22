#include "input.h"
#include "gamepad.h"

/* The native input sources' queue: keyboard, mouse, text, touch and focus events pushed in order as the host delivers them (sokol_app's
   host pushes them, the SDL3 input adapter's event watch pushes SDL's), drained once a frame by NativeInputSource; and the gamepads the
   adapter's gamepad.h gives. Each input adapter supplies helix_input_setup, _shutdown and _poll. */
typedef struct {int type,code,value;float x,y;} helix_event;
static helix_event queue[1024],current;
static int head,count;

/* A full queue drops the newest events: a frame that long is already lost. */
void helix_input_push(int type,int code,int value,float x,float y){
 if(count==1024)return;queue[(head+count++)%1024]=(helix_event){type,code,value,x,y};
}
int helix_input_next(void){if(!count)return 0;current=queue[head];head=(head+1)%1024;count--;return 1;}
int helix_event_type(void){return current.type;}int helix_event_code(void){return current.code;}int helix_event_value(void){return current.value;}
float helix_event_x(void){return current.x;}float helix_event_y(void){return current.y;}
int helix_pad_slots(void){return HELIX_GAMEPADS;}
int helix_pad_connected(int pad){return helix_gamepad_connected(pad);}
const char*helix_pad_name(int pad){return helix_gamepad_name(pad);}
int helix_pad_button(int pad,int button){return helix_gamepad_button(pad,button);}
float helix_pad_axis(int pad,int axis){return helix_gamepad_axis(pad,axis);}
