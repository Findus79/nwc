.macro LoadPalette(src_addr, src_bank, start_color_index, bytes)
    nop
    lda #start_color_index
    sta CGADD
    lda #src_bank
    ldx #src_addr
    ldy #bytes
    jsr DMA_Palette
.endmacro

.macro LoadVRAM(src_addr, src_bank, dst, size)
    lda #$80
    sta VMAINC // set vram transfer mode to word, inc by 1

    ldx #dst
    stx VMADDL
    lda #src_bank
    ldx #src_addr
    ldy #size

    jsr DMA_VRAM
.endmacro




