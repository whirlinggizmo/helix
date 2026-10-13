#include "codec.h"
#include "sndfile/sndfile.h"
#include <math.h>
#include <pthread.h>
#include <stdlib.h>
#include <string.h>

/* Codec-only bridge. Haxe owns loading, scheduling, resources and playback. */
typedef struct {
    SNDFILE *file;
    SF_INFO info;
    unsigned char *memory;
    sf_count_t length, offset, produced, total;
    float chunk[2048];
    int at, count, have_a, have_b;
    float a, b;
    double phase;
} decoder_t;
static decoder_t *decoders[32];
static pthread_mutex_t codec_lock = PTHREAD_MUTEX_INITIALIZER;

static sf_count_t memory_length(void *user) { return ((decoder_t *)user)->length; }
static sf_count_t memory_seek(sf_count_t offset, int whence, void *user) {
    decoder_t *d=user;
    sf_count_t base=whence==SEEK_SET?0:whence==SEEK_CUR?d->offset:whence==SEEK_END?d->length:-1;
    if(base<0 || offset < -base || offset > d->length-base) return -1;
    d->offset=base+offset; return d->offset;
}
static sf_count_t memory_read(void *out, sf_count_t count, void *user) {
    decoder_t *d=user;
    if(count<0) return 0;
    if(count>d->length-d->offset) count=d->length-d->offset;
    memcpy(out,d->memory+d->offset,(size_t)count);d->offset+=count;return count;
}
static sf_count_t memory_write(const void *data, sf_count_t count, void *user) { (void)data;(void)count;(void)user;return 0; }
static sf_count_t memory_tell(void *user) { return ((decoder_t *)user)->offset; }
static SF_VIRTUAL_IO memory_io={memory_length,memory_seek,memory_read,memory_write,memory_tell};

static int register_decoder(decoder_t *d) {
    int subtype=d->info.format&SF_FORMAT_SUBMASK;
    /* Ogg Vorbis or Opus, or MP3 (libsndfile 1.1 and later, through mpg123) */
    const int type=d->info.format&SF_FORMAT_TYPEMASK;
    const int ogg=type==SF_FORMAT_OGG&&(subtype==SF_FORMAT_VORBIS||subtype==SF_FORMAT_OPUS);
    const int mp3=type==SF_FORMAT_MPEG&&subtype==SF_FORMAT_MPEG_LAYER_III;
    if(!d->file || (!ogg&&!mp3) ||
       d->info.channels<1 || d->info.channels>2 || d->info.samplerate<8000 ||
       d->info.samplerate>192000 || d->info.frames<=0) {
        if(d->file)sf_close(d->file);free(d->memory);free(d);return 0;
    }
    d->total=(sf_count_t)ceil((double)d->info.frames*44100/d->info.samplerate);
    pthread_mutex_lock(&codec_lock);
    int id=0;for(int i=0;i<32;i++)if(!decoders[i]){decoders[i]=d;id=i+1;break;}
    pthread_mutex_unlock(&codec_lock);
    if(!id){sf_close(d->file);free(d->memory);free(d);}return id;
}
int helix_codec_memory(const void *data,int bytes) {
    const unsigned char *b=data;
    /* Ogg's capture pattern, or an MP3: its ID3 tag or an MPEG frame's sync bits */
    const int known=bytes>=4&&(!memcmp(b,"OggS",4)||!memcmp(b,"ID3",3)||(b[0]==0xFF&&(b[1]&0xE0)==0xE0));
    if(!data || bytes<4 || bytes>8*1024*1024 || !known)return 0;
    decoder_t *d=calloc(1,sizeof *d);if(!d)return 0;
    d->memory=malloc((size_t)bytes);if(!d->memory){free(d);return 0;}
    memcpy(d->memory,data,(size_t)bytes);d->length=bytes;
    d->file=sf_open_virtual(&memory_io,SFM_READ,&d->info,d);return register_decoder(d);
}
int helix_codec_file(const char *path) {
    if(!path)return 0;decoder_t *d=calloc(1,sizeof *d);if(!d)return 0;
    d->file=sf_open(path,SFM_READ,&d->info);return register_decoder(d);
}
static decoder_t *get_decoder(int id) { return id>0&&id<=32?decoders[id-1]:NULL; }
double helix_codec_frames(int id) {
    pthread_mutex_lock(&codec_lock);decoder_t *d=get_decoder(id);
    double n=d?(double)d->total:0;
    pthread_mutex_unlock(&codec_lock);return n;
}
static int next_sample(decoder_t *d,float *sample) {
    if(d->at==d->count){
        sf_count_t n=sf_readf_float(d->file,d->chunk,1024);
        if(n<=0)return sf_error(d->file)?-1:0;
        d->count=(int)n;d->at=0;
    }
    float value=0;for(int c=0;c<d->info.channels;c++)value+=d->chunk[d->at*d->info.channels+c];
    d->at++;value/=d->info.channels;
    if(!isfinite(value))return -1;
    *sample=fmaxf(-1,fminf(1,value));return 1;
}
int helix_codec_read(int id,void *destination,int frames) {
    if(!destination || frames<=0 || frames>2048)return -1;
    pthread_mutex_lock(&codec_lock);decoder_t *d=get_decoder(id);int n=0,error=0;float *out=destination;
    if(!d){pthread_mutex_unlock(&codec_lock);return -1;}
    if(!d->have_a){int a=next_sample(d,&d->a);if(a<0)error=1;d->have_a=a>0;
        if(d->have_a){int b=next_sample(d,&d->b);if(b<0)error=1;d->have_b=b>0;}}
    while(!error && n<frames && d->have_a && d->produced<d->total){
        out[n++]=d->a+(d->have_b?d->b-d->a:0)*(float)d->phase;
        d->produced++;
        d->phase+=(double)d->info.samplerate/44100;
        while(d->phase>=1 && d->have_a){
            d->phase-=1;d->a=d->b;d->have_a=d->have_b;
            if(d->have_a){int b=next_sample(d,&d->b);if(b<0)error=1;d->have_b=b>0;}
        }
    }
    pthread_mutex_unlock(&codec_lock);return error?-1:n;
}
int helix_codec_rewind(int id) {
    pthread_mutex_lock(&codec_lock);decoder_t *d=get_decoder(id);
    int ok=d && sf_seek(d->file,0,SEEK_SET)==0;
    if(ok){d->at=d->count=d->have_a=d->have_b=0;d->phase=0;d->produced=0;}
    pthread_mutex_unlock(&codec_lock);return ok;
}
void helix_codec_close(int id) {
    pthread_mutex_lock(&codec_lock);decoder_t *d=get_decoder(id);
    if(d){decoders[id-1]=NULL;sf_close(d->file);free(d->memory);free(d);}
    pthread_mutex_unlock(&codec_lock);
}
const char *helix_codec_version(void) { return sf_version_string(); }
