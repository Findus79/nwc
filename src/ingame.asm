







Ingame

Ingame_OnEnter
.block
    ; disable NMI
    #A8
    stz     $804200     ; disable NMI and auto-joypad
    ; enable force blank
    lda     #%10000000
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
                ldx     #$4000  ; at start of vram
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
                ldx     #$4800  ; at start of vram
                stx     $802116 ;

                lda     src_bank
                ldx     src_address
                ldy     src_size

                jsr     DMA_VRAM
            ply ; pop index
        ;plb
    .bend

    ; load sprite data
    ; set data_ptr
    #A8
    lda     #`SpriteData
    sta     data_bnk
    #A16
    lda     #<>SpriteData
    sta     data_ptr

    ; init table index
    ; #XY16
    ; ldy     #0

    ; .block  ; load sprite data
    ;     ; palette first
    ;     ;phb
    ;         #A8
    ;         lda     [data_ptr], y   ; load palette data bank
    ;         sta     src_bank
    ;         iny

    ;         #A16
    ;         lda     [data_ptr], y   ; load palette data address
    ;         sta     src_address 
    ;         iny
    ;         iny     ; 2 bytes

    ;         lda     [data_ptr], y   ; load palette size
    ;         sta     src_size
    ;         iny
    ;         iny

    ;         phy     ; push index
    ;             #A8
    ;             lda     #128        ; palette index offset (in bytes)
    ;             sta     $802121     ;
    ;             lda     src_bank
    ;             ldx     src_address
    ;             ldy     src_size

    ;             jsr     DMA_Palette
    ;         ply     ; pop index
    ;     ;plb
    ;     ; sprite tiles
    ;     #A16
    ;     ;phb
    ;         #A8
    ;         lda     [data_ptr], y   ; load tiles data bank
    ;         sta     src_bank
    ;         iny

    ;         #A16
    ;         lda     [data_ptr], y   ; load tiles data address
    ;         sta     src_address
    ;         iny
    ;         iny

    ;         lda     [data_ptr], y   ; load tiles data size
    ;         sta     src_size
    ;         iny
    ;         iny

    ;         phy ; push index
    ;             #A8
    ;             #XY8
    ;             lda     #$80
    ;             sta     $802115 ; set vram transfer

    ;             #XY16
    ;             ldx     #$2000  ; at start of vram
    ;             stx     $802116 ;

    ;             lda     src_bank
    ;             ldx     src_address
    ;             ldy     src_size

    ;             ;jsr     DMA_VRAM
    ;         ply ; pop index
    ;     plb
    ; .bend

    #A8
    ; setup bg mode
    lda     #$01        ; set screen mode 1 (4/4/2 bpp)
    sta     $802105

    ; setup tile data for bg1/2 (starts at $0000)
    lda     #%00000000  ; 4 bits for each layer
    sta     $80210B

    ; setup bg map addresses
    lda     #%01000010  ; bg1: 32x64 @ 4000/2000
    sta     $802107     ;

    lda     #%01001010  ; bg2: 32x64 @ 5600/2800
    sta     $802108     ;

    ; setup sprite mode and address
    ;lda     #%00000000
    ;sta     $802101

    ; init layers (main)
    lda     #%00010010  ; obj | bg4 | bg3 | bg2 | bg1
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
    ;jsr     ShadowOAM_Clear

    #A16
    ; reset scrolling registers
    stz     scroll_v_bg
    stz     scroll_v_fg

    #A8
    lda     #$0F
    sta     reg_brightness

    ; init mosaic
    lda     #%00000011
    sta     reg_mosaic
    sta     $802106
    
    #A16
    lda     #<>Ingame_VBlank
    sta     vblank_ptr

    lda     #<>Ingame_Loop
    sta     gamestate_ptr

    ; re-enable vblank (with full dark to begin)
    #A8
    ; setup player pos
    lda     #128
    sta     player_x_pos
    sta     player_y_pos 

    lda     #20
    sta     player2_x_pos
    sta     player2_y_pos

    ; enable NMI and Joypads
    #XY8
    #A8

    lda     $804210

    lda     #%10000001
    sta     $804200

    rts
.bend

Ingame_Loop
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
        
    .bend
    
    .block  ; handle input
    .bend

    .block  ; sprite loop
        #A16
        jsr     ShadowOAM_Clear

        #A8
        ;jsr SetOAMPtr
        ;SetMetasprite PlayerSprite, player_x_pos, player_y_pos
        ;SetMetasprite PlayerSprite, player2_x_pos, player2_y_pos
    .bend

    _done
        rts


Ingame_VBlank
    phb
        #AXY8
            jsr DMA_OAM
    plb
    rts


