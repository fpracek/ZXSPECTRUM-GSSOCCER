; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** STRING.ASM ***

; ------ ROUTINES ------

;--------------------------------------------------------------------------
; Convert a 16-bit unsigned number to a string of ASCII digits.
; INPUT:
;   HL = the 16-bit unsigned number to convert.
; OUTPUT: -
; MODIFY: HL, DE, BC, AF
;--------------------------------------------------------------------------
String_NumberToASCII:
   LD       BC,-10000
   CALL     .Num1
   LD       BC,-1000
   CALL     .Num1
   LD       BC,-100
   CALL     .Num1
   LD       C,-10
   CALL     .Num1
   LD       C,-1
.Num1:
   LD       A,'0'-1
.Num2:
   INC      A
   ADD      HL, BC
   JP       C, .Num2
   SBC      HL, BC
   LD       (DE), A
   INC      DE
   RET

;---------------------------------------------------------------------
; Remove leading zeros from the string
; INPUT:
;   HL: Pointer to the string
; OUTPUT: -
; MODIFY: HL, AF, BC
;---------------------------------------------------------------------
String_RemoveLeadingZeros:
    CALL    String_GetLength  ; Get the length of the string
    LD      B, A            ; Set B to the number of digits 
.Loop:
    ; Check if we are at the last digit; if so, exit.
    LD      A, B
    CP      1
    RET     Z
    ; Load the current character.
    LD      A, (HL)
    CP      '0'
    RET     NZ  ; If the character is not '0', we've reached the first
                          ; nonzero digit; stop replacing.
    ; Replace the '0' with a space.
    LD       A, ' '
    LD      (HL), A
    INC     HL              ; Advance to the next character.
    DEC     B               ; Decrement the digit counter.
    JP      .Loop



;---------------------------------------------------------------------
; Get the length of a string in bytes
; INPUT:
;   HL: Pointer to the string
; OUTPUT: -
; MODIFY: HL, AF, BC
;---------------------------------------------------------------------
String_GetLength:
    PUSH    HL          ; save HL
    XOR     A           ; A = 0
    LD      B, A        ; B = 0 (length counter)

.Loop:
    LD      A, (HL)     ; load byte
    OR      A           ; set Z if it’s zero
    JP      Z, .Done
    INC     B           ; increment length
    INC     HL
    JP      .Loop

.Done:
    POP     HL          ; restore HL
    LD      A, B        ; return length in A
    RET
