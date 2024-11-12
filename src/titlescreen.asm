







Titlescreen

Titlescreen_OnEnter
.block
    ; disable NMI
    #A8
    stz     $804200     ; disable NMI and auto-joypad
    ; enable force blank
    lda     #%10000000
    sta     $802100

    ; disable dma
    stz     $80420C

    ; load music
    ; #AXY16
	; lda #<>spc700_code
	; ldx #`spc700_code
	; jsl SPC_Init
	; lda #1
	; jsl SPC_Stereo
	; lda #<>music_1
	; ldx #`music_1
	; jsl SPC_Play_Song

    ; set data_ptr
    #A8
    lda     #`TitlescreenData
    sta     data_bnk
    #A16
    lda     #<>TitlescreenData
    sta     data_ptr

    ; init table index
    #A8
    #XY16
    ldy     #0

    ; load palette
    .block
        ;phb
            #A8
            lda     [data_ptr], y   ; load palette data bank
            sta     src_bank
            iny

            #A16
            lda     [data_ptr], y   ; load palette data address
            sta     src_address 
            iny
            iny     ; 2 bytes

            lda     [data_ptr], y   ; load palette size
            sta     src_size
            iny
            iny

            phy     ; push index
                #A8
                lda     #0          ; palette index offset
                sta     $802121     ;
                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_Palette
            ply     ; pop index
        ;plb
    .bend

    ; load tiles
    .block
        ;phb
            #A8
            lda     [data_ptr], y   ; load tiles data bank
            sta     src_bank
            iny

            #A16
            lda     [data_ptr], y   ; load tiles data address
            sta     src_address
            iny
            iny

            lda     [data_ptr], y   ; load tiles data size
            sta     src_size
            iny
            iny

            phy ; push index
                #A8
                #XY8
                lda     #$80
                sta     $802115 ; set vram transfer

                #XY16
                ldx     #$0000  ; at start of vram
                stx     $802116 ;

                #A8
                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_VRAM
            ply ; pop index
        ;plb
    .bend

    ; load maps
    .block
        ; foreground
        ;phb
            #A8
            lda     [data_ptr], y   ; load bg map data bank
            sta     src_bank
            iny

            #A16
            lda     [data_ptr], y   ; load bg map data address
            sta     src_address
            iny
            iny

            lda     [data_ptr], y   ; load bg map data size
            sta     src_size
            iny
            iny

            phy ; push index
                #A8
                lda     #$80
                sta     $802115 ; set vram transfer

                #XY16
                ldx     #$2000  ; at start of vram
                stx     $802116 ;

                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_VRAM
            ply ; pop index
        ;plb

        ; background
        ;phb
            #A8
            lda     [data_ptr], y   ; load fg map data bank
            sta     src_bank
            iny

            #A16
            lda     [data_ptr], y   ; load fg map data address
            sta     src_address
            iny
            iny

            lda     [data_ptr], y   ; load fg map data size
            sta     src_size
            iny
            iny

            phy ; push index
                #A8
                lda     #$80
                sta     $802115 ; set vram transfer

                #XY16
                ldx     #$2800  ; at start of vram
                stx     $802116 ;

                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_VRAM
            ply ; pop index
        ;plb
    .bend

    #AXY8
    ; setup bg mode
    lda     #$01        ; set screen mode 1 (4/4/2 bpp)
    sta     $802105

    ; setup tile data for bg1/2 (starts at $0000)
    lda     #%00000000  ; 4 bits for each layer
    sta     $80210B

    ; setup bg map addresses
    lda     #%00100001  ; bg1: 32x32 @ 4000/2000
    sta     $802107     ;

    lda     #%00101000  ; bg2: 32x32 @ 5600/2800
    sta     $802108     ;

    ; init layers
    lda     #%00000011  ; obj | bg4 | bg3 | bg2 | bg1
    sta     $80212C

    ; clear sprite OAM
    ;jsr     ShadowOAM_Clear

    ; reset scrolling registers
    stz     $80210e ; bg1
    stz     $80210e

    lda     #255
    sta     scroll_v_bg.lo
    stz     scroll_v_bg.hi
    
    stz     scroll_v_fg.lo
    stz     scroll_v_fg.hi

    ; init mosaic
    lda     #%00000011
    sta     reg_mosaic
    sta     $802106

    .block ; init hdma table
        #A8
        #XY16
        ; setup h-dma animation (indirect bg2 animation)
        sep     #$20
        lda     #%01000010      ; to ppu, 1 register, write twice
        sta     $804330         ;
        lda     #$0F            ; horizontal scroll bg2
        sta     $804331         ; destination
        ldx     #<>TitlescreenHDMA
        stx     $804332         ; address
        lda     #`TitlescreenHDMA
        sta     $804334         ; bank
        lda     #`hdma_scroll_a
        sta     $804337         ; indirect address bank
        lda     #%00001000      ; channel 1
        sta     $80420C         ; $420c
    .bend

    #A16
    lda     #<>Titlescreen_Main
    sta     gamestate_ptr

    lda     #<>Titlescreen_VBlank
    sta     vblank_ptr

    #XY8
    #A8

    ; enable NMI and Joypads
    lda     $804210

    lda     #%10000001
    sta     $804200

    rts
.bend

Titlescreen_Main
    ;jsr ShadowOAM_Clear
    .block
        ; phb
        ; pha
        ; phx
        ; phy
        #A16
        .block
            lda     hdma_scroll_a.lo
            inc     a
            sta     hdma_scroll_a.lo
            
            lda     hdma_scroll_b.lo
            dec     A
            sta     hdma_scroll_b.lo
        .bend
        
        .block  ; handle input
            jsr     PAD_READ
            #A16
            lda     pad_1_pressed
            and     #PAD_START
            bne     _exit
            jmp     _done

            _exit
                #A16
                lda     #<>Ingame_OnEnter
                sta     gamestate_ptr

            _done
        .bend
        #A8
        ; ply
        ; plx
        ; pla
        ; plb
    .bend

    _done
        rts

Titlescreen_VBlank
    phb
    ; #AXY8
    ;     jsr DMA_OAM

    ; write shadow PPU registers
    #A8
    lda     reg_brightness
    inc     A
    and     #%00001111
    sta     reg_brightness
    plb
    rts

