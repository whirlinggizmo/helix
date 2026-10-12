#include "hybrid.h"
#include <stdio.h>
#include <time.h>
#define SOKOL_LOG_IMPL
#include "sokol_log.h"
int main(void) {
    hy_audio_setup();
    if (!hy_audio_available()) { hy_audio_shutdown(); return 2; }
    const float silence[4]={0};
    const int clip=hy_audio_clip(silence,sizeof silence),voice=hy_audio_play(clip,1,1);
    const int before=hy_audio_callbacks();
    for (int i=0;i<100 && hy_audio_callbacks()<before+2;i++) {
        const struct timespec wait={.tv_nsec=10000000}; nanosleep(&wait,NULL);
    }
    const int after=hy_audio_callbacks(),rate=hy_audio_sample_rate(),channels=hy_audio_channels();
    hy_audio_stop(voice); hy_audio_destroy_clip(clip); hy_audio_shutdown();
    printf("{\"passed\":%s,\"backend\":\"sokol_audio ALSA\",\"callbacks\":%d,\"sampleRate\":%d,\"channels\":%d,\"audio\":\"Silence only; no audible-output claim\"}\n",
        after>=before+2?"true":"false",after-before,rate,channels);
    return after>=before+2?0:3;
}
