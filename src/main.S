;------------------------------------------------------------------------------
; main.S - ROLLING CODE DIGITAL LOCK
;------------------------------------------------------------------------------

#include "config.inc"

.section .data
.global buffer
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
;             DEADLOCK STATE
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