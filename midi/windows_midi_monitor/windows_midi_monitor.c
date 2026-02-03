// gcc -o windows_midi_monitor windows_midi_monitor.c -lwinmm
#include <windows.h>
#include <mmsystem.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <conio.h>

#define SYSEX_SIZE      1024
#define SYSEX_BUFFERS   2
#define MAX_DEVICES     16

// List all available MIDI input devices (aseqdump -l compatible format)
void ListDevices() {
    UINT count = midiInGetNumDevs();
    MIDIINCAPS caps;
    printf("Port    Client name                      Port name\n");
    for (UINT i = 0; i < count; i++) {
        if (midiInGetDevCaps(i, &caps, sizeof(caps)) == MMSYSERR_NOERROR) {
            // Format: "ID:0 Device_Name"
            printf("%3u:0   %s\n", i, caps.szPname);
        }
    }
}

// Callback function for incoming MIDI events (aseqdump compatible format)
void CALLBACK MidiInProc(HMIDIIN hMidiIn, UINT wMsg, DWORD_PTR dwInstance, DWORD_PTR dwParam1, DWORD_PTR dwParam2) {
    // dwInstance contains the device ID
    UINT deviceID = (UINT)dwInstance;
    
    if (wMsg == MIM_DATA) {
        // Short message (Note, CC, etc.)
        DWORD msg = (DWORD)dwParam1;
        BYTE status = msg & 0xFF;
        BYTE data1  = (msg >> 8) & 0xFF;
        BYTE data2  = (msg >> 16) & 0xFF;
        BYTE channel = (status & 0x0F);  // 0-based channel for aseqdump
        BYTE type    = status & 0xF0;

        // Output format: "SOURCE TYPE, CHANNEL, ..."
        // SOURCE format: deviceID:0
        // Note: Format must match aseqdump for reader script parsing
        switch (type) {
            case 0x80:  // Note Off
                printf("%u:0   Note off,             %2u, note %3u, velocity %3u\n", 
                       deviceID, channel, data1, data2);
                fflush(stdout);
                break;
            case 0x90:  // Note On
                if (data2 == 0) {
                    // Velocity 0 is treated as Note Off
                    printf("%u:0   Note off,             %2u, note %3u, velocity %3u\n", 
                           deviceID, channel, data1, data2);
                } else {
                    printf("%u:0   Note on,              %2u, note %3u, velocity %3u\n", 
                           deviceID, channel, data1, data2);
                }
                fflush(stdout);
                break;
            case 0xA0:  // Polyphonic Aftertouch
                printf("%u:0   Poly pressure,        %2u, note %3u, value %3u\n", 
                       deviceID, channel, data1, data2);
                fflush(stdout);
                break;
            case 0xB0:  // Control Change
                printf("%u:0   Control change,       %2u, controller %3u, value %3u\n", 
                       deviceID, channel, data1, data2);
                fflush(stdout);
                break;
            case 0xC0:  // Program Change
                printf("%u:0   Program change,       %2u, program %3u\n", 
                       deviceID, channel, data1);
                fflush(stdout);
                break;
            case 0xD0:  // Channel Pressure (Aftertouch)
                printf("%u:0   Channel pressure,     %2u, value %3u\n", 
                       deviceID, channel, data1);
                fflush(stdout);
                break;
            case 0xE0:  // Pitch Bend
                {
                    int bend = ((int)data2 << 7) | data1;
                    printf("%u:0   Pitch bend,           %2u, value %5d\n", 
                           deviceID, channel, bend);
                    fflush(stdout);
                }
                break;
            default:
                // System messages or unknown
                if ((status & 0xF0) >= 0xF0) {
                    printf("%u:0   System message 0x%02X\n", deviceID, status);
                    fflush(stdout);
                }
                break;
        }
    }
    else if (wMsg == MIM_LONGDATA) {
        // System Exclusive data (SysEx)
        MIDIHDR *hdr = (MIDIHDR*)dwParam1;
        BYTE *data = (BYTE*)hdr->lpData;
        DWORD len = hdr->dwBytesRecorded;

        printf("%u:0   System exclusive  ", deviceID);
        for (DWORD i = 0; i < len; i++) {
            printf("%02X ", data[i]);
        }
        printf("\n");
        fflush(stdout);

        // Return buffer to queue
        midiInAddBuffer(hMidiIn, hdr, sizeof(*hdr));
    }
}

int main(int argc, char *argv[]) {
    UINT devIDs[MAX_DEVICES];
    int numDevices = 0;
    
    // Parse command line arguments
    if (argc > 1) {
        if (strcmp(argv[1], "-l") == 0 || strcmp(argv[1], "--list") == 0) {
            ListDevices();
            return 0;
        }
        else if (strcmp(argv[1], "-p") == 0 || strcmp(argv[1], "--port") == 0) {
            if (argc < 3) {
                fprintf(stderr, "Error: -p requires a port specification\n");
                fprintf(stderr, "Usage: %s -p PORT[,PORT...]\n", argv[0]);
                fprintf(stderr, "       %s -l (list available ports)\n", argv[0]);
                return 1;
            }
            
            // Parse comma-separated device IDs
            char *token = strtok(argv[2], ",");
            while (token != NULL && numDevices < MAX_DEVICES) {
                devIDs[numDevices] = (UINT)atoi(token);
                numDevices++;
                token = strtok(NULL, ",");
            }
        }
        else if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
            printf("Usage: %s [OPTIONS]\n", argv[0]);
            printf("MIDI input monitor (aseqdump compatible)\n\n");
            printf("Options:\n");
            printf("  -l, --list           List available MIDI input ports\n");
            printf("  -p, --port PORT      Specify port(s) to listen to (comma-separated)\n");
            printf("  -h, --help           Display this help message\n");
            printf("\nExamples:\n");
            printf("  %s -l              List all MIDI devices\n", argv[0]);
            printf("  %s -p 0            Listen to device 0\n", argv[0]);
            printf("  %s -p 0,1          Listen to devices 0 and 1\n", argv[0]);
            return 0;
        }
        else {
            devIDs[0] = (UINT)atoi(argv[1]);
            numDevices = 1;
        }
    }
    
    // If no devices specified, default to device 0
    if (numDevices == 0) {
        devIDs[0] = 0;
        numDevices = 1;
    }
    
    UINT devCount = midiInGetNumDevs();
    if (devCount == 0) {
        fprintf(stderr, "Error: No MIDI input devices found.\n");
        return 1;
    }
    
    // Validate device IDs
    for (int i = 0; i < numDevices; i++) {
        if (devIDs[i] >= devCount) {
            fprintf(stderr, "Error: Invalid device ID %u. Use -l to list available devices.\n", devIDs[i]);
            return 1;
        }
    }
    
    // Open and start MIDI devices
    HMIDIIN hMidi[MAX_DEVICES];
    MIDIHDR hdrs[MAX_DEVICES][SYSEX_BUFFERS];
    BYTE sysexBuf[MAX_DEVICES][SYSEX_BUFFERS][SYSEX_SIZE];
    
    fprintf(stderr, "Waiting for data. Press Ctrl+C to end.\n");
    fprintf(stderr, "Source  Event                    Ch  Data\n");
    
    for (int i = 0; i < numDevices; i++) {
        MMRESULT res = midiInOpen(&hMidi[i], devIDs[i], (DWORD_PTR)MidiInProc, (DWORD_PTR)devIDs[i], CALLBACK_FUNCTION);
        if (res != MMSYSERR_NOERROR) {
            fprintf(stderr, "Error: midiInOpen failed for device %u (error %u)\n", devIDs[i], res);
            // Close already opened devices
            for (int j = 0; j < i; j++) {
                midiInStop(hMidi[j]);
                midiInClose(hMidi[j]);
            }
            return 1;
        }
        
        // Prepare SysEx buffers
        memset(hdrs[i], 0, sizeof(hdrs[i]));
        for (int j = 0; j < SYSEX_BUFFERS; j++) {
            hdrs[i][j].lpData = (LPSTR)sysexBuf[i][j];
            hdrs[i][j].dwBufferLength = SYSEX_SIZE;
            hdrs[i][j].dwBytesRecorded = 0;
            midiInPrepareHeader(hMidi[i], &hdrs[i][j], sizeof(hdrs[i][j]));
            midiInAddBuffer(hMidi[i], &hdrs[i][j], sizeof(hdrs[i][j]));
        }
        
        // Start MIDI input
        midiInStart(hMidi[i]);
    }
    
    // Keep program running until Ctrl+C or Q/Esc
    // Note: Ctrl+C detection via _getch() may not work reliably in all scenarios
    // For production use, consider implementing SetConsoleCtrlHandler()
    while (1) {
        Sleep(100);
        if (_kbhit()) {
            int c = _getch();
            if (c == 27 || c == 'q' || c == 'Q' || c == 3) break;  // ESC, Q, or Ctrl+C
        }
    }
    
    // Stop and close all MIDI devices
    for (int i = 0; i < numDevices; i++) {
        midiInStop(hMidi[i]);
        midiInClose(hMidi[i]);
    }
    
    return 0;
}
