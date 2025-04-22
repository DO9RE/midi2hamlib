#!/bin/bash

rows=$(tput lines)
cols=$(tput cols)

menu_items=(
  "1 = Menüpunkt 1"
  "2 = Menüpunkt 2"
  "3 = Menüpunkt 3"
  "4 = Menüpunkt 4"
  "5 = Menüpunkt 5"
  "6 = Menüpunkt 6"
  "7 = Menüpunkt 7"
  "8 = Menüpunkt 8"
  "9 = Menüpunkt 9"
  "10 = Menüpunkt 10"
  "11 = Menüpunkt 11"
  "12 = Menüpunkt 12"
  "13 = Menüpunkt 13"
  "14 = Menüpunkt 14"
  "15 = Menüpunkt 15"
  "16 = Menüpunkt 16"
  "17 = Menüpunkt 17"
  "18 = Menüpunkt 18"
  "19 = Menüpunkt 19"
  "20 = Menüpunkt 20"
  "21 = Menüpunkt 21"
  "22 = Menüpunkt 22"
  "23 = Menüpunkt 23"
  "24 = Menüpunkt 24"
  "25 = Menüpunkt 25"
  "26 = Menüpunkt 26"
  "27 = Menüpunkt 27"
  "28 = Menüpunkt 28"
  "29 = Menüpunkt 29"
  "30 = Menüpunkt 30"
  "31 = Menüpunkt 31"
  "32 = Menüpunkt 32"
  "33 = Menüpunkt 33"
  "34 = Menüpunkt 34"
  "35 = Menüpunkt 35"
)

max_lines=$((rows - 2))

display_menu() {
  start=$1
  end=$((start + max_lines - 1))

  for ((i = start; i <= end && i <= ${#menu_items[@]}; i += 2)); do
    left="${menu_items[i-1]}"
    right=""
    if ((i < ${#menu_items[@]})); then
      right="${menu_items[i]}"
    fi
    printf "%-$(($cols / 2))s %s\n" "$left" "$right"
  done
}

current_start=1
while true; do
  clear
  echo "Menü (Drücke Enter für nächste Seite oder gib die Nummer ein):"
  display_menu $current_start

  read -p "> " choice

  if [[ $choice =~ ^[0-9]+$ && $choice -le ${#menu_items[@]} ]]; then
    echo "Du hast Menüpunkt $choice gewählt: ${menu_items[choice-1]}"
    exit 0
  fi

  if [[ -z $choice ]]; then
    current_start=$((current_start + max_lines))
    if ((current_start > ${#menu_items[@]})); then
      current_start=1
    fi
  fi
done
