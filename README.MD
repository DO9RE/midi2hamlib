
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
- `bc` for some math
- A screen reader in the console (tested with [Fenrir](https://github.com/chrys87/fenrir) for blind users)

## Accessibility

This project was created with accessibility in mind. When run on a Raspberry Pi with a console screen reader such as **Fenrir**, all script output will be spoken, enabling blind users to interact with the system effectively.

# Installation

Flash an SD card with a Raspbian OS, preferably a minimal version without a desktop. I used Raspbian Lite 64 Bit from the Raspberry Imager.

First, we need to download this wonderful package. We do this with the following command:
```
git clone https://github.com/do9re/midi2hamlib
```

Install the necessary packages via apt: build essentials, Hamlib, bc, pip, Sox, git, Speech-Dispatcher, and Espeak:
```
sudo apt install libhamlib-utils sox espeak espeak-ng speech-dispatcher build-essential libdbus-glib-1-dev libgirepository1.0-dev libpython3-dev libdbus-1-dev git python3-pip bc
```

Then, get the Fenrir package from Storm:
```
git clone https://git.stormux.org/storm/fenrir
```

Now, run the requirements installation:
```
sudo pip install -r requirements.txt --break-system-packages
```

Yes, I know, this is usually done with a virtual environment and Venv, but it didn't work for me. Since this system isn't meant to perform thousands of tasks aside from midi2hamlib, we'll leave it as is for now. Once someone shows me how to properly get Fenrir to speak under Debian without this tinkering, I'll update this installation guide. :-)

We also want to install Enchant:
```
sudo pip install enchant --break-system-packages
```

Now, check with the check-dependencies.py file located in the Fenrir directory of your user folder if all dependencies are met. Then install Fenrir with the install.sh script.

```
sudo ./install.sh
```

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

To avoid the spoken messages about started services during system startup and to have the speech output begin immediately upon reaching the user prompt and starting the Midi2Hamlib application, you can modify the approach. Instead of placing a @reboot call for fenrir in the root's crontab, you can insert the start_fenrir.sh script, located in the additional-scripts folder, into the user's .bashrc after a call to clear. This ensures that speech output only begins after login.

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

## For the brave; Install Speechd and Pico TTS.
After some tinkering, I have managed to get Speech Dispatcher and Pico TTS running with Fenrir. This section might later become part of the general installation, but for now, it will remain separate. The system with Espeak-NG has been stable so far, so this setup is optional and experimental.

First, we need to get the speechd package:
```
sudo apt install python3-speechd
```

Next, install Pico TTS. Start with the support files so that the Speech Dispatcher can access Pico:
```
sudo apt install speech-dispatcher-pico
```

Finally, install the speech output itself:
```
sudo apt install libttspico-utils
```

Now it's time to install Pulseaudio. It seems that this wasn't present on Raspbian OS Lite, so we need to add it:
```
sudo apt install pulseaudio
```
To allow Fenrir to communicate with us via Pulseaudio, we need to create a Pulseaudio configuration for both Root and our user. Since Fenrir runs as Root, we wouldn't be able to hear its output otherwise. In the directory:
/usr/share/fenrirscreenreader/tools
there is a script called configure_pulseaudio.sh. Run this script both as your user and then as Root.

Next, we need to tell Fenrir to use Pico TTS. Note: I reverted the changes in Fenrir's configuration file before starting the configuration tool. I'm not sure if this was necessary, but it felt safer.

The configuration tool is located in the folder:
/usr/share/fenrirscreenreader/tools and is called configure_fenrir.py. Run it and select your desired speech output.

In my case, I had to install Dialog first:
```
sudo apt install python3-dialog.
```
Restard and cross your fingers.

## Braille Support

Native Braille support in Fenrir never functioned reliably. When Storm took over responsibility for the project, he decided to remove Braille support from the main program entirely. This change does not pose a real issue, as there is already a very capable alternative available: **BRLTTY**.

BRLTTY provides excellent functionality for working with Braille output devices directly on the console. It can be installed easily using:

```
sudo apt install brltty
```

This offers an optional tactile access method to the system for users who rely on Braille displays.

# Project Structure: Separation of Menu Logic and Function Logic

At the root level of the project directory, there are two main folders:

- `menus/`
- `functions/`

---

## `menus/` Folder

The `menus/` folder contains the structure and logic for the user interface menus. It consists of:

1. **`options/` folder**  
   This folder is always present and visible, regardless of the selected transceiver.

2. **One folder per transceiver type**  
   Each supported transceiver has its own dedicated subfolder. These contain the complete menu structure for the respective device.

   ### Example: `dummy/`
   The folder `dummy/` contains a fully developed menu structure for the Dummy transceiver by RIGCTL. This serves as a template for creating your own custom menu structures.

---

## Menu Structure Details

Each subfolder within a transceiver folder represents a **submenu**. The name of the submenu is defined by creating a file named `name` inside that folder. The content of this file (plain text) will be used as the **title** of the submenu when it is displayed.

### Menu Entries

Menu entries within a submenu are defined using individual script files placed in the respective folder. These scripts control both the display name and the action of the menu item.

The **filen name** of a menu entry file shall be formed in a way that
sorting the files alphabetically results in the desired order in which the
menu entries shall be displayed. This is acomplished easily by using a
prefix that consists of two digits followed by an underscore.
  Example: `10_tuning_menu`

Please note that the menu entry's number is not taken from the file name
directly, menu entries are numbered sequencially starting from 1 regardless
of their actual prefix of the file name. The file names are only important
for deriving the menu entries order. That is why you should always use two
digits and leave enough room for adding new menu entries, for example by
numbering subsequent entries like `10_entry_x`, `20_entry_y`. Following this
rule lets you easily add new entries in between or delete an entry later.

The **first line** of each script defines the **label** of the menu item:
A hash (`#`) followed by the name of the menu item.  
  Example: `#Get frequency`

Below this line, the actual shell commands are defined. A menu item can either:

1. **Execute a function**  
   Use the command `source` followed by the path to the desired function script.  
   You may use the `$funcdir` placeholder, defined in settings/settings.conf, to reference the base path to the functions directory.  
   Example:  
   ```bash
   source $funcdir/dummy/tuning/get_frequency
   ```

2. **Navigate to a submenu**  
   Use standard shell commands such as `cd` to change into another menu directory. When the script is executed, it will switch to the specified folder and the main loop will display its `Name` and menu entries.  
   Example:  
   ```bash
   cd modes
   ```

---

## `functions/` Folder

The `functions/` folder contains subfolders with scripts that control the specific behavior of the transceivers.

Although the structure is still under development and not fully defined, we aim to maintain a **consistent naming logic** for these subdirectories to ensure clarity and scalability.

---

## Using the Tool with MIDI Hardware

All functions provided by the tool can also be triggered via **MIDI hardware**. This includes devices such as DJ controllers, digital mixing consoles, step sequencers, or even musical keyboards. The essential requirement is that the device offers **interactive controls** like buttons, sliders, or rotary knobs.

### Selecting a MIDI Device

To specify which connected MIDI device(s) should be used, edit the `settings.conf` file located in the `settings/` directory.

To discover the names of available MIDI devices on your system, use the following command:

```bash
aseqdump -l
```

Copy the exact device names (in quotes) into the appropriate variable in the `settings.conf` file.

You can assign **multiple devices** at once by listing their names inside parentheses, each enclosed in quotes and separated by a space:

```bash
midi_devices=("Device 1" "Device 2")
```

### Assigning MIDI Controls to Functions

To map MIDI events to specific functions or scripts, define your control mappings in a file named `midi.map`, located in the `midi/` subdirectory.

Each mapping occupies a **single line**, with all fields separated by a **space**. Here's the structure of each line:

```
DEVICE TYPE CHAN NUM VAL SCRIPT MODE
```

#### Field Breakdown:

- **DEVICE**  
  The device number, corresponding to the order in which devices are listed in `settings.conf`.  
  - The first device is `0`, the second is `1`, and so on.

- **_TYPE**  
  The type of MIDI event:
  - **note_on** or **note_off** for button presses/releases.
  - **control** for Control Change events (e.g., knobs and faders).

- **CHAN**  
  The MIDI channel number (typically between 0 and 15).  
  Many MIDI controllers allow you to switch channels, effectively multiplying the available controls.

- **NUM**  
  The specific number of the MIDI control element (e.g., note number or control number).

- **VAL**  
  The velocity or value associated with the event:
  - For notes, this is the velocity (e.g., how hard the button was pressed).
  - For Control Change events, it represents the current value of the control. The letter `n` indicates that
  the controller value shall be ignored when searching for the mapping
  entry, so this mapping applies to all controller values.

- **SCRIPT**  
  The script or function to execute when the event occurs.  
  If a field is not relevant for your use case, enter the letter **`N`** to mark it as ignored.

- **MODE**
  The evaluation mode that shall be used to map event values to parameters, values or functions of your transceiver. This currently applies only to Controller Change events. Possible values are:
  - **abs**: Controller values shall be used unmodified by the mapped function or script.
  - **mod**: The mapped function or script shall map the controller values repeatedly to the available options. this will cycle through the avalable options again and again when the controller values increase.
  - **zone**: This will map the complete value range of the controller or fader, typically 0 to 127, to the available options in zones. So if you have four options, a fadder would be mapped as follows:
    - Values 0 to 31 to option 1.
    - values 32 to 63 to option 2,
    - values 64 to 95 to option 3,
    - and finally, values 96 to 127 to option 4.
    So the fader will be split into four zones, mapping each zone to one of
    the four options.

#### Example:

```text
0 note_on 0 60 N modes/get_mode
0 control 0 10 n sub_tones/ctcss_toggle
```

When a control change event is triggering a function, its value is always passed. This flexibility allows for dynamic and tactile control of transceiver functions using your preferred MIDI gear.

---

## Identifying MIDI Events Sent by Your Hardware

At the current stage of development, the script does **not yet provide an interactive tool** to assign MIDI events to functions in real-time. Instead, you must **manually edit the `midi.map` file** to map hardware controls to specific actions.

So how do you find out which events your MIDI controller sends?

### Using `aseqdump` to Monitor MIDI Input

To determine what messages your MIDI device sends when you press buttons, turn knobs, or move faders, you can use the command-line utility `aseqdump`. Here's how:

1. **List Available MIDI Ports**

   First, use the following command to display a list of connected MIDI devices:

   ```bash
   aseqdump -l
   ```

   This will output all available MIDI devices by name and port number. Make a note of the device or port you wish to monitor.

2. **Start Listening to a Specific Device**

   Then, use the `-p` flag to start listening to a specific port. You can either use the **port number** or the **device name** (in quotes):

   ```bash
   aseqdump -p "Device Name"
   ```

   or

   ```bash
   aseqdump -p 20:0
   ```

3. **Trigger Controls on Your MIDI Device**

   While `aseqdump` is running, start interacting with your hardware. Each control you use—buttons, sliders, knobs—will output a corresponding MIDI message to the terminal.

   Example output might look like:

   ```
   Source  Event                    Ch  Data
   20:0    Control change           1   10 127
   20:0    Note on                 10   60 100
   ```

4. **Transfer These Values into `midi.map`**

   Using the structure described in the previous section, manually enter these values into your `midi.map` file. Make sure to assign the appropriate script or function to each event.

---

## Adjustment of Display for the Visually Impaired

Firstly, the font in the console can be adjusted using the tool DPKG-RECONFIGURE. To do this, enter `sudo dpkg-reconfigure console-setup`. Generally, all default settings such as character set and keyboard type should be retained, but the font on the screen is important.

**Caution!** Not all fonts are compatible with Braille output and the screen reader Fenrir. The font **Terminus Bold** has been successfully tested.

Furthermore, it is advisable to reduce the overall pixel count, i.e., the screen resolution, which greatly enlarges everything. This can be done using options in the file `/boot/firmware/cmdline.txt`. In the **Additional Scripts** directory, there is a file named `set_screen_resolution_to_640x480.sh`, which automatically sets the necessary entries after creating a backup of `cmdline.txt`.

## License

This project is released under an open-source license. See `LICENSE` for more details.

---

*Developed with a focus on accessibility and creativity in amateur radio.*
By
DO9RE, Richard Emling - DK7STJ, Stefan Jansen

