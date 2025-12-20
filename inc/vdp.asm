; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** SCREEN.ASM (sjasm-normalized, buffered & fast VRAM I/O) ***


;------------------------------------------------------------------------
; Print string
; INPUT:  HL = pointer to null-terminated string
;         D,E = character position (Y,X)
;------------------------------------------------------------------------
VDP_PrintString:
    ld      a,(hl)
    or      a
    ret     z
    push    af
    call    VDP_PrintRomChar
    pop     af
    inc     e
    inc     hl
    jr      VDP_PrintString


;------------------------------------------------------------------------
; Print a single RAM character out to a screen address
; INPUT:
;   A: Character to print
;   D: Character Y position
;   E: Character X position
; OUTPUT: -
; MODIFIES: -
;------------------------------------------------------------------------
VDP_PrintRamChar:    
        PUSH    DE
        PUSH    AF
        CP      TILE_BALL_BOTTOM
        JP      C, .AfterColorCheck
        LD      A, GREEN_CHAR_ATTRIBUTE
        CALL    VDP_SetCharAttribute
.AfterColorCheck:
        POP     AF
        POP     DE





        PUSH    DE
        EXX                                 ; Backup registers BC, DE, HL
        POP     DE
        PUSH    AF
        LD      HL, RAM_CHAR_SET_ADDRESS    ; Character set bitmap data in ROM
        LD      B,0                         ; BC = character code
        LD      C, A
        SLA     C                           ; Multiply by 8 by shifting
        RL      B
        SLA     C
        RL      B
        SLA     C
        RL      B
        ADD     HL, BC                      ; And add to HL to get first byte of character
        CALL    GetCharAddress              ; Get screen position in DE
        LD      B,8                         ; Loop counter - 8 bytes per character
.PrintRamCharL1:          
        LD      A,(HL)                      ; Get the byte from the ROM into A
        LD      (DE),A                      ; Stick A onto the screen
        INC     HL                          ; Goto next byte of character
        INC     D                           ; Goto next line on screen
        DJNZ    .PrintRamCharL1              ; Loop around whilst it is Not Zero (NZ)
        EXX                                 ; Restore registers BC, DE, HL
        POP     AF
        RET
;------------------------------------------------------------------------
; Print a single ROM character out to a screen address
; INPUT:
;   A: Character to print
;   D: Character Y position
;   E: Character X position
; OUTPUT: -
; MODIFIES: -
;------------------------------------------------------------------------
VDP_PrintRomChar:          
        PUSH    DE
        EXX                                 ; Backup registers BC, DE, HL
        POP     DE
        PUSH    AF
        LD      HL, ROM_CHAR_SET_ADDRESS    ; Character set bitmap data in ROM
        LD      B,0                         ; BC = character code
        SUB     32                          ; Adjust for the character set
        LD      C, A
        SLA     C                           ; Multiply by 8 by shifting
        RL      B
        SLA     C
        RL      B
        SLA     C
        RL      B
        ADD     HL, BC                      ; And add to HL to get first byte of character
        CALL    GetCharAddress              ; Get screen position in DE
        LD      B,8                         ; Loop counter - 8 bytes per character
.PrintRomCharL1:          
        LD      A,(HL)                      ; Get the byte from the ROM into A
        LD      (DE),A                      ; Stick A onto the screen
        INC     HL                          ; Goto next byte of character
        INC     D                           ; Goto next line on screen
        DJNZ    .PrintRomCharL1              ; Loop around whilst it is Not Zero (NZ)
        EXX                                 ; Restore registers BC, DE, HL
        POP     AF
        RET

;------------------------------------------------------------------------
; Get screen address from a character (X,Y) coordinate
; INPUT:
;   D: Y character position (0-23)
;   E: X character position (0-31)
; OUTPUT:
;   DE: screen address 
; MODIFIES: A
;------------------------------------------------------------------------
GetCharAddress:       
        LD      A,D
        AND     %00000111
        RRA
        RRA
        RRA
        RRA
        OR      E
        LD      E,A
        LD      A,D
        AND     %00011000
        OR      %01000000
        LD      D,A
        RET    

;------------------------------------------------------------------------
; Load tiles from ROM to VRAM 
;------------------------------------------------------------------------
VDP_LoadTiles:
    DI                      ; Interrupts disabled
    LD      DE, RAM_CHAR_SET_ADDRESS   
    LD      HL, TILES   
    LD      BC, 1792
    LDIR
    ;EI                      ; Interrupts enabled
    RET
;------------------------------------------------------------------------
; Clear screen (INVARIATA)
;------------------------------------------------------------------------
VDP_ClearScreen:
    LD   A, 0           ; 0 in the lower 3 bits = black
    OUT  (254), A       ; Send A to port 0xFE
    
    ;----------------------------------------------------------
    ; Clear 6144 bytes of screen pixel area (0x4000..0x57FF)
    ;----------------------------------------------------------
    
    LD   HL, 0x4000      ; Start address of pixel area
    LD   DE, 0x4001      ; DE = HL + 1 for LDIR
    LD   BC, 6144        ; Number of bytes to clear
    LD   (HL), 0         ; Store 0 in the first byte
    LDIR                 ; Repeats until BC = 0 (fills with 0)
    
    ;----------------------------------------------------------
    ; Fill 768 bytes of attributes area (0x5800..0x5AFF)
    ; with 0x07 (white on black)
    ;----------------------------------------------------------
    
    LD   HL, 0x5800      ; Start address of attributes area
    LD   DE, 0x5801      ; DE = HL + 1 for LDIR
    LD   BC, 768         ; Number of attribute bytes
    LD   (HL), 0x07      ; Attribute = 0x07 (white on black)
    LDIR                 ; Fill the attribute area with 0x07
    
    RET






; -----------------------------------------------------------
; Draw sprite (32x32 tile)  
; INPUT: D = row (Y), E = col (X), A = tile index
; -----------------------------------------------------------
VDP_DrawSprite:
    PUSH    AF
    ld      a,d
    add     a,a          ; *2
    add     a,a          ; *4
    ld      d,a

    ld      a,e
    add     a,a          ; *2
    add     a,a          ; *4
    ld      e,a
    inc     e
    inc     d
    ld      a, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JP      Z, .NorthSideAdjust
    inc     d
    inc     d
.NorthSideAdjust:
    POP     AF
    ld      c,a
    cp      TILE_CORNER_BALL_EMPTY
    jr      z,.CornerBallArea
    cp      TILE_CORNER
    jr      z,.CornerBallArea
    cp      TILE_BALL_TOP
    jr      z,.TopBall
    cp      TILE_BALL_TOP_FRONT
    jr      z,.TopBallFront
    cp      TILE_CORNER_BALL
    jr      nz,.TileField

.CornerBallArea:
    ld      a,d
    cp      1
    jr      nz,.CornerBallEmptyBottom
    ld      d,2
    jr      .CornerBallEmptySide
.CornerBallEmptyBottom:
    ld      d,21
.CornerBallEmptySide:
    inc     e
    ld      a,c
    cp      TILE_CORNER_BALL_EMPTY
    jr      z,.CornerBallEmptyTile
    cp      TILE_CORNER
    jr      z,.CornerBallEmptyTile
    jr      .TileField
.CornerBallEmptyTile:
    ld      a,111
    call    VDP_PrintRamChar
    inc     e
    ld      a,111
    call    VDP_PrintRamChar
    ret
.TileField:
    cp      TILE_FIELD
    jp      nz,.CornerBall

    push    de
    push    af
    push    bc
    push    hl

    ld      h,d
    ld      l,e
    ld      b,d
    inc     b
    inc     b
    inc     b
    inc     b
    ld      c,e
    inc     c
    inc     c
    inc     c
    inc     c

.EmptyRowLoop:
    ld      a,d
    cp      b
    jp      z,.EmptyExit

    ld      e,l
.EmptyColLoop:
    ld      a,e
    cp      c
    jp      z,.EmptyNextRow

    ld      a,TILE_FIELD
    call    VDP_PrintRamChar
    inc     e
    jp      .EmptyColLoop

.EmptyNextRow:
    inc     d
    jp      .EmptyRowLoop

.EmptyExit:
    pop     hl
    pop     bc
    pop     af
    pop     de
    ret

.CornerBall:
    cp      TILE_CORNER_BALL
    jr      nz,.Dispatch
    ld      a,77
    call    VDP_PrintRamChar
    inc     e
    ld      a,78
    call    VDP_PrintRamChar
    ret

.TopBall:
    cp      TILE_BALL_TOP
    jr      nz,.Dispatch
    ld      a,77
    call    VDP_PrintRamChar
    inc     e
    ld      a,78
    call    VDP_PrintRamChar
    ret

.TopBallFront:
    cp      TILE_BALL_TOP_FRONT
    jr      nz,.Dispatch
    inc     e
    ld      a,77
    call    VDP_PrintRamChar
    inc     e
    ld      a,78
    call    VDP_PrintRamChar
    ret

; ---------- dispatcher ----------
.Dispatch:
    cp      TILE_WHITE_PLAYER
    jp      z,.MaybeWhiteHalfLine
    cp      TILE_WHITE_PLAYER_NEAR_HALF_FIELD
    jp      z,.MaybeWhiteHalfLine
    cp      TILE_WHITE_PLAYER_WITH_BALL
    jp      z,.DrawWhiteWithFeetBall
    cp      TILE_BLACK_PLAYER_WITH_BACK_BALL
    jp      z,.DrawBlackWithBackBall
    jp      .BaseDraw

; ---------- white: “testa nella metà campo” ----------
.MaybeWhiteHalfLine:
    cp      TILE_WHITE_PLAYER_NEAR_HALF_FIELD
    jr      z, .MaybeWhiteHalfLineContinue
    ld      a, (Var_Game_ActiveFieldSide)
    CP      FIELD_SOUTH_SIDE
    JP      NZ, .MaybeWhiteHalfLineNorth
    LD      A,D
    CP      7
    JP      NZ, .DrawWhiteBaseNormal
    JP      .MaybeWhiteHalfLineContinue
.MaybeWhiteHalfLineNorth:
    LD      A,D
    CP      17
    JP      NZ, .DrawWhiteBaseNormal
.MaybeWhiteHalfLineContinue:
    push    de
    ;ld      d,b
    ld      a,e
    inc     a
    ld      e,a
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    inc     e
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    pop     de
    inc     d
    ld      a,TILE_WHITE_PLAYER_NEAR_HALF_FIELD
    jp      .BaseDraw
    dec     d
.DrawWhiteBaseNormal:
    ld      a,TILE_WHITE_PLAYER
    jp      .BaseDraw

; ---------- white con palla ai piedi ----------
.DrawWhiteWithFeetBall:
    ld      a,(Var_Vdp_HalfFieldHorzLinePos)
    ld      b,a
    ld      a,d
    dec     a
    cp      b
    jr      nz,.NoHalf

    push    de
    ld      d,b
    ld      a,e
    inc     a
    ld      e,a
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    inc     e
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    pop     de

.NoHalf:
    ld      a,c
    cp      TILE_WHITE_PLAYER_WITH_BALL
    jr      z,.Half

    ld      a,TILE_WHITE_PLAYER
    call    .BaseDraw

    push    de
    ld      a,d
    add     a,3
    ld      d,a
    ld      a,e
    add     a,2
    ld      e,a
    dec     e
    ld      a,TILE_WHITE_PLAYER_AND_BALL
    call    VDP_PrintRamChar
    inc     e
    ld      a,TILE_BALL_FEET_OVERLAY_R
    call    VDP_PrintRamChar
    pop     de
    ret

.Half:
    push    de
    ld      a,d
    add     a,3
    ld      d,a
    ld      a,e
    add     a,2
    ld      e,a
    dec     e
    ld      a,TILE_WHITE_PLAYER_AND_BALL
    dec     d
    call    VDP_PrintRamChar
    inc     e
    ld      a,TILE_BALL_FEET_OVERLAY_R
    call    VDP_PrintRamChar
    pop     de
    ret

; ---------- nero con palla alle spalle ----------
.DrawBlackWithBackBall:
    ld      a,TILE_BLACK_PLAYER
    call    .BaseDraw

    push    de
    ld      a,e
    cp      31
    jp      z,.WBack_Done
    ld      a,TILE_BALL_BACK_OVERLAY_L
    call    VDP_PrintRamChar
    inc     e
    ld      a,TILE_BALL_BACK_OVERLAY_R
    call    VDP_PrintRamChar
.WBack_Done:
    pop     de
    ret

; ---------- routine di base: disegna 4x4 a partire da A ----------
.BaseDraw:
    push    de
    push    af

    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar

    inc     d
    dec     e
    dec     e
    dec     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar

    inc     d
    dec     e
    dec     e
    dec     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    ld      (Var_VdpTemp), a
    pop     af
    push    af
    cp      TILE_WHITE_PLAYER_NEAR_HALF_FIELD
    JR      Z, .HalfLineRedraw
    ld      a, (Var_VdpTemp)
    inc     d
    dec     e
    dec     e
    dec     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
    inc     e
    inc     a
    call    VDP_PrintRamChar
.HalfLineRedraw:
    PUSH    HL
    PUSH    BC
    call    .HalfFieldRowRedraw
    POP     BC
    POP     HL
    pop     af
    pop     de
    
    ret
.HalfFieldRowRedraw:
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      NZ, .HalfFieldRowRedrawSouth
    LD      D, 4
    LD      A, D
    ADD     A, A
    ADD     A, A
    LD      B, A
.HalfFieldRowRedrawDone:
    LD      E, 0
.HalfFieldRowRedrawDoneColsLoop:
    PUSH    DE
    PUSH    DE
    PUSH    BC
    CALL    Game_GetPlayerInfoByPos
    POP     BC
    POP     DE
    CP      NO_VALUE
    JR      NZ, .HalfFieldRowRedrawDoneColsLoopContinue
    LD      D, B
    LD      A, E
    ADD     A, A
    ADD     A, A
    LD      E, A
    INC     D
    INC     E
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    PUSH    BC
    CALL    VDP_PrintRamChar
    POP     BC
    INC     E
    PUSH    BC
    CALL    VDP_PrintRamChar
    POP     BC
    INC     E
    PUSH    BC
    CALL    VDP_PrintRamChar
    POP     BC
    INC     E
    PUSH    BC
    CALL    VDP_PrintRamChar
    POP     BC
.HalfFieldRowRedrawDoneColsLoopContinue:
    POP     DE
    INC     E
    LD      A, E
    CP      4
    RET     Z
    JR      .HalfFieldRowRedrawDoneColsLoop
.HalfFieldRowRedrawSouth:
    LD      D, 1
    LD      A, D
    ADD     A, A
    ADD     A, A
    LD      B, A
    INC     B
    INC     B
    JP      .HalfFieldRowRedrawDone


; -----------------------------------------------------------
; Fill game field area to green
; -----------------------------------------------------------
FillGameFieldAreaToGreen:
    push    af
    push    bc
    push    de
    push    hl
    
    ld      d, 0
    
.Row:
    push    de
    ld      e, 1
.Col:
    push    de
    ld      a, TILE_FIELD
    call    VDP_PrintRamChar
    pop     de
    inc     e
    ld      a, e
    cp      21
    jr      z, .NextRow
    jr      .Col
.NextRow:
    pop     de
    inc     d
    ld      a, d
    cp      24
    jr      z, .Done
    jr     .Row
.Done:
    pop     hl
    pop     de
    pop     bc
    pop     af
    ret



;------------------------------------------------------------------------
; Set screen charater attribute
; INPUT:
;   A: Value
;   D: Character Y position
;   E: Character X position
; OUTPUT: -
; MODIFIES: HL
;------------------------------------------------------------------------
VDP_SetCharAttribute:
        PUSH    DE
        PUSH    HL
        PUSH    BC
        PUSH    AF
        LD      A, D    ; Load row in A
        ; Before keeping the bits of the third, we carry out the rotations
        RRCA
        RRCA         ; Passes the bits of the third to bits 0 and 1
        RRCA         ; and those of the row to bits 5, 6 and 7
        LD      L, A    ; Load the result in L
        AND     0x03     ; A = bits of the third
        OR      0x58     ; Adds the fixed bits of the high part of the address
        LD      H, A    ; H = 0101 10TT
        LD      A, L   ; A = row in bits 5, 6 and 7 and third in bits 0 and 1
        AND     0xE0     ; Keeps the bits of the line
        OR      E       ; Adds the bits of the column
        LD      L, A    ; L = RRRC CCCC
        POP     AF
        LD      (HL),A          ; Scrivi l'attributo
        CP      0xFF
        JP      NZ, SetAttributeAtDE_1

        LD      (HL),20
SetAttributeAtDE_1:
        

        
        POP     BC
        POP     HL
        POP     DE
        RET

; -----------------------------------------------------------
; Draw field
; -----------------------------------------------------------
VDP_DrawField:

    call    FillGameFieldAreaToGreen
    ld      a,0
.VLinesLoop:
    push    af
    ld      d,a
    ld      e,0
    ld      a,TILE_FIELD_LINE_VERTICAL
    ld      c,1
    call    VDP_PrintRamChar

    ld      e,21               
    ld      a,TILE_FIELD_LINE_VERTICAL
    ld      c,1
    call    VDP_PrintRamChar

    pop     af
    inc     a
    cp      24
    jr      nz,.VLinesLoop



 
    ld      a,(Var_Game_ActiveFieldSide)
    cp      FIELD_NORTH_SIDE
    jp      z,.North

; ---------- SOUTH ----------
.South:
    ; pulizia angoli interni
    ld   d,23
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,22
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,21
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,20
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,23
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,22
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,21
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,20
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar

    ; angoli e montanti
    ld   d,19
    ld   e,0
    ld   a,TILE_FIELD_LINE_BOTTOM_LEFT
    call VDP_PrintRamChar
    ld   d,19
    ld   e,21
    ld   a,TILE_FIELD_LINE_BOTTOM_RIGHT
    call VDP_PrintRamChar
    ld   d,23
    ld   e,4
    ld   a,TILE_FIELD_LINE_BOTTOM_LEFT
    call VDP_PrintRamChar
    ld   d,23
    ld   e,17
    ld   a,TILE_FIELD_LINE_BOTTOM_RIGHT
    call VDP_PrintRamChar
    ld   d,19
    ld   e,4
    ld   a,TILE_FIELD_LINE_TOP_RIGHT
    call VDP_PrintRamChar
    ld   d,19
    ld   e,17
    ld   a,TILE_FIELD_LINE_TOP_LEFT
    call VDP_PrintRamChar

    ; montanti verticali
    ld   d,20
    ld   e,17
    ld   a,TILE_FIELD_LINE_VERTICAL
    ld   c,1
    call VDP_PrintRamChar
    ld   d,21
    ld   a,TILE_FIELD_LINE_VERTICAL
    ld   c,1
    call VDP_PrintRamChar
    ld   d,22
    ld   a,TILE_FIELD_LINE_VERTICAL
    ld   c,1
    call VDP_PrintRamChar
    ld   d,20
    ld   e,4
    ld   a,TILE_FIELD_LINE_VERTICAL
    ld   c,1
    call VDP_PrintRamChar
    ld   d,21
    ld   e,4
    ld   a,TILE_FIELD_LINE_VERTICAL
    ld   c,1
    call VDP_PrintRamChar
    ld   d,22
    ld   e,4
    ld   a,TILE_FIELD_LINE_VERTICAL
    ld   c,1
    call VDP_PrintRamChar

    ; segmenti orizzontali
    ld   d,19
    ld   e,1
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,2
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,3
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,18
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,19
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,20
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   d,23
    ld   e,5
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,6
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,7
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,8
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,9
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,10
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,11
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,12
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,13
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,14
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,15
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,16
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar

    ; croci
    ld   d,7
    ld   e,0
    ld   a,TILE_FIELD_LINE_LEFT_CROSS
    call VDP_PrintRamChar
    ld   e,21
    ld   a,TILE_FIELD_LINE_RIGHT_CROSS
    call VDP_PrintRamChar

    ; metà campo (riga 6): da col 1 a 20
    ld   a,1
.SouthLoop:
    ld   d,7
    push af
    ld   e,a
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    ld   c,1
    call VDP_PrintRamChar
    pop  af
    inc  a
    cp   21
    jr   nz,.SouthLoop
    jp   .Done
.North:
    ld   d,0
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,1
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,2
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,3
    ld   e,0
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,0
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,1
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,2
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar
    ld   d,3
    ld   e,21
    ld   a,TILE_FIELD
    call VDP_PrintRamChar

    ; angoli e montanti
    ld   d,4
    ld   e,0
    ld   a,TILE_FIELD_LINE_TOP_LEFT
    call VDP_PrintRamChar
    ld   d,4
    ld   e,21
    ld   a,TILE_FIELD_LINE_TOP_RIGHT
    call VDP_PrintRamChar
    ld   d,0
    ld   e,4
    ld   a,TILE_FIELD_LINE_TOP_LEFT
    call VDP_PrintRamChar
    ld   d,0
    ld   e,17
    ld   a,TILE_FIELD_LINE_TOP_RIGHT
    call VDP_PrintRamChar
    ld   d,4
    ld   e,4
    ld   a,TILE_FIELD_LINE_BOTTOM_RIGHT
    call VDP_PrintRamChar
    ld   d,4
    ld   e,17
    ld   a,TILE_FIELD_LINE_BOTTOM_LEFT
    call VDP_PrintRamChar

    ; montanti verticali
    ld   d,1
    ld   e,17
    ld   a,TILE_FIELD_LINE_VERTICAL
    call VDP_PrintRamChar
    ld   d,2
    ld   e,17
    ld   a,TILE_FIELD_LINE_VERTICAL
    call VDP_PrintRamChar
    ld   d,3
    ld   e,17
    ld   a,TILE_FIELD_LINE_VERTICAL
    call VDP_PrintRamChar
    ld   d,1
    ld   e,4
    ld   a,TILE_FIELD_LINE_VERTICAL
    call VDP_PrintRamChar
    ld   d,2
    ld   e,4
    ld   a,TILE_FIELD_LINE_VERTICAL
    call VDP_PrintRamChar
    ld   d,3
    ld   e,4
    ld   a,TILE_FIELD_LINE_VERTICAL
    call VDP_PrintRamChar

    ; segmenti orizzontali
    ld   d,4
    ld   e,1
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,2
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,3
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,18
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,19
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,20
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   d,0
    ld   e,5
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   d,0
    ld   e,6
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   d,0
    ld   e,7
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,8
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,9
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,10
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,11
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,12
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,13
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,14
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,15
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ld   e,16
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    call VDP_PrintRamChar
    ; croci
    ld   d,17
    ld   e,0
    ld   a,TILE_FIELD_LINE_LEFT_CROSS
    call VDP_PrintRamChar
    ld   e,21
    ld   a,TILE_FIELD_LINE_RIGHT_CROSS
    call VDP_PrintRamChar

    ; metà campo (riga 17): da col 1 a 20
    ld   a,1
.NorthLoop:
    ld   d,17
    push af
    ld   e,a
    ld   a,TILE_FIELD_LINE_HORIZONTAL
    ld   c,1
    call VDP_PrintRamChar
    pop  af
    inc  a
    cp   21
    jr   nz, .NorthLoop
.Done:
    ;POP  AF
    ;OR   01000000b      ; forza display ON (bit 6 = 1) indipendentemente dal valore letto
    ;LD   C, 1
    ;CALL VDP_SetReg
    ;POP  BC
    ;POP  AF
    RET

; ---------------------------------------------------------
; Rimuove il giocatore virtuale dallo schermo (se visibile)
; ---------------------------------------------------------
VDP_RemoveVirtualPlayer:
    LD      A,(Var_Game_VirtualPlayerYPos)
    CP      255
    RET     Z
    LD      D, A
    LD      A,(Var_Game_VirtualPlayerXPos)
    LD      E, A
    LD      A, TILE_FIELD
    CALL    VDP_DrawSprite
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_SOUTH_SIDE
    JR      NZ, .Done
    LD      A, (Var_Game_VirtualPlayerXPos)
    CP      4
    JR      NZ, .Done
    LD      D, 7
    LD      E, 17
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 18
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 19
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 20
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
.Done:
    LD  A, 255
    LD  (Var_Game_VirtualPlayerYPos), A
    RET
; ---------------------------------------------------------
; Disegno del giocatore virtuale (se visibile)
; ---------------------------------------------------------
VDP_PlayerMatrixRedraw_DrawVirtual:
    ; se Y = 255 → non disegnare
    ld   a,(Var_Game_VirtualPlayerYPos)
    cp   255
    jr   z,VDP_PlayerMatrixRedraw_Done   ; salta se invisibile

    ; D = Y, E = X (coordinate di matrice 0..4)
    ld   d,a                             ; D = Y
    ld   a,(Var_Game_VirtualPlayerXPos)
    ld   e,a                             ; E = X

    ; salviamo i registri che useremo
    push af
    push bc
    push de
    push hl

    ; scegli il tile in base alla squadra virtuale
    ld   a,(Var_Game_VirtualPlayerTeam)
    cp   TEAM_BLACK
    jr   nz,.VirtWhite

    ; squadra nera → usa giocatore nero
    ld   a,TILE_BLACK_PLAYER
    jr   .VirtHaveTile

.VirtWhite:
    ; squadra bianca → usa giocatore bianco
    ld   a,TILE_WHITE_PLAYER

.VirtHaveTile:
    ; mappa (D,E) -> coordinate schermo in (D,E)
    PUSH  AF
    POP   AF
    ; A = tile di base, D,E = row/col → disegna lo sprite
    call VDP_DrawSprite

    ; ripristina registri
    pop  hl
    pop  de
    pop  bc
    pop  af

VDP_PlayerMatrixRedraw_Done:
    ; qui metti i tuoi:
    ; POP HL
    ; POP DE
    ; POP BC
    ; POP AF
     RET

;----------------------------------------------------------------------------
;  Sets VDP register
;----------------------------------------------------------------------------
VDP_SetReg:
    ; In: A = value, C = reg#
    ; Usa la porta VDP control: 99h

    push af
    in   a,(099h)        ; reset latch (riallinea first/second write)
    pop  af

    out  (099h),a        ; value
    ld   a,c
    or   080h
    out  (099h),a        ; select register write
    ret

; ---------------------------------------------------------------------------
; Redraws all players on screen using Var_Game_PlayersInfo, tramite
; GetPlayerInfoById.
;
; Per ogni giocatore:
;   - prende PREV_X/PREV_Y e CUR_X/CUR_Y da GetPlayerInfoById;
;   - se PREV_Y != 255 disegna TILE_FIELD alla vecchia posizione;
;   - se CUR_Y  != 255 disegna la tile corretta alla posizione attuale:
;       * ID = 0 (portiere):
;           - se Var_Game_GoalkeeperHasBall = YES:
;               TEAM_BLACK -> TILE_BLACK_GOALKEEPER_WITH_BALL
;               TEAM_WHITE -> TILE_WHITE_GOALKEEPER_WITH_BALL
;           - altrimenti:
;               TEAM_BLACK -> TILE_BLACK_GOALKEEPER
;               TEAM_WHITE -> TILE_WHITE_GOALKEEPER
;       * ID != 0:
;               TEAM_BLACK -> TILE_BLACK_PLAYER
;               TEAM_WHITE -> TILE_WHITE_PLAYER
;
; INPUT:  -
; OUTPUT: giocatori ridisegnati
; PRESERVA: AF, BC, DE, HL
; ---------------------------------------------------------------------------
VDP_PlayerMatrixRedraw:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL

    ld  a,(Var_Game_BallYOldPosition)
    cp  NO_VALUE
    jr  z,.no_old_ball

    ld  d,a                          ; Y old
    ld  a,(Var_Game_BallXOldPosition)
    ld  e,a                          ; X old
    ld  a,TILE_FIELD
    call VDP_DrawSprite




.no_old_ball:

    ; ---- disegna prima TEAM_BLACK, poi TEAM_WHITE ----
    LD   B,TEAM_BLACK
    CALL VPMR_DrawTeam

    LD   B,TEAM_WHITE
    CALL VPMR_DrawTeam
    CALL VDP_PlayerMatrixRedraw_DrawVirtual
    CALL VDP_DrawBallOnMatrix
    CALL Game_ClearSinglePlayerPrevPositions
    POP  HL
    POP  DE
    POP  BC
    POP  AF
    RET

;---------------------------------------------------------------
; Disegna la palla sulla matrice (o portiere/giocatore con palla)
; Usa:
;   Var_Game_BallXPosition / Var_Game_BallYPosition
;   Var_Game_BallDirection, Var_Game_BallDiagonalMovCounter
;   Var_Game_ActiveFieldSide
;---------------------------------------------------------------
VDP_DrawBallOnMatrix:
    push af
    push bc
    push de
    push hl

    ; di default nessun portiere con palla
    ld   a,NO
    ld   (Var_Game_GoalkeeperHasBall),a

    ; HL = X,Y della palla
    call Game_GetBallPosition

    ; cerca eventuale giocatore in D/E
    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    jp   z,.no_player      ; casella vuota → gestisce solo la palla

    ;-----------------------------------------------------------
    ; QUI C’E’ UN GIOCATORE
    ;  B = TEAM   (0 nero, 1 bianco)
    ;  C = ID     (0 portiere)
    ;  A = ROLE
    ;  HL = pos corrente, DE = pos precedente
    ;-----------------------------------------------------------

    ld   a,c
    or   a
    jr   nz,.field_player      ; ID!=0 → giocatore di movimento

    ;--------- PORTIERE ----------------------------------------
    ld   a,YES
    ld   (Var_Game_GoalkeeperHasBall),a

    ld   a,b
    cp   TEAM_BLACK
    jr   nz,.white_gk
    call Game_StopShot
    ld   a,TILE_BLACK_GOALKEEPER_WITH_BALL
    jp   .draw_sprite_with_ball_pos

.white_gk:
    call Game_StopShot
    ld   a,TILE_WHITE_GOALKEEPER_WITH_BALL
    jp   .draw_sprite_with_ball_pos


;--------- GIOCATORE DI MOVIMENTO -------------------------------
.field_player:
    ; logica in base a Var_Game_BallDirection
    ld   a,(Var_Game_BallDirection)
    cp   BALL_DIRECTION_NONE
    jr   z,.bp_none
    cp   BALL_DIRECTION_NORTH
    jr   z,.bp_north
    cp   BALL_DIRECTION_NORTH_EAST
    jr   z,.bp_ne_nw
    cp   BALL_DIRECTION_NORTH_WEST
    jr   z,.bp_ne_nw
    cp   BALL_DIRECTION_SOUTH
    jr   z,.bp_south
    cp   BALL_DIRECTION_SOUTH_EAST
    jr   z,.bp_se_sw
    cp   BALL_DIRECTION_SOUTH_WEST
    jr   z,.bp_se_sw
    ; default → trattiamo come palla ferma
    jr   .bp_none

; palla statica sul giocatore → semplicemente “contatto”,
; giocatore nero con palla e direzione azzerata (adatta se vuoi
; gestire anche il bianco come nel tuo codice originale)
.bp_none:
    ld   a,TILE_BLACK_PLAYER_WITH_BALL
    ld   c,a
    call Game_StopShot
    ld   a,c
    jr   .draw_sprite_with_ball_pos

; palla che arriva da N → se nero: tiene la palla e si ferma,
; se bianco: solo disegno del bianco con palla (come da specifiche).
.bp_north:
    ld   a,b
    cp   TEAM_BLACK
    jr   nz,.bp_north_white
    ld   a,TILE_BLACK_PLAYER_WITH_BALL
    ld   c,a
    call Game_StopShot
    ld   a,c
    jr   .draw_sprite_with_ball_pos

.bp_north_white:
    ld   a,TILE_WHITE_PLAYER_WITH_BALL
    jr   .draw_sprite_with_ball_pos

; diagonale NORD (NE/NW) con contatore=1 → palla dietro al giocatore
.bp_ne_nw:
    ld   a,(Var_Game_BallDiagonalMovCounter)
    cp   0
    jr   nz,.exit            ; niente di speciale
    ld   a,TILE_BLACK_PLAYER_WITH_BACK_BALL
    jr   .draw_sprite_with_ball_pos

; palla da S → nero la controlla e si ferma
.bp_south:
    ld   a,TILE_BLACK_PLAYER_WITH_BALL
    ;ld   c,a
    ;call Game_StopShot
    ;ld   a,c
    jr   .draw_sprite_with_ball_pos

; diagonale SUD (SE/SW)
.bp_se_sw:
    ld   a,(Var_Game_BallDiagonalMovCounter)
    cp   0
    jr   z,.bp_se_sw_counter1

    ; contatore !=1 → nero riceve palla davanti e si ferma
    ld   a,TILE_WHITE_PLAYER_WITH_BALL
    ;ld   c,a
    ;call Game_StopShot
    ;ld   a,c
    jr   .draw_sprite_with_ball_pos

.bp_se_sw_counter1:
    ; contatore=1 → bianco con palla
    ld   a,TILE_WHITE_PLAYER_WITH_BALL
    jr   .draw_sprite_with_ball_pos


;================ CASO NESSUN GIOCATORE NELLA CASELLA ==============
.no_player:
    ; Qui dobbiamo decidere se BALL_BOTTOM o BALL_TOP.
    ; *** IMPORTANTE ***:
    ;  - teniamo la tile in C
    ;  - usiamo A solo per confronti
    ld   c,TILE_BALL_BOTTOM       ; default

    ; --- caso 1: diagonale NORD (NE/NW) con contatore = 1 → BALL_TOP
    ld   a,(Var_Game_BallDirection)
    cp   BALL_DIRECTION_NORTH_EAST
    jr   z,.np_diag_north
    cp   BALL_DIRECTION_NORTH_WEST
    jr   nz,.np_after_diag

.np_diag_north:
    ld   a,(Var_Game_BallDiagonalMovCounter)
    cp   0
    jr   nz,.np_after_diag
    ld   c,TILE_BALL_TOP          ; override

.np_after_diag:
    ld   a,c                       ; rimetti la tile scelta in A
    jr   .chk_fieldside_top


;----------------- TUO BLOCCO OTTIMIZZATO --------------------------
; --- caso 2: FIELD_NORTH_SIDE e Y=0 -> BALL_TOP --------------
.chk_fieldside_top:
    ld   c,a                       ; salva la tile in C

    ld   a,(Var_Game_ActiveFieldSide)
    cp   FIELD_NORTH_SIDE
    jr   nz,.draw_sprite_prep

    ld   a,(Var_Game_BallYPosition)
    or   a
    jr   nz,.draw_sprite_prep
    ld   c,TILE_CORNER_BALL           ; Y=0 in direzione NORTH -> BALL_TOP

.draw_sprite_prep:
    ld   a,c                       ; A = tile definitiva (TOP/BOTTOM/altro)


; ====== DISEGNO DELLO SPRITE (palla o giocatore con palla) ========

; Se arriviamo dai casi giocatore, ricarichiamo sempre le coordinate
; della palla prima di disegnare.
.draw_sprite_with_ball_pos:
    ld   b,a                       ; salva tile in B

    call Game_GetBallPosition           ; HL = X,Y


    ld   a,b                       ; ripristina tile
    ; cade in .draw_sprite

.draw_sprite:
    ; A = tile, D = Y, E = X (coord matrice)
    CP   TILE_BALL_BOTTOM
    JP   NZ, .draw_sprite_continue
    LD   A, (Var_Game_ActiveFieldSide)
    CP   FIELD_NORTH_SIDE
    JP   Z, .darw_ball_north_field
    LD   A, (Var_Game_BallYPosition)
    CP   4
    JP   Z, .draw_ball_top
    LD   A, TILE_BALL_BOTTOM
    JP   .draw_sprite_continue
.darw_ball_north_field:
    LD   A, (Var_Game_BallYPosition)
    CP   0
    JP   Z, .draw_ball_top
    LD   A, TILE_BALL_BOTTOM
    JP   .draw_sprite_continue
.draw_ball_top:
    LD   A, TILE_CORNER_BALL
.draw_sprite_continue:
    call VDP_DrawSprite
    jr   .exit


.exit:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret

; ---------------------------------------------------------------------------
; Disegna tutti i 4 giocatori di una squadra
; INPUT:
;   B = TEAM (TEAM_BLACK / TEAM_WHITE)
; MODIFICA:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
VPMR_DrawTeam:
    LD   C,0                    ; ID = 0..3
VPMR_PlayerLoop:
    PUSH BC                     ; salva TEAM/ID per dopo

    CALL Game_GetPlayerInfoById
    ; dopo la call:
    ;   DE = prev (D=prevY, E=prevX)
    ;   HL = cur  (H=curY,  L=curX)
    ;   A  = ROLE
    ;   B  = TEAM
    ;   C  = ID

    ; ----- CLEAR PREVIOUS POSITION (se valida) --------------------
    LD   A,D                    ; prevY
    CP   255
    JP   Z,VPMR_SkipClear


    ; mappa coord logiche prev -> schermo
    PUSH HL                     ; salvo current
    PUSH AF                     ; non mi interessa il contenuto, ma proteggo A
    PUSH BC
    LD   A,TILE_FIELD
    CALL VDP_DrawSprite             ; D=row, E=col, A=tile
    POP  BC
    PUSH BC
    LD   A, B
    CP   TEAM_WHITE
    JP   NZ, VPMR_AfterCheckHalfLineToClear
    LD   A, (Var_Game_ActiveFieldSide)
    CP   FIELD_SOUTH_SIDE
    JP   Z, VPMR_WhiteOnSouthHalfToRemove

VPMR_WhiteOnNorthHalfToRemove:
    LD   A, D
    CP   17
    JP   NZ, VPMR_AfterCheckHalfLineToClear
    PUSH  DE
    LD    A, TILE_FIELD_LINE_HORIZONTAL
    CALL  VDP_PrintRamChar
    INC   E
    LD    A, TILE_FIELD_LINE_HORIZONTAL
    CALL  VDP_PrintRamChar
    INC   E
    LD    A, TILE_FIELD_LINE_HORIZONTAL
    CALL  VDP_PrintRamChar
    INC   E
    INC   D
    LD    A, TILE_FIELD
    CALL  VDP_PrintRamChar
    DEC   E
    DEC   E
    DEC   E

    INC   D
    INC   D
    LD    A, TILE_FIELD
    CALL  VDP_PrintRamChar
    INC   E
    LD    A, TILE_FIELD
    CALL  VDP_PrintRamChar

    POP   DE
    JP    VPMR_AfterCheckHalfLineToClear
VPMR_WhiteOnSouthHalfToRemove:
    LD   A, D
    CP   7
    JP   NZ, VPMR_AfterCheckHalfLineToClear
    PUSH  DE
    LD    A, TILE_FIELD_LINE_HORIZONTAL
    CALL  VDP_PrintRamChar
    INC   E
    LD    A, TILE_FIELD_LINE_HORIZONTAL
    CALL  VDP_PrintRamChar
    INC   E
    LD    A, TILE_FIELD_LINE_HORIZONTAL
    CALL  VDP_PrintRamChar
    INC   E
    LD    A, TILE_FIELD_LINE_HORIZONTAL
    CALL  VDP_PrintRamChar
    INC   D
    LD    A, TILE_FIELD
    CALL  VDP_PrintRamChar
    DEC   E
    DEC   E
    DEC   E

    INC   D
    INC   D
    LD    A, TILE_FIELD
    CALL  VDP_PrintRamChar
    INC   E
    LD    A, TILE_FIELD
    CALL  VDP_PrintRamChar

    POP   DE
    JP    VPMR_AfterCheckHalfLineToClear

VPMR_AfterCheckHalfLineToClear:
    POP  BC
    POP  AF
    POP  HL
    CALL Game_ClearSinglePlayerPrevPositions
VPMR_SkipClear:
    ; ----- DRAW CURRENT POSITION (se visibile) -------------------
    LD   A,H                    ; curY
    CP   255
    JP   Z,VPMR_AfterDraw       ; giocatore invisibile (es. portiere nascosto)

    ; D,E = coord logiche correnti
    LD   D,H
    LD   E,L

   
    ; ora D,E = coord schermo

    ; ----- determina la tile in A -----------------------
    LD   A,C                    ; A = ID
    OR   A
    JP   NZ,VPMR_FieldPlayer    ; ID != 0 → giocatore di movimento

    ; ===== PORTIERE =====
    LD   A,(Var_Game_GoalkeeperHasBall)
    CP   YES
    JP   NZ,VPMR_GK_NoBall

    ; portiere CON palla
    LD   A,B                    ; TEAM
    CP   TEAM_BLACK
    JP   NZ,VPMR_WhiteGKWithBall
    LD   A,TILE_BLACK_GOALKEEPER_WITH_BALL
    JP   VPMR_DoDraw

VPMR_WhiteGKWithBall:
    LD   A,TILE_WHITE_GOALKEEPER_WITH_BALL
    JP   VPMR_DoDraw

VPMR_GK_NoBall:
    ; portiere SENZA palla
    LD   A,B
    CP   TEAM_BLACK
    JP   NZ,VPMR_WhiteGKNoBall
    LD   A,TILE_BLACK_GOALKEEPER
    JP   VPMR_DoDraw

VPMR_WhiteGKNoBall:
    LD   A,TILE_WHITE_GOALKEEPER
    JP   VPMR_DoDraw

    ; ===== GIOCATORE DI MOVIMENTO =====
VPMR_FieldPlayer:
    LD   A,B
    CP   TEAM_BLACK
    JP   NZ,VPMR_WhitePlayer
    LD   A,TILE_BLACK_PLAYER
    JP   VPMR_DoDraw

VPMR_WhitePlayer:
    PUSH  HL
    POP   DE
    LD   A, (Var_Game_ActiveFieldSide)
    CP   FIELD_SOUTH_SIDE
    JP   Z, VPMR_WhitPlayerSouth
    LD   A, H
    CP   4
    JP   NZ, VPMR_WhiteStandardPlayer
    LD   A,TILE_WHITE_PLAYER_NEAR_HALF_FIELD
    JP   VPMR_DoDraw
VPMR_WhitPlayerSouth:
    LD   A, H
    CP   1
    JP   NZ, VPMR_WhiteStandardPlayer
    LD   A,TILE_WHITE_PLAYER_NEAR_HALF_FIELD
    JP   VPMR_DoDraw
VPMR_WhiteStandardPlayer:
    LD   A,TILE_WHITE_PLAYER
VPMR_DoDraw:
    CALL VDP_DrawSprite          ; usa D,E già mappate

VPMR_AfterDraw:
    POP  BC                      ; ripristina TEAM/ID salvati a inizio ciclo

    INC  C
    LD   A,C
    CP   4
    JP   NZ,VPMR_PlayerLoop
    RET








; ---------------------------------------------------------------------------
; Pulisce l'area laterale del menu (colonne 23)
; ---------------------------------------------------------------------------
VDP_ClearMenuSideArea:
    XOR     A
.Loop:
    PUSH    AF
    LD      D, A
    LD      E, 23
    LD      HL, TXT_EMPTY
    CALL    VDP_PrintString

    POP     AF
    INC     A
    CP      21
    RET     Z
    JP      .Loop



VDP_ShowScores:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    RET     NZ
    LD      D, 0
    LD      E, 23
    LD      HL, TXT_TIME
    CALL    VDP_PrintString

    LD      D, 5
    LD      E, 23
    LD      HL, TXT_BLACK_TEAM
    CALL    VDP_PrintString

    LD      D, 10
    LD      E, 23
    LD      HL, TXT_WHITE_TEAM
    CALL    VDP_PrintString
    PUSH    DE
    PUSH    HL
    LD      A, (Var_Game_ScoreWhite)
    LD      H, 0
    LD      L, A
    LD      DE, Var_Utils_NumberToPrint
    CALL    String_NumberToASCII
    LD      HL, Var_Utils_NumberToPrint
    CALL    String_RemoveLeadingZeros
    LD      HL, Var_Utils_NumberToPrint
    LD      D, 11
    LD      E, 26
    CALL    VDP_PrintString   

    LD      A, (Var_Game_ScoreBlack)
    LD      H, 0
    LD      L, A
    LD      DE, Var_Utils_NumberToPrint
    CALL    String_NumberToASCII
    LD      HL, Var_Utils_NumberToPrint
    CALL    String_RemoveLeadingZeros
    LD      HL, Var_Utils_NumberToPrint
    LD      D, 6
    LD      E, 26
    CALL    VDP_PrintString 

    POP     HL
    POP     DE
    RET


