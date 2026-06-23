if shopt -q login_shell; then
  if [[ $(tty) == "/dev/tty1" ]]; then
  	setleds +num
    sudo fenrir
    sleep 10
    echo "Starting midi2hmalib."
    cd ~/repos/midi2hamlib
    ./start -c settings/settings_dk7stj.conf
  fi
fi
