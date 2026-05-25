#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/wait.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/tcp.h>

#define REC_CMD  "rec -t raw -b 16 -c 1 -e s -r 44100 -"
#define PLAY_CMD "play -t raw -b 16 -c 1 -e s -r 44100 -"

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

int main(int argc, char **argv) {
    int s;

    if (argc == 2) {
        int ss = socket(PF_INET, SOCK_STREAM, 0);
        if (ss == -1) die("socket");

        struct sockaddr_in addr;
        addr.sin_family = AF_INET;
        addr.sin_port = htons(atoi(argv[1]));
        addr.sin_addr.s_addr = INADDR_ANY;

        if (bind(ss, (struct sockaddr *)&addr, sizeof(addr)) == -1) die("bind");
        if (listen(ss, 10) == -1) die("listen");

        fprintf(stderr, "Waiting for call on port %s ...\n", argv[1]);
        s = accept(ss, NULL, NULL);
        if (s == -1) die("accept");
        close(ss);

    } else if (argc == 3) {
        s = socket(PF_INET, SOCK_STREAM, 0);
        if (s == -1) die("socket");

        struct sockaddr_in addr;
        addr.sin_family = AF_INET;
        addr.sin_port = htons(atoi(argv[2]));
        if (inet_aton(argv[1], &addr.sin_addr) == 0) {
            fprintf(stderr, "invalid IP: %s\n", argv[1]);
            exit(1);
        }

        fprintf(stderr, "Calling %s:%s ...\n", argv[1], argv[2]);
        if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) == -1) die("connect");

    } else {
        fprintf(stderr, "Usage: %s <port>           (server)\n", argv[0]);
        fprintf(stderr, "       %s <ip> <port>      (client)\n", argv[0]);
        exit(1);
    }

    fprintf(stderr, "Connected.\n");

    /* start rec and play AFTER connection — avoids buffered audio delay */
    FILE *rec  = popen(REC_CMD,  "r");
    if (!rec)  die("popen rec");
    FILE *play = popen(PLAY_CMD, "w");
    if (!play) die("popen play");

    pid_t pid = fork();
    if (pid == -1) die("fork");

    if (pid == 0) {
        /* child: socket → play */
        forward(s, fileno(play));
        pclose(play);
        exit(0);
    } else {
        /* parent: rec → socket */
        forward(fileno(rec), s);
        pclose(rec);
        close(s);
        wait(NULL);
    }

    return 0;
}
