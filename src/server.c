#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include "net.h"
#include "server.h"

int server_listen(int port) {
    int ss = socket(PF_INET, SOCK_STREAM, 0);
    if (ss == -1) die("socket");

    int opt = 1;
    setsockopt(ss, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr = {
        .sin_family      = AF_INET,
        .sin_port        = htons(port),
        .sin_addr.s_addr = INADDR_ANY,
    };
    if (bind(ss, (struct sockaddr *)&addr, sizeof(addr)) == -1) die("bind");
    if (listen(ss, 10) == -1) die("listen");

    fprintf(stderr, "Waiting for call on port %d ...\n", port);
    int s = accept(ss, NULL, NULL);
    if (s == -1) die("accept");
    close(ss);
    return s;
}
