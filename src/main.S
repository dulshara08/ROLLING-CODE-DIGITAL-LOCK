;------------------------------------------------------------------------------
; ROLLING CODE DIGITAL LOCK 
;------------------------------------------------------------------------------

#define __SFR_OFFSET 0
#include <avr/io.h>

; --- REGISTER DEFINITIONS ---
#define temp r16
#define key_val r17
#define fail_count r23
#define entropy r19         
#define seed_L r24
#define seed_H r25

.section .data
buffer:     .space 6        

.section .text
.global main

main:
    ; --- 1. INITIALIZE STACK & PORTS ---
    ldi temp, lo8(RAMEND)
    out SPL, temp
    ldi temp, hi8(RAMEND)
    out SPH, temp

    ldi temp, 0xF4       
    out DDRD, temp
    ldi temp, 0x3F       
    out DDRB, temp
    ldi temp, 0x30       
    out DDRC, temp
    ldi temp, 0x07       
    out PORTC, temp

    ; --- HARDWARE TIMER FOR RANDOMNESS ---
    ldi temp, 0x01
    out TCCR0B, temp     

    clr fail_count
    clr entropy         

    ; --- 2. LCD STARTUP ---
    rcall LCD_INIT_SEQUENCE

    ; --- 3. EEPROM SEED RECOVERY ---
    ldi r18, 0x00       
    ldi r17, 0x10       
    rcall EEPROM_READ
    mov seed_H, temp
    
    ldi r17, 0x11       
    rcall EEPROM_READ
    mov seed_L, temp
    
    cpi seed_H, 0xFF
    brne STATE_STANDBY
    cpi seed_L, 0xFF
    brne STATE_STANDBY
    
    ldi seed_H, 0x12
    ldi seed_L, 0x34
    rcall SAVE_SEED_TO_EEPROM

; ==========================================
;        MAIN SYSTEM LOOP
; ==========================================

STATE_STANDBY:
    rcall LCD_CLR        

wait_for_keys:
    rcall KEYPAD_SCAN
    
    ; Check for '#' (Start Entry)
    cpi key_val, 35        
    breq start_code_entry

    ; Check for '*' (System Wipe)
    cpi key_val, 42
    breq SYSTEM_WIPE

    rjmp wait_for_keys

start_code_entry:
    rcall WAIT_RELEASE  

    ldi temp, 'C'
    rcall DATA_4BIT
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'D'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, ':'
    rcall DATA_4BIT

    rcall GET_INPUT_STRING

    rcall VALIDATE_ROLLING_CODE
    cpi temp, 1                    
    breq UNLOCK_SYSTEM
    rjmp HANDLE_FAILURE

; ==========================================
;             ERASE LOGIC
; ==========================================

SYSTEM_WIPE:
    rcall WAIT_RELEASE
    rcall LCD_CLR
    
    ; Display "WIPE"
    ldi temp, 'W'
    rcall DATA_4BIT
    ldi temp, 'I'
    rcall DATA_4BIT
    ldi temp, 'P'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT

    ; Wipe EEPROM Addresses 0x10 and 0x11
    ldi temp, 0xFF
    ldi r18, 0x00
    ldi r17, 0x10
    rcall EEPROM_WRITE
    
    ldi temp, 0xFF
    ldi r17, 0x11
    rcall EEPROM_WRITE

    ; Signal Success
    sbi PORTC, 5        ; Green LED ON
    
halt:
    rjmp halt           ; Freeze system

; ==========================================
;                OUTCOMES
; ==========================================

UNLOCK_SYSTEM:
    clr fail_count          

    rcall LCD_CLR
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'P'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, 'N'
    rcall DATA_4BIT

    sbi PORTC, 5            
    rcall DELAY_2SEC    
    
    rcall LFSR_UPDATE   
    eor seed_L, entropy     
    clr entropy
    rcall SAVE_SEED_TO_EEPROM
    
    rcall LCD_CLR
    ldi temp, 'N'
    rcall DATA_4BIT
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, 'X'
    rcall DATA_4BIT
    ldi temp, 'T'
    rcall DATA_4BIT
    ldi temp, ':'
    rcall DATA_4BIT

    rcall SHOW_CURRENT_SEED 
    
    rcall DELAY_2SEC
    rcall DELAY_2SEC
    cbi PORTC, 5        
    rjmp STATE_STANDBY  

HANDLE_FAILURE:
    inc fail_count
    
    rcall LCD_CLR
    ldi temp, 'E'
    rcall DATA_4BIT
    ldi temp, 'R'
    rcall DATA_4BIT
    ldi temp, 'R'
    rcall DATA_4BIT
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'R'
    rcall DATA_4BIT

    sbi PORTC, 4            
    rcall BEEP_ONCE     
    rcall DELAY_2SEC    
    cbi PORTC, 4        

    cpi fail_count, 2       
    brge STATE_DEADLOCK
    rjmp STATE_STANDBY

; ==========================================
;              DEADLOCK STATE
; ==========================================

STATE_DEADLOCK:
    rcall LCD_CLR       
    ldi temp, 'L'
    rcall DATA_4BIT
    ldi temp, 'O'
    rcall DATA_4BIT
    ldi temp, 'C'
    rcall DATA_4BIT
    ldi temp, 'K'
    rcall DATA_4BIT
    ldi temp, ':'
    rcall DATA_4BIT

    mov r20, seed_L
    swap r20
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    mov r8, r20             

    mov r20, seed_L
    andi r20, 0x0F
    rcall MAKE_DECIMAL
    mov r9, r20             

    mov temp, r8
    subi temp, -48          ; Add ASCII '0'
    rcall DATA_4BIT
    mov temp, r9
    subi temp, -48          ; Add ASCII '0'
    rcall DATA_4BIT

    ldi temp, 0xC0          
    rcall CMD_4BIT

    rcall GET_INPUT_STRING

    ldi r18, 9
    sub r18, r8             
    lds temp, buffer
    subi temp, 48           ; Subtract ASCII '0'
    cp temp, r18
    brne DEADLOCK_FAIL

    ldi r18, 9
    sub r18, r9             
    lds temp, buffer+1
    subi temp, 48           ; Subtract ASCII '0'
    cp temp, r18
    brne DEADLOCK_FAIL

    clr fail_count
    rjmp STATE_STANDBY

DEADLOCK_FAIL:
    rcall LCD_CLR
    ldi temp, '?'
    rcall DATA_4BIT
    rcall DELAY_2SEC
    rjmp STATE_DEADLOCK

; ==========================================
;        ROLLING CODE & EEPROM
; ==========================================

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

; ==========================================
;         HARDWARE SUBROUTINES
; ==========================================

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
