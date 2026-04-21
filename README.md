# 🔐 AVR Rolling Code Digital Lock
A high-security digital lock system written in **AVR Assembly** for the ATmega328P. This project features a dynamic rolling code algorithm, EEPROM persistence, and a math-based "Deadlock" recovery system.

## ✨ Key Features
* **Rolling Code Logic:** Uses a Linear Feedback Shift Register (LFSR) to generate a new 4-digit code after every successful entry.
* **Entropy Injection:** Uses hardware timer `TCNT0` to inject randomness into the seed based on user input timing.
* **EEPROM Persistence:** Saves the current code seed to non-volatile memory so the lock remembers its state after a power cut.
* **Deadlock Recovery:** If an incorrect code is entered twice, the system enters a "Deadlock" state. Users must solve a 9's complement math challenge to reset the system.
* **4-Bit LCD Interface:** Optimized assembly routines to drive a 16x2 LCD with minimal pin usage.
* **Hardware Feedback:** Includes integrated buzzer alerts and LED status indicators.

## 🛠️ Hardware Components
* **MCU:** ATmega328P (Arduino Uno form factor)
* **Display:** LM016L (16x2 LCD)
* **Input:** 4x3 Numeric Keypad
* **Output:** Solenoid Lock (on PC5), Buzzer (on PD2), Error LED (on PC4)

## 🚀 How to Run
1. **Compilation:** Use `AVRA` or `AVR-GCC` to compile the `main.S` source code into a `.hex` file.
2. **Simulation:** Open the provided Proteus project in the `/simulation` folder.
3. **Flashing:** Double-click the ATmega328P in Proteus and load the `lock_firmware.hex` file.
4. **Interaction:**
   - Press `#` to begin entry.
   - Enter the 4-digit code shown on the screen (initial default is `1234`).
   - Upon success, the solenoid triggers and a **NEW** code is generated for next time.

## 🧠 Logic Flow: The Deadlock
This system implements a "9's Complement" recovery.
1. The screen displays a 2-digit challenge (e.g., `LOCK: 27`).
2. The user must calculate `9 - digit` for both numbers.
3. For `27`, the correct entry would be `72#`.
4. This resets the seed without opening the door, ensuring physical security.
