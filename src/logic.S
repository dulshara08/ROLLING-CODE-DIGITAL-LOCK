;------------------------------------------------------------------------------
; security.S - LFSR AND VERIFICATION
;------------------------------------------------------------------------------
; Handles shifting the 16-bit seed, and converting the 
; hex values into user-friendly decimal ASCII for comparisons.

#include "config.inc"

.section .text
.global LFSR_UPDATE, VALIDATE_ROLLING_CODE, MAKE_DECIMAL, SHOW_CURRENT_SEED

LFSR_UPDATE:
    ; 16-bit Linear Feedback Shift Register (Galois Configuration)
    lsl seed_L              ; Logical Shift Left the lower byte
    rol seed_H              ; Rotate Left the upper byte (brings in carry from seed_L)
    brcc lfsr_done          
    ldi temp, 0xB4          ; If carry bit is 1, XOR with the polynomial tap (0xB4)
    eor seed_L, temp
lfsr_done:
    ret

VALIDATE_ROLLING_CODE:
    ; Compares the 4 digits typed by the user (stored in 'buffer') 
    ; against the 4 hex nibbles of the current 16-bit seed.
    
    ; Check Digit 1 (High Nibble of High Byte)
    mov r20, seed_H
    swap r20                ; Move top 4 bits to bottom
    andi r20, 0x0F          ; Isolate the nibble
    rcall MAKE_DECIMAL      ; Convert A-F to 0-5
    lds r21, buffer         ; Load user's 1st typed char
    subi r21, 48            ; Convert ASCII ('0'-'9') to raw number (0-9)
    cp r20, r21
    brne val_fail           ; If they don't match, instantly fail

    ; Check Digit 2 (Low Nibble of High Byte)
    mov r20, seed_H
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    lds r21, buffer+1       ; Load user's 2nd typed char
    subi r21, 48
    cp r20, r21
    brne val_fail

    ; Check Digit 3 (High Nibble of Low Byte)
    mov r20, seed_L
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    lds r21, buffer+2       ; Load user's 3rd typed char
    subi r21, 48
    cp r20, r21
    brne val_fail

    ; Check Digit 4 (Low Nibble of Low Byte)
    mov r20, seed_L
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    lds r21, buffer+3       ; Load user's 4th typed char
    subi r21, 48
    cp r20, r21
    brne val_fail

    ldi temp, 1             ; Success! Return 1 in temp
    ret
val_fail:
    ldi temp, 0             ; Failure. Return 0 in temp
    ret

MAKE_DECIMAL:
    ; Converts hexadecimal values (A-F) into decimal (0-5) 
    ; so the keypad can type them (since the keypad has no A-F keys).
    cpi r20, 10
    brlo is_dec             ; If number is 0-9, leave it alone
    subi r20, 10            ; If number is 10-15 (A-F), subtract 10 (A=0, B=1, etc)
is_dec:
    ret

SHOW_CURRENT_SEED:
    ; Breaks the 16-bit seed into 4 printable ASCII characters and sends to LCD
    
    ; Digit 1
    mov r20, seed_H
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48           ; Convert raw number to ASCII (subtract negative = add)
    mov temp, r20
    rcall DATA_4BIT
    
    ; Digit 2
    mov r20, seed_H
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48
    mov temp, r20
    rcall DATA_4BIT
    
    ; Digit 3
    mov r20, seed_L
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48
    mov temp, r20
    rcall DATA_4BIT
    
    ; Digit 4
    mov r20, seed_L
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48
    mov temp, r20
    rcall DATA_4BIT
    ret
