#!/bin/bash

FILE="$1"

# Function to display the midi map linewise
function show_file {
# Show file with numbered lines from line 2 on
  echo "File Contents:"
  tail -n +2 "$FILE" | nl -w2 -s" "  
}

# Function to get the field headers
function get_headers {
  read -r header_line < "$FILE"
  IFS=' ' read -r -a headers <<< "$header_line"
}

# Function to display the editors main menu
function main_menu {
  while true; do
    clear
    show_file
    echo "Midi Map Editor Menu"
    echo "0 = exit editor."
    echo "Enter line number to edit:"
    read -r menu_index

    if [[ "$menu_index" == "0" ]]; then
      echo "Leaving Editor"
      exit 0
    fi

    if ! [[ "$menu_index" =~ ^[0-9]+$ ]] || (( menu_index < 1 )); then
      echo "Invalid line number."
      read -p "Press Enter to continue."
      continue
    fi
#   Skip header line
    line_number=$((menu_index + 1))
    edit_menu "$line_number"
  done
}

# Function for edit menu
function edit_menu {
  local line_number=$1
  local line
  line=$(sed -n "${line_number}p" "$FILE")  # Read the line

  if [[ -z "$line" ]]; then
    echo "Invalid line number."
    read -p "Press Enter to go back."
    return
  fi

  IFS=' ' read -r -a fields <<< "$line"  # Part fields in an array

  while true; do
    clear
    echo "Line $((line_number - 1)): $line"
    echo "Edit Menu:"
    echo "0 = Back to main menu."

#   Display fields, numbered and with headers
    for i in "${!fields[@]}"; do
      echo "$((i + 1)) = Field $((i + 1)) (${headers[i]}: ${fields[i]})"
    done

    echo "$(( ${#fields[@]} + 1 )) = Delete whole mapping."
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
      read -p "Press Enter to continue..."
      continue
    fi

    edit_field "$line_number" "$((field_choice - 1))"
    line=$(sed -n "${line_number}p" "$FILE")  # Reread line
    IFS=' ' read -r -a fields <<< "$line"    # re-divide fields
  done
}

function edit_field {
  local line_number=$1
  local field_index=$2
  local line
  line=$(sed -n "${line_number}p" "$FILE") 
  IFS=' ' read -r -a fields <<< "$line"    

  echo "Current value of ${headers[field_index]} (Feld $((field_index + 1))): ${fields[field_index]}"
  read -p "New value for ${headers[field_index]}: " new_value

  fields[field_index]=$new_value
  new_line=$(IFS=' '; echo "${fields[*]}")

# We have some slashes in our file, need to mask those from SED
  escaped_new_line=$(printf '%s' "$new_line" | sed 's/[&/\]/\\&/g')
  sed -i "${line_number}s/.*/$escaped_new_line/" "$FILE" # Write file
  echo "Field updated."
  read -p "Press Enter to continue."
}

function delete_line {
  local line_number=$1

  while true; do
    echo "Delete mapping $((line_number - 1))?"
    echo "0 = No"
    echo "1 = Yes"
    read -r confirm

    if [[ "$confirm" == "0" ]]; then
      return
    elif [[ "$confirm" == "1" ]]; then
      sed -i "${line_number}d" "$FILE"
      echo "Deleted."
      read -p "Press Enter, to return to the main menu."
      return
    else
      echo "Invalid option."
    fi
  done
}
# Run main program
if [[ ! -f "$FILE" ]]; then
  echo "File '$FILE' not found."
  exit 1
fi

get_headers
main_menu
