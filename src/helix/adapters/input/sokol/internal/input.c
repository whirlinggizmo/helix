#include "input.h"
#include "gamepad.h"

/* Keyboard, mouse, text and touch events come from Sokol in order; native gamepads use an OS adapter. */
typedef struct {int type,code,value;float x,y;} hy_event;
static hy_event queue[1024],current;
static int head,count,focus=1;

void hy_input_setup(void){hy_gamepad_setup();}
void hy_input_shutdown(void){hy_gamepad_shutdown();}
void hy_input_poll(void){hy_gamepad_poll();}
/* A full queue drops the newest events: a frame that long is already lost. */
void hy_input_push(int type,int code,int value,float x,float y){
 if(type==HY_EVENT_FOCUS)focus=value;
 if(count==1024)return;queue[(head+count++)%1024]=(hy_event){type,code,value,x,y};
}
int hy_input_next(void){if(!count)return 0;current=queue[head];head=(head+1)%1024;count--;return 1;}
int hy_event_type(void){return current.type;}int hy_event_code(void){return current.code;}int hy_event_value(void){return current.value;}
float hy_event_x(void){return current.x;}float hy_event_y(void){return current.y;}
int hy_focused(void){return focus;}
int hy_pad_connected(int pad){return hy_gamepad_connected(pad);}
const char*hy_pad_name(int pad){return hy_gamepad_name(pad);}
int hy_pad_button(int pad,int button){return focus?hy_gamepad_button(pad,button):0;}
float hy_pad_axis(int pad,int axis){return focus?hy_gamepad_axis(pad,axis):0;}
