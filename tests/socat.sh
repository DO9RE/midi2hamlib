#!/bin/bash

# Make sure to install socat: sudo apt install socat

process_one() {
  while true; do
    echo "Nachricht von Prozess 1: $(date +"%T")" | socat - TCP:localhost:12345
    response=$(echo "ACK" | socat TCP:localhost:12345 -)
    echo "Prozess 1 empfängt: $response"
    sleep 10
  done
}

process_two() {
  while true; do
    echo "Nachricht von Prozess 2: $(date +"%T")" | socat - TCP:localhost:12345
    response=$(echo "ACK" | socat TCP:localhost:12345 -)
    echo "Prozess 2 empfängt: $response"
    sleep 10
  done
}

start_server() {
  socat TCP-LISTEN:12345,reuseaddr,fork SYSTEM:"while read line; do echo \"Server empfängt: \$line\"; echo \"Antwort vom Server: \$line\"; done"
}

start_server &
server_pid=$!

process_one &
process_two &

# Suppress warning to use single quotes.
# shellcheck disable=SC2064
trap "kill $server_pid; exit" INT TERM
wait
