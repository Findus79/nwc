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

; player data
player_one          .dstruct Object
player_bullets .block   ; 32 bullets for the player at once for now.
    .fill   32*5        ; 9 bytes per bullet
.bend

enemy_objects .block
    .fill   16*11        ; max of 16 enemies at once
.bend

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

    TitlescreenSpriteData
    .block
        .byte   `TitlescreenSpritePalette
        .word   <>TitlescreenSpritePalette
        .word   len(binary("../data/Sprites/Sprites.palette"))

        .byte   `TitlescreenSpriteTiles
        .word   <>TitlescreenSpriteTiles
        .word   len(binary("../data/Sprites/Sprites.tiles"))
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

    IngameSpriteData
    .block
        .byte   `IngameSpritePalette
        .word   <>IngameSpritePalette
        .word   len(binary("../data/Sprites/Sprites.palette"))

        .byte   `IngameSpriteTiles
        .word   <>IngameSpriteTiles
        .word   len(binary("../data/Sprites/Sprites.tiles"))
    .bend

    TitlescreenPalette  .binary "../data/Titlescreen/Titlescreen.palette"
    TitlescreenTiles    .binary "../data/Titlescreen/Foreground.tiles"
    TitlescreenMap_BG   .binary "../data/Titlescreen/Background.map"
    TitlescreenMap_FG   .binary "../data/Titlescreen/Foreground.map"

    TitlescreenSpritePalette   .binary "../data/Sprites/snowflakes.palette"
    TitlescreenSpriteTiles     .binary "../data/Sprites/snowflakes.tiles"

    snowflake_small_a   .binary "../data/Sprites/snowflake_small_a.metasprite"
    snowflake_medium_a  .binary "../data/Sprites/snowflake_medium_a.metasprite"

    IngamePalette   .binary "../data/Ingame/Ingame.palette"
    IngameTiles     .binary "../data/Ingame/Foreground.tiles"
    IngameMap_BG    .binary "../data/Ingame/Background.map"
    IngameMap_FG    .binary "../data/Ingame/Foreground.map"

    IngameSpritePalette   .binary "../data/Sprites/Sprites.palette"
    IngameSpriteTiles     .binary "../data/Sprites/Sprites.tiles"

    PlayerSF        .binary "../data/Sprites/Player_SF.metasprite"
    PlayerNW        .binary "../data/Sprites/Player_NW.metasprite"
    Snowball        .binary "../data/Sprites/snowball.metasprite"

    Wavetable .block    ; all waves defs have to be stored in the same bank
        .byte   `Wave_Definitions  ; wave-defs bank
        .word   <>Wave_1           ; wave-def addr
        .word   <>Wave_2
        .word   <>Wave_3
        .word   <>Wave_4
        .word   <>Wave_5
        .word   <>Wave_6
        .word   <>Wave_7
        .word   <>Wave_8
        .word   <>Wave_9
        .word   <>Wave_10
        .word   <>Wave_11
        .word   <>Wave_12
        .word   <>Wave_13
        .word   <>Wave_14
        .word   <>Wave_15
        .word   <>Wave_16
        .word   <>Wave_17
        .word   <>Wave_18
        .word   <>Wave_19
        .word   <>Wave_20
        .word   <>Wave_21
        .word   <>Wave_22
        .word   <>Wave_23
        .word   <>Wave_24
    .bend

    EnemyTable .block
        .byte   `Enemy_Sprites
        .word   <>Enemy_0
        .word   <>Enemy_1
    .bend

    PatternTable .block
        .byte   `Pattern_Definitions
        .word   <>Pattern_0
        .word   <>Pattern_1
    .bend

.send

.section secBank82
    Enemy_Sprites
        Enemy_0         .binary "../data/Sprites/gingerbreadman.metasprite"
        Enemy_1         .binary "../data/Sprites/ufo_elf.metasprite"

    ;wave definition. number of enemies: type, starting position, pattern and time-offset from wave start
    Wave_Definitions
    Wave_1  .block
        .byte   5           ; enemy count

        .byte   1           ; enemy type
        .byte   32          ; first enemy position x,y
        .byte   32     
        .byte   0           ; pattern index
        .word   $0010       ; frame offset until start

        .byte   1           ; enemy type
        .byte   64, 32      ; enemy position x,y
        .byte   0           ; pattern index
        .word   $0020       ; frame offset until start

        .byte   1           ; enemy type
        .byte   96, 32      ; enemy position x,y
        .byte   0           ; pattern index
        .word   $0030       ; frame offset until start

        .byte   1           ; enemy type
        .byte   128, 32     ; enemy position x,y
        .byte   0           ; pattern index
        .word   $0040       ; frame offset until start

        .byte   1           ; enemy type
        .byte   160, 32     ; enemy position x,y
        .byte   0           ; pattern index
        .word   $0050       ; frame offset until start
    .bend
    Wave_2
    Wave_3
    Wave_4
    Wave_5
    Wave_6
    Wave_7
    Wave_8
    Wave_9
    Wave_10
    Wave_11
    Wave_12
    Wave_13
    Wave_14
    Wave_15
    Wave_16
    Wave_17
    Wave_18
    Wave_19
    Wave_20
    Wave_21
    Wave_22
    Wave_23
    Wave_24

    ; pattern definitions.
    ; 16 bit length, n x/y pairs.
    Pattern_Definitions
        Pattern_0 .block
            .word   $0001   ; xx yy
        .bend
        Pattern_1 .block
            .word   $0101   ; xx yy
        .bend

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


Bullet .struct  ; 5 bytes total
    .block
        flags       .byte       ?
        screenpos   .dstruct    ScreenPosition
    .bend
.ends

Enemy .struct   ; 11 bytes total
    flags           .byte       ?
    screenpos       .dstruct    ScreenPosition
    sprite_ptr      .word       ?               ; metasprite ptr
    pattern_ptr     .word       ?               ; wave-pattern ptr
    pattern_index   .word       ?               ; index into wave-pattern (aka "animation" position)
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