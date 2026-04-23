;------------------------------------------------------------------------------
; security.S - LFSR AND VERIFICATION
;------------------------------------------------------------------------------

#include "config.inc"

.section .text
.global LFSR_UPDATE, VALIDATE_ROLLING_CODE, MAKE_DECIMAL, SHOW_CURRENT_SEED

LFSR_UPDATE:
    lsl seed_L
    rol seed_H
    brcc lfsr_done
    ldi temp, 0xB4
    eor seed_L, temp
lfsr_done:
    ret

VALIDATE_ROLLING_CODE:
    mov r20, seed_H
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    lds r21, buffer
    subi r21, 48
    cp r20, r21
    brne val_fail
    mov r20, seed_H
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    lds r21, buffer+1
    subi r21, 48
    cp r20, r21
    brne val_fail
    mov r20, seed_L
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    lds r21, buffer+2
    subi r21, 48
    cp r20, r21
    brne val_fail
    mov r20, seed_L
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    lds r21, buffer+3
    subi r21, 48
    cp r20, r21
    brne val_fail
    ldi temp, 1
    ret
val_fail:
    ldi temp, 0
    ret

MAKE_DECIMAL:
    cpi r20, 10
    brlo is_dec
    subi r20, 10
is_dec:
    ret

SHOW_CURRENT_SEED:
    mov r20, seed_H
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48
    mov temp, r20
    rcall DATA_4BIT
    mov r20, seed_H
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48
    mov temp, r20
    rcall DATA_4BIT
    mov r20, seed_L
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48
    mov temp, r20
    rcall DATA_4BIT
    mov r20, seed_L
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    subi r20, -48
    mov temp, r20
    rcall DATA_4BIT
    ret