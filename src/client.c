#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include "net.h"
#include "client.h"

int client_connect(const char *ip, int port) {
    int s = socket(PF_INET, SOCK_STREAM, 0);
    if (s == -1) die("socket");

    struct sockaddr_in addr = {
        .sin_family = AF_INET,
        .sin_port   = htons(port),
    };
    if (inet_aton(ip, &addr.sin_addr) == 0) {
        fprintf(stderr, "invalid IP: %s\n", ip);
        exit(1);
    }

    fprintf(stderr, "Calling %s:%d ...\n", ip, port);
    if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) == -1) die("connect");
    return s;
}
