				//
// COMPILE THIS USING ZX-IDE
// http://www.sinclairzxworld.com/viewtopic.php?f=6&t=1064
//
// tl;dr:  file -> open, ctrl-f9
//

	format zx81

	MEMAVL =  MEM_16K	 // can be MEM_1K, MEM_2K, MEM_4K, MEM_8K, MEM_16K, MEM_32K, MEM_48K
	STARTMODE EQU SLOW_MODE  // SLOW or FAST
	DFILETYPE EQU EXPANDED	 // COLLAPSED or EXPANDED or AUTO

	include 'SINCL-ZX\ZX81.INC'

	S_OPEN		equ	1	; ZXpand+ streaming API defines
	S_READ		equ	2
	S_WAIT		equ	4
	S_STORE 	equ	8

	api_stream	equ	$1FF4	; vector addresses in ZXpand+ overlay ROM
	api_response	equ	$1FF6

	API_OP		equ	$403c	; API header addresses (PRBUFF - PRBUFF+32)
	API_RES 	equ	$403d
	API_DLEN	equ	$403e
	API_DPTR	equ	$403f

	AUTOLINE 10

	REM	_asm

SYSEXEC_CODE:
	db $f0,$7e,$7f,$09,$01,$f7	;sys exec midi start gm... resets gm synth

main:
	ld	a,$ff			; set next frame number to -1
	ld	(frameNum),a
	ld	(frameNum+1),a
	ld	(frameNum+2),a


	ld	a,($4034)
	dec	a
	ld	(frameCache),a

mainLoop:
	ld	a,S_READ+S_WAIT 	; read file & wait for result using stream API
	ld	(API_OP),a
	ld	a,0
	ld	(API_DLEN),a
	call	api_stream

	ld	a,(API_RES)		; return on file error / done
	cp	$40
	ret	nz

	in	a,($7)			; upper 8 address bits not needed for read
	ld	(frameCmp),a
	in	a,($7)
	ld	(frameCmp+1),a
	in	a,($7)
	ld	(frameCmp+2),a

; has a frame already passed?
	ld	a,(frameCache)
	ld	hl,FRAMES
	cp	(hl)

innerLoop:
	call	z,waitFrame   ;NO wait for next frame.


;increment our frame counter
	ld	a,($4034)
	ld	(frameCache),a

	ld	hl,(frameNum)
	inc	hl
	ld	(frameNum),hl
	ld	a,h
	or	l
	jr	nz,skip

;first 16 bits rolled over increment byte 3

	ld	a,(frameNum+2)
	inc	a
	ld	(frameNum+2),a

skip:

;at this point HL holds new framecount lowest 16bits

	ld	de,(frameCmp)
	and	a		;clear carry
	sbc	hl,de
	ld	a,h
	or	l
;zero if current frame = framecmp , low 16bits
	jr	nz,exitCheck	  ;not equal

;check third byte just in case
	ld	hl,frameNum+2
	ld	a,(frameCmp+2)
	sub	(hl)
	jr	nz,exitCheck	;not equal

;time for the next block

	ld	bc,$e007
	ld	a,$c1
	out (c),a
	call	$1ff6
	jr	mainLoop

exitCheck:

;is our framecount > framecmp
;if so we have gone past the end, maybe ?
	ld     hl,frameCmp+2
	ld     de,frameNum+2

	ld	a,(de)
	cp	(hl)
	jr	c,checkKeys
	jr	z,NextB1
	ret

NextB1:
	dec hl
	dec de
	ld	a,(de)
	cp	(hl)
	jr	c,checkKeys
	jr	z,NextB2
	ret
NextB2:
	dec hl
	dec de
	ld	a,(de)
	cp	(hl)
	jr	c,checkKeys
	jr	z,checkKeys
	ret

checkKeys:
	call	$02bb			; quit if key pressed
	inc	l
	jr	z,innerLoop
;a key has been pressed.
	ret

waitFrame:
	ld	hl,FRAMES
	ld	a,(hl)
waitFrameLoop:
	cp	(hl)
	jr	z,waitFrameLoop
	ret

frameCache:
	db  0
frameNum:
	db	0,0,0
frameCmp:
	db	0,0,0





	END _asm
	REM
	REM CODE SIRMORRIS
	REM ADAPTED BY ANDY REA
	REM REQUESTED BY MOGGY.
	REM



AUTORUN:
newselection:
	CLS
	PRINT "MIDIPLAY V1.02 - Moggy AutoPlay."
	PRINT
	PRINT "TRACKS WILL PLAY SEQUENTIALLY"
	PRINT "   FROM YOUR CHOSEN TRACK."
	PRINT
	PRINT "    PLEASE ENTER STARTING"
	PRINT "        TRACK NUMBER."

	INPUT I
	LET NUM=I

playloop:
	CLS
	LET A$=STR$ NUM
	PRINT "MIDIPLAY V1.02 - Moggy AutoPlay."
	PRINT
	PRINT "PLAYING """ + A$ + ".ZXM"""
	PRINT
	PRINT " ""S"" TO MAKE A NEW SELECTION "
	PRINT
	PRINT " ANY OTHER KEY FOR NEXT TRACK"

	LPRINT "OPEN MIDI"

// All internal zxpand functions work with a single file.
// Open the file here, use it in api calls!

	LPRINT "OPEN FILE " + A$ + ".ZXM"

	RAND USR #main
	LET A$=INKEY$
	LPRINT "PUT SER *16514 6"
	IF A$="S" THEN GOTO #newselection#
	LET NUM=NUM+1
	GOTO #playloop#
	STOP


getparam:
	LET A$ = ""
	LET P = #API_DPTR + 1
	FOR I = 1 TO PEEK #API_DLEN
	LET A$ = A$ + CHR$ PEEK (P + I)
	NEXT I
	RETURN

include 'SINCL-ZX\ZX81DISP.INC'   ;include D_FILE and needed memory areas

VARS_ADDR:
	db 80h
WORKSPACE:

assert ($-MEMST)<MEMAVL
// end of program