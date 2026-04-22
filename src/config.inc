; config.inc
#define __SFR_OFFSET 0
#include <avr/io.h>

; --- Shared Registers ---
#define temp r16
#define key_val r17
#define seed_L r24
#define seed_H r25

; --- Pin Mapping ---
#define LCD_CTRL_PORT PORTB
#define LCD_RS 4
#define LCD_EN 5