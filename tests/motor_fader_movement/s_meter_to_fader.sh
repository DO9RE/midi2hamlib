#!/bin/bash

MIDI_DEVICE="hw:1,0,0" 

calculate_fader_position() {
  local strength_db=$1
  local position
  position=$(echo "100 + $strength_db" | bc)
  local midi_position=$(( position * 127 / 100 ))
  echo "$midi_position"
}

while true; do
  strength=$(rigctl -m 1 l STRENGTH)
  fader_position=$(calculate_fader_position "$strength")
  MIDI_MESSAGE=$(printf "B0 01 %02x" "$fader_position")
  echo "STRENGTH: $strength dB -> Fader-Position: $fader_position -> MIDI: $MIDI_MESSAGE"
  amidi -p "$MIDI_DEVICE" -S "$MIDI_MESSAGE"
  sleep 1
done
