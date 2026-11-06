/* The graphics calls of shared/graphics.h on SDL_GPU (Vulkan, Direct3D 12 or Metal, whichever SDL picks for the system), presenting to the
   SDL3 host's window (surface.h).

   SDL_GPU differs from GL in ways this file absorbs:
   - Copies can't happen inside a render pass, and a program writes stream buffers and data textures between draws. So a pass's draws are
     recorded, its writes staged; when the pass ends, one copy pass uploads what was staged and the render pass replays the draws.
   - A stream buffer's every write is a new range of one frame-wide vertex buffer (the arena), so a draw keeps the range it was given; a
     data texture written after a draw read it this frame goes to a spare, as under sokol.
   - Its origin is the top left, as every texture's rows are stored: the screen and render targets are drawn unflipped, and shadow maps,
     whose lookups expect their rows bottom first, are drawn flipped (the pipeline's flip uniform, and pipelines' twins with the front faces
     the other way round). A clip scale is written (1, 1, 1, 1) in every other pass. Clip depth is 0..1, which the shaders' translation already gives (tools/gpu_shaders.py).
   - The swapchain can't be read back: frames are drawn into a texture of the screen's size, copied to the swapchain at the frame's end.
   - Direct3D 12 takes the HLSL as DXBC, compiled when the program is made by the system's d3dcompiler_47.dll (as sokol_gfx does for
     Direct3D 11); Metal compiles the MSL itself. */
#include "graphics.h"
#include "graphics_sdl3gpu.h"
#include "surface.h"
#include <SDL3/SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#define COBJMACROS
#include <windows.h>
#include <d3dcompiler.h>
#endif

#define SLOTS 2048
#define MAX_BLOCKS 4
/* A draw's uniforms by stage and slot: the vertex stage's 0 to 3, the fragment stage's 4 to 7. */
#define MAX_BLOCK_INDICES 8
#define MAX_TEXTURES 12
#define MAX_RENAMES 8
#define MAX_SHADOW_LAYERS 24

static SDL_GPUDevice *device;
static SDL_Window *window;
static SDL_GPUShaderFormat shader_format;
/* The depth format (a sampled one, for shadow maps too), the screen's and targets' samples, and the most the device can do. */
static SDL_GPUTextureFormat depth_format;
static int window_samples=1,max_samples=1;

/* A handle is its table slot plus one in the low 16 bits and the slot's generation above, so a disposed handle isn't taken for its slot's
   next resource. */
static uint32_t handle_of(int slot,uint32_t generation){return (generation<<16)|(uint32_t)(slot+1);}
static int slot_of(uint32_t handle){return (int)(handle&0xffff)-1;}

/* Buffers: static ones (a GPU buffer of their own; index buffers of uint32) and stream ones (createBuffer's), whose writes are ranges of the
   arena: the latest range's buffer, offset and bytes. */
static struct{uint32_t generation;int live,stream,index,appended,capacity,used;SDL_GPUBuffer *buffer;Uint32 offset;}buffers[SLOTS];

/* Programs: their shaders, their attribute slots, each block by its index in a draw's uniforms (its size, 0 for none, and whether it is the
   fragment copy of a block both stages read, pushed from the vertex copy), and where each texture slot lands in SDL_GPU's numbering (per
   stage, from 0 by slot). A block is pushed at its slot in its stage. */
static struct{uint32_t generation;int live;SDL_GPUShader *vertex,*fragment;int attributes,block_size[MAX_BLOCK_INDICES],block_both[MAX_BLOCK_INDICES];
 int texture_mask,unfiltered_mask;char texture_kind[MAX_TEXTURES];int texture_stage[MAX_TEXTURES],texture_index[MAX_TEXTURES],vertex_samplers,fragment_samplers;}programs[SLOTS];

/* Pipelines: SDL's, a twin with the front faces the other way round for flipped passes (depth alone, into shadow maps), and what a draw
   through one checks and binds. An SDL_GPU pipeline is made for one kind of pass (its color format, depth and samples): its variants for
   the others, made from its description (kept, with what it points to) the first time a draw needs one. A variant is the pass's kind: bit 0
   half floats, bit 1 no depth, bits 2-3 the samples' power of two exclusive-or the screen's (0: the screen's samples); variant 0 (the
   screen's) is the pipeline itself. */
#define VARIANTS 16
/* The attributes no buffer feeds read constants (theirs, or (0, 0, 0, 1)) from a buffer of the pipeline's own stepped per instance, as
   SDL_GPU steps an instance buffer one record an instance and no slower: its record (constants, 16 bytes an attribute) repeated
   constant_count times, made again larger when a draw has more instances. */
static struct{uint32_t generation;int live;SDL_GPUGraphicsPipeline *pipeline,*flipped,*variants[VARIANTS];uint32_t program;int buffer_count,stride[HELIX_MAX_VERTEX_BUFFERS],
 instanced[HELIX_MAX_VERTEX_BUFFERS],read[HELIX_MAX_VERTEX_BUFFERS],indexed,group,flip,flip_slot,flip_offset,depth_only;SDL_GPUGraphicsPipelineCreateInfo info;
 SDL_GPUVertexBufferDescription described[HELIX_MAX_VERTEX_BUFFERS+1];SDL_GPUVertexAttribute attrs[HELIX_MAX_VERTEX_ATTRIBUTES];SDL_GPUColorTargetDescription color;
 float constants[HELIX_MAX_VERTEX_ATTRIBUTES*4];int constant_attributes,constant_count;SDL_GPUBuffer *constant_buffer;}pipelines[SLOTS];

/* Textures by kind: sampled (a 2D image or a cube), a data texture (RGBA32F, its versions for writes after a read in a frame), a render
   target (a color texture sampled, drawn through a multisampled one when it has more than one sample, its depth or none, the pipelines'
   variant drawing into it), or a shadow map (a depth array). */
enum{PLAIN,DATA,TARGET,SHADOW};
static struct{uint32_t generation;int live,kind,width,height,layers,variant,format,cleared,sample_count;SDL_GPUTexture *texture,*samples,*depth;
 SDL_GPUTexture *versions[MAX_RENAMES];int current,bound[MAX_RENAMES];}textures[SLOTS];

/* Samplers by Sampling value (helix.platform.Sampling: bit 0 linear, bits 1-2 wrap u, bits 3-4 wrap v, bits 5-6 the mipmap filter, bits
   7-9 the anisotropy's power of two), made when first used, and the comparison sampler shadow maps are read through. */
#define SAMPLINGS 1024
static SDL_GPUSampler *samplers[SAMPLINGS],*comparison;

/* The frame: its command buffer (acquired by its first pass), the texture the screen is drawn into (with its multisampled and depth
   textures), the screen's size this frame, and whether the frame has ended (it can be read back). */
static SDL_GPUCommandBuffer *command;
static SDL_GPUTexture *screen,*screen_samples,*screen_depth;
static int screen_width,screen_height,frame_ended;

/* The arena: a vertex buffer whose ranges are stream buffers' writes this frame; replaced by a larger one when full (the old one released
   at the frame's end). cycled: whether its first upload this frame has cycled it, so last frame's ranges stay with the GPU still drawing them. */
static SDL_GPUBuffer *arena,*retired[16];static int arena_size,arena_used,arena_cycled,retired_count;

/* The pass being recorded: 0 none, 1 the screen's, 2 a target's or shadow map's; whether it's drawn flipped; the pipelines' variant it
   draws with; its size; its targets. */
static int active,flipped,pass_variant,pass_width,pass_height;
/* The texture the open target or shadow pass draws into, which its draws may not sample; 0 for none. */
static uint32_t pass_texture;
static SDL_GPUColorTargetInfo pass_color;static SDL_GPUDepthStencilTargetInfo pass_depth;static int pass_has_color,pass_has_depth;

/* What the pass stages: bytes to upload (staging), each to a buffer range or a texture region; and its commands, replayed in order. */
static unsigned char *staging;static size_t staging_used,staging_size;
/* cycle: a data texture's whole rewrite, cycled so a frame still on the GPU keeps what it read (a new texture's levels mustn't be: each
   cycle would drop the levels before it). */
typedef struct{size_t at;Uint32 bytes;SDL_GPUBuffer *buffer;Uint32 offset;SDL_GPUTexture *texture;Uint32 level,layer,x,y,width,height;bool cycle;}Upload;
static Upload *uploads;static int upload_count,upload_size;
enum{DRAW,VIEWPORT,SCISSOR};
typedef struct{int kind;SDL_GPUGraphicsPipeline *pipeline;SDL_GPUBufferBinding vertex[HELIX_MAX_VERTEX_BUFFERS+1];int vertex_count;SDL_GPUBuffer *index;
 SDL_GPUTextureSamplerBinding vertex_samplers[MAX_TEXTURES],fragment_samplers[MAX_TEXTURES];int vertex_sampler_count,fragment_sampler_count;
 size_t uniform_at[MAX_BLOCK_INDICES];int uniform_size[MAX_BLOCK_INDICES],uniform_stage[MAX_BLOCK_INDICES],uniform_index[MAX_BLOCK_INDICES],uniform_count;
 int first,count,instances,indexed;float x,y,w,h;}Command;
static Command *commands;static int command_count,command_size;
static unsigned char *uniform_bytes;static size_t uniform_used,uniform_size;

/* Grows *buffer (of *size bytes) to hold at least need, doubling; 0 when out of memory. */
static int grow(void **buffer,size_t *size,size_t need,size_t unit){
 if(need<=*size)return 1;
 size_t n=*size?*size:64;while(n<need)n*=2;
 void *p=realloc(*buffer,n*unit);if(!p)return 0;*buffer=p;*size=n;return 1;
}
/* Stages bytes for the pass's copy: where they are in the staging bytes, or (size_t)-1. */
static size_t stage_bytes(const void *data,size_t bytes){
 const size_t at=(staging_used+15)&~(size_t)15;
 if(!grow((void**)&staging,&staging_size,at+bytes,1))return (size_t)-1;
 memcpy(staging+at,data,bytes);staging_used=at+bytes;return at;
}
static Upload *add_upload(void){
 size_t size=(size_t)upload_size;
 if(!grow((void**)&uploads,&size,(size_t)upload_count+1,sizeof(Upload)))return NULL;
 upload_size=(int)size;Upload *u=&uploads[upload_count++];memset(u,0,sizeof *u);return u;
}
static Command *add_command(int kind){
 size_t size=(size_t)command_size;
 if(!grow((void**)&commands,&size,(size_t)command_count+1,sizeof(Command)))return NULL;
 command_size=(int)size;Command *c=&commands[command_count++];memset(c,0,sizeof *c);c->kind=kind;return c;
}

/* The transfer buffer uploads go through, kept for the device's life and grown when an upload needs more; each use maps it cycled, so SDL
   gives a free one of its own while the GPU still reads the last (making a buffer every pass cost Direct3D 12 most). */
static SDL_GPUTransferBuffer *transfer;static Uint32 transfer_size;
/* Copies staged uploads into their destinations through the transfer buffer and one copy pass, on cmd. 0 when SDL refused. */
static int upload_staged(SDL_GPUCommandBuffer *cmd,const unsigned char *bytes,size_t total,const Upload *list,int count){
 if(!count)return 1;
 if(total>transfer_size){
  Uint32 size=transfer_size?transfer_size:1<<20;while(size<total)size*=2;
  SDL_GPUTransferBuffer *bigger=SDL_CreateGPUTransferBuffer(device,&(SDL_GPUTransferBufferCreateInfo){.usage=SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,.size=size});
  if(!bigger)return 0;
  /* Released once the GPU has used it. */
  if(transfer)SDL_ReleaseGPUTransferBuffer(device,transfer);
  transfer=bigger;transfer_size=size;
 }
 void *mapped=SDL_MapGPUTransferBuffer(device,transfer,true);
 if(!mapped)return 0;
 memcpy(mapped,bytes,total);SDL_UnmapGPUTransferBuffer(device,transfer);
 SDL_GPUCopyPass *copy=SDL_BeginGPUCopyPass(cmd);
 for(int i=0;i<count;i++){
  const Upload *u=&list[i];
  if(u->buffer){
   /* The arena cycles at its first upload of a frame (see arena_cycled); nothing else here is written while the GPU may read it. */
   const bool cycle=u->buffer==arena&&!arena_cycled;if(cycle)arena_cycled=1;
   SDL_UploadToGPUBuffer(copy,&(SDL_GPUTransferBufferLocation){transfer,(Uint32)u->at},&(SDL_GPUBufferRegion){u->buffer,u->offset,u->bytes},cycle);
  }else SDL_UploadToGPUTexture(copy,&(SDL_GPUTextureTransferInfo){.transfer_buffer=transfer,.offset=(Uint32)u->at},
    &(SDL_GPUTextureRegion){.texture=u->texture,.mip_level=u->level,.layer=u->layer,.x=u->x,.y=u->y,.w=u->width,.h=u->height,.d=1},u->cycle);
 }
 SDL_EndGPUCopyPass(copy);
 return 1;
}
/* Uploads now, through a command buffer of its own submitted at once (before the frame's, which is submitted at its end): a static
   buffer's or a texture's contents. */
static int upload_now(const unsigned char *bytes,size_t total,const Upload *list,int count){
 SDL_GPUCommandBuffer *cmd=SDL_AcquireGPUCommandBuffer(device);
 if(!cmd)return 0;
 if(!upload_staged(cmd,bytes,total,list,count)){SDL_CancelGPUCommandBuffer(cmd);return 0;}
 return SDL_SubmitGPUCommandBuffer(cmd);
}

static SDL_GPUSampleCount sample_count_of(int samples){return samples>=8?SDL_GPU_SAMPLECOUNT_8:samples>=4?SDL_GPU_SAMPLECOUNT_4:samples>=2?SDL_GPU_SAMPLECOUNT_2:SDL_GPU_SAMPLECOUNT_1;}

#if defined(_WIN32)
/* Direct3D 12's programs as DXBC (shader model 5.1), compiled from the HLSL by the system's d3dcompiler_47.dll, loaded once. */
typedef HRESULT (WINAPI *Compile)(LPCVOID,SIZE_T,LPCSTR,const D3D_SHADER_MACRO*,ID3DInclude*,LPCSTR,LPCSTR,UINT,UINT,ID3DBlob**,ID3DBlob**);
static Compile d3d_compile;
static ID3DBlob *dxbc(const char *hlsl,const char *target){
 if(!d3d_compile){HMODULE dll=LoadLibraryA("d3dcompiler_47.dll");if(dll)d3d_compile=(Compile)(void*)GetProcAddress(dll,"D3DCompile");}
 if(!d3d_compile){fprintf(stderr,"HeliX SDL_GPU: d3dcompiler_47.dll can't be loaded\n");return NULL;}
 ID3DBlob *code=NULL,*errors=NULL;
 HRESULT result=d3d_compile(hlsl,strlen(hlsl),NULL,NULL,NULL,"main",target,D3DCOMPILE_OPTIMIZATION_LEVEL3,0,&code,&errors);
 /* Its messages only when it fails: its warnings (loops unrolled, say) are about code SPIRV-Cross wrote, nothing to act on. */
 if(FAILED(result)&&errors)fprintf(stderr,"HeliX SDL_GPU: %s\n",(const char*)ID3D10Blob_GetBufferPointer(errors));
 if(errors)ID3D10Blob_Release(errors);
 if(FAILED(result)){if(code)ID3D10Blob_Release(code);return NULL;}
 return code;
}
#endif

int helix_sdl3gpu_setup(void){
 window=(SDL_Window*)helix_surface_window();
 device=SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV|SDL_GPU_SHADERFORMAT_MSL|SDL_GPU_SHADERFORMAT_DXBC,SDL_GetHintBoolean("HELIX_GPU_DEBUG",false),NULL);
 if(!device){fprintf(stderr,"HeliX SDL_GPU: no device: %s\n",SDL_GetError());return 0;}
 if(!window||!SDL_ClaimWindowForGPUDevice(device,window)){fprintf(stderr,"HeliX SDL_GPU: the window can't be claimed: %s\n",SDL_GetError());
  SDL_DestroyGPUDevice(device);device=NULL;return 0;}
 /* Without vsync, presenting doesn't wait: IMMEDIATE where the window has it, else MAILBOX (waits for nothing, but doesn't tear), else
    SDL's VSYNC, which every window has. */
 if(!helix_surface_vsync()){
  const SDL_GPUPresentMode mode=SDL_WindowSupportsGPUPresentMode(device,window,SDL_GPU_PRESENTMODE_IMMEDIATE)?SDL_GPU_PRESENTMODE_IMMEDIATE:
   SDL_WindowSupportsGPUPresentMode(device,window,SDL_GPU_PRESENTMODE_MAILBOX)?SDL_GPU_PRESENTMODE_MAILBOX:SDL_GPU_PRESENTMODE_VSYNC;
  SDL_SetGPUSwapchainParameters(device,window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR,mode);
 }
 const SDL_GPUShaderFormat formats=SDL_GetGPUShaderFormats(device);
 shader_format=formats&SDL_GPU_SHADERFORMAT_SPIRV?SDL_GPU_SHADERFORMAT_SPIRV:formats&SDL_GPU_SHADERFORMAT_MSL?SDL_GPU_SHADERFORMAT_MSL:SDL_GPU_SHADERFORMAT_DXBC;
 /* Depth: 32-bit float where it can be drawn into and sampled, else 24-bit; both are depth alone. */
 const SDL_GPUTextureUsageFlags depth_use=SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER;
 depth_format=SDL_GPUTextureSupportsFormat(device,SDL_GPU_TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTURETYPE_2D_ARRAY,depth_use)?SDL_GPU_TEXTUREFORMAT_D32_FLOAT:SDL_GPU_TEXTUREFORMAT_D24_UNORM;
 /* Samples: the most both color and depth can take, at most 8; the screen's what the window asked for, or fewer. */
 max_samples=1;
 for(int n=8;n>=2;n/=2)if(SDL_GPUTextureSupportsSampleCount(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,sample_count_of(n))&&
  SDL_GPUTextureSupportsSampleCount(device,depth_format,sample_count_of(n))){max_samples=n;break;}
 /* Which backend and GPU run, as SDL may choose any (a machine may have two GPUs): said once, for logs and checks (the autopilot repeats it). */
 const char *gpu=SDL_GetStringProperty(SDL_GetGPUDeviceProperties(device),SDL_PROP_GPU_DEVICE_NAME_STRING,"an unnamed GPU");
 fprintf(stderr,"HeliX SDL_GPU: %s on %s\n",SDL_GetGPUDeviceDriver(device),gpu);
 const int asked=helix_surface_samples();
 window_samples=1;for(int n=max_samples;n>=2;n/=2)if(n<=asked){window_samples=n;break;}
 return 1;
}
int helix_sdl3gpu_shader_format(void){return shader_format==SDL_GPU_SHADERFORMAT_SPIRV?0:shader_format==SDL_GPU_SHADERFORMAT_MSL?1:2;}
int helix_msaa_samples(void){return window_samples;}
int helix_max_msaa_samples(void){return max_samples;}
/* The device as SDL names it (IGraphics.device): 0 the API, 1 the driver's name, 2 the GPU, 3 the driver's version, 4 the shader format; "" for
   one SDL doesn't give. */
const char *helix_device_info(int field){
 if(!device)return "";
 const char *driver=SDL_GetGPUDeviceDriver(device);
 if(field==0)return !driver?"":strcmp(driver,"vulkan")==0?"Vulkan":strcmp(driver,"metal")==0?"Metal":strcmp(driver,"direct3d12")==0?"Direct3D 12":driver;
 if(field==4)return shader_format==SDL_GPU_SHADERFORMAT_SPIRV?"SPIR-V":shader_format==SDL_GPU_SHADERFORMAT_MSL?"MSL":"DXBC";
 const SDL_PropertiesID p=SDL_GetGPUDeviceProperties(device);
 if(field==1)return SDL_GetStringProperty(p,SDL_PROP_GPU_DEVICE_DRIVER_NAME_STRING,"");
 if(field==2)return SDL_GetStringProperty(p,SDL_PROP_GPU_DEVICE_NAME_STRING,"");
 if(field==3){const char *info=SDL_GetStringProperty(p,SDL_PROP_GPU_DEVICE_DRIVER_INFO_STRING,NULL);return info?info:SDL_GetStringProperty(p,SDL_PROP_GPU_DEVICE_DRIVER_VERSION_STRING,"");}
 return "";
}
/* The power of two of a sample count (1, 2, 4 or 8). */
static int power_of(int samples){return samples>=8?3:samples>=4?2:samples>=2?1:0;}

/* helix.platform.TextureFormat's values as SDL_GPU's: RGBA8, BC7, ASTC 4x4, ETC2 RGBA8 (none: SDL_GPU has no ETC2), RGBA16F. */
static SDL_GPUTextureFormat format_of(int format){
 switch(format){case 0:return SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;case 1:return SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM;
  case 2:return SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM;case 4:return SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT;default:return SDL_GPU_TEXTUREFORMAT_INVALID;}
}
/* Whether render targets of format (helix.platform.TextureFormat's) can be drawn into and sampled: RGBA8, and RGBA16F where the device has it
   (SDL_GPU blends and filters every such format). */
int helix_can_render(int format){
 if(format!=0&&format!=4)return 0;
 return SDL_GPUTextureSupportsFormat(device,format_of(format),SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER);
}
/* Whether a format can be sampled (filtered, for half floats: SDL_GPU filters every sampled format it has). */
int helix_can_sample(int format){
 const SDL_GPUTextureFormat f=format_of(format);
 return f!=SDL_GPU_TEXTUREFORMAT_INVALID&&SDL_GPUTextureSupportsFormat(device,f,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_SAMPLER)&&
  SDL_GPUTextureSupportsFormat(device,f,SDL_GPU_TEXTURETYPE_CUBE,SDL_GPU_TEXTUREUSAGE_SAMPLER);
}
/* The bytes of a w x h level of format: 4 a texel, 8 for half floats, or 4x4 blocks of 16. */
static size_t level_bytes(int format,int w,int h){return format==0?(size_t)w*(size_t)h*4:format==4?(size_t)w*(size_t)h*8:(size_t)((w+3)/4)*(size_t)((h+3)/4)*16;}

static int free_texture_slot(void){for(int i=0;i<SLOTS;i++)if(!textures[i].live)return i;return -1;}
static uint32_t take_texture(int slot,int kind,int w,int h){
 textures[slot].live=1;textures[slot].kind=kind;textures[slot].width=w;textures[slot].height=h;textures[slot].generation++;
 return handle_of(slot,textures[slot].generation);
}
/* A sampled texture: a 2D image (faces 1) or a cube (faces 6), levels mip levels of format packed one after another (a cube's faces +X, -X,
   +Y, -Y, +Z, -Z within each level). */
static uint32_t sampled(int w,int h,int faces,const void *data,int bytes,int levels,int format){
 const int slot=free_texture_slot();
 if(slot<0||w<=0||h<=0||w>16384||h>16384||!data||levels<1||levels>16||!helix_can_sample(format))return 0;
 size_t total=0;int lw=w,lh=h;
 for(int i=0;i<levels;i++){total+=(size_t)faces*level_bytes(format,lw,lh);lw=lw>1?lw/2:1;lh=lh>1?lh/2:1;}
 if(total!=(size_t)bytes)return 0;
 SDL_GPUTexture *texture=SDL_CreateGPUTexture(device,&(SDL_GPUTextureCreateInfo){.type=faces==6?SDL_GPU_TEXTURETYPE_CUBE:SDL_GPU_TEXTURETYPE_2D,
  .format=format_of(format),.usage=SDL_GPU_TEXTUREUSAGE_SAMPLER,.width=(Uint32)w,.height=(Uint32)h,.layer_count_or_depth=(Uint32)faces,.num_levels=(Uint32)levels});
 if(!texture)return 0;
 Upload list[16*6];int count=0;size_t at=0;lw=w;lh=h;
 for(int i=0;i<levels;i++){
  const size_t size=level_bytes(format,lw,lh);
  for(int f=0;f<faces;f++){list[count++]=(Upload){.at=at,.bytes=(Uint32)size,.texture=texture,.level=(Uint32)i,.layer=(Uint32)f,.width=(Uint32)lw,.height=(Uint32)lh};at+=size;}
  lw=lw>1?lw/2:1;lh=lh>1?lh/2:1;
 }
 if(!upload_now(data,total,list,count)){SDL_ReleaseGPUTexture(device,texture);return 0;}
 textures[slot].texture=texture;textures[slot].layers=faces;textures[slot].format=format;
 return take_texture(slot,PLAIN,w,h);
}
uint32_t helix_texture(int w,int h,const void *data,int bytes,int levels,int format){return sampled(w,h,1,data,bytes,levels,format);}
uint32_t helix_cube_texture(int size,const void *data,int bytes,int levels,int format){return sampled(size,size,6,data,bytes,levels,format);}

static SDL_GPUTexture *data_version(int w,int h){
 return SDL_CreateGPUTexture(device,&(SDL_GPUTextureCreateInfo){.type=SDL_GPU_TEXTURETYPE_2D,.format=SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT,
  .usage=SDL_GPU_TEXTUREUSAGE_SAMPLER,.width=(Uint32)w,.height=(Uint32)h,.layer_count_or_depth=1,.num_levels=1});
}
uint32_t helix_data_texture(int w,int h){
 const int slot=free_texture_slot();
 if(slot<0||w<=0||h<=0||w>16384||h>16384)return 0;
 SDL_GPUTexture *texture=data_version(w,h);
 if(!texture)return 0;
 memset(textures[slot].versions,0,sizeof textures[slot].versions);memset(textures[slot].bound,0,sizeof textures[slot].bound);
 textures[slot].versions[0]=textures[slot].texture=texture;textures[slot].current=0;
 return take_texture(slot,DATA,w,h);
}
static int texture_live(uint32_t handle){const int s=slot_of(handle);return s>=0&&s<SLOTS&&textures[s].live&&(handle>>16)==textures[s].generation;}
/* Rewrites a data texture whole. Its current version, unless a draw read it this frame: then the next it hasn't, made when first needed.
   Staged for the pass's copy, or uploaded at once outside a pass. */
static int update_data(int slot,const void *data,int bytes){
 const size_t size=(size_t)textures[slot].width*(size_t)textures[slot].height*16;
 if((size_t)bytes<size)return 0;
 int v=textures[slot].current;
 if(textures[slot].bound[v]){
  for(v=0;v<MAX_RENAMES&&textures[slot].bound[v];v++){}
  if(v==MAX_RENAMES)return 0;
  if(!textures[slot].versions[v]&&!(textures[slot].versions[v]=data_version(textures[slot].width,textures[slot].height)))return 0;
  textures[slot].current=v;
 }
 const Upload u={.bytes=(Uint32)size,.texture=textures[slot].versions[v],.width=(Uint32)textures[slot].width,.height=(Uint32)textures[slot].height,.cycle=true};
 if(!active)return upload_now(data,size,&u,1);
 const size_t at=stage_bytes(data,size);Upload *staged=at==(size_t)-1?NULL:add_upload();
 if(!staged)return 0;
 *staged=u;staged->at=at;return 1;
}
/* Replaces a rectangle of a texture's texels: a data texture's whole (x and y 0, its size), inside a pass or outside; a 2D texture's top
   level, RGBA8 or half floats, outside a pass, not cycled (the texels outside the rectangle are kept): a copy in the frame's command buffer
   when a frame is being recorded, after its passes so far, else uploaded at once. 0 for anything else. */
int helix_update_texture(uint32_t handle,int x,int y,int w,int h,const void *data,int bytes){
 if(!texture_live(handle)||!data||x<0||y<0||w<=0||h<=0)return 0;
 const int slot=slot_of(handle);
 if(textures[slot].kind==DATA)return x||y||w!=textures[slot].width||h!=textures[slot].height?0:update_data(slot,data,bytes);
 const int format=textures[slot].format;
 if(active||textures[slot].kind!=PLAIN||textures[slot].layers!=1||(format!=0&&format!=4)||x+w>textures[slot].width||y+h>textures[slot].height)return 0;
 const size_t size=level_bytes(format,w,h);
 if((size_t)bytes<size)return 0;
 const Upload u={.bytes=(Uint32)size,.texture=textures[slot].texture,.x=(Uint32)x,.y=(Uint32)y,.width=(Uint32)w,.height=(Uint32)h};
 return command?upload_staged(command,data,size,&u,1):upload_now(data,size,&u,1);
}

static int free_buffer_slot(void){for(int i=0;i<SLOTS;i++)if(!buffers[i].live)return i;return -1;}
static int buffer_live(uint32_t handle){const int s=slot_of(handle);return s>=0&&s<SLOTS&&buffers[s].live&&(handle>>16)==buffers[s].generation;}
static uint32_t take_buffer(int slot){buffers[slot].live=1;buffers[slot].generation++;return handle_of(slot,buffers[slot].generation);}
/* A stream buffer: up to capacity bytes a write, each write a new range of the arena. */
uint32_t helix_buffer(int capacity){
 const int slot=free_buffer_slot();
 if(slot<0||capacity<=0||capacity%4)return 0;
 buffers[slot].stream=1;buffers[slot].index=0;buffers[slot].appended=0;buffers[slot].capacity=capacity;buffers[slot].used=0;buffers[slot].buffer=NULL;buffers[slot].offset=0;
 return take_buffer(slot);
}
/* An immutable vertex buffer, or an index buffer of uint32 indices, holding the bytes of data. */
uint32_t helix_static_buffer(const void *data,int bytes,int index){
 const int slot=free_buffer_slot();
 if(slot<0||!data||bytes<=0||bytes%4)return 0;
 SDL_GPUBuffer *buffer=SDL_CreateGPUBuffer(device,&(SDL_GPUBufferCreateInfo){.usage=index?SDL_GPU_BUFFERUSAGE_INDEX:SDL_GPU_BUFFERUSAGE_VERTEX,.size=(Uint32)bytes});
 if(!buffer)return 0;
 const Upload u={.bytes=(Uint32)bytes,.buffer=buffer};
 if(!upload_now(data,(size_t)bytes,&u,1)){SDL_ReleaseGPUBuffer(device,buffer);return 0;}
 buffers[slot].stream=0;buffers[slot].index=index!=0;buffers[slot].capacity=buffers[slot].used=bytes;buffers[slot].buffer=buffer;buffers[slot].offset=0;
 return take_buffer(slot);
}
/* Sets aside bytes of the arena for a stream buffer's ranges, growing it when full: the offset, or -1. */
static int arena_reserve(int bytes){
 const int at=(arena_used+15)&~15;
 if(arena&&at+bytes<=arena_size){arena_used=at+bytes;return at;}
 /* Full: a larger arena from here on; the old one is released at the frame's end, after the draws reading it. */
 int size=arena_size?arena_size:1<<20;while(size<bytes*2||size<arena_size*2)size*=2;
 SDL_GPUBuffer *bigger=SDL_CreateGPUBuffer(device,&(SDL_GPUBufferCreateInfo){.usage=SDL_GPU_BUFFERUSAGE_VERTEX,.size=(Uint32)size});
 if(!bigger||(arena&&retired_count==16)){if(bigger)SDL_ReleaseGPUBuffer(device,bigger);return -1;}
 if(arena)retired[retired_count++]=arena;
 arena=bigger;arena_size=size;arena_used=bytes;arena_cycled=1;
 return 0;
}
/* Writes a stream buffer, inside a pass: its bytes staged for the pass's copy into a new range of the arena, which its later draws read. */
int helix_update(uint32_t handle,const void *data,int bytes){
 if(!active||!data||bytes<0||bytes%4||!buffer_live(handle))return 0;
 const int slot=slot_of(handle);
 if(!buffers[slot].stream||bytes>buffers[slot].capacity||buffers[slot].appended)return 0;
 buffers[slot].used=bytes;
 if(!bytes)return 1;
 const int at=arena_reserve(bytes);
 if(at<0)return 0;
 const size_t staged=stage_bytes(data,(size_t)bytes);Upload *u=staged==(size_t)-1?NULL:add_upload();
 if(!u)return 0;
 u->at=staged;u->bytes=(Uint32)bytes;u->buffer=arena;u->offset=(Uint32)at;
 buffers[slot].buffer=arena;buffers[slot].offset=(Uint32)at;
 return 1;
}
/* Adds bytes after a stream buffer's used ones, in a pass: the offset they landed at, -1 for anything invalid. Its first append of a frame
   sets aside the buffer's whole capacity of the arena, so its ranges are one run the draws read from offsets. */
int helix_append(uint32_t handle,const void *data,int bytes){
 if(!active||!data||bytes<=0||bytes%4||!buffer_live(handle))return -1;
 const int slot=slot_of(handle);
 if(!buffers[slot].stream||buffers[slot].used+bytes>buffers[slot].capacity)return -1;
 if(!buffers[slot].appended){
  if(buffers[slot].used)return -1;
  const int base=arena_reserve(buffers[slot].capacity);
  if(base<0)return -1;
  buffers[slot].buffer=arena;buffers[slot].offset=(Uint32)base;buffers[slot].appended=1;
 }
 const size_t staged=stage_bytes(data,(size_t)bytes);Upload *u=staged==(size_t)-1?NULL:add_upload();
 if(!u)return -1;
 const int at=buffers[slot].used;
 u->at=staged;u->bytes=(Uint32)bytes;u->buffer=buffers[slot].buffer;u->offset=buffers[slot].offset+(Uint32)at;
 buffers[slot].used=at+bytes;return at;
}

/* A program from its stages in the device's format (helix_sdl3gpu_shader_format: SPIR-V, MSL or HLSL; text ends with a NUL) and its layout,
   a line each, as NativeGraphics writes it: "a <slot> <name>" an attribute, "k <count>" the attribute slots (a matrix's columns each one),
   "u <slot> <v|f|b> <size> <name>" a uniform block at its slot in its stage, or in both (b), its "m ..." members after it (SDL_GPU takes the
   block's bytes whole), "t|s|c|d <slot> <v|f> <name>" a texture (plain, shadow map, cube, data) and its sampler, sharing the slot. */
uint32_t helix_sdl3gpu_shader(const void *vs,int vs_bytes,const void *fs,int fs_bytes,const char *layout){
 int slot=-1;for(int i=0;i<SLOTS;i++)if(!programs[i].live){slot=i;break;}
 if(slot<0||!vs||!fs||vs_bytes<=0||fs_bytes<=0)return 0;
 int sizes[MAX_BLOCK_INDICES]={0},both[MAX_BLOCK_INDICES]={0},block_counts[2]={0,0},attributes=0,mask=0,unfiltered=0,texture_stages[MAX_TEXTURES]={0};char kinds[MAX_TEXTURES]={0};
 for(const char *line=layout;line&&*line;){
  char kind,stage;int s,size,used=0;char name[128];
  if(sscanf(line," a %d %127s%n",&s,name,&used)==2){if(s<0||s>=16)return 0;if(s+1>attributes)attributes=s+1;}
  else if(sscanf(line," k %d%n",&s,&used)==1){if(s<0||s>16)return 0;if(s>attributes)attributes=s;}
  else if(sscanf(line," u %d %c %d %127s%n",&s,&stage,&size,name,&used)==4){
   if(s<0||s>=MAX_BLOCKS||size<=0||(stage!='v'&&stage!='f'&&stage!='b'))return 0;
   /* A block both stages read: at both indices, its fragment copy pushed from the vertex one. */
   if(stage!='f'){if(sizes[s])return 0;sizes[s]=size;if(s+1>block_counts[0])block_counts[0]=s+1;}
   if(stage!='v'){if(sizes[4+s])return 0;sizes[4+s]=size;both[4+s]=stage=='b';if(s+1>block_counts[1])block_counts[1]=s+1;}
  }else if(sscanf(line," m %127s %d%n",name,&s,&used)==2){
   /* A member: the rest of its line. */
   while(line[used]&&line[used]!='\n')used++;
  }else if(sscanf(line," %c %d %c %127s%n",&kind,&s,&stage,name,&used)==4&&(kind=='t'||kind=='s'||kind=='c'||kind=='d')){
   if(s<0||s>=MAX_TEXTURES)return 0;
   mask|=1<<s;texture_stages[s]=stage=='v'?0:1;kinds[s]=kind;if(kind=='d')unfiltered|=1<<s;
  }else return 0;
  line+=used;while(*line=='\n'||*line==' ')line++;
 }
 /* SDL_GPU's numbering of textures: per stage, from 0 in slot order; blocks at their slots (num_uniform_buffers the highest and one). */
 int counts[2]={0,0},texture_index[MAX_TEXTURES]={0};
 for(int i=0;i<MAX_TEXTURES;i++)if(mask&1<<i)texture_index[i]=counts[texture_stages[i]]++;
 const char *entry=shader_format==SDL_GPU_SHADERFORMAT_MSL?"main0":"main";
 const void *code[2]={vs,fs};size_t code_size[2]={(size_t)vs_bytes,(size_t)fs_bytes};
#if defined(_WIN32)
 ID3DBlob *compiled[2]={NULL,NULL};
 if(shader_format==SDL_GPU_SHADERFORMAT_DXBC){
  compiled[0]=dxbc(vs,"vs_5_1");compiled[1]=compiled[0]?dxbc(fs,"ps_5_1"):NULL;
  if(!compiled[1]){if(compiled[0])ID3D10Blob_Release(compiled[0]);return 0;}
  for(int i=0;i<2;i++){code[i]=ID3D10Blob_GetBufferPointer(compiled[i]);code_size[i]=ID3D10Blob_GetBufferSize(compiled[i]);}
 }
#endif
 SDL_GPUShader *made[2];
 for(int i=0;i<2;i++){
  const size_t n=code_size[i];
  made[i]=SDL_CreateGPUShader(device,&(SDL_GPUShaderCreateInfo){.code_size=n,.code=code[i],.entrypoint=entry,.format=shader_format,
   .stage=i?SDL_GPU_SHADERSTAGE_FRAGMENT:SDL_GPU_SHADERSTAGE_VERTEX,.num_samplers=(Uint32)counts[i],.num_uniform_buffers=(Uint32)block_counts[i]});
  if(!made[i])fprintf(stderr,"HeliX SDL_GPU: the %s stage didn't build: %s\n",i?"fragment":"vertex",SDL_GetError());
 }
#if defined(_WIN32)
 for(int i=0;i<2;i++)if(compiled[i])ID3D10Blob_Release(compiled[i]);
#endif
 if(!made[0]||!made[1]){for(int i=0;i<2;i++)if(made[i])SDL_ReleaseGPUShader(device,made[i]);return 0;}
 programs[slot].vertex=made[0];programs[slot].fragment=made[1];programs[slot].attributes=attributes;programs[slot].texture_mask=mask;programs[slot].unfiltered_mask=unfiltered;memcpy(programs[slot].texture_kind,kinds,sizeof kinds);
 memcpy(programs[slot].block_size,sizes,sizeof sizes);memcpy(programs[slot].block_both,both,sizeof both);
 memcpy(programs[slot].texture_stage,texture_stages,sizeof texture_stages);memcpy(programs[slot].texture_index,texture_index,sizeof texture_index);
 programs[slot].vertex_samplers=counts[0];programs[slot].fragment_samplers=counts[1];
 programs[slot].live=1;programs[slot].generation++;
 return handle_of(slot,programs[slot].generation);
}
static int program_live(uint32_t handle){const int s=slot_of(handle);return s>=0&&s<SLOTS&&programs[s].live&&(handle>>16)==programs[s].generation;}

/* A helix.platform.Blend (bits 0-3 the color's source factor, 4-7 its destination's, 8-11 and 12-15 the alpha's, 16-18 the color's
   operation, 19-21 the alpha's) and ColorChannels (bit 0 red, 1 green, 2 blue, 3 alpha) as SDL_GPU's blend state: BlendFactor's and
   BlendOperation's values in order; no blending for One, Zero and Add on both. 0 in *ok for a value outside the enums. */
static SDL_GPUColorTargetBlendState blend_of(int blend,int channels,int *ok){
 static const SDL_GPUBlendFactor factors[11]={SDL_GPU_BLENDFACTOR_ZERO,SDL_GPU_BLENDFACTOR_ONE,SDL_GPU_BLENDFACTOR_SRC_COLOR,SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR,
  SDL_GPU_BLENDFACTOR_DST_COLOR,SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_COLOR,SDL_GPU_BLENDFACTOR_SRC_ALPHA,SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
  SDL_GPU_BLENDFACTOR_DST_ALPHA,SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_ALPHA,SDL_GPU_BLENDFACTOR_SRC_ALPHA_SATURATE};
 static const SDL_GPUBlendOp ops[5]={SDL_GPU_BLENDOP_ADD,SDL_GPU_BLENDOP_SUBTRACT,SDL_GPU_BLENDOP_REVERSE_SUBTRACT,SDL_GPU_BLENDOP_MIN,SDL_GPU_BLENDOP_MAX};
 const int cs=blend&15,cd=blend>>4&15,as=blend>>8&15,ad=blend>>12&15,co=blend>>16&7,ao=blend>>19&7;
 *ok=blend>=0&&blend<1<<22&&cs<11&&cd<11&&as<11&&ad<11&&co<5&&ao<5&&channels>=0&&channels<=15;
 SDL_GPUColorTargetBlendState state={.color_write_mask=(SDL_GPUColorComponentFlags)(*ok?channels:15),.enable_color_write_mask=true};
 if(!*ok||(cs==1&&cd==0&&as==1&&ad==0&&co==0&&ao==0))return state;
 state.enable_blend=true;state.src_color_blendfactor=factors[cs];state.dst_color_blendfactor=factors[cd];state.color_blend_op=ops[co];
 state.src_alpha_blendfactor=factors[as];state.dst_alpha_blendfactor=factors[ad];state.alpha_blend_op=ops[ao];
 return state;
}
/* A pipeline as helix.platform.PipelineDesc describes it, its ints in order (as sokol's adapter reads them): shader, primitive (0 triangles,
   1 lines, 2 points), indexed, blend (blend_of), depth test (0 none, 1 less or equal, 2 greater), depth write, cull (0 none, 1 back, 2 front),
   clockwise, depth only, clip flip (0 none, 1 clip scale, 2 view-projection), the color channels written (blend_of), the flip uniform's
   block slot (the vertex stage's) and byte offset, the buffer count, then each buffer's stride, instanced and attribute count, each
   attribute's slot, format (graphics.h) and offset, then the constants' count and each one's slot and four floats' bits, then the depth bias
   and the slope bias as floats' bits (the depth test: 0 off, with no write, 1 less or equal, 2 greater, 3 always, 4 less). */
uint32_t helix_pipeline(const int *desc,int count){
 int slot=-1;for(int i=0;i<SLOTS;i++)if(!pipelines[i].live){slot=i;break;}
 if(slot<0||!desc||count<15||!program_live((uint32_t)desc[0]))return 0;
 const int program=slot_of((uint32_t)desc[0]),group=desc[1]==2?1:desc[1]==1?2:3,indexed=desc[2],depth_only=desc[8],clockwise=desc[7];int blend_ok=0;
 const SDL_GPUColorTargetBlendState blend=blend_of(desc[3],desc[10],&blend_ok);
 if(!blend_ok||desc[1]<0||desc[1]>2)return 0;
 SDL_GPUVertexBufferDescription vbs[HELIX_MAX_VERTEX_BUFFERS];SDL_GPUVertexAttribute attrs[HELIX_MAX_VERTEX_ATTRIBUTES];int nattrs=0;
 const int flip_slot=desc[11],flip_offset=desc[12],nbuffers=desc[13];int at=14,strides[HELIX_MAX_VERTEX_BUFFERS]={0},instanced[HELIX_MAX_VERTEX_BUFFERS]={0},read[HELIX_MAX_VERTEX_BUFFERS]={0};
 if(nbuffers<0||nbuffers>HELIX_MAX_VERTEX_BUFFERS)return 0;
 for(int b=0;b<nbuffers;b++){
  if(at+3>count)return 0;
  strides[b]=desc[at];instanced[b]=desc[at+1]!=0;const int n=desc[at+2];at+=3;
  if(strides[b]<0||n<0||at+n*3>count)return 0;
  vbs[b]=(SDL_GPUVertexBufferDescription){.slot=(Uint32)b,.pitch=(Uint32)strides[b],.input_rate=instanced[b]?SDL_GPU_VERTEXINPUTRATE_INSTANCE:SDL_GPU_VERTEXINPUTRATE_VERTEX};
  for(int a=0;a<n;a++,at+=3){
   const int location=desc[at],format=desc[at+1],offset=desc[at+2],bytes=helix_vertex_format_bytes(format);
   if(location<0||location>=HELIX_MAX_VERTEX_ATTRIBUTES||!bytes||offset<0||offset+bytes>strides[b]||nattrs==HELIX_MAX_VERTEX_ATTRIBUTES)return 0;
   static const SDL_GPUVertexElementFormat formats[HELIX_VERTEX_FORMATS]={SDL_GPU_VERTEXELEMENTFORMAT_FLOAT,SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2,
    SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3,SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4,SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4_NORM,SDL_GPU_VERTEXELEMENTFORMAT_BYTE4_NORM,
    SDL_GPU_VERTEXELEMENTFORMAT_USHORT2_NORM,SDL_GPU_VERTEXELEMENTFORMAT_SHORT2_NORM,SDL_GPU_VERTEXELEMENTFORMAT_USHORT4_NORM,
    SDL_GPU_VERTEXELEMENTFORMAT_SHORT4_NORM,SDL_GPU_VERTEXELEMENTFORMAT_HALF2,SDL_GPU_VERTEXELEMENTFORMAT_HALF4};
   attrs[nattrs++]=(SDL_GPUVertexAttribute){.location=(Uint32)location,.buffer_slot=(Uint32)b,.format=formats[format],.offset=(Uint32)offset};
  }
  read[b]=n>0;
 }
 if(flip_slot<0||flip_slot>=MAX_BLOCKS||flip_offset<0||flip_offset%4)return 0;
 /* The constants: each slot no buffer feeds, its four floats. */
 float given[HELIX_MAX_VERTEX_ATTRIBUTES][4];int has_constant[HELIX_MAX_VERTEX_ATTRIBUTES]={0},fed[HELIX_MAX_VERTEX_ATTRIBUTES]={0};
 for(int a=0;a<nattrs;a++)fed[attrs[a].location]=1;
 if(at>=count)return 0;
 const int nconstants=desc[at++];
 if(nconstants<0||at+nconstants*5>count)return 0;
 for(int k=0;k<nconstants;k++,at+=5){
  const int location=desc[at];
  if(location<0||location>=HELIX_MAX_VERTEX_ATTRIBUTES||fed[location])return 0;
  has_constant[location]=1;for(int i=0;i<4;i++){union{int i;float f;}bits={desc[at+1+i]};given[location][i]=bits.f;}
 }
 /* The depth biases: the constant in resolvable units, the slope's factor. */
 float depth_bias=0,slope_bias=0;
 if(at+2<=count){union{int i;float f;}b1={desc[at]},b2={desc[at+1]};depth_bias=b1.f;slope_bias=b2.f;at+=2;}
 /* Buffers no attribute reads aren't described: SDL_GPU wants none it isn't given. The rest are numbered in order, as a draw binds them;
    the constants' buffer after them. */
 SDL_GPUVertexBufferDescription described[HELIX_MAX_VERTEX_BUFFERS+1];int ndescribed=0,renumbered[HELIX_MAX_VERTEX_BUFFERS]={0};
 for(int b=0;b<nbuffers;b++)if(read[b]){renumbered[b]=ndescribed;described[ndescribed]=vbs[b];described[ndescribed].slot=(Uint32)ndescribed;ndescribed++;}
 for(int a=0;a<nattrs;a++)attrs[a].buffer_slot=(Uint32)renumbered[attrs[a].buffer_slot];
 float constants[HELIX_MAX_VERTEX_ATTRIBUTES*4];int nconstant=0;
 for(int location=0;location<programs[program].attributes;location++){
  if(fed[location])continue;
  if(nattrs==HELIX_MAX_VERTEX_ATTRIBUTES)return 0;
  for(int i=0;i<4;i++)constants[nconstant*4+i]=has_constant[location]?given[location][i]:i==3?1.0f:0.0f;
  attrs[nattrs++]=(SDL_GPUVertexAttribute){.location=(Uint32)location,.buffer_slot=(Uint32)ndescribed,.format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4,.offset=(Uint32)(nconstant*16)};
  nconstant++;
 }
 if(nconstant){described[ndescribed]=(SDL_GPUVertexBufferDescription){.slot=(Uint32)ndescribed,.pitch=(Uint32)(nconstant*16),.input_rate=SDL_GPU_VERTEXINPUTRATE_INSTANCE};ndescribed++;}
 const SDL_GPUColorTargetDescription color={.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,.blend_state=blend};
 SDL_GPUGraphicsPipelineCreateInfo info={.vertex_shader=programs[program].vertex,.fragment_shader=programs[program].fragment,
  .vertex_input_state={.vertex_buffer_descriptions=described,.num_vertex_buffers=(Uint32)ndescribed,.vertex_attributes=attrs,.num_vertex_attributes=(Uint32)nattrs},
  .primitive_type=group==1?SDL_GPU_PRIMITIVETYPE_POINTLIST:group==2?SDL_GPU_PRIMITIVETYPE_LINELIST:SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
  .rasterizer_state={.fill_mode=SDL_GPU_FILLMODE_FILL,.cull_mode=desc[6]==2?SDL_GPU_CULLMODE_FRONT:desc[6]?SDL_GPU_CULLMODE_BACK:SDL_GPU_CULLMODE_NONE,
   .front_face=clockwise?SDL_GPU_FRONTFACE_CLOCKWISE:SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE,.enable_depth_clip=true,
   .depth_bias_constant_factor=depth_bias,.depth_bias_slope_factor=slope_bias,.enable_depth_bias=depth_bias!=0||slope_bias!=0},
  .multisample_state={.sample_count=depth_only?SDL_GPU_SAMPLECOUNT_1:sample_count_of(window_samples)},
  .depth_stencil_state={.compare_op=desc[4]==2?SDL_GPU_COMPAREOP_GREATER:desc[4]==4?SDL_GPU_COMPAREOP_LESS:desc[4]==1?SDL_GPU_COMPAREOP_LESS_OR_EQUAL:SDL_GPU_COMPAREOP_ALWAYS,.enable_depth_test=desc[4]!=0,.enable_depth_write=desc[5]!=0&&desc[4]!=0},
  .target_info={.color_target_descriptions=depth_only?NULL:&color,.num_color_targets=depth_only?0:1,.depth_stencil_format=depth_format,.has_depth_stencil_target=true}};
 SDL_GPUGraphicsPipeline *pipeline=SDL_CreateGPUGraphicsPipeline(device,&info),*twin=NULL;
 if(!pipeline){fprintf(stderr,"HeliX SDL_GPU: a pipeline didn't build: %s\n",SDL_GetError());return 0;}
 /* The description kept for the variants, pointing at copies of its arrays. */
 memcpy(pipelines[slot].described,described,sizeof described);memcpy(pipelines[slot].attrs,attrs,sizeof attrs);pipelines[slot].color=color;
 pipelines[slot].info=info;pipelines[slot].info.vertex_input_state.vertex_buffer_descriptions=pipelines[slot].described;
 pipelines[slot].info.vertex_input_state.vertex_attributes=pipelines[slot].attrs;
 memset(pipelines[slot].variants,0,sizeof pipelines[slot].variants);pipelines[slot].variants[0]=pipeline;
 /* Depth alone (shadow maps, drawn flipped) gets a twin, its front faces the other way round. */
 if(depth_only&&group==3){
  SDL_GPUGraphicsPipelineCreateInfo flipped_info=info;
  flipped_info.rasterizer_state.front_face=clockwise?SDL_GPU_FRONTFACE_COUNTER_CLOCKWISE:SDL_GPU_FRONTFACE_CLOCKWISE;
  twin=SDL_CreateGPUGraphicsPipeline(device,&flipped_info);
  if(!twin){SDL_ReleaseGPUGraphicsPipeline(device,pipeline);return 0;}
 }
 pipelines[slot].pipeline=pipeline;pipelines[slot].flipped=twin;pipelines[slot].program=(uint32_t)desc[0];pipelines[slot].buffer_count=nbuffers;
 memcpy(pipelines[slot].stride,strides,sizeof strides);memcpy(pipelines[slot].instanced,instanced,sizeof instanced);memcpy(pipelines[slot].read,read,sizeof read);
 pipelines[slot].indexed=indexed!=0;pipelines[slot].group=group;pipelines[slot].flip=desc[9];pipelines[slot].depth_only=depth_only!=0;
 pipelines[slot].flip_slot=flip_slot;pipelines[slot].flip_offset=flip_offset;
 memcpy(pipelines[slot].constants,constants,sizeof constants);pipelines[slot].constant_attributes=nconstant;pipelines[slot].constant_count=0;pipelines[slot].constant_buffer=NULL;
 pipelines[slot].live=1;pipelines[slot].generation++;
 return handle_of(slot,pipelines[slot].generation);
}
static int pipeline_live(uint32_t handle){const int s=slot_of(handle);return s>=0&&s<SLOTS&&pipelines[s].live&&(handle>>16)==pipelines[s].generation;}

/* A color texture of format (RGBA8 or half floats), drawn into and sampled; a multisampled one of samples (drawn into, resolved into the first)
   when samples > 1; depth. */
static SDL_GPUTexture *color_texture(int w,int h,SDL_GPUTextureFormat format){
 return SDL_CreateGPUTexture(device,&(SDL_GPUTextureCreateInfo){.type=SDL_GPU_TEXTURETYPE_2D,.format=format,
  .usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER,.width=(Uint32)w,.height=(Uint32)h,.layer_count_or_depth=1,.num_levels=1});
}
static SDL_GPUTexture *samples_texture(int w,int h,SDL_GPUTextureFormat format,int samples){
 return samples>1?SDL_CreateGPUTexture(device,&(SDL_GPUTextureCreateInfo){.type=SDL_GPU_TEXTURETYPE_2D,.format=format,
  .usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET,.width=(Uint32)w,.height=(Uint32)h,.layer_count_or_depth=1,.num_levels=1,.sample_count=sample_count_of(samples)}):NULL;
}
static SDL_GPUTexture *depth_texture(int w,int h,int layers,int samples){
 return SDL_CreateGPUTexture(device,&(SDL_GPUTextureCreateInfo){.type=layers>1?SDL_GPU_TEXTURETYPE_2D_ARRAY:SDL_GPU_TEXTURETYPE_2D,.format=depth_format,
  .usage=SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|(samples>1?0:SDL_GPU_TEXTUREUSAGE_SAMPLER),.width=(Uint32)w,.height=(Uint32)h,
  .layer_count_or_depth=(Uint32)layers,.num_levels=1,.sample_count=sample_count_of(samples)});
}
/* The most samples a render target of format takes, at most 8: the most both it and the depth format take, so it holds with depth or without. */
int helix_max_target_samples(int format){
 if(!helix_can_render(format))return 1;
 const SDL_GPUTextureFormat pixels=format_of(format);
 for(int n=8;n>=2;n/=2)if(SDL_GPUTextureSupportsSampleCount(device,pixels,sample_count_of(n))&&SDL_GPUTextureSupportsSampleCount(device,depth_format,sample_count_of(n)))
  return n;
 return 1;
}
/* A render target: a color texture of format sampled through the handle, drawn through a multisampled texture resolved into it, or with one
   sample into it directly; with depth, a depth texture of the same samples for its passes. Its samples are the most the device takes for
   both the format and depth (as helix_max_target_samples) up to the samples asked for (at least 1), which a device need not take for every
   power of two (lavapipe takes 1 and 4). */
uint32_t helix_target(int w,int h,int format,int depth,int asked){
 const int slot=free_texture_slot();
 if(slot<0||w<=0||h<=0||w>16384||h>16384||!helix_can_render(format)||asked<1)return 0;
 const SDL_GPUTextureFormat pixels=format_of(format);
 int samples=asked>=8?8:asked>=4?4:asked>=2?2:1;
 while(samples>1&&!(SDL_GPUTextureSupportsSampleCount(device,pixels,sample_count_of(samples))&&
  SDL_GPUTextureSupportsSampleCount(device,depth_format,sample_count_of(samples))))samples/=2;
 SDL_GPUTexture *color=color_texture(w,h,pixels),*drawn=samples_texture(w,h,pixels,samples),*depth_target=depth?depth_texture(w,h,1,samples):NULL;
 if(!color||(samples>1&&!drawn)||(depth&&!depth_target)){
  if(color)SDL_ReleaseGPUTexture(device,color);if(drawn)SDL_ReleaseGPUTexture(device,drawn);if(depth_target)SDL_ReleaseGPUTexture(device,depth_target);return 0;
 }
 textures[slot].texture=color;textures[slot].samples=drawn;textures[slot].depth=depth_target;textures[slot].layers=1;textures[slot].sample_count=samples;
 textures[slot].variant=(format==4?1:0)|(depth?0:2)|((power_of(samples)^power_of(window_samples))<<2);
 return take_texture(slot,TARGET,w,h);
}
/* A shadow map: a depth array of layers layers, each size x size, sampled through the handle. Always an array, so its programs read it as one. */
uint32_t helix_shadow_map(int size,int layers){
 const int slot=free_texture_slot();
 if(slot<0||size<=0||size>16384||layers<=0||layers>MAX_SHADOW_LAYERS)return 0;
 SDL_GPUTexture *texture=SDL_CreateGPUTexture(device,&(SDL_GPUTextureCreateInfo){.type=SDL_GPU_TEXTURETYPE_2D_ARRAY,.format=depth_format,
  .usage=SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|SDL_GPU_TEXTUREUSAGE_SAMPLER,.width=(Uint32)size,.height=(Uint32)size,.layer_count_or_depth=(Uint32)layers,.num_levels=1});
 if(!texture)return 0;
 if(!comparison)comparison=SDL_CreateGPUSampler(device,&(SDL_GPUSamplerCreateInfo){.min_filter=SDL_GPU_FILTER_LINEAR,.mag_filter=SDL_GPU_FILTER_LINEAR,
  .address_mode_u=SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,.address_mode_v=SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,.address_mode_w=SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
  .compare_op=SDL_GPU_COMPAREOP_LESS_OR_EQUAL,.enable_compare=true});
 textures[slot].texture=texture;textures[slot].layers=layers;
 return take_texture(slot,SHADOW,size,size);
}

/* The frame's command buffer, acquired by its first pass, for a pass drawn with samples samples. A pass of fewer samples than one
   already recorded in it goes in a new one, the recorded passes submitted first: NVIDIA's Vulkan driver (595) loses the device on a
   multisampled pass followed by one of fewer samples in a command buffer, which the validation layers find nothing wrong with and Mesa's
   lavapipe draws. command_samples is the most samples a pass recorded in the command buffer has. */
static int command_samples;
static int frame_command(int samples){
 if(command&&samples<command_samples){SDL_SubmitGPUCommandBuffer(command);command=NULL;}
 if(!command){command=SDL_AcquireGPUCommandBuffer(device);command_samples=1;}
 if(!command){fprintf(stderr,"HeliX SDL_GPU: no command buffer: %s\n",SDL_GetError());return 0;}
 if(samples>command_samples)command_samples=samples;
 return 1;
}
static void begin_recording(int kind,int flip,int w,int h){
 active=kind;flipped=flip;pass_width=w;pass_height=h;staging_used=0;upload_count=0;command_count=0;uniform_used=0;
}
static SDL_FColor color_of(uint32_t color){return (SDL_FColor){((color>>16)&255)/255.f,((color>>8)&255)/255.f,(color&255)/255.f,(color>>24)/255.f};}

/* A depth-only pass into layer of map, cleared to the farthest and kept. Drawn flipped: a shadow map's rows run bottom first, as its lookups
   expect. */
int helix_begin_shadow(uint32_t map,int layer){
 if(active||!texture_live(map))return 0;
 const int slot=slot_of(map);
 if(textures[slot].kind!=SHADOW||layer<0||layer>=textures[slot].layers||!frame_command(1))return 0;
 pass_has_color=0;pass_has_depth=1;pass_variant=0;
 pass_depth=(SDL_GPUDepthStencilTargetInfo){.texture=textures[slot].texture,.clear_depth=1,.load_op=SDL_GPU_LOADOP_CLEAR,.store_op=SDL_GPU_STOREOP_STORE,
  .stencil_load_op=SDL_GPU_LOADOP_DONT_CARE,.stencil_store_op=SDL_GPU_STOREOP_DONT_CARE,.layer=(Uint8)layer};
 begin_recording(2,1,textures[slot].width,textures[slot].height);pass_texture=map;
 return 1;
}
/* Color and depth targets for a pass cleared to color, or (keep) loading what they hold: drawn into color, or into samples resolved into
   color at the pass's end; depth, or none. A kept target's samples and depth are stored, so a later pass can load them. */
static void color_pass(SDL_GPUTexture *color,SDL_GPUTexture *samples,SDL_GPUTexture *depth,SDL_FColor clear,int keep){
 pass_has_color=1;pass_has_depth=depth!=NULL;
 const SDL_GPULoadOp load=keep?SDL_GPU_LOADOP_LOAD:SDL_GPU_LOADOP_CLEAR;
 pass_color=samples?(SDL_GPUColorTargetInfo){.texture=samples,.clear_color=clear,.load_op=load,.store_op=keep?SDL_GPU_STOREOP_RESOLVE_AND_STORE:SDL_GPU_STOREOP_RESOLVE,.resolve_texture=color}
  :(SDL_GPUColorTargetInfo){.texture=color,.clear_color=clear,.load_op=load,.store_op=SDL_GPU_STOREOP_STORE};
 pass_depth=(SDL_GPUDepthStencilTargetInfo){.texture=depth,.clear_depth=1,.load_op=load,.store_op=keep?SDL_GPU_STOREOP_STORE:SDL_GPU_STOREOP_DONT_CARE,
  .stencil_load_op=SDL_GPU_LOADOP_DONT_CARE,.stencil_store_op=SDL_GPU_STOREOP_DONT_CARE};
}
/* A pass into target, before the screen's: cleared to red, green, blue, alpha as its texels store them (clear), or loading what it holds,
   cleared to transparent black the first time. Its samples and depth are stored, so a later pass can load them. Not flipped: SDL_GPU's rows
   are stored top first, as every texture's are. */
static int begin_target(uint32_t target,int clear,SDL_FColor color){
 if(active||!texture_live(target))return 0;
 const int slot=slot_of(target);
 if(textures[slot].kind!=TARGET||!frame_command(textures[slot].sample_count))return 0;
 if(!textures[slot].cleared)clear=1;
 textures[slot].cleared=1;
 color_pass(textures[slot].texture,textures[slot].samples,textures[slot].depth,color,1);
 if(clear){pass_color.load_op=SDL_GPU_LOADOP_CLEAR;pass_depth.load_op=SDL_GPU_LOADOP_CLEAR;}
 begin_recording(2,0,textures[slot].width,textures[slot].height);pass_variant=textures[slot].variant;pass_texture=target;
 return 1;
}
int helix_begin_target(uint32_t target,float red,float green,float blue,float alpha){return begin_target(target,1,(SDL_FColor){red,green,blue,alpha});}
int helix_resume_target(uint32_t target){return begin_target(target,0,(SDL_FColor){0,0,0,0});}
/* The screen's pass: into the screen texture (made again when the size changes), copied to the swapchain when the frame ends. */
int helix_begin(int width,int height,uint32_t color){
 if(active||width<=0||height<=0||!frame_command(window_samples))return 0;
 if(!screen||width!=screen_width||height!=screen_height){
  if(screen)SDL_ReleaseGPUTexture(device,screen);if(screen_samples)SDL_ReleaseGPUTexture(device,screen_samples);if(screen_depth)SDL_ReleaseGPUTexture(device,screen_depth);
  screen=color_texture(width,height,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM);screen_samples=samples_texture(width,height,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,window_samples);
  screen_depth=depth_texture(width,height,1,window_samples);
  screen_width=width;screen_height=height;
  if(!screen||(window_samples>1&&!screen_samples)||!screen_depth)return 0;
 }
 frame_ended=0;
 color_pass(screen,screen_samples,screen_depth,color_of(color),0);
 begin_recording(1,0,width,height);pass_variant=0;
 return 1;
}

/* Ends the pass: its staged writes copied, then its render pass replaying what was recorded. */
static int end_pass(void){
 if(!upload_staged(command,staging,staging_used,uploads,upload_count))return 0;
 SDL_GPURenderPass *pass=SDL_BeginGPURenderPass(command,pass_has_color?&pass_color:NULL,pass_has_color?1:0,pass_has_depth?&pass_depth:NULL);
 if(!pass){fprintf(stderr,"HeliX SDL_GPU: a render pass didn't begin: %s\n",SDL_GetError());return 0;}
 for(int i=0;i<command_count;i++){
  const Command *c=&commands[i];
  if(c->kind==VIEWPORT)SDL_SetGPUViewport(pass,&(SDL_GPUViewport){c->x,c->y,c->w,c->h,0,1});
  else if(c->kind==SCISSOR)SDL_SetGPUScissor(pass,&(SDL_Rect){(int)c->x,(int)c->y,(int)c->w,(int)c->h});
  else{
   SDL_BindGPUGraphicsPipeline(pass,c->pipeline);
   if(c->vertex_count)SDL_BindGPUVertexBuffers(pass,0,c->vertex,(Uint32)c->vertex_count);
   if(c->indexed)SDL_BindGPUIndexBuffer(pass,&(SDL_GPUBufferBinding){c->index,0},SDL_GPU_INDEXELEMENTSIZE_32BIT);
   if(c->vertex_sampler_count)SDL_BindGPUVertexSamplers(pass,0,c->vertex_samplers,(Uint32)c->vertex_sampler_count);
   if(c->fragment_sampler_count)SDL_BindGPUFragmentSamplers(pass,0,c->fragment_samplers,(Uint32)c->fragment_sampler_count);
   for(int u=0;u<c->uniform_count;u++){
    /* Stage 0 the vertex's, 1 the fragment's, 2 both. */
    if(c->uniform_stage[u])SDL_PushGPUFragmentUniformData(command,(Uint32)c->uniform_index[u],uniform_bytes+c->uniform_at[u],(Uint32)c->uniform_size[u]);
    if(c->uniform_stage[u]!=1)SDL_PushGPUVertexUniformData(command,(Uint32)c->uniform_index[u],uniform_bytes+c->uniform_at[u],(Uint32)c->uniform_size[u]);
   }
   if(c->indexed)SDL_DrawGPUIndexedPrimitives(pass,(Uint32)c->count,(Uint32)c->instances,(Uint32)c->first,0,0);
   else SDL_DrawGPUPrimitives(pass,(Uint32)c->count,(Uint32)c->instances,(Uint32)c->first,0);
  }
 }
 SDL_EndGPURenderPass(pass);
 return 1;
}
int helix_end_target(void){if(active!=2)return 0;const int ok=end_pass();active=0;flipped=0;pass_texture=0;return ok;}

/* Clips to x, y, w, h from the bottom left (on), or to the whole pass (off); lasts the pass. */
int helix_scissor(int x,int y,int w,int h,int on){
 if(!active||(on&&(w<0||h<0)))return 0;
 Command *c=add_command(SCISSOR);if(!c)return 0;
 if(on){c->x=(float)x;c->y=(float)(flipped?y:pass_height-y-h);c->w=(float)w;c->h=(float)h;}
 else{c->x=0;c->y=0;c->w=(float)pass_width;c->h=(float)pass_height;}
 return 1;
}
/* The viewport, from the bottom left as asked: SDL_GPU's top-left origin turns it over, unless the pass is drawn flipped. */
int helix_viewport(int x,int y,int w,int h){
 if(!active||w<=0||h<=0)return 0;
 Command *c=add_command(VIEWPORT);if(!c)return 0;
 c->x=(float)x;c->y=(float)(flipped?y:pass_height-y-h);c->w=(float)w;c->h=(float)h;
 return 1;
}
/* The sampler for a Sampling value: linear or nearest; the mipmaps not read (their levels clamped to the top), the nearest, or the two
   nearest blended; each axis's wrap; and the anisotropy, only with every filter linear, as sokol's adapter takes it. */
static SDL_GPUSampler *sampler_of(int sampling){
 static const SDL_GPUSamplerAddressMode wraps[3]={SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,SDL_GPU_SAMPLERADDRESSMODE_REPEAT,SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT};
 sampling&=SAMPLINGS-1;
 if(!samplers[sampling]){
  const SDL_GPUFilter filter=sampling&1?SDL_GPU_FILTER_LINEAR:SDL_GPU_FILTER_NEAREST;
  const int mipmaps=sampling>>5&3,anisotropy=1<<(sampling>>7&7),anisotropic=(sampling&1)&&mipmaps==2&&anisotropy>1&&anisotropy<=16;
  samplers[sampling]=SDL_CreateGPUSampler(device,&(SDL_GPUSamplerCreateInfo){.min_filter=filter,.mag_filter=filter,
   .mipmap_mode=mipmaps==2?SDL_GPU_SAMPLERMIPMAPMODE_LINEAR:SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,.address_mode_u=wraps[(sampling>>1&3)%3],
   .address_mode_v=wraps[(sampling>>3&3)%3],.address_mode_w=SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE,.max_lod=mipmaps?1000:0,
   .max_anisotropy=anisotropic?(float)anisotropy:1,.enable_anisotropy=anisotropic});
 }
 return samplers[sampling];
}
/* Stages a uniform block's bytes: where they are, or (size_t)-1. */
static size_t stage_uniform(const void *data,size_t bytes){
 const size_t at=uniform_used;
 if(!grow((void**)&uniform_bytes,&uniform_size,at+bytes,1))return (size_t)-1;
 memcpy(uniform_bytes+at,data,bytes);uniform_used=at+bytes;return at;
}
/* The variant of the pipeline in slot that draws in the open pass, made the first time (NULL when SDL refuses it): depth alone has none (it
   draws only into shadow maps). */
static SDL_GPUGraphicsPipeline *variant_of(int slot){
 const int v=pipelines[slot].depth_only?0:pass_variant;
 if(!pipelines[slot].variants[v]){
  SDL_GPUGraphicsPipelineCreateInfo info=pipelines[slot].info;SDL_GPUColorTargetDescription color=pipelines[slot].color;
  if(v&1)color.format=SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT;
  info.target_info.color_target_descriptions=&color;
  if(v&2){info.target_info.has_depth_stencil_target=false;info.depth_stencil_state.enable_depth_test=false;info.depth_stencil_state.enable_depth_write=false;}
  if(v&12)info.multisample_state.sample_count=sample_count_of(1<<(((v>>2)&3)^power_of(window_samples)));
  pipelines[slot].variants[v]=SDL_CreateGPUGraphicsPipeline(device,&info);
  if(!pipelines[slot].variants[v])fprintf(stderr,"HeliX SDL_GPU: a pipeline's variant didn't build: %s\n",SDL_GetError());
 }
 return pipelines[slot].variants[v];
}
/* What an unbound slot reads (a draw's texture 0 where the program declares one): a 1x1 texture of the slot's kind, clear, made when first
   needed. */
static uint32_t placeholders[3];
static uint32_t placeholder(char kind){
 static const unsigned char clear[24]={0};
 const int which=kind=='c'?1:kind=='s'?2:0;
 if(!placeholders[which])placeholders[which]=which==1?helix_cube_texture(1,clear,24,1,0):which==2?helix_shadow_map(1,1):helix_texture(1,1,clear,4,1,0);
 return placeholders[which];
}
/* The pipeline's constants' buffer, holding its record for at least instances instances, made again larger when it holds too few (the old
   one released once the GPU is done with it). */
static SDL_GPUBuffer *constant_buffer(int ps,int instances){
 if(pipelines[ps].constant_count<instances){
  int n=pipelines[ps].constant_count?pipelines[ps].constant_count:1;while(n<instances)n*=2;
  const size_t record=(size_t)pipelines[ps].constant_attributes*16,bytes=record*(size_t)n;
  unsigned char *data=malloc(bytes);if(!data)return NULL;
  for(int i=0;i<n;i++)memcpy(data+record*(size_t)i,pipelines[ps].constants,record);
  SDL_GPUBuffer *buffer=SDL_CreateGPUBuffer(device,&(SDL_GPUBufferCreateInfo){.usage=SDL_GPU_BUFFERUSAGE_VERTEX,.size=(Uint32)bytes});
  const Upload u={.bytes=(Uint32)bytes,.buffer=buffer};
  if(!buffer||!upload_now(data,bytes,&u,1)){free(data);if(buffer)SDL_ReleaseGPUBuffer(device,buffer);return NULL;}
  free(data);
  if(pipelines[ps].constant_buffer)SDL_ReleaseGPUBuffer(device,pipelines[ps].constant_buffer);
  pipelines[ps].constant_buffer=buffer;pipelines[ps].constant_count=n;
 }
 return pipelines[ps].constant_buffer;
}
/* A draw through pipeline p, recorded for the pass's replay, checked as sokol's adapter checks it: count vertices from first (or indices, for
   an indexed pipeline, from first of `indices`) as instance_count instances from record first_instance of its instanced buffers; buffers[i]
   its buffer i (0 for one it doesn't read); the program's textures and samplings by slot; its uniform blocks' bytes one after another by
   their index (the vertex stage's slots 0 to 3, the fragment stage's 4 to 7, a block both read at both), the pipeline's flip uniform
   written as its clip flip says. offsets[i]: bytes into buffers[i], a multiple of 4 within its used bytes. -1 for a texture that is the pass's own target; 0, drawing nothing, for anything else invalid. */
int helix_draw(uint32_t p,const uint32_t *buffer_handles,const int *offsets,int buffer_count,uint32_t indices,int first,int count,int first_instance,int instance_count,
               const uint32_t *texture_handles,const int *samplings,int texture_count,const void *uniforms,int uniform_total){
 if(!active||!pipeline_live(p))return 0;
 const int ps=slot_of(p),group=pipelines[ps].group,indexed=pipelines[ps].indexed;
 if(!program_live(pipelines[ps].program))return 0;
 const int program=slot_of(pipelines[ps].program);
 if(first<0||count<=0||count%group||first_instance<0||instance_count<=0||buffer_count<pipelines[ps].buffer_count)return 0;
 int total=0;for(int i=0;i<MAX_BLOCK_INDICES;i++)total+=programs[program].block_size[i];
 const int mask=programs[program].texture_mask;
 if(total!=uniform_total||texture_count>MAX_TEXTURES)return 0;
 Command c={.kind=DRAW,.first=first,.count=count,.instances=instance_count,.indexed=indexed};
 c.pipeline=flipped&&pipelines[ps].flipped?pipelines[ps].flipped:variant_of(ps);
 if(!c.pipeline)return 0;
 if(indexed){
  if(!buffer_live(indices))return 0;
  const int is=slot_of(indices);
  if(!buffers[is].index||(long)(first+count)*4>buffers[is].used)return 0;
  c.index=buffers[is].buffer;
 }
 for(int b=0;b<pipelines[ps].buffer_count;b++){
  if(!pipelines[ps].read[b])continue;
  if(!buffer_live(buffer_handles[b]))return 0;
  const int bs=slot_of(buffer_handles[b]),stride=pipelines[ps].stride[b],instanced=pipelines[ps].instanced[b];
  if(buffers[bs].index||!buffers[bs].buffer)return 0;
  const long offset=offsets[b];
  if(offset<0||offset%4||offset>buffers[bs].used)return 0;
  if(instanced&&offset+(long)(first_instance+instance_count)*stride>buffers[bs].used)return 0;
  if(!instanced&&!indexed&&offset+(long)(first+count)*stride>buffers[bs].used)return 0;
  c.vertex[c.vertex_count++]=(SDL_GPUBufferBinding){buffers[bs].buffer,buffers[bs].offset+(Uint32)offset+(Uint32)(instanced?first_instance*stride:0)};
 }
 if(pipelines[ps].constant_attributes){
  SDL_GPUBuffer *constants=constant_buffer(ps,instance_count);
  if(!constants)return 0;
  c.vertex[c.vertex_count++]=(SDL_GPUBufferBinding){constants,0};
 }
 for(int i=0;i<MAX_TEXTURES;i++){
  if(!(mask&1<<i))continue;
  /* A slot the draw leaves unbound reads a placeholder of its kind. */
  const uint32_t handle=i<texture_count&&texture_handles[i]?texture_handles[i]:placeholder(programs[program].texture_kind[i]);
  const int sampling=i<texture_count?samplings[i]:0;
  if(!texture_live(handle))return 0;
  if(handle==pass_texture)return -1;
  const int ts=slot_of(handle),kind=textures[ts].kind;
  SDL_GPUTexture *texture=textures[ts].texture;
  if(kind==DATA){texture=textures[ts].versions[textures[ts].current];textures[ts].bound[textures[ts].current]=1;}
  /* A slot the program never filters (it only fetches texels) and a data texture are sampled nearest, whatever the draw's sampling. */
  const int unfiltered=kind==DATA||programs[program].unfiltered_mask&1<<i;
  const SDL_GPUTextureSamplerBinding binding={texture,kind==SHADOW?comparison:sampler_of(unfiltered?0:sampling)};
  if(programs[program].texture_stage[i])c.fragment_samplers[programs[program].texture_index[i]]=binding;
  else c.vertex_samplers[programs[program].texture_index[i]]=binding;
 }
 c.vertex_sampler_count=programs[program].vertex_samplers;c.fragment_sampler_count=programs[program].fragment_samplers;
 const char *at=uniforms;
 for(int i=0;i<MAX_BLOCK_INDICES;i++){
  const int size=programs[program].block_size[i];
  if(!size)continue;
  /* The fragment copy of a block both stages read: the vertex copy is pushed to both. */
  if(programs[program].block_both[i]){at+=size;continue;}
  size_t staged=stage_uniform(at,(size_t)size);
  if(staged==(size_t)-1)return 0;
  /* The flip uniform, in the adapter's copy: a clip scale (1, -1, 1, 1) in a flipped pass (a shadow map's, its rows bottom first) and
     (1, 1, 1, 1) in any other; a view-projection's y row negated in a flipped pass. */
  const int flip=pipelines[ps].flip,offset=pipelines[ps].flip_offset;
  if(flip&&i==pipelines[ps].flip_slot){
   float *place=(float*)(uniform_bytes+staged+offset);
   if(flip==1&&offset+16<=size){place[0]=1.0f;place[1]=flipped?-1.0f:1.0f;place[2]=1.0f;place[3]=1.0f;}
   else if(flip==2&&flipped&&offset+64<=size){place[1]=-place[1];place[5]=-place[5];place[9]=-place[9];place[13]=-place[13];}
  }
  c.uniform_at[c.uniform_count]=staged;c.uniform_size[c.uniform_count]=size;
  c.uniform_stage[c.uniform_count]=i<4?(programs[program].block_both[i+4]?2:0):1;c.uniform_index[c.uniform_count]=i&3;c.uniform_count++;
  at+=size;
 }
 Command *recorded=add_command(DRAW);
 if(!recorded)return 0;
 *recorded=c;return 1;
}
/* Ends the screen's pass and the frame: the frame, drawn into the screen texture, submitted. present shows it. */
void helix_end(void){
 if(active!=1)abort();
 end_pass();active=0;
 SDL_SubmitGPUCommandBuffer(command);command=NULL;frame_ended=1;
 for(int i=0;i<retired_count;i++)SDL_ReleaseGPUBuffer(device,retired[i]);
 retired_count=0;arena_used=0;arena_cycled=0;
 /* Stream buffers start each frame empty; data textures' versions are free again. */
 for(int i=0;i<SLOTS;i++){if(buffers[i].live&&buffers[i].stream){buffers[i].used=0;buffers[i].appended=0;buffers[i].buffer=NULL;}if(textures[i].kind==DATA)memset(textures[i].bound,0,sizeof textures[i].bound);}
}

/* What handle 0 (the frame just ended), an RGBA8 render target or an RGBA8 2D texture of helix_texture reads back as: its width and
   height, 0 when it can't be read now (or, a target of half floats, a cube, a data texture or a shadow map, at all). */
static int readable(uint32_t handle){
 if(!texture_live(handle))return 0;
 const int slot=slot_of(handle);
 return textures[slot].kind==TARGET?!(textures[slot].variant&1):textures[slot].kind==PLAIN&&textures[slot].layers==1&&textures[slot].format==0;
}
int helix_read_width(uint32_t target){
 if(!target)return frame_ended?screen_width:0;
 return readable(target)?textures[slot_of(target)].width:0;
}
int helix_read_height(uint32_t target){
 if(!target)return frame_ended?screen_height:0;
 return readable(target)?textures[slot_of(target)].height:0;
}
/* Reads target into out (width * height * 4 bytes, RGBA8, rows top first), outside any pass, waiting for the GPU: the screen texture for 0,
   else the texture (a target's color texture), its top level. A frame still being recorded is submitted first. */
int helix_read_pixels(uint32_t target,unsigned char *out){
 const int w=helix_read_width(target),h=helix_read_height(target);
 if(active||!out||w<=0||h<=0)return 0;
 SDL_GPUTexture *texture=target?textures[slot_of(target)].texture:screen;
 if(command){SDL_SubmitGPUCommandBuffer(command);command=NULL;}
 const Uint32 size=(Uint32)w*(Uint32)h*4;
 SDL_GPUTransferBuffer *download=SDL_CreateGPUTransferBuffer(device,&(SDL_GPUTransferBufferCreateInfo){.usage=SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD,.size=size});
 SDL_GPUCommandBuffer *cmd=download?SDL_AcquireGPUCommandBuffer(device):NULL;
 if(!cmd){if(download)SDL_ReleaseGPUTransferBuffer(device,download);return 0;}
 SDL_GPUCopyPass *copy=SDL_BeginGPUCopyPass(cmd);
 SDL_DownloadFromGPUTexture(copy,&(SDL_GPUTextureRegion){.texture=texture,.w=(Uint32)w,.h=(Uint32)h,.d=1},&(SDL_GPUTextureTransferInfo){.transfer_buffer=download});
 SDL_EndGPUCopyPass(copy);
 SDL_GPUFence *fence=SDL_SubmitGPUCommandBufferAndAcquireFence(cmd);
 int ok=0;
 if(fence&&SDL_WaitForGPUFences(device,true,&fence,1)){
  const void *mapped=SDL_MapGPUTransferBuffer(device,download,false);
  if(mapped){memcpy(out,mapped,size);SDL_UnmapGPUTransferBuffer(device,download);ok=1;}
 }
 if(fence)SDL_ReleaseGPUFence(device,fence);
 SDL_ReleaseGPUTransferBuffer(device,download);
 return ok;
}

/* Releases a texture's GPU textures and frees its slot. */
static void release_texture(int slot){
 if(textures[slot].kind==DATA){for(int i=0;i<MAX_RENAMES;i++)if(textures[slot].versions[i])SDL_ReleaseGPUTexture(device,textures[slot].versions[i]);}
 else if(textures[slot].texture)SDL_ReleaseGPUTexture(device,textures[slot].texture);
 if(textures[slot].samples)SDL_ReleaseGPUTexture(device,textures[slot].samples);
 if(textures[slot].depth)SDL_ReleaseGPUTexture(device,textures[slot].depth);
 const uint32_t generation=textures[slot].generation;memset(&textures[slot],0,sizeof textures[slot]);textures[slot].generation=generation;
}
static void release_pipeline(int slot){
 if(pipelines[slot].constant_buffer)SDL_ReleaseGPUBuffer(device,pipelines[slot].constant_buffer);
 SDL_ReleaseGPUGraphicsPipeline(device,pipelines[slot].pipeline);if(pipelines[slot].flipped)SDL_ReleaseGPUGraphicsPipeline(device,pipelines[slot].flipped);
 for(int v=1;v<VARIANTS;v++)if(pipelines[slot].variants[v])SDL_ReleaseGPUGraphicsPipeline(device,pipelines[slot].variants[v]);
 const uint32_t generation=pipelines[slot].generation;memset(&pipelines[slot],0,sizeof pipelines[slot]);pipelines[slot].generation=generation;
}
/* Shows the frame: the screen texture copied to the window's swapchain, acquired as the display allows (the wait that paces the loop,
   unless the window was opened without vsync),
   when the window has one to give (none while minimized). */
void helix_present(void){
 if(!device||!frame_ended)return;
 SDL_GPUCommandBuffer *present=SDL_AcquireGPUCommandBuffer(device);
 if(!present)return;
 SDL_GPUTexture *swapchain=NULL;Uint32 w=0,h=0;
 if(SDL_WaitAndAcquireGPUSwapchainTexture(present,window,&swapchain,&w,&h)&&swapchain)
  SDL_BlitGPUTexture(present,&(SDL_GPUBlitInfo){.source={.texture=screen,.w=(Uint32)screen_width,.h=(Uint32)screen_height},
   .destination={.texture=swapchain,.w=w,.h=h},.load_op=SDL_GPU_LOADOP_DONT_CARE,.filter=SDL_GPU_FILTER_LINEAR});
 SDL_SubmitGPUCommandBuffer(present);
}
/* Disposes a buffer (0), texture (1), pipeline (2) or program (3, its pipelines first). SDL_GPU frees each once the GPU is done with it. */
int helix_dispose_resource(int kind,uint32_t handle){
 const int slot=slot_of(handle);
 if(kind==0&&buffer_live(handle)){if(!buffers[slot].stream)SDL_ReleaseGPUBuffer(device,buffers[slot].buffer);buffers[slot].live=0;buffers[slot].buffer=NULL;return 1;}
 if(kind==1&&texture_live(handle)){release_texture(slot);return 1;}
 if(kind==2&&pipeline_live(handle)){release_pipeline(slot);return 1;}
 if(kind==3&&program_live(handle)){
  for(int i=0;i<SLOTS;i++)if(pipelines[i].live&&pipelines[i].program==handle)release_pipeline(i);
  SDL_ReleaseGPUShader(device,programs[slot].vertex);SDL_ReleaseGPUShader(device,programs[slot].fragment);programs[slot].live=0;return 1;
 }
 return 0;
}
void helix_sdl3gpu_dispose(void){
 if(!device)return;
 if(command){SDL_CancelGPUCommandBuffer(command);command=NULL;}
 SDL_WaitForGPUIdle(device);
 for(int i=0;i<SLOTS;i++){
  if(pipelines[i].live)release_pipeline(i);
  if(programs[i].live){SDL_ReleaseGPUShader(device,programs[i].vertex);SDL_ReleaseGPUShader(device,programs[i].fragment);programs[i].live=0;}
  if(textures[i].live)release_texture(i);
  if(buffers[i].live&&!buffers[i].stream)SDL_ReleaseGPUBuffer(device,buffers[i].buffer);
  buffers[i].live=0;
 }
 memset(placeholders,0,sizeof placeholders);
 for(int i=0;i<SAMPLINGS;i++)if(samplers[i]){SDL_ReleaseGPUSampler(device,samplers[i]);samplers[i]=NULL;}
 if(comparison){SDL_ReleaseGPUSampler(device,comparison);comparison=NULL;}
 for(int i=0;i<retired_count;i++)SDL_ReleaseGPUBuffer(device,retired[i]);
 retired_count=0;
 if(arena){SDL_ReleaseGPUBuffer(device,arena);arena=NULL;arena_size=arena_used=0;}
 if(transfer){SDL_ReleaseGPUTransferBuffer(device,transfer);transfer=NULL;transfer_size=0;}
 if(screen)SDL_ReleaseGPUTexture(device,screen);if(screen_samples)SDL_ReleaseGPUTexture(device,screen_samples);if(screen_depth)SDL_ReleaseGPUTexture(device,screen_depth);
 screen=screen_samples=screen_depth=NULL;
 SDL_ReleaseWindowFromGPUDevice(device,window);SDL_DestroyGPUDevice(device);device=NULL;
 free(staging);free(uploads);free(commands);free(uniform_bytes);staging=NULL;uploads=NULL;commands=NULL;uniform_bytes=NULL;
 staging_size=uniform_size=0;upload_size=command_size=0;
}
