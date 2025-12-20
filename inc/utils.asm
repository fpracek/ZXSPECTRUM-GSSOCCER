; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** UTILS.ASM ***

; ------ ROUTINES ------




; ---------------------------------------------------------------------------
; Reads keyboard and returns a code if one of the arrows or SPACE is pressed.
; INPUT: -
; OUTPUT:
;   A = KEY_XXX constant, or 0 if no relevant key is pressed
; MODIFIES:
;   AF, BC, HL
; ---------------------------------------------------------------------------

; ------ ROUTINES ------



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
    JP  NC, .ReadKeyboard2   ; If the bit is 0, we've found our key
    INC HL                  ; Go to next table address
    DEC E                   ; Decrement key loop counter
    JP  NZ, .ReadKeyboard1   ; Loop around until this row finished
    DEC D                   ; Decrement row loop counter
    JP  NZ, .ReadKeyboard0   ; Loop around until we are done
    AND A                   ; Clear A (no key found)
    LD  (Var_Utils_LastKbdKeyPressed), A
    RET
.ReadKeyboard2:        
    LD  A, (HL)             ; We've found a key at this point; fetch the character code!
    LD  B, A
    LD  A,(Var_Utils_LastKbdKeyPressed)
    CP  0
    JP  Z, .ReadKeyboard3    ; If no key pressed before, skip the check
    CP  B                   ; Check if the key is the same as the last one pressed
    JP  NZ, .ReadKeyboard3    ; If it is, skip the rest of this routine
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



; --------------------------------------------------
; Play beep
; INPUT: 
;   B: Number of toggles
;   C: Delay loop
; --------------------------------------------------
PlayBeep:
    PUSH BC
    LD   A, 16          ; 0001 0000 → beeper ON
.BeepLoop:
    OUT  (254), A       ; accendi
    CALL DelayHalf
    XOR  A              ; A=0 → beeper OFF
    OUT  (254), A       ; spegni
    CALL DelayHalf
    DEC  B
    JR   NZ, .BeepLoop
    POP  BC
    RET

DelayHalf:
    LD   D, C
.DH:
    DEC  D
    JR   NZ, .DH
    RET




; Genera un beep usando PSG con impostazioni sicure
Utils_PlayBeep:
    ld  b,80        ; durata
    ld  d,24        ; pitch (più basso = più acuto)
    call PlayBeep
    RET

;-----------------------------------------
; Utils_PlayBeepGoalCorner - Beep più acuto (MSX)
; Usa solo canale A, salva/ripristina mixer e volume
;-----------------------------------------
Utils_PlayBeepGoalCorner:
    ld  b,80        ; durata
    ld  d,4         ; pitch (più basso = più acuto)
    call PlayBeep
    RET
Utils_PlayBeepHighLong:
    ;ld  b,80        ; durata
    ;ld  d,10         ; pitch (più basso = più acuto)
    ;call PlayBeep
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
    ld  b,80        ; durata
    ld  d,10         ; pitch (più basso = più acuto)
    call PlayBeep
    RET




; ------------------------------------------------------------
; Utils_ResetBeepTick
; ------------------------------------------------------------
Utils_ResetBeepTick:
    XOR  A
    LD   (Var_Game_BeepStep),A
    RET


