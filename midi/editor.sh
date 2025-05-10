#!/bin/bash
file=$midi_mapping_file

# function to display the midi map linewise
function show_file {
# show file with numbered lines from line 2 on
  echo "file contents:"
  tail -n +2 "$file" | nl -w2 -s" "  
}

# function to get the field headers
function get_headers {
  read -r header_line < "$file"
  if [[ ${header_line:0:1} == "#" ]]; then
    header_line=${header_line:1}
  fi
  ifs=' ' read -r -a headers <<< "$header_line"
}

# function to display the editors main menu
function main_menu {
  while true; do
    clear
    show_file
    echo "midi map editor menu"
    echo "0 = exit editor."
    read -rp "enter line number to edit: " menu_index

    if [[ "$menu_index" == "0" ]]; then
      echo "leaving editor"
      return 0
    elif ! [[ "$menu_index" =~ ^[0-9]+$ ]] || (( menu_index < 1 )); then
      echo "invalid line number."
      read -rp "press enter to continue."
      continue
    else
#     skip header line
      line_number=$((menu_index + 1))
      edit_menu "$line_number"
    fi
  done
}

# function for edit menu
function edit_menu {
  local line_number=$1
  local line
  line=$(sed -n "${line_number}p" "$file")  # read the line

  if [[ -z "$line" ]]; then
    echo "invalid line number."
    read -rp "Press enter to go back."
    return
  elif [[ "$line" =~ ^# ]]; then
    echo "This line is a comment and cannot be edited."
    read -rp "Press enter to go back."
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
    read -rp "Field choice: " field_choice

    if [[ "$field_choice" == "0" ]]; then
      return
    fi

    if (( field_choice == ${#fields[@]} + 1 )); then
      delete_line "$line_number"
      return
    fi

    if ! [[ "$field_choice" =~ ^[0-9]+$ ]] || (( field_choice < 1 )) || (( field_choice > ${#fields[@]} )); then
      echo "invalid option."
      read -rp "press enter to continue..."
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

  echo "current value of ${headers[field_index]} (field $((field_index + 1))): ${fields[field_index]}"

  # Check for special case: editing "Field 2", TYPE
  if [[ $field_index -eq 1 ]]; then
    while true; do
      echo "Select a new value for ${headers[field_index]}:"
      echo "1 = note_on"
      echo "2 = note_off"
      echo "3 = control"
#      echo "4 = pitch"
      echo "0 = go back"
      read -rp "Your choice: " choice

      case $choice in
        1) new_value="note_on"; break ;;
        2) new_value="note_off"; break ;;
        3) new_value="control"; break ;;
#       4) new_value="pitch"; break ;;
        0) return ;;
        *) echo "Invalid option. Please try again." ;;
      esac
    done
# Check for special case: editing "Field 6", SCRIPT
  elif [[ $field_index -eq 5 ]]; then
    source "$funcdir/file_picker.sh" "$funcdir"
    # We cannot do replacement in variable expansion, because the pattern contains slashes.
    # shellcheck disable=SC2001
    new_value=$(echo "$file_picker_result" | sed "s#${funcdir}/##g")
# Check for special case: editing "Field 7", MODE
  elif [[ $field_index -eq 6 ]]; then
    while true; do
      echo "Select a new value for ${headers[field_index]}:"
      if [[ ${fields[1]} == "control" ]]; then
        echo "1 = absolute mapping"
        echo "2 = modulo mapping"
        echo "3 = zone mapping"
        echo "4 = absolute, control in rel ode"
        echo "5 = modulo mapping, control in relative mode"
      else
        echo "1 = key, regular keystroke"
        echo "2 = up, increment a value or select next option"
        echo "3 = down, increment a value or select previous option"
        echo "4 = up_r, like 'up' but with wrap-around"
        echo "5 = down_r, like 'down' but with wrap-around"
      fi
      echo "0 = go back"
      read -rp "Your choice: " choice

      if [[ $choice -eq 0 ]]; then
        return
      elif [[ ${fields[1]} == "control" ]]; then
        case $choice in
          1) new_value="abs"; break ;;
          2) new_value="mod"; break ;;
          3) new_value="zone"; break ;;
          4) new_value="abs_r"; break ;;
          5) new_value="mod_r"; break ;;
          *) echo "Invalid option. Please try again." ;;
        esac
      else
        case $choice in
          1) new_value="key"; break ;;
          2) new_value="up"; break ;;
          3) new_value="down"; break ;;
          4) new_value="up_r"; break ;;
          5) new_value="down_r"; break ;;
          *) echo "Invalid option. Please try again." ;;
        esac
      fi
    done
  else
    read -rp "New value for ${headers[field_index]}: " new_value
  fi
  # store new value for currently edited field.
  fields[field_index]=$new_value
  # If TYPE was changed and mode doesn't match, set it to a suitable default.
  if [[ $field_index -eq 1 ]]; then
    case ${fields[field_index]} in
      "control")
        # Quoting rhs of ~= is OK here, we do not need regexp matching.
        # shellcheck disable=SC2076
        if [[ ! " abs mod zone abs_r mod_r " =~ " ${fields[6]} " ]]; then
          fields[6]='abs'
          echo "${headers[6]} has been set to '${fields[6]}' for consistency with TYPE field."
        fi
        ;;
      *)
        # Quoting rhs of ~= is OK here, we do not need regexp matching.
        # shellcheck disable=SC2076
        if [[ ! " key up down up_r down_r " =~ " ${fielda[6]} " ]]; then
          fields[6]='key'
          echo "${headers[6]} has been set to '${fields[6]}' for consistency with TYPE field."
        fi
        ;;
    esac
  fi
  # re-read currently edited line.
  new_line="${fields[*]}"

  # Escape slashes for sed
  escaped_new_line=$(printf '%s' "$new_line" | sed 's/[&/\]/\\&/g')
  sed -i "${line_number}s/.*/$escaped_new_line/" "$file" # Write file
  echo "Field updated."
  read -rp "Press enter to continue."
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
      read -rp "Press enter, to return to the main menu."
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
