#!/usr/bin/env bash
case "$1" in
  server)
    ./bin/phone ${2:-50000}
    ;;
  call)
    if [ -z "$2" ]; then
      echo "Usage: $0 call <ip> [port]"; exit 1
    fi
    ./bin/phone $2 ${3:-50000}
    ;;
  *)
    echo "Usage:"
    echo "  $0 server [port]       wait for incoming call"
    echo "  $0 call <ip> [port]    call someone"
    exit 1
    ;;
esac
