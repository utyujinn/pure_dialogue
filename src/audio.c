#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <sox.h>
#include "audio.h"
#include "net.h"
#include "process.h"

/* override at compile time with -DAUDIO_DRIVER=pulse etc. */
#ifndef AUDIO_DRIVER
#  ifdef __APPLE__
#    define AUDIO_DRIVER "coreaudio"
#  else
#    define AUDIO_DRIVER "alsa"
#  endif
#endif

static const sox_signalinfo_t sig = {
    .rate      = AUDIO_RATE,
    .channels  = AUDIO_CHANNELS,
    .precision = AUDIO_BITS,
    .length    = SOX_UNSPEC,
};

static const sox_encodinginfo_t enc = {
    .encoding        = SOX_ENCODING_SIGN2,
    .bits_per_sample = AUDIO_BITS,
};

sox_format_t *audio_open_input(void) {
    sox_format_t *ft = sox_open_read("default", &sig, &enc, AUDIO_DRIVER);
    if (!ft) die("audio_open_input");
    return ft;
}

sox_format_t *audio_open_output(void) {
    sox_format_t *ft = sox_open_write("default", &sig, &enc, AUDIO_DRIVER, NULL, NULL);
    if (!ft) die("audio_open_output");
    return ft;
}

int audio_read_to_fd(sox_format_t *in, int fd) {
    sox_sample_t buf[AUDIO_BUFSIZE];
    int16_t raw[AUDIO_BUFSIZE];

    size_t n;
    while ((n = sox_read(in, buf, AUDIO_BUFSIZE)) > 0) {
        process(buf, n);

        SOX_SAMPLE_LOCALS;
        size_t clips = 0;
        for (size_t i = 0; i < n; i++)
            raw[i] = SOX_SAMPLE_TO_SIGNED_16BIT(buf[i], clips);

        int bytes = (int)(n * sizeof(int16_t));
        int w = 0;
        while (w < bytes) {
            int r = write(fd, (char *)raw + w, bytes - w);
            if (r <= 0) return -1;
            w += r;
        }
    }
    return 0;
}

int audio_write_from_fd(int fd, sox_format_t *out) {
    int16_t raw[AUDIO_BUFSIZE];
    sox_sample_t buf[AUDIO_BUFSIZE];

    while (1) {
        int r = read(fd, raw, sizeof(raw));
        if (r <= 0) break;
        size_t n = (size_t)r / sizeof(int16_t);
        for (size_t i = 0; i < n; i++)
            buf[i] = SOX_SIGNED_TO_SAMPLE(16, raw[i]);
        if (sox_write(out, buf, n) != n) break;
    }
    return 0;
}
