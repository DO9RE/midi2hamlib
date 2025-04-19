source ../functions/helper_functions
maxval=10
while true; do
  echo "Here would be a menu with entries numbered from 0 to $maxval."
  if ! read_and_validate "Input: " $maxval choice ; then
    continue
  fi
  echo "Input $choice OK."
  if [[ $choice -eq 0 ]]; then
    break
  fi
done
 