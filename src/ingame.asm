







Ingame

Ingame_OnEnter
.block
    ; disable vblank
    lda     #%10001111
    sta     $802100

    ; disable dma
    stz     $80420C

    ; set data_ptr
    #A8
    lda     #`IngameData
    sta     data_bnk
    #A16
    lda     #<>IngameData
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
    lda     #%00100010  ; bg1: 32x64 @ 4000/2000
    sta     $802107     ;

    lda     #%00101010  ; bg2: 32x64 @ 5600/2800
    sta     $802108     ;

    ; init layers (main)
    lda     #%00000010  ; obj | bg4 | bg3 | bg2 | bg1
    sta     $80212C
    ; init layers (sub)
    lda     #%00000001
    sta     $80212D

    ; setup color math
    lda     #%00000010
    sta     $802130         ; cgwsel

    lda     #%01000011
    sta     $802131         ; cgadsub

    lda     #$0e
    sta     $802132         ; coldata


    ; clear sprite OAM
    jsl     ShadowOAM_Clear

    ; reset scrolling registers
    stz     $80210e ; bg1
    stz     $80210e

    stz     $80210f ; bg2 
    stz     $80210f

    stz     $802111 ; bg3
    stz     $802111

    ; bg2 vscroll
    lda     #255
    sta     $802110
    stz     $802110

    ; init mosaic
    lda     #%00000011
    sta     reg_mosaic
    sta     $802106

    stz     tmp_0

    #A16
    stz     scroll_v_bg

    ; re-enable vblank (with full dark to begin)
    #A8
    stz     reg_brightness
    sta     $802100

    ; enable NMI and Joypads
    stz     $804016
    lda     #%10000001
    sta     $804200
.bend

Ingame_Loop
    #A8
    Ingame_Loop_Wait
        lda     NMIReadyNF
        bpl     Ingame_Loop_Wait
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
        
        ; scroll backgrounds
        .block ; scroll bg/fg
            #A16
            lda     scroll_v_bg
            dec     A
            and     #%0000000111111111
            sta     scroll_v_bg

            lda     scroll_v_fg
            dec     A
            dec     A
            and     #%0000000111111111
            sta     scroll_v_fg
            
            #A8
            ; scroll bg2 (background)
            lda     scroll_v_bg.lo
            sta     $802110
            lda     scroll_v_bg.hi
            sta     $802110
            ; scroll bg1 (foreground)
            lda     scroll_v_fg.lo
            sta     $80210e
            lda     scroll_v_fg.hi
            sta     $80210e
        .bend
        
        .block  ; handle input
        .bend

_done
        jmp     Ingame_Loop


Ingame_OnExit
.block
.bend

