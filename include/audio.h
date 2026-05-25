#pragma once
#include <sox.h>

#define AUDIO_RATE     44100
#define AUDIO_CHANNELS 1
#define AUDIO_BITS     16
#define AUDIO_BUFSIZE  4096

sox_format_t *audio_open_input(void);
sox_format_t *audio_open_output(void);
int audio_read_to_fd(sox_format_t *in, int fd);
int audio_write_from_fd(int fd, sox_format_t *out);
