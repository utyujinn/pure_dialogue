CC      = cc
CFLAGS  = -Wall -Wextra -g -I./include $(shell pkg-config --cflags sox)
ARFLAGS = rcs

LIB_SRCS = src/server.c src/client.c src/audio.c src/process.c src/net.c
LIB_OBJS = $(LIB_SRCS:.c=.o)
LIB      = lib/libphone.a
TARGET   = bin/phone

.PHONY: all clean
all: $(TARGET)

$(TARGET): src/main.o $(LIB) | bin
	$(CC) src/main.o -L./lib -lphone $(shell pkg-config --libs sox) -o $@

$(LIB): $(LIB_OBJS) | lib
	ar $(ARFLAGS) $@ $^

$(LIB_OBJS): src/%.o: src/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

src/main.o: src/main.c
	$(CC) $(CFLAGS) -c -o $@ $<

bin lib:
	mkdir -p $@

clean:
	rm -f $(LIB_OBJS) src/main.o $(LIB) $(TARGET)
