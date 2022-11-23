  .inesprg 1    ; Defines the number of 16kb PRG banks
  .ineschr 1    ; Defines the number of 8kb CHR banks
  .inesmap 0    ; Defines the NES mapper
  .inesmir 1    ; Defines VRAM mirroring of banks

  .rsset $0000 ;Defining some variables at $0000
  
pointerBackgroundLowByte  .rs 1
pointerBackgroundHighByte .rs 1

charcterTile1X = $1003
charcterTile2X = $1007
charcterTile3X = $100B
charcterTile4X = $100F
charcterTile5X = $1013
charcterTile6X = $1017
charcterTile7X = $101B
charcterTile8X = $101F

charcterTile1A = $1002
charcterTile2A = $1006
charcterTile3A = $100A
charcterTile4A = $100E
charcterTile5A = $1012
charcterTile6A = $1016
charcterTile7A = $101A
charcterTile8A = $101E

moveAnimProperty = $0100 ;adress for containing legs position
shouldMoveLegs = $0101
moveLeft = $0110

  .bank 0 ;bank contains the game's "program"  (max 8kb)
  .org $C000

RESET:
  JSR LoadBackground
  JSR LoadPalettesSprite
  JSR LoadPalettesBG
  JSR LoadSprites
  JSR SetShouldMoveZero

  LDA #%10001000 ; Enable NMI, sprites and background on table 0
  STA $2000
  LDA #%00011110 ; Enable sprites, enable backgrounds
  STA $2001
  LDA #$00 ; No background scrolling
  STA $2006
  STA $2006
  STA $2005
  STA $2005
  LDX #$00
  STX moveAnimProperty
  STX moveLeft
  LDY #$00

InfiniteLoop:
  JMP InfiniteLoop

  LoadPalettesBG:
    LDA $2002 ; read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006 ; write the high byte of $3F00 address
    LDA #$00
    STA $2006 ; write the low byte of $3F00 address
    LDX #$00
  .Loop:
    LDA background_palette, x
    STA $2007             
    INX        
    CPX #$10              ; Compare X to hex $10 => 16 dec - copying 16 bytes = 4 sprites
    BNE .Loop

  LoadPalettesSprite:
    LDA $2002 ; read PPU status to reset the high/low latch
    LDA #$3F
    STA $2006 ; write the high byte of $3F00 address
    LDA #$10
    STA $2006 ; write the low byte of $3F00 address
    LDX #$00
  .Loop:
    LDA sprite_palette, x
    STA $2007             
    INX                   
    CPX #$10             
    BNE .Loop 

  LoadAttributes:
    LDA $2002
    LDA #$23
    STA $2006
    LDA #$C0
    STA $2006
    LDX #$00
  .Loop:
    LDA attributes, x
    STA $2007
    INX
    CPX #$40
    BNE .Loop
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

FlipCharcacter:
  LDA charcterTile1A
  AND #%01000000
  CMP #%01000000
  BEQ .Back
  LDA charcterTile1A
  ORA #%01000000
  STA charcterTile1A
  STA charcterTile2A
  STA charcterTile3A
  STA charcterTile4A
  STA charcterTile5A
  STA charcterTile6A
  STA charcterTile7A
  STA charcterTile8A

  LDA charcterTile1X
  CLC
  ADC #%00001000
  STA charcterTile1X
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

  LDA charcterTile2X
  SEC
  SBC #%00001000
  STA charcterTile2X
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X

  RTS
.Back:
  RTS

FlipBackwards:
  LDA charcterTile1A
  AND #%01000000
  CMP #%00000000
  BEQ .Back
  LDA charcterTile1A
  AND #%10111111
  STA charcterTile1A
  STA charcterTile2A
  STA charcterTile3A
  STA charcterTile4A
  STA charcterTile5A
  STA charcterTile6A
  STA charcterTile7A
  STA charcterTile8A

  LDA charcterTile1X
  SEC
  SBC #%00001000
  STA charcterTile1X
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

  LDA charcterTile2X
  CLC
  ADC #%00001000
  STA charcterTile2X
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X
.Back:
  RTS

ReadPlayerOneControls:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016

ReadA:
  LDA $4016       ; Controller 1 input - A
  AND #%00000001
  BEQ EndReadA 


EndReadA:
  LDA $4016       ; Controller 1 input - B
  LDA $4016       ; Controller 1 input - Select
  LDA $4016       ; Controller 1 input - Start

ReadUp:
  LDA $4016       ; Controller 1 input - Up
EndReadUp:

ReadDown:
  LDA $4016       ; Controller 1 input - Down
  AND #%00000001
  BEQ EndReadDown

EndReadDown:

ReadLeft:
  LDA $4016       ; Controller 1 input - Left
  AND #%00000001
  BEQ EndReadLeft
  JSR FlipCharcacter
  LDY charcterTile1X
  LDX moveLeft
  CPX #$01
  BNE .notPressd
  CPY #$08
  BEQ .notPressd

  LDY shouldMoveLegs
  INC shouldMoveLegs
  CPY #$00
  BNE .moveFull

  JSR MoveCharacterTopBackwards

  LDY moveAnimProperty
  INC moveAnimProperty
  CPY #$01
  BEQ .backwardAnim

.forwardAnim:
  LDA charcterTile5X
  SEC
  SBC #%00000100
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

  LDA charcterTile6X
  CLC
  ADC #%00000010
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X
  JMP EndReadRight
.backwardAnim: 
  LDA charcterTile6X
  SEC
  SBC #%00000100
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X

  LDA charcterTile5X
  CLC
  ADC #%00000010
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

 .EndReadYAndZeroLegs:
  LDY #$00
  STY moveAnimProperty
  JMP EndReadRight

.moveFull:
  JMP MoveCharacterBackward
.notPressd:
  LDX #$01
  STX moveLeft 
  JMP NotPressed


EndReadLeft:

ReadRight:
  LDA $4016       ; Controller 1 input - Right
  AND #%00000001
  BEQ NotPressed
  JSR FlipBackwards
  LDY charcterTile1X
  CPY #$F0
  BEQ NotPressed
  LDX moveLeft
  CPX #$00
  BNE .FirstStep

  LDY shouldMoveLegs
  INC shouldMoveLegs
  CPY #$00
  BNE MoveCharacter

  JSR MoveCharacterTop

  LDY moveAnimProperty
  INC moveAnimProperty
  CPY #$01
  BEQ .backwardAnim

.forwardAnim:
  LDA charcterTile5X
  CLC
  ADC #%00000100
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

  LDA charcterTile6X
  SEC
  SBC #%00000010
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X
  JMP EndReadRight
.backwardAnim: 
  LDA charcterTile6X
  CLC
  ADC #%00000100
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X

  LDA charcterTile5X
  SEC
  SBC #%00000010
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

 .EndReadYAndZeroLegs:
  LDY #$00
  STY moveAnimProperty
  RTS 
 .FirstStep:
  LDX #$00
  STX moveLeft
  JMP NotPressed

NotPressed:
  LDY #$00
  STY moveAnimProperty
  STY shouldMoveLegs

  LDA charcterTile1X
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

  LDA charcterTile2X
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X

  RTS

MoveCharacter:
  LDA charcterTile1X
  CLC
  ADC #%00000001
  STA charcterTile1X
  ;STA charcterTile3X

  LDA charcterTile5X
  CLC
  ADC #%00000001
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

  LDA charcterTile2X
  CLC
  ADC #%00000001
  STA charcterTile2X
  ;STA charcterTile4X
  LDA charcterTile6X
  CLC
  ADC #%00000001
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X
  LDY shouldMoveLegs
  CPY #$10
  BEQ SetShouldMoveZero
  JMP EndReadRight

EndReadRight:
  RTS

MoveCharacterBackward:
  LDA charcterTile1X
  SEC
  SBC #%00000001
  STA charcterTile1X
  ;STA charcterTile3X

  LDA charcterTile5X
  SEC
  SBC #%00000001
  STA charcterTile3X
  STA charcterTile5X
  STA charcterTile7X

  LDA charcterTile2X
  SEC
  SBC #%00000001
  STA charcterTile2X
  ;STA charcterTile4X
  LDA charcterTile6X
  SEC
  SBC #%00000001
  STA charcterTile4X
  STA charcterTile6X
  STA charcterTile8X
  LDY shouldMoveLegs
  CPY #$10
  BEQ SetShouldMoveZero
  JMP EndReadRight


SetShouldMoveZero:
  LDY #$00
  STY shouldMoveLegs
  JMP EndReadRight

MoveCharacterTop:
  LDA charcterTile1X
  CLC
  ADC #%00000001
  STA charcterTile1X
  ;STA charcterTile3X

  LDA charcterTile2X
  CLC
  ADC #%00000001
  STA charcterTile2X
  ;STA charcterTile4X
  RTS

MoveCharacterTopBackwards:
  LDA charcterTile1X
  SEC
  SBC #%00000001
  STA charcterTile1X
  ;STA charcterTile3X

  LDA charcterTile2X
  SEC
  SBC #%00000001
  STA charcterTile2X
  ;STA charcterTile4X
  RTS

NMI:
  LDA #$00
  STA $2003
  LDA #$10
  STA $4014
  JSR ReadPlayerOneControls
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
