#!/bin/bash
echo -e "Enter rigctl commands to execute here\nquit to exit"
while [[ ! $command == "quit" ]]; do
read -p 'command: ' command
if [[ $command == "quit" ]]; then
  break
else
  rigctl -m 2 -r $host:$port $command
fi
done
