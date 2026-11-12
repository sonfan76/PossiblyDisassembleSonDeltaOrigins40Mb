;Ram vars					     ADDED
Cursor_X equ $00FF0000		;Ram for X_position  ADDED THIS IS THE CHAR CURSOR
Cursor_Y equ $00FF0000+1	;Ram for Y position  ADDED
Cursor1_X1 equ $00FF0000+2	;Ram for X_position2  ADDED FOR SMILEY 1
Cursor1_Y1 equ $00FF0000+3	;Ram for Y position2  ADDED
Cursor2_X2 equ $00FF0000+4	;Ram for X_position2  ADDED FOR SMILEY 2
Cursor2_Y2 equ $00FF0000+5	;Ram for Y position2  ADDED
Color0_Normal_LastSet equ $00FF0000+16	;Ram for Color0

Color0_Was_Changed_By_Move equ $00FF0000+64	;Ram for Color0WasChangedByMove

Concurrent_Overlap_Of_Smileys_Has_Occured equ $00FF0000+128

;VDP data ports
VDP_data equ $C00000	;VDP data port R/W word or long access only
VDP_ctrl equ $C00004	;VDP control port, longword or word write only

;Cartrige header for fusion 
;	dc.l $FFFFFE00
;	dc.l ProgramStart
;	ds.l 62,InterruptHandler		;62*InterruptHandler Note: has to be ds, not dc
;	ds.b 256,0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 					Traps
	DC.L	$FFFFFE00		;SP register value
	DC.L	ProgramStart	;Start of Program Code
	DS.L	7,IntReturn		; bus err,addr err,illegal inst,divzero,CHK,TRAPV,priv viol
	DC.L	IntReturn		; TRACE
	DC.L	IntReturn		; Line A (1010) emulator
	DC.L	IntReturn		; Line F (1111) emulator
	DS.L	4,IntReturn		; Reserverd /Coprocessor/Format err/ Uninit Interrupt
	DS.L	8,IntReturn		; Reserved
	DC.L	IntReturn		; spurious interrupt
	DC.L	IntReturn		; IRQ level 1
	DC.L	IntReturn		; IRQ level 2 EXT
	DC.L	IntReturn		; IRQ level 3
	DC.L	IntReturn		; IRQ level 4 Hsync
	DC.L	IntReturn		; IRQ level 5
	DC.L	IntReturn		; IRQ level 6 Vsync
	DC.L	IntReturn		; IRQ level 7 
	DS.L	16,IntReturn	; TRAPs
	DS.L	16,IntReturn	; Misc (FP/MMU)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Header
	DC.B	"SEGA GENESIS    "	;System Name
	DC.B	"(C)TAILS"			;Copyright
 	DC.B	"2026.Oct"			;Date            
	DC.B	"TailsCo                                         " ; Cart Name
	DC.B	"SweetDreams                                     " ; Cart Name (Alt)
	DC.B	"GM TAILS001-00"	;TT NNNNNNNN-RR T=Type (GM=Game) N=game Num  R=Revision
	DC.W	$0000				;16-bit Checksum (Address $000200+)
	DC.B	"J               "	;Control Data (J=3button K=Keyboard 6=6button C=cdrom)
	DC.L	$00000000			;ROM Start
	DC.L	$003FFFFF			;ROM Length
	DC.L	$00FF0000,$00FFFFFF	;RAM start/end (fixed)
	DC.B	"            "		;External RAM Data
	DC.B	"            "		;Modem Data
	DC.B	"                                        " ;MEMO
	DC.B	"JUE             "	;Regions Allowed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Generic Interrupt Handler
IntReturn:
	rte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;					Program Start
ProgramStart:
	;initialize TMSS (TradeMark Security System)
	move.b ($A10001),D0		;A10001 test the hardware version
	and.b #$0F,D0
	beq	NoTmss				;branch if no TMSS chip
	move.l #'SEGA',($A14000);A14000 disable TMSS 
NoTmss:

;;ProgramStart:

	;Setup screen
	lea VDP_settings,a5	;Init screen registers
	move.l #19,d1		;Number of Settings
	
	move.w (VDP_ctrl),d0	;C00004 read VDP status (Interrupt ack?)
	move.l #$00008000,d5	;VDP Reg command ($8rvv) R=Reg V=new value
	
	
NextInitByte:
	move.b (a5)+,d5		;get next video control byte
	move.w d5,(VDP_ctrl)	;C00004 send write register command to VDP
		;8RVV - R=Reg, V=value
	add.w #$0100,d5		;Point to next VDP register
	dbra d1,NextInitByte	;loop for the rest of the block
				;(d1 here number was set in the number of settings number up there
				;(the lea VDP_settings a5 put the mem addy into a5 IIRC, which puts into d5 and then increments up there in move.b and move.w)
 
;define pallet ($----BBB-GGG-RRR-)
	move.l #$C0000000,VDP_ctrl	;Color 0
	move.w #%0000011011101110,VDP_data   ;the actual color sent to vdp_data  back
	
	move.l #$C0020000,VDP_ctrl	;Color 1
	move.w #%0000000011001110,VDP_data ;the actual color sent to vdp_data    fore
	
	move.l #$C0040000,VDP_ctrl	;Color 2
	move.w #%0000110011100000,VDP_data ;the actual color sent to vdp_data    eye1
	
	move.l #$C0060000,VDP_ctrl	;Color 3
	move.w #%0000111011100000,VDP_data ;the actual color sent to vdp_data    eye2
	
	move.l #$C0080000,VDP_ctrl	;Color 4
	move.w #%0000111011101110,VDP_data ;the actual color sent to vdp_data    teeth
	
	move.l #$C00A0000,VDP_ctrl	;Color 5
	move.w #%0000110011001100,VDP_data ;the actual color sent to vdp_data    darker
	
	move.w #$8144,(VDP_ctrl)	;C00004 reg 1 = 0x44 unblank display


		move.w #%0000110011101110,Color0_Normal_LastSet ; Initial "fixing" background color saved
			
FontStart:
	cmp.b #27,d1	;check if at the bottom of the screen again
		beq ChangePallet
	cmp.b #40,d0	;Check if at right of the screen (note)was 39, changed to 40 so you could go right up to the edge
		beq OrigPallet
FontContinue:
	;Setup Font
	lea Font,a1	; Font Address in ROM
	move.l #26*8*4,d6	;our font contains 26 8 line 4 bytes per line
	
	move.l #$44200000,(VDP_ctrl)	;start writes to address $0420
					;patterns in vram
NextFont:
	move.b (a1)+,d0		;Get byte from font
	moveq.l #7,d5		;bit count (eight bits)
	clr.l d1		;Reset buildup byte
					
Font_NextBit:	;1 color per nibble = 4 bytes

	rol.l #3,d1	;shift buildup 3 bytes left
	roxl.b #1,d0	;shift a bit from the 1bpp font into the pattern
	roxl.l #1,d1	;shift bit into BuildUp
	dbra d5,Font_NextBit	;Next bit from font
	
	move.l d1,(VDP_data)	;vvrite next long of char to VDP_data (one line)
	dbra d6,NextFont	;loop untill done
	
	clr.w Cursor_X		;clear cursor xy
	move.w #$8144,(VDP_ctrl)	;turn on screen
	
	lea Message,a3		;string to show
	jsr PrintString		;print string to screen
	jmp ContinueProgramStart; That worked
	;;;;;;;;;;;not needed? jmp *			;infinite loop
	

	
ContinueProgramStart:
;define our test tile
	lea Bitmap,a0		;Source data
	move.w #32,d1		;Length of data (1 tile = 32 bytes)
	
	move.l #$40200000,(VDP_ctrl)	;start writes to the address $0020

		move.l #0,(Color0_Was_Changed_By_Move)	;Reset this as we have reset the colors going --> is fine again



DefineTilesAgain:
	move.l (a0)+,d0
	move.l d0,(VDP_data)	;send the tile data to the VDP
	dbra d1,DefineTilesAgain	;d1 contains 32, the length of data, will loop here from 32..31..30..29..28...etc decremented till no num left	
	
	clr.w Cursor1_X1	;clear smileysave cursor xy		;This is for the position of the first smiley
	clr.w Cursor2_X2	;clear smileysave 2 cursor xy   	;This is for the position of the second smiley
	
	move.l #3,d0			;xpos
	move.l #3,d1			;ypos
	move.b d0,(Cursor1_X1)						;This is for recording the first position of the first smiley
	move.b d1,(Cursor1_Y1)						;This is for recording the first position of the first smiley
	jsr DrawSprite			;show new sprite
	
	move.l #23,d0			;xpos	;initial position
	move.l #23,d1			;ypos	;initial position2
	move.b d0,(Cursor2_X2)						;This is for recording the first position of the second smiley
	move.b d1,(Cursor2_Y2)						;This is for recording the first position of the second smiley
	jsr DrawSprite2			;show new sprite 		;I guess...
	
	jmp DrawLoop
ChangePallet:
	;First clear the 2 sprites
		move.b (Cursor1_X1),d0			;These all are for recalling the recording the 2 different positions for the 2 smileys
		move.b (Cursor1_Y1),d1			;These all are for recalling the recording the 2 different positions for the 2 smileys
		jsr SpecialClearSprite	;Remove old sprite 1
		move.b (Cursor2_X2),d0			;These all are for recalling the  recording the 2 different positions for the 2 smileys
		move.b (Cursor2_Y2),d1			;These all are for recalling the  recording the 2 different positions for the 2 smileys
		jsr SpecialClearSprite	;Remove old sprite 2
	
	;Actual Pallet change:
	move.l #$C0000000,VDP_ctrl	;Color 0
	move.w #%0000011000001110,VDP_data   ;the actual color sent to vdp_data  back
			;move.w VDP_data,(Color0_Normal_LastSet) ;Does not work, all black even after 1st time
			;move.w (VDP_data),(Color0_Normal_LastSet) ;Does not work same reason
			;move.w #%0000011000001110,(Color0_Normal_LastSet) 
		move.w #%0000011000001110,Color0_Normal_LastSet ;also works

	jmp FontContinue
OrigPallet:
	;First clear the 2 sprites since this is called only when warping
		move.b (Cursor1_X1),d0			;These all are for recalling the recording the 2 different positions for the 2 smileys
		move.b (Cursor1_Y1),d1			;These all are for recalling the recording the 2 different positions for the 2 smileys
		jsr SpecialClearSprite	;Remove old sprite 1
		move.b (Cursor2_X2),d0			;These all are for recalling the  recording the 2 different positions for the 2 smileys
		move.b (Cursor2_Y2),d1			;These all are for recalling the  recording the 2 different positions for the 2 smileys
		jsr SpecialClearSprite	;Remove old sprite 2
	
	;Actual Pallet change:
	move.l #$C0000000,VDP_ctrl	;Color 0
	move.w #%0000011011101110,VDP_data   ;the actual color sent to vdp_data  back
			;move.w VDP_data,(Color0_Normal_LastSet) ;Does not work, all black even after 1st run to the side
			;move.w (VDP_data),(Color0_Normal_LastSet) ;Does not work 
			;move.w #%0000011011101110,(Color0_Normal_LastSet)
		move.w #%0000011011101110,Color0_Normal_LastSet ;also works
	jmp FontContinue

YIsSame:
	move.b #5,(Concurrent_Overlap_Of_Smileys_Has_Occured) ;Same, so set to 5 (arbitrary decision)
	jsr SameSpotChangePallet
	jmp ContinueDrawLoopAfterXYTest
XIsSame:
	move.b (Cursor1_Y1),d0
	move.b (Cursor2_Y2),d1
	cmp.b d0,d1
		beq YIsSame
	
	;;;;;;;;;;;  Here we see if we must restore the pallet
	move.b (Concurrent_Overlap_Of_Smileys_Has_Occured),d0
	cmp.b #5,d0
		beq SkipThisPartXIS
	jsr DiffSpotRestorePallet
SkipThisPartXIS:
	;;;;;;;;;;;
	
	move.b #0,(Concurrent_Overlap_Of_Smileys_Has_Occured)  ;Not same so set to 0
	jmp ContinueDrawLoopAfterXYTest
	
	
DrawLoop:
	move.b (Cursor1_X1),d0
	move.b (Cursor2_X2),d1
	cmp.b d0,d1
		beq XIsSame
		
	;; Not needed ;; ;;;;;;;;;;; Here we see if we must restore the pallet
	;; Not needed ;; move.b (Concurrent_Overlap_Of_Smileys_Has_Occured),d0
	;; Not needed ;; cmp.b #5,d0
	;; Not needed ;; 	beq SkipThisPartXYIS
	;; Not needed ;; ;jsr DiffSpotRestorePallet ;caused problems (inital background color was the light one instead of the regular, it "restored" it to that)
	;; Not needed ;; SkipThisPartXYIS:
	;; Not needed ;; ;;;;;;;;;;;

	move.b #0,(Concurrent_Overlap_Of_Smileys_Has_Occured)  ;Not same so set to 0
	
ContinueDrawLoopAfterXYTest:
		
	move.b (Cursor1_X1),d0			;These all are for recalling the recording the 2 different positions for the 2 smileys
	move.b (Cursor1_Y1),d1			;These all are for recalling the recording the 2 different positions for the 2 smileys
	;See if we pressed <--- button on either joy
	cmpa.l #1,a6
	bne SkipA	
			move.l #$C0000000,VDP_ctrl	;Color 0
			move.w #%0000111011101110,VDP_data   ;the actual color sent to vdp_data  
			move.l #1,(Color0_Was_Changed_By_Move) ;inform us we changed the color by moving around
SkipA:
	cmpa.l #2,a6
	bne SkipB	
			move.l #$C0000000,VDP_ctrl	;Color 0
			move.w #%0000110011001100,VDP_data   ;the actual color sent to vdp_data  
			move.l #1,(Color0_Was_Changed_By_Move) ;inform us we changed the color by moving around
SkipB:
	cmpa.l #3,a6
	bne Skip	
		cmp.l #1,(Color0_Was_Changed_By_Move)
		bne Skip
			;move.l #$C0000000,VDP_ctrl	;Color 0
			;move.w #%0000111011001110,VDP_data   ;the actual color sent to vdp_data  
			
			; ;move.l #$C0000000,VDP_ctrl	;Color 0
			; ;move.w #%0000000000000000,VDP_data   ;the actual color sent to vdp_data  
			 move.l #$C0000000,VDP_ctrl	;Color 0  ;Without this it
			 move.w (Color0_Normal_LastSet),VDP_data   ;Cycles
			; move.w Color0_Normal_LastSet,VDP_data   ;Cycles ; seems to work too

Skip:
	movea.l #0,a6 ;reset a6
	move.b #%01000000,($A100009) ;Setport direction I0IIIIII (I=In, 0=Out)
	move.l #$A10003,a0	;RW port for player 1 joypad .. had an extra zero before the 3
	
	move.b #$40,(a0)	;Strobe port
	nop			;delay
	nop
	move.b (a0),d3		;Get buttons --CBRLDU
	
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;;;clr.l d7	;Going to use d7 for a counter    HERE
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;;;move.b #1,(a2)  ; use a2 as the counter?
	movea.l #1,a2	; HERE set this counter says we polled joy1;MOVEA.L
	jmp SkipJoyTwoAndUseJoyOne ;Jump over joy 2 if any keys pressed on joy one 
	                           ; Note: Below at the end is jumped to dojoytwo every other time
			
DoJoyTwo:
	move.b (Cursor2_X2),d0			;These all are for recalling the  recording the 2 different positions for the 2 smileys
	move.b (Cursor2_Y2),d1			;These all are for recalling the  recording the 2 different positions for the 2 smileys
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;;clr.b d3 ; clear d3?
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;;;clr.l a0 ; and a0?
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;;;This works alone
	move.b #%01000000,($A10000B) ;Setport direction I0IIIIII (I=In, 0=Out)  ;Joy2
	move.l #$A10005,a0	;RW port for player 1 joypad .. Joy
	
	move.b #$40,(a0)	;Strobe port
	nop			;delay
	nop
	move.b (a0),d3		;Get buttons --CBRLDU
	
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	;move.b #1,d7 ;We used joy 2, set d7 to something  HERE
			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	;move.b #0,(a2)
	movea.l #0,a2	;HERE set this counter says we polled joy two			;MOVEA.L
	
SkipJoyTwoAndUseJoyOne:
	cmp.b #%00111111,d3	;Test if any keys are pressed
	beq DrawLoop
	
	jsr ClearSprite	;Remove old sprite

	btst #0,d3
	bne JoyNotUp	;Jump if UP not pressed
	tst.b d1	;check if at top of screen
	beq JoyNotUp
	subq.w #1,d1	;Move Y Up the screen
	
JoyNotUp:
	btst #1,d3
	bne JoyNotDown ;jump if down not pressed
	cmp.b #27,d1	;check if at the bottom of the screen
	beq JoyNotDown
	addq.w #1,d1	;Move Y Down the screen

JoyNotDown:
	btst #2,d3
	bne JoyNotLeft	;Jump if LEFT is not pressed
	tst.b d0	;check if at the left of the screen
	beq JoyNotLeft 
	subq.w #1,d0	;Move X left
	
	cmpa.l #0,a2
	beq SkipKeyPressToA6
	movea.l #1,a6	;let us know we pressed key	;HERE HERE
SkipKeyPressToA6:
	cmpa.l #1,a2
	beq SkipKeyPressToA6_Again
		movea.l #2,a6	;let us know we pressed key	;HERE HERE
SkipKeyPressToA6_Again:
	
JoyNotLeft:
	btst #3,d3
	bne JoyNotRight	;Jump if RIGHT not pressed
	cmp.b #40,d0	;Check if at right of the screen (note)was 39, changed to 40 so you could go right up to the edge
	beq JoyNotRight
	addq.w #1,d0
	
	movea.l #3,a6	;let us know we pressed key	;HERE HERE
	
JoyNotRight:
	cmpa.l #0,a2				;These all are for recording the 2 different positions for the 2 smileys
	beq SkipToJoy2Record			;These all are for recording the 2 different positions for the 2 smileys	
	jmp SkipToJoy1Record			;These all are for recording the 2 different positions for the 2 smileys
						;These all are for recording the 2 different positions for the 2 smileys
SkipToJoy1Record:				;These all are for recording the 2 different positions for the 2 smileys
	move.b d0,(Cursor1_X1)			;These all are for recording the 2 different positions for the 2 smileys
	move.b d1,(Cursor1_Y1)			;These all are for recording the 2 different positions for the 2 smileys	
	jmp ContinueAfterRecord			;These all are for recording the 2 different positions for the 2 smileys
						;These all are for recording the 2 different positions for the 2 smileys
SkipToJoy2Record:				;These all are for recording the 2 different positions for the 2 smileys
	move.b d0,(Cursor2_X2)			;These all are for recording the 2 different positions for the 2 smileys
	move.b d1,(Cursor2_Y2)			;These all are for recording the 2 different positions for the 2 smileys
						;These all are for recording the 2 different positions for the 2 smileys
ContinueAfterRecord:				;These all are for recording the 2 different positions for the 2 smileys
	jsr DrawSprite	;Show new sprite
		;cmp.b #27,d1	;check if at the bottom of the screen again
			;;;;move.l d1,a1	;try to save info
			;;;;move.l d0,a2	;try to save info
		;beq FontStartButClearFirst
		;beq FontStart
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;move.l #$FFFF,d3	;pause
	move.l #$7FFF,d3	;pause ;but half the time since we're now polling 1 joy and then another
	
DelayLoop:
	dbra d3,DelayLoop
	
	cmpa.l #0,a2
	beq DrawLoop
	jmp DoJoyTwo 
	;Note, used to simply jump to DrawLoop before trying to add 2nd controler
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	cmp.b #1,(a2)	;See if a2 has a 1 in it
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	;beq DoJoyTwo
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	;;jmp DoJoyTwo ;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	;jmp DrawLoop	;Draw again
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	beq DrawLoop
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; tried;	jmp DoJoyTwo ;

ClearSprite:
	move.l #0,d4	;TileNumber (Clear)
	jmp DrawSpriteAlt	;omitted this, oops
DrawSprite2:						
	move.l #2,d4	;TileNumber (Smiley2maybe)	;Adding
	jmp DrawSpriteAlt				;Adding
DrawSprite
	move.l #1,d4	;TileNumber (Smiley)
	
DrawSpriteAlt:
	move.l #$40000003,d5 	;C000 offset + Vram command
	clr.l d7
	move.b d1,d7
	
	rol.l #8,d7	;calculate ypos
	rol.l #8,d7
	rol.l #7,d7
	add.l d7,d5
	
	move.b d0,d7	;calculate xpos
	rol.l #8,d7
	rol.l #8,d7
	rol.l #1,d7
	add.l d7,d5
	
	move.l d5,(VDP_ctrl)	;C00004 Get VRAM address
	move.w d4,(VDP_data)	;C00000 select tile from mem loc
	cmp.b #27,d1	;check if at the bottom of the screen again
			;;;;move.l d1,a1	;try to save info
			;;;;move.l d0,a2	;try to save info
		;beq FontStartButClearFirst
		beq FontStart
		cmp.b #40,d0	;Check if at right of the screen (note)was 39, changed to 40 so you could go right up to the edge
		beq FontStart
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;Font stuff
PrintChar:	;show d0 to screen
	and.l #%11011111,d0	;convert to uppercase
	sub.l #32,d0		;no characters in our font below 32
PrintCharAlt:
	move.l #$40000003,d5	;top 4 = write, bottom $3=CXXX range (tile map)
	clr.l d4
	
	move.b (Cursor_Y),d4
	move.l #8+8+7,d1
	rol.l d1,d4
	add.l d4,d5		;add 4------3
	
	move.b (Cursor_X),d4
	move.l #8+8+1,d1
	rol.l d1,d4
	add.l d4,d5		;add 4------3
	
	move.l d5,(VDP_ctrl)	;C00004 write next character to VDP
	move.w d0,(VDP_data)	;C00000 store next word of name data
	
	addq.b #1,(Cursor_X)	;inc Xposition
	rts
	
PrintString:
	move.b (a3)+,d0		;read a character from A3
	cmp.b #255,d0	
	beq PrintString_Done	;return on 255
	jsr PrintChar		;print the character
	bra PrintString
PrintString_Done
		;;;;move.l a1,d1	;try to restore save info
		;;;;move.l a2,a0	;try to restore save info
	rts
	
	
		
InterruptHandler:		;Basic interrupt handler
	rte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;Font stuff
SpecialClearSprite:
	move.l #0,d4	;TileNumber (Clear)
	jmp SpecialDrawSpriteAlt	;omitted this, oops
SpecialDrawSprite2:						
	move.l #2,d4	;TileNumber (Smiley2maybe)	;Adding
	jmp SpecialDrawSpriteAlt				;Adding
SpecialDrawSprite
	move.l #1,d4	;TileNumber (Smiley)
	
SpecialDrawSpriteAlt:
	move.l #$40000003,d5 	;C000 offset + Vram command
	clr.l d7
	move.b d1,d7
	
	rol.l #8,d7	;calculate ypos
	rol.l #8,d7
	rol.l #7,d7
	add.l d7,d5
	
	move.b d0,d7	;calculate xpos
	rol.l #8,d7
	rol.l #8,d7
	rol.l #1,d7
	add.l d7,d5
	
	move.l d5,(VDP_ctrl)	;C00004 Get VRAM address
	move.w d4,(VDP_data)	;C00000 select tile from mem loc
	
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;Font stuff

SameSpotChangePallet:
	;Actual Pallet change:
	move.l #$C0000000,VDP_ctrl	;Color 0
	move.w #%0000000000001110,VDP_data   ;the actual color sent to vdp_data  back
	;define pallet ($----BBB-GGG-RRR-)

	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;Font stuff
DiffSpotRestorePallet:
	;Actual Pallet change:
	move.l #$C0000000,VDP_ctrl	;Color 0
	move.w (Color0_Normal_LastSet),VDP_data   ;Cycles
	
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;Font stuff


Bitmap:		;one nibble per pixel

	dc.b $00,$11,$11,$00  ;1
	dc.b $01,$11,$11,$10  ;2
	dc.b $11,$21,$13,$11  ;3
	dc.b $11,$11,$11,$11  ;4
	dc.b $11,$11,$11,$11  ;5
	dc.b $11,$51,$14,$11  ;6
	dc.b $01,$14,$41,$10  ;7
	dc.b $00,$11,$11,$00  ;8
	
Font:							;ADDED
	dc.b $18,$3C,$66,$66,$7E,$66,$24,$00 ;A		;ADDED
	dc.b $3C,$66,$66,$7C,$66,$66,$3C,$00 ;B		;ADDED
	dc.b $38,$7C,$C0,$C0,$C0,$7C,$38,$00 ;C		;ADDED
	dc.b $3C,$64,$66,$66,$66,$64,$38,$00 ;D		;ADDED
	dc.b $3C,$7E,$60,$78,$60,$7E,$3C,$00 ;E		;ADDED
	dc.b $38,$7C,$60,$78,$60,$60,$20,$00 ;F		;ADDED
	dc.b $3C,$66,$C0,$C0,$CC,$66,$3C,$00 ;G		;ADDED
	dc.b $24,$66,$66,$7E,$66,$66,$24,$00 ;H		;ADDED
	dc.b $10,$18,$18,$18,$18,$18,$08,$00 ;I		;ADDED
	dc.b $08,$0C,$0C,$0C,$4C,$FC,$78,$00 ;J		;ADDED
	dc.b $24,$66,$6C,$78,$6C,$66,$24,$00 ;K		;ADDED
	dc.b $20,$60,$60,$60,$60,$7E,$3E,$00 ;L		;ADDED
	dc.b $44,$EE,$FE,$D6,$D6,$D6,$44,$00 ;M		;ADDED
	dc.b $44,$E6,$F6,$DE,$CE,$C6,$44,$00 ;N		;ADDED
	dc.b $38,$6C,$C6,$C6,$C6,$6C,$38,$00 ;O		;ADDED
	dc.b $38,$6C,$64,$7C,$60,$60,$20,$00 ;P		;ADDED
	dc.b $38,$6C,$C6,$C6,$CA,$74,$3A,$00 ;Q		;ADDED
	dc.b $3C,$66,$66,$7C,$6C,$66,$26,$00 ;R		;ADDED
	dc.b $3C,$7E,$60,$3C,$06,$7E,$3C,$00 ;S		;ADDED
	dc.b $3C,$7E,$18,$18,$18,$18,$08,$00 ;T		;ADDED
	dc.b $24,$66,$66,$66,$66,$66,$3C,$00 ;U		;ADDED
	dc.b $24,$66,$66,$66,$66,$3C,$18,$00 ;V		;ADDED
	dc.b $44,$C6,$D6,$D6,$FE,$EE,$44,$00 ;W		;ADDED
	dc.b $C6,$6C,$38,$38,$6C,$C6,$44,$00 ;X		;ADDED
	dc.b $24,$66,$66,$3C,$18,$18,$08,$00 ;Y		;ADDED
	dc.b $7C,$FC,$0C,$18,$30,$7E,$7C,$00 ;Z		;ADDED
	


VDP_Settings:
	dc.b 4,4,$30,$3C,$07,$6C,0,0,0,0,$FF,0,$81,$37,0,2,1,0,0


Message: dc.b 'Tails is a girl',255
	
	even	;Word align after byte data
