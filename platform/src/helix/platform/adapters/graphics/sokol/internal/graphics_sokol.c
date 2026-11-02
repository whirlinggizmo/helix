#include "graphics.h"
#include "graphics_sokol.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "surface.h"
#define SOKOL_GFX_IMPL
#define SOKOL_GLCORE
#include "sokol/sokol_gfx.h"
/* sokol_log, private to this file: each sokol piece keeps its own copy, as a build may link any of them without the others. */
#define SOKOL_LOG_IMPL
#define SOKOL_LOG_API_DECL static
#include "sokol/sokol_log.h"

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
/* The uniform setters and the generic attribute sokol never calls, loaded the first time a program is made. */
__declspec(dllimport) PROC __stdcall wglGetProcAddress(LPCSTR name);
typedef void (APIENTRY *helix_uniform_uiv)(GLint location,GLsizei count,const GLuint *value);
typedef void (APIENTRY *helix_uniform_matrix)(GLint location,GLsizei count,GLboolean transpose,const GLfloat *value);
typedef void (APIENTRY *helix_attrib4fv)(GLuint index,const GLfloat *value);
typedef void (APIENTRY *helix_active_uniform)(GLuint program,GLuint index,GLsizei size,GLsizei *length,GLint *count,GLenum *type,GLchar *name);
static helix_uniform_uiv helix_glUniform1uiv,helix_glUniform2uiv,helix_glUniform3uiv,helix_glUniform4uiv;
static helix_uniform_matrix helix_glUniformMatrix2fv,helix_glUniformMatrix3fv;
static helix_attrib4fv helix_glVertexAttrib4fv;
static helix_active_uniform helix_glGetActiveUniform;
#define glUniform1uiv helix_glUniform1uiv
#define glUniform2uiv helix_glUniform2uiv
#define glUniform3uiv helix_glUniform3uiv
#define glUniform4uiv helix_glUniform4uiv
#define glUniformMatrix2fv helix_glUniformMatrix2fv
#define glUniformMatrix3fv helix_glUniformMatrix3fv
#define glVertexAttrib4fv helix_glVertexAttrib4fv
#define glGetActiveUniform helix_glGetActiveUniform
#ifndef GL_ACTIVE_UNIFORMS
#define GL_ACTIVE_UNIFORMS 0x8B86
#endif
static void load_gl(void){
 if(helix_glVertexAttrib4fv)return;
 helix_glUniform1uiv=(helix_uniform_uiv)wglGetProcAddress("glUniform1uiv");helix_glUniform2uiv=(helix_uniform_uiv)wglGetProcAddress("glUniform2uiv");
 helix_glUniform3uiv=(helix_uniform_uiv)wglGetProcAddress("glUniform3uiv");helix_glUniform4uiv=(helix_uniform_uiv)wglGetProcAddress("glUniform4uiv");
 helix_glUniformMatrix2fv=(helix_uniform_matrix)wglGetProcAddress("glUniformMatrix2fv");helix_glUniformMatrix3fv=(helix_uniform_matrix)wglGetProcAddress("glUniformMatrix3fv");
 helix_glGetActiveUniform=(helix_active_uniform)wglGetProcAddress("glGetActiveUniform");
 helix_glVertexAttrib4fv=(helix_attrib4fv)wglGetProcAddress("glVertexAttrib4fv");
}
#else
static void load_gl(void){}
#endif

/* Programs (helix_shader), by shader slot: their uniform blocks' sizes by index in a draw's uniforms (a vertex block's slot, a fragment
   block's 4 + its slot, a block both stages read at both, 0 for none), the texture slots they sample (a bit each), and the GL uniform
   setters their blocks' members are applied by. GL 410 holds a block as a uniform of its struct type; sokol's own uniform blocks compute
   their offsets from a flat member list (no struct's padding, no mat2, mat3, uint or bool, 16 members at most), so each member is set
   here, by its type, from its std140 place in the block. */
#define MAX_BLOCKS 8
#define MAX_TEXTURES 12
/* A setter: count elements of a member (base 'f', 'i' or 'u'; comps a column's components; cols a matrix's columns, else 1), the first at
   offset in the bytes of block (an index), each stride bytes after the last, to the GL location loc. */
typedef struct{int block,offset,stride,count,loc;char base,comps,cols;}setter;
static struct{int texture_mask,unfiltered_mask,block_size[MAX_BLOCKS];char kind[MAX_TEXTURES];setter *setters;int setter_count;}programs[256];
/* What an unbound slot reads (a draw's texture 0 where the program declares one): a 1x1 texture of the slot's kind, clear, made when first
   needed. */
static uint32_t placeholders[3];
static sg_sampler sampler_of(int sampling);
/* One sampler for each Sampling value used (helix.platform.Sampling: bit 0 linear, bits 1-2 wrap u, bits 3-4 wrap v, bits 5-6 the mipmap
   filter, bits 7-9 the anisotropy's power of two), made when first used. */
#define SAMPLINGS 1024
static sg_sampler samplers[SAMPLINGS];
/* Pipelines (helix_pipeline), by pipeline slot: what a draw through one checks and binds (its program, its buffers' strides and whether each
   is an instance's and read at all, indexed or not, the elements a primitive takes (1 points, 2 lines, 3 triangles), depth alone, block 0's clip flip). Per buffer slot: whether it is an
   index buffer. */
static struct{uint32_t id,shader;int buffer_count,stride[HELIX_MAX_VERTEX_BUFFERS],instanced[HELIX_MAX_VERTEX_BUFFERS],read[HELIX_MAX_VERTEX_BUFFERS],indexed,group,depth_only,flip,flip_slot,flip_offset,fed;float constants[HELIX_MAX_VERTEX_ATTRIBUTES][4];}pipeline_info[256];
/* A sokol pipeline is made for one kind of pass (its color format, depth format and samples), and a flipped pass draws triangles with their
   front faces the other way round: a pipeline's variants, by pipeline slot, each made from its description the first time a draw needs it.
   A variant is the pass's kind: bit 0 half floats, bit 1 no depth, bits 2-3 the samples' power of two exclusive-or the screen's (0: the
   screen's samples), bit 4 flipped; variant 0 (the screen's) is the pipeline itself. */
#define VARIANTS 32
static sg_pipeline_desc pipeline_descs[256];static sg_pipeline variants[256][VARIANTS];
static int index_buffers[256];
/* active: 1 in the screen's pass, 2 in a target's; flipped: the pass is drawn flipped (GL, whose framebuffers' origin is the bottom left, into a
   target), so a target is stored top row first, as every texture is; pass_variant: the pipelines' variant the pass draws with. */
static int active,flipped,pass_variant,used[256],frame_width,frame_height;
/* The texture the open target or shadow pass draws into (its view), 0 for none: a draw may not sample it. */
static uint32_t pass_texture;
/* The screen's size this frame, and whether helix_end has ended it (so it can be read back). */
static int screen_width,screen_height,frame_ended;
/* A stream buffer written again after a draw bound it this frame takes another sokol buffer of the same size, as sokol allows writes only
   before a bind: renamed[slot] is how many of its extras are in use this frame, bound[slot] whether the current one was bound since its write. */
#define MAX_RENAMES 8
static sg_buffer extras[256][MAX_RENAMES];static int renamed[256],bound[256];
/* Render targets, by texture view slot: their color and depth attachment views (no depth view without depth), depth image and size, the
   pipelines' variant drawing into them (unflipped), and whether a pass has cleared them yet. */
static struct{sg_view color,depth,resolve;sg_image depth_image,samples_image;int width,height,variant,cleared;}targets[256];
/* Shadow maps, by texture view slot: the depth array, an attachment view a layer, and their size; and the sampler they're read through
   (comparing, linear, clamped), made with the first. */
#define MAX_SHADOW_LAYERS 16
static struct{sg_image image;sg_view layers[MAX_SHADOW_LAYERS];int size,count;}shadow_maps[256];static sg_sampler comparison;
/* Data textures, by texture view slot: RGBA32F, rewritten whole by helix_update_texture. sokol's write-transient images hold what's written for
   the frame alone, and take writes only until they're bound, so the adapter keeps the contents (copy) and writes them at the first bind of a
   frame without a write of its own; and a write after a bind goes to a spare of the same size (made the first time it's needed): renamed is
   how many are in use this frame, and the texture's draws read the latest. */
static struct{sg_image image;int width,height,written,bound,renamed;float *copy;sg_image extra_images[MAX_RENAMES];sg_view extra_views[MAX_RENAMES];}data_textures[256];
/* Per buffer slot: whether it is a stream buffer (createBuffer's), rewritten each frame. */
static int stream_buffers[256];
/* The samples a pixel the window's framebuffer got (GL's count: what the window asked for, or fewer), read at setup. */
static int window_samples=1,max_samples=1;
/* The window as sokol_gfx sees it (surface.h): framebuffer 0 of its GL context, RGBA8 with depth. */
static sg_environment environment(void){
 return (sg_environment){.defaults={.color_format=SG_PIXELFORMAT_RGBA8,.depth_format=SG_PIXELFORMAT_DEPTH,.sample_count=helix_surface_samples()}};
}
static sg_swapchain swapchain(void){
 return (sg_swapchain){.width=helix_surface_width(),.height=helix_surface_height(),.sample_count=helix_surface_samples(),
  .color_format=SG_PIXELFORMAT_RGBA8,.depth_format=SG_PIXELFORMAT_DEPTH,.gl.framebuffer=0};
}
int helix_msaa_samples(void){return window_samples;}
int helix_max_msaa_samples(void){return max_samples;}
/* The power of two of a sample count (1, 2, 4 or 8), and the screen's samples (sokol's environment default, which pipelines are made for). */
static int power_of(int samples){return samples>=8?3:samples>=4?2:samples>=2?1:0;}
static int screen_samples(void){const int n=sg_query_desc().environment.defaults.sample_count;return n>1?n:1;}
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
void helix_dispose(void){
 for(int i=0;i<SAMPLINGS;i++)if(samplers[i].id)sg_destroy_sampler(samplers[i]);
 if(comparison.id)sg_destroy_sampler(comparison);
 sg_shutdown();
 memset(placeholders,0,sizeof placeholders);
}
/* helix.platform.TextureFormat's values as sokol's: RGBA8, BC7, ASTC 4x4, ETC2 RGBA8, RGBA16F. */
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
/* Rewrites a data texture's contents whole: its current image, unless a draw bound it since its last write, then the next spare. */
static int update_data(int slot,const void *data,int bytes){
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
/* Replaces a rectangle of a texture's texels: a data texture's whole (x and y 0, its size), inside a pass or outside; a helix_texture
   texture's top level, RGBA8 or half floats, outside a pass, through GL directly (sokol can't write an image made with its data), with
   sokol's cached GL state reset after. GL's rows run from the first, which is the texture's top. 0 for anything else. */
int helix_update_texture(uint32_t texture,int x,int y,int w,int h,const void *data,int bytes){
 const int slot=texture&0xffff;
 if(!data||slot>=256||x<0||y<0||w<=0||h<=0||sg_query_view_state((sg_view){texture})!=SG_RESOURCESTATE_VALID)return 0;
 if(data_textures[slot].image.id)return x||y||w!=data_textures[slot].width||h!=data_textures[slot].height?0:update_data(slot,data,bytes);
 if(active||targets[slot].color.id||shadow_maps[slot].image.id)return 0;
 const sg_image image=sg_query_view_image((sg_view){texture});
 const sg_image_desc desc=sg_query_image_desc(image);
 const int half=desc.pixel_format==SG_PIXELFORMAT_RGBA16F;
 if(desc.type!=SG_IMAGETYPE_2D||(!half&&desc.pixel_format!=SG_PIXELFORMAT_RGBA8)||x+w>desc.width||y+h>desc.height||(size_t)bytes<level_bytes(half?4:0,w,h))return 0;
 const sg_gl_image_info info=sg_gl_query_image_info(image);
 glBindTexture(GL_TEXTURE_2D,info.tex[info.active_slot]);glPixelStorei(GL_UNPACK_ALIGNMENT,1);
 glTexSubImage2D(GL_TEXTURE_2D,0,x,y,w,h,GL_RGBA,half?GL_HALF_FLOAT:GL_UNSIGNED_BYTE,data);
 const int ok=glGetError()==GL_NO_ERROR;
 sg_reset_state_cache();
 return ok;
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
/* A helix.platform.Blend (bits 0-3 the color's source factor, 4-7 its destination's, 8-11 and 12-15 the alpha's, 16-18 the color's
   operation, 19-21 the alpha's) as sokol's blend state: BlendFactor's and BlendOperation's values in order. No blending for One, Zero and
   Add on both; MIN and MAX take every factor ONE (sokol checks it; GL ignores them). 0 in *ok for a value outside the enums. */
static sg_blend_state blend_of(int blend,int *ok){
 static const sg_blend_factor factors[11]={SG_BLENDFACTOR_ZERO,SG_BLENDFACTOR_ONE,SG_BLENDFACTOR_SRC_COLOR,SG_BLENDFACTOR_ONE_MINUS_SRC_COLOR,
  SG_BLENDFACTOR_DST_COLOR,SG_BLENDFACTOR_ONE_MINUS_DST_COLOR,SG_BLENDFACTOR_SRC_ALPHA,SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,SG_BLENDFACTOR_DST_ALPHA,
  SG_BLENDFACTOR_ONE_MINUS_DST_ALPHA,SG_BLENDFACTOR_SRC_ALPHA_SATURATED};
 static const sg_blend_op ops[5]={SG_BLENDOP_ADD,SG_BLENDOP_SUBTRACT,SG_BLENDOP_REVERSE_SUBTRACT,SG_BLENDOP_MIN,SG_BLENDOP_MAX};
 const int cs=blend&15,cd=blend>>4&15,as=blend>>8&15,ad=blend>>12&15,co=blend>>16&7,ao=blend>>19&7;
 *ok=blend>=0&&blend<1<<22&&cs<11&&cd<11&&as<11&&ad<11&&co<5&&ao<5;
 if(!*ok||(cs==1&&cd==0&&as==1&&ad==0&&co==0&&ao==0))return (sg_blend_state){0};
 const int cm=co>=3,am=ao>=3;
 return (sg_blend_state){.enabled=true,.src_factor_rgb=cm?SG_BLENDFACTOR_ONE:factors[cs],.dst_factor_rgb=cm?SG_BLENDFACTOR_ONE:factors[cd],.op_rgb=ops[co],
  .src_factor_alpha=am?SG_BLENDFACTOR_ONE:factors[as],.dst_factor_alpha=am?SG_BLENDFACTOR_ONE:factors[ad],.op_alpha=ops[ao]};
}
/* A helix.platform.ColorChannels (bit 0 red, 1 green, 2 blue, 3 alpha) as sokol's write mask. */
static sg_color_mask mask_of(int channels){return channels?(sg_color_mask)channels:SG_COLORMASK_NONE;}
/* A pipeline as helix.platform.PipelineDesc describes it, its ints in order: shader, primitive (0 triangles, 1 lines, 2 points), indexed, blend
   (blend_of), depth test (0 none, 1 less or equal, 2 greater), depth write, cull (0 none, 1 back, 2 front), clockwise, depth only, clip flip
   (0 none, 1 clip scale, 2 view-projection), the color channels written (mask_of), the flip uniform's vertex block slot and byte offset, the
   buffer count, then each buffer's stride, instanced and attribute count, each attribute's slot, format (graphics.h) and offset, then the count of
   attribute constants and each one's slot and four floats' bits. An attribute no buffer feeds reads its constant, or (0, 0, 0, 1): GL's
   generic attribute value, set before each draw. 0 for a description it can't make (a constant for a slot a buffer feeds among them). */
uint32_t helix_pipeline(const int *desc,int count){
 if(!desc||count<15)return 0;
 const uint32_t shader=(uint32_t)desc[0];const int group=desc[1]==2?1:desc[1]==1?2:3,indexed=desc[2],depth_only=desc[8],clockwise=desc[7],channels=desc[10];int blend_ok=0;
 const sg_blend_state blend=blend_of(desc[3],&blend_ok);
 if(desc[1]<0||desc[1]>2||!blend_ok||channels<0||channels>15||(shader&0xffff)>=256||sg_query_shader_state((sg_shader){shader})!=SG_RESOURCESTATE_VALID)return 0;
 sg_pipeline_desc pd={.shader={shader},.primitive_type=group==1?SG_PRIMITIVETYPE_POINTS:group==2?SG_PRIMITIVETYPE_LINES:SG_PRIMITIVETYPE_TRIANGLES,
  .index_type=indexed?SG_INDEXTYPE_UINT32:SG_INDEXTYPE_NONE,.depth={.compare=desc[4]==2?SG_COMPAREFUNC_GREATER:desc[4]?SG_COMPAREFUNC_LESS_EQUAL:SG_COMPAREFUNC_ALWAYS,.write_enabled=desc[5]!=0},
  .cull_mode=desc[6]==2?SG_CULLMODE_FRONT:desc[6]?SG_CULLMODE_BACK:SG_CULLMODE_NONE,.face_winding=clockwise?SG_FACEWINDING_CW:SG_FACEWINDING_CCW,.colors[0]={.blend=blend,.write_mask=mask_of(channels)}};
 /* Depth alone: a shadow pass's, no color attachment. */
 if(depth_only){pd.depth.pixel_format=SG_PIXELFORMAT_DEPTH;pd.color_count=0;pd.sample_count=1;}
 const int flip_slot=desc[11],flip_offset=desc[12];
 if(desc[9]&&(flip_slot<0||flip_slot>3||flip_offset<0||flip_offset%4))return 0;
 const int buffers=desc[13];int at=14,fed=0,strides[HELIX_MAX_VERTEX_BUFFERS]={0},instanced[HELIX_MAX_VERTEX_BUFFERS]={0},read[HELIX_MAX_VERTEX_BUFFERS]={0};
 if(buffers<0||buffers>HELIX_MAX_VERTEX_BUFFERS)return 0;
 for(int b=0;b<buffers;b++){
  if(at+3>count)return 0;
  strides[b]=desc[at];instanced[b]=desc[at+1]!=0;const int attrs=desc[at+2];at+=3;
  if(strides[b]<0||attrs<0||at+attrs*3>count)return 0;
  pd.layout.buffers[b].stride=strides[b];if(instanced[b])pd.layout.buffers[b].step_func=SG_VERTEXSTEP_PER_INSTANCE;
  for(int a=0;a<attrs;a++,at+=3){
   const int slot=desc[at],format=desc[at+1],offset=desc[at+2],bytes=helix_vertex_format_bytes(format);
   if(slot<0||slot>=HELIX_MAX_VERTEX_ATTRIBUTES||!bytes||offset<0||offset+bytes>strides[b])return 0;
   static const sg_vertex_format formats[HELIX_VERTEX_FORMATS]={SG_VERTEXFORMAT_FLOAT,SG_VERTEXFORMAT_FLOAT2,SG_VERTEXFORMAT_FLOAT3,SG_VERTEXFORMAT_FLOAT4,
    SG_VERTEXFORMAT_UBYTE4N,SG_VERTEXFORMAT_BYTE4N,SG_VERTEXFORMAT_USHORT2N,SG_VERTEXFORMAT_SHORT2N,SG_VERTEXFORMAT_USHORT4N,SG_VERTEXFORMAT_SHORT4N,
    SG_VERTEXFORMAT_HALF2,SG_VERTEXFORMAT_HALF4};
   pd.layout.attrs[slot]=(sg_vertex_attr_state){.format=formats[format],.offset=offset,.buffer_index=b};
   fed|=1<<slot;
  }
  read[b]=attrs>0;
 }
 float constants[HELIX_MAX_VERTEX_ATTRIBUTES][4];
 for(int i=0;i<HELIX_MAX_VERTEX_ATTRIBUTES;i++){constants[i][0]=constants[i][1]=constants[i][2]=0;constants[i][3]=1;}
 if(at>=count)return 0;
 const int constant_count=desc[at++];
 if(constant_count<0||at+constant_count*5>count)return 0;
 for(int c=0;c<constant_count;c++,at+=5){
  const int slot=desc[at];
  if(slot<0||slot>=HELIX_MAX_VERTEX_ATTRIBUTES||fed&1<<slot)return 0;
  memcpy(constants[slot],&desc[at+1],sizeof constants[slot]);
 }
 sg_pipeline pipeline=sg_make_pipeline(&pd);
 if(sg_query_pipeline_state(pipeline)!=SG_RESOURCESTATE_VALID||(pipeline.id&0xffff)>=256){sg_destroy_pipeline(pipeline);return 0;}
 const int slot=pipeline.id&0xffff;
 pipeline_descs[slot]=pd;memset(variants[slot],0,sizeof variants[slot]);variants[slot][0]=pipeline;
 pipeline_info[slot].id=pipeline.id;pipeline_info[slot].shader=shader;pipeline_info[slot].buffer_count=buffers;pipeline_info[slot].indexed=indexed!=0;pipeline_info[slot].group=group;
 pipeline_info[slot].depth_only=depth_only!=0;pipeline_info[slot].flip=desc[9];
 pipeline_info[slot].flip_slot=flip_slot;pipeline_info[slot].flip_offset=flip_offset;pipeline_info[slot].fed=fed;memcpy(pipeline_info[slot].constants,constants,sizeof constants);
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
/* A member's type as a setter's base, components a column and columns: GL 410 declares a bool as a uint, a bvecN as a uvecN. 0 for one it
   doesn't know. */
static int type_of(const char *type,setter *u){
 static const struct{const char *name;char base,comps,cols;}types[]={{"float",'f',1,1},{"vec2",'f',2,1},{"vec3",'f',3,1},{"vec4",'f',4,1},
  {"int",'i',1,1},{"ivec2",'i',2,1},{"ivec3",'i',3,1},{"ivec4",'i',4,1},{"uint",'u',1,1},{"uvec2",'u',2,1},{"uvec3",'u',3,1},{"uvec4",'u',4,1},
  {"bool",'u',1,1},{"bvec2",'u',2,1},{"bvec3",'u',3,1},{"bvec4",'u',4,1},{"mat2",'f',2,2},{"mat3",'f',3,3},{"mat4",'f',4,4}};
 for(size_t i=0;i<sizeof types/sizeof types[0];i++)if(!strcmp(types[i].name,type)){u->base=types[i].base;u->comps=types[i].comps;u->cols=types[i].cols;return 1;}
 return 0;
}
/* The GL name of element e of a member whose path's parts are parts[0..n) (parts[0] the block's uniform), its array at part k (k == n:
   none), as GL 410 names a struct's fields: an array of structs indexed at the struct (`_31.lights[1].on`), any other array at itself. */
static void element_name(char *out,size_t size,char parts[][128],int n,int k,int e){
 size_t at=0;out[0]=0;
 for(int i=0;i<n;i++){
  at+=(size_t)snprintf(out+at,at<size?size-at:0,"%s%s",i?".":"",parts[i]);
  if(i==k&&e>=0)at+=(size_t)snprintf(out+at,at<size?size-at:0,"[%d]",e);
 }
}
/* The location of the uniform named name in prog, -1 unless the program has it: its name exactly as GL lists its active uniforms, or an
   element of an array GL lists (`weights[2]` of `weights[0]`, three long). glGetUniformLocation alone can't say: NVIDIA's driver finds
   names GL doesn't give (a location for `lights.color[0]`, where the array is `lights`), so the array a member is in would be guessed
   wrong. */
static GLint located(GLuint prog,const char *name){
 GLint uniforms=0;glGetProgramiv(prog,GL_ACTIVE_UNIFORMS,&uniforms);
 const size_t length=strlen(name);
 for(GLint i=0;i<uniforms;i++){
  char listed[640];GLsizei used=0;GLint size=0;GLenum type=0;
  glGetActiveUniform(prog,(GLuint)i,sizeof listed,&used,&size,&type,listed);
  if(!strcmp(listed,name))return glGetUniformLocation(prog,name);
  /* An array GL lists as its first element: name is its base, or one of its elements. */
  if(used<3||strcmp(listed+used-3,"[0]"))continue;
  const size_t base=(size_t)used-3;
  if(length==base&&!strncmp(listed,name,base))return glGetUniformLocation(prog,name);
  int element=-1,end=0;
  if(length>base&&!strncmp(listed,name,base)&&sscanf(name+base,"[%d]%n",&element,&end)==1&&(size_t)(base+(size_t)end)==length&&element>=0&&element<size)
   return glGetUniformLocation(prog,name);
 }
 return -1;
}
/* Adds the setters of one member through a block's uniform named var: one setting every element (an array whose elements' locations follow
   one another), or one an element (a field of an array of structs, or an array GL placed apart). */
static int add_setters(setter **list,int *count,int *cap,GLuint prog,const char *var,const char *path,setter u,int elements){
 char full[512],name[640],parts[16][128];int n=0;
 size_t vl=strlen(var);
 if(!strncmp(path,var,vl)&&path[vl]=='.')snprintf(full,sizeof full,"%s",path);else snprintf(full,sizeof full,"%s.%s",var,path);
 for(const char *at=full;*at&&n<16;n++){
  const char *dot=strchr(at,'.');size_t len=dot?(size_t)(dot-at):strlen(at);if(len>127)return 0;
  memcpy(parts[n],at,len);parts[n][len]=0;at=dot?dot+1:at+len;
 }
 #define PUSH(x) do{if(*count==*cap){*cap=*cap?*cap*2:16;setter *g=realloc(*list,sizeof(setter)*(size_t)*cap);if(!g)return 0;*list=g;}(*list)[(*count)++]=(x);}while(0)
 if(elements<=1){
  element_name(name,sizeof name,parts,n,n,-1);u.loc=located(prog,name);u.count=1;
  if(u.loc>=0)PUSH(u);
  return 1;
 }
 /* Which part the array is at: the first where an element is there. */
 int k=-1;
 for(int part=n-1;part>=1&&k<0;part--)for(int e=0;e<elements;e++){element_name(name,sizeof name,parts,n,part,e);if(located(prog,name)>=0){k=part;break;}}
 if(k<0)return 1;
 int first=-1,together=k==n-1;
 for(int e=0;e<elements;e++){
  element_name(name,sizeof name,parts,n,k,e);const int loc=located(prog,name);
  if(e==0)first=loc;
  if(loc<0||loc!=first+e)together=0;
 }
 if(together){u.loc=first;u.count=elements;PUSH(u);return 1;}
 const int offset=u.offset;
 for(int e=0;e<elements;e++){
  element_name(name,sizeof name,parts,n,k,e);u.loc=located(prog,name);u.count=1;u.offset=offset+e*u.stride;
  if(u.loc>=0)PUSH(u);
 }
 #undef PUSH
 return 1;
}
/* A program from its GLSL 410 stages and its layout, a line each: "a <slot> <name>" an attribute; "u <slot> <v|f|b> <size> <name>" a uniform
   block (b: one both stages read, at the slot in each), each followed by its members, "m <type> <offset> <count> <stride> <path>", at their
   std140 places; "n <block> <vertex> <fragment>" the block's uniform's name in each stage (- for none); "t <slot> <v|f> <name>" a texture and
   its sampler, sharing the slot, "s <slot> <v|f> <name>" a shadow map (a depth array) and its comparison sampler, "c <slot> <v|f> <name>" a
   cube and its sampler, "d <slot> <v|f> <name>" a data texture (RGBA32F, unfiltered) and its nonfiltering sampler. */
uint32_t helix_shader(const char *vs,const char *fs,const char *layout){
 load_gl();
 sg_shader_desc desc={.vertex_func={.source=vs,.entry="main"},.fragment_func={.source=fs,.entry="main"},.label="app_shader"};
 static char names[32][128];int name=0,textures=0,unfiltered=0,sizes[MAX_BLOCKS]={0};char kinds[MAX_TEXTURES]={0};
 /* The blocks and their members as read, applied once the program is linked. */
 static struct{int slot;char stage;char name[128],vertex[128],fragment[128];}blocks[MAX_BLOCKS];int block_count=0;
 static struct{int block,offset,count,stride;char type[16],path[256];}members[1024];int member_count=0;
 for(const char *line=layout;line&&*line;){
  char kind,stage,type[16],word[256],other[128],third[128];int slot,size,offset,count,stride,used=0;
  if(name>=32)return 0;
  if(sscanf(line," a %d %127s%n",&slot,names[name],&used)==2){
   if(slot<0||slot>=SG_MAX_VERTEX_ATTRIBUTES)return 0;
   desc.attrs[slot].base_type=SG_SHADERATTRBASETYPE_FLOAT;desc.attrs[slot].glsl_name=names[name++];
  }else if(sscanf(line," u %d %c %d %127s%n",&slot,&stage,&size,word,&used)==4){
   if(slot<0||slot>3||size<=0||block_count==MAX_BLOCKS||(stage!='v'&&stage!='f'&&stage!='b'))return 0;
   blocks[block_count].slot=slot;blocks[block_count].stage=stage;snprintf(blocks[block_count].name,128,"%s",word);
   blocks[block_count].vertex[0]=blocks[block_count].fragment[0]=0;block_count++;
   if(stage!='f')sizes[slot]=size;
   if(stage!='v')sizes[4+slot]=size;
  }else if(sscanf(line," m %15s %d %d %d %255s%n",type,&offset,&count,&stride,word,&used)==5){
   if(!block_count||member_count==1024||offset<0||count<1||stride<0)return 0;
   members[member_count].block=block_count-1;members[member_count].offset=offset;members[member_count].count=count;members[member_count].stride=stride;
   snprintf(members[member_count].type,16,"%s",type);snprintf(members[member_count].path,256,"%s",word);member_count++;
  }else if(sscanf(line," n %127s %127s %127s%n",other,word,third,&used)==3){
   for(int b=0;b<block_count;b++)if(!strcmp(blocks[b].name,other)){
    snprintf(blocks[b].vertex,128,"%s",strcmp(word,"-")?word:"");snprintf(blocks[b].fragment,128,"%s",strcmp(third,"-")?third:"");
   }
  }else if(sscanf(line," %c %d %c %127s%n",&kind,&slot,&stage,names[name],&used)==4&&(kind=='t'||kind=='s'||kind=='c'||kind=='d')){
   if(slot<0||slot>=MAX_TEXTURES)return 0;
   const sg_shader_stage st=stage=='v'?SG_SHADERSTAGE_VERTEX:SG_SHADERSTAGE_FRAGMENT;const int shadow=kind=='s';
   desc.views[slot].texture=(sg_shader_texture_view){.stage=st,.image_type=shadow?SG_IMAGETYPE_ARRAY:kind=='c'?SG_IMAGETYPE_CUBE:SG_IMAGETYPE_2D,
    .sample_type=shadow?SG_IMAGESAMPLETYPE_DEPTH:kind=='d'?SG_IMAGESAMPLETYPE_UNFILTERABLE_FLOAT:SG_IMAGESAMPLETYPE_FLOAT};
   desc.samplers[slot]=(sg_shader_sampler){.stage=st,.sampler_type=shadow?SG_SAMPLERTYPE_COMPARISON:kind=='d'?SG_SAMPLERTYPE_NONFILTERING:SG_SAMPLERTYPE_FILTERING};
   desc.texture_sampler_pairs[slot]=(sg_shader_texture_sampler_pair){.stage=st,.view_slot=(uint8_t)slot,.sampler_slot=(uint8_t)slot,.glsl_name=names[name++]};
   textures|=1<<slot;kinds[slot]=kind;if(kind=='d')unfiltered|=1<<slot;
  }else return 0;
  line+=used;while(*line=='\n'||*line==' ')line++;
 }
 sg_shader shader=sg_make_shader(&desc);
 if(sg_query_shader_state(shader)!=SG_RESOURCESTATE_VALID||(shader.id&0xffff)>=256){sg_destroy_shader(shader);return 0;}
 /* Each member's setters through the block's uniform in each stage that has it (once where both stages name it alike). */
 const GLuint prog=sg_gl_query_shader_info(shader).prog;
 setter *list=NULL;int list_count=0,cap=0;
 for(int i=0;i<member_count;i++){
  const int b=members[i].block;setter u={.block=blocks[b].stage=='f'?4+blocks[b].slot:blocks[b].slot,.offset=members[i].offset,.stride=members[i].stride};
  if(!type_of(members[i].type,&u)){free(list);sg_destroy_shader(shader);return 0;}
  const char *vars[2]={blocks[b].stage!='f'?blocks[b].vertex:"",blocks[b].stage!='v'?blocks[b].fragment:""};
  for(int v=0;v<2;v++){
   if(!vars[v][0]||(v==1&&!strcmp(vars[0],vars[1])))continue;
   if(!add_setters(&list,&list_count,&cap,prog,vars[v],members[i].path,u,members[i].count)){free(list);sg_destroy_shader(shader);return 0;}
  }
 }
 int slot=shader.id&0xffff;programs[slot].texture_mask=textures;programs[slot].unfiltered_mask=unfiltered;memcpy(programs[slot].kind,kinds,sizeof kinds);memcpy(programs[slot].block_size,sizes,sizeof sizes);
 free(programs[slot].setters);programs[slot].setters=list;programs[slot].setter_count=list_count;
 return shader.id;
}
/* Whether render targets of format (helix.platform.TextureFormat's) can be drawn into, blended over and sampled filtered: RGBA8, and RGBA16F
   where GL has it. */
int helix_can_render(int format){
 if(format!=0&&format!=4)return 0;
 const sg_pixelformat_info info=sg_query_pixelformat(format_of(format));
 return info.render&&info.blend&&info.sample&&info.filter;
}
/* The most samples a render target of format takes: GL's most (max_samples) where sokol multisamples the format, else 1. */
int helix_max_target_samples(int format){return helix_can_render(format)&&sg_query_pixelformat(format_of(format)).msaa?max_samples:1;}
/* A render target: a color image of format sampled through the returned texture view, drawn with the samples asked for (at least 1) rounded
   down to 1, 2, 4 or 8 and to helix_max_target_samples; with depth, a depth image of the same samples for its passes. */
uint32_t helix_target(int w,int h,int format,int depth,int asked){
 if(w<=0||h<=0||w>16384||h>16384||!helix_can_render(format)||asked<1)return 0;
 const int most=helix_max_target_samples(format),n=asked<most?asked:most,samples=n>=8?8:n>=4?4:n>=2?2:1;
 /* The screen's depth format (sokol's environment default). Multisampled, its passes draw into an image of its samples, resolved at the
    pass's end into the one sampled. */
 const sg_environment_defaults defaults=sg_query_desc().environment.defaults;
 const sg_pixel_format pixels=format_of(format);
 sg_image color=sg_make_image(&(sg_image_desc){.usage={.color_attachment=samples==1,.resolve_attachment=samples>1},.width=w,.height=h,
  .pixel_format=pixels,.sample_count=1});
 sg_image drawn=samples>1?sg_make_image(&(sg_image_desc){.usage.color_attachment=true,.width=w,.height=h,.pixel_format=pixels,
  .sample_count=samples}):color;
 sg_image depth_image=depth?sg_make_image(&(sg_image_desc){.usage.depth_stencil_attachment=true,.width=w,.height=h,.pixel_format=defaults.depth_format,
  .sample_count=samples}):(sg_image){0};
 if(sg_query_image_state(color)!=SG_RESOURCESTATE_VALID||sg_query_image_state(drawn)!=SG_RESOURCESTATE_VALID||
  (depth&&sg_query_image_state(depth_image)!=SG_RESOURCESTATE_VALID)){
  sg_destroy_image(color);if(samples>1)sg_destroy_image(drawn);if(depth)sg_destroy_image(depth_image);return 0;
 }
 sg_view texture=sg_make_view(&(sg_view_desc){.texture.image=color});
 int slot=texture.id&0xffff;
 if(slot>=256){sg_destroy_view(texture);sg_destroy_image(color);if(samples>1)sg_destroy_image(drawn);if(depth)sg_destroy_image(depth_image);return 0;}
 memset(&targets[slot],0,sizeof targets[slot]);
 targets[slot].color=sg_make_view(&(sg_view_desc){.color_attachment.image=drawn});
 if(samples>1){targets[slot].resolve=sg_make_view(&(sg_view_desc){.resolve_attachment.image=color});targets[slot].samples_image=drawn;}
 if(depth){targets[slot].depth=sg_make_view(&(sg_view_desc){.depth_stencil_attachment.image=depth_image});targets[slot].depth_image=depth_image;}
 targets[slot].width=w;targets[slot].height=h;
 targets[slot].variant=(format==4?1:0)|(depth?0:2)|((power_of(samples)^power_of(screen_samples()))<<2);
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
 active=2;flipped=0;pass_variant=0;frame_width=frame_height=shadow_maps[slot].size;pass_texture=map;
 sg_begin_pass(&(sg_pass){.action={.depth={.load_action=SG_LOADACTION_CLEAR,.store_action=SG_STOREACTION_STORE,.clear_value=1.0f},
  .stencil={.load_action=SG_LOADACTION_DONTCARE}},.attachments={.depth_stencil=shadow_maps[slot].layers[layer]},.label="helix-shadow-map"});
 return 1;
}
static sg_color color_of(uint32_t color){return (sg_color){((color>>16)&255)/255.f,((color>>8)&255)/255.f,(color&255)/255.f,(color>>24)/255.f};}
/* A pass into target, before the screen's: cleared to red, green, blue, alpha as its texels store them and its depth, if it has one, to the
   farthest, or (clear 0) loading what it holds, cleared to transparent black the first time. Its samples and depth are stored either way
   (sokol's defaults discard a multisampled image's samples once resolved, and depth), so a later pass can load them. Drawn flipped where the
   backend's origin is the bottom left (GL). */
static int begin_target(uint32_t target,int clear,sg_color color){
 int slot=target&0xffff;
 if(active||slot>=256||!targets[slot].color.id||sg_query_view_state((sg_view){target})!=SG_RESOURCESTATE_VALID)return 0;
 if(!targets[slot].cleared)clear=1;
 targets[slot].cleared=1;
 active=2;flipped=!sg_query_features().origin_top_left;frame_width=targets[slot].width;frame_height=targets[slot].height;pass_texture=target;
 pass_variant=targets[slot].variant|(flipped?16:0);
 const sg_load_action load=clear?SG_LOADACTION_CLEAR:SG_LOADACTION_LOAD;
 sg_begin_pass(&(sg_pass){.action={.colors[0]={.load_action=load,.store_action=SG_STOREACTION_STORE,.clear_value=color},
  .depth={.load_action=load,.store_action=SG_STOREACTION_STORE,.clear_value=1.0f}},
  .attachments={.colors[0]=targets[slot].color,.resolves[0]=targets[slot].resolve,.depth_stencil=targets[slot].depth}});
 return 1;
}
int helix_begin_target(uint32_t target,float red,float green,float blue,float alpha){return begin_target(target,1,(sg_color){red,green,blue,alpha});}
int helix_resume_target(uint32_t target){return begin_target(target,0,(sg_color){0,0,0,0});}
int helix_end_target(void){if(active!=2)return 0;sg_end_pass();active=0;flipped=0;pass_texture=0;return 1;}
int helix_begin(int width,int height,uint32_t color){
 if(active||width<=0||height<=0)return 0;
 active=1;flipped=0;pass_variant=0;frame_width=screen_width=width;frame_height=screen_height=height;frame_ended=0;
 sg_begin_pass(&(sg_pass){.swapchain=swapchain(),.action={.colors[0]={.load_action=SG_LOADACTION_CLEAR,.clear_value=color_of(color)},.depth={.load_action=SG_LOADACTION_CLEAR,.clear_value=1.0f}}});
 return 1;
}
/* Reading back. The back buffer holds the ended frame until helix_present swaps it. */
/* What handle 0 (the frame just ended), an RGBA8 render target or an RGBA8 helix_texture texture reads back as: its width and height, 0
   when it can't be read now (or, a target of half floats, a cube, a data texture or a shadow map, at all). */
static sg_image_desc plain_desc(uint32_t texture){
 const int slot=texture&0xffff;
 if(slot>=256||targets[slot].color.id||data_textures[slot].image.id||shadow_maps[slot].image.id||sg_query_view_state((sg_view){texture})!=SG_RESOURCESTATE_VALID)
  return (sg_image_desc){0};
 const sg_image_desc desc=sg_query_image_desc(sg_query_view_image((sg_view){texture}));
 return desc.type==SG_IMAGETYPE_2D&&desc.pixel_format==SG_PIXELFORMAT_RGBA8?desc:(sg_image_desc){0};
}
static int readable(uint32_t target){int slot=target&0xffff;return slot<256&&targets[slot].color.id&&!(targets[slot].variant&1);}
int helix_read_width(uint32_t handle){
 if(!handle)return frame_ended?screen_width:0;
 return readable(handle)?targets[handle&0xffff].width:plain_desc(handle).width;
}
int helix_read_height(uint32_t handle){
 if(!handle)return frame_ended?screen_height:0;
 return readable(handle)?targets[handle&0xffff].height:plain_desc(handle).height;
}
/* Reads target into out (width * height * 4 bytes, RGBA8, rows top first) through GL, outside any pass: the back buffer for 0 (GL's rows
   come bottom first, so they're turned over), else the texture's (a target's color) top level attached to a framebuffer of the moment (its
   rows are already top first: textures are uploaded first row first, and target passes draw flipped). sokol caches GL state, so its cache is
   reset after. */
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
/* The sampler for a Sampling value: linear or nearest; the mipmaps not read (the level clamped to a quarter, which the nearest mipmap
   rounds to the top: sokol takes a max_lod of 0 for its default), the nearest, or the two
   nearest blended; each axis's wrap; and the anisotropy, which sokol takes only with every filter linear (GL clamps it to its own most). */
static sg_sampler sampler_of(int sampling){
 static const sg_wrap wraps[3]={SG_WRAP_CLAMP_TO_EDGE,SG_WRAP_REPEAT,SG_WRAP_MIRRORED_REPEAT};
 sampling&=SAMPLINGS-1;
 if(!samplers[sampling].id){
  const sg_filter filter=sampling&1?SG_FILTER_LINEAR:SG_FILTER_NEAREST;
  const int mipmaps=sampling>>5&3,anisotropy=1<<(sampling>>7&7);
  samplers[sampling]=sg_make_sampler(&(sg_sampler_desc){.min_filter=filter,.mag_filter=filter,.mipmap_filter=mipmaps==2?SG_FILTER_LINEAR:SG_FILTER_NEAREST,
   .max_lod=mipmaps?1000.0f:0.25f,.wrap_u=wraps[(sampling>>1&3)%3],.wrap_v=wraps[(sampling>>3&3)%3],
   .max_anisotropy=(uint32_t)((sampling&1)&&mipmaps==2&&anisotropy<=16?anisotropy:1)});
 }
 return samplers[sampling];
}
/* Binds textures (by slot, each of the program's set) into bindings, and checks uniforms: the blocks' bytes one after another by slot, each its
   declared size. A shadow map is read through the comparison sampler, a data texture (its latest write) through the nearest one. 0 for a
   mismatch. */
static uint32_t placeholder(char kind){
 static const unsigned char clear[24]={0};
 const int which=kind=='c'?1:kind=='s'?2:0;
 if(!placeholders[which])placeholders[which]=which==1?helix_cube_texture(1,clear,24,1,0):which==2?helix_shadow_map(1,1):helix_texture(1,1,clear,4,1,0);
 return placeholders[which];
}
static int bind_program(int shader,sg_bindings *bindings,const uint32_t *textures,const int *samplings,int texture_count,int uniform_bytes){
 int total=0;
 for(int i=0;i<MAX_BLOCKS;i++)total+=programs[shader].block_size[i];
 const int mask=programs[shader].texture_mask;
 if(total!=uniform_bytes||texture_count>MAX_TEXTURES)return 0;
 for(int i=0;i<MAX_TEXTURES;i++){
  if(!(mask&1<<i))continue;
  /* A slot the draw leaves unbound reads a placeholder of its kind. */
  const uint32_t texture=i<texture_count&&textures[i]?textures[i]:placeholder(programs[shader].kind[i]);
  /* Sampling what the pass draws into is undefined. */
  if(texture==pass_texture)return -1;
  const int sampling=i<texture_count?samplings[i]:0;
  if(sg_query_view_state((sg_view){texture})!=SG_RESOURCESTATE_VALID)return 0;
  const int vslot=texture&0xffff,data=vslot<256&&data_textures[vslot].image.id;
  /* A data texture not yet written this frame gets its contents first: sokol keeps them a frame. */
  if(data){if(!data_textures[vslot].written)write_data(vslot);data_textures[vslot].bound=1;}
  bindings->views[i]=current_view(texture);
  /* A slot the program never filters (it only fetches texels) and a data texture are sampled nearest, whatever the draw's sampling. */
  const int unfiltered=data||programs[shader].unfiltered_mask&1<<i;
  bindings->samplers[i]=vslot<256&&shadow_maps[vslot].image.id?comparison:sampler_of(unfiltered?0:sampling);
 }
 return 1;
}
/* Sets the program's uniforms after the pipeline and bindings, each member by its type from its std140 place in its block's bytes (the
   blocks one after another by index, a block both stages read at both, read from its vertex copy), repacked tight as GL takes them; the
   pipeline's flip uniform written into a copy of its block: a clip scale always, a view-projection's y row negated in a flipped pass. */
static void apply_blocks(int shader,int p,const void *uniforms){
 static unsigned char *flip_copy;static size_t flip_size;static float *packed;static size_t packed_size;
 const unsigned char *at[MAX_BLOCKS];const unsigned char *base=uniforms;int offset=0;
 for(int i=0;i<MAX_BLOCKS;i++){at[i]=base+offset;offset+=programs[shader].block_size[i];}
 const int flip=pipeline_info[p].flip,fs=pipeline_info[p].flip_slot,fo=pipeline_info[p].flip_offset,size=programs[shader].block_size[fs];
 if(flip&&size&&(flip==1||flipped)){
  if(flip_size<(size_t)size){unsigned char *g=realloc(flip_copy,(size_t)size);if(!g)return;flip_copy=g;flip_size=(size_t)size;}
  memcpy(flip_copy,at[fs],(size_t)size);
  if(flip==1&&fo+16<=size){const float scale[4]={1.0f,flipped?-1.0f:1.0f,1.0f,1.0f};memcpy(flip_copy+fo,scale,16);}
  else if(flip==2&&fo+64<=size)for(int i=1;i<16;i+=4){float v;memcpy(&v,flip_copy+fo+i*4,4);v=-v;memcpy(flip_copy+fo+i*4,&v,4);}
  at[fs]=flip_copy;
 }
 for(int k=0;k<programs[shader].setter_count;k++){
  const setter *u=&programs[shader].setters[k];
  const size_t words=(size_t)u->count*(size_t)u->comps*(size_t)u->cols;
  if(packed_size<words){float *g=realloc(packed,words*sizeof(float));if(!g)return;packed=g;packed_size=words;}
  const unsigned char *src=at[u->block]+u->offset;size_t w=0;
  for(int e=0;e<u->count;e++)for(int c=0;c<u->cols;c++){memcpy(packed+w,src+(size_t)e*(size_t)u->stride+(size_t)c*16,(size_t)u->comps*4);w+=(size_t)u->comps;}
  const GLfloat *f=packed;const GLint *iv=(const GLint *)packed;const GLuint *uv=(const GLuint *)packed;
  if(u->cols>1)switch(u->cols){case 2:glUniformMatrix2fv(u->loc,u->count,GL_FALSE,f);break;case 3:glUniformMatrix3fv(u->loc,u->count,GL_FALSE,f);break;
   default:glUniformMatrix4fv(u->loc,u->count,GL_FALSE,f);}
  else if(u->base=='f')switch(u->comps){case 1:glUniform1fv(u->loc,u->count,f);break;case 2:glUniform2fv(u->loc,u->count,f);break;
   case 3:glUniform3fv(u->loc,u->count,f);break;default:glUniform4fv(u->loc,u->count,f);}
  else if(u->base=='i')switch(u->comps){case 1:glUniform1iv(u->loc,u->count,iv);break;case 2:glUniform2iv(u->loc,u->count,iv);break;
   case 3:glUniform3iv(u->loc,u->count,iv);break;default:glUniform4iv(u->loc,u->count,iv);}
  else switch(u->comps){case 1:glUniform1uiv(u->loc,u->count,uv);break;case 2:glUniform2uiv(u->loc,u->count,uv);break;
   case 3:glUniform3uiv(u->loc,u->count,uv);break;default:glUniform4uiv(u->loc,u->count,uv);}
 }
}
/* The variant of the pipeline in slot that draws in the open pass, made the first time: depth alone has none (it draws only into shadow
   maps), lines and points none flipped (they have no faces). */
static sg_pipeline variant_of(int slot){
 const int v=pipeline_info[slot].depth_only?0:pipeline_info[slot].group<3?pass_variant&15:pass_variant;
 if(!variants[slot][v].id){
  sg_pipeline_desc pd=pipeline_descs[slot];
  if(v&1)pd.colors[0].pixel_format=SG_PIXELFORMAT_RGBA16F;
  if(v&2){pd.depth.pixel_format=SG_PIXELFORMAT_NONE;pd.depth.compare=SG_COMPAREFUNC_ALWAYS;pd.depth.write_enabled=false;}
  if(v&12)pd.sample_count=1<<(((v>>2)&3)^power_of(screen_samples()));
  /* Flipped: the front faces (and gl_FrontFacing) the other way round. */
  if(v&16)pd.face_winding=pd.face_winding==SG_FACEWINDING_CW?SG_FACEWINDING_CCW:SG_FACEWINDING_CW;
  variants[slot][v]=sg_make_pipeline(&pd);
 }
 return variants[slot][v];
}
/* A draw through pipeline p: count vertices from first (or indices, for an indexed pipeline, from first of `indices`) as instance_count
   instances from record first_instance of its instanced buffers; buffers[i] its buffer i (0 for one it doesn't read), the program's textures
   and samplings by slot, its uniform blocks' bytes one after another by index (a vertex block's slot, a fragment block's 4 + its slot, a
   block both stages read at both). -1, drawing nothing, for a texture that is the pass's own target; 0 for anything else invalid. */
int helix_draw(uint32_t p,const uint32_t *buffers,int buffer_count,uint32_t indices,int first,int count,int first_instance,int instance_count,
               const uint32_t *textures,const int *samplings,int texture_count,const void *uniforms,int uniform_bytes){
 const int pslot=p&0xffff;
 if(!active||pslot>=256||sg_query_pipeline_state((sg_pipeline){p})!=SG_RESOURCESTATE_VALID)return 0;
 const int shader=pipeline_info[pslot].shader&0xffff,group=pipeline_info[pslot].group,indexed=pipeline_info[pslot].indexed;
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
 {const int bound=bind_program(shader,&bindings,textures,samplings,texture_count,uniform_bytes);if(bound!=1)return bound;}
 const sg_pipeline pipeline=variant_of(pslot);
 if(sg_query_pipeline_state(pipeline)!=SG_RESOURCESTATE_VALID)return 0;
 sg_apply_pipeline(pipeline);
 sg_apply_bindings(&bindings);
 apply_blocks(shader,pslot,uniforms);
 /* What no buffer feeds reads its constant, or (0, 0, 0, 1): GL's generic attribute values, which sokol's state cache leaves alone. */
 for(int a=0;a<HELIX_MAX_VERTEX_ATTRIBUTES;a++)if(!(pipeline_info[pslot].fed&1<<a))glVertexAttrib4fv((GLuint)a,pipeline_info[pslot].constants[a]);
 for(int b=0;b<pipeline_info[pslot].buffer_count;b++)if(pipeline_info[pslot].read[b])bound[buffers[b]&0xffff]=1;
 sg_draw(first,count,instance_count);return 1;
}
void helix_end(void){
 if(active!=1)abort();sg_end_pass();sg_commit();active=0;frame_ended=1;
 /* Stream buffers start each frame empty and unrenamed; a static one keeps its size. */
 for(int i=0;i<256;i++){if(stream_buffers[i]){used[i]=0;renamed[i]=bound[i]=0;}data_textures[i].written=data_textures[i].bound=data_textures[i].renamed=0;}
}
/* The frame shown: the window swaps it (surface.h), waiting for the display. */
void helix_present(void){helix_surface_present();}
/* Disposes a pipeline, its variants and its record. */
static void dispose_pipeline(uint32_t id){
 const int slot=id&0xffff;
 sg_destroy_pipeline((sg_pipeline){id});
 if(slot<256){
  for(int v=1;v<VARIANTS;v++)if(variants[slot][v].id)sg_destroy_pipeline(variants[slot][v]);
  memset(variants[slot],0,sizeof variants[slot]);memset(&pipeline_info[slot],0,sizeof pipeline_info[slot]);
 }
}
int helix_dispose_resource(int kind,uint32_t id){
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
   sg_destroy_view(targets[slot].color);if(targets[slot].depth.id){sg_destroy_view(targets[slot].depth);sg_destroy_image(targets[slot].depth_image);}
   if(targets[slot].samples_image.id){sg_destroy_view(targets[slot].resolve);sg_destroy_image(targets[slot].samples_image);}
   memset(&targets[slot],0,sizeof targets[slot]);
  }
  return 1;
 }
 if(kind==3&&sg_query_shader_state((sg_shader){id})==SG_RESOURCESTATE_VALID){
  /* Its pipelines (and their twins) go first. */
  for(int i=0;i<256;i++)if(pipeline_info[i].id&&pipeline_info[i].shader==id)dispose_pipeline(pipeline_info[i].id);
  sg_destroy_shader((sg_shader){id});
  if(slot<256){free(programs[slot].setters);programs[slot].setters=NULL;programs[slot].setter_count=0;}
  return 1;
 }
 if(kind==2&&sg_query_pipeline_state((sg_pipeline){id})==SG_RESOURCESTATE_VALID){dispose_pipeline(id);return 1;}
 return 0;
}
