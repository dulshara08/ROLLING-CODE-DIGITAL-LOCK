#include "config.inc"
.section .text
.global EEPROM_READ, EEPROM_WRITE, DELAY_MS, DELAY_2SEC

EEPROM_WRITE:
    sbic EECR, EEPE
    rjmp EEPROM_WRITE
    out EEARH, r18
    out EEARL, r17
    out EEDR, temp
    sbi EECR, EEMPE
    sbi EECR, EEPE
    ret