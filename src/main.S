#include "config.inc"
.section .data
.global buffer
buffer: .space 6

.section .text
.global main

main:
    ; 1. SETUP
    rcall LCD_INIT_SEQUENCE
    rcall RECOVER_SEED ; (Calls EEPROM_READ internally)

STATE_STANDBY:
    rcall LCD_CLR
wait_loop:
    rcall KEYPAD_SCAN
    cpi key_val, 35
    breq start_entry
    rjmp wait_loop

start_entry:
    rcall GET_INPUT_STRING
    rcall VALIDATE_ROLLING_CODE
    ; ... and so on