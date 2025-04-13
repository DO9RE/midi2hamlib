#!/bin/bash
# Check if Fenrir-Screenreader is running. If not, start it.
if [[ ! -f /var/run/fenrir.pid ]]; then $(sudo fenrir); fi
