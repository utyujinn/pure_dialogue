#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "net.h"

void die(const char *s) {
    perror(s);
    exit(1);
}

void forward(int from, int to) {
    unsigned char buf[4096];
    int n;
    while (1) {
        n = read(from, buf, sizeof(buf));
        if (n <= 0) break;
        int w = 0;
        while (w < n) {
            int r = write(to, buf + w, n - w);
            if (r == -1) break;
            w += r;
        }
    }
}
