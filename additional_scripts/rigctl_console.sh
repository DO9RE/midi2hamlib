#!/bin/bash
echo -e "Enter rigctl commands to execute here\\nquit to exit."
while [[ ! $command == "quit" ]]; do
  read -rp 'command: ' command
  if [[ $command == "quit" ]]; then
    break
  else
    # word splitting is OK here, we may want to enter more than one parameter.
    # shellcheck disable=SC2086
    rigctl -m 2 -r "$host:$port" $command
  fi
done
