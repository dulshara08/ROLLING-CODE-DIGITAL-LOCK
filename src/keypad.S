;------------------------------------------------------------------------------
; keypad.S - MATRIX KEYPAD SCANNER
;------------------------------------------------------------------------------

#include "config.inc"

.section .text
.global KEYPAD_SCAN, GET_INPUT_STRING, WAIT_FOR_KEY_ACTIVE, WAIT_RELEASE

WAIT_FOR_KEY_ACTIVE:
    rcall KEYPAD_SCAN
    cpi key_val, 0xFF
    breq WAIT_FOR_KEY_ACTIVE 
    in temp, TCNT0
    eor entropy, temp
    ret

WAIT_RELEASE:
    rcall KEYPAD_SCAN
    cpi key_val, 0xFF
    brne WAIT_RELEASE
    rcall DELAY_MS      
    ret

GET_INPUT_STRING:
    ldi XL, lo8(buffer)
    ldi XH, hi8(buffer)
    ldi r22, 0
input_loop:
    rcall WAIT_FOR_KEY_ACTIVE   
    cpi key_val, 35             ; DECIMAL 35 IS '#' 
    breq input_done
    st X+, key_val                 
    mov temp, key_val                
    rcall DATA_4BIT             
    rcall WAIT_RELEASE          
    inc r22                     
    cpi r22, 4                  
    brne input_loop
input_done:
    ret

KEYPAD_SCAN:
    sbi PORTB, 0
    sbi PORTB, 1
    sbi PORTB, 2
    sbi PORTB, 3

    cbi PORTB, 0
    nop
    sbis PINC, 0
    ldi key_val, '1'
    sbis PINC, 0
    ret
    sbis PINC, 1
    ldi key_val, '2'
    sbis PINC, 1
    ret
    sbis PINC, 2
    ldi key_val, '3'
    sbis PINC, 2
    ret
    sbi PORTB, 0
    
    cbi PORTB, 1
    nop
    sbis PINC, 0
    ldi key_val, '4'
    sbis PINC, 0
    ret
    sbis PINC, 1
    ldi key_val, '5'
    sbis PINC, 1
    ret
    sbis PINC, 2
    ldi key_val, '6'
    sbis PINC, 2
    ret
    sbi PORTB, 1
    
    cbi PORTB, 2
    nop
    sbis PINC, 0
    ldi key_val, '7'
    sbis PINC, 0
    ret
    sbis PINC, 1
    ldi key_val, '8'
    sbis PINC, 1
    ret
    sbis PINC, 2
    ldi key_val, '9'
    sbis PINC, 2
    ret
    sbi PORTB, 2
    
    cbi PORTB, 3
    nop
    sbis PINC, 0
    ldi key_val, 42     ; DECIMAL 42 IS '*'
    sbis PINC, 0
    ret
    sbis PINC, 1
    ldi key_val, '0'
    sbis PINC, 1
    ret
    sbis PINC, 2
    ldi key_val, 35     ; DECIMAL 35 IS '#'
    sbis PINC, 2
    ret
    sbi PORTB, 3
    
    ldi key_val, 0xFF
    ret