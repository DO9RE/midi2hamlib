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

## License

This project is released under an open-source license. See `LICENSE` for more details.

---

*Developed with a focus on accessibility and creativity in amateur radio.*

