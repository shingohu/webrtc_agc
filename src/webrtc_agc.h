#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else

#include <pthread.h>
#include <unistd.h>

#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT void *webrtc_agc_init(int minLevel, int maxLevel, int sampleRate, int mode);

FFI_PLUGIN_EXPORT int
webrtc_agc_set_config(void *handle,int targetLevelDbfs, int compressionGaindB, int limiterEnable);

FFI_PLUGIN_EXPORT int webrtc_agc_process(void *handle,int16_t *src_audio_data, int64_t length);


FFI_PLUGIN_EXPORT void webrtc_agc_destroy(void *handle);

