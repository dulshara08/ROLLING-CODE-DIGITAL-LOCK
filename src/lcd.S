;------------------------------------------------------------------------------
; lcd.S - LCD 4-BIT DRIVER
;------------------------------------------------------------------------------

#include "config.inc"

.section .text
.global LCD_INIT_SEQUENCE, LCD_CLR, CMD_4BIT, DATA_4BIT, PULSE_EN

LCD_INIT_SEQUENCE:
    rcall DELAY_LONG
    rcall DELAY_LONG
    cbi PORTB, 4        
    ldi temp, 0x30
    out PORTD, temp
    rcall PULSE_EN
    rcall DELAY_LONG
    ldi temp, 0x30
    out PORTD, temp
    rcall PULSE_EN
    rcall DELAY_LONG
    ldi temp, 0x30
    out PORTD, temp
    rcall PULSE_EN
    rcall DELAY_LONG
    ldi temp, 0x20       
    out PORTD, temp
    rcall PULSE_EN
    rcall DELAY_LONG
    ldi temp, 0x28       
    rcall CMD_4BIT
    ldi temp, 0x08       
    rcall CMD_4BIT
    rcall LCD_CLR       
    ldi temp, 0x06       
    rcall CMD_4BIT
    ldi temp, 0x0C       
    rcall CMD_4BIT
    ret

LCD_CLR:
    ldi temp, 0x01
    rcall CMD_4BIT
    rcall DELAY_LONG
    ret

PULSE_EN:
    sbi PORTB, 5
    rcall DELAY_MS
    cbi PORTB, 5
    rcall DELAY_MS
    ret

CMD_4BIT:
    cbi PORTB, 4
    rjmp SEND_BYTE

DATA_4BIT:
    sbi PORTB, 4

SEND_BYTE:
    push key_val
    mov key_val, temp
    andi key_val, 0xF0
    out PORTD, key_val
    rcall PULSE_EN
    mov key_val, temp
    swap key_val
    andi key_val, 0xF0
    out PORTD, key_val
    rcall PULSE_EN
    pop key_val
    ret