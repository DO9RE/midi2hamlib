#!/bin/bash
[ -n "$SSH_CONNECTION" ] && echo SSH || tty | grep -o 'tty[0-9]*' | grep -o '[0-9]*'
