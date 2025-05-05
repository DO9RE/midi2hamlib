// gcc -o windows_midi_monitor win_midi_monitor.c -lwinmm
#include <windows.h>
#include <mmsystem.h>
#include <stdio.h>
#include <string.h>
#include <conio.h>

#define SYSEX_SIZE      1024   // Größe des SysEx-Puffers
#define SYSEX_BUFFERS   2      // Anzahl der zu reservierenden SysEx-Puffer

// Liste aller verfügbaren MIDI-Eingabegeräte ausgeben
void ListDevices() {
    UINT count = midiInGetNumDevs();
    printf("Verfügbare MIDI-Eingabegeräte:\n");
    MIDIINCAPS caps;
    for (UINT i = 0; i < count; i++) {
        if (midiInGetDevCaps(i, &caps, sizeof(caps)) == MMSYSERR_NOERROR) {
            printf("  %u: %s\n", i, caps.szPname);
        }
    }
}

// Callback-Funktion für eingehende MIDI-Events
void CALLBACK MidiInProc(HMIDIIN hMidiIn, UINT wMsg, DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2) {
    static DWORD startTime = 0;

    if (wMsg == MIM_DATA) {
        // Kurzmitteilung (Note, CC, etc.)
        DWORD msg = (DWORD)dwParam1;
        DWORD time = (DWORD)dwParam2;
        if (!startTime) startTime = time;
        DWORD elapsed = time - startTime;
        BYTE status = msg & 0xFF;
        BYTE data1  = (msg >> 8) & 0xFF;
        BYTE data2  = (msg >> 16) & 0xFF;
        BYTE channel = (status & 0x0F) + 1;
        BYTE type    = status & 0xF0;

        printf("%lu ms: ", elapsed);
        switch (type) {
            case 0x80:
                printf("Note Off,     ch %u, note %u, velocity %u\n", channel, data1, data2);
                break;
            case 0x90:
                if (data2 == 0)
                    printf("Note Off,     ch %u, note %u\n", channel, data1);
                else
                    printf("Note On,      ch %u, note %u, velocity %u\n", channel, data1, data2);
                break;
            case 0xA0:
                printf("Poly Pressure, ch %u, note %u, pressure %u\n", channel, data1, data2);
                break;
            case 0xB0:
                printf("Control Change, ch %u, controller %u, value %u\n", channel, data1, data2);
                break;
            case 0xC0:
                printf("Program Change,  ch %u, program %u\n", channel, data1);
                break;
            case 0xD0:
                printf("Channel Pressure, ch %u, pressure %u\n", channel, data1);
                break;
            case 0xE0: {
                int bend = ((int)data2 << 7) | data1;
                bend -= 8192;  // zentriert auf 0
                printf("Pitch Bend,   ch %u, value %d\n", channel, bend);
                break;
            }
            default:
                if ((status & 0xF0) >= 0xF0)
                    printf("System-Msg 0x%02X\n", status);
                else
                    printf("Unbekannte Msg 0x%02X\n", status);
        }
    }
    else if (wMsg == MIM_LONGDATA) {
        // System-Exklusiv-Daten (SysEx)
        MIDIHDR *hdr = (MIDIHDR*)dwParam1;
        DWORD time = (DWORD)dwParam2;
        if (!startTime) startTime = time;
        DWORD elapsed = time - startTime;
        BYTE *data = (BYTE*)hdr->lpData;
        DWORD len = hdr->dwBytesRecorded;

        printf("%lu ms: SysEx (%u Bytes):", elapsed, (unsigned)len);
        for (DWORD i = 0; i < len; i++) {
            printf(" %02X", data[i]);
        }
        printf("\n");

        // Puffer zurück in die Warteschlange stellen
        midiInAddBuffer(hMidiIn, hdr, sizeof(*hdr));
    }
}

int main(int argc, char *argv[]) {
    // Kommandozeilenparameter auswerten (-l zur Liste der Geräte)
    if (argc > 1) {
        if (strcmp(argv[1], "-l") == 0 || strcmp(argv[1], "--list") == 0) {
            ListDevices();
            return 0;
        }
    }
    UINT devID = 0;
    if (argc > 1) {
        devID = (UINT)atoi(argv[1]);
    }
    UINT devCount = midiInGetNumDevs();
    if (devCount == 0) {
        fprintf(stderr, "Keine MIDI-Eingabegeräte gefunden.\n");
        return 1;
    }
    if (devID >= devCount) {
        fprintf(stderr, "Ungültige Geräte-ID %u. Mit -l verfügbare Geräte auflisten.\n", devID);
        return 1;
    }

    // MIDI-Gerät öffnen
    HMIDIIN hMidi = NULL;
    MMRESULT res = midiInOpen(&hMidi, devID, (DWORD_PTR)MidiInProc, 0, CALLBACK_FUNCTION);
    if (res != MMSYSERR_NOERROR) {
        fprintf(stderr, "midiInOpen fehlgeschlagen (Fehler %u)\n", res);
        return 1;
    }

    // SysEx-Puffer vorbereiten und der Eingabe übergeben
    MIDIHDR hdrs[SYSEX_BUFFERS];
    BYTE sysexBuf[SYSEX_BUFFERS][SYSEX_SIZE];
    memset(hdrs, 0, sizeof(hdrs));
    for (int i = 0; i < SYSEX_BUFFERS; i++) {
        hdrs[i].lpData = (LPSTR)sysexBuf[i];
        hdrs[i].dwBufferLength = SYSEX_SIZE;
        hdrs[i].dwBytesRecorded = 0;
        midiInPrepareHeader(hMidi, &hdrs[i], sizeof(hdrs[i]));
        midiInAddBuffer(hMidi, &hdrs[i], sizeof(hdrs[i]));
    }

    // MIDI-Input starten
    midiInStart(hMidi);
    printf("Höre auf MIDI-Gerät %u. Mit Q oder Esc beenden...\n", devID);

    // Einfache Schleife, um das Programm laufen zu lassen bis zur Tasteneingabe
    while (1) {
        Sleep(100);
        if (_kbhit()) {
            int c = _getch();
            if (c == 27 || c == 'q' || c == 'Q') break;
        }
    }

    // MIDI-Input stoppen und schließen
    midiInStop(hMidi);
    midiInClose(hMidi);
    return 0;
}
