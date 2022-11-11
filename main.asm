  .inesprg 1    ; Defines the number of 16kb PRG banks
  .ineschr 1    ; Defines the number of 8kb CHR banks
  .inesmap 0   ; Defines the NES mapper
  .inesmir 1    ; Defines VRAM mirroring of banks

  .rsset $0000 ;Defining some variables at $0000
  ;.rs defines how many bytes needed for variable
pointerBackgroundLowByte  .rs 1
pointerBackgroundHighByte .rs 1

  .bank 0 ;bank can contain at most 8kb of memory
  .org $C000 ;address space of this bank will originate
             ; at address $C000 and fill 8kb of memory beyond that address

RESET:
  ;JSR - jump to that label, then return here once it is done
  JSR LoadBackground
  JSR LoadPalettes

  ;% - binary
  LDA #%10000000 ; Enable NMI, sprites and background on table 0
  STA $2000
  LDA #%10001010 ; Disable sprites, enable backgrounds
  STA $2001
  LDA #$00 ; No background scrolling
  STA $2006
  STA $2006
  STA $2005
  STA $2005

InfiniteLoop:
  JMP InfiniteLoop

  LoadPalettes:
    LDA $2002 ; read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006 ; write the high byte of $3F00 address
    LDA #$00
    STA $2006 ; write the low byte of $3F00 address
    LDX #$00
  LoadPalettesLoop:
    LDA background_palette, x
    STA $2007             ; write to PPU
    INX                   ; Incrementing value at X register => going to next palette
    CPX #$10              ; Compare X to hex $10 => 16 dec - copying 16 bytes = 4 sprites
    BNE LoadPalettesLoop  ; restart cycle to LoadPalettesLoop if X is not 16

  LoadAttributes:
    LDA $2002
    LDA #$23
    STA $2006
    LDA #$C0
    STA $2006
    LDX #$00
  .AtrLoop:
    LDA attributes, x
    STA $2007
    INX
    CPX #$40
    BNE .AtrLoop
    RTS

  

LoadBackground:
  ;LDA (Load Accumulator) - take a raw value or value from a memory
  ;address and load it into the accumulator register
  ;LDA $2002 ;loading the address $2002 specifically to reset the PPU (Picture Processing Unit)
  ;The # sign means it is a value, and the $ sign means it is in hexadecimal
  ;STA (Store Accumulator) - take Accumulator value and store it in memory
  ;$2006 is a port to the PPU to tell it where to store the background data
  LDA #$20 ;load #$20 into the accumulator
  STA $2006; take that value and store it at $2006
  LDA #$00
  STA $2006
  ;memory adresses are two bytes and we can only send one byte at a time
  ;so sending it two times and getting $2000 on the PPU

  ;loading low byte of bg data and storing it in var lowByte
  LDA #LOW(background)
  STA pointerBackgroundLowByte
  ;loading high byte of bg data and storing it in var highByte
  LDA #HIGH(background)
  STA pointerBackgroundHighByte
  ;This is used to loop through all the data (in .Loop starting from lowByte ending w highByte)
  ;#LOW and #HIGH are predefined functions for assembler

  LDX #$00 ;load data in X register
  LDY #$00 ;load data in Y register
;. at the beggining of label means it is private (not accesible outside of parent label)
.Loop:
  LDA [pointerBackgroundLowByte], Y ;This LDA uses the Y register to offset the memory access.
                                    ; Each time it will load the next byte in the sequence.
  STA $2007 ;Writing a byte to $2007 communicates one graphical tile to the PPU
  ;so we will need to repeatedly send data to this address until we’re done
  INY ;Increment the value in the Y register
  CPY #$00 ;Compare value in Y to the value #$00
  BNE .Loop ;restart .Loop if Y is not equal to #$00 (Branch if not equal) 

  ;This part is a secondary loop. We have too much data to send with a single register,
  ;that contains 960 bytes. we can only store one byte in a register at a time
  ;So we can only go up to 256 until we start to overflow
  ;Once we overflow and hit #$00 again, we are using the X register
  ;to allow this to happen 4 times before finishing cycle
  ;This is enough to get the 960 bytes of data we need.
  INC pointerBackgroundHighByte ;Increment variable so that when loop breaks we still had enough bytes in mem
  INX ;Increment value in X
  CPX #$04 ;Compare value in X to the value #$04
  BNE .Loop ;restart .Loop if X is not yet equal to #$04
  RTS ;Return from Subroutine means end of method



  

;IRQ: for mapper and audio
;The CPU has a few memory addresses set aside
;to define three interrupt vectors (NMI, RESET, and IRQ).
;These three vectors will each take up 2 bytes of memory
;and will be located at the range $FFFA-$FFFF

NMI:
  RTI ;RTI denotes end of NMI

  .bank 1 ;bank for RESET NMI and IRQ
  .org $E000
  background_palette:
  .db $38,$1F,$12,$16, $38,$1F,$13,$18, $38,$1F,$13,$17, $38,$17,$13,$18

background:
  .include "graphics/bg.asm" ;include our background file

attributes:
  .include "graphics/attributes.asm"

  .org $FFFA ;at adress $FFFA
  ;dw means dataword (defining word weight 2 bytes data)
  .dw NMI 
  .dw RESET
  .dw 0 ;IRQ 0 for now, not used

  .bank 2 ;bank for sprite and background data
  .org $0000 ;at adress $0000
  .incbin "me.bin" ;including graphics file

