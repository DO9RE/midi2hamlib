// xcode-select --install
// gcc -o mac_midi_monitor mac_midi_monitor.c -framework CoreMIDI -framework CoreFoundation
#include <CoreMIDI/CoreMIDI.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

void MyMIDINotifyProc(const MIDINotification *message, void *refCon) {
    // Benachrichtigungen ignorieren
}

// Hilfsfunktion zur Interpretation von MIDI-Nachrichten
void parseMIDIMessage(const unsigned char *data, unsigned int length) {
    if (length < 1) return;

    unsigned char status = data[0];
    unsigned char command = status & 0xF0;
    unsigned char channel = status & 0x0F;

    switch (command) {
        case 0x80: // Note Off
            if (length >= 3)
                printf("Note Off, Channel %d, Note %d, Velocity %d\n", channel + 1, data[1], data[2]);
            break;
        case 0x90: // Note On
            if (length >= 3)
                printf("Note On, Channel %d, Note %d, Velocity %d\n", channel + 1, data[1], data[2]);
            break;
        case 0xA0: // Polyphonic Key Pressure
            if (length >= 3)
                printf("Poly Pressure, Channel %d, Note %d, Pressure %d\n", channel + 1, data[1], data[2]);
            break;
        case 0xB0: // Control Change
            if (length >= 3)
                printf("Control Change, Channel %d, Controller %d, Value %d\n", channel + 1, data[1], data[2]);
            break;
        case 0xC0: // Program Change
            if (length >= 2)
                printf("Program Change, Channel %d, Program %d\n", channel + 1, data[1]);
            break;
        case 0xD0: // Channel Pressure
            if (length >= 2)
                printf("Channel Pressure, Channel %d, Pressure %d\n", channel + 1, data[1]);
            break;
        case 0xE0: // Pitch Bend
            if (length >= 3) {
                int value = (data[2] << 7) | data[1];
                printf("Pitch Bend, Channel %d, Value %d\n", channel + 1, value - 8192);
            }
            break;
        default:
            printf("Unknown MIDI Message: ");
            for (unsigned int i = 0; i < length; i++) {
                printf("%02X ", data[i]);
            }
            printf("\n");
            break;
    }
}

void MyMIDIReadProc(const MIDIPacketList *pktlist, void *refCon, void *connRefCon) {
    MIDIPacket *packet = (MIDIPacket *)pktlist->packet;
    for (unsigned int i = 0; i < pktlist->numPackets; i++) {
        printf("[%p] ", connRefCon); // Port identifier
        parseMIDIMessage(packet->data, packet->length);
        packet = MIDIPacketNext(packet);
    }
}

void listMIDIDevices() {
    ItemCount numSources = MIDIGetNumberOfSources();
    printf("Available MIDI devices:\n");
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef endpointName = NULL;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &endpointName);
        if (endpointName != NULL) {
            char name[128];
            CFStringGetCString(endpointName, name, sizeof(name), kCFStringEncodingUTF8);
            printf("  [%lu] %s\n", i, name);
            CFRelease(endpointName);
        } else {
            printf("  [%lu] Unknown Device\n", i);
        }
    }
}

int findMIDIPortByName(const char *name) {
    ItemCount numSources = MIDIGetNumberOfSources();
    for (ItemCount i = 0; i < numSources; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);
        CFStringRef endpointName = NULL;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &endpointName);
        if (endpointName != NULL) {
            char deviceName[128];
            CFStringGetCString(endpointName, deviceName, sizeof(deviceName), kCFStringEncodingUTF8);
            CFRelease(endpointName);
            if (strcmp(deviceName, name) == 0) {
                return i;
            }
        }
    }
    return -1; // Not found
}

int main(int argc, char *argv[]) {
    int listFlag = 0;
    int portIndex = -1;
    char *portName = NULL;

    // Kommandozeilenargumente parsen
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-l") == 0 || strcmp(argv[i], "--list") == 0) {
            listFlag = 1;
        } else if (strcmp(argv[i], "-p") == 0 || strcmp(argv[i], "--port") == 0) {
            if (i + 1 < argc) {
                portName = argv[++i];
                // Check if it is a number (port index) or a name (device name)
                if (isdigit(portName[0])) {
                    portIndex = atoi(portName);
                } else {
                    portIndex = findMIDIPortByName(portName);
                    if (portIndex == -1) {
                        fprintf(stderr, "Error: MIDI device '%s' not found.\n", portName);
                        return 1;
                    }
                }
            } else {
                fprintf(stderr, "Error: Missing argument for -p/--port\n");
                return 1;
            }
        }
    }

    if (listFlag) {
        listMIDIDevices();
        return 0;
    }

    MIDIClientRef client;
    MIDIPortRef inPort;
    OSStatus result;

    result = MIDIClientCreate(CFSTR("MIDI Monitor"), MyMIDINotifyProc, NULL, &client);
    if (result != noErr) {
        fprintf(stderr, "Error creating MIDI client: %d\n", result);
        return 1;
    }

    result = MIDIInputPortCreate(client, CFSTR("Input Port"), MyMIDIReadProc, NULL, &inPort);
    if (result != noErr) {
        fprintf(stderr, "Error creating MIDI input port: %d\n", result);
        return 1;
    }

    ItemCount numSources = MIDIGetNumberOfSources();
    if (portIndex >= 0) {
        if (portIndex >= numSources) {
            fprintf(stderr, "Error: Invalid port index %d\n", portIndex);
            return 1;
        }
        MIDIEndpointRef source = MIDIGetSource(portIndex);
        result = MIDIPortConnectSource(inPort, source, (void *)source);
        if (result != noErr) {
            fprintf(stderr, "Error connecting to source %d: %d\n", portIndex, result);
            return 1;
        }
        printf("Listening for MIDI messages on port '%s'...\n", portName ? portName : "Unknown");
    } else {
        for (ItemCount i = 0; i < numSources; i++) {
            MIDIEndpointRef source = MIDIGetSource(i);
            result = MIDIPortConnectSource(inPort, source, (void *)source);
            if (result != noErr) {
                fprintf(stderr, "Error connecting to source %lu: %d\n", i, result);
            }
        }
        printf("Listening for MIDI messages on all ports...\n");
    }

    CFRunLoopRun(); // Start the run loop to receive MIDI messages

    MIDIClientDispose(client);
    return 0;
}
