- [ ] Ensure that the numeric keypad is automatically enabled on all virtual consoles at system startup, allowing for numeric input.

- [ ] Plan for multilingual support in the long term. Decide whether to handle translations directly in the script or implement a more professional solution. Note: Menu entries are currently embedded as comments in the menu definition files, which complicates proper translation via variables.

- [ ] Validate all user inputs in text fields and all settings via knobs or sliders to prevent meaningless or out-of-range values.

- [ ] Decide on a method for setting the frequency. None of the currently available hardware interfaces provide continuous data from rotary knobs (limited to 0–127 range). Pending: test DJ controller functionality. Interim solution:  
  - Use one rotary control to set the frequency step size (in Hz).  
  - Use two buttons to increase or decrease the frequency based on the step size.

- [ ] Test Braille display compatibility. How straightforward is it to connect a Braille output device to the screen reader?

- [ ] Implement "Fast Lock" feature directly from the script using available telemetry data.

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
