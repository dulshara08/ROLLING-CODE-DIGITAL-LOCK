#include "config.inc"
.section .text
.global LFSR_UPDATE, VALIDATE_ROLLING_CODE, MAKE_DECIMAL

LFSR_UPDATE:
    lsl seed_L
    rol seed_H
    brcc lfsr_done
    ldi temp, 0xB4
    eor seed_L, temp
lfsr_done:
    ret

VALIDATE_ROLLING_CODE:
    ; ... (Logic to compare buffer to seed)
    ret