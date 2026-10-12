#include "hybrid.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define SOKOL_IMPL
#define SOKOL_NO_ENTRY
#define SOKOL_GLCORE
#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"
#include "sokol_log.h"
#include "sprite.glsl.h"
#include "vertex_layout.h"

static sg_shader shader;
static sg_sampler sampler;
static int active,used[256];
static void (*init_cb)(void),(*cleanup_cb)(void);
static void (*frame_cb)(float);
void hy_setup(void){
 sg_setup(&(sg_desc){.environment=sglue_environment(),.logger.func=slog_func});
 shader=sg_make_shader(HY_SHADER_DESC(sg_query_backend()));
 sampler=sg_make_sampler(&(sg_sampler_desc){.min_filter=SG_FILTER_NEAREST,.mag_filter=SG_FILTER_NEAREST,.wrap_u=SG_WRAP_CLAMP_TO_EDGE,.wrap_v=SG_WRAP_CLAMP_TO_EDGE});
 if(sg_query_shader_state(shader)!=SG_RESOURCESTATE_VALID)abort();

}
void hy_shutdown(void){
 sg_destroy_sampler(sampler);sg_destroy_shader(shader);sg_shutdown();
}
uint32_t hy_texture(int w,int h,const void *data,int bytes){
 if(w<=0||h<=0||w>4096||h>4096||!data||bytes!=w*h*4)return 0;
 sg_image image=sg_make_image(&(sg_image_desc){.width=w,.height=h,.pixel_format=SG_PIXELFORMAT_RGBA8,.data.mip_levels[0]={data,(size_t)bytes}});
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID)return 0;
 return sg_make_view(&(sg_view_desc){.texture.image=image}).id;
}
uint32_t hy_buffer(int capacity){
 if(capacity<=0||capacity%HY_VERTEX_STRIDE)return 0;
 return sg_make_buffer(&(sg_buffer_desc){.size=(size_t)capacity,.usage={.vertex_buffer=true,.write_transient=true}}).id;
}
uint32_t hy_pipeline(int alpha){
 return sg_make_pipeline(&(sg_pipeline_desc){.shader=shader,
  .layout=hy_vertex_layout(),
  .depth.compare=SG_COMPAREFUNC_ALWAYS,.cull_mode=SG_CULLMODE_NONE,
  .colors[0].blend={.enabled=alpha!=0,.src_factor_rgb=SG_BLENDFACTOR_SRC_ALPHA,.dst_factor_rgb=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,.src_factor_alpha=SG_BLENDFACTOR_ONE,.dst_factor_alpha=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA}}).id;
}
int hy_update(uint32_t id,const void *data,int bytes){
 sg_buffer buffer={id};int slot=id&0xffff;
 if(!active||!data||bytes<0||bytes%HY_VERTEX_STRIDE||slot>=256||sg_query_buffer_state(buffer)!=SG_RESOURCESTATE_VALID||(size_t)bytes>sg_query_buffer_size(buffer))return 0;
 if(bytes)sg_write_buffer_transient(&(sg_write_buffer_desc){.src.data={data,(size_t)bytes},.dst.buffer=buffer});used[slot]=bytes;return 1;
}
int hy_begin(int width,int height,int x,int y,int w,int h){
 if(active||width<=0||height<=0||w<=0||h<=0)return 0;
 active=1;memset(used,0,sizeof used);
 sg_begin_pass(&(sg_pass){.swapchain=sglue_swapchain(),.action.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value={.015f,.025f,.045f,1}}});
 sg_apply_viewport(x,y,w,h,false);return 1;
}
int hy_draw(uint32_t p,uint32_t b,uint32_t t,int vertices){
 int slot=b&0xffff;
 if(!active||vertices<=0||vertices%3||slot>=256||vertices>used[slot]/HY_VERTEX_STRIDE||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID||sg_query_buffer_state((sg_buffer){b})!=SG_RESOURCESTATE_VALID||sg_query_view_state((sg_view){t})!=SG_RESOURCESTATE_VALID)return 0;
 sg_apply_pipeline((sg_pipeline){p});sg_apply_bindings(&(sg_bindings){.vertex_buffers[0]={b},.views[HY_VIEW_SLOT]={t},.samplers[HY_SAMPLER_SLOT]=sampler});sg_draw(0,vertices,1);return 1;
}
void hy_end(void){if(!active)abort();sg_end_pass();sg_commit();active=0;}
int hy_destroy(int kind,uint32_t id){
 if(kind==0&&sg_query_buffer_state((sg_buffer){id})==SG_RESOURCESTATE_VALID){sg_destroy_buffer((sg_buffer){id});return 1;}
 if(kind==1&&sg_query_view_state((sg_view){id})==SG_RESOURCESTATE_VALID){sg_image image=sg_query_view_image((sg_view){id});sg_destroy_view((sg_view){id});sg_destroy_image(image);return 1;}
 if(kind==2&&sg_query_pipeline_state((sg_pipeline){id})==SG_RESOURCESTATE_VALID){sg_destroy_pipeline((sg_pipeline){id});return 1;}return 0;
}
void hy_capture(const char *path){
 int w=sapp_width(),h=sapp_height();size_t row=(size_t)w*3;unsigned char *pixels=malloc(row*h);FILE *f=fopen(path,"wb");if(!pixels||!f)abort();
 glPixelStorei(GL_PACK_ALIGNMENT,1);glReadPixels(0,0,w,h,GL_RGB,GL_UNSIGNED_BYTE,pixels);if(glGetError())abort();
 fprintf(f,"P6\n%d %d\n255\n",w,h);for(int y=h-1;y>=0;y--)if(fwrite(pixels+row*y,1,row,f)!=row)abort();fclose(f);free(pixels);
}
const char *hy_renderer(void){return (const char*)glGetString(GL_RENDERER);}
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
  .width=800,.height=600,.sample_count=1,.swap_interval=1,.high_dpi=false,.window_title="Hybrid Haxe Asteroids",.logger.func=slog_func});
}
