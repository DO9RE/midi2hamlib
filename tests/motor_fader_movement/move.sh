#!/bin/bash

MIDI_DEVICE="hw:1,0,0" 
FADER_POSITION=64 # Example position, middle

for FADER_NUMBER in {1..4}; do
# Format: [B0 | Fader Number] [Controller Number] [Value]
  MIDI_MESSAGE=$(printf "B0 %02x %02x" "$FADER_NUMBER" "$FADER_POSITION")
  echo "Fader $FADER_NUMBER: $MIDI_MESSAGE"
  amidi -p "$MIDI_DEVICE" -S "$MIDI_MESSAGE"
done
