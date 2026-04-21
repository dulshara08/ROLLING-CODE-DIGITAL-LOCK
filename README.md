# Rolling Code Digital Lock

This repository is for a **Rolling Code Digital Lock** project.

A rolling code lock system improves security by changing the valid unlock code after each successful use, helping prevent replay and reuse attacks.

## Project Status

This repository now includes the final AVR assembly implementation of the lock system in:

- `main.asm`

## Goals

- Build a secure digital lock system using rolling/one-time codes
- Reduce risk from captured or repeated unlock signals
- Provide a clear and maintainable implementation

## Implemented Components

- Rolling code validation (`VALIDATE_ROLLING_CODE`)
- LFSR-based next-code update (`LFSR_UPDATE`)
- EEPROM seed persistence (`EEPROM_READ` / `EEPROM_WRITE`)
- Keypad scanning (`KEYPAD_SCAN`)
- LCD output in 4-bit mode
- Error handling, buzzer alert, and deadlock state

## Repository Structure

- `main.asm` — complete AVR assembly source for the digital lock
- `README.md` — project documentation

## Build and Flash (AVR Toolchain)

1. Clone the repository:
   ```bash
   git clone https://github.com/dulshara08/ROLLING-CODE-DIGITAL-LOCK.git
   ```
2. Open the project directory:
   ```bash
   cd ROLLING-CODE-DIGITAL-LOCK
   ```
3. Assemble and link (example for ATmega32):
   ```bash
   avr-gcc -mmcu=atmega32 -x assembler-with-cpp -o lock.elf main.asm
   avr-objcopy -O ihex lock.elf lock.hex
   ```
4. Flash to MCU (example with USBasp):
   ```bash
   avrdude -c usbasp -p m32 -U flash:w:lock.hex:i
   ```

> Update `-mmcu` / `-p` values to match your exact AVR chip.

## Contributing

Contributions are welcome. If you'd like to contribute:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a pull request

## License

No license has been added yet.  
Consider adding a license file (for example, MIT) to define usage terms.
