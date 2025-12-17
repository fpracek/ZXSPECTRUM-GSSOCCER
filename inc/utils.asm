; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** UTILS.ASM ***

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
   JR       C, .Num2
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
    JR      .Loop


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
    JR      Z, .Done
    INC     B           ; increment length
    INC     HL
    JR      .Loop

.Done:
    POP     HL          ; restore HL
    LD      A, B        ; return length in A
    RET



; ---------------------------------------------------------------------------
; Reads keyboard and returns a code if one of the arrows or SPACE is pressed.
; INPUT: -
; OUTPUT:
;   A = KEY_XXX constant, or 0 if no relevant key is pressed
; MODIFIES:
;   AF, BC, HL
; ---------------------------------------------------------------------------

; ------ ROUTINES ------




;------------------------------------------------------------------------
; Read the keyboard
; INPUT: -
; OUTPUT:
;   A: ASCII code of key pressed
; MODIFY: HL, BC, AF
;------------------------------------------------------------------------
Utils_ReadKeyboard:          
    LD  HL,KEYBOARD_MAP     ; Point HL at the keyboard list
    LD  D, 8                ; This is the number of ports (rows) to check
    LD  C, #FE              ; C is always FEh for reading keyboard ports
.ReadKeyboard0:        
    LD  B, (HL)             ; Get the keyboard port address from table
    INC HL                  ; Increment to list of keys
    IN  A, (C)              ; Read the row of keys in
    AND #1F                 ; We are only interested in the first five bits
    LD  E, 5                ; This is the number of keys in the row
.ReadKeyboard1:        
    SRL A                   ; Shift A right; bit 0 sets carry bit
    JR  NC, .ReadKeyboard2   ; If the bit is 0, we've found our key
    INC HL                  ; Go to next table address
    DEC E                   ; Decrement key loop counter
    JR  NZ, .ReadKeyboard1   ; Loop around until this row finished
    DEC D                   ; Decrement row loop counter
    JR  NZ, .ReadKeyboard0   ; Loop around until we are done
    AND A                   ; Clear A (no key found)
    LD  (Var_Utils_LastKbdKeyPressed), A
    RET
.ReadKeyboard2:        
    LD  A, (HL)             ; We've found a key at this point; fetch the character code!
    LD  B, A
    LD  A,(Var_Utils_LastKbdKeyPressed)
    CP  0
    JR  Z, .ReadKeyboard3    ; If no key pressed before, skip the check
    CP  B                   ; Check if the key is the same as the last one pressed
    JR  NZ, .ReadKeyboard3    ; If it is, skip the rest of this routine
    XOR A               ; If it is the same, clear A (no key found)
    RET
.ReadKeyboard3:
    LD  A, B
    LD  (Var_Utils_LastKbdKeyPressed), A
    LD  (Var_Utils_KbdKeyPressed), A
    RET


;------------------------------------------------------------------------
; Utils_GetRandomNumber
; OUTPUT: A = 0..127  (uniforme-ish)
; MODIFIES: A, BC
;------------------------------------------------------------------------
Utils_GetRandomNumber:
    LD   A,(Var_Utils_OldRnd)
    LD   C,A

    ; s = s*33 + R  (33 = 32 + 1)
    ADD  A,A         ; 2
    ADD  A,A         ; 4
    ADD  A,A         ; 8
    ADD  A,A         ; 16
    ADD  A,A         ; 32
    ADD  A,C         ; *33
    LD   C,A
    LD   A,R
    ADD  A,C

    LD   (Var_Utils_OldRnd),A
    AND  127         ; 0..127
    RET





; Genera un beep usando PSG con impostazioni sicure
Utils_PlayBeep:
    RET

;-----------------------------------------
; Utils_PlayBeepGoalCorner - Beep più acuto (MSX)
; Usa solo canale A, salva/ripristina mixer e volume
;-----------------------------------------
Utils_PlayBeepGoalCorner:
    RET









; ------------------------------------------------------------
; Var_Game_BeepStep (BYTE in RAM) - definiscila tu nel tuo blocco variabili
; Var_Game_BeepStep: DB 0
; ------------------------------------------------------------


; ------------------------------------------------------------
; Utils_PlayBeepTick
; Un solo beep breve (ta).
; Ogni chiamata usa il prossimo periodo: 250,235,220,205 (ciclico)
; Suono più simile al BASIC: micro-decay 12->8->0 + tiny delay
; ------------------------------------------------------------
Utils_PlayBeepTick:
    RET


; ------------------------------------------------------------
; Utils_PlayBeepHighLong
; Un beep singolo più acuto e più lungo (taaaa).
; Anche qui micro-decay per avvicinarsi al BASIC.
; ------------------------------------------------------------
Utils_PlayBeepHighLong:
    RET


; ------------------------------------------------------------
; Utils_ResetBeepTick
; ------------------------------------------------------------
Utils_ResetBeepTick:
    XOR  A
    LD   (Var_Game_BeepStep),A
    RET




; ------------------------------------------------------------
; Tabelle
; ------------------------------------------------------------
Utils_BeepPeriods4:
    DW 250,235,220,205


; ------ CONSTANTS ------
KBD_KEY_NONE    EQU 0
KBD_KEY_SPACE   EQU 32

KBD_KEY_UP      EQU 55
KBD_KEY_DOWN    EQU 54
KBD_KEY_LEFT    EQU 53
KBD_KEY_RIGHT   EQU 56

KBD_KEY_W       EQU 87
KBD_KEY_A       EQU 65
KBD_KEY_S       EQU 83


KBD_KEY_J       EQU 74
KBD_KEY_K       EQU 75
KBD_KEY_I       EQU 73