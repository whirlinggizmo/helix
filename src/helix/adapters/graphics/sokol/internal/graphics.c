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
#include "shaders.h"

static sg_shader shaders[2];
static sg_sampler sampler,linear_sampler,mip_sampler;static uint32_t linear_textures[256],mip_textures[256];
/* Per pipeline slot: its kind (0 Sprite2D, 1 Color3D, 2 Lines3D). */
static int pipeline_kinds[256];
static int active,used[256],audit_enabled,frame_width,frame_height;
static void (*driver_audit_reset)(void);
static const char *(*driver_audit_json)(void);
static int frame_uploaded_bytes;static int vertex_reserved[256];
void helix_setup(void){
 sg_setup(&(sg_desc){.environment=sglue_environment(),.logger.func=slog_func});
 audit_enabled=getenv("HELIX_AUDIT")&&strcmp(getenv("HELIX_AUDIT"),"1")==0;
 if(!audit_enabled)sg_disable_stats();
 else {driver_audit_reset=(void (*)(void))dlsym(RTLD_DEFAULT,"helix_gl_audit_reset");driver_audit_json=(const char *(*)(void))dlsym(RTLD_DEFAULT,"helix_gl_audit_json");}
 shaders[0]=sg_make_shader(HELIX_SPRITE2D_SHADER_DESC(sg_query_backend()));
 shaders[1]=sg_make_shader(HELIX_COLOR3D_SHADER_DESC(sg_query_backend()));
 sampler=sg_make_sampler(&(sg_sampler_desc){.min_filter=SG_FILTER_NEAREST,.mag_filter=SG_FILTER_NEAREST,.wrap_u=SG_WRAP_CLAMP_TO_EDGE,.wrap_v=SG_WRAP_CLAMP_TO_EDGE});
 linear_sampler=sg_make_sampler(&(sg_sampler_desc){.min_filter=SG_FILTER_LINEAR,.mag_filter=SG_FILTER_LINEAR,.wrap_u=SG_WRAP_CLAMP_TO_EDGE,.wrap_v=SG_WRAP_CLAMP_TO_EDGE});
 /* Trilinear, for a linear texture with mipmaps: drawn smaller than itself without shimmering. */
 mip_sampler=sg_make_sampler(&(sg_sampler_desc){.min_filter=SG_FILTER_LINEAR,.mag_filter=SG_FILTER_LINEAR,.mipmap_filter=SG_FILTER_LINEAR,.wrap_u=SG_WRAP_CLAMP_TO_EDGE,.wrap_v=SG_WRAP_CLAMP_TO_EDGE});
 memset(linear_textures,0,sizeof linear_textures);memset(mip_textures,0,sizeof mip_textures);
 for(int i=0;i<2;i++)if(sg_query_shader_state(shaders[i])!=SG_RESOURCESTATE_VALID)abort();
}
void helix_shutdown(void){
 sg_destroy_sampler(sampler);sg_destroy_sampler(linear_sampler);sg_destroy_sampler(mip_sampler);
 for(int i=0;i<2;i++)sg_destroy_shader(shaders[i]);sg_shutdown();
}
/* levels mip levels, each half the last (at least 1), packed one after another in data. */
uint32_t helix_texture(int w,int h,const void *data,int bytes,int levels,int linear){
 if(w<=0||h<=0||w>4096||h>4096||!data||levels<1||levels>SG_MAX_MIPMAPS)return 0;
 sg_image_desc desc={.width=w,.height=h,.num_mipmaps=levels,.pixel_format=SG_PIXELFORMAT_RGBA8};
 size_t offset=0;int lw=w,lh=h;
 for(int i=0;i<levels;i++){
  const size_t size=(size_t)lw*(size_t)lh*4;
  desc.data.mip_levels[i]=(sg_range){(const char *)data+offset,size};offset+=size;
  lw=lw>1?lw/2:1;lh=lh>1?lh/2:1;
 }
 if(offset!=(size_t)bytes)return 0;
 sg_image image=sg_make_image(&desc);
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID)return 0;
 uint32_t view=sg_make_view(&(sg_view_desc){.texture.image=image}).id;
 if((view&0xffff)<256){linear_textures[view&0xffff]=linear?view:0;mip_textures[view&0xffff]=linear&&levels>1?view:0;}return view;
}
uint32_t helix_buffer(int capacity){
 if(capacity<=0||capacity%4)return 0;
 sg_buffer buffer=sg_make_buffer(&(sg_buffer_desc){.size=(size_t)capacity,.usage={.vertex_buffer=true,.write_transient=true}});
 if((buffer.id&0xffff)<256){int slot=buffer.id&0xffff;used[slot]=0;vertex_reserved[slot]=capacity*sg_query_buffer_info(buffer).num_slots;}return buffer.id;
}
uint32_t helix_pipeline(int kind,int alpha){
 if(kind<0||kind>2)return 0;
 const int three=kind!=0;
 sg_pipeline pipeline=sg_make_pipeline(&(sg_pipeline_desc){.shader=shaders[three],
  .layout=three?helix_color3d_layout():helix_sprite2d_layout(),
  .primitive_type=kind==2?SG_PRIMITIVETYPE_LINES:SG_PRIMITIVETYPE_TRIANGLES,
  .depth={.compare=three?SG_COMPAREFUNC_LESS_EQUAL:SG_COMPAREFUNC_ALWAYS,.write_enabled=three},.cull_mode=SG_CULLMODE_NONE,
  .colors[0].blend={.enabled=alpha!=0,.src_factor_rgb=SG_BLENDFACTOR_SRC_ALPHA,.dst_factor_rgb=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,.src_factor_alpha=SG_BLENDFACTOR_ONE,.dst_factor_alpha=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA}});
 if(sg_query_pipeline_state(pipeline)!=SG_RESOURCESTATE_VALID||(pipeline.id&0xffff)>=256){sg_destroy_pipeline(pipeline);return 0;}
 pipeline_kinds[pipeline.id&0xffff]=kind;return pipeline.id;
}
int helix_update(uint32_t id,const void *data,int bytes){
 sg_buffer buffer={id};int slot=id&0xffff;
 if(!active||!data||bytes<0||bytes%4||slot>=256||sg_query_buffer_state(buffer)!=SG_RESOURCESTATE_VALID||(size_t)bytes>sg_query_buffer_size(buffer))return 0;
 frame_uploaded_bytes+=bytes;
 if(bytes)sg_write_buffer_transient(&(sg_write_buffer_desc){.src.data={data,(size_t)bytes},.dst.buffer=buffer});used[slot]=bytes;return 1;
}
int helix_begin(int width,int height,uint32_t color){
 if(active||width<=0||height<=0)return 0;
 active=1;frame_width=width;frame_height=height;if(driver_audit_reset)driver_audit_reset();frame_uploaded_bytes=0;memset(used,0,sizeof used);
 const sg_color clear={(color>>24)/255.f,((color>>16)&255)/255.f,((color>>8)&255)/255.f,(color&255)/255.f};
 sg_begin_pass(&(sg_pass){.swapchain=sglue_swapchain(),.action={.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value=clear},.depth={.load_action=SG_LOADACTION_CLEAR,.clear_value=1.0f}}});
 return 1;
}
int helix_viewport(int x,int y,int w,int h){
 if(!active||w<=0||h<=0)return 0;
 sg_apply_viewport(x,y,w,h,false);return 1;
}
int helix_draw(uint32_t p,uint32_t b,uint32_t t,int vertices,int first_vertex,const void *uniforms,int uniform_bytes){
 int slot=b&0xffff,pslot=p&0xffff;
 if(!active||slot>=256||pslot>=256||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID||sg_query_buffer_state((sg_buffer){b})!=SG_RESOURCESTATE_VALID)return 0;
 const int kind=pipeline_kinds[pslot],stride=kind?HELIX_COLOR3D_STRIDE:HELIX_SPRITE2D_STRIDE,group=kind==2?2:3;
 if(vertices<=0||vertices%group||first_vertex<0||first_vertex%group||vertices>used[slot]/stride||first_vertex>used[slot]/stride-vertices)return 0;
 if(kind==0){
  if(uniforms||sg_query_view_state((sg_view){t})!=SG_RESOURCESTATE_VALID)return 0;
  sg_apply_pipeline((sg_pipeline){p});
  sg_apply_bindings(&(sg_bindings){.vertex_buffers[0]={b},.views[HELIX_SPRITE2D_VIEW_SLOT]={t},.samplers[HELIX_SPRITE2D_SAMPLER_SLOT]=(t&0xffff)>=256?sampler:mip_textures[t&0xffff]==t?mip_sampler:linear_textures[t&0xffff]==t?linear_sampler:sampler});
 }else{
  if(!uniforms||uniform_bytes!=HELIX_COLOR3D_UNIFORM_BYTES)return 0;
  sg_apply_pipeline((sg_pipeline){p});
  sg_apply_bindings(&(sg_bindings){.vertex_buffers[0]={b}});
  sg_apply_uniforms(HELIX_COLOR3D_UNIFORM_SLOT,&(sg_range){uniforms,(size_t)uniform_bytes});
 }
 sg_draw(first_vertex,vertices,1);return 1;
}
void helix_end(void){if(!active)abort();sg_end_pass();sg_commit();active=0;}
int helix_destroy(int kind,uint32_t id){
 if(kind==0&&sg_query_buffer_state((sg_buffer){id})==SG_RESOURCESTATE_VALID){sg_destroy_buffer((sg_buffer){id});if((id&0xffff)<256)vertex_reserved[id&0xffff]=0;return 1;}
 if(kind==1&&sg_query_view_state((sg_view){id})==SG_RESOURCESTATE_VALID){sg_image image=sg_query_view_image((sg_view){id});sg_destroy_view((sg_view){id});sg_destroy_image(image);return 1;}
 if(kind==2&&sg_query_pipeline_state((sg_pipeline){id})==SG_RESOURCESTATE_VALID){sg_destroy_pipeline((sg_pipeline){id});return 1;}return 0;
}
void helix_capture(const char *path){
 int w=sapp_width(),h=sapp_height();size_t row=(size_t)w*3;unsigned char *pixels=malloc(row*h);FILE *f=fopen(path,"wb");if(!pixels||!f)abort();
 glPixelStorei(GL_PACK_ALIGNMENT,1);glReadPixels(0,0,w,h,GL_RGB,GL_UNSIGNED_BYTE,pixels);if(glGetError())abort();
 fprintf(f,"P6\n%d %d\n255\n",w,h);for(int y=h-1;y>=0;y--)if(fwrite(pixels+row*y,1,row,f)!=row)abort();fclose(f);free(pixels);
}
const char *helix_renderer(void){return (const char*)glGetString(GL_RENDERER);}

/* Sokol's public counters count actual GL backend state calls after its cache.
   sg draw/write counters are actual API entries, separately labelled. Stats stay off in timing. */
const char *helix_graphics_audit(void){
 static char json[1024];
 if(!audit_enabled)return "null";
 sg_frame_stats f=sg_query_stats().prev_frame;
 snprintf(json,sizeof json,"{\"sgDraws\":%u,\"sgPipelines\":%u,\"sgBindings\":%u,\"sgUploads\":%u,\"uploadedBytes\":%d,\"glPrograms\":%u,\"glTextures\":%u,\"glSamplers\":%u,\"glBuffers\":%u,\"glAttributes\":%u,\"glRenderState\":%u,\"glUniforms\":%u,\"driver\":%s}",
  f.num_draw,f.num_apply_pipeline,f.num_apply_bindings,f.num_write_buffer_transient,frame_uploaded_bytes,
  f.gl.num_use_program,f.gl.num_bind_texture,f.gl.num_bind_sampler,f.gl.num_bind_buffer,f.gl.num_vertex_attrib_pointer,f.gl.num_render_state,f.gl.num_uniform,driver_audit_json?driver_audit_json():"null");
 return json;
}

double helix_peak_rss(void){struct rusage usage;if(getrusage(RUSAGE_SELF,&usage)!=0)return -1;return (double)usage.ru_maxrss*1024.0;}
int helix_vertex_reserved(void){int bytes=0;for(int i=0;i<256;i++)bytes+=vertex_reserved[i];return bytes;}
