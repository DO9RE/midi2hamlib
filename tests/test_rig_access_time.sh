#!/bin/bash
rig_port=4500
print_usage() {
  echo "Usage: $0 num_iterations rig_model rig_option1 rig_option2 ..."
  echo "rig_model must not be 2 (network/remote), as this script compares the time"
  echo "between accessing a rig directly and remotely."
  exit 1
}

if [[ $1 -gt 0 ]]; then
  num_iterations=$1
else
  print_usage
fi
if [[ ( $2 -gt 0 ) && ( $2 -ne 2 ) ]]; then
  rig_model=$2
else
  print_usage
fi
shift 2
rig_options="$*"

do_queries() {
  local first_rig_result i
  first_rig_result=""
  for ((i=1; i<=num_iterations; i++)); do
    retval=$(rigctl $@)
    echo "$i: rigctl $*: $retval"
    if [[ -z "$first_rig_result" ]]; then
      first_rig_result="$retval"
    elif [[ "$first_rig_result" != "$retval" ]]; then
      echo "RIG returned a different value as when invoked the first time. Exiting."
      exit 1
    fi
  done
}

echo "Measuring RIG access time for ${num_iterations} times by requesting current QRG."
echo "RIG options: -m${rig_model} $*"
echo "Accessing RIG directly."
time do_queries "-m${rig_model}" $@ f
echo "Starting rigctld"
rigctld "-m${rig_model}" -t "${rig_port}" $@ &
rigctld_pid=$!
echo "rigctld PID is ${rigctld_pid}. Sleeping 5s."
sleep 5
echo "Accessing RIG remotely through rigctld."
time do_queries -m2 -r "localhost:${rig_port}" $@ f
echo "Stopping rigctld."
kill $rigctld_pid
wait $rigctld_pid
sleep 1
echo "Done."

