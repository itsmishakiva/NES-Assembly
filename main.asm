  .inesprg 1    ; Defines the number of 16kb PRG banks
  .ineschr 1    ; Defines the number of 8kb CHR banks
  .inesmap 0    ; Defines the NES mapper
  .inesmir 1    ; Defines VRAM mirroring of banks

  .rsset $0000 ;Defining some variables at $0000
  
pointerBackgroundLowByte  .rs 1
pointerBackgroundHighByte .rs 1

  .bank 0 ;bank contains the game's "program"  (max 8kb)
  .org $C000

RESET:
  JSR LoadBackground
  JSR LoadPalettesSprite
  JSR LoadPalettesBG
  JSR LoadSprites

  LDA #%10001000 ; Enable NMI, sprites and background on table 0
  STA $2000
  LDA #%00011110 ; Enable sprites, enable backgrounds
  STA $2001
  LDA #$00 ; No background scrolling
  STA $2006
  STA $2006
  STA $2005
  STA $2005

InfiniteLoop:
  JMP InfiniteLoop

  LoadPalettesBG:
    LDA $2002 ; read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006 ; write the high byte of $3F00 address
    LDA #$00
    STA $2006 ; write the low byte of $3F00 address
    LDX #$00
  LoadPalettesLoop:
    LDA background_palette, x
    STA $2007             
    INX        
    CPX #$10              ; Compare X to hex $10 => 16 dec - copying 16 bytes = 4 sprites
    BNE LoadPalettesLoop

  LoadPalettesSprite:
    LDA $2002 ; read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006 ; write the high byte of $3F00 address
    LDA #$10
    STA $2006 ; write the low byte of $3F00 address
    LDX #$00
  LoadPalettesLoopSprite:
    LDA sprite_palette, x
    STA $2007             
    INX                   
    CPX #$10             
    BNE LoadPalettesLoopSprite 

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
  LDA $2002
  LDA #$20 
  STA $2006
  LDA #$00
  STA $2006
  ;sending #2000 to $2006

  ;loading low byte of bg data and storing it in var lowByte
  LDA #LOW(background)
  STA pointerBackgroundLowByte
  ;loading high byte of bg data and storing it in var highByte
  LDA #HIGH(background)
  STA pointerBackgroundHighByte
  ;This is used to loop through all the data (in .Loop starting from lowByte ending w highByte)
  ;#LOW and #HIGH are predefined functions for assembler

  LDX #$00 
  LDY #$00 
.Loop:
  LDA [pointerBackgroundLowByte], Y
  STA $2007 ;Writing a byte to $2007 communicates one graphical tile to the PPU
  ;so we will need to repeatedly send data to this address until we’re done
  INY
  CPY #$00
  BNE .Loop

  ;Once we overflow and hit #$00 again, we are using the X register
  ;to allow this to happen 4 times before finishing cycle
  ;This is enough to get the 960 bytes of data we need for background.
  INC pointerBackgroundHighByte
  INX 
  CPX #$04 
  BNE .Loop
  RTS


LoadSprites:
  LDX #$00
.Loop:
  LDA sprites, x
  STA $1000, x ;1000 - adress containing first byte second pattern table
  INX
  CPX #$20 ; Loading 8 tiles (each containing 8 byte data => takes 4 mem adress)
           ; 8 * 4 = 32 which is 20 in hex
  BNE .Loop
  RTS

NMI:
  LDA #$00
  STA $2003
  LDA #$10
  STA $4014
  RTI ;RTI denotes end of NMI

  .bank 1 ;bank for RESET, NMI and IRQ
  .org $E000
  background_palette:
  .db $1d,$2d,$06,$26, $1d,$02,$04,$13, $1d,$2d,$06,$17

  sprite_palette:
  .db $1d,$08,$06,$26

background:
  .incbin "nametable.bin" ;background tiles

sprites:
  .include "sprite.asm" ;sprite nametable

attributes:
  .incbin "attributes.bin" ;background attributes

  .org $FFFA ;$FFFA - addresses to define three interrupt vectors (NMI, RESET, and IRQ)
  .dw NMI 
  .dw RESET
  .dw 0 ;IRQ 0 for now

  .bank 2 ;bank for sprite and background data
  .org $0000
  .incbin "pattern.bin" ;background pattern table
  .org $1000 
  .incbin "spritePattern.bin" ;sprite pattern table 
