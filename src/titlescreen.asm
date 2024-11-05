







Titlescreen

Titlescreen_OnEnter
.block
    ; disable vblank
    lda     #%10001111
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
    #XY16
    ldy     #0

    ; load palette
    .block
        phb
            lda     [data_ptr], y   ; load palette data bank
            sta     src_bank
            iny

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
        plb
    .bend

    ; load tiles
    .block
        #A16
        phb
            lda     [data_ptr], y   ; load tiles data bank
            sta     src_bank
            iny

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
                lda     #$80
                sta     $802115 ; set vram transfer

                ldx     #$0000  ; at start of vram
                stx     $802116 ;

                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_VRAM
            ply ; pop index
        plb
    .bend

    ; load maps
    .block
        #A16
        ; foreground
        phb
            lda     [data_ptr], y   ; load bg map data bank
            sta     src_bank
            iny

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

                ldx     #$2000  ; at start of vram
                stx     $802116 ;

                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_VRAM
            ply ; pop index
        plb

        ; background
        #A16
        phb
            lda     [data_ptr], y   ; load fg map data bank
            sta     src_bank
            iny

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

                ldx     #$2800  ; at start of vram
                stx     $802116 ;

                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_VRAM
            ply ; pop index
        plb
    .bend

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
    jsl     ShadowOAM_Clear

    ; reset scrolling registers
    stz     $80210e ; bg1
    stz     $80210e

    lda     #255
    sta     $802110
    stz     $802110
    
    stz     $80210f ; bg2 
    stz     $80210f

    stz     $802111 ; bg3
    stz     $802111

    ; init mosaic
    lda     #%00000011
    sta     reg_mosaic
    sta     $802106

    .block ; init hdma table
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

    ; re-enable vblank (with full dark to begin)
    #A8
    stz     reg_brightness
    sta     $802100

    ; enable NMI and Joypads
    stz     $804016
    lda     #%10000001
    sta     $804200
.bend

Titlescreen_Loop
    #A8
Titlescreen_Loop_Wait
        lda     NMIReadyNF
        bpl     Titlescreen_Loop_Wait
        stz     NMIReadyNF          ; clear flag

        
_fadeIn
        lda     current_frame
        bit     #1
        beq     _mainUpdate

        ; until reg_brightness < 16 increment and do not take input from player
        lda     reg_brightness
        cmp     #$0F
        beq     _mainUpdate ; full brightness?
        
        ina
        and     #%00001111
        sta     reg_brightness

        jmp     _mainUpdate

_fadeOut

_mainUpdate
        
        jsr ShadowOAM_Clear

        .block  ; handle hdma scrolling values
            lda     hdma_scroll_a.lo
            inc     a
            sta     hdma_scroll_a.lo
            
            lda     hdma_scroll_b.lo
            dec     A
            sta     hdma_scroll_b.lo
        .bend

        .block  ; handle input
            
            jsr     PAD_READ
            #A8
            lda     pad_1_pressed+1
            and     #$80
            bne     Titlescreen_OnExit

        .bend

_done
        jmp     Titlescreen_Loop


Titlescreen_OnExit
.block
    stz     $80420C     ; stop h-dma
    jmp     Ingame_OnEnter
.bend

