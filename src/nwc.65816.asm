; super stay forever

.cpu "65816"

; ROM MAP
* = $000000         ; file offset (in the sfc/rom file)
.logical $808000    ; set to logical 80:8000 for snes address (Bank 80, upper 32k at $8000)

.dsection secBank80
.cerror * > $80FFB0, "overflow at bank 80: ", *- $80FFB0 ; check if there is too much code/data in this bank...

* = $80FFB0
.dsection secHeader     ; snes header

* = $80FFE4
.dsection sec65816IRQVectors

* = $80FFF4
.dsection sec6502IRQVectors

.here ; switch back to file offset instead of snes-offset



* = $008000         ; file offset
.logical $818000    ; snes address 81:8000
.dsection secBank81
.here
.cerror * > $10000, "overflow at bank 81: ", * - $10000

* = $010000         ; file offset
.logical $828000    ; snes address 82:8000
.dsection secBank82
.here
*=$17fff
.byte 0
.cerror * > $18000, "overflow at bank 82: ", * - $18000

* = $018000
.logical $838000
.dsection secBank83
.here
.cerror * > $20000, "overflow at bank 83: ", * - $20000

* = $020000
.logical $848000
.dsection secBank84
.here
.cerror * > $28000, "overflow at bank 84: ", * - $28000

* = $028000
.logical $858000
.dsection secBank85
.here
.cerror * > $30000, "overflow at bank 85: ", * - $30000

* = $030000
.logical $868000
.dsection secBank86
.here
.cerror * > $38000, "overflow at bank 86: ", * - $38000

* = $038000
.logical $878000
.dsection secBank87
.here
.cerror * > $40000, "overflow at bank 87: ", * - $40000

* = $040000
.logical $888000
.dsection secBank88
.here
.cerror * > $48000, "overflow at bank 88: ", * - $48000




; virtual address setup/definition
* = $0000
.dsection secDP
.cerror * > $100, "direct page overflow: ", * - $100
gSharedRamStart

.dsection secSharedWRAM
.cerror * > $1FC0, "shared WRAM overflow: ", * - $1FC0

; LoWRAM
* = $7e2000
.dsection secLoWRAM
.cerror * > $7F0000, "LoWRAM overflow: ", *-$7F0000

; HiWRAM
* = $7F0000
.dsection secHiWRAM
.cerror * > $800000, "HiWRAM overflow: ", *-$800000
 
; load up some defines
.include "../include/snes.inc"

; setup
.section secDP
.send; secDP

; WRAM
.section secLoWRAM
ShadowOAM           .fill   256*2   ; lower 512 bytes
ShadowOAMHi         .fill   32      ; higer  32 bytest

pad_1_raw           .word   ?   
pad_2_raw           .word   ?
pad_3_raw           .word   ?

pad_1_pressed       .word   ?   
pad_2_pressed       .word   ?   
pad_3_pressed       .word   ?

pad_1_repeat        .word   ?   
pad_2_repeat        .word   ?
pad_3_repeat        .word   ?

; player
player_one          .dstruct Object

; place hdma stuff
* = $7e4000
hdma_scroll_a       .dunion HLWord
hdma_scroll_b       .dunion HLWord
.send ; secLoWRAM


; SNES HEADER SETUP
.section secHeader
    .word   0
    .text   "TEST"
    .fill   7, 0
    .byte   0       ; RAM
    .byte   0       ; special version
    .byte   0       ; cart type
    ;        123456789012345678901
    .text   "Nerdwelten Weihnacht " ; needs proper length
.cerror * != $80ffd5, "name is short", *
    .byte   $30     ; mapping
    .byte   $00     ; rom
    .byte   $10     ; 128K
    .byte   $00     ; 0K SRAM
    .byte   $01     ; PAL
    .byte   $33     ; version 3
    .byte   $00     ; rom version 0
    .word   $0000   ; complement
    .word   $0000   ; CRC
.send ; secHeader

; IRQ VECTORS
.section sec65816IRQVectors
.block
    vCOP    .word   <>Logic.justRTI
    vBRK    .word   <>Logic.justRTI
    ABORT   .word   <>Logic.justRTI
    NMI     .word   <>Logic.VBlank
    RESET   .word   <>Logic.justRTI
    IRQ     .word   <>Logic.justRTI
.bend
.send; sec65816IRQVectors

.section sec6502IRQVectors
.block
    vCOP    .word   <>Logic.justRTI
    vBRK    .word   <>Logic.justRTI
    ABORT   .word   <>Logic.justRTI
    NMI     .word   <>Logic.justRTI
    RESET   .word   <>Logic.RESET
    IRQ     .word   <>Logic.justRTI
.bend
.send; sec6502IRQVectors

; include/instance banks with proper "names"
.include "vram.inc"

.section secBank80
    Logic .binclude "Bank80.asm"

    TitlescreenHDMA ; indirect hdma table
    .block      ; titlescreen h-dma indirect table
        .byte $20
        .word $4000
        .byte $20
        .word $4002
        .byte $20
        .word $4000
        .byte $20
        .word $4002
        .byte $20
        .word $4000
        .byte $20
        .word $4002
        .byte $20
        .word $4000
        .byte $00
    .bend
.send ; secBank80

.section secBank81
    ; level address table stuff
    ; testlevel
    TitlescreenData
    .block
        ; bank
        ; address
        ; size
        
        .byte   `TitlescreenPalette
        .word   <>TitlescreenPalette
        .word   len(binary("../data/Titlescreen/Titlescreen.palette"))

        .byte   `TitlescreenTiles
        .word   <>TitlescreenTiles
        .word   len(binary("../data/Titlescreen/Foreground.tiles"))

        .byte   `TitlescreenMap_FG
        .word   <>TitlescreenMap_FG
        .word   len(binary("../data/Titlescreen/Foreground.map"))

        .byte   `TitlescreenMap_BG
        .word   <>TitlescreenMap_BG        
        .word   len(binary("../data/Titlescreen/Background.map"))
    .bend

    IngameData
    .block
        .byte   `IngamePalette
        .word   <>IngamePalette
        .word   len(binary("../data/Ingame/Ingame.palette"))

        .byte   `IngameTiles
        .word   <>IngameTiles
        .word   len(binary("../data/Ingame/Foreground.tiles"))

        .byte   `IngameMap_FG
        .word   <>IngameMap_FG
        .word   len(binary("../data/Ingame/Foreground.map"))

        .byte   `IngameMap_BG
        .word   <>IngameMap_BG        
        .word   len(binary("../data/Ingame/Background.map"))
    .bend

    SpriteData
    .block
        .byte   `SpritePalette
        .word   <>SpritePalette
        .word   len(binary("../data/Sprites/Sprites.palette"))

        .byte   `SpriteTiles
        .word   <>SpriteTiles
        .word   len(binary("../data/Sprites/Sprites.tiles"))
    .bend

    TitlescreenPalette  .binary "../data/Titlescreen/Titlescreen.palette"
    TitlescreenTiles    .binary "../data/Titlescreen/Foreground.tiles"
    TitlescreenMap_BG   .binary "../data/Titlescreen/Background.map"
    TitlescreenMap_FG   .binary "../data/Titlescreen/Foreground.map"

    IngamePalette   .binary "../data/Ingame/Ingame.palette"
    IngameTiles     .binary "../data/Ingame/Foreground.tiles"
    IngameMap_BG    .binary "../data/Ingame/Background.map"
    IngameMap_FG    .binary "../data/Ingame/Foreground.map"

    SpritePalette   .binary "../data/Sprites/Sprites.palette"
    SpriteTiles     .binary "../data/Sprites/Sprites.tiles"

    PlayerSF        .binary "../data/Sprites/Player_SF.metasprite"
    PlayerNW        .binary "../data/Sprites/Player_NW.metasprite"
    Enemy_0         .binary "../data/Sprites/gingerbreadman.metasprite"
.send

.section secBank82
    spc700_code     .binary "../data/Music/spc700.bin"
.send

.section secBank83
    music_1         .binary "../data/Music/music_1.bin"
.send

; useful definitions from Oziphantom
HLWord .union
    .word ?
    .struct
        lo .byte ?
        hi .byte ?
    .ends
.endu; HLWord

HLBLong .union
    .long ?
    .struct
        lo      .byte   ?
        hi      .byte   ?
        bank    .byte   ?
    .ends
    .struct
        loWord  .word   ?
        dummy1  .byte   ?
    .ends
    .struct
        dummy2  .byte   ?
        hiWord  .word   ?
    .ends
.endu; HLBLong

WorldPosition .struct
    x   .word   ?
    y   .word   ?
.ends

ScreenPosition .struct
    x   .dunion HLWord
    y   .dunion HLWord
.ends

Object .struct
    worldpos    .dstruct    WorldPosition
    screenpos   .dstruct    ScreenPosition
    speed       .byte       ?
.ends


Bullet .struct
    .block
        flags       .byte       ?
        worldpos    .dstruct    WorldPosition
        screenpos   .dstruct    ScreenPosition
    .bend
.ends

.comment
myWord .dunion HLWord
myLong .dunion HLBLong

lda myWord+1 <-> lda myWorld.hi
lda myLong+2 <-> lda myLong.bank
.endc

; macros
A8 .macro
	SEP #$20
.endm

A16 .macro
	REP #$20
.endm

A16Clear .macro
	REP #$21
.endm

XY8 .macro
	SEP #$10
.endm

XY16 .macro
	REP #$10
.endm

AXY8 .macro
	SEP #$30
.endm

A8XY16 .macro
	REP #$30
.endm

AXY16 .macro
    REP #$30
.endm