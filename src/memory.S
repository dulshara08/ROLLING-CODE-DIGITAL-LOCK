;------------------------------------------------------------------------------
; utils.S - DELAYS, BEEP, AND EEPROM
;------------------------------------------------------------------------------

#include "config.inc"

.section .text
.global SAVE_SEED_TO_EEPROM, EEPROM_READ, EEPROM_WRITE
.global BEEP_ONCE, DELAY_MS, DELAY_LONG, DELAY_2SEC

SAVE_SEED_TO_EEPROM:
    ldi r18, 0x00
    ldi r17, 0x10
    mov temp, seed_H
    rcall EEPROM_WRITE
    ldi r17, 0x11
    mov temp, seed_L
    rcall EEPROM_WRITE
    ret

EEPROM_READ:
    sbic EECR, EEPE       
    rjmp EEPROM_READ
    out EEARH, r18      
    out EEARL, r17
    sbi EECR, EERE          
    in temp, EEDR        
    ret

EEPROM_WRITE:
    sbic EECR, EEPE       
    rjmp EEPROM_WRITE
    out EEARH, r18      
    out EEARL, r17
    out EEDR, temp       
    sbi EECR, EEMPE         
    sbi EECR, EEPE         
    ret

BEEP_ONCE:
    ldi r22, 200        
beep_wave:
    sbi PORTD, 2        
    rcall DELAY_MS      
    cbi PORTD, 2        
    rcall DELAY_MS      
    dec r22
    brne beep_wave
    ret

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