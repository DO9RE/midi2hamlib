#!/bin/bash
function get_functions_with_setter_info() {
  local getter=$1
  local setter=$2
  echo "$1"
  echo "$2"
  local getter_list
  getter_list="$(rigctl -m 1 "$getter" "?")"
  local setter_list
  setter_list="$(rigctl -m 1 "$setter" "?")"
  echo "'$getter_list'"
  echo "'$setter_list'"
  IFS=' ' read -r -a getter_array <<< "$getter_list"
  IFS=' ' read -r -a setter_array <<< "$setter_list"
  declare -A map
  for setter in "${setter_array[@]}"; do
    map["$setter"]=$(( ${map["$setter"]} + 2))
  done
  for getter in "${getter_array[@]}"; do
    map["$getter"]=$(( ${map["$getter"]} + 1))
  done
  for item in "${!map[@]}"; do
    case ${map["$item"]} in
      1)
        echo "$item: read-only"
        ;;
      2)
        echo "$item: write-only"
        ;;
      3)
        echo "$item: read-write"
        ;;
      *)
        echo "ERROR while processing $item"
        ;;
    esac
  done
}

echo "Functions:"
get_functions_with_setter_info u U
echo -e "\\nLevels:"
get_functions_with_setter_info l L
echo -e "\\nParameters:"
get_functions_with_setter_info p P
