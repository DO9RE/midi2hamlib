sudo sed -i.bak -e 's/video=HDMI-A-1:\S*\s\?//g' -e 's/$/ video=HDMI-A-1:640x480@60D/' /boot/firmware/cmdline.txt
