







Titlescreen

Titlescreen_OnEnter
.block
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

    ; load/play music
    ; #AXY16
    ; lda     #<>music_1
	; ldx     #`music_1
	; jsl     SPC_Play_Song

    ; reset scrolling registers
    stz     $80210e ; bg1
    stz     $80210e

    ; scroll bg 1 pixel.
    #A8
    lda     #$FF
    sta     reg_scroll_v_bg2.lo

    ; init mosaic
    lda     #%11111111
    sta     reg_mosaic
    sta     $802106

    stz     reg_brightness

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
    lda     #<>Titlescreen_FadeIn
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
    .block
        #AXY16
        .block  ; handle input
            jsr     PAD_READ
            lda     pad_1_pressed
            and     #PAD_START
            bne     _exit

            clc
            lda     pad_1_pressed
            and     #PAD_LEFT
            bne     _scroll_logo_left

            clc
            lda     pad_1_pressed
            and     #PAD_RIGHT
            bne     _scroll_logo_right

            jmp     _done

            _scroll_logo_left
                lda     #<>Titlescreen_LogoLeft
                sta     gamestate_ptr
                jmp     _done

            _scroll_logo_right
                lda     #<>Titlescreen_LogoRight
                sta     gamestate_ptr
                jmp     _done

            _exit
                lda     #<>Titlescreen_FadeOut
                sta     gamestate_ptr

            _done
        .bend

        .block  ; handle snowflake sprites
        .bend;
        #AXY8
    .bend

    _done
        rts

Titlescreen_LogoLeft
    #A16
    lda     reg_scroll_h_bg1
    cmp     #$00
    beq     _exit

    clc     
    sbc     #4
    bmi     _exit
    sta     reg_scroll_h_bg1
    jmp     _done
    
    _exit
        stz     reg_scroll_h_bg1        ; just to be safe
        lda     #<>Titlescreen_Main
        sta     gamestate_ptr

    _done
    rts

Titlescreen_LogoRight
    #A16
    lda     reg_scroll_h_bg1
    cmp     #$100
    beq     _exit

    clc     
    adc     #4
    sta     reg_scroll_h_bg1
    jmp     _done
    
    _exit
        lda     #$0100
        sta     reg_scroll_h_bg1        ; just to be safe
        lda     #<>Titlescreen_Main
        sta     gamestate_ptr

    _done
    rts

Titlescreen_FadeIn
    .block
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
    .bend
    rts

Titlescreen_FadeOut
    .block
        #A16
        lda     current_frame
        and     #1
        beq     _done

        #A8
        clc
        lda     reg_brightness
        cmp     #$00
        beq     _exit

        lda     reg_brightness
        dec     A
        and     #%00001111
        sta     reg_brightness

        lda     reg_mosaic
        clc
        adc     #%00010000
        sta     reg_mosaic

        jmp     _done

        _exit
            #A16
            lda     #<>Ingame_OnEnter
            sta     gamestate_ptr

        _done
    .bend
    rts

Titlescreen_VBlank
    phb
        .block  ; set hdma scroll values
            #A16
            lda     current_frame
            and     #1
            bne     _done

            #A8
            lda     hdma_scroll_a.lo
            inc     a
            sta     hdma_scroll_a.lo
            
            lda     hdma_scroll_b.lo
            dec     A
            sta     hdma_scroll_b.lo
            
            _done
        .bend
    plb
    rts

