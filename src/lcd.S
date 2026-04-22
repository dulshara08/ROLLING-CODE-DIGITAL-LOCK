#include "config.inc"
.section .text
.global LCD_INIT_SEQUENCE, LCD_CLR, DATA_4BIT, CMD_4BIT

LCD_INIT_SEQUENCE:
    ; ... (Your initialization code here)
    ret

LCD_CLR:
    ldi temp, 0x01
    rcall CMD_4BIT
    ret

; ... (Include PULSE_EN and SEND_BYTE here as local helpers)