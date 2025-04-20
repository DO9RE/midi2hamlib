sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.bak
sudo sed -i '/video=HDMI-A-1:/d' /boot/firmware/cmdline.txt
sudo sed -i 's/$/ video=HDMI-A-1:640x480@60D/' /boot/firmware/cmdline.txt

