#include "webrtc_agc.h"
#include "agc.h"

#ifndef MIN
#define  MIN(A, B)        ((A) < (B) ? (A) : (B))
#endif

FFI_PLUGIN_EXPORT void *webrtc_agc_init(int minLevel, int maxLevel, int sampleRate, int mode) {
    void *handle = WebRtcAgc_Create();
    int ret = WebRtcAgc_Init(handle, minLevel, maxLevel, mode, sampleRate);
    if (ret != 0) {
        WebRtcAgc_Free(handle);
        return NULL;
    }
    return handle;
}


FFI_PLUGIN_EXPORT int
webrtc_agc_set_config(void *handle, int targetLevelDbfs, int compressionGaindB, int limiterEnable) {
    if (handle != NULL) {
        WebRtcAgcConfig agcConfig;
        agcConfig.compressionGaindB = compressionGaindB; // default 9 dB
        agcConfig.limiterEnable = limiterEnable; // default kAgcTrue (on)
        agcConfig.targetLevelDbfs = targetLevelDbfs; // default 3 (-3 dBOv)
        int ret = WebRtcAgc_set_config(handle, agcConfig);
        if (ret != 0) {
            return ret;
        }
        return 0;
    }
    return -1;
}

FFI_PLUGIN_EXPORT void webrtc_agc_destroy(void *handle) {
    if (handle != NULL) {
        WebRtcAgc_Free(handle);
        handle = NULL;
    }
}

FFI_PLUGIN_EXPORT int webrtc_agc_process(void *handle,int16_t *src_audio_data, int64_t length) {
    if (handle != NULL) {
        LegacyAgc* mHandle = (LegacyAgc*)handle;
        size_t samples = MIN(160, mHandle->fs / 100);
        const int maxSamples = 320;
        int16_t *input = src_audio_data;
        size_t nTotal = (length / samples);
        size_t num_bands = 1;
        int inMicLevel, outMicLevel = -1;
        int16_t out_buffer[maxSamples];
        int16_t *out16 = out_buffer;
        uint8_t saturationWarning = 1;                 //是否有溢出发生，增益放大以后的最大值超过了65536
        int16_t echo = 0;                                 //增益放大是否考虑回声影响
        for (int i = 0; i < nTotal; i++) {
            inMicLevel = 0;
            int nAgcRet = WebRtcAgc_Process(mHandle, (const int16_t *const *) &input, num_bands,
                                            samples,
            (int16_t *const *) &out16, inMicLevel, &outMicLevel, echo,
                    &saturationWarning);

            if (nAgcRet != 0) {
                return -1;
            }
            memcpy(input, out_buffer, samples * sizeof(int16_t));
            input += samples;
        }
        const size_t remainedSamples = length - nTotal * samples;
        if (remainedSamples > 0) {
            if (nTotal > 0) {
                input = input - samples + remainedSamples;
            }

            inMicLevel = 0;
            int nAgcRet = WebRtcAgc_Process(mHandle, (const int16_t *const *) &input, num_bands,
                                            samples,
            (int16_t *const *) &out16, inMicLevel, &outMicLevel, echo,
                    &saturationWarning);

            if (nAgcRet != 0) {
                return -1;
            }
            memcpy(&input[samples - remainedSamples], &out_buffer[samples - remainedSamples],
                   remainedSamples * sizeof(int16_t));
            input += samples;
        }
        return 0;
    }

    return -1;

}