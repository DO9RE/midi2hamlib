# Windows MIDI Monitor

A Windows-compatible replacement for Linux's `aseqdump` utility, designed to work seamlessly with the midi2hamlib project on Windows systems (MSYS2, MinGW, Cygwin).

## Overview

This program monitors MIDI input devices and outputs MIDI events in a format compatible with `aseqdump`, allowing the midi2hamlib Reader script to parse MIDI events on Windows systems without modification.

## Features

- **aseqdump-compatible output format**: Events are formatted exactly like Linux's aseqdump
- **Multiple device support**: Can monitor multiple MIDI devices simultaneously
- **Comprehensive MIDI event support**:
  - Note On/Off messages
  - Control Change (CC) messages
  - Program Change messages
  - Pitch Bend
  - Polyphonic and Channel Aftertouch
  - System Exclusive (SysEx) messages
- **Command-line interface**: Compatible with aseqdump command-line options

## Compilation

The program is automatically compiled by the `check_environment()` function in `functions/helper_functions` when you run the main midi2hamlib script on Windows.

### Manual Compilation

If you need to compile manually:

```bash
cd midi/windows_midi_monitor
gcc -o windows_midi_monitor.exe windows_midi_monitor.c -lwinmm
```

## Usage

### List Available MIDI Devices

```bash
./windows_midi_monitor.exe -l
```

Output format:
```
Port    Client name                      Port name
  0:0   Device Name 1
  1:0   Device Name 2
```

### Monitor a Single Device

```bash
./windows_midi_monitor.exe -p 0
```

### Monitor Multiple Devices

```bash
./windows_midi_monitor.exe -p 0,1
```

### Help

```bash
./windows_midi_monitor.exe -h
```

## Output Format

The program outputs MIDI events in aseqdump-compatible format:

### Control Change Events
```
0:0   Control change,       0, controller  10, value 127
```

### Note Events
```
0:0   Note on,              0, note  60, velocity 100
0:0   Note off,             0, note  60, velocity   0
```

### Other Events
```
0:0   Program change,       0, program  42
0:0   Pitch bend,           0, value  8192
0:0   Channel pressure,     0, value  64
```

## Integration with midi2hamlib

The integration is automatic when running on Windows systems:

1. The `check_environment()` function in `functions/helper_functions` detects Windows
2. Automatically compiles `windows_midi_monitor.exe` if not present
3. Sets `ASEQDUMP_CMD` environment variable to point to the Windows MIDI monitor
4. Creates an `aseqdump` alias for convenience

The Reader script in `midi/reader` uses `$ASEQDUMP_CMD` to invoke the appropriate MIDI monitor for the platform, making the switch transparent.

## Device Configuration

In your `settings/settings.conf` file, configure MIDI devices by name:

```bash
midi_devices=("Device Name 1" "Device Name 2")
```

The Reader script will automatically:
1. Call `windows_midi_monitor.exe -l` to list devices
2. Match device names from settings.conf
3. Extract device IDs
4. Start monitoring with `-p ID1,ID2,...`

## Requirements

- Windows with MSYS2, MinGW, or Cygwin
- GCC compiler (install with: `pacman -S mingw-w64-x86_64-gcc`)
- Windows Multimedia API (winmm.dll - included with Windows)

## Differences from Linux aseqdump

While functionally equivalent for midi2hamlib's purposes, there are some minor differences:

1. **Port format**: Uses simple device IDs (0, 1, 2...) instead of ALSA client:port format
2. **Device naming**: Windows MIDI device names may differ from Linux equivalents
3. **Timestamp format**: Timestamps are intentionally omitted as they are not used by the Reader script, which only parses source port, event type, channel, and data values

These differences do not affect compatibility with the midi2hamlib Reader script.

## Troubleshooting

### "No MIDI input devices found"
- Ensure your MIDI device is connected and recognized by Windows
- Check Device Manager for MIDI devices
- Try unplugging and reconnecting the device

### "Compilation failed"
- Ensure GCC is installed: `gcc --version`
- Install GCC if missing: `pacman -S mingw-w64-x86_64-gcc`
- Check that winmm library is available

### Device not showing in list
- Verify the device works with other MIDI software
- Check Windows Sound settings for MIDI devices
- Restart the device or computer

## License

This code is part of the midi2hamlib project and follows the same license.

## Authors

Richard Emling (DO9RE) and Stefan Jansen (DK7STJ)
- Developed for the midi2hamlib project
- Based on Windows Multimedia API documentation
