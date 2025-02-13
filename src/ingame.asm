







Ingame

Ingame_OnEnter .block
    ; disable NMI
    #A8
    stz     $804200     ; disable NMI and auto-joypad
    ; enable force blank
    lda     #%10000000
    sta     $802100

    ; disable dma
    stz     $80420C

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
    lda     #`IngameSpriteData
    sta     data_bnk
    #A16
    lda     #<>IngameSpriteData
    sta     data_ptr

    ; init table index
    #XY16
    ldy     #0

    .block  ; load sprite data
        ; palette first
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
            lda     #128        ; palette index offset (in bytes)
            sta     $802121     ;
            lda     src_bank
            ldx     src_address
            ldy     src_size

            jsr     DMA_Palette
        ply     ; pop index
    
        ; sprite tiles
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
            ldx     #$2000  ; at start of vram
            stx     $802116 ;

            lda     src_bank
            ldx     src_address
            ldy     src_size

            jsr     DMA_VRAM
        ply ; pop index
    .bend

    .block ; setup ppu
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
        lda     #%00000001
        sta     $802101

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
    .bend
    
    #A16
    lda     #$0000
    sta     player_score

    ; setup player data
    #A8
    lda     #116
    sta     player_one.screenpos.x.hi
    lda     #160
    sta     player_one.screenpos.y.hi
    
    #A8
    lda     #0
    sta     next_bullet
    sta     next_item
    sta     next_enemy_bullet
    
    lda     #2
    sta     player_one.speed

    lda     #5
    sta     player_lives

    ; clear all player bullets
    jsr     ClearBullets
    jsr     ClearItems
    jsr     ClearEnemies

    ; load first wave definition
    lda     #0
    sta     current_wave

    ; clear all sprites
    jsr     ShadowOAM_Clear
        

    #A8
    stz     reg_brightness
    lda     #%11111111
    sta     reg_mosaic

    ; init mosaic
    lda     #%00000011
    sta     reg_mosaic
    sta     $802106
    
    #A16
    lda     #<>Ingame_VBlank
    sta     vblank_ptr

    lda     #<>Ingame_FadeIn
    sta     gamestate_ptr

    ; re-enable vblank (with full dark to begin)
    #A8
    ; setup player pos
    

    ; enable NMI and Joypads
    #XY8
    #A8

    lda     $804210

    lda     #%10000001
    sta     $804200

    rts
.bend

Ingame_Loop .block
    ; scroll backgrounds
    jsr     HandleInput

    .block  ; sprite loop
        #A16
        jsr     ShadowOAM_Clear

        #A8
        jsr SetOAMPtr   ; clear sprite shadow table

        ; draw score on top using sprites
        jsr     DrawScore
        
        jsr     DrawLives
        DrawPlayerSprite player_one.screenpos.x.hi, player_one.screenpos.y.hi
        
        ; handle/bullets
        jsr     UpdatePlayerBullets
        
        ; handle items
        jsr     UpdateItems

        ; so some collision checks
        jsr     CheckBulletsVsEnemies
        jsr     CheckBulletsVsPlayer
        jsr     CheckItemsVsPlayer

        ; check enemy wave status
        jsr     CheckCurrentWave    ; puts 0/1 in tmp_0 (0 alive, 1 wave done)
        lda     tmp_0
        beq     _enemy_updates

        ; move to next wave
        #A8
        lda     current_wave
        inc     A
        sta     current_wave
        cmp     #24             ; is this the last wave?
        bne     _next_wave

        #A16
            lda     #5*60
            sta     wtmp_0  ; exit counter
            lda     #<>Ingame_FinishedGame
            sta     gamestate_ptr
        #A8

        jmp     _done

        _next_wave
            lda     #0
            ora     WAVENUMBER_INIT
            sta     wave_init_state
            lda     #60 ; wait sixty frames
            sta     wavenumber_wait

            #A16
            lda     #<>Ingame_StartNextWave
            sta     gamestate_ptr
            #A8

        jmp     _done

        #A8
        _enemy_updates
        ; draw/update current enemy wave objects
        .block ; enemy object update
            
            ldx #(15*ENEMY_STRIDE)            ; start loop again          
            _enemy_loop
                ; preload some vars
                #A8
                lda     #`Pattern_Definitions   ; load pattern bank
                sta     wave_pattern_bank       ; doppelt gemoppelt :D

                #A16
                lda     enemy_objects,X+5       ; load sprite data ptr
                sta     sprite_data_ptr

                #A8
                lda     enemy_objects,X     ; load flags
                bit     ENEMY_EXPLODE
                bne     _exploding

                bit     ENEMY_ALIVE         ; skip if enemy is not alive
                beq     _next_enemy         ; next/prev. enemy

                bit     ENEMY_WAITING       ; if enemy is waiting -> decrement frame counter
                beq     _update_enemy       ; not waiting -> move

                #A16
                clc
                lda     enemy_objects,X+9   ; load wait counter
                dec     A                   ;
                sta     enemy_objects,X+9   ; store decremented counter
                bne     _next_enemy         ; not zero -> next enemy

                #A8
                lda     enemy_objects,X     ; load flags
                and     UNSET_ENEMY_WAITING ; start it next frame
                sta     enemy_objects,X     ; store new flags

                _update_enemy                       ; update enemy according to current set wave pattern
                    #A16
                    lda     enemy_objects,X+7       ; load current pattern offset
                    sta     wave_pattern_ptr
                    #A8
                    jsr     Ingame_MoveEnemy
                    jmp     _draw_enemy

                _exploding
                    #A16
                    lda     #<>Explosion_small
                    sta     sprite_data_ptr
                    #A8
                    lda     enemy_objects,X
                    and     #%00001111
                    beq     _remove_explosion
                    dec     A
                    sta     enemy_objects,X         ; disable after one frame
                    #A16
                    jmp     _draw_enemy

                _remove_explosion
                    lda     #0
                    sta     enemy_objects,X
                    #A16

                _draw_enemy
                    .block ; draw sprite
                        pha
                        phx
                        phy
                            #A8
                            lda     #`Enemy_Sprites    ; load src sprite bank
                            sta     tmp_0
                            #A8
                            #XY8
                            lda     enemy_objects,X+4     ; load y-hi pos to y
                            tay
                            lda     enemy_objects,X+2     ; load x-hi pos to x
                            tax
                            #A16
                            lda     sprite_data_ptr  

                            jsr     CopyMetasprite     
                        ply
                        plx
                        pla
                    .bend

                _next_enemy
                    #A16
                    txa                 ; get current index
                    beq _done           ; if 0 this was the last enemy to check --> done

                    sec
                    sbc #ENEMY_STRIDE              ; substract
                    tax
                    jmp _enemy_loop     ; next enemy
            _done
        .bend

        jsr     UpdateEnemyBullets

        _done
    .bend

    _done
        rts
.bend

Ingame_HandleBeingHit .block

    rts
.bend

HandleInput .block
    #A16    
    _move_left
        lda     pad_1_repeat
        and     #PAD_LEFT
        beq     _move_right

        jsr     MovePlayer_Left

    _move_right
        lda     pad_1_repeat
        and     #PAD_RIGHT
        beq     _move_up

        jsr     MovePlayer_Right

    _move_up
        lda     pad_1_repeat
        and     #PAD_UP
        beq     _move_down

        jsr     MovePlayer_Up

    _move_down
        lda     pad_1_repeat
        and     #PAD_DOWN
        beq     _shoot_snowball

        jsr     MovePlayer_Down

    _shoot_snowball
        lda     pad_1_pressed
        and     #PAD_Y
        beq     _input_done

        jsr     ShootSnowball
        ; play sfx
        #AXY8
        phy
            lda     #2
            ldy     #5
            jsr     Play_SFX
        ply
    
    _input_done
    rts
.bend

MovePlayer_Left .block
    #A16
    dec     reg_scroll_h_bg1
    dec     reg_scroll_h_bg1
    dec     reg_scroll_h_bg1
    dec     reg_scroll_h_bg2
    sec
    lda     player_one.screenpos.x
    sbc     PLAYER_SPEED
    bcs     _done

    lda     #$0000
    _done
    sta     player_one.screenpos.x
    rts
.bend

MovePlayer_Right .block
    #A16
    inc     reg_scroll_h_bg1
    inc     reg_scroll_h_bg1
    inc     reg_scroll_h_bg1
    inc     reg_scroll_h_bg2
    clc
    lda     player_one.screenpos.x
    adc     PLAYER_SPEED
    cmp     #$E800
    bcc     _done
    lda     #$E800

    _done
    sta     player_one.screenpos.x
    rts
.bend

MovePlayer_Up .block
    #A16
    sec
    lda     player_one.screenpos.y
    sbc     PLAYER_SPEED
    bcs     _done

    lda     #$0000
    _done
    sta     player_one.screenpos.y
    rts
.bend

MovePlayer_Down .block
    #A16
    clc
    lda     player_one.screenpos.y
    adc     PLAYER_SPEED
    cmp     #$C800
    bcc     _done
    lda     #$C800
    
    _done
    sta     player_one.screenpos.y
    rts
.bend

ShootSnowball .block
    #A8
    lda     next_bullet
    tax
    
    lda     player_bullets,X
    ora     BULLET_IN_USE
    sta     player_bullets,X
    
    #A16
    lda     player_one.screenpos.x
    clc
    adc     #$0800
    sta     player_bullets,X+1
    
    clc
    lda     player_one.screenpos.y
    sta     player_bullets,X+3

    #A8
    lda     next_bullet
    clc
    adc     #5
    cmp     #(31*5)
    bne     _next_bullet

    lda     #0
    sta     next_bullet
    jmp     _done

    _next_bullet
        sta next_bullet

    _done
    rts
.bend

SpawnItem .block
    #A8
    phx
    phy
        lda     next_item
        tax
        
        lda     collectible_object,X
        ora     BULLET_IN_USE
        sta     collectible_object,X
        
        lda     tmp_0
        sta     collectible_object,X+2
        
        lda     tmp_1
        sta     collectible_object,X+4

        lda     next_item
        clc
        adc     #5
        cmp     #(31*5)
        bne     _next_item

        lda     #0
        sta     next_item
        jmp     _done

        _next_item
            sta next_item

        _done
    ply
    plx
    rts
.bend

SpawnEnemyBullet .block
    #A8
    phx
    phy
        lda     next_enemy_bullet
        tax
        
        lda     enemy_bullets,X
        ora     BULLET_IN_USE
        sta     enemy_bullets,X
        
        lda     tmp_0
        sta     enemy_bullets,X+2
        
        lda     tmp_1
        sta     enemy_bullets,X+4

        lda     next_enemy_bullet
        clc
        adc     #5
        cmp     #(31*5)
        bne     _next_item

        lda     #0
        sta     next_enemy_bullet
        jmp     _done

        _next_item
            sta next_enemy_bullet

        _done
    ply
    plx
    rts
.bend

ClearBullets .block; clear bullets
    .block ; player
        #A8
        lda     #0;
        #XY16
        ldx     #(31*5)
        _loop
            sta player_bullets,x
            dex
            bne _loop
        ; clear last element
        sta player_bullets,X
    .bend
    .block ; enemy
        #AXY8
        lda     #0;
        #XY16
        ldx     #(31*5)
        _loop
            sta enemy_bullets,x
            dex
            bne _loop
        ; clear last element
        sta enemy_bullets,X
    .bend
    #AXY8
    rts
.bend

ClearItems .block
    #A8
    lda     #0;
    #XY16
    ldx     #(31*5)
    _loop
        sta collectible_object,x
        dex
        bne _loop
    ; clear last element
    sta collectible_object,X
    #AXY8
    rts
.bend

ClearEnemies .block; clear enemy objects   
    #A8
    lda     #0
    #XY16
    ldx     #(16*ENEMY_STRIDE)
    _loop
        sta enemy_objects,X
        dex
        bne _loop
    ; clear last element
    sta enemy_objects,X
    #AXY8
    rts
.bend

UpdatePlayerBullets .block ; player bullet update    
    ldx #(31*5)             ; start with last bullet

    _bullet_loop
        #A8
        lda player_bullets,X    ; load bullet flags
        bit BULLET_IN_USE       ; 
        beq _next_bullet      ; next/prev. bullet

        _update_bullet
            #A16
            sec
            lda     player_bullets,X+3     ; load screenpos.y
            sbc     BULLET_SPEED
            sta     player_bullets,X+3     ; store new screenpos.y

        _check_offscreen
            bcs     _move_bullet
        
        _remove_bullet
            #A8
            lda     #0
            sta     player_bullets,X
            jmp     _next_bullet      
        
        _move_bullet              
            #A8
            lda     player_bullets,X+2      ; load x position
            sta     sprite_pos_x

            lda     player_bullets,X+4      ; load y position
            sta     sprite_pos_y
                                
            SetMetasprite   Snowball, sprite_pos_x, sprite_pos_y
            
        _next_bullet
            #A16
            txa                 ; get current index
            beq _done           ; if 0 this was the last bullet to check --> done

            sec
            sbc #5              ; substract
            tax
            jmp _bullet_loop    ; next bullet
    _done
    rts
.bend

UpdateEnemyBullets .block ;   
    ldx #(31*5)             ; start with last bullet

    _item_loop
        #A8
        lda enemy_bullets,X    ; load item flags
        bit BULLET_IN_USE       ; 
        beq _next_item          ; next/prev. item

        _update_item
            #A16
            clc
            lda     enemy_bullets,X+3     ; load screenpos.y
            adc     BULLET_SPEED
            sta     enemy_bullets,X+3     ; store new screenpos.y

        _check_offscreen
            cmp     #$E000
            bcc     _draw_item
        
        _remove_item
            #A8
            lda     #0
            sta     enemy_bullets,X
            jmp     _next_item      
        
        _draw_item              
            #A8
            lda     enemy_bullets,X+2      ; load x position
            sta     sprite_pos_x

            lda     enemy_bullets,X+4      ; load y position
            sta     sprite_pos_y
                                
            SetMetasprite   Snowball_E, sprite_pos_x, sprite_pos_y
            
        _next_item
            #A16
            txa                 ; get current index
            beq _done           ; if 0 this was the last bullet to check --> done

            sec
            sbc #5              ; substract
            tax
            jmp _item_loop    ; next bullet
    _done
    rts
.bend

UpdateItems .block ; collectible item update    
    ldx #(31*5)             ; start with last bullet

    _item_loop
        #A8
        lda collectible_object,X    ; load item flags
        bit BULLET_IN_USE       ; 
        beq _next_item          ; next/prev. item

        _update_item
            #A16
            clc
            lda     collectible_object,X+3     ; load screenpos.y
            adc     ITEM_SPEED
            sta     collectible_object,X+3     ; store new screenpos.y

        _check_offscreen
            cmp     #$E000
            bcc     _draw_item
        
        _remove_item
            #A8
            lda     #0
            sta     collectible_object,X
            jmp     _next_item      
        
        _draw_item              
            #A8
            lda     collectible_object,X+2      ; load x position
            sta     sprite_pos_x

            lda     collectible_object,X+4      ; load y position
            sta     sprite_pos_y
                                
            SetMetasprite   floppy, sprite_pos_x, sprite_pos_y
            
        _next_item
            #A16
            txa                 ; get current index
            beq _done           ; if 0 this was the last bullet to check --> done

            sec
            sbc #5              ; substract
            tax
            jmp _item_loop    ; next bullet
    _done
    rts
.bend

CheckCurrentWave .block
    #A8
    ; simple check if all enemies are dones (killed or end of wave animation)
    stz     tmp_0
    ldx #(15*ENEMY_STRIDE)             ; start with last enemy
    _enemy_check_loop
        lda     enemy_objects,X     ; load enemy flags
        bne     _done               ; if not zero -> someone is still alive -> early out

        ; next enemy.
        txa                         ; get current index
        beq     _all_dead_or_gone   ; if 0 this was the last enemy to check --> all gone

        sec
        sbc     #ENEMY_STRIDE       ; substract
        tax
        jmp     _enemy_check_loop   ; next enemy
            
    _all_dead_or_gone
        lda     #1
        sta     tmp_0

    _done
    rts
.bend

CheckBulletsVsEnemies .block
    ; loop all active bullets
    ; check against all active enemies
    ; remove both if hit
    ldx #(31*5)             ; start with last bullet

    _bullet_loop
        #A8
        lda     player_bullets,X    ; load bullet flags
        sta     tmp_2               ; keep flag
        bit     BULLET_IN_USE       ; 
        beq     _next_bullet      ; next/prev. bullet

        ; load bullet screen position (take "middle pixel" only)
        #A8
        clc
        lda     player_bullets,X+2      ; x position
        adc     #4                      ; add 4 pixels
        sta     tmp_0                   ;

        clc
        lda     player_bullets,X+4      ; y position (hi-byte only)
        adc     #4                      ; add 4 pixels
        sta     tmp_1                   ;

        .block  ; loop all active enemies
        phx 
            ldx #(15*ENEMY_STRIDE)            ; start loop again          
            _enemy_loop
                lda     enemy_objects,X     ; load flags
                bit     ENEMY_ALIVE         ; skip if enemy is not alive
                beq     _next_enemy         ; next/prev. enemy 

                ; load enemy position
                clc
                lda     enemy_objects,X+2     ; load x-hi position
                adc     enemy_objects,X+12    ; add hbox x offset
                cmp     tmp_0
                bcs     _next_enemy           ; if (tmp_0<left_sprite_border)
                clc
                adc     enemy_objects,X+13    ; move check to right border (add hbox width)
                cmp     tmp_0                  
                bcc     _next_enemy           ; if (tmp_0>right_sprite_border)

                lda     enemy_objects,X+4     ; load y-hi position
                cmp     tmp_1
                bcs     _next_enemy           ; if (tmp_0<left_sprite_border)
                clc
                adc     enemy_objects,X+14    ; move check to lower hbox (add height)
                cmp     tmp_1                  
                bcc     _next_enemy           ; if (tmp_0>right_sprite_border)

                ; enemy has been hit -> dec hitpoints and remove if required
                ; play sfx
                #AXY8
                lda     #0
                sta     tmp_2                   ; remove bullet
                lda     enemy_objects,X+11      ; load current hitpoints
                dec     A
                sta     enemy_objects,X+11
                bne     _next_enemy

                _remove_enemy
                    jsr     RemoveEnemy
                    jmp     _done                 ; remove only one enemy at a time

                _next_enemy
                    txa                 ; get current index
                    beq _done           ; if 0 this was the last enemy to check --> done

                    sec
                    sbc #ENEMY_STRIDE              ; substract
                    tax
                    jmp _enemy_loop     ; next enemy
            _done            
        plx
        .bend

        ; set bullet state
        lda     tmp_2               ;
        sta     player_bullets,X    ; removes bullet if tmp_2==0

        _next_bullet
            txa                 ; get current index
            beq _done           ; if 0 this was the last bullet to check --> done

            sec
            sbc #5              ; substract
            tax
            jmp _bullet_loop    ; next bullet
    _done
    rts
.bend

RemoveEnemy .block
    phy
        lda     #1
        ldy     #6
        jsr     Play_SFX
    ply

    lda     ENEMY_EXPLODE
    sta     enemy_objects,X
    ; spawn new item at enemy position
    lda     enemy_objects,X+2     ; x position
    sta     tmp_0
    lda     enemy_objects,X+4     ; y position
    sta     tmp_1
    jsr     SpawnItem             ; spawn item at pos
    jsr     Add_KillPoints        ; add points to score
    rts
.bend

DrawScore .block
    #A8
    lda     #5
    sta     sprite_pos_x
    sta     sprite_pos_y

    SetMetasprite score, sprite_pos_x, sprite_pos_y

    ; 21 29 37 45
    phx
    phy
        .block
            #A16
            lda     player_score
            sta     wtmp_1
            and     #$000F
            #A8
            asl     A
            tax
            #A16
            lda     Digits,X            ; load sprite digit ptr.
            sta     sprite_data_ptr

            lda     #`Digits    ; load src sprite bank
            sta     tmp_0
            #A8
            #XY8
            lda     sprite_pos_y     ; load y-hi pos to y
            tay
            lda     #49     ; load x-hi pos to x
            tax
            #A16
            lda     sprite_data_ptr  

            jsr     CopyMetasprite
        .bend
        .block
            #A16
            lda     wtmp_1
            lsr
            lsr
            lsr
            lsr
            clc
            sta     wtmp_1
            and     #$000F
            #A8
            asl     A
            tax
            #A16
            lda     Digits,X            ; load sprite digit ptr.
            sta     sprite_data_ptr

            lda     #`Digits    ; load src sprite bank
            sta     tmp_0
            #A8
            #XY8
            lda     sprite_pos_y     ; load y-hi pos to y
            tay
            lda     #40     ; load x-hi pos to x
            tax
            #A16
            lda     sprite_data_ptr  

            jsr     CopyMetasprite
        .bend
        .block
            #A16
            lda     wtmp_1
            lsr
            lsr
            lsr
            lsr
            clc
            sta     wtmp_1
            and     #$000F
            #A8
            asl     A
            tax
            #A16
            lda     Digits,X            ; load sprite digit ptr.
            sta     sprite_data_ptr

            lda     #`Digits    ; load src sprite bank
            sta     tmp_0
            #A8
            #XY8
            lda     sprite_pos_y     ; load y-hi pos to y
            tay
            lda     #31     ; load x-hi pos to x
            tax
            #A16
            lda     sprite_data_ptr  

            jsr     CopyMetasprite
        .bend
        .block
            #A16
            lda     wtmp_1
            lsr
            lsr
            lsr
            lsr
            clc
            sta     wtmp_1
            and     #$000F
            #A8
            asl     A
            tax
            #A16
            lda     Digits,X            ; load sprite digit ptr.
            sta     sprite_data_ptr

            lda     #`Digits    ; load src sprite bank
            sta     tmp_0
            #A8
            #XY8
            lda     sprite_pos_y     ; load y-hi pos to y
            tay
            lda     #22     ; load x-hi pos to x
            tax
            #A16
            lda     sprite_data_ptr  

            jsr     CopyMetasprite
        .bend
        #A8
    ply
    plx

    rts
.bend

DrawLives .block
    phx
    phy
        #A8
        lda     #235
        sta     sprite_pos_x
        lda     #5
        sta     sprite_pos_y

        lda     player_lives
        tax
        
        _loop_lives
            SetMetasprite sled_symbol, sprite_pos_x, sprite_pos_y
            lda     sprite_pos_x
            sec
            sbc     #16
            sta     sprite_pos_x

            dex
            bne     _loop_lives
    ply
    plx
    #A16
    rts
.bend

CheckItemsVsPlayer .block
    ; loop all active items
    ; check against player
    ; remove item if it, add to score
    ldx #(31*5)             ; start with last item

    _item_loop
        #A8
        lda     collectible_object,X    ; load bullet flags
        bit     BULLET_IN_USE    ; 
        beq     _next_item       ; next/prev. item

        ; load item screen position (take "middle pixel" only)
        #A8
        clc
        lda     collectible_object,X+2  ; x position
        adc     #4                      ; add 4 pixels
        sta     tmp_0                   ;

        clc
        lda     collectible_object,X+4  ; y position (hi-byte only)
        adc     #4                      ; add 4 pixels
        sta     tmp_1                   ;

        .block  ; check against player character
            ; load player position
            clc
            lda     player_one.screenpos.x.hi    ; load x-hi position (screen position)
            cmp     tmp_0
            bcs     _done           ; if (tmp_0<left_sprite_border)
            
            clc
            adc     #24                   ; move check to right border (add hbox width)
            cmp     tmp_0                  
            bcc     _done           ; if (tmp_0>right_sprite_border)

            lda     player_one.screenpos.y.hi ; load y-hi position
            cmp     tmp_1
            bcs     _done           ; if (tmp_0<left_sprite_border)
            
            clc
            adc     #32    ; move check to lower hbox (add height)
            cmp     tmp_1                  
            bcc     _done           ; if (tmp_0>right_sprite_border)

            ; collect item
            lda     #0
            sta     collectible_object,X    ; remove it
            phy
                lda     #0
                ldy     #7
                jsr     Play_SFX
            ply
            jsr     Add_DiscPoints              ; scoring

            _done            
        .bend

        _next_item
            txa                 ; get current index
            beq _done           ; if 0 this was the last item to check --> done

            sec
            sbc #5              ; substract
            tax
            jmp _item_loop    ; next bullet
    _done
    rts
.bend

CheckBulletsVsPlayer .block
    ; loop all active items
    ; check against player
    ; remove item if it, add to score
    ldx #(31*5)             ; start with last item

    _bullet_loop
        #A8
        lda     enemy_bullets,X    ; load bullet flags
        bit     BULLET_IN_USE      ; 
        beq     _next_bullet       ; next/prev. item

        ; load item screen position (take "middle pixel" only)
        #A8
        clc
        lda     enemy_bullets,X+2       ; x position
        adc     #4                      ; add 4 pixels
        sta     tmp_0                   ;

        clc
        lda     enemy_bullets,X+4  ; y position (hi-byte only)
        adc     #4                      ; add 4 pixels
        sta     tmp_1                   ;

        .block  ; check against player character
            ; load player position
            clc
            lda     player_one.screenpos.x.hi    ; load x-hi position (screen position)
            cmp     tmp_0
            bcs     _done           ; if (tmp_0<left_sprite_border)
            
            clc
            adc     #24                   ; move check to right border (add hbox width)
            cmp     tmp_0                  
            bcc     _done           ; if (tmp_0>right_sprite_border)

            lda     player_one.screenpos.y.hi ; load y-hi position
            cmp     tmp_1
            bcs     _done           ; if (tmp_0<left_sprite_border)
            
            clc
            adc     #32    ; move check to lower hbox (add height)
            cmp     tmp_1                  
            bcc     _done           ; if (tmp_0>right_sprite_border)

            ; player hit by bullet
            lda     #0
            sta     enemy_bullets,X    ; remove it
            phy
                lda     #1
                ldy     #6
                jsr     Play_SFX
            ply

            ; set player sprite to explosion
            #A16
            lda     #<>Explosion_big
            sta     playersprite_addr
            
            #A8
            lda     #`Enemy_Sprites
            sta     playersprite_bank

            lda     player_lives
            clc
            dec     A
            sta     player_lives

            bne     _start_over

            ; --> lost game
            #A16
            lda     #120
            sta     wtmp_1
            lda     #<>Ingame_LostGame
            sta     gamestate_ptr
            jmp     _done

            _start_over
                #A16
                lda     #40
                sta     wtmp_2
                lda     #<>Ingame_RestartWave
                sta     gamestate_ptr

            _done            
                #A8
        .bend

        _next_bullet
            txa                 ; get current index
            beq _done           ; if 0 this was the last item to check --> done

            sec
            sbc #5              ; substract
            tax
            jmp _bullet_loop    ; next bullet
    _done
    rts
.bend

Ingame_FadeIn .block
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
        lda     #<>Ingame_MovePlayerToStartingPosition
        sta     gamestate_ptr
        ; set player pos and move him onscreen
        lda     #223
        sta     player_one.screenpos.y.hi
    _done
    rts
.bend

Ingame_FadeOut .block
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
        lda     #<>Endscreen_OnEnter
        sta     gamestate_ptr

    _done
    rts
.bend

Ingame_MovePlayerToStartingPosition .block
    #A16
    lda     selected_player
    sta     playersprite_addr
    #A8
    lda     #`PlayerSF
    sta     playersprite_bank

    jsr     ShadowOAM_Clear

    #A8
    clc
    lda     player_one.screenpos.y.hi
    dec     A
    sta     player_one.screenpos.y.hi
    cmp     #160
    bne     _done

    lda     #0
    ora     WAVENUMBER_INIT
    sta     wave_init_state

    jsr     ClearItems
    #A16
    lda     #<>Ingame_StartNextWave
    sta     gamestate_ptr

    _done
        #A8
        jsr     SetOAMPtr           ; start at beginning
        ; draw score
        jsr     DrawScore
        jsr     DrawLives
        ; draw player sprite
        DrawPlayerSprite player_one.screenpos.x.hi, player_one.screenpos.y.hi
    rts
.bend

Ingame_StartNextWave .block
    jsr     HandleInput

    #A8
    lda     wave_init_state
    bit     WAVENUMBER_INIT
    bne     _init
    
    bit     WAVENUMBER_IN
    bne     _scroll_in

    bit     WAVENUMBER_HOLD
    bne     _hold

    bit     WAVENUMBER_OUT
    bne     _scroll_out

    bit     WAVENUMBER_EXIT
    bne     _exit

    jmp     _done

    _init
        jsr     WavenumberInit
        jmp     _done

    _scroll_in
        jsr     WavenumberScrollIn
        jmp     _done

    _hold
        jsr     WavenumberHold
        jmp     _done

    _scroll_out
        jsr     WavenumberScrollOut
        jmp     _done

    _exit
        #A16
        lda     #<>Ingame_Loop
        sta     gamestate_ptr
        
        #A8
        lda     current_wave
        jsr     Ingame_LoadWave    

        
    _done
        #A16
        jsr     ShadowOAM_Clear         ; clear all sprites

        #A8
        jsr     SetOAMPtr           ; start at beginning
        ; draw score
        jsr     DrawScore
        jsr     DrawLives

        ; draw wave sprite number
        _draw_wave_number .block ; draw sprite
            #A8
            lda     #`Wavesprites    ; load src sprite bank
            sta     tmp_0
            #AXY16
            lda     wavenumber_pos_x          ; load x pos to x
            tax
            lda     wavenumber_pos_y          ; load y pos to y
            tay
            lda     wtmp_0
        
            jsr     CopyMetasprite
        .bend

        ; draw player sprite
        DrawPlayerSprite player_one.screenpos.x.hi, player_one.screenpos.y.hi
        
        ; handle/bullets
        jsr     UpdatePlayerBullets
        ; handle items
        jsr     UpdateItems
        jsr     CheckItemsVsPlayer

    rts
.bend

Ingame_RestartWave .block
    #A16
    jsr     ShadowOAM_Clear         ; clear all sprites
    #A8
    jsr     SetOAMPtr           ; start at beginning

    jsr     DrawScore
    jsr     DrawLives

    DrawPlayerSprite player_one.screenpos.x.hi, player_one.screenpos.y.hi
    
    brk
    nop
    nop
    #A16
    lda     wtmp_2
    sec
    sbc     #1
    sta     wtmp_2
    bpl     _done

    #A8
    lda     #116
    sta     player_one.screenpos.x.hi
    lda     #223
    sta     player_one.screenpos.y.hi

    #A16
    lda     #<>Ingame_MovePlayerToStartingPosition ; Start wave over...
    sta     gamestate_ptr
    
    _done
    #A8
    rts
.bend

Ingame_FinishedGame .block
    jsr     HandleInput

    #A16
    jsr     ShadowOAM_Clear         ; clear all sprites

    #A8
    jsr     SetOAMPtr           ; start at beginning
    
    ; draw player sprite
    DrawPlayerSprite player_one.screenpos.x.hi, player_one.screenpos.y.hi
    
    ; handle/bullets
    jsr     UpdatePlayerBullets
    ; handle items
    jsr     UpdateItems
    jsr     CheckItemsVsPlayer

    #A16
    dec     wtmp_0
    bpl     _done

    ; fade out and switch to exit screen
    lda     #<>Ingame_FadeOut
    sta     gamestate_ptr

    _done
    rts
.bend

Ingame_LostGame .block
    #A16
    jsr     ShadowOAM_Clear         ; clear all sprites

    #A8
    jsr     SetOAMPtr           ; start at beginning
    
    ; handle items
    jsr     UpdateItems
    
    #A16
    lda     wtmp_1
    sec
    sbc     #1
    sta     wtmp_1
    bpl     _done

    ; fade out and switch to exit screen
    lda     #<>Gameover_OnEnter
    sta     gamestate_ptr

    _done
    rts
.bend

WavenumberInit .block
    #A8
    jsr     ClearEnemies
    jsr     ClearBullets
    
    ; load wave number sprite
    lda     current_wave
    clc
    asl     A
    tax
    #A16
    lda     Wavenumbers,X
    sta     wtmp_0

    ;set initial position
    #A8
    lda     #13*8
    sta     wavenumber_pos_x
    lda     #224
    sta     wavenumber_pos_y

    #A8
    lda     #0
    ora     WAVENUMBER_IN
    sta     wave_init_state

    rts
.bend

WavenumberScrollIn .block
    #A8
    lda     wavenumber_wait
    sec
    dec     A
    bmi     _move

    sta     wavenumber_wait
    jmp     _done

    _move
        lda     wavenumber_pos_y
        clc
        adc     #2
        cmp     #100
        beq     _next
        
        sta     wavenumber_pos_y
        jmp     _done

    _next
        lda     #90                 ; wait 90 frames
        sta     wavenumber_wait     ;
        lda     #0
        ora     WAVENUMBER_HOLD
        sta     wave_init_state

    _done
    rts
.bend

WavenumberHold .block
    #A8
    lda     wavenumber_wait
    dec     A
    bmi     _next

    sta     wavenumber_wait
    jmp     _done

    _next
        lda     #0
        ora     WAVENUMBER_OUT
        sta     wave_init_state

    _done
    rts
.bend

WavenumberScrollOut .block
    #A8
    lda     wavenumber_pos_y
    clc
    adc     #2
    cmp     #224
    beq     _next
    
    sta     wavenumber_pos_y
    jmp     _done

    _next
        lda     #0
        ora     WAVENUMBER_EXIT
        sta     wave_init_state
        
    _done
    rts
.bend

Ingame_LoadWave .block ; load new wave at start of enemy list; wave idx needs to be in A (8 bit)
    #A8
    pha
        lda     Wavetable   ; load wavetable bank
        sta     data_bnk
    pla
    ; calc index (A*2+1)
    clc
    asl A
    inc A
    tax     ; store index
    
    ; now we can read the proper wave definition index
    #A16
    lda     Wavetable,X
    sta     data_ptr
    
    ; data_ptr/bank now points to the proper wave definition
    ; load number of enemies (used as a loop counter)
    #A8XY16
    lda     [data_ptr]      ; number of enemies in this wave def.
    sta     tmp_0           ; store index for enemies in wave
    
    ldx     #0              ; x index for writing enemy table
    ldy     #1              ; init index to 1 (after the enemy count value)

    _enemy_loop
        #AXY8
        ; set enemy alive
        lda     enemy_objects, X
        ora     ENEMY_INIT
        sta     enemy_objects, X
        
        .block ; load enemy type
            lda     [data_ptr], Y   ; get enemy index from wave def
            iny     ; next
            phx
                #A8
                asl     A
                inc     A
                tax

                #A16
                lda     EnemyTable,X
                sta     data_ptr_0
            plx
            sta     enemy_objects,X+5
        .bend

        .block ; load enemy starting position
            #A8
            lda     [data_ptr], Y
            sta     enemy_objects,X+2
            iny     ; next

            lda     [data_ptr], Y
            sta     enemy_objects,X+4
            iny     ; next
        .bend

        .block ; load pattern index (8-bit) and starting offset
            lda     [data_ptr], Y   ; get pattern index from wave def
            iny     ; next
            phx
                #A8
                asl     A
                inc     A
                tax

                #A16
                lda     PatternTable,X
            plx
            sta     enemy_objects,X+7
            
            ; frame offset until start of wave "playback"
            lda     [data_ptr], y
            sta     enemy_objects,X+9
            iny     ; advance two bytes
            iny     ;
        .bend

        .block    ; load hitpoints
            #A8
            lda     [data_ptr],y
            sta     enemy_objects,X+11
            iny
        .bend

        .block  ; load hitbox offset and size
            lda     [data_ptr],Y        ; hbox offset x (max 16)
            sta     enemy_objects,X+12
            iny
            
            lda     [data_ptr],Y    ; hbox width
            sta     enemy_objects,X+13
            iny
            
            lda     [data_ptr],Y    ; hbox height
            sta     enemy_objects,X+14
            iny
        .bend

        ; advance to next enemy
        clc
        txa
        adc     #ENEMY_STRIDE ; enemy byte stride
        tax
        
        #A8
        clc
        lda     tmp_0
        dec     A
        sta     tmp_0
        bne     _enemy_loop
    
    #A8
    ; set wave alive
    lda     #0
    ora     WAVE_ALIVE
    sta     wave_state
    rts
.bend

Ingame_MoveEnemy .block
    #A16
    lda     [wave_pattern_ptr]       ; load x movement
    cmp     #$aaaa
    bcs     _remove_enemy
    sta     wtmp_0                   ; store

    inc     wave_pattern_ptr
    inc     wave_pattern_ptr
    lda     [wave_pattern_ptr]       ; load y movement
    cmp     #$aaaa
    bcs     _remove_enemy
    sta     wtmp_1
    jmp     _move_enemy

    _remove_enemy
        #A8
        lda     #0
        sta     enemy_objects,X
        #A16
        jmp     _done
    
    ; move enemy (something clumsy but.. meh)
    _move_enemy
        #A16
        .block ; move x
            lda     wtmp_0
            bit     #$8000    ; highest bit set -> negative
            bne     _minus
            
            _plus
            clc
            lda     enemy_objects,X+1
            adc     wtmp_0
            jmp     _store

            _minus
            lda     wtmp_0
            and     #$7FFF  ; get rid of the negative flag
            sta     wtmp_0
            lda     enemy_objects,X+1
            sec
            sbc     wtmp_0

            _store
            sta     enemy_objects,X+1
        .bend

        .block ; move y
            lda     wtmp_1
            bit     #$8000    ; highest bit set -> negative
            bne     _minus
            
            _plus
            clc
            lda     enemy_objects,X+3
            adc     wtmp_1
            jmp     _store

            _minus
            lda     wtmp_1
            and     #$7FFF  ; get rid of the negative flag
            sta     wtmp_1
            lda     enemy_objects,X+3
            sec
            sbc     wtmp_1

            _store
            sta     enemy_objects,X+3
        .bend
        
        ; check if we should fire a bullet
        #A8
        lda     enemy_objects,X
        bit     ENEMY_SHOOT
        beq     _next           ; not allowed to shoot

        lda     player_one.screenpos.x.hi
        cmp     enemy_objects,X+2
        bne     _next

        lda     enemy_objects,X
        and     ENEMY_REMOVE_SHOT
        sta     enemy_objects,X

        lda     enemy_objects,X+2
        clc
        adc     #4
        sta     tmp_0
        lda     enemy_objects,X+4
        sta     tmp_1
        jsr     SpawnEnemyBullet
        jmp     _next
    

    _next
        ; increment pattern offset pointer by four bytes
        #A16
        lda     wave_pattern_ptr        ; load offset
        clc
        adc     #2                      ; add four bytes (2 * 8.8)
        sta     enemy_objects,X+7       ; store new value

    _done
    rts
.bend

Play_SFX .block ; A sfx index
    phx
        ldx     #127
        jsl     SFX_Play_Center
    plx
    rts
.bend

Add_DiscPoints .block ; increment score
    php
    #A16
    sed     ; switch to decimal mode
    clc
    lda     player_score
    adc     #10      ; add one disk
    sta     player_score
    cld     ; back to binary
    #A8
    plp
    rts
.bend

Add_KillPoints .block ; increment score
    php
    #A16
    sed     ; switch to decimal mode
    clc
    lda     player_score
    adc     #1      ; add one kill
    sta     player_score
    cld     ; back to binary
    #A8
    plp
    rts
.bend

Ingame_VBlank .block
    phb
        _scrolling

        .block ; scroll bg/fg
            #A16
            lda     current_frame
            and     #1
            bne     _skip


            lda     reg_scroll_v_bg2
            dec     A
            and     #%0000000111111111
            sta     reg_scroll_v_bg2

            clc
            lda     reg_scroll_v_bg1
            sbc     #6
            and     #%0000000111111111
            sta     reg_scroll_v_bg1
            
            _skip
            #A8
        .bend
        
        _sprites
        #AXY8
            jsr     DMA_OAM

        _input
            jsr     PAD_READ
    plb
    rts
.bend


