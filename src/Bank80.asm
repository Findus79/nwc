; Bank80


; fake snes addressing/shadowing of shared ram/wram
.virtual $800000+gSharedRamStart
.dsection secSharedWRAM
.endv

.as                         ; assume 8-bit A
.xs                         ; assume 8-bit X
.autsiz                     ; auto size detect
.databank   $00             ; databank to 0
.dpage      $0000           ; dpage 0000



Reset
    clc
    xce                     ; set to 65816 native mode
    lda     #$01
    sta     $420D
    jml     ResetHi

ResetHi
    rep     #$30            ; a/xy to 16-bit
    ldx     #$1FFF          ; set stack pointer/address
    txs
    phk
    plb
.databank   $80
    lda     #$0000
    tcd
    lda     #$008F          ; force v-blank, obsel to 0
    sta     $802100
ClearWRAM
    lda     #$8008          ; a -> b, fixed source, write byte|wram
    sta     $804300
    lda     #<>DMAZero      ; get low word 
    sta     $804302         
    lda     #`DMAZero       ; get bank
    sta     $804303
    stz     $802181
    stz 	$802182         ; start at 7e:0000
    stz     $804305         ; do 64k
    lda     #$0001
    sta     $80420B         ; start dma
    sta     $80420B         ; start dma again (2 times 64k matches 128k wram)
InitSNESAndMirror
    rep     #$20            ; a16
    lda     #$008F      ; FORCE BLANK, SET OBSEL TO 0
    sta     $802100
    stz     $802105 ;6
    ;stz mBGMODE
    ;stz mMOSIAC
    stz     $802107 ;8
    ;stz mBG1SC
    ;stz mBG2SC
    stz     $802109 ;A
    ;stz mBG3SC
    ;stz mBG4SC
    stz     $80210B ;C
    ;stz mBG12NBA
    ;stz mBG23NBA
    stz     $80210D ;E
    stz     $80210D ;E
    ;stz mBG1HOFS
    ;stz mBG1VOFS
    stz     $80210F ;10
    stz     $80210F ;10
    ;stz mBG2HOFS
    ;stz mBG2VOFS
    stz     $802111 ;12
    stz     $802111 ;12
    ;stz mBG3HOFS
    ;stz mBG3VOFS
    stz     $802113 ;14
    stz     $802113 ;14
    ;stz mBG4HOFS
    ;stz mBG4VOFS
    stz     $802119 ;1A to get Mode7
    stz     $80211B ;1C these are write twice
    stz     $80211B ;1C regs
    stz     $80211D ;1E
    stz     $80211D ;1E
    stz     $80211F ;20
    stz     $80211F ;20
    ; add mirrors here if you are doing mode7
    stz     $802123 ;24
    ;stz mW12SEL
    ;stz mW34SEL
    stz     $802125 ;26
    ;stz mWOBJSEL
    stz     $802126 ;27 YES IT DOUBLES OH WELL
    stz     $802128 ;29
    ;stz mWH0
    ;stz mWH1
    ;stz mWH2
    ;stz mWH3
    stz     $80212A ;2B
    ;stz mWBGLOG
    ;stz mOBJLOG
    stz     $80212C ;2D
    stz     $80212E ;2F
    ;stz mTM
    ;stz mTS
    ;stz mTMW
    ;stz mTSW
    lda     #$00E0
    sta     $802132
    ;sta     mCOldaTA
    ;stz mSETINI
    ;ONTO THE CPU I/O REGS
    lda     #$FF00
    sta     $804201
    ;stz mNMITIMEN
    stz     $804202 ;3
    stz     $804204 ;5
    stz     $804206 ;7
    stz     $804208 ;9
    stz     $80420A ;B
    stz     $80420C ;D
    ; CLEAR VRAM
    REP     #$20       ; A16
    lda     #$1809     ; A -> B, FIXED SOURCE, WRITE WORD | VRAM
    sta     $804300
    lda     #<>DMAZero ; THIS GET THE LOW WORD, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
    sta     $804302
    lda     #`DMAZero  ; THIS GETS THE BANK, YOU WILL NEED TO CHANGE IF NOT USING 64TASS
    sta     $804304    ; AND THE UPPER BYTE WILL BE 0
    stz     $804305    ; DO 64K
    lda     #$80       ; INC ON HI WRITE
    sta     $802115
    stz     $802116    ; staRT AT 00
    lda     #$01
    sta     $80420B    ; FIRE DMA
    ; CLEAR CG-RAM
    lda     #$2208     ; A -> B, FIXED SOURCE, WRITE BYTE | CG-RAM
    sta     $804300
    lda     #$200      ; 512 BYTES
    sta     $804305
    SEP     #$20       ; A8
    stz     $802121    ; staRT AT 0
    lda     #$01
    sta     $80420B    ; FIRE DMA
    stz     NMIReadyNF

    ; load audio driver
InitAudioDriver
    ; #AXY16
    ; lda     #<>spc700_code
    ; ldx     #`spc700_code
    ; jsl     SPC_Init
    ; lda 	#1
    ; jsl     SPC_Stereo
    ; #A8

    ; CLI

    jmp     Titlescreen


.include "defines.asm"

;.include "spc.asm"
.include "titlescreen.asm"
.include "ingame.asm"
.include "music/music.asm"


DMAZero .word   $0000

DMA_Palette
    phb
    php

    stx     $804302     ; source address
    sta     $804304     ; source bank
    sty     $804305     ; bytes to transfer

    stz     $804300     ; dma
    lda     #$22        ; write to $2122 (CGRAM)
    sta     $804301     ; ""
    lda     #$01        ; start
    sta     $80420B     ; dma transfer

    plp
    plb

    rts

DMA_VRAM
    phb
    php

    ; dma setup
    stx     $804302     ; data offset
    sta     $804304     ; src data bank
    sty     $804305     ; size

    lda     #$01        ; set dma mode
    sta     $804300     
    lda     #$18        ; set dst register (vram write register)
    sta     $804301
    lda     #$01
    sta     $80420B      ; start dma transfer

    plp
    plb
    rts

DMA_OAM
    php
    rep     #$10        ; XY 16-bit
    sep     #$20        ; A 8-bit
    stz     $802102     ; OAM is zero
    stz     $802103
    ldx     #$0400
    stx     $804310
    ldx     #<>ShadowOAM
    stx     $804312
    ldx     #$207E
    stx     $804314
    lda     #$02
    sta     $804316
    sta     $80420B
    plp
    rts

PAD_READ
    php
    lda     $804212     ; read pad status
    and     #$01        ; check if pad is ready
    bne     PAD_READ

    rep     #$30        ; all registers set to 16bit.

    ; player one
    ldx     #$00
    lda     pad_1_raw,X   ; pad_1_raw
    tax
    lda     $804218     ; pad one register (word)
    sta     pad_1_raw
    txa                 ; transfer last state to A
    eor     pad_1_raw   ; xor -> get difference between last and current input state
    and     pad_1_raw   ; get currently pressed inputs
    sta     pad_1_pressed
    txa 
    and     pad_1_raw
    sta     pad_1_repeat

    sep     #$10
    rep     #$20
    plp
    rts

; sprite clear values...
SpriteClearValue        .byte   $E0
SpriteUpperClearValue   .byte   $00

ShadowOAM_Clear
    php
    rep     #$10        ; xy 16-bit
    sep     #$20        ; a 8-bit
    ; first 512 bytes aka 256 words
    ldx     #$8018
    stx     $804300     ; setup dma (4300+4301)
    ldx     #<>SpriteClearValue
    stx     $804302
    ldx     #`SpriteClearValue
    stx     $804304
    ldx     #512
    stx     $804305
    ldx     #<>ShadowOAM
    stx     $802181
    lda     #`ShadowOAM
    sta     $802183
    lda     #$01
    sta     $80420B

    ; upper 32 bytes
    ldx     #$8018
    stx     $804300     ; setup dma
    ldx     #<>SpriteUpperClearValue
    stx     $804302
    ldx     #`SpriteUpperClearValue
    stx     $804304
    ldx     #32
    stx     $804305
    ldx     #<>ShadowOAMHi
    stx     $802181
    lda     #`ShadowOAMHi
    sta     $802183
    lda     #$01
    sta     $80420B
    plp
    rts


CopyMetasprite 
.block
    phb
    php

    ; tmp_0 src bank
    ; a src address
    ; x pos x
    ; y pos y
    stx sprite_pos_x
    sty sprite_pos_y
    sta sprite_address

    #A8
    lda tmp_0
    sta sprite_bank

    #XY8

    lda [sprite_address]
    tax ; use number of tiles for tile-copy loop
    #XY16
    ldy #1

    _tile_loop
        phx
            ldx oam_offset
            clc
            lda [sprite_address],y    ; relative x position
            adc sprite_pos_x          ; add absolute x position
            sta [oam_ptr]
            #A16
            lda oam_ptr
            ina
            sta oam_ptr
            #A8
            iny

            clc
            lda [sprite_address],y    ; relative y position
            adc sprite_pos_y            ; add absolute y position
            sta [oam_ptr]            ; store
            #A16
            lda oam_ptr
            ina
            sta oam_ptr
            #A8
            iny

            lda [sprite_address],y    ; tile number
            sta [oam_ptr]            ; store
            #A16
            lda oam_ptr
            ina
            sta oam_ptr
            #A8
            iny

            lda [sprite_address],y    ; attributes
            sta [oam_ptr]
            #A16
            lda oam_ptr
            ina
            sta oam_ptr
            #A8
            iny
            
        plx
        dex
        bne _tile_loop
        
    plb
    plp
    rts
.bend


VBlank
    jml     VBlankFast

VBlankFast
    phb						; Save Data Bank
	phk
	plb						; Set Data Bank to Match Program Bank
	#A8						; A8
	bit $804210				; Ack NMI
	bit@W NMIReadyNF,b	    ; Check if this is safe
	bpl _ready
		plb					; No, restore Data Bank
		rti					; Exit
_ready						; Safe
	#AXY16					; A16 XY16
	pha
	phx
	phy						; Save A,X,Y
	phd						; Save the DP register
	lda #0000				; or where ever you want your NMI DP
	tcd						; set DP to known value
	; do update code here
	#AXY16
        inc current_frame

    #AXY8
        jsr DMA_OAM

        ; write shadow PPU registers
        lda     reg_brightness
        sta     $802100
	
    ; finish
    #A8					; A8
	lda #$FF				; Doing this is slightly faster than DEC, but 2 more bytes
	sta NMIReadyNF		; set NMI Done Flag
	#AXY16				; A16 XY16
	pld					; restore DP page
	ply
	plx
	pla					; Restore A,X,Y
	plb					; Restore Data Bank
justRTI
	rti					; Exit


    
.section secDP
; helper vars for data loading
src_address   .word   ?
src_bank      .byte   ?
src_size      .word   ?
dst_address   .word   ?

data_ptr      .word   ?
data_bnk      .byte   ?

dma_transfer    .byte   ?

current_frame    .word   ?
last_frame       .word   ?
framediff        .word   ?

; shadow registers to be manipulated by level scripting
reg_mosaic      .byte   ?
reg_brightness  .byte   ?   ; [0-15]

scroll_v_bg     .dunion HLWord
scroll_v_fg     .dunion HLWord

NMIReadyNF    .byte   ?

tmp_0               .byte   ?
tmp_1               .byte   ?
tmp_2               .byte   ?
tmp_3               .byte   ?

wtmp_0              .word   ?
wtmp_1              .word   ?

sprite_pos_x        .byte   ?
sprite_pos_y        .byte   ?

sprite_address      .word   ?
sprite_bank         .byte   ?

oam_ptr             .word   ?
oam_bank            .byte   ?
oam_offset          .word   ?

.send