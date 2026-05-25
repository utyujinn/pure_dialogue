#include <stddef.h>
#include <sox.h>
#include "process.h"

/* audio processing pipeline — called on each captured chunk before sending */
void process(sox_sample_t *buf, size_t n) {
    (void)buf;
    (void)n;
}
