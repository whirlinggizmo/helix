// raylib 5.5 C: N robots, each posed by UpdateModelAnimation at its own frame, drawn with DrawModel; built with -DGPU they're posed by
// UpdateModelAnimationBones and skinned by its shader. --count=N natively, count=N in a page's query.
#include "raylib.h"
#include "raymath.h"
#include "shaders.h"
#ifdef PLATFORM_WEB
#define VS skin_vs_100
#define FS skin_fs_100
#else
#define VS skin_vs_330
#define FS skin_fs_330
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#ifdef PLATFORM_WEB
#include <emscripten/emscripten.h>
#endif
#define WARM 120
#define FRAMES 600
#ifndef COUNT
#define COUNT 100
#endif
static int chunk = 1<<30, count = COUNT, cols, frame = -1, nanims, loaded = 0;
static Model *models; static ModelAnimation *anims; static Camera camera;
static double *deltas, *upds, last, firstWall;
static int cmp(const void*a,const void*b){double x=*(double*)a,y=*(double*)b;return x<y?-1:x>y;}
static void report(int verts, int bones){
  double s=0,u=0; qsort(deltas,FRAMES,sizeof(double),cmp);
  for(int i=0;i<FRAMES;i++){s+=deltas[i];u+=upds[i];}
  double p95=deltas[(int)(FRAMES*0.95)];
  printf("{\"contender\":\"raylib C %s\",\"count\":%d,\"verts\":%d,\"bones\":%d,\"mean_ms\":%.4f,\"p95_ms\":%.4f,\"upd_ms\":%.4f}\n",
#ifdef GPU
"gpu"
#else
"cpu"
#endif
,count,verts,bones,s/FRAMES,p95,u/FRAMES);
  fflush(stdout);
}
static int done=0;
static void tick(void){
  double now=GetTime()*1000;
  if(frame>=WARM){deltas[frame-WARM]=now-last;}
  last=now;
  double u=0;
  for(int i=0;i<count;){
    BeginDrawing(); if(i==0) ClearBackground(RAYWHITE); BeginMode3D(camera);
    int stop=i+chunk<count?i+chunk:count;
    for(;i<stop;i++){
      double t0=GetTime();
#ifdef GPU
      UpdateModelAnimationBones(models[0],anims[0],(frame+1+i*5)%anims[0].frameCount);
#else
      UpdateModelAnimation(models[0],anims[0],(frame+1+i*5)%anims[0].frameCount);
#endif
      u+=GetTime()-t0;
      Vector3 p={((i%cols)-(cols-1)/2.0f)*4.0f,0,((i/cols)-(cols-1)/2.0f)*4.0f};
#ifdef GPU
      { Matrix tr=MatrixTranslate(p.x,p.y,p.z);
        for(int m=0;m<models[0].meshCount;m++) DrawMesh(models[0].meshes[m],models[0].materials[models[0].meshMaterial[m]],tr); }
#else
      DrawModel(models[0],p,1.0f,WHITE);
#endif
    }
    EndMode3D(); EndDrawing();
  }
  u*=1000;
  if(frame>=WARM) upds[frame-WARM]=u;
  frame++;
  if(frame>=WARM+FRAMES+0){
    int v=0;for(int m=0;m<models[0].meshCount;m++)v+=models[0].meshes[m].vertexCount;
    report(v,models[0].boneCount); done=1;
#ifdef PLATFORM_WEB
    emscripten_cancel_main_loop();
#endif
  }
}
int main(int argc,char**argv){
#ifdef PLATFORM_WEB
  { char *q=emscripten_run_script_string("location.search"); const char *c=strstr(q,"count="); if(c) count=atoi(c+6); }
#else
  for(int i=1;i<argc;i++) if(!strncmp(argv[i],"--count=",8)) count=atoi(argv[i]+8); else if(!strncmp(argv[i],"--chunk=",8)) chunk=atoi(argv[i]+8);
#endif
  SetTraceLogLevel(LOG_WARNING);
  InitWindow(1280,720,"skin C");
  cols=(int)ceil(sqrt((double)count)); float W=cols*4.0f;
  camera=(Camera){{0,0.9f*W,0.9f*W},{0,1.5f,0},{0,1,0},45,CAMERA_PERSPECTIVE};
  models=malloc(sizeof(Model));
  models[0]=LoadModel("robot.glb");
  anims=LoadModelAnimations("robot.glb",&nanims);
#ifdef GPU
  { Shader sh=LoadShaderFromMemory(VS,FS);
    for(int m=0;m<models[0].materialCount;m++) models[0].materials[m].shader=sh; }
#endif
  deltas=malloc(sizeof(double)*FRAMES); upds=malloc(sizeof(double)*FRAMES);
#ifdef PLATFORM_WEB
  emscripten_set_main_loop(tick,0,1);
#else
  while(!done&&!WindowShouldClose()) tick();
#endif
  return 0;
}
