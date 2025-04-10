# midi2hamlib

**midi2hamlib** is an experimental project that explores the possibility of controlling amateur radio transceivers using the [Hamlib](https://github.com/Hamlib/Hamlib)
 library, with input from external devices such as a MIDI controller, a USB numeric keypad, and a Raspberry Pi.

The primary aim of this project is to provide an accessible control interface for blind amateur radio operators, though it may also be useful to sighted users who are looking for an alternative and programmable control method.

## Project Status

⚠️ **Warning:** This project is currently in a very early, experimental stage. It is a feasibility study and the code is raw, incomplete, and prone to bugs.

## How It Works

- A customisable audio menu provides access to rig functions.
- MIDI input is read via `aseqdump`, a utility that is part of the ALSA (Advanced Linux Sound Architecture) package.
- MIDI events are parsed and mapped to Hamlib commands, which can control a connected transceiver.
- By default, the system can be tested using Hamlib’s built-in **Dummy** transceiver model (Model 1), which simulates a radio without requiring real hardware.

## Requirements

- A Linux system (tested on Raspberry Pi OS)
- A connected MIDI controller, keyboard or numpad
- `aseqdump` from the ALSA utilities
- `hamlib` and its utilities
- A screen reader in the console (tested with [Fenrir](https://github.com/chrys87/fenrir) for blind users)

## Accessibility

This project was created with accessibility in mind. When run on a Raspberry Pi with a console screen reader such as **Fenrir**, all script output will be spoken, enabling blind users to interact with the system effectively.

# Installation

Flash an SD card with a Raspbian OS, preferably a minimal version without a desktop. I used Raspbian Lite 64 Bit from the Raspberry Imager.

First, we need to download this wonderful package. We do this with the following command:
```
git clone https://github.com/do9re/midi2hamlib
```

Install the necessary packages via apt: build essentials, Hamlib, pip, Sox, git, Speech-Dispatcher, and Espeak:
```
sudo apt install sox espeak espeak-ng speech-dispatcher build-essential libdbus-glib-1-dev libgirepository1.0-dev libpython3-dev libdbus-1-dev git python3-pip
```

Then, get the Fenrir package from Storm:
```
git clone https://git.stormux.org/storm/fenrir
```

Storm has an extra 'P' at the beginning of the pyperclip package in the requirements.txt file. Remove it using your favorite editor. I use Nano.

Now, run the requirements:
```
sudo pip install -r requirements.txt --break-system-packages
```

Yes, I know, this is usually done with a virtual environment and Venv, but it didn't work for me. Since this system isn't meant to perform thousands of tasks aside from midi2hamlib, we'll leave it as is for now. Once someone shows me how to properly get Fenrir to speak under Debian without this tinkering, I'll update this installation guide. :-)

We also want to install Enchant:
```
sudo install enchant --break-system-packages
```

Now, check with the check-dependencies.py file located in the Fenrir directory of your user folder if all dependencies are met.

For me, it still says Speechd is not available despite installing Speech-Dispatcher. Therefore, I changed two lines in the file ./etc/fenrir-screenreader/settings/settings.conf:

Under the [speech] category, comment out `driver=speechDriver` and uncomment `driver=genericDriver`.

Further down, uncomment the line:
```
#module=espeak-ng
```

Fenrir now speaks with Espeak. Again, if someone shows me how to properly use the Speech Dispatcher, this will be explained correctly here.

Copying the start script for the automatic start of Fenrir to /etc/systemd/system/ didn't work either. So, I boldly added the call for Fenrir to the root's crontab at system startup:

Open the root's crontab by becoming root and entering:
```
crontab -e
```

At the very end of the file, add:
```
@reboot fenrir
```
Fenrir should now start automatically.

The user should be logged in automatically so that the system doesn't require entering a username and password to unlock. You can use the Raspi-Config tool for this:
```
sudo raspi-config
```

In the first category, System, you can set up a console login and ensure that the current user is logged in automatically.

Finally, midi2hamlib should start automatically when the system boots. We achieve this by adjusting the user's .bashrc:

Open the .bashrc file:
```
nano ~/.bashrc
```

Go to the very end and add the following:
```
cd ~/midi2hamlib
source start
```

Save the file with Control+X.

Happy testing!

## License

This project is released under an open-source license. See `LICENSE` for more details.

---

*Developed with a focus on accessibility and creativity in amateur radio.*

