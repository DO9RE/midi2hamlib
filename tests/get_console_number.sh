#!/bin/bash
# shellcheck disable=SC2015
[ -n "$SSH_CONNECTION" ] && echo SSH || tty | grep -o 'tty[0-9]*' | grep -o '[0-9]*'
