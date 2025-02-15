;music code for snesgss
;written by Shiru
;modified to work with ca65 by Doug Fraker 2020-2021
;modified to work on 64tass by Oziphantom 2023
;streaming audio has been removed and
;the spc code has been patched to fix a bug - and add echo
;now called snesgssQ.exe -

;version 5
;update 11/2021
;added SPC_All_Echo to set all echo parameters
;using a single table of values


LOROM = 1
;set to zero, if HIROM

;notes
;cmdStereo, param 8 bit, 0 or 1
;cmdGlobalVolume, param L = vol 0-127, H = how quickly volume fades, 1-255
;cmdChannelVolume, param L = vol 0-127, H = which channel (bit field)*
;cmdMusicPlay, no param
;cmdStopAllSounds, no param
;cmdMusicStop, no param
;cmdMusicPause, param 8 bit, 0 or 1
;cmdSfxPlay, 4 params, vol 0-127, sfx #, pan, channel 0-7
;cmdLoad, params= apu address, size, src address
;stream, removed.

;*bitfield for channel volume, if channel volume command will set
; a max volume for a specific channel
;0000 0001 channel 1
;0000 0010 channel 2
;0000 0100 channel 3
;0000 1000 channel 4
;0001 0000 channel 5
;0010 0000 channel 6
;0100 0000 channel 7
;1000 0000 channel 8


kFULL_VOL	=  127
kPAN_CENTER = 128
kPAN_LEFT	= 0
kPAN_RIGHT	= 255


kAPU0		= $2140
kAPU1		= $2141
kAPU01	= $2140
kAPU2		= $2142
kAPU3		= $2143
kAPU23	= $2142

;to send a command
;although 8 bit values, A should be 16 bit when you
;lda #SCMD_INITIALIZE
kSCMD_NONE					= $00
kSCMD_INITIALIZE			= $01
kSCMD_LOAD					= $02
kSCMD_STEREO				= $03
kSCMD_GLOBAL_VOLUME		= $04
kSCMD_CHANNEL_VOLUME		= $05
kSCMD_MUSIC_PLAY 			= $06
kSCMD_MUSIC_STOP 			= $07
kSCMD_MUSIC_PAUSE 		= $08
kSCMD_SFX_PLAY				= $09
kSCMD_STOP_ALL_SOUNDS	= $0a
kSCMD_STREAM_START		= $0b
kSCMD_STREAM_STOP			= $0c
kSCMD_STREAM_SEND			= $0d
kSCMD_ECHO_VOL				= $0b
kSCMD_ECHO_ADDR			= $0c
kSCMD_ECHO_FB_FIR			= $0d



.section secDP
spc_temp					.word ?
gss_param				.word ?
gss_command				.word ?
save_stack				.word ?
spc_pointer				.dword ?
spc_music_load_adr	.word ?
echo_pointer			.dword ?
.send ; sDP


;notes:
; code loads to $200
; stereo, 0 is off (mono), 1 is on;
; volume 127 = max
; pan 128 = center
; music_1.bin is song 1
; and spc700.bin is the code and brr samples
; sounds.h and sounds.asm are only useful in that
; they tell you the number value of each song
; and sfx. they are meant for tools other than ca65



;nmi should be disabled
;AXY16
;lda # address of spc700.bin
;ldx # bank of spc700.bin
;jsl SPC_Init
.al
.xl
SPC_Init

;note, first 2 bytes of bin are size
;increment the data address by 2

	php
	#AXY16
	sta spc_pointer 			;address of music code
	stx spc_pointer+2 		;bank of music code
	
	tsx
	stx save_stack
	ldy #14 						;bytes 14-15 is the address to load the song
	lda [spc_pointer], y 	;address to load the song
	sta spc_music_load_adr	;save for later
	
	lda spc_pointer+2			;bank of music code
	pha
	lda spc_pointer			;address of music code
	inc a
	inc a							;actual code is address +2
	pha
	lda [spc_pointer]			;1st 2 bytes are the size
	pha
	lda #$0200					;address in apu
	pha
	jsl SPC_Load_Data
	ldx save_stack
	txs 							;8
	
	lda #kSCMD_INITIALIZE
	sta gss_command
	stz gss_param
;	jsl SPC_Command_ASM
;	;default is mono
;	plp
;	rtl
	jmp SPC_Common_End
	

;stack relative
;5 = addr in apu, last pha
;7 = size
;9 = src l
;11 = src h
.al
.xl
SPC_Load_Data

	php
	#AXY16
	
	sei
; make sure no irq's fire during this transfer

	#A8
	lda #$aa
-	cmp kAPU0
	bne -
	#A16
	lda 11,s					;src h
	sta spc_pointer+2
	lda 9,s					;src l
	sta spc_pointer+0
	lda 7,s					;size
	tax
	lda 5,s					;adr
	sta kAPU23
	#A8
	lda #$01
	sta kAPU1
	lda #$cc
	sta kAPU0
-	cmp kAPU0
	bne -	
	ldy #0
_load_loop
;A8
;	xba ;unneccessary
	lda [spc_pointer] ;,y
	xba
	tya
	
	#A16
	sta kAPU01
	#A8
	
-	cmp kAPU0
	bne -
	
	iny
	#A16
	inc spc_pointer
	bne +
	inc spc_pointer+2
	
.if LOROM == 1	
	lda #$8000
	sta spc_pointer
	
.endif	
+	A8
	dex
	bne _load_loop
	
	xba
	lda #$00
	xba
	clc
	adc #$02
	#A16
	tax
	
	lda #$0200			;loaded code starting address
	sta kAPU23

	txa
	sta kAPU01
	#A8
	
-	cmp kAPU0
	bne -
	
	#A16
-	lda kAPU0			;wait until SPC700 clears all communication ports, confirming that code has started
	ora kAPU2
	bne -
	
;	cli					;enable IRQ
;this is covered with the plp
	plp
	rtl



	
;nmi should be disabled
;AXY16
;lda # address of song
;ldx # bank of song
;jsl SPC_Play_Song

;1st 2 bytes of song are size, then song+2 is address of song data
.al
.xl
SPC_Play_Song

	php
	#AXY16
	sta spc_pointer
	stx spc_pointer+2
	
	jsl Music_Stop
	
	lda #kSCMD_LOAD
	sta gss_command
	stz gss_param
	jsl SPC_Command_ASM
	
	#AXY16
	tsx
	stx save_stack
	lda spc_pointer+2			;#^music_code ; bank
	pha
	lda spc_pointer			;#.loword(music_code)
	inc a
	inc a 						;actual data at data+2
	pha
	lda [spc_pointer] 		;first 2 bytes of data are size
	pha
;saved at init	
	lda spc_music_load_adr 	;address in apu
	pha
	jsl SPC_Load_Data
	ldx save_stack
	txs 							;8

	stz gss_param ;zero
	lda #kSCMD_MUSIC_PLAY
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;send a command to the SPC driver	
;A16
;lda #command
;sta gss_command
;lda #parameter
;sta gss_param
;jsl SPC_Command_ASM
.al
SPC_Command_ASM

	php
	#A8
-	lda kAPU0
	bne -

	#A16
	lda gss_param
	sta kAPU23
	lda gss_command
	#A8
	xba
	sta kAPU1
	xba
	sta kAPU0

	cmp #kSCMD_LOAD	;don't wait acknowledge
	beq +

-	lda kAPU0
	beq -

+	plp
	rtl

	

;void SPC_Stereo(unsigned int stereo);
;A8 or A16
;lda #0 (mono) or 1 (stereo)
;jsl SPC_Stereo
.al
.xl
SPC_Stereo

	php
	#AXY16
	and #$00ff
	sta gss_param
	
	lda #kSCMD_STEREO
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;void SPC_Global_Volume(unsigned int volume,unsigned int speed);
;AXY8 or AXY16
;lda #speed, how quickly the volume fades, 1-255*
;ldx #volume, 0-127
;jsl SPC_Global_Volume

;*255 is default = instant (any value >= 127 is instant)
;speed = 7 is about 2 seconds, and is a medium fade in/out
.al
.xl
SPC_Global_Volume

	php
	#AXY16	
	xba
	and #$ff00		;speed
	sta gss_param
	txa
	and #$00ff		;volume
	ora gss_param
	sta gss_param
	
	lda #kSCMD_GLOBAL_VOLUME
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;void SPC_Channel_Volume(unsigned int channels,unsigned int volume);
;AXY8 or AXY16
;lda #channels (bit field), see above
;ldx #volume   0-127
;jsl SPC_Channel_Volume
.al
.xl
SPC_Channel_Volume

	php
	#AXY16
	xba
	and #$ff00 ;channel
	sta gss_param
	txa
	and #$00ff ;volume
	ora gss_param
	sta gss_param
	
	lda #kSCMD_CHANNEL_VOLUME
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
	
;void Music_Stop(void);
;jsl Music_Stop
.al
.xl
Music_Stop

	php
	#AXY16
	
	lda #kSCMD_MUSIC_STOP
	sta gss_command
	stz gss_param
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	

	
;void Music_Pause(unsigned int pause);
;A8 or A16
;lda #0 (unpause) or 1 (pause)
;jsl Music_Pause
.al
.xl
Music_Pause

	php
	#AXY16
	and #$00ff
	sta gss_param
	
	lda #kSCMD_MUSIC_PAUSE
	sta gss_command
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
;void Sound_Stop_All(void);
;jsl Sound_Stop_All
.al
.xl
Sound_Stop_All

	php
	#AXY16
	
	lda #kSCMD_STOP_ALL_SOUNDS
	sta gss_command
	stz gss_param
	
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
.al
.xl	
SFX_Play_Center
;AXY8 or AXY16
;in a= sfx #
;	x= volume 0-127
;	y= sfx channel 0-7, needs to be > than max song channel
;pan center

	php
	#AXY8
	sta spc_temp
	stx spc_temp+1
	
	#AXY16
	tsx
	stx save_stack
	
	lda #128			;pan center
	pha
SFX_Play_common
	lda spc_temp+1 ;volume 0-127
	and #$00ff
	pha
	lda spc_temp	;sfx #
	and #$00ff
	pha
	tya 				;channel, needs to be > the song channels
	and #$0007
	pha
	jsl SFX_Play
	ldx save_stack
	txs
	plp
	rtl

	
.al
.xl	
SFX_Play_Left
;AXY8 or AXY16
;in a= sfx #
;	x= volume 0-127
;	y= sfx channel 0-7, needs to be > than max song channel
;pan left

	php
	#AXY8
	sta spc_temp
	stx spc_temp+1
	
	#AXY16
	tsx
	stx save_stack
	
	lda #0 ;pan left
	pha
	jmp SFX_Play_common
	

.al
.xl	
SFX_Play_Right
;AXY8 or AXY16
;in a= sfx #
;	x= volume 0-127
;	y= sfx channel 0-7, needs to be > than max song channel
;pan right

	php
	#AXY8
	sta spc_temp
	stx spc_temp+1
	
	#AXY16
	tsx
	stx save_stack
	
	lda #255 ;pan right
	pha
	jmp SFX_Play_common	



	
;void SFX_Play(unsigned int chn,unsigned int sfx,unsigned int vol,int pan);
;stack relative
;5 = chn last in
;7 = volume
;9 = sfx
;11 = pan
;NOTE - use the other functions above
.al
.xl
SFX_Play

	php
	#AXY16

	lda 11,s			;pan
	bpl +
		lda #0
+	cmp #255
	bcc +
		lda #255
+	xba
	and #$ff00
	sta gss_param
	
	lda 7,s				;sfx number
	and #$00ff
	ora gss_param
	sta gss_param

	lda 9,s				;volume
	xba
	and #$ff00
	sta gss_command

	lda 5,s				;chn
	asl a
	asl a
	asl a
	asl a
	and #$0070
	ora #kSCMD_SFX_PLAY
	ora gss_command
	sta gss_command

;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End






;void SPC_Stream_Update(void);
.al
.xl
SPC_Stream_Update

; streaming functions have been removed



;adding some echo functions - doug fraker 2021

;AXY8 or AXY16
;lda #echo volume 0-$7f or ($80-ff negative), (0 = off) 
;ldx #which channels on? (bit field, each bit = a channel)
;jsl Echo_Vol
.al
.xl
Echo_Vol
	php
	#AXY16
	and #$00ff 		;***** changed v5
	sta spc_temp
	txa
	and #$00ff 		;which channels
	xba
	ora spc_temp
	sta gss_param
	lda #kSCMD_ECHO_VOL
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	



;AXY8 or AXY16
;lda #echo start address highbyte
;ldx #echo delay (0-$f), should be 0-5
;jsl Echo_Addr

; this is very important! echo vol must be off before changing this
; echo address needs to be > the last spc file byte
; delay is $800 bytes x val, and needs to be small enough
; to fit in the remaining RAM space (and shouldn't use
; that last $800 since it's part of the boot loader ROM)
; Note: a delay of 0 does actually function as a VERY short 
; echo delay, but probably won't sound very good.
.al
.xl
Echo_Addr
	php
	#AXY16
	and #$00ff
	sta spc_temp
	txa
	and #$00ff
	xba
	ora spc_temp
	sta gss_param
	lda #kSCMD_ECHO_ADDR
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
	jmp SPC_Common_End
	
	
;AXY8 or AXY16
;lda #FIR filter settings (0-3)
;  0 = simple echo
;  1 = multi tap echo
;  2 = low pass echo
;  3 = high pass echo
;ldx #echo feedback volume (0-$7f) or ($80-ff negative)
;jsl Echo_Fb_Fir	
.al
.xl	
Echo_Fb_Fir
	php
	#AXY16
	and #$0003 ;fir
	sta spc_temp
	txa
	and #$00ff ;***** changed v5
	xba
	ora spc_temp
	sta gss_param
	lda #kSCMD_ECHO_FB_FIR
	sta gss_command
;	jsl SPC_Command_ASM
;	plp
;	rtl
;	jmp SPC_Common_End --- fall through ---
	
	
.al
.xl	
SPC_Common_End
	jsl SPC_Command_ASM
	plp
	rtl
	
	
;sets all the echo functions AND global volume
;output from Echo4GSS is a 14 byte array
;
;1 = which channels have echo enabled
;2 = echo start address
;3 = echo size / delay
;4 = echo volume
;5 = echo feedback
;6-13 = FIR filter values
;14 = global (main) volume

;AXY16
;lda # address of echo data
;ldx # bank of echo data
;jsl SPC_All_Echo
.al
.xl
SPC_All_Echo
	php
	#AXY16
	sta echo_pointer ;pointer to the data
	stx echo_pointer+2 ;bank
	
	jsl Sound_Stop_All
	
;first send the FIR, overwrite FIR set #0
;	AXY16
	lda #kSCMD_LOAD
	sta gss_command
	stz gss_param
	jsl SPC_Command_ASM
	tsx
	stx save_stack
;	lda #^TEST_FIR ;source bank
	lda echo_pointer+2
	pha
;	lda #.loword(TEST_FIR) ;source address
	lda echo_pointer
	clc
	adc #5
	pha
	lda #8 ;size
	pha
	lda #$03aa ;SPC address to patch (= the FIR table)
	pha
	jsl SPC_Load_Data
	ldx save_stack
	txs

	#AXY8
	ldy #4
	lda [echo_pointer], y ;echo feedback
	tax
	lda #0 ;FIR Set 0
	jsl Echo_Fb_Fir	
	
	lda #0 ;echo volume 0 before we change
	tax    ;the echo start address
	jsl Echo_Vol

	ldy #2 
	lda [echo_pointer], y ;size / delay
	and #$0f ;should be 0-f
	tax
	dey ;y = 1
	lda [echo_pointer], y ;start address
	jsl Echo_Addr
	
	ldy #13
	lda [echo_pointer], y ;global volume
	tax ;right away
	jsl SPC_Global_Volume
	
	lda [echo_pointer] ;which echo channels active
	tax 
	ldy #3
	lda [echo_pointer], y ;echo volume
	jsl Echo_Vol
	
	plp
	rtl














	