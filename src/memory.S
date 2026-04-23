;------------------------------------------------------------------------------
; utilis.S - DELAYS, BEEP, AND EEPROM
;------------------------------------------------------------------------------
; Contains hardware delays, the piezo buzzer routine, and non-volatile memory logic.

#include "config.inc"

.section .text
.global SAVE_SEED_TO_EEPROM, EEPROM_READ, EEPROM_WRITE
.global BEEP_ONCE, DELAY_MS, DELAY_LONG, DELAY_2SEC

SAVE_SEED_TO_EEPROM:
    ; Saves the 16-bit seed into EEPROM at Addresses 0x0010 and 0x0011
    ldi r18, 0x00           ; EEPROM Address High Byte
    ldi r17, 0x10           ; EEPROM Address Low Byte (0x10)
    mov temp, seed_H        ; Data to save
    rcall EEPROM_WRITE
    
    ldi r17, 0x11           ; Next address (0x11)
    mov temp, seed_L
    rcall EEPROM_WRITE
    ret

EEPROM_READ:
    sbic EECR, EEPE         ; Check EEPROM Programming Enable bit
    rjmp EEPROM_READ        ; If busy, loop until hardware is free
    out EEARH, r18          ; Set Address High
    out EEARL, r17          ; Set Address Low
    sbi EECR, EERE          ; Trigger Read Enable
    in temp, EEDR           ; Read data from Data Register into 'temp'
    ret

EEPROM_WRITE:
    sbic EECR, EEPE         ; Wait for completion of previous write
    rjmp EEPROM_WRITE
    out EEARH, r18          ; Set Address High
    out EEARL, r17          ; Set Address Low
    out EEDR, temp          ; Put data into Data Register
    sbi EECR, EEMPE         ; Set Master Write Enable (Hardware security feature)
    sbi EECR, EEPE          ; Start write within 4 clock cycles
    ret

BEEP_ONCE:
    ; Generates a square wave on PORTD.2 for a buzzer
    ldi r22, 200            ; Number of wave cycles to generate
beep_wave:
    sbi PORTD, 2            ; Speaker HIGH
    rcall DELAY_MS          
    cbi PORTD, 2            ; Speaker LOW
    rcall DELAY_MS          
    dec r22
    brne beep_wave
    ret

; --- SOFTWARE DELAYS ---
; Nested loop delays consuming instruction cycles to create pauses.
; Assumes ~1MHz default clock. 

DELAY_MS:
    ldi r20, 20
dms_outer:
    ldi r21, 200
dms_inner:
    dec r21
    brne dms_inner
    dec r20
    brne dms_outer
    ret

DELAY_LONG:
    ldi r22, 20
dl_loop:
    rcall DELAY_MS
    dec r22
    brne dl_loop
    ret

DELAY_2SEC:
    ldi r20, 100
d2s_1:
    ldi r21, 255
d2s_2:
    ldi r22, 100
d2s_3:
    nop
    nop
    dec r22
    brne d2s_3
    dec r21
    brne d2s_2
    dec r20
    brne d2s_1
    ret