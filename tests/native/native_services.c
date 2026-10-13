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
        hy_audio_test_render(out, 128, 1);
        for (int j=0; j<128; j++) if (!isfinite(out[j]) || out[j] < -1 || out[j] > 1) abort();
    }
    return NULL;
}
int main(void) {
    hy_input_setup();
    /* Events queue in order and drain once; focus changes are tracked as they are queued. */
    hy_input_push(HY_EVENT_KEY,257,1,0,0); hy_input_push(HY_EVENT_KEY,257,0,0,0); hy_input_push(HY_EVENT_MOUSE_BUTTON,0,1,20,30);
    CHECK(hy_input_next() && hy_event_type()==HY_EVENT_KEY && hy_event_code()==257 && hy_event_value()==1);
    CHECK(hy_input_next() && hy_event_value()==0); CHECK(hy_input_next() && hy_event_type()==HY_EVENT_MOUSE_BUTTON && hy_event_x()==20 && hy_event_y()==30);
    CHECK(!hy_input_next());
    for (int i=0; i<1100; i++) hy_input_push(HY_EVENT_MOUSE_MOVE,0,0,(float)i,0);
    int drained=0; while (hy_input_next()) drained++; CHECK(drained==1024); /* A full queue drops the newest. */
    hy_input_push(HY_EVENT_FOCUS,0,0,0,0); CHECK(!hy_focused()); hy_input_push(HY_EVENT_FOCUS,0,1,0,0); CHECK(hy_focused()); while (hy_input_next()) {}

    int pipefd[2]; CHECK(pipe(pipefd)==0); CHECK(fcntl(pipefd[0],F_SETFL,O_NONBLOCK)==0);
    hy_gamepad_test_connect(1,pipefd[0]); hy_gamepad_test_driver(1,1,0); /* xpad: X and Y report BTN_NORTH's and BTN_WEST's codes */
    hy_gamepad_test_range(1,ABS_X,-32768,32767,0); hy_gamepad_test_range(1,ABS_Y,-32768,32767,0);
    hy_gamepad_test_range(1,ABS_RX,-32768,32767,0); hy_gamepad_test_range(1,ABS_RY,-32768,32767,0);
    hy_gamepad_test_range(1,ABS_Z,0,255,0); hy_gamepad_test_range(1,ABS_RZ,0,255,0); hy_gamepad_test_range(1,ABS_HAT0X,-1,1,0); hy_gamepad_test_range(1,ABS_HAT0Y,-1,1,0);
    event(pipefd[1],EV_KEY,BTN_EAST,1); event(pipefd[1],EV_KEY,BTN_Y,1); event(pipefd[1],EV_ABS,ABS_X,-26000); event(pipefd[1],EV_ABS,ABS_RY,26000); event(pipefd[1],EV_ABS,ABS_RZ,200);
    hy_input_poll(); CHECK(!hy_pad_connected(0) && hy_pad_connected(1) && hy_pad_name(1)[0]);
    CHECK(hy_pad_button(1,1) && hy_pad_button(1,3) && !hy_pad_button(1,2) && hy_pad_axis(1,0)<-.7 && hy_pad_axis(1,3)>.7 && hy_pad_axis(1,5)>.7 && hy_pad_axis(1,4)==0);
    hy_gamepad_test_driver(1,0,0); CHECK(hy_pad_button(1,2) && !hy_pad_button(1,3)); hy_gamepad_test_driver(1,1,0); /* by the kernel's spec, BTN_Y (BTN_WEST) is West */
    event(pipefd[1],EV_ABS,ABS_HAT0X,-1); event(pipefd[1],EV_ABS,ABS_HAT0Y,1); hy_input_poll(); CHECK(hy_pad_button(1,14) && hy_pad_button(1,13) && !hy_pad_button(1,12));
    hy_input_push(HY_EVENT_FOCUS,0,0,0,0); CHECK(!hy_pad_button(1,1) && hy_pad_axis(1,0)==0); hy_input_push(HY_EVENT_FOCUS,0,1,0,0); while (hy_input_next()) {}
    event(pipefd[1],EV_ABS,ABS_X,40000); event(pipefd[1],EV_KEY,BTN_EAST,0); hy_input_poll(); CHECK(hy_pad_axis(1,0)==1 && !hy_pad_button(1,1));
    close(pipefd[1]); hy_input_poll(); CHECK(!hy_pad_connected(1) && !hy_pad_button(1,1) && hy_pad_axis(1,5)==0);
    CHECK(pipe(pipefd)==0); CHECK(fcntl(pipefd[0],F_SETFL,O_NONBLOCK)==0); hy_gamepad_test_connect(0,pipefd[0]);
    hy_gamepad_test_range(0,ABS_RZ,0,255,200); CHECK(hy_pad_axis(0,5)>.7 && hy_pad_button(0,7) && hy_pad_axis(0,2)==0); /* RZ is the right trigger, a button past half way */
    hy_gamepad_test_range(0,ABS_Z,-32768,32767,-32768); hy_gamepad_test_range(0,ABS_RZ,-32768,32767,10000); hy_gamepad_test_driver(0,0,1);
    CHECK(hy_pad_axis(0,2)==-1 && hy_pad_axis(0,3)>.3 && hy_pad_axis(0,3)<.31 && hy_pad_axis(0,5)==0); hy_gamepad_test_driver(0,0,0); /* a generic HID pad's right stick on Z/RZ */
    event(pipefd[1],EV_KEY,BTN_TL2,1); hy_input_poll(); CHECK(hy_pad_button(0,6)); event(pipefd[1],EV_KEY,BTN_TL2,0); hy_input_poll(); CHECK(!hy_pad_button(0,6)); /* digital trigger */
    hy_gamepad_test_range(0,ABS_GAS,0,1023,800); CHECK(hy_pad_axis(0,5)>.7);
    hy_gamepad_test_range(0,ABS_X,0,0,0); CHECK(hy_pad_axis(0,0)==0);
    event(pipefd[1],EV_SYN,SYN_DROPPED,0); event(pipefd[1],EV_KEY,BTN_SOUTH,1); hy_input_poll(); CHECK(!hy_pad_button(0,0));
    event(pipefd[1],EV_SYN,SYN_REPORT,0); hy_input_poll(); CHECK(!hy_pad_connected(0)); /* Pipe cannot resync by ioctl; disconnect safely. */
    close(pipefd[1]); hy_input_shutdown();

    hy_audio_setup(); CHECK(hy_audio_available());
    float pcm[4]={.1f,-.1f,.2f,-.2f},out[16]; int clip=hy_audio_clip(pcm,sizeof pcm); CHECK(clip>0); pcm[0]=NAN;
    CHECK(hy_audio_play(0,0,.5f)==-1 && hy_audio_destroy_clip(0)==0);
    int voice=hy_audio_play(clip,1,.5f); CHECK(voice>0 && hy_audio_loops()==1);
    hy_audio_test_render(out,8,1); CHECK(fabsf(out[0]-.05f)<1e-6 && fabsf(out[4]-.05f)<1e-6 && hy_audio_loops()==1); /* Copied samples + wrapping. */
    hy_audio_stop(voice); CHECK(hy_audio_loops()==0 && hy_audio_stopped()==1); hy_audio_stop(voice); CHECK(hy_audio_stopped()==1);
    hy_audio_test_render(out,8,1); CHECK(out[0]==0 && out[7]==0);
    CHECK(hy_audio_clip(pcm,sizeof pcm)==0 && hy_audio_play(clip,0,2)==-1);
    voice=hy_audio_play(clip,0,1); CHECK(voice>0); hy_audio_test_render(out,8,1); CHECK(fabsf(out[2]-.2f)<1e-6 && out[4]==0); hy_audio_stop(voice); CHECK(hy_audio_stopped()==1);
    float full[2]={.9f,.9f}; int loud=hy_audio_clip(full,sizeof full); CHECK(loud>0);
    int one=hy_audio_play(loud,1,1),two=hy_audio_play(loud,1,1); CHECK(one>0 && two>0);
    hy_audio_test_render(out,8,2); CHECK(out[0]==1 && out[1]==1); CHECK(hy_audio_destroy_clip(loud)==1 && hy_audio_loops()==0);
    int voices[16]; for(int i=0;i<16;i++) voices[i]=hy_audio_play(clip,1,.1f); CHECK(voices[15]>0 && hy_audio_play(clip,1,1)==0);
    for(int i=0;i<16;i++) hy_audio_stop(voices[i]); CHECK(hy_audio_loops()==0);
    pthread_t thread; CHECK(pthread_create(&thread,NULL,render_thread,NULL)==0);
    for(int i=0;i<1000;i++) { int id=hy_audio_play(clip,1,.5f); hy_audio_stop(id); }
    CHECK(pthread_join(thread,NULL)==0);
    CHECK(hy_audio_destroy_clip(clip)==1 && hy_audio_play(clip,0,.5f)==-1 && hy_audio_destroy_clip(clip)==0); hy_audio_shutdown(); CHECK(!hy_audio_available());
    hy_audio_test_setup(48000); float ramp[4]={0,.25f,.5f,.75f}; clip=hy_audio_clip(ramp,sizeof ramp); CHECK(hy_audio_play(clip,1,1)>0);
    hy_audio_test_render(out,4,1); CHECK(fabsf(out[1]-(.25f*44100/48000))<1e-6); hy_audio_shutdown();
    hy_audio_setup();int stream=hy_audio_stream(.5f);CHECK(stream>0);
    float chunk[4]={.2f,.4f,-.2f,-.4f};CHECK(hy_audio_stream_push(stream,chunk,sizeof chunk,0)==4);CHECK(hy_audio_stream_queued(stream)==4);
    hy_audio_pause(stream,1);hy_audio_test_render(out,4,1);CHECK(out[0]==0&&hy_audio_stream_queued(stream)==4&&hy_audio_is_playing(stream));
    hy_audio_pause(stream,0);hy_audio_volume(stream,.25f);hy_audio_test_render(out,4,1);CHECK(fabsf(out[1]-.1f)<1e-6&&hy_audio_stream_queued(stream)==0);
    hy_audio_test_render(out,4,1);CHECK(out[0]==0&&hy_audio_is_playing(stream)); /* Underrun waits without finishing. */
    CHECK(hy_audio_stream_push(stream,chunk,sizeof chunk,1)==4);hy_audio_test_render(out,8,1);CHECK(!hy_audio_is_playing(stream));
    stream=hy_audio_stream(1);float *many=calloc(9000,sizeof(float));CHECK(hy_audio_stream_push(stream,many,9000*sizeof(float),1)==8192&&hy_audio_stream_queued(stream)==8192);free(many);
    hy_audio_stop(stream);CHECK(!hy_audio_is_playing(stream)&&hy_audio_stream_queued(stream)==-1);hy_audio_shutdown();
    printf("{\"passed\":true,\"checks\":%d,\"controller\":\"Pipe-fed evdev records; no kernel virtual-device or physical-controller claim\",\"audio\":\"Sokol dummy backend with mixer callback, concurrency and resampling checks; no audible-output claim\"}\n",checks);
    return 0;
}
