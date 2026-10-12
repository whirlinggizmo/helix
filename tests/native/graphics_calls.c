/* Linux-only diagnostic interposer, loaded for audits and absent from timing/game delivery. */
#define _GNU_SOURCE
#define GL_GLEXT_PROTOTYPES
#include <GL/gl.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

static uint32_t draws,uploads,programs,textures;
static uint64_t uploaded_bytes;
static void *required(const char *name){void *fn=dlsym(RTLD_NEXT,name);if(!fn){fprintf(stderr,"Missing audit GL function: %s\n",name);abort();}return fn;}
void helix_gl_audit_reset(void){draws=uploads=programs=textures=0;uploaded_bytes=0;}
const char *helix_gl_audit_json(void){
 static char json[256];snprintf(json,sizeof json,"{\"drawArrays\":%u,\"bufferSubData\":%u,\"uploadedBytes\":%llu,\"useProgram\":%u,\"bindTexture\":%u}",draws,uploads,(unsigned long long)uploaded_bytes,programs,textures);return json;
}
void glDrawArrays(GLenum mode,GLint first,GLsizei count){
 static void (*real)(GLenum,GLint,GLsizei);if(!real)real=(void (*)(GLenum,GLint,GLsizei))required("glDrawArrays");draws++;real(mode,first,count);
}
void glBufferSubData(GLenum target,GLintptr offset,GLsizeiptr size,const void *data){
 static void (*real)(GLenum,GLintptr,GLsizeiptr,const void*);if(!real)real=(void (*)(GLenum,GLintptr,GLsizeiptr,const void*))required("glBufferSubData");uploads++;uploaded_bytes+=(uint64_t)size;real(target,offset,size,data);
}
void glUseProgram(GLuint program){
 static void (*real)(GLuint);if(!real)real=(void (*)(GLuint))required("glUseProgram");programs++;real(program);
}
void glBindTexture(GLenum target,GLuint texture){
 static void (*real)(GLenum,GLuint);if(!real)real=(void (*)(GLenum,GLuint))required("glBindTexture");textures++;real(target,texture);
}
