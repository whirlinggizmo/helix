#include "audio.h"
#include "input.h"
#include "gamepad.h"
#include <fcntl.h>
#include <linux/input.h>
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#define SOKOL_LOG_IMPL
#include "sokol_log.h"

static int checks;
#define CHECK(value) do { if (!(value)) { fprintf(stderr, "Failed at line %d\n", __LINE__); abort(); } checks++; } while (0)
static void event(int fd, int type, int code, int value) {
    const struct input_event input = {.type=type, .code=code, .value=value};
    if (write(fd, &input, sizeof input) != sizeof input) abort();
}
static void *render_thread(void *unused) {
    (void)unused;
    float out[128];
    for (int i=0; i<1000; i++) {
        helix_audio_test_render(out, 128, 1);
        for (int j=0; j<128; j++) if (!isfinite(out[j]) || out[j] < -1 || out[j] > 1) abort();
    }
    return NULL;
}
int main(void) {
    helix_input_setup();
    /* Events queue in order and drain once. */
    helix_input_push(HELIX_EVENT_KEY,257,1,0,0); helix_input_push(HELIX_EVENT_KEY,257,0,0,0); helix_input_push(HELIX_EVENT_MOUSE_BUTTON,0,1,20,30);
    CHECK(helix_input_next() && helix_event_type()==HELIX_EVENT_KEY && helix_event_code()==257 && helix_event_value()==1);
    CHECK(helix_input_next() && helix_event_value()==0); CHECK(helix_input_next() && helix_event_type()==HELIX_EVENT_MOUSE_BUTTON && helix_event_x()==20 && helix_event_y()==30);
    CHECK(!helix_input_next());
    for (int i=0; i<1100; i++) helix_input_push(HELIX_EVENT_MOUSE_MOVE,0,0,(float)i,0);
    int drained=0; while (helix_input_next()) drained++; CHECK(drained==1024); /* A full queue drops the newest. */

    int pipefd[2]; CHECK(pipe(pipefd)==0); CHECK(fcntl(pipefd[0],F_SETFL,O_NONBLOCK)==0);
    helix_gamepad_test_connect(1,pipefd[0]); helix_gamepad_test_driver(1,1,0); /* xpad: X and Y report BTN_NORTH's and BTN_WEST's codes */
    helix_gamepad_test_range(1,ABS_X,-32768,32767,0); helix_gamepad_test_range(1,ABS_Y,-32768,32767,0);
    helix_gamepad_test_range(1,ABS_RX,-32768,32767,0); helix_gamepad_test_range(1,ABS_RY,-32768,32767,0);
    helix_gamepad_test_range(1,ABS_Z,0,255,0); helix_gamepad_test_range(1,ABS_RZ,0,255,0); helix_gamepad_test_range(1,ABS_HAT0X,-1,1,0); helix_gamepad_test_range(1,ABS_HAT0Y,-1,1,0);
    event(pipefd[1],EV_KEY,BTN_EAST,1); event(pipefd[1],EV_KEY,BTN_Y,1); event(pipefd[1],EV_ABS,ABS_X,-26000); event(pipefd[1],EV_ABS,ABS_RY,26000); event(pipefd[1],EV_ABS,ABS_RZ,200);
    helix_input_poll(); CHECK(!helix_pad_connected(0) && helix_pad_connected(1) && helix_pad_name(1)[0]);
    CHECK(helix_pad_button(1,1) && helix_pad_button(1,3) && !helix_pad_button(1,2) && helix_pad_axis(1,0)<-.7 && helix_pad_axis(1,3)>.7 && helix_pad_axis(1,5)>.7 && helix_pad_axis(1,4)==0);
    helix_gamepad_test_driver(1,0,0); CHECK(helix_pad_button(1,2) && !helix_pad_button(1,3)); helix_gamepad_test_driver(1,1,0); /* by the kernel's spec, BTN_Y (BTN_WEST) is West */
    event(pipefd[1],EV_ABS,ABS_HAT0X,-1); event(pipefd[1],EV_ABS,ABS_HAT0Y,1); helix_input_poll(); CHECK(helix_pad_button(1,14) && helix_pad_button(1,13) && !helix_pad_button(1,12));
    event(pipefd[1],EV_ABS,ABS_X,40000); event(pipefd[1],EV_KEY,BTN_EAST,0); helix_input_poll(); CHECK(helix_pad_axis(1,0)==1 && !helix_pad_button(1,1));
    close(pipefd[1]); helix_input_poll(); CHECK(!helix_pad_connected(1) && !helix_pad_button(1,1) && helix_pad_axis(1,5)==0);
    CHECK(pipe(pipefd)==0); CHECK(fcntl(pipefd[0],F_SETFL,O_NONBLOCK)==0); helix_gamepad_test_connect(0,pipefd[0]);
    helix_gamepad_test_range(0,ABS_RZ,0,255,200); CHECK(helix_pad_axis(0,5)>.7 && helix_pad_button(0,7) && helix_pad_axis(0,2)==0); /* RZ is the right trigger, a button past half way */
    helix_gamepad_test_range(0,ABS_Z,-32768,32767,-32768); helix_gamepad_test_range(0,ABS_RZ,-32768,32767,10000); helix_gamepad_test_driver(0,0,1);
    CHECK(helix_pad_axis(0,2)==-1 && helix_pad_axis(0,3)>.3 && helix_pad_axis(0,3)<.31 && helix_pad_axis(0,5)==0); helix_gamepad_test_driver(0,0,0); /* a generic HID pad's right stick on Z/RZ */
    event(pipefd[1],EV_KEY,BTN_TL2,1); helix_input_poll(); CHECK(helix_pad_button(0,6)); event(pipefd[1],EV_KEY,BTN_TL2,0); helix_input_poll(); CHECK(!helix_pad_button(0,6)); /* digital trigger */
    helix_gamepad_test_range(0,ABS_GAS,0,1023,800); CHECK(helix_pad_axis(0,5)>.7);
    helix_gamepad_test_range(0,ABS_X,0,0,0); CHECK(helix_pad_axis(0,0)==0);
    event(pipefd[1],EV_SYN,SYN_DROPPED,0); event(pipefd[1],EV_KEY,BTN_SOUTH,1); helix_input_poll(); CHECK(!helix_pad_button(0,0));
    event(pipefd[1],EV_SYN,SYN_REPORT,0); helix_input_poll(); CHECK(!helix_pad_connected(0)); /* Pipe cannot resync by ioctl; disconnect safely. */
    close(pipefd[1]); helix_input_shutdown();

    helix_audio_setup(); CHECK(helix_audio_available());
    float pcm[4]={.1f,-.1f,.2f,-.2f},out[16]; int clip=helix_audio_clip(pcm,sizeof pcm); CHECK(clip>0); pcm[0]=NAN;
    CHECK(helix_audio_play(0,0,.5f)==-1 && helix_audio_destroy_clip(0)==0);
    int voice=helix_audio_play(clip,1,.5f); CHECK(voice>0 && helix_audio_loops()==1);
    helix_audio_test_render(out,8,1); CHECK(fabsf(out[0]-.05f)<1e-6 && fabsf(out[4]-.05f)<1e-6 && helix_audio_loops()==1); /* Copied samples + wrapping. */
    helix_audio_stop(voice); CHECK(helix_audio_loops()==0 && helix_audio_stopped()==1); helix_audio_stop(voice); CHECK(helix_audio_stopped()==1);
    helix_audio_test_render(out,8,1); CHECK(out[0]==0 && out[7]==0);
    CHECK(helix_audio_clip(pcm,sizeof pcm)==0 && helix_audio_play(clip,0,2)==-1);
    voice=helix_audio_play(clip,0,1); CHECK(voice>0); helix_audio_test_render(out,8,1); CHECK(fabsf(out[2]-.2f)<1e-6 && out[4]==0); helix_audio_stop(voice); CHECK(helix_audio_stopped()==1);
    float full[2]={.9f,.9f}; int loud=helix_audio_clip(full,sizeof full); CHECK(loud>0);
    int one=helix_audio_play(loud,1,1),two=helix_audio_play(loud,1,1); CHECK(one>0 && two>0);
    helix_audio_test_render(out,8,2); CHECK(out[0]==1 && out[1]==1); CHECK(helix_audio_destroy_clip(loud)==1 && helix_audio_loops()==0);
    int voices[16]; for(int i=0;i<16;i++) voices[i]=helix_audio_play(clip,1,.1f); CHECK(voices[15]>0 && helix_audio_play(clip,1,1)==0);
    for(int i=0;i<16;i++) helix_audio_stop(voices[i]); CHECK(helix_audio_loops()==0);
    pthread_t thread; CHECK(pthread_create(&thread,NULL,render_thread,NULL)==0);
    for(int i=0;i<1000;i++) { int id=helix_audio_play(clip,1,.5f); helix_audio_stop(id); }
    CHECK(pthread_join(thread,NULL)==0);
    CHECK(helix_audio_destroy_clip(clip)==1 && helix_audio_play(clip,0,.5f)==-1 && helix_audio_destroy_clip(clip)==0); helix_audio_shutdown(); CHECK(!helix_audio_available());
    helix_audio_test_setup(48000); float ramp[4]={0,.25f,.5f,.75f}; clip=helix_audio_clip(ramp,sizeof ramp); CHECK(helix_audio_play(clip,1,1)>0);
    helix_audio_test_render(out,4,1); CHECK(fabsf(out[1]-(.25f*44100/48000))<1e-6); helix_audio_shutdown();
    helix_audio_setup();int stream=helix_audio_stream(.5f);CHECK(stream>0);
    float chunk[4]={.2f,.4f,-.2f,-.4f};CHECK(helix_audio_stream_push(stream,chunk,sizeof chunk,0)==4);CHECK(helix_audio_stream_queued(stream)==4);
    helix_audio_pause(stream,1);helix_audio_test_render(out,4,1);CHECK(out[0]==0&&helix_audio_stream_queued(stream)==4&&helix_audio_is_playing(stream));
    helix_audio_pause(stream,0);helix_audio_volume(stream,.25f);helix_audio_test_render(out,4,1);CHECK(fabsf(out[1]-.1f)<1e-6&&helix_audio_stream_queued(stream)==0);
    helix_audio_test_render(out,4,1);CHECK(out[0]==0&&helix_audio_is_playing(stream)); /* Underrun waits without finishing. */
    CHECK(helix_audio_stream_push(stream,chunk,sizeof chunk,1)==4);helix_audio_test_render(out,8,1);CHECK(!helix_audio_is_playing(stream));
    stream=helix_audio_stream(1);float *many=calloc(9000,sizeof(float));CHECK(helix_audio_stream_push(stream,many,9000*sizeof(float),1)==8192&&helix_audio_stream_queued(stream)==8192);free(many);
    helix_audio_stop(stream);CHECK(!helix_audio_is_playing(stream)&&helix_audio_stream_queued(stream)==-1);helix_audio_shutdown();
    printf("{\"passed\":true,\"checks\":%d,\"controller\":\"Pipe-fed evdev records; no kernel virtual-device or physical-controller claim\",\"audio\":\"Sokol dummy backend with mixer callback, concurrency and resampling checks; no audible-output claim\"}\n",checks);
    return 0;
}
