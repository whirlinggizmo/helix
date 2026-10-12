#include "host.h"
#include "input.h"
#define SOKOL_APP_IMPL
#define SOKOL_LOG_IMPL
#define SOKOL_NO_ENTRY
#define SOKOL_GLCORE
#include "sokol_app.h"
#include "sokol_log.h"

static void (*init_cb)(void),(*cleanup_cb)(void);
static void (*frame_cb)(float);
int hy_width(void){return sapp_width();}int hy_height(void){return sapp_height();}
float hy_pixel_ratio(void){return sapp_dpi_scale();}
void hy_quit(void){sapp_request_quit();}
static void frame(void){frame_cb((float)sapp_frame_duration());}
static int key_code(sapp_keycode k){
 if(k==SAPP_KEYCODE_ENTER)return 13;if(k==SAPP_KEYCODE_ESCAPE)return 27;if(k==SAPP_KEYCODE_TAB)return 9;if(k==SAPP_KEYCODE_LEFT)return 37;if(k==SAPP_KEYCODE_UP)return 38;if(k==SAPP_KEYCODE_RIGHT)return 39;if(k==SAPP_KEYCODE_DOWN)return 40;return (int)k;
}
static void event(const sapp_event *e){
 int k=key_code(e->key_code);
 if(e->type==SAPP_EVENTTYPE_KEY_DOWN)hy_input_key(k,1);if(e->type==SAPP_EVENTTYPE_KEY_UP)hy_input_key(k,0);
 if(e->type==SAPP_EVENTTYPE_MOUSE_DOWN&&e->mouse_button==SAPP_MOUSEBUTTON_LEFT)hy_input_pointer(e->mouse_x,e->mouse_y,1);
 if(e->type==SAPP_EVENTTYPE_MOUSE_UP&&e->mouse_button==SAPP_MOUSEBUTTON_LEFT)hy_input_pointer(e->mouse_x,e->mouse_y,0);
 if(e->type==SAPP_EVENTTYPE_MOUSE_MOVE)hy_input_pointer(e->mouse_x,e->mouse_y,hy_pointer_down());
 if(e->type==SAPP_EVENTTYPE_UNFOCUSED)hy_input_focus(0);if(e->type==SAPP_EVENTTYPE_FOCUSED)hy_input_focus(1);
 if(e->type==SAPP_EVENTTYPE_SUSPENDED)hy_input_focus(0);if(e->type==SAPP_EVENTTYPE_RESUMED)hy_input_focus(1);
}

void hy_run(void (*init)(void),void (*tick)(float),void (*cleanup)(void)){
 init_cb=init;frame_cb=tick;cleanup_cb=cleanup;
 sapp_run(&(sapp_desc){.init_cb=init_cb,.frame_cb=frame,.cleanup_cb=cleanup_cb,.event_cb=event,
  .width=800,.height=600,.sample_count=1,.swap_interval=1,.high_dpi=false,.window_title="HeliX Haxe",.logger.func=slog_func});
}
