		.include "ucommand.inc"

        .include "geossym.inc"
		.include "geossym2.inc"
        .include "geosmac.inc"
		.include "const.inc"
        .include "jumptab.inc"
        .include "c64.inc"

        .import u2_check, u2_get_data, u2_get_status, u2_accept, u2_start_cmd, u2_finish_cmd

		; like MoveB from geosmac.inc, but converts a BCD source value to a
		; regular byte
		.macro MoveBCD_B source, dest
			lda source
			jsr fromBCD
			sta dest
		.endmacro

		; Size of status/date-string buffer. Must be <= 255 bytes
		BUFSIZE 	= 64

        .segment "STARTUP"
start:
.proc main
		LoadB dispBufferOn, ST_WR_FORE | ST_WR_BACK

		jsr InitForIO

.if !.defined(MOCK)
		; check if 1541U2 is present
        jsr u2_check
        beq @u2_ok

		; No 1541U detected - print error message and bail out
		LoadW r0, errDev
		LoadB lastLine, 0	; Last text line in dialog box is unused here
		jmp @errexit

@u2_ok:	jsr get_time
		bcc @status_ok	; get_time returns with C=0 if command was successful

		; Status channel indicated an error - print error message and bail out.
		LoadW r0, errSt
		jmp @errexit

@status_ok:
.endif
		jsr DoneWithIO
		jsr parse_time
		cpy #6
		beq @parse_ok
		LoadW r0, errDate
		jmp @errexit

@parse_ok:
		; setup CIA#1 time-of-day clock
		jsr InitForIO
		lda mhour
		cmp #$13
		bcc @am
		php
		sei
		sed
		sbc #$12
		plp
		ora #$80		; high bit of CIA hour register is AM/PM flag
@am:	sta CIA1_TODHR
		MoveB mmin, CIA1_TODMIN
		MoveB msec, CIA1_TODSEC
		LoadB CIA1_TOD10, 0
		jsr DoneWithIO

		; convert from BCD and setup local time
		MoveBCD_B msec, seconds
		MoveBCD_B mmin, minutes
		MoveBCD_B mhour, hour
		MoveBCD_B mday, day
		MoveBCD_B mmonth, month
		MoveBCD_B myear, year

		jmp EnterDeskTop

@errexit:
		jsr DoneWithIO

		; Copy error message string at (r0) to end of "ERROR: " text
		ldx #r0
		ldy #r1
		LoadW r1, errinfo
		jsr CopyString

		LoadW r0, errDlg
		jsr DoDlgBox
		jmp EnterDeskTop
.endproc

		.segment "CODE"

; read time and date from 1541U2
; If command was successful, returns with carry flag clear, buf contains
; the time/date string.
; If an error occurred, returns with carry flag set, buf contains the error
; message.
.proc get_time
		jsr u2_start_cmd
		lda #$01
		sta U2_COMMAND_ID
        lda #$26            ; 0x26 = DOS_CMD_GET_TIME
        sta U2_COMMAND_ID
        lda #$00            ; 0x00 = format = YYYY/MM/DD HH:MM:SS
        sta U2_COMMAND_ID
        jsr u2_finish_cmd

		; read from status channel first
        ldx #0
@loop1: jsr u2_get_status
        bcs @end1
        sta buf, x
        inx
        cpx #BUFSIZE-1
        bcc @loop1
@end1:  lda #0
		sta buf, x
		
		; first 2 bytes of status are the return code as ASCII digits. Anything
		; other than '00' is an error
		lda buf
		cmp #'0'
		bne @bad
		lda buf+1
		cmp #'0'
		beq @ok
@bad:	sec
		rts

		; All good, read the data channel
@ok:    ldx #0
@loop2: jsr u2_get_data
        bcs @end2
        sta buf, x
        inx
        cpx #BUFSIZE-1
        bcc @loop2
		clc
@end2:	lda #0
		sta buf, x
		clc
		rts
.endproc

; Parse a YYYY/MM/DD HH:MM:SS string in buf, into consecutive BCD bytes
; Destroys a0L
; Returns number of characters consumed in X, number of values read in Y
.proc parse_time
        ldx #2			; first 2 chars of date string are the century, skip them
		ldy #0
@loop:
		lda buf, x
		beq @end		; give up if we hit a NULL
		sec
		sbc #'0'
		bmi @no			; skip character if not a digit
		cmp #10
		bcs @no
		asl				; first char is tens, shift to upper nibble
		asl
		asl
		asl
        sta a0L
        inx
        lda buf, x		; assume second char is a digit
		sec
		sbc #$30
		ora a0L			; OR in saved upper nibble
		sta myear, y	; store value 
		iny
@no:	inx
		cpy #6			; read 6 values
		bne @loop
@end:   rts
.endproc

; convert BCD in A, output in A. Destroys Y
.proc fromBCD
		pha
		lsr
		lsr
		lsr
		lsr
		tay
		pla
		and #$0f
		clc
@loop:	dey
		bmi @end
		adc #10
		bne @loop
@end:	rts
.endproc

		.segment "DATA"

; Dialog box definition for error messages
errDlg:	.byte DEF_DB_POS | 1	; default posiiton, using pattern 1 for shadow
		.byte DBSYSOPV			; close dialog on ENTER key or any click
		.byte OK
			.byte TXT_LN_X
			.byte TXT_LN_4_Y
		.byte DBTXTSTR
			.byte TXT_LN_X
			.byte TXT_LN_1_Y
			.addr title
		.byte DBTXTSTR
			.byte TXT_LN_X
			.byte TXT_LN_2_Y
			.addr errMsg
lastLine:						; Not all messages need or want to print the contents of buf
		.byte DBTXTSTR			; write a 0 to this label to suppress it
			.byte TXT_LN_X
			.byte TXT_LN_3_Y
			.addr buf
		.byte 0

; Strings for above dialox box
title: 	.byte BOLDON, "1541 Ultimate II RTC", PLAINTEXT, 0
errMsg: .byte BOLDON, "ERROR: ", PLAINTEXT

; Error handler moves one of the below strings up to concatenate it with the
; "ERROR: " text above.
errinfo:
errDate:.byte "Unable to parse date:", 0
errDev:	.byte "Device not detected.", 0
errSt:	.byte "Device status:", 0

		.segment "BSS"
myear:	.byte 0
mmonth: .byte 0
mday:   .byte 0
mhour:  .byte 0
mmin:	.byte 0
msec:	.byte 0

.if !.defined(MOCK)
buf:	.res BUFSIZE
.else
		.segment "DATA"
		.define MOCKDATE "2019/06/12 20:48:04"
buf:	.byte MOCKDATE, 0
		.res BUFSIZE - .strlen(MOCKDATE)
.endif
