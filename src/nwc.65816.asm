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
.byte 0
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
*=$19fff
.byte 0
.cerror * > $20000, "overflow at bank 83: ", * - $20000

* = $020000
.logical $848000
.dsection secBank84
.here
*=$27fff
.byte 0
.cerror * > $28000, "overflow at bank 84: ", * - $28000

* = $028000
.logical $858000
.dsection secBank85
.here
*=$29fff
.byte 0
.cerror * > $30000, "overflow at bank 85: ", * - $30000

* = $030000
.logical $868000
.dsection secBank86
.here
*=$37fff
.byte 0
.cerror * > $38000, "overflow at bank 86: ", * - $38000

* = $038000
.logical $878000
.dsection secBank87
.here
*=$39fff
.byte 0
.cerror * > $40000, "overflow at bank 87: ", * - $40000

* = $040000
.logical $888000
.dsection secBank88
.here
*=$47fff
.cerror * > $48000, "overflow at bank 88: ", * - $48000

*=$07ffff
.byte 0



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
player_bullets .block   ; 16 bullets for the player at once for now.
    .fill   32*5        ; 5 bytes per bullet
.bend

enemy_objects .block
    .fill   16*11        ; max of 16 enemies at once
.bend

; place hdma stuff
* = $7e4000
hdma_scroll_a       .dunion HLWord
hdma_scroll_b       .dunion HLWord
.send ; secLoWRAM


.enc "none"
; SNES HEADER SETUP
.section secHeader
    .word   0
    .text   "test"
    .fill   7, 0
    .byte   0       ; RAM
    .byte   0       ; special version
    .byte   0       ; cart type
    ;        123456789012345678901
    .text   "nerdwelten weihnacht " ; needs proper length
.cerror * != $80ffd5, "name is short", *
    .byte   $30     ; mapping
    .byte   $00     ; rom
    .byte   $09     ; 512K
    .byte   $00     ; 0K SRAM
    .byte   $00     ; NTSC
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
        .word   len(binary("../data/Sprites/snowflakes.palette"))

        .byte   `TitlescreenSpriteTiles
        .word   <>TitlescreenSpriteTiles
        .word   len(binary("../data/Sprites/snowflakes.tiles"))
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

    IngamePalette   .binary "../data/Ingame/Ingame.palette"
    IngameTiles     .binary "../data/Ingame/Foreground.tiles"
    IngameMap_BG    .binary "../data/Ingame/Background.map"
    IngameMap_FG    .binary "../data/Ingame/Foreground.map"

    IngameSpritePalette   .binary "../data/Sprites/Sprites.palette"
    IngameSpriteTiles     .binary "../data/Sprites/Sprites.tiles"

    PlayerSF        .binary "../data/Sprites/Player_SF.metasprite"
    PlayerNW        .binary "../data/Sprites/Player_NW.metasprite"
    Snowball        .binary "../data/Sprites/snowball.metasprite"

    Wavenumbers
        .word   <>wave_spr_1
        .word   <>wave_spr_2
        .word   <>wave_spr_3
        .word   <>wave_spr_4
        .word   <>wave_spr_5
        .word   <>wave_spr_6
        .word   <>wave_spr_7
        .word   <>wave_spr_8
        .word   <>wave_spr_9
        .word   <>wave_spr_10
        .word   <>wave_spr_11
        .word   <>wave_spr_12
        .word   <>wave_spr_13
        .word   <>wave_spr_14
        .word   <>wave_spr_15
        .word   <>wave_spr_16
        .word   <>wave_spr_17
        .word   <>wave_spr_18
        .word   <>wave_spr_19
        .word   <>wave_spr_20
        .word   <>wave_spr_21
        .word   <>wave_spr_22
        .word   <>wave_spr_23
        .word   <>wave_spr_24
    
    Wavesprites
        wave_spr_1      .binary "../data/Sprites/wave_01.metasprite"
        wave_spr_2      .binary "../data/Sprites/wave_02.metasprite"
        wave_spr_3      .binary "../data/Sprites/wave_03.metasprite"
        wave_spr_4      .binary "../data/Sprites/wave_04.metasprite"
        wave_spr_5      .binary "../data/Sprites/wave_05.metasprite"
        wave_spr_6      .binary "../data/Sprites/wave_06.metasprite"
        wave_spr_7      .binary "../data/Sprites/wave_07.metasprite"
        wave_spr_8      .binary "../data/Sprites/wave_08.metasprite"
        wave_spr_9      .binary "../data/Sprites/wave_09.metasprite"
        wave_spr_10     .binary "../data/Sprites/wave_10.metasprite"
        wave_spr_11     .binary "../data/Sprites/wave_11.metasprite"
        wave_spr_12     .binary "../data/Sprites/wave_12.metasprite"
        wave_spr_13     .binary "../data/Sprites/wave_13.metasprite"
        wave_spr_14     .binary "../data/Sprites/wave_14.metasprite"
        wave_spr_15     .binary "../data/Sprites/wave_15.metasprite"
        wave_spr_16     .binary "../data/Sprites/wave_16.metasprite"
        wave_spr_17     .binary "../data/Sprites/wave_17.metasprite"
        wave_spr_18     .binary "../data/Sprites/wave_18.metasprite"
        wave_spr_19     .binary "../data/Sprites/wave_19.metasprite"
        wave_spr_20     .binary "../data/Sprites/wave_20.metasprite"
        wave_spr_21     .binary "../data/Sprites/wave_21.metasprite"
        wave_spr_22     .binary "../data/Sprites/wave_22.metasprite"
        wave_spr_23     .binary "../data/Sprites/wave_23.metasprite"
        wave_spr_24     .binary "../data/Sprites/wave_24.metasprite"
    
    
    Wavetable .block    ; all waves defs have to be stored in the same bank
        .byte   `Wave_Definitions  ; wave-defs bank
        .word   <>Wave_1           ; wave-def addr
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_2
        .word   <>Wave_1
        .word   <>Wave_24
    .bend

    EnemyTable .block
        .byte   `Enemy_Sprites
        .word   <>Enemy_0
        .word   <>Enemy_1
        .word   <>Enemy_2
    .bend

    PatternTable .block
        .byte   `Pattern_Definitions
        .word   <>Pattern_0
        .word   <>Pattern_1
    .bend

.send

.section secBank82
    TitlescreenPalette  .binary "../data/Titlescreen/Titlescreen.palette"
    TitlescreenTiles    .binary "../data/Titlescreen/Foreground.tiles"
    TitlescreenMap_BG   .binary "../data/Titlescreen/Background.map"
    TitlescreenMap_FG   .binary "../data/Titlescreen/Foreground.map"

    TitlescreenSpritePalette   .binary "../data/Sprites/snowflakes.palette"
    TitlescreenSpriteTiles     .binary "../data/Sprites/snowflakes.tiles"

    snowflake_small_a   .binary "../data/Sprites/snowflake_small_a.metasprite"
    snowflake_medium_a  .binary "../data/Sprites/snowflake_medium_a.metasprite"

    Enemy_Sprites
        Enemy_0         .binary "../data/Sprites/gingerbreadman.metasprite"
        Enemy_1         .binary "../data/Sprites/ufo_elf.metasprite"
        Enemy_2         .binary "../data/Sprites/santa.metasprite"

    ;wave definition. number of enemies: type, starting position, pattern and time-offset from wave start
    Wave_Definitions
    Wave_1  .block
        .byte   4          ; enemy count

        .byte   1           ; enemy type
        .byte   32, 224     ; first enemy position x,y
        .byte   0           ; pattern index
        .word   3*8         ; frame offset until start

        .byte   1           ; enemy type
        .byte   32, 224     ; first enemy position x,y
        .byte   0           ; pattern index
        .word   7*8         ; frame offset until start

        .byte   1           ; enemy type
        .byte   32, 224     ; first enemy position x,y
        .byte   0           ; pattern index
        .word   11*8         ; frame offset until start

        .byte   1           ; enemy type
        .byte   32, 224     ; first enemy position x,y
        .byte   0           ; pattern index
        .word   15*8        ; frame offset until start

        .byte   1           ; enemy type
        .byte   192, 224     ; first enemy position x,y
        .byte   1           ; pattern index
        .word   19*8         ; frame offset until start

        .byte   1           ; enemy type
        .byte   192, 224     ; first enemy position x,y
        .byte   1           ; pattern index
        .word   23*8         ; frame offset until start

        .byte   1           ; enemy type
        .byte   192, 224     ; first enemy position x,y
        .byte   1           ; pattern index
        .word   27*8         ; frame offset until start

        .byte   1           ; enemy type
        .byte   192, 224     ; first enemy position x,y
        .byte   1           ; pattern index
        .word   31*8        ; frame offset until start       
    .bend
    Wave_2 .block
        .byte   1          ; enemy count

        .byte   2           ; enemy type
        .byte   100, 224    ; first enemy position x,y
        .byte   0           ; pattern index
        .word   3*8         ; frame offset until start
    .bend
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
        Pattern_0
            .binary     "../data/Patterns/left_right.pattern"
        Pattern_1
            .binary     "../data/Patterns/right_left.pattern"
.send

.section secBank83
    spc_code
    .binary     "../data/Music/spc700.bin"    

    music_1
    .binary     "../data/Music/music_1.bin"
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
    screenpos       .dstruct    ScreenPosition  ; (+1/3)
    sprite_ptr      .word       ?               ; (+5)  metasprite ptr
    pattern_ptr     .word       ?               ; (+7)  wave-pattern ptr
    frame_offset    .word       ?               ; (+9) frames until pattern playback starts
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