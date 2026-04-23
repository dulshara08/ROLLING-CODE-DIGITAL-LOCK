;------------------------------------------------------------------------------
; config.inc - SHARED DEFINITIONS
;------------------------------------------------------------------------------

#define __SFR_OFFSET 0      ; Treat Special Function Registers as standard memory addresses
#include <avr/io.h>         ; Standard AVR I/O definitions (PORTB, DDRC, etc.)

; --- GLOBAL REGISTER ALLOCATIONS ---
#define temp r16            ; General-purpose working register used for immediate math/logic
#define key_val r17         ; Stores the current ASCII character read from the keypad
#define fail_count r23      ; Tracks consecutive wrong code entries (triggers deadlock at 2)
#define entropy r19         ; Accumulates random timing data for the LFSR seed
#define seed_L r24          ; Low byte of the current rolling code seed
#define seed_H r25          ; High byte of the current rolling code seed
