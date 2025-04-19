#!/bin/bash

function get_functions_with_setter_info() {
  local getter=$1
  local setter=$2
 echo "$1"
 echo "$2"
  local getter_list="$(rigctl -m 1 $getter ?)"
  local setter_list="$(rigctl -m 1 $setter ?)"
  echo "$getter_list"
  echo "$setter_list"
  IFS=' ' read -r -a getter_array <<< "$getter_list"
    IFS=' ' read -r -a setter_array <<< "$setter_list"
    declare -A setter_map
    for setter in "${setter_array[@]}"; do
      setter_map["$setter"]=true
    done
    declare -A items
    for item in "${getter_array[@]}"; do
      if [[ -n "${setter_map[$item]}" ]]; then
        items["$item"]="has_setter=true"
      else
        items["$item"]="has_setter=false"
      fi
    done
    for item in "${!items[@]}"; do
        echo "$item: ${items[$item]}"
    done
}

get_functions_with_setter_info p P
