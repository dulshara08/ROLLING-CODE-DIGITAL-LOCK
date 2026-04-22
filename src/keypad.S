#include "config.inc"
.section .text
.global KEYPAD_SCAN, GET_INPUT_STRING, WAIT_RELEASE

KEYPAD_SCAN:
    ; ... (Your scanning logic)
    ret

GET_INPUT_STRING:
    ; ... (The loop that fills the buffer)
    ret