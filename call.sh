#!/usr/bin/env bash
PORT=${3:-50001}
REC="rec -t raw -b 16 -c 1 -e s -r 44100 -"
PLAY="play -t raw -b 16 -c 1 -e s -r 44100 -"

case "$1" in
  server)
    PORT=${2:-50001}
    echo "Waiting for call on port $PORT ..."
    $REC | ./phone $PORT | $PLAY
    ;;
  call)
    if [ -z "$2" ]; then
      echo "Usage: $0 call <ip> [port]"; exit 1
    fi
    echo "Calling $2:$PORT ..."
    $REC | ./phone $2 $PORT | $PLAY
    ;;
  *)
    echo "Usage:"
    echo "  $0 server [port]       wait for incoming call"
    echo "  $0 call <ip> [port]    call someone"
    exit 1
    ;;
esac
