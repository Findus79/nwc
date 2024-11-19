; macros...
LoadPalette .macro  ; // 1 src, 2 target palette index, 3 num colors
    lda     #\2
    sta     $802121
    lda     #`\1
    ldx     #<>\1
    ldy     #\3
    jsr     DMA_Palette
.endmacro

LoadVRAM .macro     ; // 1 src, 2 dst, 3 size
    lda     #$80
    sta     $802115 ; set vram transfer

    ldx     #(\2/2) ; divide by 2 to get "word address"
    stx     $802116
    lda     #`\1
    ldx     #<>\1
    ldy     #\3
    jsr     DMA_VRAM
.endmacro

; place metasprite at given position
SetMetasprite .macro    ; 1 src metasprite, x pos, y pos
    #A8
    pha
    phx
    phy
        lda     #`\1        ; load src sprite bank
        sta     tmp_0
        #A16
        lda     \2          ; load x pos to x
        tax
        lda     \3          ; load y pos to y
        tay
        lda     #<>\1    

        jsr     CopyMetasprite
    #A8
    ply
    plx
    pla
.endmacro