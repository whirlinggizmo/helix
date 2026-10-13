#include "host.h"
#include "input.h"
#define SOKOL_APP_IMPL
#define SOKOL_LOG_IMPL
#define SOKOL_NO_ENTRY
#define SOKOL_GLCORE
#include "sokol_app.h"
#include "sokol_log.h"
#define SOKOL_APP_UTILS_IMPL
#include "sokol_app_utils.h"

static void (*init_cb)(void),(*cleanup_cb)(void);
static void (*frame_cb)(float);
int helix_width(void){return sapp_width();}int helix_height(void){return sapp_height();}
float helix_pixel_ratio(void){return sapp_dpi_scale();}
void helix_quit(void){sapp_request_quit();}
/* The window, through sokol_app and sokol_app_utils: sizes and positions are the OS's pixels, which are logical here (high_dpi off). */
void helix_window_set_title(const char*title){sapp_set_window_title(title);}
int helix_window_width(void){int w=0,h=0;sapp_get_window_size(&w,&h);return w;}
int helix_window_height(void){int w=0,h=0;sapp_get_window_size(&w,&h);return h;}
void helix_window_set_size(int w,int h){sapp_set_window_size(w,h);}
int helix_window_can_move(void){return sapp_can_move_window();}
int helix_window_x(void){int x=0,y=0;sapp_get_window_position(&x,&y);return x;}
int helix_window_y(void){int x=0,y=0;sapp_get_window_position(&x,&y);return y;}
void helix_window_set_position(int x,int y){sapp_set_window_position(x,y);}
int helix_window_fullscreen(void){return sapp_is_fullscreen();}
void helix_window_set_fullscreen(int on){sapp_set_fullscreen(on!=0);}
int helix_window_visible(void){return sapp_window_visible();}
void helix_window_set_visible(int on){sapp_set_window_visible(on!=0);}
int helix_display_count(void){int n=sapp_num_displays();return n>0?n:1;}
int helix_display_current(void){int i=sapp_current_display();return i>=0?i:0;}
void helix_display_set(int i){sapp_set_display(i);}
int helix_display_x(int i){int x=0,y=0;sapp_display_position(i,&x,&y);return x;}
int helix_display_y(int i){int x=0,y=0;sapp_display_position(i,&x,&y);return y;}
int helix_display_width(int i){return sapp_display_width(i);}
int helix_display_height(int i){return sapp_display_height(i);}
const char*helix_display_name(int i){const char*n=sapp_display_name(i);return n?n:"";}
static void frame(void){frame_cb((float)sapp_frame_duration());}
/* Sokol's key codes are Key's values; right-hand modifiers become left-hand ones there. Mouse x/y are framebuffer pixels. */
static void event(const sapp_event *e){
 switch(e->type){
  case SAPP_EVENTTYPE_KEY_DOWN:helix_input_push(HELIX_EVENT_KEY,(int)e->key_code,1,0,0);break;
  case SAPP_EVENTTYPE_KEY_UP:helix_input_push(HELIX_EVENT_KEY,(int)e->key_code,0,0,0);break;
  case SAPP_EVENTTYPE_CHAR:if(e->char_code>=32&&e->char_code!=127)helix_input_push(HELIX_EVENT_CHAR,(int)e->char_code,0,0,0);break;
  case SAPP_EVENTTYPE_MOUSE_DOWN:helix_input_push(HELIX_EVENT_MOUSE_BUTTON,(int)e->mouse_button,1,e->mouse_x,e->mouse_y);break;
  case SAPP_EVENTTYPE_MOUSE_UP:helix_input_push(HELIX_EVENT_MOUSE_BUTTON,(int)e->mouse_button,0,e->mouse_x,e->mouse_y);break;
  case SAPP_EVENTTYPE_MOUSE_MOVE:helix_input_push(HELIX_EVENT_MOUSE_MOVE,0,0,e->mouse_x,e->mouse_y);break;
  /* Sokol's X11 scroll-left is positive x; Key's wheel has right positive, as the browser's. */
  case SAPP_EVENTTYPE_MOUSE_SCROLL:helix_input_push(HELIX_EVENT_WHEEL,0,0,-e->scroll_x,e->scroll_y);break;
  case SAPP_EVENTTYPE_TOUCHES_BEGAN:case SAPP_EVENTTYPE_TOUCHES_MOVED:case SAPP_EVENTTYPE_TOUCHES_ENDED:case SAPP_EVENTTYPE_TOUCHES_CANCELLED:
   for(int i=0;i<e->num_touches;i++){const sapp_touchpoint*t=&e->touches[i];if(!t->changed)continue;
    const int down=e->type==SAPP_EVENTTYPE_TOUCHES_BEGAN||e->type==SAPP_EVENTTYPE_TOUCHES_MOVED;helix_input_push(HELIX_EVENT_TOUCH,(int)t->identifier,down,t->pos_x,t->pos_y);}
   break;
  case SAPP_EVENTTYPE_UNFOCUSED:case SAPP_EVENTTYPE_SUSPENDED:helix_input_push(HELIX_EVENT_FOCUS,0,0,0,0);break;
  case SAPP_EVENTTYPE_FOCUSED:case SAPP_EVENTTYPE_RESUMED:helix_input_push(HELIX_EVENT_FOCUS,0,1,0,0);break;
  default:break;
 }
}

void helix_run(void (*init)(void),void (*tick)(float),void (*cleanup)(void)){
 init_cb=init;frame_cb=tick;cleanup_cb=cleanup;
 sapp_run(&(sapp_desc){.init_cb=init_cb,.frame_cb=frame,.cleanup_cb=cleanup_cb,.event_cb=event,
  .width=800,.height=600,.sample_count=1,.swap_interval=1,.high_dpi=false,.window_title="HeliX Haxe",.logger.func=slog_func});
}
