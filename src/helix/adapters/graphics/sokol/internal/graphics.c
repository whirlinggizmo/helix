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

static sg_shader shaders[3];
/* Apps' programs (helix_shader), by shader slot: their uniform blocks' stages and sizes and their textures' count, by binding slot. A pipeline's
   app program, by pipeline slot (0 for the framework's). */
#define MAX_BLOCKS 4
#define MAX_TEXTURES 4
static struct{int blocks,texture_mask,block_size[MAX_BLOCKS];}programs[256];static uint32_t pipeline_shaders[256];
static sg_sampler sampler_of(int sampling);
/* One sampler for each Sampling value used (helix.graphics.Sampling: bit 0 linear, bits 1-2 wrap u, bits 3-4 wrap v), made when first used. */
static sg_sampler samplers[32];
/* Per pipeline slot: its kind (0 Sprite2D, 1 Color3D, 2 Lines3D, 3 Lit3D). Per buffer slot: whether it is an index buffer. */
static int pipeline_kinds[256],index_buffers[256];
/* active: 1 in the screen's pass, 2 in a target's; flipped: the pass is drawn flipped (GL, whose framebuffers' origin is the bottom left, into a
   target), so a target is stored top row first, as every texture is. */
static int active,flipped,used[256],audit_enabled,frame_width,frame_height;
/* A stream buffer written again after a draw bound it this frame takes another sokol buffer of the same size, as sokol allows writes only
   before a bind: renamed[slot] is how many of its extras are in use this frame, bound[slot] whether the current one was bound since its write. */
#define MAX_RENAMES 8
static sg_buffer extras[256][MAX_RENAMES];static int renamed[256],bound[256];
/* Render targets, by texture view slot: their color and depth attachment views, depth image and size. A Lit3D pipeline's flipped twin (its
   front faces clockwise), by pipeline slot. */
static struct{sg_view color,depth;sg_image depth_image;int width,height;}targets[256];static sg_pipeline flipped_pipelines[256];
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
 shaders[2]=sg_make_shader(HELIX_LIT3D_SHADER_DESC(sg_query_backend()));
 memset(samplers,0,sizeof samplers);
 for(int i=0;i<3;i++)if(sg_query_shader_state(shaders[i])!=SG_RESOURCESTATE_VALID)abort();
}
void helix_shutdown(void){
 for(int i=0;i<32;i++)if(samplers[i].id)sg_destroy_sampler(samplers[i]);
 for(int i=0;i<3;i++)sg_destroy_shader(shaders[i]);sg_shutdown();
}
/* helix.graphics.TextureFormat's values as sokol's: RGBA8, BC7, ASTC 4x4, ETC2 RGBA8. */
static sg_pixel_format format_of(int format){
 switch(format){case 0:return SG_PIXELFORMAT_RGBA8;case 1:return SG_PIXELFORMAT_BC7_RGBA;case 2:return SG_PIXELFORMAT_ASTC_4x4_RGBA;
  case 3:return SG_PIXELFORMAT_ETC2_RGBA8;default:return SG_PIXELFORMAT_NONE;}
}
int helix_can_sample(int format){sg_pixel_format f=format_of(format);return f!=SG_PIXELFORMAT_NONE&&sg_query_pixelformat(f).sample;}
/* levels mip levels of format, each half the last (at least 1), packed one after another in data. */
uint32_t helix_texture(int w,int h,const void *data,int bytes,int levels,int format){
 if(w<=0||h<=0||w>16384||h>16384||!data||levels<1||levels>SG_MAX_MIPMAPS||!helix_can_sample(format))return 0;
 sg_image_desc desc={.width=w,.height=h,.num_mipmaps=levels,.pixel_format=format_of(format)};
 size_t offset=0;int lw=w,lh=h;
 for(int i=0;i<levels;i++){
  const size_t size=format==0?(size_t)lw*(size_t)lh*4:(size_t)((lw+3)/4)*(size_t)((lh+3)/4)*16;
  desc.data.mip_levels[i]=(sg_range){(const char *)data+offset,size};offset+=size;
  lw=lw>1?lw/2:1;lh=lh>1?lh/2:1;
 }
 if(offset!=(size_t)bytes)return 0;
 sg_image image=sg_make_image(&desc);
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID)return 0;
 return sg_make_view(&(sg_view_desc){.texture.image=image}).id;
}
uint32_t helix_buffer(int capacity){
 if(capacity<=0||capacity%4)return 0;
 sg_buffer buffer=sg_make_buffer(&(sg_buffer_desc){.size=(size_t)capacity,.usage={.vertex_buffer=true,.write_transient=true}});
 if((buffer.id&0xffff)<256){int slot=buffer.id&0xffff;used[slot]=0;index_buffers[slot]=0;vertex_reserved[slot]=capacity*sg_query_buffer_info(buffer).num_slots;
  renamed[slot]=bound[slot]=0;memset(extras[slot],0,sizeof extras[slot]);}return buffer.id;
}
/* The sokol buffer a stream buffer's draws read now: itself, or the extra its latest write went to. */
static sg_buffer current_buffer(uint32_t id){int slot=id&0xffff;return slot<256&&renamed[slot]?extras[slot][renamed[slot]-1]:(sg_buffer){id};}
/* An immutable vertex buffer, or an index buffer of uint32 indices, holding the bytes of data (neither write flag: immutable). */
uint32_t helix_static_buffer(const void *data,int bytes,int index){
 if(!data||bytes<=0||bytes%4)return 0;
 sg_buffer buffer=sg_make_buffer(&(sg_buffer_desc){.data={data,(size_t)bytes},.usage={.vertex_buffer=!index,.index_buffer=index!=0}});
 if(sg_query_buffer_state(buffer)!=SG_RESOURCESTATE_VALID||(buffer.id&0xffff)>=256){sg_destroy_buffer(buffer);return 0;}
 int slot=buffer.id&0xffff;used[slot]=bytes;index_buffers[slot]=index!=0;vertex_reserved[slot]=0;return buffer.id;
}
static sg_pipeline make_pipeline(int kind,int alpha,sg_face_winding winding,uint32_t shader,int double_sided){
 if(kind==4)return sg_make_pipeline(&(sg_pipeline_desc){.shader={shader},.primitive_type=SG_PRIMITIVETYPE_TRIANGLES,
  .depth={.compare=SG_COMPAREFUNC_ALWAYS,.write_enabled=false},.cull_mode=SG_CULLMODE_NONE,
  .colors[0].blend={.enabled=alpha!=0,.src_factor_rgb=SG_BLENDFACTOR_SRC_ALPHA,.dst_factor_rgb=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,.src_factor_alpha=SG_BLENDFACTOR_ONE,.dst_factor_alpha=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA}});
 const int three=kind!=0;
 /* Lit models are indexed, their back faces culled unless double sided (counter-clockwise is the front, as GL's, unless winding turns it:
    gl_FrontFacing follows it too). */
 return sg_make_pipeline(&(sg_pipeline_desc){.shader=shader?(sg_shader){shader}:shaders[kind==3?2:three],
  .layout=kind==3?helix_lit3d_layout():three?helix_color3d_layout():helix_sprite2d_layout(),
  .primitive_type=kind==2?SG_PRIMITIVETYPE_LINES:SG_PRIMITIVETYPE_TRIANGLES,.index_type=kind==3?SG_INDEXTYPE_UINT32:SG_INDEXTYPE_NONE,
  .depth={.compare=three?SG_COMPAREFUNC_LESS_EQUAL:SG_COMPAREFUNC_ALWAYS,.write_enabled=three},
  .cull_mode=kind==3&&!double_sided?SG_CULLMODE_BACK:SG_CULLMODE_NONE,.face_winding=winding,
  .colors[0].blend={.enabled=alpha!=0,.src_factor_rgb=SG_BLENDFACTOR_SRC_ALPHA,.dst_factor_rgb=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,.src_factor_alpha=SG_BLENDFACTOR_ONE,.dst_factor_alpha=SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA}});
}
uint32_t helix_pipeline(int kind,int alpha,uint32_t shader,int double_sided,int clockwise){
 /* Screen takes an app's program; Lit3D may (a surface shader). */
 if(kind<0||kind>4||(kind==4&&!shader)||(shader&&kind!=3&&kind!=4))return 0;
 if(shader&&((shader&0xffff)>=256||sg_query_shader_state((sg_shader){shader})!=SG_RESOURCESTATE_VALID))return 0;
 sg_pipeline pipeline=make_pipeline(kind,alpha,clockwise?SG_FACEWINDING_CW:SG_FACEWINDING_CCW,shader,double_sided);
 if(sg_query_pipeline_state(pipeline)!=SG_RESOURCESTATE_VALID||(pipeline.id&0xffff)>=256){sg_destroy_pipeline(pipeline);return 0;}
 /* A lit pipeline's twin for flipped passes: its front faces the other way round. */
 flipped_pipelines[pipeline.id&0xffff]=kind==3?make_pipeline(kind,alpha,clockwise?SG_FACEWINDING_CCW:SG_FACEWINDING_CW,shader,double_sided):(sg_pipeline){0};
 pipeline_kinds[pipeline.id&0xffff]=kind;pipeline_shaders[pipeline.id&0xffff]=shader;return pipeline.id;
}
int helix_update(uint32_t id,const void *data,int bytes){
 sg_buffer buffer={id};int slot=id&0xffff;
 if(!active||!data||bytes<0||bytes%4||slot>=256||sg_query_buffer_state(buffer)!=SG_RESOURCESTATE_VALID||(size_t)bytes>sg_query_buffer_size(buffer)||!vertex_reserved[slot])return 0;
 if(bound[slot]){
  /* Bound since its last write: the write goes to the next extra, made the first time it's needed. */
  if(renamed[slot]==MAX_RENAMES)return 0;
  sg_buffer *extra=&extras[slot][renamed[slot]];
  if(!extra->id){
   *extra=sg_make_buffer(&(sg_buffer_desc){.size=sg_query_buffer_size(buffer),.usage={.vertex_buffer=true,.write_transient=true}});
   if(sg_query_buffer_state(*extra)!=SG_RESOURCESTATE_VALID)return 0;
   vertex_reserved[slot]+=(int)sg_query_buffer_size(buffer)*sg_query_buffer_info(*extra).num_slots;
  }
  renamed[slot]++;bound[slot]=0;
 }
 frame_uploaded_bytes+=bytes;
 if(bytes)sg_write_buffer_transient(&(sg_write_buffer_desc){.src.data={data,(size_t)bytes},.dst.buffer=current_buffer(id)});used[slot]=bytes;return 1;
}
/* An app's program from its GLSL 410 stages and its layout, a line each: "a <slot> <name>" an attribute, "u <slot> <v|f> <size> <vec4s> <name>"
   a uniform block (flattened to a vec4 array), "t <slot> <v|f> <name>" a texture and its sampler, sharing the slot. */
uint32_t helix_shader(const char *vs,const char *fs,const char *layout){
 sg_shader_desc desc={.vertex_func={.source=vs,.entry="main"},.fragment_func={.source=fs,.entry="main"},.label="app_shader"};
 static char names[32][128];int name=0,blocks=0,textures=0,sizes[MAX_BLOCKS]={0};
 for(const char *line=layout;line&&*line;){
  char kind,stage;int slot,size,count,used=0;
  if(name>=32)return 0;
  if(sscanf(line," a %d %127s%n",&slot,names[name],&used)==2){
   if(slot<0||slot>=SG_MAX_VERTEX_ATTRIBUTES)return 0;
   desc.attrs[slot].base_type=SG_SHADERATTRBASETYPE_FLOAT;desc.attrs[slot].glsl_name=names[name++];
  }else if(sscanf(line," u %d %c %d %d %127s%n",&slot,&stage,&size,&count,names[name],&used)==5){
   if(slot<0||slot>=MAX_BLOCKS||size<=0||count<=0)return 0;
   desc.uniform_blocks[slot].stage=stage=='v'?SG_SHADERSTAGE_VERTEX:SG_SHADERSTAGE_FRAGMENT;desc.uniform_blocks[slot].layout=SG_UNIFORMLAYOUT_STD140;
   desc.uniform_blocks[slot].size=(uint32_t)size;desc.uniform_blocks[slot].glsl_uniforms[0].type=SG_UNIFORMTYPE_FLOAT4;
   desc.uniform_blocks[slot].glsl_uniforms[0].array_count=(uint16_t)count;desc.uniform_blocks[slot].glsl_uniforms[0].glsl_name=names[name++];
   sizes[slot]=size;if(slot+1>blocks)blocks=slot+1;
  }else if(sscanf(line," t %d %c %127s%n",&slot,&stage,names[name],&used)==3){
   if(slot<0||slot>=MAX_TEXTURES)return 0;
   const sg_shader_stage st=stage=='v'?SG_SHADERSTAGE_VERTEX:SG_SHADERSTAGE_FRAGMENT;
   desc.views[slot].texture=(sg_shader_texture_view){.stage=st,.image_type=SG_IMAGETYPE_2D,.sample_type=SG_IMAGESAMPLETYPE_FLOAT};
   desc.samplers[slot]=(sg_shader_sampler){.stage=st,.sampler_type=SG_SAMPLERTYPE_FILTERING};
   desc.texture_sampler_pairs[slot]=(sg_shader_texture_sampler_pair){.stage=st,.view_slot=(uint8_t)slot,.sampler_slot=(uint8_t)slot,.glsl_name=names[name++]};
   textures|=1<<slot;
  }else return 0;
  line+=used;while(*line=='\n'||*line==' ')line++;
 }
 sg_shader shader=sg_make_shader(&desc);
 if(sg_query_shader_state(shader)!=SG_RESOURCESTATE_VALID||(shader.id&0xffff)>=256){sg_destroy_shader(shader);return 0;}
 int slot=shader.id&0xffff;programs[slot].blocks=blocks;programs[slot].texture_mask=textures;memcpy(programs[slot].block_size,sizes,sizeof sizes);
 return shader.id;
}
/* What a pipeline's program binds: its uniform blocks' sizes by slot (0 for one it lacks) and its texture slots (a bit each); the framework's
   lit program's, or an app's. */
static void program_of(int pslot,int *blocks,int *sizes,int *mask){
 if(!pipeline_shaders[pslot]){*blocks=2;sizes[0]=HELIX_LIT3D_VERTEX_UNIFORM_BYTES;sizes[1]=HELIX_LIT3D_FRAGMENT_UNIFORM_BYTES;*mask=3;return;}
 const int s=pipeline_shaders[pslot]&0xffff;*blocks=programs[s].blocks;memcpy(sizes,programs[s].block_size,sizeof programs[s].block_size);*mask=programs[s].texture_mask;
}
/* Binds textures (by slot, each of the program's set) into bindings, and checks uniforms: the blocks' bytes one after another by slot, each its
   declared size. 0 for a mismatch. */
static int bind_program(int pslot,sg_bindings *bindings,const uint32_t *textures,const int *samplings,int texture_count,int uniform_bytes){
 int blocks,sizes[MAX_BLOCKS]={0},mask,total=0;program_of(pslot,&blocks,sizes,&mask);
 for(int i=0;i<blocks;i++)total+=sizes[i];
 if(total!=uniform_bytes||texture_count>MAX_TEXTURES||(mask>>texture_count))return 0;
 for(int i=0;i<texture_count;i++){
  if(!(mask&1<<i))continue;
  if(sg_query_view_state((sg_view){textures[i]})!=SG_RESOURCESTATE_VALID)return 0;
  bindings->views[i]=(sg_view){textures[i]};bindings->samplers[i]=sampler_of(samplings[i]);
 }
 return 1;
}
/* Applies the uniform blocks after the pipeline and bindings: block 0 in a flipped pass is turned over here (a clip scale's y, or a
   view-projection's y row). */
static void apply_blocks(int pslot,const void *uniforms){
 int blocks,sizes[MAX_BLOCKS]={0},mask;program_of(pslot,&blocks,sizes,&mask);
 const char *at=uniforms;
 for(int i=0;i<blocks;i++){
  if(!sizes[i])continue;
  if(i==0&&pipeline_kinds[pslot]==4){float clip[4]={1.0f,flipped?-1.0f:1.0f,0.0f,0.0f};sg_apply_uniforms(0,&SG_RANGE(clip));}
  else if(i==0&&flipped){
   float copy[64];memcpy(copy,at,(size_t)sizes[0]>sizeof copy?sizeof copy:(size_t)sizes[0]);
   copy[1]=-copy[1];copy[5]=-copy[5];copy[9]=-copy[9];copy[13]=-copy[13];sg_apply_uniforms(0,&(sg_range){copy,(size_t)sizes[0]});
  }else sg_apply_uniforms(i,&(sg_range){at,(size_t)sizes[i]});
  at+=sizes[i];
 }
}
/* A Screen pipeline's draw: one triangle over the viewport, the program's textures and samplings by slot, its uniform blocks' bytes one after
   another by slot, block 0 (the clip scale) set here. */
int helix_draw_screen(uint32_t p,const uint32_t *textures,const int *samplings,int texture_count,const void *uniforms,int uniform_bytes){
 const int pslot=p&0xffff;
 if(!active||pslot>=256||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID||pipeline_kinds[pslot]!=4)return 0;
 sg_bindings bindings={0};
 if(!bind_program(pslot,&bindings,textures,samplings,texture_count,uniform_bytes))return 0;
 sg_apply_pipeline((sg_pipeline){p});
 sg_apply_bindings(&bindings);
 apply_blocks(pslot,uniforms);
 sg_draw(0,3,1);return 1;
}
/* A render target: a color image (8 bits a channel) sampled through the returned texture view, with a depth image for its passes. */
uint32_t helix_target(int w,int h){
 if(w<=0||h<=0||w>16384||h>16384)return 0;
 /* The screen's formats (sokol's environment defaults), so the same pipelines draw into both. */
 const sg_environment_defaults defaults=sg_query_desc().environment.defaults;
 sg_image color=sg_make_image(&(sg_image_desc){.usage.color_attachment=true,.width=w,.height=h,.pixel_format=defaults.color_format,.sample_count=1});
 sg_image depth=sg_make_image(&(sg_image_desc){.usage.depth_stencil_attachment=true,.width=w,.height=h,.pixel_format=defaults.depth_format,.sample_count=1});
 if(sg_query_image_state(color)!=SG_RESOURCESTATE_VALID||sg_query_image_state(depth)!=SG_RESOURCESTATE_VALID){sg_destroy_image(color);sg_destroy_image(depth);return 0;}
 sg_view texture=sg_make_view(&(sg_view_desc){.texture.image=color});
 int slot=texture.id&0xffff;
 if(slot>=256){sg_destroy_view(texture);sg_destroy_image(color);sg_destroy_image(depth);return 0;}
 targets[slot].color=sg_make_view(&(sg_view_desc){.color_attachment.image=color});
 targets[slot].depth=sg_make_view(&(sg_view_desc){.depth_stencil_attachment.image=depth});
 targets[slot].depth_image=depth;targets[slot].width=w;targets[slot].height=h;
 return texture.id;
}
static sg_color color_of(uint32_t color){return (sg_color){(color>>24)/255.f,((color>>16)&255)/255.f,((color>>8)&255)/255.f,(color&255)/255.f};}
/* A pass into target, cleared to color, before the screen's: drawn flipped where the backend's origin is the bottom left (GL). */
int helix_begin_target(uint32_t target,uint32_t color){
 int slot=target&0xffff;
 if(active||slot>=256||!targets[slot].color.id||sg_query_view_state((sg_view){target})!=SG_RESOURCESTATE_VALID)return 0;
 active=2;flipped=!sg_query_features().origin_top_left;frame_width=targets[slot].width;frame_height=targets[slot].height;
 sg_begin_pass(&(sg_pass){.action={.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value=color_of(color)},.depth={.load_action=SG_LOADACTION_CLEAR,.clear_value=1.0f}},
  .attachments={.colors[0]=targets[slot].color,.depth_stencil=targets[slot].depth}});
 return 1;
}
int helix_end_target(void){if(active!=2)return 0;sg_end_pass();active=0;flipped=0;return 1;}
int helix_begin(int width,int height,uint32_t color){
 if(active||width<=0||height<=0)return 0;
 active=1;flipped=0;frame_width=width;frame_height=height;
 sg_begin_pass(&(sg_pass){.swapchain=sglue_swapchain(),.action={.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value=color_of(color)},.depth={.load_action=SG_LOADACTION_CLEAR,.clear_value=1.0f}}});
 return 1;
}
int helix_viewport(int x,int y,int w,int h){
 if(!active||w<=0||h<=0)return 0;
 /* From the bottom left, as asked; a flipped pass's rows are upside down. */
 sg_apply_viewport(x,flipped?frame_height-y-h:y,w,h,false);return 1;
}
/* A 3D kind's view-projection, its y row negated in a flipped pass. */
static const void *view_projection(const void *uniforms,float *copy){
 if(!flipped)return uniforms;
 memcpy(copy,uniforms,64);copy[1]=-copy[1];copy[5]=-copy[5];copy[9]=-copy[9];copy[13]=-copy[13];return copy;
}
/* The sampler for a Sampling value: linear (through the mipmaps, when there are any) or nearest, and each axis's wrap. */
static sg_sampler sampler_of(int sampling){
 static const sg_wrap wraps[3]={SG_WRAP_CLAMP_TO_EDGE,SG_WRAP_REPEAT,SG_WRAP_MIRRORED_REPEAT};
 sampling&=31;
 if(!samplers[sampling].id){
  const sg_filter filter=sampling&1?SG_FILTER_LINEAR:SG_FILTER_NEAREST;
  samplers[sampling]=sg_make_sampler(&(sg_sampler_desc){.min_filter=filter,.mag_filter=filter,.mipmap_filter=filter,
   .wrap_u=wraps[(sampling>>1&3)%3],.wrap_v=wraps[(sampling>>3&3)%3]});
 }
 return samplers[sampling];
}
int helix_draw(uint32_t p,uint32_t b,uint32_t t,int sampling,int vertices,int first_vertex,const void *uniforms,int uniform_bytes){
 int slot=b&0xffff,pslot=p&0xffff;
 if(!active||slot>=256||pslot>=256||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID||sg_query_buffer_state((sg_buffer){b})!=SG_RESOURCESTATE_VALID||index_buffers[slot])return 0;
 const int kind=pipeline_kinds[pslot],stride=kind?HELIX_COLOR3D_STRIDE:HELIX_SPRITE2D_STRIDE,group=kind==2?2:3;
 if(kind==3)return 0; /* lit models draw with helix_draw_mesh */
 if(vertices<=0||vertices%group||first_vertex<0||first_vertex%group||vertices>used[slot]/stride||first_vertex>used[slot]/stride-vertices)return 0;
 if(kind==0){
  if(uniforms||sg_query_view_state((sg_view){t})!=SG_RESOURCESTATE_VALID)return 0;
  /* Its clip space's y scale: -1 in a flipped pass. */
  const float clip[4]={1.0f,flipped?-1.0f:1.0f,0.0f,0.0f};
  sg_apply_pipeline((sg_pipeline){p});
  sg_apply_bindings(&(sg_bindings){.vertex_buffers[0]=current_buffer(b),.views[HELIX_SPRITE2D_ATLAS_VIEW_SLOT]={t},.samplers[HELIX_SPRITE2D_ATLAS_SAMPLER_SLOT]=sampler_of(sampling)});
  sg_apply_uniforms(HELIX_SPRITE2D_VERTEX_UNIFORM_SLOT,&SG_RANGE(clip));
 }else{
  if(!uniforms||uniform_bytes!=HELIX_COLOR3D_VERTEX_UNIFORM_BYTES)return 0;
  float copy[16];
  sg_apply_pipeline((sg_pipeline){p});
  sg_apply_bindings(&(sg_bindings){.vertex_buffers[0]=current_buffer(b)});
  sg_apply_uniforms(HELIX_COLOR3D_VERTEX_UNIFORM_SLOT,&(sg_range){view_projection(uniforms,copy),(size_t)uniform_bytes});
 }
 bound[slot]=1;
 sg_draw(first_vertex,vertices,1);return 1;
}
/* A lit pipeline's indexed, instanced draw: index_count indices of `indices` into `vertices`, instance_count instances from first_instance of
   `instances`' upload this frame, the program's textures and samplings by slot and its uniform blocks' bytes one after another by slot. */
int helix_draw_mesh(uint32_t p,uint32_t vertices,uint32_t indices,int index_count,uint32_t instances,int first_instance,int instance_count,
                    const uint32_t *textures,const int *samplings,int texture_count,const void *uniforms,int uniform_bytes){
 const int pslot=p&0xffff,vslot=vertices&0xffff,islot=indices&0xffff,nslot=instances&0xffff;
 if(!active||pslot>=256||vslot>=256||islot>=256||nslot>=256||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID||pipeline_kinds[pslot]!=3)return 0;
 if(sg_query_buffer_state((sg_buffer){vertices})!=SG_RESOURCESTATE_VALID||index_buffers[vslot]||sg_query_buffer_state((sg_buffer){indices})!=SG_RESOURCESTATE_VALID||!index_buffers[islot])return 0;
 if(sg_query_buffer_state((sg_buffer){instances})!=SG_RESOURCESTATE_VALID||index_buffers[nslot])return 0;
 if(index_count<=0||index_count%3||(size_t)index_count*4>(size_t)used[islot]||first_instance<0||instance_count<=0||
    (long)(first_instance+instance_count)*HELIX_LIT3D_INSTANCE_STRIDE>used[nslot])return 0;
 sg_bindings bindings={.vertex_buffers={{vertices},current_buffer(instances)},.vertex_buffer_offsets[1]=first_instance*HELIX_LIT3D_INSTANCE_STRIDE,.index_buffer={indices}};
 if(!bind_program(pslot,&bindings,textures,samplings,texture_count,uniform_bytes))return 0;
 /* Flipped, the front faces wind the other way: the pipeline's twin. */
 sg_apply_pipeline(flipped?flipped_pipelines[pslot]:(sg_pipeline){p});
 sg_apply_bindings(&bindings);
 apply_blocks(pslot,uniforms);
 bound[nslot]=1;
 sg_draw(0,index_count,instance_count);return 1;
}
void helix_end(void){
 if(active!=1)abort();sg_end_pass();sg_commit();active=0;if(driver_audit_reset)driver_audit_reset();frame_uploaded_bytes=0;
 /* Stream buffers start each frame empty and unrenamed; a static one keeps its size. */
 for(int i=0;i<256;i++)if(vertex_reserved[i]){used[i]=0;renamed[i]=bound[i]=0;}
}
int helix_destroy(int kind,uint32_t id){
 int slot=id&0xffff;
 if(kind==0&&sg_query_buffer_state((sg_buffer){id})==SG_RESOURCESTATE_VALID){
  sg_destroy_buffer((sg_buffer){id});
  if(slot<256){vertex_reserved[slot]=0;for(int i=0;i<MAX_RENAMES;i++)if(extras[slot][i].id)sg_destroy_buffer(extras[slot][i]);memset(extras[slot],0,sizeof extras[slot]);}
  return 1;
 }
 if(kind==1&&sg_query_view_state((sg_view){id})==SG_RESOURCESTATE_VALID){
  sg_image image=sg_query_view_image((sg_view){id});sg_destroy_view((sg_view){id});sg_destroy_image(image);
  if(slot<256&&targets[slot].color.id){sg_destroy_view(targets[slot].color);sg_destroy_view(targets[slot].depth);sg_destroy_image(targets[slot].depth_image);memset(&targets[slot],0,sizeof targets[slot]);}
  return 1;
 }
 if(kind==3&&sg_query_shader_state((sg_shader){id})==SG_RESOURCESTATE_VALID){sg_destroy_shader((sg_shader){id});return 1;}
 if(kind==2&&sg_query_pipeline_state((sg_pipeline){id})==SG_RESOURCESTATE_VALID){
  sg_destroy_pipeline((sg_pipeline){id});if(slot<256&&flipped_pipelines[slot].id){sg_destroy_pipeline(flipped_pipelines[slot]);flipped_pipelines[slot].id=0;}return 1;
 }
 return 0;
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
