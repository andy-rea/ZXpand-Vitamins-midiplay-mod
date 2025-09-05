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

	api_zxpandcmd	equ	$1FF2
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
	xor	a
	ld	(TimeTracker),a
	ld	(TimeTracker + 1),a
	ld	(TimeTracker + 2),a
	dec	a			 ; set next frame number to -1
	ld	(frameNum),a
	ld	(frameNum + 1),a
	ld	(frameNum + 2),a
	ld	a,28			;char code for zero
	ld	(ElaspedTime),a
	ld	(ElaspedTime + 1),a
	ld	(ElaspedTime + 3),a
	ld	(ElaspedTime + 4),a



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
;if we have jumped back here from check keys zero is already set

	call	z,waitFrame   ;NO wait for next frame.


					;increment our frame counter
	ld	a,($4034)
	ld	(frameCache),a


	ld	hl,frameNum
	inc	(hl)
	jr	nz,skip
	inc	hl
	inc	(hl)
	jr	nz,skip
	inc	hl
	inc	(hl)

;above routine maybequicker than following 9 lines

;        ld      hl,(frameNum)
;        inc     hl
;        ld      (frameNum),hl
;        ld      a,h
;        or      l
;        jr      nz,skip
;                                        ;first 16 bits rolled over increment byte 3
;       ld      a,(frameNum+2)
;       inc     a
;       ld      (frameNum+2),a

skip:
	ld	hl,frameNum
	ld	de,frameCmp
	ld	a,(de)
	cpi
	jr	nz,exitCheck
	inc	de
	ld	a,(de)
	cpi
	jr	nz,exitCheck
	inc	de
	ld	a,(de)
	cpi
	jr	nz,exitCheck

;        ld      hl,(frameNum)
;       ld      de,(frameCmp)
;        and     a                       ;clear carry
;        sbc     hl,de
;        ld      a,h
;        or      l
;                                        ;zero if current frame = framecmp , low 16bits
;        jr      nz,exitCheck            ;not equal
;
;;check third byte just in case
;        ld      hl,frameNum+2
;        ld      a,(frameCmp+2)
;        sub     (hl)
;        jr      nz,exitCheck             ;not equal

;time for the next block

	ld	bc,$e007
	ld	a,$c1
	out (c),a
	call	$1ff6
	jr	mainLoop

exitCheck:

;is our frameNum > frameCmp
;if so we have gone past the end, maybe ?

;        LD      HL,(frameCmp + 1)
;        ld      de,(frameNum + 1)
;
;        and     a                       ;clear carry
;        sbc     hl,de                   ;if DE > HL, carry set
;        jr      c, ExitDelay
;        jr      nz, checkKeys
;
;; else test the low byte
;        ld      a,(frameCmp)
;        ld      HL,frameNum
;        sub     (hl)                    ;if (hl) > a, carry set
;        jr      c, ExitDelay

	ld	hl,(frameCmp)
	ld	de,(frameNum)
	and	a
	sbc	hl,de
	ex	de,hl
	ld	hl,frameNum + 2
	ld	a,(frameCmp + 2)
	sbc	a,(hl)
	jr	c, ExitDelay

;de holds number of frames we need to wait.
; going to ignore D
	ld	  a,1
	sub	  e
	jr	  c,AdjustElapsed	; e => 2

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

ExitDelay:
	ld	b,25			;half a secon should do it
EndDelayLoop:
	ld	hl,FRAMES
	ld	a,(hl)
EndDelayLoopInner:
	cp	(hl)
	jr	z,EndDelayLoopInner
	djnz	EndDelayLoop
	RET


AdjustElapsed:
; lets see if over 50 frames have elasped since last stored time tracker

	ld	hl,(frameNum)
	ld	de,(TimeTracker)
	and	a
	sbc	hl,de
	ex	de,hl
	ld	hl,TimeTracker + 2
	ld	a,(frameNum + 2)
	sbc	a,(hl)
	ld	  a,50
	sub	  e
	jr	  c,PlusSecond	     ; e => 50
	jr	  checkKeys

PlusSecond:
;save the timr track + 50
	ld	hl,(TimeTracker)
	ld	de,50
	add	hl,de
	ld	a,(TimeTracker + 2)
	adc	a,0
	ld	(TimeTracker + 2),a
	ld	(TimeTracker), hl
ChangeTheDigits:

	ld	a,(ElaspedTime + 4)		;secomds
	inc	a				;zx digits are char codes 28 to 37
	cp	38
	jr	nz,StoreSecondUnits
	ld	a,28				;back to zero
StoreSecondUnits:
	ld	(ElaspedTime + 4),a
	jr	nz,DisplayNewTime

;carry set so must increment next digit
	ld	a,(ElaspedTime + 3)		;tens of secomds
	inc	a				;zx digits are char codes 28 to 37
	cp	34				;tens can only go to 5
	jr	nz,StoreSecondTens
	ld	a,28				;back to zero
StoreSecondTens:
	ld	(ElaspedTime + 3),a
	jr	nz,DisplayNewTime

;carry set so must increment next digit
	ld	a,(ElaspedTime + 1)		;minutess
	inc	a				;zx digits are char codes 28 to 37
	cp	38				;tens can only go to 5
	jr	nz,StoreMinuteUnits
	ld	a,28				;back to zero
StoreMinuteUnits:
	ld	(ElaspedTime + 1),a
	jr	nz,DisplayNewTime

;carry set so must increment next digit
	ld	a,(ElaspedTime) 	    ;Tens of minutes
	inc	a				;zx digits are char codes 28 to 37
	cp	34				;tens can only go to 5
	jr	nz,StoreMinuteTens
	ld	a,28				;back to zero
StoreMinuteTens:
	ld	(ElaspedTime),a

DisplayNewTime:
	 LD	 HL,(16396)		 //D-file
	LD	DE,94		       //3RD LINE 5 chars from end of line
	ADD	HL,DE
	LD	D,H
	LD	E,L
	LD	HL,ElaspedTime
	ldi
	ldi
	ldi
	ldi
	ldi
	jp	checkKeys








frameCache:
	db	 0
TimeTracker:
	db	0,0,0
frameNum:
	db	0,0,0
frameCmp:
	db	0,0,0
ElaspedTime:
	dbzx  '00:00'


include 'LISTCODE.ASM'




	END _asm
	goto #newselection#
Set_AString:
	LET A$="            "
	RETURN

	REM
	REM CODE SIRMORRIS
	REM ADAPTED BY ANDY REA
	REM REQUESTED BY MOGGY.
	REM



AUTORUN:
newselection:
	CLS
	PRINT "MIDIPLAY V1.03 PLAYLIST ENABLED."
	PRINT
	PRINT " TRACKS WILL PLAY SEQUENTIALLY  "
	PRINT " FROM CHOSEN TRACK OR PLAYLIST  "
	PRINT
	PRINT "  PLEASE ENTER STARTING TRACK   "
	PRINT "   NUMBER OR ""PLAYLIST.ZPL""     "

	INPUT A$
	IF LEN A$<5 THEN GOTO #preplayloop#
	LET S=LEN A$
	IF A$(S-3 TO S) = ".ZPL" THEN GOTO #goplaylist#

preplayloop:
	LET NUM=VAL A$
playloop:
	CLS
	LET A$=STR$ NUM
	PRINT "MIDIPLAY V1.03 PLAYLIST ENABLED."
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

goplaylist:

	CLS
	LET C$="OFFON "
	PRINT "MIDIPLAY V1.03 PLAYLIST ENABLED."
	PRINT
	PRINT "PLAYING"
	PRINT
	PRINT
	PRINT
	PRINT
	PRINT
	PRINT
	PRINT
	PRINT
	PRINT
	PRINT
	PRINT " ""S"" TO MAKE A NEW SELECTION "
	PRINT
	PRINT "   ""R"" TOGGLES RANDOM PLAY"
	PRINT "    RANDOM IS CURRENTLY OFF"
	PRINT
	PRINT " ANY OTHER KEY FOR NEXT TRACK"
	REM FILL PLAYLIST SPACE WITH $FF
	RAND USR #Plist_ResetAll
	LET A$=A$+";32768"
	LOAD A$
	REM OPEN MIDI, SAME AS ZXPAND "OPEN MIDI"
	RAND USR #Plist_OpenMidi
nexttrack:
	REM FIND GET NAME MIDI FILE AND TEXT IF AVAILABLE
	RAND  USR #Plist_GetNext
	REM OPEN MIDI FILE
	RAND USR #PList_OpenFile
	REM DISPLAY DETAILS
	RAND USR #PlistDisplayText
	REM  GO STREAM THAT BITCH
	RAND USR #main
	LET A$=INKEY$
	LPRINT "PUT SER *16514 6"
	IF A$="S" THEN GOTO #newselection#
	IF A$="R" THEN GOTO #TOGGLE#
	GOTO #nexttrack#
TOGGLE:
	LET Z=PEEK(#random)
	let z=1-z
	poke(#random),z
	PRINT AT 16,24;C$(1+3*Z TO 3+3*Z)
	GOTO #nexttrack#



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