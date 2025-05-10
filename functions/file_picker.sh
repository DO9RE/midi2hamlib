#!/bin/bash
file_picker_result=""
# Do we have a directory?
if [ -z "$1" ]; then
  echo "Please pass directory"
  exit 1
fi

# Set start directory
start_dir=$(realpath "$1")
current_dir="$start_dir"

while true; do
  echo "Directory: $current_dir"
  echo "0: Go back"
  echo "1: Up one directory"

# List files and folders
  index=2
  for item in "$current_dir"/*; do
    if [ -d "$item" ]; then
      echo "$index: $(basename "$item") (folder)"
    else
      echo "$index: $(basename "$item")"
    fi
    ((index++))
  done

# Fetch user input
  read -rp "Your choice: " choice

# Quit if 0 is given
  if [ "$choice" -eq 0 ]; then
    echo "Returning to interface"
    return 0
  fi

# Up one level, if 1 is given, but not beyond the starting directory
  if [ "$choice" -eq 1 ]; then
    if [ "$current_dir" != "$start_dir" ]; then
      current_dir=$(dirname "$current_dir")
    else
      echo "Already at top level."
    fi
    continue
  fi

# Run through files and folders, to find the selection
  index=2
  for item in "$current_dir"/*; do
    if [ "$choice" -eq "$index" ]; then
      if [ -d "$item" ]; then
        current_dir="$item"
      else
#       Output file to stdout
        # shellcheck disable=SC2034
        file_picker_result="$item"
        return 0
      fi
      break
    fi
    ((index++))
  done
done

