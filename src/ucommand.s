        .include "ucommand.inc"

        .export u2_check
        .export u2_start_cmd
        .export u2_finish_cmd
        .export u2_accept
        .export u2_get_data
        .export u2_get_status

; Check for presence of Ultimate II hardware
; Returns: A - zero if Ultimate II was detected, nonzero otherwise
.proc u2_check
        lda U2_COMMAND_ID
        cmp #U2_DEVICEID
        rts  
.endproc

; Start a command by making sure the ultimate is in the correct state
; Destroys: A
.proc u2_start_cmd
        lda #U2_ERROR
        bit U2_CONTROL_STATUS   ; check error flag
        beq @check_idle         ; no error, do idle check
        sta U2_CONTROL_STATUS   ; error flag is set; clear it
@check_idle:
        lda #U2_STATEMASK       ; check state machine state
        bit U2_CONTROL_STATUS
        beq @finished           ; state is idle, good to go

        ; otherwise, abort current command
        lda #U2_ABORT           ; set the abort bit, returning the
        sta U2_CONTROL_STATUS   ; ultimate to idle state
        lda #U2_STATEMASK       ; check if idle state is reached
@wait_idle:
        bit U2_CONTROL_STATUS
        beq @finished           ; yes. return.
        jmp @wait_idle          ; keep waiting.
@finished:
        rts
.endproc

; Finish a command and return
; Destroys: A
; Returns:  C flag indicates success/failure
;               0 - command was written sucessfully
;               1 - error
.proc u2_finish_cmd
        lda #U2_ERROR
        bit U2_CONTROL_STATUS   ; check error flag
        bne @err                ; error flag is set, return failure
        lda #U2_PUSH            ; push the command
        sta U2_CONTROL_STATUS
@wait_push:                     ; wait for command push to be acknowledged
        bit U2_CONTROL_STATUS
        bne @wait_push
@wait_busy:
        lda #U2_STATEMASK       ; wait for command-busy state to finish
        and U2_CONTROL_STATUS
        cmp #U2_STATE_BUSY
        beq @wait_busy
        clc
        rts
@err:   sec
        rts
.endproc

; Accept received data
; Destroys: A
.proc u2_accept
        lda #U2_ACCEPT          ; set the data-accepted flag
        sta U2_CONTROL_STATUS
@wait:  bit U2_CONTROL_STATUS   ; wait for acknowledgement
        bne @wait
        rts
.endproc

; Read one byte from data channel into A
; Automatically accepts data (and checks for more data) when a block is
; exhausted.
; Returns: A - byte read from data channel (only valid if C is 0 - see below)
;          C flag indicates success/failure:
;               0 = data was successfully read
;               1 = error/no data available     
.proc u2_get_data
        lda #U2_DATA_AVAIL
        bit U2_CONTROL_STATUS   ; is there data?
        beq @nodata             ; no.
        lda U2_RESPONSE_DATA    ; yes. load it.
        clc                     ; return success
        rts
@nodata:
        jsr u2_accept           ; acknowledge current data block
@wait_busy:
        lda U2_CONTROL_STATUS
        and #U2_STATEMASK
        cmp #U2_STATE_BUSY      ; wait for busy state to end
        beq @wait_busy

        cmp #U2_STATE_IDLE      ; have we entered idle state?
        bne u2_get_data         ; no - more data is available
        sec                     ; yes - no more data
        rts
.endproc

; Read one byte from data channel into A
; Returns: A - byte read from status channel (only valid if C is 0 - see below)
;          C flag indicates success/failure:
;               0 = data was successfully read
;               1 = error/no data available   
.proc u2_get_status
        lda #U2_STATUS_AVAIL    ; is there a status?
        bit U2_CONTROL_STATUS
        beq @nostatus           ; no
        lda U2_STATUS_DATA      ; yes. load it.
        clc
        rts
@nostatus:
        sec
        rts
.endproc
