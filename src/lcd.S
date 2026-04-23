;------------------------------------------------------------------------------
; lcd.S - LCD 4-BIT DRIVER
;------------------------------------------------------------------------------
; This module handles the HD44780 LCD controller in 4-bit mode.
; Hardware mapping:
;   PORTB.4 = RS (Register Select: 0=Command, 1=Data)
;   PORTB.5 = EN (Enable: Pulses high to latch data)
;   PORTD.4-7 = D4-D7 (Data lines)

#include "config.inc"

.section .text
.global LCD_INIT_SEQUENCE, LCD_CLR, CMD_4BIT, DATA_4BIT, PULSE_EN

LCD_INIT_SEQUENCE:
    rcall DELAY_LONG        ; Wait for LCD internal power-on reset
    rcall DELAY_LONG
    
    cbi PORTB, 4            ; RS = 0 (Command mode)
    
    ; The HD44780 requires a specific sequence of 0x30 nibbles to sync in 4-bit mode
    ldi temp, 0x30
    out PORTD, temp
    rcall PULSE_EN          ; Pulse 1
    rcall DELAY_LONG
    
    ldi temp, 0x30
    out PORTD, temp
    rcall PULSE_EN          ; Pulse 2
    rcall DELAY_LONG
    
    ldi temp, 0x30
    out PORTD, temp
    rcall PULSE_EN          ; Pulse 3
    rcall DELAY_LONG
    
    ; Switch to 4-bit operation mode
    ldi temp, 0x20       
    out PORTD, temp
    rcall PULSE_EN
    rcall DELAY_LONG
    
    ;Sending full 8-bit commands (sent as two 4-bit nibbles)
    ldi temp, 0x28          ; Function Set: 4-bit mode, 2 lines, 5x8 font
    rcall CMD_4BIT
    ldi temp, 0x08          ; Display OFF
    rcall CMD_4BIT
    rcall LCD_CLR           ; Clear Display RAM
    ldi temp, 0x06          ; Entry Mode: Auto-increment cursor, no shift
    rcall CMD_4BIT
    ldi temp, 0x0C          ; Display ON, Cursor OFF, Blink OFF
    rcall CMD_4BIT
    ret

LCD_CLR:
    ldi temp, 0x01          ; Clear display command
    rcall CMD_4BIT
    rcall DELAY_LONG        ; 
    ret

PULSE_EN:
    sbi PORTB, 5            ; Set Enable HIGH
    rcall DELAY_MS          ; Hold HIGH
    cbi PORTB, 5            ; Set Enable LOW (latches the data into LCD)
    rcall DELAY_MS          ; Wait for LCD to process
    ret

CMD_4BIT:
    cbi PORTB, 4            ; RS = 0 (Sending Command)
    rjmp SEND_BYTE

DATA_4BIT:
    sbi PORTB, 4            ; RS = 1 (Sending ASCII Data)

SEND_BYTE:
    push key_val            ; Save key_val to avoid destroying it
    
    ; Send High Nibble first
    mov key_val, temp
    andi key_val, 0xF0      ; Mask out lower 4 bits
    out PORTD, key_val      ; Send top 4 bits to LCD data pins
    rcall PULSE_EN
    
    ; Send Low Nibble second
    mov key_val, temp
    swap key_val            ; Swap high and low nibbles
    andi key_val, 0xF0      ; Mask out lower 4 bits (which was the high nibble)
    out PORTD, key_val      ; Send bottom 4 bits to LCD data pins
    rcall PULSE_EN
    
    pop key_val             ; Restore key_val
    ret
