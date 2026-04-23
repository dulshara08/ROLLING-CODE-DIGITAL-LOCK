;------------------------------------------------------------------------------
; main.S - ROLLING CODE DIGITAL LOCK
;------------------------------------------------------------------------------
; The primary application controller. It manages the High-Level states of
; the lock (Standby, Entry, Locked, Wiped) and coordinates the subroutines.

#include "config.inc"

.section .data
.global buffer
buffer:     .space 6        ; RAM allocation for user keypad input string

.section .text
.global main

main:
    ; --- 1. INITIALIZE STACK & PORTS ---
    ; Set the Stack Pointer to the top of RAM (mandatory for rcall/push/pop)
    ldi temp, lo8(RAMEND)
    out SPL, temp
    ldi temp, hi8(RAMEND)
    out SPH, temp

    ; Configure I/O Pins
    ldi temp, 0xF4          ; PORTD: D4-D7 outputs (LCD), D2 output (Buzzer)
    out DDRD, temp
    ldi temp, 0x3F          ; PORTB: B0-B3 outputs (Keypad Rows), B4,B5 outputs (LCD RS,EN)
    out DDRB, temp
    ldi temp, 0x30          ; PORTC: C4,C5 outputs (LEDs)
    out DDRC, temp
    ldi temp, 0x07          ; Enable internal Pull-ups on C0-C2 (Keypad Columns)
    out PORTC, temp

    ; --- START HARDWARE TIMER ---
    ; Timer0 runs continuously without prescaling. We read TCNT0 arbitrarily 
    ; during human interaction to generate RNG entropy.
    ldi temp, 0x01
    out TCCR0B, temp     

    clr fail_count          ; Reset failed attempts
    clr entropy             ; Clear random noise accumulator

    ; --- 2. LCD STARTUP ---
    rcall LCD_INIT_SEQUENCE

    ; --- 3. EEPROM SEED RECOVERY ---
    ldi r18, 0x00           
    ldi r17, 0x10           ; Target EEPROM address 0x0010
    rcall EEPROM_READ       ; Fetch High Byte
    mov seed_H, temp
    
    ldi r17, 0x11           ; Target EEPROM address 0x0011
    rcall EEPROM_READ       ; Fetch Low Byte
    mov seed_L, temp
    
    ; Check if EEPROM is uninitialized (0xFF is factory default)
    cpi seed_H, 0xFF
    brne STATE_STANDBY      ; If valid, jump to normal operation
    cpi seed_L, 0xFF
    brne STATE_STANDBY
    
    ; If EEPROM is blank, write a default hardcoded seed (0x1234)
    ldi seed_H, 0x12
    ldi seed_L, 0x34
    rcall SAVE_SEED_TO_EEPROM

; ==========================================
;        MAIN SYSTEM LOOP
; ==========================================

STATE_STANDBY:
    rcall LCD_CLR        

wait_for_keys:
    rcall KEYPAD_SCAN
    
    cpi key_val, 35         ; '#' Key pressed? Start password entry process
    breq start_code_entry

    cpi key_val, 42         ; '*' Key pressed? Trigger factory wipe sequence
    breq SYSTEM_WIPE

    rjmp wait_for_keys

start_code_entry:
    rcall WAIT_RELEASE      ; Ensure button is let go before proceeding

    ; Print "CODE:" UI
    ldi temp, 'C'
    rcall DATA_4BIT
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'D'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, ':'
    rcall DATA_4BIT

    ; Block and wait for 4 inputs
    rcall GET_INPUT_STRING

    ; Test the buffer against the seed
    rcall VALIDATE_ROLLING_CODE
    cpi temp, 1             ; Did the validation return 1?       
    breq UNLOCK_SYSTEM      ; Yes -> Open Lock
    rjmp HANDLE_FAILURE     ; No  -> Trigger Error

; ==========================================
;             ERASE LOGIC
; ==========================================

SYSTEM_WIPE:
    rcall WAIT_RELEASE
    rcall LCD_CLR
    
    ; Display "WIPE" status
    ldi temp, 'W'
    rcall DATA_4BIT
    ldi temp, 'I'
    rcall DATA_4BIT
    ldi temp, 'P'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT

    ; Overwrite EEPROM Seed Addresses with 0xFF
    ldi temp, 0xFF
    ldi r18, 0x00
    ldi r17, 0x10
    rcall EEPROM_WRITE
    
    ldi temp, 0xFF
    ldi r17, 0x11
    rcall EEPROM_WRITE

    ; Signal Success visually
    sbi PORTC, 5            ; Turn Green LED ON
    
halt:
    rjmp halt               ; Infinite loop (Forces physical reboot)

; ==========================================
;                OUTCOMES
; ==========================================

UNLOCK_SYSTEM:
    clr fail_count          ; Reset security lockouts

    rcall LCD_CLR
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'P'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, 'N'
    rcall DATA_4BIT

    sbi PORTC, 5            ; Turn Green LED ON
    rcall DELAY_2SEC    
    
    ; Generate the NEXT code to use and save it
    rcall LFSR_UPDATE       ; Shift polynomial
    eor seed_L, entropy     ; Inject human randomness
    clr entropy             ; Clear entropy
    rcall SAVE_SEED_TO_EEPROM
    
    ; Display the NEXT code for the user to memorize/write down
    rcall LCD_CLR
    ldi temp, 'N'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, 'X'
    rcall DATA_4BIT
    ldi temp, 'T'
    rcall DATA_4BIT
    ldi temp, ':'
    rcall DATA_4BIT

    rcall SHOW_CURRENT_SEED 
    
    rcall DELAY_2SEC
    rcall DELAY_2SEC
    cbi PORTC, 5            ; Turn Green LED OFF
    rjmp STATE_STANDBY      ; Return to idle

HANDLE_FAILURE:
    inc fail_count          ; Count the bad attempt
    
    rcall LCD_CLR
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, 'R'
    rcall DATA_4BIT
    ldi temp, 'R'
    rcall DATA_4BIT
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'R'
    rcall DATA_4BIT

    sbi PORTC, 4            ; Red LED ON
    rcall BEEP_ONCE         ; Sound alarm
    rcall DELAY_2SEC    
    cbi PORTC, 4            ; Red LED OFF

    cpi fail_count, 2       ; Did they fail 2 times?
    brge STATE_DEADLOCK     ; If >= 2, enter lockout mode
    rjmp STATE_STANDBY      ; Otherwise, let them try again

; ==========================================
;             DEADLOCK STATE
; ==========================================

STATE_DEADLOCK:
    ; Security feature: Prevents brute forcing.
    ; Shows 2 digits derived from the seed. The user must type the "9's complement"
    ; of those two digits to prove they are authorized to reset the lockout.

    rcall LCD_CLR       
    ldi temp, 'L'
    rcall DATA_4BIT
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'C'
    rcall DATA_4BIT
    ldi temp, 'K'
    rcall DATA_4BIT
    ldi temp, ':'
    rcall DATA_4BIT

    ; Extract 1st Challenge Digit (High nibble of seed_L)
    mov r20, seed_L
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    mov r8, r20             ; Store challenge digit 1 in r8

    ; Extract 2nd Challenge Digit (Low nibble of seed_L)
    mov r20, seed_L
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    mov r9, r20             ; Store challenge digit 2 in r9

    ; Display the challenge on LCD
    mov temp, r8
    subi temp, -48          ; Convert decimal back to ASCII
    rcall DATA_4BIT
    mov temp, r9
    subi temp, -48          ; Convert decimal back to ASCII
    rcall DATA_4BIT

    ldi temp, 0xC0          ; Move LCD Cursor to start of Bottom Row
    rcall CMD_4BIT

    ; Get user's recovery attempt
    rcall GET_INPUT_STRING

    ; Test 1st recovery digit (Requires 9 - Challenge = Input)
    ldi r18, 9
    sub r18, r8             ; r18 = 9 - challenge1
    lds temp, buffer        ; Get 1st char user typed
    subi temp, 48           ; Convert ASCII to number
    cp temp, r18            ; Compare
    brne DEADLOCK_FAIL

    ; Test 2nd recovery digit
    ldi r18, 9
    sub r18, r9             ; r18 = 9 - challenge2
    lds temp, buffer+1      ; Get 2nd char user typed
    subi temp, 48           
    cp temp, r18
    brne DEADLOCK_FAIL

    clr fail_count          ; Math is correct, clear the lockout
    rjmp STATE_STANDBY

DEADLOCK_FAIL:
    ; Shows a '?' to indicate bad math, loop back to lockdown
    rcall LCD_CLR
    ldi temp, '?'
    rcall DATA_4BIT
    rcall DELAY_2SEC
    rjmp STATE_DEADLOCK