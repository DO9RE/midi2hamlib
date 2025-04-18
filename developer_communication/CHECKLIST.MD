# Checklist, Todo and ideas

- [ ] Rework function selection / toggling.

## **Note by DK7STJ – 2025-04-18:**  

  Selecting and toggling a function alternately by MIDI and by menu doesn't work as expected.
  Toggling a function by menu doesn't update the variable n which the last function state is stored. So toggling it afterwards by MIDI yields wrong results.
  Either do not use last function state and always get status from TRX
  first, or update function state when using menu.

- [ ] We need to compile the latest Hamlib from its Repo, cause the Version which comes with aptAPT on Bookworm is 2 years old.

## **Note by DO9RE – 2025-04-18:**  

  https://github.com/Hamlib/Hamlib/releases/download/4.6.2/hamlib-4.6.2.tar.gz
  Sources.
  DK7STJ told me, he will check the task after his vacations.

- [ ] The application should also benefit visually impaired users. Therefore, we need to consider a visually impaired-friendly display. In the console, there is the option to enlarge the font and use alternative fonts. We also need to think about alternative color representations. We must examine how an alternative display affects the ability of the Fenrir screen reader to read the text in the console. A small screen can then be connected to the Raspberry Pi to provide access to the system for sighted users who may only need a small adjustment.

- [ ] MIDI ports can change, but device names remain consistent. 

## **Note by DO9RE – 2025-04-16:**  

  We can use `aconnect -i` to display a list of MIDI devices, which will appear with their names. Finally, you can access the device directly with `aseqdump -p 'device name'`. 
  Question: What needs to be changed in the script to work with the more reliable device names instead of the previously used port numbers?
  How can we preserve multi device usage possibility?

## **Note by DK7STJ – 2025-04-17:**  

  aseqdump uses the same command-line option regardless if you give a client name or numeric port. Also should accept more than one clients.
  I cannot test this, only have one MIDI device.
  Questions: Can device names contain spaces? What if two identical controllers are connected?

## **Note by DO9RE – 2025-04-17:**  
  midi_ports is now called midi_devices.  
  Names of MIDI devices can be entered in quotation marks.  
  The reader generates a list of ports for these device names by using ASEQDUMP -L, filtering with grep and sed. Head -n 1 outputs only the first line.  
  Variable_Name changed both in the settings and in the reader.  
  Tests with a MIDI device name worked, need to wait until I have two devices available again.

- [ ] Ensure that the numeric keypad is automatically enabled on all virtual consoles at system startup, allowing for numeric input.

## **Note by DK7STJ – 2025-04-16:**  

  - numlock state of main keyboard can be set with setleds.
  - This however also changes numlock on smal keyboards like on pi400, where leters jkl are then 123. this is maybe not what you want when you also need to type text.
  - Additional numpad seems to have independent numlock state and works out of the box.
  - Don't know how to contol state of additional numpad. Neither setleds nor writing to sys/leds.. works. 
  - How shall we proceed? Add a flag in settings to set numlock at startup?

## **Note by DO9RE – 2025-04-16:**  
  Added
  ```
  setleds +num
  ```
  to the start script to ensure numlock is always on.
  Stays still the question, how to handle other external numpads.

- [ ] Plan for multilingual support in the long term. Decide whether to handle translations directly in the script or implement a more professional solution. Note: Menu entries are currently embedded as comments in the menu definition files, which complicates proper translation via variables.

- [ ] Validate all user inputs in text fields and all settings via knobs or sliders to prevent meaningless or out-of-range values.

- [ ] Decide on a method for setting the frequency. None of the currently available hardware interfaces provide continuous data from rotary knobs (limited to 0–127 range). Pending: test DJ controller functionality. Interim solution:  
  - Use one rotary control to set the frequency step size (in Hz).  
  - Use two buttons to increase or decrease the frequency based on the step size.

- [x] Test Braille display compatibility. How straightforward is it to connect a Braille output device to the screen reader?

## **Note by DO9RE – 2025-04-16:**  
  After running 
  ```bash
  sudo apt-get install brltty
  ```  
  the Braille display was functional in the terminal within approximately 10 seconds.  
   Tested with a Focus 40 Blue display.

## **Note by DO9RE – 2025-04-17:**  

   Added a small section to the installation hints about BRLTTY, so I consider this point as successfully done, changed checkmark accordingly.

- [ ] Implement "Fast Log" feature directly from the script using available telemetry data.

- [ ] Optimize boot time. On a Raspberry Pi 4 (4 GB or 8 GB), the system currently takes around 25 seconds to start.  
  - Identify services that can be disabled without impacting functionality.  
  - Explore additional boot-time optimizations.

- [ ] Implement control commands for speech output (e.g. speech rate, volume, comfort settings). These must be accessible through the menu system, as not every user will have a full keyboard, and essential keys like those on the numpad may be unavailable.

- [ ] Investigate whether additional keys on USB numeric keypads (e.g. volume dials or extra buttons) can be repurposed for useful functionality.

- [ ] Check for RF interference. Does the Raspberry Pi emit high-frequency signals that could require mitigation when placed near a transceiver?

- [ ] Implement automated polling of transceiver state at fixed intervals (e.g. every 500 ms or 1 second).  
  - The system should compare current values with previous ones.  
  - When a change is detected (e.g. someone pressed a button or changed the frequency), it should be announced.

- [ ] Evaluate whether all values need to be polled continuously, or if some can be excluded to conserve bandwidth.

- [ ] RIGCTL commands.
## **Note by DO9RE – 2025-04-17:**  

  I copied the list from --help. We will work down and document for each command, whats been done to integrate it into the system.
  As I transfer the list into markdown, I see, that there are a few commands to get lists. VFO and Mode List for example. Maybe we can use these instead of fetching stuff from --dump-caps.
  We should decide, if we use the short or long form of the commands in our function scripts. 

### F: set_freq        (Frequency)         
### f: get_freq        ()
### M: set_mode        (Mode,Passband)     
### m: get_mode        ()
### I: set_split_freq  (TX Frequency)      
### i: get_split_freq  ()
### X: set_split_mode  (TX Mode,TX Passband) 
### x: get_split_mode  ()
### K: set_split_freq_mode(TX Frequency,TX Mode,TX Passband)              
### k: get_split_freq_mode()
### S: set_split_vfo   (Split,TX VFO)      
### s: get_split_vfo   ()
### N: set_ts          (Tuning Step)       
### n: get_ts          ()
### L: set_level       (Level,Level Value) 
### l: get_level       (Level)
### U: set_func        (Func,Func Status)  
### u: get_func        (Func)
### P: set_parm        (Parm,Parm Value)   
### p: get_parm        (Parm)
### G: vfo_op          (Mem/VFO Op)        
### g: scan            (Scan Fct,Scan Channel)
### A: set_trn         (Transceive)        
### a: get_trn         ()
### R: set_rptr_shift  (Rptr Shift)        
### r: get_rptr_shift  ()
### O: set_rptr_offs   (Rptr Offset)       
### o: get_rptr_offs   ()
### C: set_ctcss_tone  (CTCSS Tone)        
### c: get_ctcss_tone  ()
### D: set_dcs_code    (DCS Code)          
### d: get_dcs_code    ()
### ?: set_ctcss_sql   (CTCSS Sql)         
### ?: get_ctcss_sql   ()
### ?: set_dcs_sql     (DCS Sql)           
### ?: get_dcs_sql     ()
### V: set_vfo         (VFO)               
### v: get_vfo         ()
### T: set_ptt         (PTT)               
### t: get_ptt         ()
### E: set_mem         (Memory#)           
### e: get_mem         ()
### H: set_channel     (Channel)           
### h: get_channel     (Channel,Read Only)
### B: set_bank        (Bank)              
### _: get_info        ()
### J: set_rit         (RIT)               
### j: get_rit         ()
### Z: set_xit         (XIT)               
### z: get_xit         ()
### Y: set_ant         (Antenna,Option)    
### y: get_ant         (AntCurr)
### ?: set_powerstat   (Power Status)      
### ?: get_powerstat   ()
### ?: send_dtmf       (Digits)            
### ?: recv_dtmf       ()
### *: reset           (Reset)             
### w: send_cmd        (Cmd)
### W: send_cmd_rx     (Cmd,Reply)         
### b: send_morse      (Morse)
### ?: stop_morse      ()                  
### ?: wait_morse      ()
### ?: send_voice_mem  (Voice Mem#)        
### ?: stop_voice_mem  ()
### ?: get_dcd         ()                  
### ?: set_twiddle     (Timeout (secs))
### ?: get_twiddle     ()                  
### ?: uplink          (1=Sub, 2=Main)
### ?: set_cache       (Timeout (msecs))   
### ?: get_cache       ()
### 2: power2mW        (Power [0.0..1.0],Frequency,Mode)             
### 4: mW2power        (Pwr mW,Freq,Mode)
### 1: dump_caps       ()                  
### 3: dump_conf       ()
### ?: dump_state      ()                  
### ?: chk_vfo         ()
### ?: set_vfo_opt     (Status)            
### ?: get_vfo_info    (VFO)
### ?: get_rig_info    ()                  
### ?: get_vfo_list    ()
### ?: get_modes       ()                  
### ?: get_clock       ()
### ?: set_clock       (local or utc or YYYY-MM-DDTHH:MM:SS.sss+ZZ or YYYY-MM-DDTHH:MM+ZZ)                                               
### ?: halt            ()
### ?: pause           (Seconds)           
### ?: password        (Password)
### ?: get_mode_bandwidths(Mode)              
### ?: set_separator   (Separator)
### ?: get_separator   ()                  
### ?: set_lock_mode   (Locked)
### ?: get_lock_mode   ()                  
### ?: send_raw        (Terminator,Command)
### ?: client_version  (Version)           
### ?: get_vfo_list    ()
### ?: test            (routine)           
### ?: hamlib_version  ()
### ?: get_gpio        (GPIO#)             
### ?: set_gpio        (GPIO#,0/1)
### ?: set_conf        (Token,Token Value) 
### ?: get_conf        (Token)


