







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

    ; play music
    #AXY16
    lda #<>music_1
	ldx #`music_1
	jsl SPC_Play_Song
    #A8

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
    ; reset scrolling registers

    ; setup player data
    #A16
    lda     #116
    sta     player_one.screenpos.x
    lda     #160
    sta     player_one.screenpos.y
    
    #A8
    lda     #0
    sta     next_bullet

    lda     #2
    sta     player_one.speed

    ; clear all player bullets
    .block; clear bullets
        #A8
        lda     #0;
        #XY16
        ldx     #(16*5)
        _loop
            sta player_bullets,x
            dex
            bne _loop
        ; clear last element
        sta player_bullets,X
    .bend

    .block; clear enemy objects
        #A8
        lda     #0
        #XY16
        ldx     #(16*13)
        _loop
            sta enemy_objects,X
            dex
            bne _loop
        ; clear last element
        sta enemy_objects,X
    .bend

    ; load first wave definition
    stz     current_wave

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

Ingame_Loop
    ; scroll backgrounds
    .block  ; handle input
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
        
        _input_done
    .bend

    .block  ; sprite loop
        #A16
        jsr     ShadowOAM_Clear

        ; collision detection

        ; scoring

        #A8
        jsr SetOAMPtr   ; clear sprite shadow table
        ; draw player sprite
        SetMetasprite PlayerNW, player_one.screenpos.x, player_one.screenpos.y
        
        ; handle/bullets
        jsr     UpdatePlayerBullets
        
        ; check enemy wave status
        jsr     CheckCurrentWave

        #A8
        ; draw/update current enemy wave objects
        .block ; enemy object update
            
            ldx #(15*13)            ; start loop again          
            _enemy_loop
                ; preload some vars
                #A8
                lda     #`Pattern_Definitions   ; load pattern bank
                sta     data_bnk                ; store pattern bank

                #A16
                lda     enemy_objects,X+7       ; load pattern address
                sta     data_ptr                ; store

                lda     enemy_objects,X+9       ; load current pattern offset
                tay

                lda     enemy_objects,X+1       ; load x position
                sta     sprite_pos_x

                lda     enemy_objects,X+3       ; load y position
                sta     sprite_pos_y

                lda     enemy_objects,X+5       ; load sprite data ptr
                sta     sprite_data_ptr

                #A8
                lda     enemy_objects,X     ; load flags
                bit     ENEMY_ALIVE         ; skip if enemy is not alive
                beq     _next_enemy         ; next/prev. enemy 

                bit     ENEMY_WAITING       ; if enemy is waiting -> decrement frame counter
                beq     _update_enemy       ; not waiting -> move

                #A16
                clc
                lda     enemy_objects,X+11  ; load wait counter
                dec     A                   ;
                sta     enemy_objects,X+11  ; store decremented counter
                bne     _next_enemy         ; not zero -> next enemy

                #A8
                lda     enemy_objects,X     ; load flags
                and     UNSET_ENEMY_WAITING ; start it next frame
                sta     enemy_objects,X     ; store new flags

                _update_enemy               ; update enemy according to current set wave pattern
                    jsr     Ingame_MoveEnemy

                _draw_enemy
                    .block ; draw sprite
                        pha
                        phx
                        phy
                            #A8
                            lda     #`Enemy_Sprites    ; load src sprite bank
                            sta     tmp_0
                            #A16
                            lda     sprite_pos_x          ; load x pos to x
                            tax
                            lda     sprite_pos_y          ; load y pos to y
                            tay
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
                    sbc #13              ; substract
                    tax
                    jmp _enemy_loop     ; next enemy
            _done
        .bend
    .bend

    _done
        rts

MovePlayer_Left
    #A16
    clc
    lda     player_one.screenpos.x
    dec     A
    dec     A
    bmi     _done
    sta     player_one.screenpos.x

    _done
    rts

MovePlayer_Right
    #A16
    clc
    lda     player_one.screenpos.x
    inc     A
    inc     A
    cmp     #234
    beq     _done
    sta     player_one.screenpos.x
    _done
    rts

MovePlayer_Up
    #A16
    clc
    lda     player_one.screenpos.y
    dec     A
    dec     A
    bmi     _done
    sta     player_one.screenpos.y
    _done
    rts

MovePlayer_Down
    #A16
    clc
    lda     player_one.screenpos.y
    inc     A
    inc     A
    cmp     #200
    beq     _done
    sta     player_one.screenpos.y
    _done
    rts


ShootSnowball
    .block
        #A8
        lda     next_bullet
        tax
        
        lda     player_bullets,X
        ora     BULLET_IN_USE
        sta     player_bullets,X
        
        #A16
        lda     player_one.screenpos.x
        clc
        adc     #8
        sta     player_bullets,X+1
        
        clc
        lda     player_one.screenpos.y
        sta     player_bullets,X+3

        #A8
        lda     next_bullet
        clc
        adc     #5
        cmp     #(16*5)
        bne     _next_bullet

        lda     #0
        sta     next_bullet
        jmp     _done

        _next_bullet
            sta next_bullet

        _done
    .bend
    rts

UpdatePlayerBullets
    .block ; player bullet update
            
        ldx #(15*5)             ; start with last bullet

        _bullet_loop
            #A8
            lda player_bullets,X    ; load bullet flags
            bit BULLET_IN_USE       ; 
            beq _next_bullet      ; next/prev. bullet

            _update_bullet
                #A16
                clc
                lda     player_bullets,X+3     ; load screenpos.y
                sbc     BULLET_SPEED
                sta     player_bullets,X+3     ; store new screenpos.y

            _check_offscreen
                bpl     _move_bullet
            
            _remove_bullet
                #A8
                lda     #0
                sta     player_bullets,X
                jmp     _next_bullet      
            
            _move_bullet              
                #A16
                lda     player_bullets,X+1      ; load x position
                sta     sprite_pos_x

                lda     player_bullets,X+3      ; load y position
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
    .bend
    rts

CheckCurrentWave
    #A8
    .block ; ; simple check if all enemies are dones (killed or end of wave animation)
        ldx #(15*13)             ; start with last enemy
        _enemy_check_loop

            lda     enemy_objects,X     ; load enemy flags
                
            ; next enemy.
            #A16
            txa                 ; get current index
            beq     _done           ; if 0 this was the last enemy to check --> done

            sec
            sbc     #13              ; substract
            tax
            jmp     _enemy_check_loop     ; next enemy
                
        _all_dead_or_gone
            ; all gone

        _done
    .bend
    rts

Ingame_FadeIn
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
            lda     #<>Ingame_MovePlayerToStartingPosition
            sta     gamestate_ptr
            ; set player pos and move him onscreen
            lda     #223
            sta     player_one.screenpos.y
        _done
    .bend
    rts

Ingame_FadeOut
    rts

Ingame_MovePlayerToStartingPosition
    .block
        #A16
        jsr     ShadowOAM_Clear

        clc
        lda     player_one.screenpos.y
        dec     A
        sta     player_one.screenpos.y
        cmp     #160
        bne     _done

        lda     #<>Ingame_StartNextWave
        sta     gamestate_ptr

        #A8
        lda     #0
        ora     WAVENUMBER_INIT
        sta     wave_init_state
        
        _done
            #A8
            jsr     SetOAMPtr   ; clear sprite shadow table
            ; draw player sprite
            SetMetasprite PlayerNW, player_one.screenpos.x, player_one.screenpos.y
    .bend
    rts

Ingame_StartNextWave
    .block
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
            SetMetasprite   PlayerNW, player_one.screenpos.x, player_one.screenpos.y
            
    .bend
    rts

WavenumberInit
    ; load wave number sprite
    #A8
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

WavenumberScrollIn
    #A8
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

WavenumberHold
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

WavenumberScrollOut
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

Ingame_LoadWave ; load new wave at start of enemy list; wave idx needs to be in A (8 bit)
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
        ora     ENEMY_WAITING
        ora     ENEMY_ALIVE
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
            sta     enemy_objects,X+1
            iny     ; next

            lda     [data_ptr], Y
            sta     enemy_objects,X+3
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
                sta     data_ptr_0
            plx
            sta     enemy_objects,X+7
            ; set pattern index to 0
            lda     #$0000
            sta     enemy_objects,X+9

            ; frame offset until start of wave "playback"
            #A16
            lda     [data_ptr], y
            sta     enemy_objects,X+11
            iny     ; advance two bytes
            iny     ;
        .bend

        ; advance to next enemy
        clc
        txa
        adc     #13 ; enemy byte stride
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


Ingame_MoveEnemy
    #A8
    lda     [data_ptr],Y            ; load x movement
    sta     tmp_0                   ; store
    iny
    lda     [data_ptr],Y            ; load y movement
    sta     tmp_1
    
    #A16
    clc
    lda     tmp_0                   ; end movement if DEDE is set
    cmp     #$aaaa
    beq     _remove_enemy           ; remove if DEDE
    
    ; move enemy
    _move_enemy
        #A8
        clc
        lda     enemy_objects,X+1     
        adc     tmp_0
        sta     enemy_objects,X+1
        clc
        lda     enemy_objects,X+3     
        adc     tmp_1
        sta     enemy_objects,X+3
        jmp     _next

    _remove_enemy
        #A8
        lda     #0
        sta     enemy_objects,X
        #A16
        jmp     _done

    _next
        ; increment pattern offset pointer by two bytes
        #A16
        lda     enemy_objects,X+9       ; load offset
        clc
        adc     #2                      ; add two bytes (one for earch x/y)
        sta     enemy_objects,X+9       ; store new value

    _done
    rts

Ingame_VBlank
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
            sbc     #3
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


