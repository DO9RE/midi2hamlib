#!/bin/bash
SHELLCHECK=$(command -v shellcheck)
if [[ -n "$SHELLCHECK" && -x $SHELLCHECK ]]; then
  EXITCODE=0
  for i in $(find ./ -type f | grep -v '\(/name$\)\|\(\.conf\)\|\(\.map\)\|\(\.txt$\)\|\(midi_monitor/\)\|\(\.git\)\|\(README\.MD\)\|\(/developer_communication/\)') ; do
    # SC2154: Disalbd checkinf for referencing unassigned variable.
    # this is done because we do a lot of sourcing, variables are defined
    # in scripts where they are not referenced and vice versa.
    # SC1090, SC1091: disable follow sourced files.
    # SC2164: disable warning to catch failing 'cd' commands.
    # SC2206,SC2207: Suppress warning for not using read -a or mapfile to parse arrays.
    # read -a and read -ar had issues when strings started with space character.
    # SC2004: Suppress warning if ${varname} is used inside array subscripts.
    # While this works for normal arrays, it doesn't for associative arrays.
    # That i why we suppres this warning, it is not correct for associative arrays.
    if ! $SHELLCHECK -s bash -e SC2154,SC1090,SC1091,SC2164,SC2206,SC2207,SC2004 "$i" ; then
      EXITCODE=1
      #break # end after first script with errors or warnings was found.
    fi
  done
  if [[ $EXITCODE -eq 0 ]]; then
    echo "No warnings."
  fi
  exit $EXITCODE
else
  echo "Please install shellcheck."
  exit 1
fi
