#include "graphics.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <dlfcn.h>
#define SOKOL_GFX_IMPL
#define SOKOL_GLUE_IMPL
#define SOKOL_GLCORE
#include "sokol_gfx.h"
#include "sokol_app.h"
#include "sokol_glue.h"
#include "sokol_log.h"
#include "sprite.glsl.h"
#include "vertex_layout.h"

static sg_shader shader;
static sg_sampler sampler,linear_sampler;static uint32_t linear_textures[256];static sg_color clear_color={.015f,.025f,.045f,1};
void hy_clear_color(uint32_t color){clear_color=(sg_color){(color>>24)/255.f,((color>>16)&255)/255.f,((color>>8)&255)/255.f,(color&255)/255.f};}
static int active,used[256],audit_enabled;
static void (*driver_audit_reset)(void);
static const char *(*driver_audit_json)(void);
static int frame_uploaded_bytes;static int vertex_reserved[256];
void hy_setup(void){
 sg_setup(&(sg_desc){.environment=sglue_environment(),.logger.func=slog_func});
 audit_enabled=getenv("HELIX_AUDIT")&&strcmp(getenv("HELIX_AUDIT"),"1")==0;
 if(!audit_enabled)sg_disable_stats();
 else {driver_audit_reset=(void (*)(void))dlsym(RTLD_DEFAULT,"helix_gl_audit_reset");driver_audit_json=(const char *(*)(void))dlsym(RTLD_DEFAULT,"helix_gl_audit_json");}
 shader=sg_make_shader(HY_SHADER_DESC(sg_query_backend()));
 sampler=sg_make_sampler(&(sg_sampler_desc){.min_filter=SG_FILTER_NEAREST,.mag_filter=SG_FILTER_NEAREST,.wrap_u=SG_WRAP_CLAMP_TO_EDGE,.wrap_v=SG_WRAP_CLAMP_TO_EDGE});
 linear_sampler=sg_make_sampler(&(sg_sampler_desc){.min_filter=SG_FILTER_LINEAR,.mag_filter=SG_FILTER_LINEAR,.wrap_u=SG_WRAP_CLAMP_TO_EDGE,.wrap_v=SG_WRAP_CLAMP_TO_EDGE});
 memset(linear_textures,0,sizeof linear_textures);clear_color=(sg_color){.015f,.025f,.045f,1};
 if(sg_query_shader_state(shader)!=SG_RESOURCESTATE_VALID)abort();

}
void hy_shutdown(void){
 sg_destroy_sampler(sampler);sg_destroy_sampler(linear_sampler);sg_destroy_shader(shader);sg_shutdown();
}
uint32_t hy_texture(int w,int h,const void *data,int bytes,int linear){
 if(w<=0||h<=0||w>4096||h>4096||!data||bytes!=w*h*4)return 0;
 sg_image image=sg_make_image(&(sg_image_desc){.width=w,.height=h,.pixel_format=SG_PIXELFORMAT_RGBA8,.data.mip_levels[0]={data,(size_t)bytes}});
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID)return 0;
 uint32_t view=sg_make_view(&(sg_view_desc){.texture.image=image}).id;
 if((view&0xffff)<256)linear_textures[view&0xffff]=linear?view:0;return view;
}
uint32_t hy_buffer(int capacity){
 if(capacity<=0||capacity%HY_VERTEX_STRIDE)return 0;
 sg_buffer buffer=sg_make_buffer(&(sg_buffer_desc){.size=(size_t)capacity,.usage={.vertex_buffer=true,.write_transient=true}});
 if((buffer.id&0xffff)<256){int slot=buffer.id&0xffff;used[slot]=0;vertex_reserved[slot]=capacity*sg_query_buffer_info(buffer).num_slots;}return buffer.id;
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
 frame_uploaded_bytes+=bytes;
 if(bytes)sg_write_buffer_transient(&(sg_write_buffer_desc){.src.data={data,(size_t)bytes},.dst.buffer=buffer});used[slot]=bytes;return 1;
}
int hy_begin(int width,int height,int x,int y,int w,int h){
 if(active||width<=0||height<=0||w<=0||h<=0)return 0;
 active=1;if(driver_audit_reset)driver_audit_reset();frame_uploaded_bytes=0;memset(used,0,sizeof used);
 sg_begin_pass(&(sg_pass){.swapchain=sglue_swapchain(),.action.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value=clear_color}});
 sg_apply_viewport(x,y,w,h,false);return 1;
}
int hy_draw(uint32_t p,uint32_t b,uint32_t t,int vertices,int first_vertex){
 int slot=b&0xffff;
 if(!active||vertices<=0||vertices%3||slot>=256||first_vertex<0||first_vertex%3||vertices>used[slot]/HY_VERTEX_STRIDE||first_vertex>used[slot]/HY_VERTEX_STRIDE-vertices||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID||sg_query_buffer_state((sg_buffer){b})!=SG_RESOURCESTATE_VALID||sg_query_view_state((sg_view){t})!=SG_RESOURCESTATE_VALID)return 0;
 sg_apply_pipeline((sg_pipeline){p});sg_apply_bindings(&(sg_bindings){.vertex_buffers[0]={b},.views[HY_VIEW_SLOT]={t},.samplers[HY_SAMPLER_SLOT]=((t&0xffff)<256&&linear_textures[t&0xffff]==t)?linear_sampler:sampler});sg_draw(first_vertex,vertices,1);return 1;
}
void hy_end(void){if(!active)abort();sg_end_pass();sg_commit();active=0;}
int hy_destroy(int kind,uint32_t id){
 if(kind==0&&sg_query_buffer_state((sg_buffer){id})==SG_RESOURCESTATE_VALID){sg_destroy_buffer((sg_buffer){id});if((id&0xffff)<256)vertex_reserved[id&0xffff]=0;return 1;}
 if(kind==1&&sg_query_view_state((sg_view){id})==SG_RESOURCESTATE_VALID){sg_image image=sg_query_view_image((sg_view){id});sg_destroy_view((sg_view){id});sg_destroy_image(image);return 1;}
 if(kind==2&&sg_query_pipeline_state((sg_pipeline){id})==SG_RESOURCESTATE_VALID){sg_destroy_pipeline((sg_pipeline){id});return 1;}return 0;
}
void hy_capture(const char *path){
 int w=sapp_width(),h=sapp_height();size_t row=(size_t)w*3;unsigned char *pixels=malloc(row*h);FILE *f=fopen(path,"wb");if(!pixels||!f)abort();
 glPixelStorei(GL_PACK_ALIGNMENT,1);glReadPixels(0,0,w,h,GL_RGB,GL_UNSIGNED_BYTE,pixels);if(glGetError())abort();
 fprintf(f,"P6\n%d %d\n255\n",w,h);for(int y=h-1;y>=0;y--)if(fwrite(pixels+row*y,1,row,f)!=row)abort();fclose(f);free(pixels);
}
const char *hy_renderer(void){return (const char*)glGetString(GL_RENDERER);}

/* Sokol's public counters count actual GL backend state calls after its cache.
   sg draw/write counters are actual API entries, separately labelled. Stats stay off in timing. */
const char *hy_graphics_audit(void){
 static char json[1024];
 if(!audit_enabled)return "null";
 sg_frame_stats f=sg_query_stats().prev_frame;
 snprintf(json,sizeof json,"{\"sgDraws\":%u,\"sgPipelines\":%u,\"sgBindings\":%u,\"sgUploads\":%u,\"uploadedBytes\":%d,\"glPrograms\":%u,\"glTextures\":%u,\"glSamplers\":%u,\"glBuffers\":%u,\"glAttributes\":%u,\"glRenderState\":%u,\"glUniforms\":%u,\"driver\":%s}",
  f.num_draw,f.num_apply_pipeline,f.num_apply_bindings,f.num_write_buffer_transient,frame_uploaded_bytes,
  f.gl.num_use_program,f.gl.num_bind_texture,f.gl.num_bind_sampler,f.gl.num_bind_buffer,f.gl.num_vertex_attrib_pointer,f.gl.num_render_state,f.gl.num_uniform,driver_audit_json?driver_audit_json():"null");
 return json;
}

double hy_peak_rss(void){struct rusage usage;if(getrusage(RUSAGE_SELF,&usage)!=0)return -1;return (double)usage.ru_maxrss*1024.0;}
int hy_vertex_reserved(void){int bytes=0;for(int i=0;i<256;i++)bytes+=vertex_reserved[i];return bytes;}
