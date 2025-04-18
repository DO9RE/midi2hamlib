#!/bin/bash

file="$1" # The MIDI map
funcdir="$2" # coming from stard, passed to file_selection.sh

# function to display the midi map linewise
function show_file {
# show file with numbered lines from line 2 on
  echo "file contents:"
  tail -n +2 "$file" | nl -w2 -s" "  
}

# function to get the field headers
function get_headers {
  read -r header_line < "$file"
  ifs=' ' read -r -a headers <<< "$header_line"
}

# function to display the editors main menu
function main_menu {
  while true; do
    clear
    show_file
    echo "midi map editor menu"
    echo "0 = exit editor."
    echo "enter line number to edit:"
    read -r menu_index

    if [[ "$menu_index" == "0" ]]; then
      echo "leaving editor"
      exit 0
    fi

    if ! [[ "$menu_index" =~ ^[0-9]+$ ]] || (( menu_index < 1 )); then
      echo "invalid line number."
      read -p "press enter to continue."
      continue
    fi
#   skip header line
    line_number=$((menu_index + 1))
    edit_menu "$line_number"
  done
}

# function for edit menu
function edit_menu {
  local line_number=$1
  local line
  line=$(sed -n "${line_number}p" "$file")  # read the line

  if [[ -z "$line" ]]; then
    echo "invalid line number."
    read -p "press enter to go back."
    return
  fi

  ifs=' ' read -r -a fields <<< "$line"  # part fields in an array

  while true; do
    clear
    echo "line $((line_number - 1)): $line"
    echo "edit menu:"
    echo "0 = back to main menu."

#   display fields, numbered and with headers
    for i in "${!fields[@]}"; do
      echo "$((i + 1)) = field $((i + 1)) (${headers[i]}: ${fields[i]})"
    done

    echo "$(( ${#fields[@]} + 1 )) = delete whole mapping."
    read -r field_choice

    if [[ "$field_choice" == "0" ]]; then
      return
    fi

    if (( field_choice == ${#fields[@]} + 1 )); then
      delete_line "$line_number"
      return
    fi

    if ! [[ "$field_choice" =~ ^[0-9]+$ ]] || (( field_choice < 1 )) || (( field_choice > ${#fields[@]} )); then
      echo "invalid option."
      read -p "press enter to continue..."
      continue
    fi

    edit_field "$line_number" "$((field_choice - 1))"
    line=$(sed -n "${line_number}p" "$file")  # reread line
    ifs=' ' read -r -a fields <<< "$line"    # re-divide fields
  done
}

function edit_field {
  local line_number=$1
  local field_index=$2
  local line
  line=$(sed -n "${line_number}p" "$file") 
  ifs=' ' read -r -a fields <<< "$line"    

  echo "current value of ${headers[field_index]} (feld $((field_index + 1))): ${fields[field_index]}"
  read -p "new value for ${headers[field_index]}: " new_value

  fields[field_index]=$new_value
  new_line=$(ifs=' '; echo "${fields[*]}")

# we have some slashes in our file, need to mask those from sed
  escaped_new_line=$(printf '%s' "$new_line" | sed 's/[&/\]/\\&/g')
  sed -i "${line_number}s/.*/$escaped_new_line/" "$file" # write file
  echo "field updated."
  read -p "press enter to continue."
}

function delete_line {
  local line_number=$1

  while true; do
    echo "delete mapping $((line_number - 1))?"
    echo "0 = no"
    echo "1 = yes"
    read -r confirm

    if [[ "$confirm" == "0" ]]; then
      return
    elif [[ "$confirm" == "1" ]]; then
      sed -i "${line_number}d" "$file"
      echo "deleted."
      read -p "press enter, to return to the main menu."
      return
    else
      echo "invalid option."
    fi
  done
}
# run main program
if [[ ! -f "$file" ]]; then
  echo "file '$file' not found."
  exit 1
fi

get_headers
main_menu
