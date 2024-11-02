

; a few simple macros for collision detection



CheckCollisionPoint .macro  ; // needs check_x and check_y filled
    .block
        #A8
        stz     collision_flags
        #A16
        jsr     CheckCollision
        bne     _collide

        jmp     _done
        _collide
            #A8
            lda     #1
            sta     collision_flags

        _done
    .bend
.endmacro

CheckPlayerCollisionUp      .macro
    .block
        #A8
        stz     collision_flags
        #AXY16
        clc
        lda     player_one.worldpos.x
        sbc     #6
        sta     check_x
        clc
        lda     player_one.worldpos.y
        sbc     #14
        sta     check_y
        jsr     CheckCollision
        bne     _collide ; collision found

        ; check upper right
        #AXY16
        clc
        lda     check_x
        adc     #12
        sta     check_x
        jsr     CheckCollision
        bne     _collide

        jmp     _done

        _collide
            #A8
            lda     #1
            sta     collision_flags

        _done
    .bend
.endmacro

CheckPlayerCollisionDown    .macro
    .block
        #A8
        stz     collision_flags
        #AXY16
        clc
        lda     player_one.worldpos.x
        sbc     #6
        sta     check_x
        clc
        lda     player_one.worldpos.y
        adc     #13
        sta     check_y
        jsr     CheckCollision
        bne     _collide ; collision found

        ; check upper right
        #AXY16
        clc
        lda     check_x
        adc     #12
        sta     check_x
        jsr     CheckCollision
        bne     _collide

        jmp     _done

        _collide
            #A8
            lda     #1
            sta     collision_flags

        _done
    .bend
.endmacro

CheckPlayerCollisionLeft    .macro
    .block
        #A8
        stz     collision_flags

        #AXY16
        clc
        lda     player_one.worldpos.x
        sbc     #7
        sta     check_x
        lda     player_one.worldpos.y
        sta     check_y
        jsr     CheckCollision
        bne     _collide ; collision found

        ; check upper right
        #AXY16
        clc
        lda     check_y
        sbc     #13
        sta     check_y
        jsr     CheckCollision
        bne     _collide

        ; check lower right
        #AXY16
        clc
        lda     check_y
        adc     #26
        sta     check_y
        jsr     CheckCollision
        bne     _collide

        jmp     _done

        _collide
            #A8
            lda     #1
            stz     collision_flags
            
        _done
    .bend
.endmacro

CheckPlayerCollisionRight   .macro
    .block
        #A8
        stz     collision_flags

        #AXY16
        clc
        lda     player_one.worldpos.x
        adc     #7
        sta     check_x
        lda     player_one.worldpos.y
        sta     check_y
        jsr     CheckCollision
        bne     _collide ; collision found

        ; check upper right
        #AXY16
        clc
        lda     check_y
        sbc     #13
        sta     check_y
        jsr     CheckCollision
        bne     _collide

        ; check lower right
        #AXY16
        clc
        lda     check_y
        adc     #26
        sta     check_y
        jsr     CheckCollision
        bne     _collide

        jmp     _done

        _collide
            #A8
            lda     #1
            sta     collision_flags

        _done
    .bend
.endmacro
