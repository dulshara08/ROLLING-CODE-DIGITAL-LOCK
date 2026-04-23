;------------------------------------------------------------------------------
; config.inc - SHARED DEFINITIONS
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