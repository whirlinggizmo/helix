#include "hybrid.h"
#include "gamepad.h"
#include <math.h>
#include <stdlib.h>
#include <string.h>

/* Keyboard/pointer events come from Sokol; native gamepads use an OS adapter. */
static int held[256],pushes[256],lifts[256],focus=1;
static float mouse_x=-1,mouse_y=-1;
static int mouse_down,mouse_push,mouse_lift;

void hy_input_setup(void){hy_gamepad_setup();}
void hy_input_shutdown(void){hy_gamepad_shutdown();}
void hy_input_key(int key,int value){if(key<0||key>=256||value&&!focus)return;if(value&&!held[key])pushes[key]=1;if(!value&&held[key])lifts[key]=1;held[key]=value;}
void hy_input_pointer(float x,float y,int value){mouse_x=x;mouse_y=y;if(value&&!mouse_down)mouse_push=1;if(!value&&mouse_down)mouse_lift=1;mouse_down=value;}
void hy_input_focus(int value){focus=value;if(!value){for(int i=0;i<256;i++)hy_input_key(i,0);hy_input_pointer(-1,-1,0);memset(pushes,0,sizeof pushes);mouse_push=0;}}
void hy_input_poll(void){hy_gamepad_poll();}
void hy_input_consume(void){memset(pushes,0,sizeof pushes);memset(lifts,0,sizeof lifts);mouse_push=mouse_lift=0;}
int hy_key(int key){return key>=0&&key<256?held[key]:0;}int hy_key_pressed(int key){return key>=0&&key<256?pushes[key]:0;}int hy_key_released(int key){return key>=0&&key<256?lifts[key]:0;}
int hy_focused(void){return focus;}float hy_pointer_x(void){return mouse_x;}float hy_pointer_y(void){return mouse_y;}
int hy_pointer_down(void){return mouse_down;}int hy_pointer_pressed(void){return mouse_push;}int hy_pointer_released(void){return mouse_lift;}
int hy_pad_available(void){return hy_gamepad_available();}
int hy_pad_button(int button){return focus?hy_gamepad_button(button):0;}
float hy_pad_axis(int axis){return focus?hy_gamepad_axis(axis):0;}
