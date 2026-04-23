;------------------------------------------------------------------------------
; keypad.S - MATRIX KEYPAD SCANNER
;------------------------------------------------------------------------------
; Scans a 4x3 matrix keypad.
; Rows are on PORTB (Pins 0-3), set as outputs.
; Columns are on PINC (Pins 0-2), set as inputs with pull-ups.
; A button press pulls the column low.

#include "config.inc"

.section .text
.global KEYPAD_SCAN, GET_INPUT_STRING, WAIT_FOR_KEY_ACTIVE, WAIT_RELEASE

WAIT_FOR_KEY_ACTIVE:
    rcall KEYPAD_SCAN
    cpi key_val, 0xFF       ; 0xFF means no key pressed
    breq WAIT_FOR_KEY_ACTIVE ; Block until a key is physically held down
    
    ; Accumulate randomness from Hardware Timer 0
    ; The unpredictable human reaction time randomizes the LFSR
    in temp, TCNT0
    eor entropy, temp
    ret

WAIT_RELEASE:
    rcall KEYPAD_SCAN
    cpi key_val, 0xFF       ; Check if fingers are off the keypad
    brne WAIT_RELEASE       ; Block until keypad is completely released
    rcall DELAY_MS          ; Debounce delay to prevent double-reads
    ret

GET_INPUT_STRING:
    ldi XL, lo8(buffer)     ; Load X pointer with RAM buffer address
    ldi XH, hi8(buffer)
    ldi r22, 0              ; Initialize digit counter to 0

input_loop:
    rcall WAIT_FOR_KEY_ACTIVE   
    cpi key_val, 35             ; If user presses '#', abort entry early 
    breq input_done
    
    st X+, key_val              ; Store ASCII character in RAM and increment pointer
    mov temp, key_val                
    rcall DATA_4BIT             ; Echo character to the LCD
    rcall WAIT_RELEASE          ; Wait for finger to lift
    
    inc r22                     ; Increment entered digit count
    cpi r22, 4                  ; Lock needs exactly 4 digits
    brne input_loop             ; Loop until 4 digits are typed
input_done:
    ret

KEYPAD_SCAN:
    ; Drive all rows HIGH initially
    sbi PORTB, 0
    sbi PORTB, 1
    sbi PORTB, 2
    sbi PORTB, 3

    ; --- SCAN ROW 1 ---
    cbi PORTB, 0            ; Pull Row 1 LOW
    nop                     ; Wait 1 cycle for logic to settle
    sbis PINC, 0            ; Check Column 1 (Skips next instruction if HIGH)
    ldi key_val, '1'
    sbis PINC, 0
    ret                     ; Return if '1' is pressed
    sbis PINC, 1            ; Check Column 2
    ldi key_val, '2'
    sbis PINC, 1
    ret
    sbis PINC, 2            ; Check Column 3
    ldi key_val, '3'
    sbis PINC, 2
    ret
    sbi PORTB, 0            ; Restore Row 1 to HIGH
    
    ; --- SCAN ROW 2 ---
    cbi PORTB, 1            ; Pull Row 2 LOW
    nop
    sbis PINC, 0
    ldi key_val, '4'
    sbis PINC, 0
    ret
    sbis PINC, 1
    ldi key_val, '5'
    sbis PINC, 1
    ret
    sbis PINC, 2
    ldi key_val, '6'
    sbis PINC, 2
    ret
    sbi PORTB, 1            ; Restore Row 2 to HIGH
    
    ; --- SCAN ROW 3 ---
    cbi PORTB, 2            ; Pull Row 3 LOW
    nop
    sbis PINC, 0
    ldi key_val, '7'
    sbis PINC, 0
    ret
    sbis PINC, 1
    ldi key_val, '8'
    sbis PINC, 1
    ret
    sbis PINC, 2
    ldi key_val, '9'
    sbis PINC, 2
    ret
    sbi PORTB, 2            ; Restore Row 3 to HIGH
    
    ; --- SCAN ROW 4 ---
    cbi PORTB, 3            ; Pull Row 4 LOW
    nop
    sbis PINC, 0
    ldi key_val, 42         ; ASCII 42 is '*'
    sbis PINC, 0
    ret
    sbis PINC, 1
    ldi key_val, '0'
    sbis PINC, 1
    ret
    sbis PINC, 2
    ldi key_val, 35         ; ASCII 35 is '#'
    sbis PINC, 2
    ret
    sbi PORTB, 3            ; Restore Row 4 to HIGH
    
    ldi key_val, 0xFF       ; If nothing is low, return 0xFF (Idle)
    ret