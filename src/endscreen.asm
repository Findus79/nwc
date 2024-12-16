







Endscreen

Endscreen_OnEnter .block
    ; disable NMI
    #A8
    stz     $804200     ; disable NMI and auto-joypad
    ; enable force blank and set bg brightness to zero
    lda     #%10000000
    sta     $802100

    ; disable dma
    stz     $80420C

    ; set data_ptr
    #A8
    lda     #`EndscreenData
    sta     data_bnk
    #A16
    lda     #<>EndscreenData
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
    .bend

    

    ; setup ppu
    .block
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
        lda     #%00000001  ; obj | bg4 | bg3 | bg2 | bg1
        sta     $80212C

        ; scroll bg 1 pixel.
        #A8
        lda     #$FF
        sta     reg_scroll_v_bg1.lo

        stz     reg_scroll_h_bg1.lo
        stz     reg_scroll_h_bg1.hi

        ; init mosaic
        lda     #%11111111
        sta     reg_mosaic
        sta     $802106

        stz     reg_brightness
    .bend

    #A16
    lda     #<>Endscreen_FadeIn
    sta     gamestate_ptr

    lda     #<>Endscreen_VBlank
    sta     vblank_ptr

    #XY8
    #A8

    ; enable NMI and Joypads
    lda     $804210

    lda     #%10000001
    sta     $804200

    rts
.bend

Endscreen_Main .block
    rts
.bend

Endscreen_FadeIn .block
    #A16
    lda     current_frame
    and     #1
    beq     _done

    #A8
    clc
    lda     reg_brightness
    and     #%00001111
    cmp     #$0F
    beq     _exit

    lda     reg_brightness
    inc     A
    and     #%00001111
    sta     reg_brightness

    lda     reg_mosaic
    clc
    sbc     #%00010000
    ora     #%00001111
    sta     reg_mosaic
    jmp     _done

    _exit
        #A8
        lda     #%00001111
        sta     reg_mosaic
        #A16
        lda     #<>Titlescreen_Main
        sta     gamestate_ptr

    _done
    rts
.bend

Endscreen_VBlank .block
    rts
.bend
