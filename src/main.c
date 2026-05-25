#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sox.h>
#include "net.h"
#include "server.h"
#include "client.h"
#include "audio.h"

int main(int argc, char **argv) {
    int s;

    if (argc == 2) {
        s = server_listen(atoi(argv[1]));
    } else if (argc == 3) {
        s = client_connect(argv[1], atoi(argv[2]));
    } else {
        fprintf(stderr, "Usage: %s <port>           (server)\n", argv[0]);
        fprintf(stderr, "       %s <ip> <port>      (client)\n", argv[0]);
        return 1;
    }

    fprintf(stderr, "Connected.\n");

    if (sox_init() != SOX_SUCCESS) die("sox_init");

    sox_format_t *mic = audio_open_input();
    sox_format_t *spk = audio_open_output();

    pid_t pid = fork();
    if (pid == -1) die("fork");

    if (pid == 0) {
        /* child: network → speaker */
        audio_write_from_fd(s, spk);
        sox_close(spk);
        sox_quit();
        exit(0);
    } else {
        /* parent: mic → network */
        audio_read_to_fd(mic, s);
        sox_close(mic);
        close(s);
        wait(NULL);
        sox_quit();
    }

    return 0;
}
