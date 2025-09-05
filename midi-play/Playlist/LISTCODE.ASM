// Extras relate to Plsylists. user may load a playlist *.ZPL file (max file size 8192)
// since as ZXPAND is present ( you wouldn't be usings this program otherwise )
// we can garantee ( from a cold/warm boot ) that memory from 32768 to 40959 will be available
// Probably ! Mwhahaha
//
// anyway a playlist is a collection of 8.3 filenames created on a PC
// 1 filename per line
// must be at least 1 character befor the .ZXM (zx81 midi file)
// must include .ZXM
// Only AlphNumeric allowed NO spaces NO apecial characters
// Only file names NO paths
//
// once playlist is created it is then converted to a .ZPL (zx81 PlayList)
// the playlist file is formated thus :-
//
// filename converted to ZX81 Character codes followed by .ZXM (in ZX81 chzracter codes)
// The highbit ( 128 ) of the M in .ZXM is set this HBT (highbit terminated string)
// is then imediately followed by the next filename in the playlist in the same format
// if and only if no more filenames follow the next byte will be 255 ($ff) in addition
// the entire playlist space 8192 byte will be filled to the end with FF
// note the .ZPL file can be any length between 5 bytes (minimum needed for a 8,3 filename)
// and 8192 bytes ( approx 692 full 8.3 file names , or more if many shorter name are used )
//
// for now only sequential play of playlist will be supported
//
// plans are for random play at some point


//The following routine divides hl by c and places the quotient in hl and the remainder in a

//div_hl_c:
//   xor  a
//   ld   b, 16
//
//_loop:
//   add  hl, hl
//   rla
//   jr   c, $+5
//  cp   c
//   jr   c, $+4
//
//   sub  c
//   inc  l
//
//   djnz _loop
//
//   ret


Plist_ResetAll:
	LD	A,$FF
	LD	DE,$8001
	LD	HL,$8000
	LD	BC,8191
	LD	(HL),A
	LDIR
	LD	HL,$8000
	LD	(Plist_ListPos),HL	//set the playlist position to the start
	LD	HL,( FRAMES)
	LD	( randData),HL


	RET

PlistDisplayText:
	LD	HL,(16396)		//D-file
	LD	DE,133			//5TH LINE
	ADD	HL,DE
	LD	D,H
	LD	E,L
	LD	HL,Plist_TextBuff
	LD	A,8
PlistDisplayTextLoop:
	LD	BC,32
	LDIR
	INC	DE			// skip newline
	DEC	A
	JR	NZ,PlistDisplayTextLoop

	LD	HL,(16396)		//D-file
	LD	DE,75		       //3RD LINE
	ADD	HL,DE
	LD	D,H
	LD	E,L
	LD	HL,Plist_ZpandBuffFname
;        PUSH    DE
;        LD      B,12
;        XOR     A
;PlistBLoop:
;        LD      (DE),A
;        INC     DE
;        DJNZ    PlistBLoop
;        POP     DE
	LD	B,23
PlistDisplayTrackLoop:
	LD	A,(HL)
	AND	$3F		//ENSURE PRINTABLE
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	PlistDisplayTrackLoop

	RET




Plist_OpenMidi:
    LD	  DE,Plist_ZpandOpenMidi	//de points to HBT "OPEN MIDI" string
    CALL  api_zxpandcmd 		//ZXpand API CALL proccesses the tring pointed to be DE
					//returns if all went well
					// else will throw an error
    RET

PList_OpenFile:
    LD	  DE,Plist_ZpandBuff		//DE points to HBT "OPEN FILE filename.ZXM" where the M is HBT
    CALL  api_zxpandcmd
					// as above either it returns or throws an error
    RET

PlistRandomGet:

Random:

	ld	hl,(randData)
	ld	a,r
	ld	d,a
	ld	e,(hl)
	add	hl,de
	add	a,l
	xor	h
	ld	(randData),hl
	AND	$3F	//LIMIT MAX NUMBER
	AND	A	// IF A = 0 NO SKIPS
	LD	b,a	// this is our count
	LD	HL,( Plist_ListPos)
	RET	Z	// A WAS ZERO
	Dec	hl
PlistRandomLoop:
	inc	hl
	LD	A,(HL)
	CP	$FF
	JR	Z,PlistRandomRestartList
	CP	$FE
	JR	Z ,PlistRandomLoop
	BIT	6,A
	JR	Z,PlistRandomLoop   // NO HIT

	DJNZ	PlistRandomLoop     // SKIP UNTIL 0
	LD	( Plist_ListPos),hl
	RET

PlistRandomRestartList:
	LD	HL,$8000
	JR     PlistRandomLoop

Plist_EndHit:

// if we got here and HL == $8000 very likely that playist
// was nt loaded into memory
	LD	A,H
	AND	$7F	// STRIP BIT 7
	OR	l	//
	JR	Z,Plist_GetNext_ErrorName

// should only end up here if the end of the playlist has been reached
// by Plist_GetNect below, Reset Plist_ListPos to the start.
	LD    HL,$8000
	LD    (Plist_ListPos),HL
// And Fall through to Plist_GetNext...
// Effectively makeing the playlist a loop
//
// Still thinking how to implement random


Plist_GetNext:


	ld	a,(random)
	and	a
	call	nz,  PlistRandomGet

// copy the next filename into Plist_ZpandBuff
// doesn't matter if tail of buffer has old content
// as Spand api will stop at the HBT byte.
	LD	DE,Plist_ZpandBuffFname
	xor	a
	ld	b,12
ClearExsistingFname:
	ld	(de),a
	inc	de
	djnz	ClearExsistingFname

	LD	DE,Plist_ZpandBuffFname
	LD	HL,(Plist_ListPos)
	LD	A,(HL)
// check if we are at the end.
	CP	$ff
	JR	Z,Plist_EndHit
	LD	B,13		    // counter for safety but shouldnt be needed !
Plist_GetLoop:
	DEC	B
	JR	Z,Plist_GetLoop_Error // filename too long....
	LD    A,(HL)
	AND   $BF			//strip bit 6 used for random play
	INC   HL
	LD    (DE),A
	INC   DE
	AND   $80
	JR	Z,Plist_GetLoop
//NOW ALWAYS 5 BYTES HOLDING ESTIMATED TRACK TIME
	LD    DE,Plist_TimeBuff
	LDI
	LDI
	LDI
	LDI
	LDI
	CALL  PlistIsText
	LD    (Plist_ListPos),HL		// save pointer
	RET

Plist_GetLoop_Error:
// hopefully we never get here but...
// we are going to step through the playlist looking for the next HBT
// or $ff, if $ff found then we will reset to start of playlist
// otherwise we shall start at the byte immediately folLowing the HBT
	LD	A,(HL)
	INC	HL
	CP	$FF
	JR	Z,Plist_EndHit		// its just occured to me thst it would be possible
					// to end up in an endless loop with s malformed playlist
// else we test for HBT
	and	$80
	JR	Z,Plist_GetLoop_Error
// we have found a HBT MUST CHECK NEXT BYTE FOR $FE
	LD	A,(HL)
	CP	$FE
	JR	NZ, PlistErrorGoodToGo
	INC	HL		   // SKIP OVER $fe
	JR	Plist_GetLoop_Error
PlistErrorGoodToGo:
// so lets go back and try the next entry
	LD	(Plist_ListPos),HL
	JR	Plist_GetNext

Plist_GetNext_ErrorName:
	LD	DE,Plist_ZpandBuff
	LD	HL,Plist_ErrorFilename
	LD	BC,11
	LDIR
	RET

PlistIsText:
// CLEAR BUFFER FIRST
	PUSH	HL
	LD	DE, Plist_TextBuff + 1
	LD	HL, Plist_TextBuff
	LD	BC,255
	XOR	A		// ZERO
	LD	(HL),A
	LDIR

	POP	HL
	LD	A,(HL)
	CP	$FE
	RET	NZ	// NO TEXT FOR THIS FILE
	INC	HL
// COPY HBT TO TEXT BUFFER MAX 64 BYTES
	LD     B,0
	LD     DE, Plist_TextBuff
PlistIsTextLoop:

	LD     A,(HL)
	INC    HL
	BIT    7,A
	JR     NZ,PlistTextLastBtye
	AND    $3F	  //ENSURE CHARACTERS ARE PRINTABLE ON ZX81 DFILE
	LD     (DE),A
	INC    DE
	DJNZ   PlistIsTextLoop

	RET



PlistTextLastBtye:
	AND    $3F	  //ENSURE CHARACTERS ARE PRINTABLE ON ZX81 DFILE
	LD     (DE),A

	RET


Plist_VarBlock:
random:
	db	0
randData:
	DW	0
Plist_ErrorFilename:
	DBZX	222,  'NOPLAYLIS', 185
// this filename will be used if the playlist has not been loaded
// it should cause an error 6 illegal character in filename

Plist_ListPos:
	DW	 $8000
Plist_ZpandBuff:
	DBZX	  'OPEN FILE '
Plist_ZpandBuffFname:
	DB	  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
PADDING:
	DB		0
Plist_TimeBuff:
	DB	0, 0, 0, 0, 0
	db	0
StartPlayTime:
	dbzx  '00:00'
Plist_ZpandOpenMidi:
	DBZX	  'OPEN MID'
	DB	  174
Plist_TextBuff:
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	DB	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0