# Internationalization (i18n) Guide

This document explains the internationalization system implemented in midi2hamlib-cpa.

## Overview

The system uses language files stored in the `./lang` directory. Currently supported languages:
- **en** - English (default)
- **de** - German (Deutsch)

## Configuration

### Setting the Language

The language is configured in `settings/settings.conf`:

```bash
MIDI2HAMLIB_LANG=en  # for English
# or
MIDI2HAMLIB_LANG=de  # for German
```

You can also override this by setting the environment variable before starting the application:

```bash
export MIDI2HAMLIB_LANG=de
source start
```

## Language File Format

Language files are located in `./lang/` and follow the format:

```
# Comment lines start with #
KEY="Translated text"
KEY_WITH_PARAMS="Text with %s parameters %d"
```

## Using Translations in Code

The `t` function is used to retrieve translated strings:

### Simple Translation
```bash
echo "$(t MSG_GREETING)"
# Output in English: Hello
# Output in German: Hallo
```

### Translation with Parameters (printf-style)
```bash
echo "$(t ERR_INPUT_OUT_OF_RANGE 100)"
# Output in English: Input out of range. please enter a number between 0 and 100.
# Output in German: Eingabe außerhalb des Bereichs. Bitte geben Sie eine Zahl zwischen 0 und 100 ein.
```

### In Menu Files

Menu name files (`menus/*/name`) use:
```bash
$(t MENU_OPTIONS)
```

Menu entry files use translation keys in their first line:
```bash
# $(t MENU_GET_FREQUENCY)
source "$funcdir/tuning/get_frequency"
```

## Translation Key Categories

### General Messages
- `MSG_GREETING` - Welcome message
- `MSG_USE_ZERO_TO_RETURN` - Menu instruction
- `MSG_AND_NOW` - Menu prompt
- etc.

### Error Messages
- `ERR_BC_NOT_INSTALLED` - bc not installed error
- `ERR_RIGCTL_NOT_FOUND` - rigctl not found error
- `ERR_INVALID_INPUT` - Invalid input error
- etc.

### System Messages
- `SYS_RUNNING_ON_MACOS` - Running on macOS
- `SYS_COMPILATION_SUCCESS` - Compilation successful
- etc.

### Menu Names and Entries
- `MENU_OPTIONS` - Options Menu
- `MENU_TUNING` - Tuning Menu
- `MENU_GET_FREQUENCY` - Get frequency
- etc.

### MIDI Editor
- `MIDI_EDITOR_MENU` - MIDI editor menu
- `MIDI_FIELD_UPDATED` - Field updated message
- etc.

