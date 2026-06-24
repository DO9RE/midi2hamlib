if shopt -q login_shell; then
  if [[ $(tty) == "/dev/tty1" ]]; then
    clear
  	setleds +num
    sudo fenrir
    clear
    sleep 10
    echo "Starting midi2hamlib."
    cd ~/repos/midi2hamlib
    ./start -c settings/settings_dk7stj.conf
  fi
fi
