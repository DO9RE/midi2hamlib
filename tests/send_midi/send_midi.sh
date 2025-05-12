#!/bin/bash

# Function to show usage instructions
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -p, --port <port>       Specify the MIDI port (name or identifier, e.g., 'hw:3,0,0' or 'MIDI Device Name')."
  echo "  -l, --list              List all available MIDI ports."
  echo "  -s, --send <event>      Send a MIDI event in human-readable format, such as:"
  echo "                          'noteon 1 60 127' for Note On, channel 1, note 60, velocity 127."
  echo "                          'noteoff 1 60 64' for Note Off, channel 1, note 60, velocity 64."
  echo "                          'cc 1 10 127' for Control Change, channel 1, controller 10, value 127."
  echo "  -h, --help              Show this help message and exit."
}

# Function to list available MIDI ports
list_ports() {
  echo "Available MIDI ports:"
  amidi -l
}

# Function to convert a human-readable MIDI event to a hexadecimal MIDI message
convert_to_hex() {
  local event_type="$1"
  local channel="$2"
  local param1="$3"
  local param2="$4"

  # Convert channel to the correct MIDI channel value (0-15)
  if [[ "$channel" -lt 1 || "$channel" -gt 16 ]]; then
    echo "Error: MIDI channel must be between 1 and 16."
    exit 1
  fi
  local midi_channel=$((channel - 1))

  # Determine the event type and construct the message
  case "$event_type" in
    noteon|on)
      local status=$((0x90 + midi_channel))
      ;;
    noteoff|off)
      local status=$((0x80 + midi_channel))
      ;;
    controlchange|cc)
      local status=$((0xB0 + midi_channel))
      ;;
    *)
      echo "Error: Unsupported event type '$event_type'. Supported types are 'noteon', 'noteoff', and 'cc'."
      exit 1
      ;;
  esac

  # Ensure parameters are valid (0-127)
  if [[ "$param1" -lt 0 || "$param1" -gt 127 || "$param2" -lt 0 || "$param2" -gt 127 ]]; then
    echo "Error: Parameters must be between 0 and 127."
    exit 1
  fi

  # Construct the hex message
  printf "%02X %02X %02X" "$status" "$param1" "$param2"
}

# Function to resolve the port if a name is provided
resolve_port() {
  local port_input="$1"
  local resolved_port=""

  # Check if the input matches the hw:X,Y,Z format
  if [[ "$port_input" =~ ^hw:[0-9]+,[0-9]+,[0-9]+$ ]]; then
    echo "$port_input"
    return
  fi

  # Search for the port name in the output of `amidi -l`
  resolved_port=$(amidi -l | grep -i "$port_input" | awk '{print $2}')

  if [[ -z "$resolved_port" ]]; then
    echo "Error: Could not find a MIDI port matching '$port_input'."
    exit 1
  fi

  echo "$resolved_port"
}

# Parse command-line arguments
PORT=""
EVENT_TYPE=""
CHANNEL=""
PARAM1=""
PARAM2=""
COMMAND=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port)
      PORT="$2"
      shift 2
      ;;
    -l|--list)
      COMMAND="list"
      shift
      ;;
    -s|--send)
      COMMAND="send"
      IFS=' ' read -r EVENT_TYPE CHANNEL PARAM1 PARAM2 <<< "$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'"
      usage
      exit 1
      ;;
  esac
done

# Execute the appropriate command
case "$COMMAND" in
  "list")
    list_ports
    ;;
  "send")
    if [[ -z "$PORT" ]]; then
      echo "Error: MIDI port must be specified with -p or --port."
      usage
      exit 1
    fi
    if [[ -z "$EVENT_TYPE" || -z "$CHANNEL" || -z "$PARAM1" || -z "$PARAM2" ]]; then
      echo "Error: MIDI event must be fully specified with type, channel, and parameters."
      usage
      exit 1
    fi

    # Resolve the port name or identifier
    RESOLVED_PORT=$(resolve_port "$PORT")
    HEX_MESSAGE=$(convert_to_hex "$EVENT_TYPE" "$CHANNEL" "$PARAM1" "$PARAM2")

    echo "Sending MIDI message: $HEX_MESSAGE to port: $RESOLVED_PORT"
    # Send the message using amidi --send-hex
    amidi --port="$RESOLVED_PORT" --send-hex="$HEX_MESSAGE"
    ;;
  *)
    echo "Error: No valid command provided."
    usage
    exit 1
    ;;
esac
