#include "graphics.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "surface.h"
#define SOKOL_GFX_IMPL
#define SOKOL_GLCORE
#include "sokol_gfx.h"
/* sokol_log, private to this file: each sokol piece keeps its own copy, as a build may link any of them without the others. */
#define SOKOL_LOG_IMPL
#define SOKOL_LOG_API_DECL static
#include "sokol_log.h"

#if defined(_WIN32)
/* sokol's Win32 GL loader declares only what sokol calls; these are the rest this file uses. glReadPixels is GL 1.1's, which opengl32
   exports itself. */
#ifndef GL_SAMPLES
#define GL_SAMPLES 0x80A9
#endif
#ifndef GL_MAX_SAMPLES
#define GL_MAX_SAMPLES 0x8D57
#endif
#ifndef GL_PACK_ALIGNMENT
#define GL_PACK_ALIGNMENT 0x0D05
#endif
__declspec(dllimport) void __stdcall glReadPixels(GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, void *pixels);
#endif

/* Programs (helix_shader), by shader slot: their uniform blocks' count and sizes by binding slot, and the texture slots they sample (a bit
   each). */
#define MAX_BLOCKS 4
#define MAX_TEXTURES 12
#define MAX_BUFFERS 4
static struct{int blocks,texture_mask,block_size[MAX_BLOCKS];}programs[256];
static sg_sampler sampler_of(int sampling);
/* One sampler for each Sampling value used (helix.graphics.Sampling: bit 0 linear, bits 1-2 wrap u, bits 3-4 wrap v), made when first used. */
static sg_sampler samplers[32];
/* Pipelines (helix_pipeline), by pipeline slot: what a draw through one checks and binds (its program, its buffers' strides and whether each
   is an instance's and read at all, indexed or not, lines or triangles, block 0's clip flip) and its twin for flipped passes (its front faces
   the other way round), where it draws triangles into colors. Per buffer slot: whether it is an index buffer. */
static struct{uint32_t id,shader;int buffer_count,stride[MAX_BUFFERS],instanced[MAX_BUFFERS],read[MAX_BUFFERS],indexed,lines,flip;}pipeline_info[256];
static int index_buffers[256];
/* active: 1 in the screen's pass, 2 in a target's; flipped: the pass is drawn flipped (GL, whose framebuffers' origin is the bottom left, into a
   target), so a target is stored top row first, as every texture is. */
static int active,flipped,used[256],frame_width,frame_height;
/* The screen's size this frame, and whether helix_end has ended it (so it can be read back). */
static int screen_width,screen_height,frame_ended;
/* A stream buffer written again after a draw bound it this frame takes another sokol buffer of the same size, as sokol allows writes only
   before a bind: renamed[slot] is how many of its extras are in use this frame, bound[slot] whether the current one was bound since its write. */
#define MAX_RENAMES 8
static sg_buffer extras[256][MAX_RENAMES];static int renamed[256],bound[256];
/* Render targets, by texture view slot: their color and depth attachment views, depth image and size. A pipeline's flipped twin, by pipeline
   slot. */
static struct{sg_view color,depth,resolve;sg_image depth_image,samples_image;int width,height;}targets[256];static sg_pipeline flipped_pipelines[256];
/* Shadow maps, by texture view slot: the depth array, an attachment view a layer, and their size; and the sampler they're read through
   (comparing, linear, clamped), made with the first. */
#define MAX_SHADOW_LAYERS 16
static struct{sg_image image;sg_view layers[MAX_SHADOW_LAYERS];int size,count;}shadow_maps[256];static sg_sampler comparison;
/* Data textures, by texture view slot: RGBA32F, rewritten whole by helix_update_data. sokol's write-transient images hold what's written for
   the frame alone, and take writes only until they're bound, so the adapter keeps the contents (copy) and writes them at the first bind of a
   frame without a write of its own; and a write after a bind goes to a spare of the same size (made the first time it's needed): renamed is
   how many are in use this frame, and the texture's draws read the latest. */
static struct{sg_image image;int width,height,written,bound,renamed;float *copy;sg_image extra_images[MAX_RENAMES];sg_view extra_views[MAX_RENAMES];}data_textures[256];
/* Per buffer slot: whether it is a stream buffer (createBuffer's), rewritten each frame. */
static int stream_buffers[256];
/* The samples a pixel the window's framebuffer got (GL's count: what the window asked for, or fewer), read at setup. */
static int window_samples=1,max_samples=1;
/* The host's window as sokol_gfx sees it (surface.h): framebuffer 0 of its GL context, RGBA8 with depth, as sokol_glue gave it from sokol_app. */
static sg_environment environment(void){
 return (sg_environment){.defaults={.color_format=SG_PIXELFORMAT_RGBA8,.depth_format=SG_PIXELFORMAT_DEPTH,.sample_count=helix_surface_samples()}};
}
static sg_swapchain swapchain(void){
 return (sg_swapchain){.width=helix_surface_width(),.height=helix_surface_height(),.sample_count=helix_surface_samples(),
  .color_format=SG_PIXELFORMAT_RGBA8,.depth_format=SG_PIXELFORMAT_DEPTH,.gl.framebuffer=0};
}
int helix_msaa_samples(void){return window_samples;}
int helix_max_msaa_samples(void){return max_samples;}
void helix_setup(void){
 /* Pools as large as the adapter's tables, which are indexed by slot (below 256): sokol's defaults (64 pipelines) run out on a stage with
    a few surface shaders, each several pipelines and their flipped twins. */
 sg_setup(&(sg_desc){.environment=environment(),.logger.func=slog_func,.buffer_pool_size=255,.image_pool_size=255,.sampler_pool_size=255,
  .shader_pool_size=255,.pipeline_pool_size=255,.view_pool_size=255});
 sg_disable_stats();
 memset(samplers,0,sizeof samplers);
 GLint n=0;glBindFramebuffer(GL_FRAMEBUFFER,0);glGetIntegerv(GL_SAMPLES,&n);window_samples=n>1?n:1;
 n=0;glGetIntegerv(GL_MAX_SAMPLES,&n);max_samples=n>=8?8:n>=4?4:n>=2?2:1;
}
void helix_shutdown(void){
 for(int i=0;i<32;i++)if(samplers[i].id)sg_destroy_sampler(samplers[i]);
 if(comparison.id)sg_destroy_sampler(comparison);
 sg_shutdown();
}
/* helix.graphics.TextureFormat's values as sokol's: RGBA8, BC7, ASTC 4x4, ETC2 RGBA8, RGBA16F. */
static sg_pixel_format format_of(int format){
 switch(format){case 0:return SG_PIXELFORMAT_RGBA8;case 1:return SG_PIXELFORMAT_BC7_RGBA;case 2:return SG_PIXELFORMAT_ASTC_4x4_RGBA;
  case 3:return SG_PIXELFORMAT_ETC2_RGBA8;case 4:return SG_PIXELFORMAT_RGBA16F;default:return SG_PIXELFORMAT_NONE;}
}
/* Half floats count only where they're filtered too. */
int helix_can_sample(int format){sg_pixel_format f=format_of(format);if(f==SG_PIXELFORMAT_NONE)return 0;sg_pixelformat_info info=sg_query_pixelformat(f);
 return info.sample&&(format!=4||info.filter);}
/* The bytes of a w x h level (a face's, for a cube) of format: 4 a texel, 8 for half floats, or 4x4 blocks of 16. */
static size_t level_bytes(int format,int w,int h){return format==0?(size_t)w*(size_t)h*4:format==4?(size_t)w*(size_t)h*8:(size_t)((w+3)/4)*(size_t)((h+3)/4)*16;}
/* levels mip levels of format, each half the last (at least 1), packed one after another in data. */
uint32_t helix_texture(int w,int h,const void *data,int bytes,int levels,int format){
 if(w<=0||h<=0||w>16384||h>16384||!data||levels<1||levels>SG_MAX_MIPMAPS||!helix_can_sample(format))return 0;
 sg_image_desc desc={.width=w,.height=h,.num_mipmaps=levels,.pixel_format=format_of(format)};
 size_t offset=0;int lw=w,lh=h;
 for(int i=0;i<levels;i++){
  const size_t size=level_bytes(format,lw,lh);
  desc.data.mip_levels[i]=(sg_range){(const char *)data+offset,size};offset+=size;
  lw=lw>1?lw/2:1;lh=lh>1?lh/2:1;
 }
 if(offset!=(size_t)bytes)return 0;
 sg_image image=sg_make_image(&desc);
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID)return 0;
 return sg_make_view(&(sg_view_desc){.texture.image=image}).id;
}
/* A cube of size, levels mip levels of format, each its six faces (+X, -X, +Y, -Y, +Z, -Z) one after another, the levels packed one after
   another in data. */
uint32_t helix_cube_texture(int size,const void *data,int bytes,int levels,int format){
 if(size<=0||size>16384||!data||levels<1||levels>SG_MAX_MIPMAPS||!helix_can_sample(format))return 0;
 sg_image_desc desc={.type=SG_IMAGETYPE_CUBE,.width=size,.height=size,.num_mipmaps=levels,.pixel_format=format_of(format)};
 size_t offset=0;int s=size;
 for(int i=0;i<levels;i++){
  const size_t level=6*level_bytes(format,s,s);
  desc.data.mip_levels[i]=(sg_range){(const char *)data+offset,level};offset+=level;s=s>1?s/2:1;
 }
 if(offset!=(size_t)bytes)return 0;
 sg_image image=sg_make_image(&desc);
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID)return 0;
 return sg_make_view(&(sg_view_desc){.texture.image=image}).id;
}
/* A data texture: RGBA32F, width x height, written each frame it's used and read texel by texel. */
static sg_image data_image(int w,int h){return sg_make_image(&(sg_image_desc){.width=w,.height=h,.pixel_format=SG_PIXELFORMAT_RGBA32F,.usage.write_transient=true,.label="helix-data"});}
uint32_t helix_data_texture(int w,int h){
 if(w<=0||h<=0||w>16384||h>16384||!sg_query_pixelformat(SG_PIXELFORMAT_RGBA32F).sample)return 0;
 sg_image image=data_image(w,h);
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID){sg_destroy_image(image);return 0;}
 sg_view view=sg_make_view(&(sg_view_desc){.texture.image=image});int slot=view.id&0xffff;
 float *copy=calloc((size_t)w*(size_t)h*4,sizeof(float));
 if(slot>=256||!copy){free(copy);sg_destroy_view(view);sg_destroy_image(image);return 0;}
 memset(&data_textures[slot],0,sizeof data_textures[slot]);data_textures[slot].image=image;data_textures[slot].width=w;data_textures[slot].height=h;
 data_textures[slot].copy=copy;
 return view.id;
}
/* The image a data texture's draws read now: itself, or the spare its latest write went to. */
static sg_image current_data_image(int slot){return data_textures[slot].renamed?data_textures[slot].extra_images[data_textures[slot].renamed-1]:data_textures[slot].image;}
/* Writes a data texture's contents into its current image. */
static void write_data(int slot){
 const size_t size=(size_t)data_textures[slot].width*(size_t)data_textures[slot].height*16;
 sg_write_image_transient(&(sg_write_image_desc){.src.data={data_textures[slot].copy,size},.dst.image=current_data_image(slot)});
 data_textures[slot].written=1;
}
int helix_update_data(uint32_t texture,const void *data,int bytes){
 const int slot=texture&0xffff;
 if(!data||slot>=256||!data_textures[slot].image.id||sg_query_view_state((sg_view){texture})!=SG_RESOURCESTATE_VALID)return 0;
 const size_t size=(size_t)data_textures[slot].width*(size_t)data_textures[slot].height*16;
 if((size_t)bytes<size)return 0;
 if(data_textures[slot].bound){
  /* Bound since its last write: the write goes to the next spare. */
  const int r=data_textures[slot].renamed;
  if(r==MAX_RENAMES)return 0;
  if(!data_textures[slot].extra_images[r].id){
   data_textures[slot].extra_images[r]=data_image(data_textures[slot].width,data_textures[slot].height);
   if(sg_query_image_state(data_textures[slot].extra_images[r])!=SG_RESOURCESTATE_VALID)return 0;
   data_textures[slot].extra_views[r]=sg_make_view(&(sg_view_desc){.texture.image=data_textures[slot].extra_images[r]});
  }
  data_textures[slot].renamed++;data_textures[slot].bound=0;
 }
 memcpy(data_textures[slot].copy,data,size);write_data(slot);return 1;
}
/* The view a texture's draws read: a data texture's latest write, or itself. */
static sg_view current_view(uint32_t texture){
 const int slot=texture&0xffff;
 return slot<256&&data_textures[slot].image.id&&data_textures[slot].renamed?data_textures[slot].extra_views[data_textures[slot].renamed-1]:(sg_view){texture};
}
uint32_t helix_buffer(int capacity){
 if(capacity<=0||capacity%4)return 0;
 sg_buffer buffer=sg_make_buffer(&(sg_buffer_desc){.size=(size_t)capacity,.usage={.vertex_buffer=true,.write_transient=true}});
 if((buffer.id&0xffff)<256){int slot=buffer.id&0xffff;used[slot]=0;index_buffers[slot]=0;stream_buffers[slot]=1;
  renamed[slot]=bound[slot]=0;memset(extras[slot],0,sizeof extras[slot]);}return buffer.id;
}
/* The sokol buffer a stream buffer's draws read now: itself, or the extra its latest write went to. */
static sg_buffer current_buffer(uint32_t id){int slot=id&0xffff;return slot<256&&renamed[slot]?extras[slot][renamed[slot]-1]:(sg_buffer){id};}
/* An immutable vertex buffer, or an index buffer of uint32 indices, holding the bytes of data (neither write flag: immutable). */
uint32_t helix_static_buffer(const void *data,int bytes,int index){
 if(!data||bytes<=0||bytes%4)return 0;
 sg_buffer buffer=sg_make_buffer(&(sg_buffer_desc){.data={data,(size_t)bytes},.usage={.vertex_buffer=!index,.index_buffer=index!=0}});
 if(sg_query_buffer_state(buffer)!=SG_RESOURCESTATE_VALID||(buffer.id&0xffff)>=256){sg_destroy_buffer(buffer);return 0;}
 int slot=buffer.id&0xffff;used[slot]=bytes;index_buffers[slot]=index!=0;stream_buffers[slot]=0;return buffer.id;
}
/* helix.graphics.BlendMode's: opaque (none), alpha (straight), additive (the source times its alpha, plus what's there). */
static sg_blend_state blend_of(int blend){
 if(!blend)return (sg_blend_state){0};
 const sg_blend_factor dst=blend==2?SG_BLENDFACTOR_ONE:SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
 return (sg_blend_state){.enabled=true,.src_factor_rgb=SG_BLENDFACTOR_SRC_ALPHA,.dst_factor_rgb=dst,.src_factor_alpha=SG_BLENDFACTOR_ONE,.dst_factor_alpha=dst};
}
/* A pipeline as helix.graphics.PipelineDesc describes it, its ints in order: shader, primitive (0 triangles, 1 lines), indexed, blend,
   depth test, depth write, cull back, clockwise, depth only, clip flip (0 none, 1 clip scale, 2 view-projection), the buffer count, then each
   buffer's stride, instanced and attribute count, each attribute's slot, components and offset. 0 for a description it can't make. */
uint32_t helix_pipeline(const int *desc,int count){
 if(!desc||count<11)return 0;
 const uint32_t shader=(uint32_t)desc[0];const int lines=desc[1]==1,indexed=desc[2],blend=desc[3],depth_only=desc[8],clockwise=desc[7];
 if(blend<0||blend>2||(shader&0xffff)>=256||sg_query_shader_state((sg_shader){shader})!=SG_RESOURCESTATE_VALID)return 0;
 sg_pipeline_desc pd={.shader={shader},.primitive_type=lines?SG_PRIMITIVETYPE_LINES:SG_PRIMITIVETYPE_TRIANGLES,
  .index_type=indexed?SG_INDEXTYPE_UINT32:SG_INDEXTYPE_NONE,.depth={.compare=desc[4]?SG_COMPAREFUNC_LESS_EQUAL:SG_COMPAREFUNC_ALWAYS,.write_enabled=desc[5]!=0},
  .cull_mode=desc[6]?SG_CULLMODE_BACK:SG_CULLMODE_NONE,.face_winding=clockwise?SG_FACEWINDING_CW:SG_FACEWINDING_CCW,.colors[0].blend=blend_of(blend)};
 /* Depth alone: a shadow pass's, no color attachment. */
 if(depth_only){pd.depth.pixel_format=SG_PIXELFORMAT_DEPTH;pd.color_count=0;pd.sample_count=1;}
 const int buffers=desc[10];int at=11,strides[MAX_BUFFERS]={0},instanced[MAX_BUFFERS]={0},read[MAX_BUFFERS]={0};
 if(buffers<0||buffers>MAX_BUFFERS)return 0;
 for(int b=0;b<buffers;b++){
  if(at+3>count)return 0;
  strides[b]=desc[at];instanced[b]=desc[at+1]!=0;const int attrs=desc[at+2];at+=3;
  if(strides[b]<0||attrs<0||at+attrs*3>count)return 0;
  pd.layout.buffers[b].stride=strides[b];if(instanced[b])pd.layout.buffers[b].step_func=SG_VERTEXSTEP_PER_INSTANCE;
  for(int a=0;a<attrs;a++,at+=3){
   const int slot=desc[at],components=desc[at+1],offset=desc[at+2];
   if(slot<0||slot>=SG_MAX_VERTEX_ATTRIBUTES||components<1||components>4||offset<0||offset+components*4>strides[b])return 0;
   static const sg_vertex_format formats[4]={SG_VERTEXFORMAT_FLOAT,SG_VERTEXFORMAT_FLOAT2,SG_VERTEXFORMAT_FLOAT3,SG_VERTEXFORMAT_FLOAT4};
   pd.layout.attrs[slot]=(sg_vertex_attr_state){.format=formats[components-1],.offset=offset,.buffer_index=b};
  }
  read[b]=attrs>0;
 }
 sg_pipeline pipeline=sg_make_pipeline(&pd);
 if(sg_query_pipeline_state(pipeline)!=SG_RESOURCESTATE_VALID||(pipeline.id&0xffff)>=256){sg_destroy_pipeline(pipeline);return 0;}
 const int slot=pipeline.id&0xffff;
 /* Triangles into colors get a twin for flipped passes: their front faces (and gl_FrontFacing) the other way round. */
 flipped_pipelines[slot]=(sg_pipeline){0};
 if(!lines&&!depth_only){pd.face_winding=clockwise?SG_FACEWINDING_CCW:SG_FACEWINDING_CW;flipped_pipelines[slot]=sg_make_pipeline(&pd);}
 pipeline_info[slot].id=pipeline.id;pipeline_info[slot].shader=shader;pipeline_info[slot].buffer_count=buffers;pipeline_info[slot].indexed=indexed!=0;pipeline_info[slot].lines=lines;
 pipeline_info[slot].flip=desc[9];
 memcpy(pipeline_info[slot].stride,strides,sizeof strides);memcpy(pipeline_info[slot].instanced,instanced,sizeof instanced);memcpy(pipeline_info[slot].read,read,sizeof read);
 return pipeline.id;
}
int helix_update(uint32_t id,const void *data,int bytes){
 sg_buffer buffer={id};int slot=id&0xffff;
 if(!active||!data||bytes<0||bytes%4||slot>=256||sg_query_buffer_state(buffer)!=SG_RESOURCESTATE_VALID||(size_t)bytes>sg_query_buffer_size(buffer)||!stream_buffers[slot])return 0;
 if(bound[slot]){
  /* Bound since its last write: the write goes to the next extra, made the first time it's needed. */
  if(renamed[slot]==MAX_RENAMES)return 0;
  sg_buffer *extra=&extras[slot][renamed[slot]];
  if(!extra->id){
   *extra=sg_make_buffer(&(sg_buffer_desc){.size=sg_query_buffer_size(buffer),.usage={.vertex_buffer=true,.write_transient=true}});
   if(sg_query_buffer_state(*extra)!=SG_RESOURCESTATE_VALID)return 0;
  }
  renamed[slot]++;bound[slot]=0;
 }
 if(bytes)sg_write_buffer_transient(&(sg_write_buffer_desc){.src.data={data,(size_t)bytes},.dst.buffer=current_buffer(id)});used[slot]=bytes;return 1;
}
/* A program from its GLSL 410 stages and its layout, a line each: "a <slot> <name>" an attribute, "u <slot> <v|f> <size> <vec4s> <name>" a
   uniform block (flattened to a vec4 array), "t <slot> <v|f> <name>" a texture and its sampler, sharing the slot, "s <slot> <v|f> <name>" a
   shadow map (a depth array) and its comparison sampler, "c <slot> <v|f> <name>" a cube and its sampler, "d <slot> <v|f> <name>" a data
   texture (RGBA32F, unfiltered) and its nonfiltering sampler. */
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
  }else if(sscanf(line," %c %d %c %127s%n",&kind,&slot,&stage,names[name],&used)==4&&(kind=='t'||kind=='s'||kind=='c'||kind=='d')){
   if(slot<0||slot>=MAX_TEXTURES)return 0;
   const sg_shader_stage st=stage=='v'?SG_SHADERSTAGE_VERTEX:SG_SHADERSTAGE_FRAGMENT;const int shadow=kind=='s';
   desc.views[slot].texture=(sg_shader_texture_view){.stage=st,.image_type=shadow?SG_IMAGETYPE_ARRAY:kind=='c'?SG_IMAGETYPE_CUBE:SG_IMAGETYPE_2D,
    .sample_type=shadow?SG_IMAGESAMPLETYPE_DEPTH:kind=='d'?SG_IMAGESAMPLETYPE_UNFILTERABLE_FLOAT:SG_IMAGESAMPLETYPE_FLOAT};
   desc.samplers[slot]=(sg_shader_sampler){.stage=st,.sampler_type=shadow?SG_SAMPLERTYPE_COMPARISON:kind=='d'?SG_SAMPLERTYPE_NONFILTERING:SG_SAMPLERTYPE_FILTERING};
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
/* A render target: a color image (8 bits a channel) sampled through the returned texture view, with a depth image for its passes. */
uint32_t helix_target(int w,int h){
 if(w<=0||h<=0||w>16384||h>16384)return 0;
 /* The screen's formats and samples (sokol's environment defaults), so the same pipelines draw into both: multisampled, its passes draw
    into an image of the screen's samples, resolved at the pass's end into the one sampled. */
 const sg_environment_defaults defaults=sg_query_desc().environment.defaults;
 const int samples=defaults.sample_count>1?defaults.sample_count:1;
 sg_image color=sg_make_image(&(sg_image_desc){.usage={.color_attachment=samples==1,.resolve_attachment=samples>1},.width=w,.height=h,
  .pixel_format=defaults.color_format,.sample_count=1});
 sg_image drawn=samples>1?sg_make_image(&(sg_image_desc){.usage.color_attachment=true,.width=w,.height=h,.pixel_format=defaults.color_format,
  .sample_count=samples}):color;
 sg_image depth=sg_make_image(&(sg_image_desc){.usage.depth_stencil_attachment=true,.width=w,.height=h,.pixel_format=defaults.depth_format,.sample_count=samples});
 if(sg_query_image_state(color)!=SG_RESOURCESTATE_VALID||sg_query_image_state(drawn)!=SG_RESOURCESTATE_VALID||sg_query_image_state(depth)!=SG_RESOURCESTATE_VALID){
  sg_destroy_image(color);if(samples>1)sg_destroy_image(drawn);sg_destroy_image(depth);return 0;
 }
 sg_view texture=sg_make_view(&(sg_view_desc){.texture.image=color});
 int slot=texture.id&0xffff;
 if(slot>=256){sg_destroy_view(texture);sg_destroy_image(color);if(samples>1)sg_destroy_image(drawn);sg_destroy_image(depth);return 0;}
 targets[slot].color=sg_make_view(&(sg_view_desc){.color_attachment.image=drawn});
 if(samples>1){targets[slot].resolve=sg_make_view(&(sg_view_desc){.resolve_attachment.image=color});targets[slot].samples_image=drawn;}
 targets[slot].depth=sg_make_view(&(sg_view_desc){.depth_stencil_attachment.image=depth});
 targets[slot].depth_image=depth;targets[slot].width=w;targets[slot].height=h;
 return texture.id;
}
/* A shadow map: a depth array of layers layers, each size x size, sampled through the returned texture view, with an attachment view a layer. */
uint32_t helix_shadow_map(int size,int layers){
 if(size<=0||size>16384||layers<=0||layers>MAX_SHADOW_LAYERS)return 0;
 const sg_pixelformat_info info=sg_query_pixelformat(SG_PIXELFORMAT_DEPTH);
 if(!info.depth||!info.sample)return 0;
 sg_image image=sg_make_image(&(sg_image_desc){.type=SG_IMAGETYPE_ARRAY,.usage.depth_stencil_attachment=true,.width=size,.height=size,
  .num_slices=layers,.pixel_format=SG_PIXELFORMAT_DEPTH,.sample_count=1,.label="helix-shadow-map"});
 if(sg_query_image_state(image)!=SG_RESOURCESTATE_VALID){sg_destroy_image(image);return 0;}
 sg_view texture=sg_make_view(&(sg_view_desc){.texture.image=image});
 int slot=texture.id&0xffff;
 if(slot>=256){sg_destroy_view(texture);sg_destroy_image(image);return 0;}
 shadow_maps[slot].image=image;shadow_maps[slot].size=size;shadow_maps[slot].count=layers;
 for(int i=0;i<layers;i++)shadow_maps[slot].layers[i]=sg_make_view(&(sg_view_desc){.depth_stencil_attachment={.image=image,.slice=i}});
 if(!comparison.id)comparison=sg_make_sampler(&(sg_sampler_desc){.min_filter=SG_FILTER_LINEAR,.mag_filter=SG_FILTER_LINEAR,
  .wrap_u=SG_WRAP_CLAMP_TO_EDGE,.wrap_v=SG_WRAP_CLAMP_TO_EDGE,.compare=SG_COMPAREFUNC_LESS_EQUAL});
 return texture.id;
}
/* A depth-only pass into layer of map, cleared to the farthest and kept (sokol's default for depth is to discard it). Not flipped: a shadow map's
   rows run bottom first, as its lookups expect. */
int helix_begin_shadow(uint32_t map,int layer){
 int slot=map&0xffff;
 if(active||slot>=256||!shadow_maps[slot].image.id||layer<0||layer>=shadow_maps[slot].count||sg_query_view_state((sg_view){map})!=SG_RESOURCESTATE_VALID)return 0;
 active=2;flipped=0;frame_width=frame_height=shadow_maps[slot].size;
 sg_begin_pass(&(sg_pass){.action={.depth={.load_action=SG_LOADACTION_CLEAR,.store_action=SG_STOREACTION_STORE,.clear_value=1.0f},
  .stencil={.load_action=SG_LOADACTION_DONTCARE}},.attachments={.depth_stencil=shadow_maps[slot].layers[layer]},.label="helix-shadow-map"});
 return 1;
}
static sg_color color_of(uint32_t color){return (sg_color){(color>>24)/255.f,((color>>16)&255)/255.f,((color>>8)&255)/255.f,(color&255)/255.f};}
/* A pass into target, cleared to color, before the screen's: drawn flipped where the backend's origin is the bottom left (GL). */
int helix_begin_target(uint32_t target,uint32_t color){
 int slot=target&0xffff;
 if(active||slot>=256||!targets[slot].color.id||sg_query_view_state((sg_view){target})!=SG_RESOURCESTATE_VALID)return 0;
 active=2;flipped=!sg_query_features().origin_top_left;frame_width=targets[slot].width;frame_height=targets[slot].height;
 sg_begin_pass(&(sg_pass){.action={.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value=color_of(color)},.depth={.load_action=SG_LOADACTION_CLEAR,.clear_value=1.0f}},
  .attachments={.colors[0]=targets[slot].color,.resolves[0]=targets[slot].resolve,.depth_stencil=targets[slot].depth}});
 return 1;
}
int helix_end_target(void){if(active!=2)return 0;sg_end_pass();active=0;flipped=0;return 1;}
int helix_begin(int width,int height,uint32_t color){
 if(active||width<=0||height<=0)return 0;
 active=1;flipped=0;frame_width=screen_width=width;frame_height=screen_height=height;frame_ended=0;
 sg_begin_pass(&(sg_pass){.swapchain=swapchain(),.action={.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value=color_of(color)},.depth={.load_action=SG_LOADACTION_CLEAR,.clear_value=1.0f}}});
 return 1;
}
/* Reading back. The back buffer holds the ended frame until sokol_app swaps, after the frame callback returns. */
/* What target 0 (the frame just ended) or a render target reads back as: its width and height, 0 when it can't be read now. */
int helix_read_width(uint32_t target){int slot=target&0xffff;return target?(slot<256&&targets[slot].color.id?targets[slot].width:0):(frame_ended?screen_width:0);}
int helix_read_height(uint32_t target){int slot=target&0xffff;return target?(slot<256&&targets[slot].color.id?targets[slot].height:0):(frame_ended?screen_height:0);}
/* Reads target into out (width * height * 4 bytes, RGBA8, rows top first) through GL, outside any pass: the back buffer for 0 (GL's rows
   come bottom first, so they're turned over), else the target's color image attached to a framebuffer of the moment (its rows are already
   top first: target passes draw flipped). sokol caches GL state, so its cache is reset after. */
int helix_read_pixels(uint32_t target,unsigned char *out){
 int w=helix_read_width(target),h=helix_read_height(target);
 if(active||!out||w<=0||h<=0)return 0;
 GLuint framebuffer=0;
 if(target){
  sg_gl_image_info info=sg_gl_query_image_info(sg_query_view_image((sg_view){target}));
  glGenFramebuffers(1,&framebuffer);glBindFramebuffer(GL_READ_FRAMEBUFFER,framebuffer);
  glFramebufferTexture2D(GL_READ_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_TEXTURE_2D,info.tex[info.active_slot],0);
  glReadBuffer(GL_COLOR_ATTACHMENT0);
 }else{glBindFramebuffer(GL_READ_FRAMEBUFFER,0);glReadBuffer(GL_BACK);}
 glPixelStorei(GL_PACK_ALIGNMENT,1);glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,out);
 int ok=glGetError()==GL_NO_ERROR;
 if(framebuffer){glBindFramebuffer(GL_READ_FRAMEBUFFER,0);glDeleteFramebuffers(1,&framebuffer);}
 sg_reset_state_cache();
 if(ok&&!target){size_t row=(size_t)w*4;unsigned char *swap=malloc(row);if(!swap)return 0;
  for(int y=0;y<h/2;y++){memcpy(swap,out+row*y,row);memcpy(out+row*y,out+row*(h-1-y),row);memcpy(out+row*(h-1-y),swap,row);}free(swap);}
 return ok;
}
/* Clips to x, y, w, h from the bottom left (on), or to the whole pass (off). sokol's scissor lasts the pass. */
int helix_scissor(int x,int y,int w,int h,int on){
 if(!active||(on&&(w<0||h<0)))return 0;
 if(on)sg_apply_scissor_rect(x,flipped?frame_height-y-h:y,w,h,false);
 else sg_apply_scissor_rect(0,0,frame_width,frame_height,false);
 return 1;
}
int helix_viewport(int x,int y,int w,int h){
 if(!active||w<=0||h<=0)return 0;
 /* From the bottom left, as asked; a flipped pass's rows are upside down. */
 sg_apply_viewport(x,flipped?frame_height-y-h:y,w,h,false);return 1;
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
/* Binds textures (by slot, each of the program's set) into bindings, and checks uniforms: the blocks' bytes one after another by slot, each its
   declared size. A shadow map is read through the comparison sampler, a data texture (its latest write) through the nearest one. 0 for a
   mismatch. */
static int bind_program(int shader,sg_bindings *bindings,const uint32_t *textures,const int *samplings,int texture_count,int uniform_bytes){
 int total=0;
 for(int i=0;i<programs[shader].blocks;i++)total+=programs[shader].block_size[i];
 const int mask=programs[shader].texture_mask;
 if(total!=uniform_bytes||texture_count>MAX_TEXTURES||(mask>>texture_count))return 0;
 for(int i=0;i<texture_count;i++){
  if(!(mask&1<<i))continue;
  if(sg_query_view_state((sg_view){textures[i]})!=SG_RESOURCESTATE_VALID)return 0;
  const int vslot=textures[i]&0xffff,data=vslot<256&&data_textures[vslot].image.id;
  /* A data texture not yet written this frame gets its contents first: sokol keeps them a frame. */
  if(data){if(!data_textures[vslot].written)write_data(vslot);data_textures[vslot].bound=1;}
  bindings->views[i]=current_view(textures[i]);
  bindings->samplers[i]=vslot<256&&shadow_maps[vslot].image.id?comparison:sampler_of(data?0:samplings[i]);
 }
 return 1;
}
/* Applies the program's uniform blocks after the pipeline and bindings; block 0 as the pipeline's clip flip says: a clip scale written here,
   or a view-projection's y row negated in a flipped pass. */
static void apply_blocks(int shader,int flip,const void *uniforms){
 const char *at=uniforms;
 for(int i=0;i<programs[shader].blocks;i++){
  const int size=programs[shader].block_size[i];
  if(!size)continue;
  if(i==0&&flip==1){float clip[4]={1.0f,flipped?-1.0f:1.0f,0.0f,0.0f};sg_apply_uniforms(0,&SG_RANGE(clip));}
  else if(i==0&&flip==2&&flipped){
   float copy[256];if((size_t)size>sizeof copy)return;memcpy(copy,at,(size_t)size);
   copy[1]=-copy[1];copy[5]=-copy[5];copy[9]=-copy[9];copy[13]=-copy[13];sg_apply_uniforms(0,&(sg_range){copy,(size_t)size});
  }else sg_apply_uniforms(i,&(sg_range){at,(size_t)size});
  at+=size;
 }
}
/* A draw through pipeline p: count vertices from first (or indices, for an indexed pipeline, from first of `indices`) as instance_count
   instances from record first_instance of its instanced buffers; buffers[i] its buffer i (0 for one it doesn't read), the program's textures
   and samplings by slot, its uniform blocks' bytes one after another by slot. 0, drawing nothing, for anything invalid. */
int helix_draw(uint32_t p,const uint32_t *buffers,int buffer_count,uint32_t indices,int first,int count,int first_instance,int instance_count,
               const uint32_t *textures,const int *samplings,int texture_count,const void *uniforms,int uniform_bytes){
 const int pslot=p&0xffff;
 if(!active||pslot>=256||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID)return 0;
 const int shader=pipeline_info[pslot].shader&0xffff,group=pipeline_info[pslot].lines?2:3,indexed=pipeline_info[pslot].indexed;
 if(first<0||count<=0||count%group||first_instance<0||instance_count<=0||buffer_count<pipeline_info[pslot].buffer_count)return 0;
 sg_bindings bindings={0};
 if(indexed){
  const int islot=indices&0xffff;
  if(islot>=256||sg_query_buffer_state((sg_buffer){indices})!=SG_RESOURCESTATE_VALID||!index_buffers[islot]||(long)(first+count)*4>used[islot])return 0;
  bindings.index_buffer=(sg_buffer){indices};
 }
 for(int b=0;b<pipeline_info[pslot].buffer_count;b++){
  if(!pipeline_info[pslot].read[b])continue;
  const int slot=buffers[b]&0xffff,stride=pipeline_info[pslot].stride[b],instanced=pipeline_info[pslot].instanced[b];
  if(slot>=256||sg_query_buffer_state((sg_buffer){buffers[b]})!=SG_RESOURCESTATE_VALID||index_buffers[slot])return 0;
  if(instanced&&(long)(first_instance+instance_count)*stride>used[slot])return 0;
  if(!instanced&&!indexed&&(long)(first+count)*stride>used[slot])return 0;
  bindings.vertex_buffers[b]=current_buffer(buffers[b]);
  if(instanced)bindings.vertex_buffer_offsets[b]=first_instance*stride;
 }
 if(!bind_program(shader,&bindings,textures,samplings,texture_count,uniform_bytes))return 0;
 /* Flipped, the front faces wind the other way: the pipeline's twin. */
 sg_apply_pipeline(flipped&&flipped_pipelines[pslot].id?flipped_pipelines[pslot]:(sg_pipeline){p});
 sg_apply_bindings(&bindings);
 apply_blocks(shader,pipeline_info[pslot].flip,uniforms);
 for(int b=0;b<pipeline_info[pslot].buffer_count;b++)if(pipeline_info[pslot].read[b])bound[buffers[b]&0xffff]=1;
 sg_draw(first,count,instance_count);return 1;
}
void helix_end(void){
 if(active!=1)abort();sg_end_pass();sg_commit();active=0;frame_ended=1;
 /* Stream buffers start each frame empty and unrenamed; a static one keeps its size. */
 for(int i=0;i<256;i++){if(stream_buffers[i]){used[i]=0;renamed[i]=bound[i]=0;}data_textures[i].written=data_textures[i].bound=data_textures[i].renamed=0;}
}
/* Destroys a pipeline, its twin and its record. */
static void destroy_pipeline(uint32_t id){
 const int slot=id&0xffff;
 sg_destroy_pipeline((sg_pipeline){id});
 if(slot<256){if(flipped_pipelines[slot].id)sg_destroy_pipeline(flipped_pipelines[slot]);flipped_pipelines[slot].id=0;memset(&pipeline_info[slot],0,sizeof pipeline_info[slot]);}
}
int helix_destroy(int kind,uint32_t id){
 int slot=id&0xffff;
 if(kind==0&&sg_query_buffer_state((sg_buffer){id})==SG_RESOURCESTATE_VALID){
  sg_destroy_buffer((sg_buffer){id});
  if(slot<256){stream_buffers[slot]=0;for(int i=0;i<MAX_RENAMES;i++)if(extras[slot][i].id)sg_destroy_buffer(extras[slot][i]);memset(extras[slot],0,sizeof extras[slot]);}
  return 1;
 }
 if(kind==1&&sg_query_view_state((sg_view){id})==SG_RESOURCESTATE_VALID){
  sg_image image=sg_query_view_image((sg_view){id});sg_destroy_view((sg_view){id});sg_destroy_image(image);
  if(slot<256&&shadow_maps[slot].image.id){
   for(int i=0;i<shadow_maps[slot].count;i++)sg_destroy_view(shadow_maps[slot].layers[i]);
   memset(&shadow_maps[slot],0,sizeof shadow_maps[slot]);
  }
  if(slot<256&&data_textures[slot].image.id){
   for(int i=0;i<MAX_RENAMES;i++)if(data_textures[slot].extra_images[i].id){sg_destroy_view(data_textures[slot].extra_views[i]);sg_destroy_image(data_textures[slot].extra_images[i]);}
   free(data_textures[slot].copy);memset(&data_textures[slot],0,sizeof data_textures[slot]);
  }
  if(slot<256&&targets[slot].color.id){
   sg_destroy_view(targets[slot].color);sg_destroy_view(targets[slot].depth);sg_destroy_image(targets[slot].depth_image);
   if(targets[slot].samples_image.id){sg_destroy_view(targets[slot].resolve);sg_destroy_image(targets[slot].samples_image);}
   memset(&targets[slot],0,sizeof targets[slot]);
  }
  return 1;
 }
 if(kind==3&&sg_query_shader_state((sg_shader){id})==SG_RESOURCESTATE_VALID){
  /* Its pipelines (and their twins) go first. */
  for(int i=0;i<256;i++)if(pipeline_info[i].id&&pipeline_info[i].shader==id)destroy_pipeline(pipeline_info[i].id);
  sg_destroy_shader((sg_shader){id});return 1;
 }
 if(kind==2&&sg_query_pipeline_state((sg_pipeline){id})==SG_RESOURCESTATE_VALID){destroy_pipeline(id);return 1;}
 return 0;
}
