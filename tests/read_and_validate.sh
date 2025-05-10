# shellcheck disable=SC1091
source ../functions/helper_functions
maxval=10
while true; do
  echo "Here would be a menu with entries numbered from 1 to $maxval, 0 leaves the menu."
  if ! read_and_validate "Input: " $maxval choice ; then
    continue
  fi
  echo "Input $choice OK."
  if [[ $choice -eq 0 ]]; then
    break
  fi
done
echo "zero-based array:"
arr=("goback" "one" "two")
while true; do
  echo "Menu with ${#arr[@]} entries from array (${arr[*]}) with keys ${!arr[*]}."
  if ! read_and_validate_arr_0 "Input: " arr choice ; then
    continue
  fi
  echo "Input $choice OK."
  if [[ $choice -eq 0 ]]; then
    break
  fi
done
echo "1-based array:"
unset arr
arr[1]="one"
arr[2]="two"
while true; do
  echo "Menu with ${#arr[@]} entries from array (${arr[*]}) with keys ${!arr[*]}."
  if ! read_and_validate_arr_1 "Input: " arr choice ; then
    continue
  fi
  echo "Input $choice OK."
  if [[ $choice -eq 0 ]]; then
    break
  fi
done
 