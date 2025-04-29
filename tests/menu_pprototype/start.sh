#!/bin/bash
source ../../functions/helper_functions

# it is important to always use different names for arrays and handlers for menus.
# This is because otherwise, since scripts for menus will be sourced, defining
# menu data in different scripts will overwrite other script's data.

main_menu_handler() {
  # menu exit is already handled in show_menu.
  # Keep demo simple, just source a script that is named like the menu entry.
  source ${main_menu_entries[$1]}
  return 0
}

# We consistently use zero-based arrays for those menus. Indices are shifted inside to get 0 for "go back".
main_menu_entries=("fruits" "squares")
show_menu "Main menu:" main_menu_entries "Select: " main_menu_handler
echo "Exiting main menu."
