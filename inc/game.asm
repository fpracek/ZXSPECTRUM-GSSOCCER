
; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** GAME.ASM ***

; ------ ROUTINES ------
Game_InitVariables:
    LD      A, NO_VALUE
    LD      (Var_Game_FirstKickType), A
    LD      A, NO
    LD      (Var_Utils_VblankStopped), A
    LD      (Var_Hooks_ForceVdpRedraw), A
    LD      (Var_Hooks_GameResumingWaiting), A
    LD      A, GAME_MODE_1_PLAYER
    LD      (Var_Game_SelectedPlayers), A
    LD      A, NO
    LD      (Var_Game_MatchInProgress), A
    LD      A, 2
    LD      (Var_Game_HumanPlayerSpeed), A
    XOR     A
    LD      (Var_Game_BallUpdateTimer), A
    LD      (Var_Hooks_GoalCerimonyCounter), A
    CALL    Hooks_InitAICounters
    CALL    Game_StopShot
    RET


; ---------------------------------------------------------------------------
; Game_CheckVerticalShotPossessionStop
;
; INPUT:
;   D = BallY
;   E = BallX
; ---------------------------------------------------------------------------
Game_CheckVerticalShotPossessionStop:
    push af
    push bc
    push de
    push hl

    ; ---------------------------
    ; Check NERI: match esatto (Y,X)  ID 1..3
    ; ---------------------------
    ld   b,TEAM_BLACK
    ld   c,1
.chk_black_loop:
    push de
    call Game_GetPlayerInfoById      ; HL = cur (H=Y, L=X)
    pop  de

    ld   a,h
    cp   d
    jr   nz,.chk_black_next
    ld   a,l
    cp   e
    jr   nz,.chk_black_next

    call Game_StopShot
    jr   .done

.chk_black_next:
    inc  c
    ld   a,c
    cp   4
    jr   nz,.chk_black_loop

    ; ---------------------------
    ; Check BIANCHI: match su (BallY+1, BallX)  ID 1..3
    ; ---------------------------
    ld   b,TEAM_WHITE
    ld   c,1
.chk_white_loop:
    push de
    call Game_GetPlayerInfoById      ; HL = cur (H=Y, L=X)
    pop  de

    ld   a,d
    inc  a                           ; targetY = BallY+1
    cp   h
    jr   nz,.chk_white_next

    ld   a,e
    cp   l
    jr   nz,.chk_white_next

    call Game_StopShot
    jr   .done

.chk_white_next:
    inc  c
    ld   a,c
    cp   4
    jr   nz,.chk_white_loop

    ; ------------------------------------------------------------
    ; Nessun possesso: verifica stop per fondo campo del lato attuale
    ; e/o cambio metà campo
    ; ------------------------------------------------------------
    ld   a,(Var_Game_ActiveFieldSide)
    cp   FIELD_SOUTH_SIDE
    jr   nz,.field_is_north

; ===== CAMPO SOUTH =====
    ; Se palla su riga 4 -> fondo campo / porta: stop tiro
    ld   a,d
    cp   4
    jr   nz,.done
    call Game_StopShot
    jr   .done



; ===== CAMPO NORTH =====
.field_is_north:
    ; Se palla su riga 0 -> fondo campo / porta: stop tiro
    ld   a,d
    or   a
    jr   nz,.done
    call Game_StopShot

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret




; ---------------------------------------------------------------------------
; Game_UpdateBallMovement
; Da chiamare a ogni tick (AiTick) per muovere la palla se in tiro.
;
; Usa:
;   Var_Game_BallDirection
;   Var_Game_BallDiagonalMovCounter (0 normale, 255 caso speciale)
;
; Convenzioni:
;   Game_GetBallPosition -> DE  (D=Y, E=X)
;   Game_SetBallPosition usa DE (D=Y, E=X)
;
; Regole:
; - Se BallDirection = NONE -> nessun movimento
; - Caso speciale counter=255 (solo WHITE attaccante, campo NORTH, Y=2):
;     * NORTH: primo tick = nessun movimento, counter->0
;     * NE/NW: primo tick = solo laterale, counter->0
; - Diagonali: ogni tick muove Y e prova a muovere X; se X è già al bordo
;   che impedisce la diagonale, X non cambia ma il tick conta comunque.
; - Il counter aumenta SEMPRE per direzioni diverse da:
;       BALL_DIRECTION_NONE, BALL_DIRECTION_NORTH, BALL_DIRECTION_SOUTH
; - Se (counter == 2) prima di uscire: Game_StopShot (stop definitivo tiro)
; ---------------------------------------------------------------------------
Game_UpdateBallMovement:

    ld    a,(Var_Hooks_ForceVdpRedraw)
    cp    YES
    ret   z
    LD    A, (Var_Game_BallUpdateTimer)
    inc   a
    LD    (Var_Game_BallUpdateTimer), A
    CP    10
    RET    NZ
    XOR   A
    LD    (Var_Game_BallUpdateTimer), A

    push af
    push bc
    push de
    push hl

    ; se palla ferma -> niente
    ld   a,(Var_Game_BallDirection)
    cp   BALL_DIRECTION_NONE
    jp   z,.done

    ; forza redraw
    ld   a,YES
    ld   (Var_Hooks_ForceVdpRedraw),a

    ; DE = (Y,X)
    call Game_GetBallPosition         ; D=Y, E=X

    ; ------------------------------------------------------------
    ; Caso speciale "first tick grafico" (counter=255)
    ; ------------------------------------------------------------
    ld   a,(Var_Game_BallDiagonalMovCounter)
    cp   255
    jr   nz,.normal_move

    ld   a,(Var_Game_BallDirection)
    cp   BALL_DIRECTION_NORTH
    jr   z,.special_north
    cp   BALL_DIRECTION_NORTH_EAST
    jr   z,.special_ne
    cp   BALL_DIRECTION_NORTH_WEST
    jr   z,.special_nw

    ; se per errore 255 con altre direzioni, normalizza
    xor  a
    ld   (Var_Game_BallDiagonalMovCounter),a
    jr   .normal_move

.special_north:
    ; primo tick: nessun movimento, solo marker grafico.
    xor  a
    ld   (Var_Game_BallDiagonalMovCounter),a
    jp   .done_check2

.special_ne:
    ; primo tick: solo laterale (X+1 se possibile)
    ld   a,e
    cp   4
    jr   z,.special_ne_clear
    inc  e
    call Game_SetBallPosition
.special_ne_clear:
    xor  a
    ld   (Var_Game_BallDiagonalMovCounter),a
    jp   .done_check2

.special_nw:
    ; primo tick: solo laterale (X-1 se possibile)
    ld   a,e
    or   a
    jr   z,.special_nw_clear
    dec  e
    call Game_SetBallPosition
.special_nw_clear:
    xor  a
    ld   (Var_Game_BallDiagonalMovCounter),a
    jp   .done_check2


; ------------------------------------------------------------
; Movimento normale
; ------------------------------------------------------------
.normal_move:


    ; --- incremento counter SOLO se direzione è diagonale ---
    ld   a,(Var_Game_BallDirection)
    cp   BALL_DIRECTION_NONE
    jr   z,.skip_counter_inc
    cp   BALL_DIRECTION_NORTH
    jr   z,.skip_counter_inc
    cp   BALL_DIRECTION_SOUTH
    jr   z,.skip_counter_inc

    ld   a,(Var_Game_BallDiagonalMovCounter)
    inc  a
    ld   (Var_Game_BallDiagonalMovCounter),a
.skip_counter_inc:

    ld a, YES
    ld    (Var_Hooks_ForceVdpRedraw), a

    ; dispatch direzione
    ld   a,(Var_Game_BallDirection)

    cp   BALL_DIRECTION_NORTH
    jr   z,.move_north

    cp   BALL_DIRECTION_SOUTH
    jr   z,.move_south

    cp   BALL_DIRECTION_NORTH_EAST
    jp   z,.move_ne

    cp   BALL_DIRECTION_NORTH_WEST
    jp   z,.move_nw

    cp   BALL_DIRECTION_SOUTH_EAST
    jp   z,.move_se

    cp   BALL_DIRECTION_SOUTH_WEST
    jp   z,.move_sw

    ; direzione sconosciuta -> stop
    call Game_StopShot
    jp   .done


.move_north:
    dec     d
    ld      a,d
    cp      255  
    jr      nz,.move_north_continue
    inc     d
    ld      a, (Var_Game_ActiveFieldSide)
    cp      FIELD_NORTH_SIDE
    jp      z,.stop_now
    CALL    Hooks_TickStop
    LD      A, FIELD_NORTH_SIDE
    LD      (Var_Game_ActiveFieldSide),A
    CALL    VDP_DrawField
    CALL    Game_PutPlayersToNewFieldSide
    ld      a,YES
    ld      (Var_Hooks_ForceVdpRedraw),a
    CALL    Game_GetBallPosition
    LD      D, 4
    CALL    Game_SetBallPosition
    LD      A, NO_VALUE
    LD      (Var_Game_BallYOldPosition), A
    CALL    Hooks_TickStart
    jp      .done
.move_north_continue:
    call Game_SetBallPosition

    ; --- NUOVO: stop se diventa possesso (verticale puro) ---
    call Game_CheckVerticalShotPossessionStop

    jr   .done_check2


.move_south:
    inc     d
    ld      a,d
    cp      5
    jr      nz,.move_south_continue
    dec     d
    ld      a, (Var_Game_ActiveFieldSide)
    cp      FIELD_SOUTH_SIDE
    jr      z,.stop_now
    CALL    Hooks_TickStop
    LD      A, FIELD_SOUTH_SIDE
    LD      (Var_Game_ActiveFieldSide),A
    CALL    VDP_DrawField
    CALL    Game_PutPlayersToNewFieldSide
    ld      a,YES
    ld      (Var_Hooks_ForceVdpRedraw),a
    CALL    Game_GetBallPosition
    LD      D, 0
    CALL    Game_SetBallPosition
    LD      A, NO_VALUE
    LD      (Var_Game_BallYOldPosition), A
    CALL    Hooks_TickStart
    jr      .done

.move_south_continue:
    call Game_SetBallPosition

    ; --- NUOVO: stop se diventa possesso (verticale puro) ---
    call Game_CheckVerticalShotPossessionStop

    jr   .done_check2

; Diagonali: muove SEMPRE Y, e X solo se non uscirebbe dal bordo.
.move_ne:
    ; Y--
    ld   a,d
    or   a
    jr   z,.stop_now
    dec  d
    ; X++ se possibile
    ld   a,e
    cp   4
    jr   z,.set_pos_only      ; a bordo -> solo verticale
    inc  e
    jr   .set_pos_only

.move_nw:
    ; Y--
    ld   a,d
    or   a
    jr   z,.stop_now
    dec  d
    ; X-- se possibile
    ld   a,e
    or   a
    jr   z,.set_pos_only
    dec  e
    jr   .set_pos_only

.move_se:
    ; Y++
    ld   a,d
    cp   4
    jr   z,.stop_now
    inc  d
    ; X++ se possibile
    ld   a,e
    cp   4
    jr   z,.set_pos_only
    inc  e
    jr   .set_pos_only

.move_sw:
    ; Y++
    ld   a,d
    cp   4
    jr   z,.stop_now
    inc  d
    ; X-- se possibile
    ld   a,e
    or   a
    jr   z,.set_pos_only
    dec  e

.set_pos_only:
    call Game_SetBallPosition
    jr   .done_check2


.stop_now:
    call Game_StopShot
    jr   .done


; ------------------------------------------------------------
; Check fine tiro dopo 2 tick (vale SOLO per diagonali perché
; il counter viene incrementato solo in quei casi).
; ------------------------------------------------------------
.done_check2:
    ld   a,(Var_Game_BallDiagonalMovCounter)
    cp   2
    jr   nz,.done
    call Game_StopShot

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret



;------------------------------------------------------------------------
; Get ball position
; INPUT: -
; OUTPUT: DE = X,Y
; MODIFIES: -
;------------------------------------------------------------------------
Game_GetBallPosition:
    PUSH    AF
    LD      A, (Var_Game_BallXPosition)
    LD      E, A
    LD      A, (Var_Game_BallYPosition)  
    LD      D, A
    POP     AF
    RET
;------------------------------------------------------------------------
; Set ball position
; INPUT:  D = Y, E = X   (coordinate di matrice 0..4)
; OUTPUT: -
; MODIFIES: AF
; NOTE:
;   - Prima copia la posizione corrente in Var_Game_Ball*OldPosition
;   - Poi aggiorna Var_Game_BallX/YPosition con la nuova
;------------------------------------------------------------------------
Game_SetBallPosition:
    PUSH    AF

    ; --- salviamo la posizione corrente come "old" ---
    LD      A,(Var_Game_BallXPosition)
    LD      (Var_Game_BallXOldPosition),A

    LD      A,(Var_Game_BallYPosition)
    LD      (Var_Game_BallYOldPosition),A

    ; --- scriviamo la nuova posizione (da D/E) ---
    LD      A,D
    LD      (Var_Game_BallYPosition),A

    LD      A,E
    LD      (Var_Game_BallXPosition),A

    POP     AF
    RET

; ** UTILITY ROUTINES **

; ---------------------------------------------------------------------------
; Calculates pointer to the player entry in Var_Game_PlayersInfo.
;
; INPUT:
;   B = TEAM (TEAM_BLACK=0, TEAM_WHITE=1)
;   C = ID   (0..3)  ; 4 players per team
;
; OUTPUT:
;   HL = pointer to entry start:
;        [0] PREV_X, [1] PREV_Y, [2] CUR_X, [3] CUR_Y,
;        [4] TEAM, [5] ID, [6] ROLE
;
; PRESERVES:
;   B = TEAM, C = ID    (utile per le routine chiamanti)
;
; MODIFIES:
;   AF, DE, HL
; ---------------------------------------------------------------------------
GetPlayerEntryPtr:
    ; n = TEAM*4 + ID  (TEAM_BLACK=0, TEAM_WHITE=1)
    ; salvo TEAM/ID perché userò BC come registro di lavoro
    PUSH BC

    LD   A,B
    ADD  A,A           ; *2
    ADD  A,A           ; *4
    ADD  A,C           ; + ID → n (0..7)

    LD   C,A           ; C = n
    LD   B,0           ; BC = n (16-bit)

    ; HL = n * PLAYER_ENTRY_SIZE (7)
    LD   HL,0
    LD   A,PLAYER_ENTRY_SIZE      ; A = 7
.GPE_MulLoop:
    ADD  HL,BC                    ; HL += n
    DEC  A
    JR   NZ,.GPE_MulLoop          ; ripeti 7 volte

    ; A questo punto HL = n * 7
    LD   DE,Var_Game_PlayersInfo
    ADD  HL,DE                    ; HL = base + n*7

    POP  BC                       ; ripristina TEAM/ID
    RET


; ---------------------------------------------------------------------------
; Determines the role of a player based on TEAM, FIELD DIRECTION and Y.
; NOTE:
;   This is intended for non-goalkeepers (ID != 0).
;   Goalkeepers are forced to ROLE_GOALKEEPER in SetPlayerInfo, but
;   mappings for goalkeeper rows are kept here for completeness.
;
; LOGIC (Var_Game_ActiveFieldSide = FIELD_NORTH_SIDE):
;   TEAM_BLACK:
;       Y=0 -> GOALKEEPER
;       Y=1 -> DEFENDER
;       Y=3 -> MIDFIELDER
;       else -> STRIKER
;   TEAM_WHITE (no visible goalkeeper):
;       Y=4 -> MIDFIELDER
;       Y=2 -> STRIKER
;       else -> STRIKER
;
; LOGIC (Var_Game_ActiveFieldSide = FIELD_SOUTH_SIDE):
;   TEAM_WHITE:
;       Y=4 -> GOALKEEPER
;       Y=3 -> DEFENDER
;       Y=1 -> MIDFIELDER
;       else -> STRIKER
;   TEAM_BLACK (no visible goalkeeper):
;       Y=0 -> MIDFIELDER
;       Y=2 -> STRIKER
;       else -> STRIKER
;
; INPUT:
;   B = TEAM (TEAM_WHITE or TEAM_BLACK)
;   D = Y (0..4)
; OUTPUT:
;   A = ROLE (ROLE_GOALKEEPER / ROLE_DEFENDER / ROLE_MIDFIELDER / ROLE_STRIKER)
; MODIFIES:
;   AF
; ---------------------------------------------------------------------------
DeterminePlayerRole:
    LD   A,(Var_Game_ActiveFieldSide)
    CP   FIELD_NORTH_SIDE
    JR   Z,.NORTH

; ===== FIELD DIRECTION SOUTH =======================================

.SOUTH:
    ; Check which team
    LD   A,B
    CP   TEAM_WHITE
    JR   Z,.SOUTH_WHITE

    ; --- TEAM_BLACK (no visible goalkeeper) ---
    LD   A,D
    CP   0
    JR   Z,.BLACK_MID_S
    CP   2
    JR   Z,.BLACK_STR_S

    LD   A,ROLE_STRIKER
    RET

.BLACK_MID_S:
    LD   A,ROLE_MIDFIELDER
    RET

.BLACK_STR_S:
    LD   A,ROLE_STRIKER
    RET

; --- TEAM_WHITE (with goalkeeper) ---
.SOUTH_WHITE:
    LD   A,D
    CP   4
    JR   Z,.WHITE_GK_S
    CP   3
    JR   Z,.WHITE_DEF_S
    CP   1
    JR   Z,.WHITE_MID_S

    LD   A,ROLE_STRIKER
    RET

.WHITE_GK_S:
    LD   A,ROLE_GOALKEEPER
    RET

.WHITE_DEF_S:
    LD   A,ROLE_DEFENDER
    RET

.WHITE_MID_S:
    LD   A,ROLE_MIDFIELDER
    RET


; ===== FIELD DIRECTION NORTH ======================================

.NORTH:
    ; Check which team
    LD   A,B
    CP   TEAM_WHITE
    JR   Z,.NORTH_WHITE

    ; --- TEAM_BLACK (with goalkeeper) ---
    LD   A,D
    CP   0
    JR   Z,.BLACK_GK_N
    CP   1
    JR   Z,.BLACK_DEF_N
    CP   3
    JR   Z,.BLACK_MID_N

    LD   A,ROLE_STRIKER
    RET

.BLACK_GK_N:
    LD   A,ROLE_GOALKEEPER
    RET

.BLACK_DEF_N:
    LD   A,ROLE_DEFENDER
    RET

.BLACK_MID_N:
    LD   A,ROLE_MIDFIELDER
    RET

; --- TEAM_WHITE (no visible goalkeeper) ---
.NORTH_WHITE:
    LD   A,D
    CP   4
    JR   Z,.WHITE_MID_N
    CP   2
    JR   Z,.WHITE_STR_N

    LD   A,ROLE_STRIKER
    RET

.WHITE_MID_N:
    LD   A,ROLE_MIDFIELDER
    RET

.WHITE_STR_N:
    LD   A,ROLE_STRIKER
    RET

; ---------------------------------------------------------------------------
; Sets player info, updating previous and current positions and role.
; Previous position is taken from old CUR_X/CUR_Y (if not NO_VALUE).
; For ID = 0, the role is always ROLE_GOALKEEPER.
;
; INPUT:
;   B = TEAM (TEAM_WHITE / TEAM_BLACK)
;   C = ID   (0..3)
;   D = new Y (0..4 o 255 per invisibile)
;   E = new X (0..4 o 255 per invisibile)
; OUTPUT:
;   -
; MODIFIES:
;   AF, DE, HL
; ---------------------------------------------------------------------------
SetPlayerInfo:
    PUSH    BC             ; salva TEAM, ID
    PUSH    DE             ; salva newY,newX

    ; HL -> inizio entry (PREV_X)
    CALL    GetPlayerEntryPtr

    ; ----- leggi vecchia CUR_X / CUR_Y -----
    PUSH    HL             ; salva base entry

    INC     HL             ; PREV_Y
    INC     HL             ; CUR_X
    LD      A,(HL)         ; A = old CUR_X
    INC     HL             ; CUR_Y
    LD      C,(HL)         ; C = old CUR_Y

    POP     HL             ; HL di nuovo su PREV_X

    ; ----- PREV_X / PREV_Y -----
    LD      (HL),A         ; PREV_X = old CUR_X
    INC     HL
    LD      (HL),C         ; PREV_Y = old CUR_Y

    ; ----- CUR_X / CUR_Y -----
    INC     HL             ; HL -> CUR_X
    POP     DE             ; D=newY, E=newX
    LD      (HL),E         ; CUR_X
    INC     HL
    LD      (HL),D         ; CUR_Y

    ; ----- TEAM / ID / ROLE -----
    INC     HL             ; TEAM
    POP     BC             ; ripristina TEAM,ID
    LD      (HL),B         ; TEAM
    INC     HL             ; ID
    LD      (HL),C         ; ID
    INC     HL             ; ROLE

    ; Se ID=0 → portiere fisso
    LD      A,C
    OR      A
    JR      NZ,.not_goalkeeper

    LD      A,ROLE_GOALKEEPER
    LD      (HL),A
    RET

.not_goalkeeper:
    ; determina il ruolo per i giocatori di movimento
    ; B = TEAM, D = Y sono ancora validi
    CALL    DeterminePlayerRole
    LD      (HL),A
    RET

; ---------------------------------------------------------------------------
; Gets player info by TEAM and ID.
;
; INPUT:
;   B = TEAM  (TEAM_BLACK / TEAM_WHITE)
;   C = ID    (0..3)
;
; OUTPUT (se OK):
;   HL = current position (H = Y, L = X)
;   DE = previous position (D = prevY, E = prevX)
;   A  = ROLE
;   B  = TEAM (come in ingresso)
;   C  = ID   (come in ingresso)
;
; OUTPUT (se ID fuori range):
;   A  = NO_VALUE
;
; MODIFIES:
;   AF, DE, HL
; ---------------------------------------------------------------------------
Game_GetPlayerInfoById:
    ld   a,c
    cp   4
    jr   c,.GPI_ValidId
    ld   a,NO_VALUE
    ret

.GPI_ValidId:
    ; salviamo TEAM/ID perché useremo B,C come temporanei
    push bc

    ; HL -> PREV_X dell'entry (usa TEAM/ID salvati dentro GetPlayerEntryPtr)
    ; GetPlayerEntryPtr preserva B,C da solo (fa PUSH/POP BC)
    call GetPlayerEntryPtr       ; HL = base entry (PREV_X)

    ; ----- PREV in DE -----
    ld   e,(hl)                  ; PREV_X
    inc  hl
    ld   d,(hl)                  ; PREV_Y

    ; ----- CUR in B,C temporanei -----
    inc  hl                      ; CUR_X
    ld   c,(hl)                  ; C = CUR_X
    inc  hl                      ; CUR_Y
    ld   b,(hl)                  ; B = CUR_Y

    ; ----- ROLE in A -----
    inc  hl                      ; TEAM
    inc  hl                      ; ID
    inc  hl                      ; ROLE
    ld   a,(hl)                  ; A = ROLE

    ; ----- ricomponi output -----
    ; HL = (Y,X)
    ld   h,b                     ; H = CUR_Y
    ld   l,c                     ; L = CUR_X

    ; DE già contiene (prevY,prevX)

    ; ripristina TEAM/ID originali in BC
    pop  bc                      ; B = TEAM, C = ID

    ret



; ---------------------------------------------------------------------------
; Searches a player by his current position (CUR_X, CUR_Y).
;
; INPUT:
;   D = Y (curY)
;   E = X (curX)
;
; OUTPUT (if found):
;   B  = TEAM        (0 = TEAM_BLACK, 1 = TEAM_WHITE)
;   C  = ID          (0..3)
;   A  = ROLE
;   DE = current position  (D = curY, E = curX)
;   HL = previous position (H = prevY, L = prevX)
;
; OUTPUT (if not found):
;   A  = NO_VALUE
;
; MODIFIES:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
Game_GetPlayerInfoByPos:
    LD   B,TEAM_BLACK
.black:
    LD   C,0                      ; ID = 0..3
.black_loop:
    PUSH BC
    PUSH DE
    CALL Game_GetPlayerInfoById
    POP DE
    POP BC
    LD   A, H
    CP   D
    JR   NZ,.black_loop_not_found
    LD   A, L
    CP   E
    JR   NZ,.black_loop_not_found
    CALL Game_GetPlayerInfoById
    RET
.black_loop_not_found
    INC  C
    LD   A, C
    CP   4
    JR   NZ, .black_loop
    LD   B,TEAM_WHITE
.white:
    LD   C,0            
.white_loop:
    PUSH BC
    PUSH DE
    CALL Game_GetPlayerInfoById
    POP DE
    POP BC
    LD   A, H
    CP   D
    JR   NZ,.white_loop_not_found
    LD   A, L
    CP   E
    JR   NZ,.white_loop_not_found
    CALL Game_GetPlayerInfoById
    RET
.white_loop_not_found
    INC  C
    LD   A, C
    CP   4
    JR   NZ, .white_loop
    LD   A, NO_VALUE
    RET

; ---------------------------------------------------------------------------
; Clears all previous positions (PREV_X, PREV_Y) for all players.
; PREV_X and PREV_Y are set to NO_VALUE (255).
;
; INPUT:
;  B: TEAM (TEAM_BLACK / TEAM_WHITE)
;  C: ID (0..3)
;   -
; OUTPUT:
;   -
; MODIFIES:
;   -
; ---------------------------------------------------------------------------
Game_ClearSinglePlayerPrevPositions:
    PUSH DE
    PUSH BC
    PUSH HL
    PUSH AF



    CALL GetPlayerEntryPtr        ; HL -> PREV_X of this player
    LD   A, NO_VALUE
    LD   (HL),A                   ; PREV_X = NO_VALUE
    INC  HL
    LD   (HL),A                   ; PREV_Y = NO_VALUE

   


    POP AF
    POP HL
    POP BC
    POP DE
    RET
; ---------------------------------------------------------------------------
; Clears all previous positions (PREV_X, PREV_Y) for all players.
; PREV_X and PREV_Y are set to NO_VALUE (255).
;
; INPUT:
;   -
; OUTPUT:
;   -
; MODIFIES:
;   AF, BC, HL
; ---------------------------------------------------------------------------
ClearAllPrevPositions:
    LD   A,NO_VALUE

    ; ---- Team BLACK ----
    LD   B,TEAM_BLACK
    CALL .ClearTeamPrev

    ; ---- Team WHITE ----
    LD   B,TEAM_WHITE
    CALL .ClearTeamPrev

    RET

; Clears PREV_X / PREV_Y for one team (B = TEAM, C = 0..3)
.ClearTeamPrev:
    LD   C,0                      ; ID = 0..3
.CT_Loop:
    PUSH BC
    CALL GetPlayerEntryPtr        ; HL -> PREV_X of this player
    LD   A, NO_VALUE
    LD   (HL),A                   ; PREV_X = NO_VALUE
    INC  HL
    LD   (HL),A                   ; PREV_Y = NO_VALUE

    POP  BC
    INC  C
    LD   A,C                      ; *** qui confrontiamo C, non A vecchio ***
    CP   4
    JR   NZ,.CT_Loop
    RET




; ---------------------------------------------------------------------------
; Sets kickoff schema when WHITE team is attacking (field direction NORTH).
; Black goalkeeper is visible on row 0, white goalkeeper is hidden.
; Players layout (Y=row, X=col):
;   - Black GK:        Y=0, X=2
;   - Black DEF:       Y=1, X=1 and Y=1, X=3
;   - Black MID:       Y=3, X=4
;   - White MID:       Y=4, X=1,2,3
;   - White GK:        Y=255 (hidden), X=2
; Also sets virtual player variables for a black virtual player at (0,0).
; INPUT:
;   -
; OUTPUT:
;   Var_Game_ActiveFieldSide updated
;   Var_Game_PlayersInfo fully initialized for this schema
;   All previous positions cleared (PREV_X/PREV_Y = 255)
; MODIFIES:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
Game_SetWhiteKickoffSchema:
    LD   A, TEAM_WHITE
    LD   (Var_Game_TeamWithBall), A

    LD     D, 3
    LD     E, 2
    CALL   Game_SetBallPosition
    LD     A, 255
    LD     (Var_Game_BallYOldPosition ), A
    LD      A, BALL_DIRECTION_NONE
    LD      (Var_Game_BallDirection),A

    ; Set field direction to NORTH
    LD   A,FIELD_NORTH_SIDE
    LD   (Var_Game_ActiveFieldSide),A

    ; ---- BLACK TEAM (TEAM_BLACK) ---------------------------------

    ; Black GK, ID=0, Y=0, X=2
    LD   B,TEAM_BLACK
    LD   C,0                  ; ID=0 (goalkeeper)
    LD   D,0                  ; Y
    LD   E,2                  ; X
    CALL SetPlayerInfo

    ; Black DEF 1, ID=1, Y=1, X=1
    LD   B,TEAM_BLACK
    LD   C,1
    LD   D,1
    LD   E,1
    CALL SetPlayerInfo

    ; Black DEF 2, ID=2, Y=1, X=3
    LD   B,TEAM_BLACK
    LD   C,2
    LD   D,1
    LD   E,3
    CALL SetPlayerInfo

    ; Black MID, ID=3, Y=3, X=4
    LD   B,TEAM_BLACK
    LD   C,3
    LD   D,3
    LD   E,4
    CALL SetPlayerInfo

    ; ---- WHITE TEAM (TEAM_WHITE) ---------------------------------

    ; White GK hidden, ID=0, Y=255, X=2
    LD   B,TEAM_WHITE
    LD   C,0
    LD   D,255
    LD   E,2
    CALL SetPlayerInfo

    ; White MID 1, ID=1, Y=4, X=1
    LD   B,TEAM_WHITE
    LD   C,1
    LD   D,4
    LD   E,1
    CALL SetPlayerInfo

    ; White MID 2, ID=2, Y=4, X=2
    LD   B,TEAM_WHITE
    LD   C,2
    LD   D,4
    LD   E,2
    CALL SetPlayerInfo

    ; White MID 3, ID=3, Y=4, X=3
    LD   B,TEAM_WHITE
    LD   C,3
    LD   D,4
    LD   E,3
    CALL SetPlayerInfo

    ; ---- VIRTUAL PLAYER ------------------------------------------

    LD   A,TEAM_BLACK
    LD   (Var_Game_VirtualPlayerTeam),A

    XOR   A
    LD   (Var_Game_VirtualPlayerXPos),A   ; X=0
    LD   A, 3
    LD   (Var_Game_VirtualPlayerYPos),A
    ; ---- CLEAR PREVIOUS POSITIONS --------------------------------
    CALL ClearAllPrevPositions

    RET

; ---------------------------------------------------------------------------
; Sets kickoff schema when BLACK team is attacking (field direction SOUTH).
; White goalkeeper is visible on row 4, black goalkeeper is hidden.
; Players layout (Y=row, X=col):
;   - White GK:        Y=4, X=2
;   - White DEF:       Y=3, X=1 and Y=3, X=3
;   - White MID:       Y=1, X=0
;   - Black MID:       Y=0, X=1,2,3
;   - Black GK:        Y=255 (hidden), X=2
; Also sets virtual player variables for a white virtual player at (1,4).
; INPUT:
;   -
; OUTPUT:
;   Var_Game_ActiveFieldSide updated
;   Var_Game_PlayersInfo fully initialized for this schema
;   All previous positions cleared (PREV_X/PREV_Y = 255)
; MODIFIES:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
Game_SetBlackKickoffSchema:
    LD   A, TEAM_BLACK
    LD   (Var_Game_TeamWithBall), A

    LD     D, 0
    LD     E, 2
    CALL   Game_SetBallPosition
    LD     A, 255
    LD     (Var_Game_BallYOldPosition ), A
    LD   A, BALL_DIRECTION_NONE
    LD   (Var_Game_BallDirection),A

    ; Set field direction to SOUTH
    LD   A,FIELD_SOUTH_SIDE
    LD   (Var_Game_ActiveFieldSide),A

    ; ---- WHITE TEAM (TEAM_WHITE) ---------------------------------

    ; White GK, ID=0, Y=4, X=2
    LD   B,TEAM_WHITE
    LD   C,0
    LD   D,4
    LD   E,2
    CALL SetPlayerInfo

    ; White DEF 1, ID=1, Y=3, X=1
    LD   B,TEAM_WHITE
    LD   C,1
    LD   D,3
    LD   E,1
    CALL SetPlayerInfo

    ; White DEF 2, ID=2, Y=3, X=3
    LD   B,TEAM_WHITE
    LD   C,2
    LD   D,3
    LD   E,3
    CALL SetPlayerInfo

    ; White MID, ID=3, Y=1, X=0
    LD   B,TEAM_WHITE
    LD   C,3
    LD   D,1
    LD   E,0
    CALL SetPlayerInfo

    ; ---- BLACK TEAM (TEAM_BLACK) ---------------------------------

    ; Black GK hidden, ID=0, Y=255, X=2
    LD   B,TEAM_BLACK
    LD   C,0
    LD   D,255
    LD   E,2
    CALL SetPlayerInfo

    ; Black MID 1, ID=1, Y=0, X=1
    LD   B,TEAM_BLACK
    LD   C,1
    LD   D,0
    LD   E,1
    CALL SetPlayerInfo

    ; Black MID 2, ID=2, Y=0, X=2
    LD   B,TEAM_BLACK
    LD   C,2
    LD   D,0
    LD   E,2
    CALL SetPlayerInfo

    ; Black MID 3, ID=3, Y=0, X=3
    LD   B,TEAM_BLACK
    LD   C,3
    LD   D,0
    LD   E,3
    CALL SetPlayerInfo

    ; ---- VIRTUAL PLAYER ------------------------------------------

    LD   A,TEAM_WHITE
    LD   (Var_Game_VirtualPlayerTeam),A

    LD   A,1
    LD   (Var_Game_VirtualPlayerYPos),A   ; Y=1
    LD   A,4
    LD   (Var_Game_VirtualPlayerXPos),A   ; X=4

    ; ---- CLEAR PREVIOUS POSITIONS --------------------------------
    CALL ClearAllPrevPositions

    RET

; ---------------------------------------------------------------------------
; Sets restart-from-goal schema when BLACK team is defending and the
; active field side is NORTH.
;
; Player layout (Y=row, X=col):
;   - Black GK:        Y=0, X=2
;   - Black DEF:       Y=1, X=1 / X=2 / X=3
;   - White FWD:       Y=2, X=0 and Y=2, X=4
;   - White MID:       Y=4, X=3
;   - White GK:        Y=255 (hidden), X=2
;
; Virtual player:
;   Var_Game_VirtualPlayerTeam = TEAM_WHITE
;   Var_Game_VirtualPlayerYPos = 4
;   Var_Game_VirtualPlayerXPos = 1
;
; INPUT:
;   -
; OUTPUT:
;   Var_Game_ActiveFieldSide updated to FIELD_NORTH_SIDE
;   Var_Game_PlayersInfo filled for this schema
;   All previous positions cleared (PREV_X/PREV_Y = 255)
; MODIFIES:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
SetBlackRestartSchema:
    LD   A, TEAM_BLACK
    LD   (Var_Game_TeamWithBall), A

    LD     D, 0
    LD     E, 2
    CALL   Game_SetBallPosition
    LD     A, 255
    LD     (Var_Game_BallYOldPosition ), A
    LD     A, BALL_DIRECTION_NONE
    LD     (Var_Game_BallDirection),A

    ; Set active field side to NORTH
    LD   A,FIELD_NORTH_SIDE
    LD   (Var_Game_ActiveFieldSide),A

    LD   A, YES
    LD   (Var_Game_GoalkeeperHasBall), A

    ; ---- BLACK TEAM (TEAM_BLACK) ---------------------------------

    ; Black GK, ID=0, Y=0, X=2
    LD   B,TEAM_BLACK
    LD   C,0                  ; ID=0 (goalkeeper)
    LD   D,0                  ; Y
    LD   E,2                  ; X
    CALL SetPlayerInfo

    ; Black DEF 1, ID=1, Y=1, X=1
    LD   B,TEAM_BLACK
    LD   C,1
    LD   D,1
    LD   E,1
    CALL SetPlayerInfo

    ; Black DEF 2, ID=2, Y=1, X=2
    LD   B,TEAM_BLACK
    LD   C,2
    LD   D,1
    LD   E,2
    CALL SetPlayerInfo

    ; Black DEF 3, ID=3, Y=1, X=3
    LD   B,TEAM_BLACK
    LD   C,3
    LD   D,1
    LD   E,3
    CALL SetPlayerInfo

    ; ---- WHITE TEAM (TEAM_WHITE) ---------------------------------

    ; White GK hidden, ID=0, Y=255, X=2
    LD   B,TEAM_WHITE
    LD   C,0
    LD   D,255
    LD   E,2
    CALL SetPlayerInfo

    ; White FWD 1, ID=1, Y=2, X=0
    LD   B,TEAM_WHITE
    LD   C,1
    LD   D,2
    LD   E,0
    CALL SetPlayerInfo

    ; White FWD 2, ID=2, Y=2, X=4
    LD   B,TEAM_WHITE
    LD   C,2
    LD   D,2
    LD   E,4
    CALL SetPlayerInfo

    ; White MID, ID=3, Y=4, X=3
    LD   B,TEAM_WHITE
    LD   C,3
    LD   D,4
    LD   E,3
    CALL SetPlayerInfo

    ; ---- VIRTUAL PLAYER ------------------------------------------

    LD   A,TEAM_WHITE
    LD   (Var_Game_VirtualPlayerTeam),A

    LD   A,4
    LD   (Var_Game_VirtualPlayerYPos),A   ; Y=4
    LD   A,1
    LD   (Var_Game_VirtualPlayerXPos),A   ; X=1

    ; ---- CLEAR PREVIOUS POSITIONS --------------------------------
    CALL ClearAllPrevPositions

    RET

; ---------------------------------------------------------------------------
; Sets restart-from-goal schema when WHITE team is defending and the
; active field side is SOUTH.
;
; Player layout (Y=row, X=col):
;   - White GK:        Y=4, X=2
;   - White DEF:       Y=3, X=1 / X=2 / X=3
;   - Black FWD:       Y=2, X=0 and Y=2, X=4
;   - Black MID:       Y=0, X=4
;   - Black GK:        Y=255 (hidden), X=2
;
; Virtual player:
;   Var_Game_VirtualPlayerTeam = TEAM_BLACK
;   Var_Game_VirtualPlayerYPos = 0
;   Var_Game_VirtualPlayerXPos = 0
;
; INPUT:
;   -
; OUTPUT:
;   Var_Game_ActiveFieldSide updated to FIELD_SOUTH_SIDE
;   Var_Game_PlayersInfo filled for this schema
;   All previous positions cleared (PREV_X/PREV_Y = 255)
; MODIFIES:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
SetWhiteRestartSchema:
    LD   A, TEAM_WHITE
    LD   (Var_Game_TeamWithBall), A
    LD     D, 4
    LD     E, 2
    CALL   Game_SetBallPosition
    LD     A, 255
    LD     (Var_Game_BallYOldPosition ), A
    LD   A, BALL_DIRECTION_NONE
    LD   (Var_Game_BallDirection),A

    ; Set active field side to SOUTH
    LD   A,FIELD_SOUTH_SIDE
    LD   (Var_Game_ActiveFieldSide),A

    LD   A, YES
    LD   (Var_Game_GoalkeeperHasBall), A

    ; ---- WHITE TEAM (TEAM_WHITE) ---------------------------------

    ; White GK, ID=0, Y=4, X=2
    LD   B,TEAM_WHITE
    LD   C,0
    LD   D,4
    LD   E,2
    CALL SetPlayerInfo

    ; White DEF 1, ID=1, Y=3, X=1
    LD   B,TEAM_WHITE
    LD   C,1
    LD   D,3
    LD   E,1
    CALL SetPlayerInfo

    ; White DEF 2, ID=2, Y=3, X=2
    LD   B,TEAM_WHITE
    LD   C,2
    LD   D,3
    LD   E,2
    CALL SetPlayerInfo

    ; White DEF 3, ID=3, Y=3, X=3
    LD   B,TEAM_WHITE
    LD   C,3
    LD   D,3
    LD   E,3
    CALL SetPlayerInfo

    ; ---- BLACK TEAM (TEAM_BLACK) ---------------------------------

    ; Black GK hidden, ID=0, Y=255, X=2
    LD   B,TEAM_BLACK
    LD   C,0
    LD   D,255
    LD   E,2
    CALL SetPlayerInfo

    ; Black FWD 1, ID=1, Y=2, X=0
    LD   B,TEAM_BLACK
    LD   C,1
    LD   D,2
    LD   E,0
    CALL SetPlayerInfo

    ; Black FWD 2, ID=2, Y=2, X=4
    LD   B,TEAM_BLACK
    LD   C,2
    LD   D,2
    LD   E,4
    CALL SetPlayerInfo

    ; Black MID, ID=3, Y=0, X=4
    LD   B,TEAM_BLACK
    LD   C,3
    LD   D,0
    LD   E,3
    CALL SetPlayerInfo

    ; ---- VIRTUAL PLAYER ------------------------------------------

    LD   A,TEAM_BLACK
    LD   (Var_Game_VirtualPlayerTeam),A

    XOR  A
    LD   (Var_Game_VirtualPlayerYPos),A  
    LD   A, 1
    LD   (Var_Game_VirtualPlayerXPos),A  

    ; ---- CLEAR PREVIOUS POSITIONS --------------------------------
    CALL ClearAllPrevPositions

    RET



; ---------------------------------------------------------------------------
; ResumeGame
;
; Decide il tipo di ripresa in base a:
;   - Var_Game_ActiveFieldSide
;   - posizione Y della palla
;
; Casi:
;   - Campo NORTH, BallY = 1 -> rimessa dal fondo NERA
;   - Campo SOUTH, BallY = 2 -> rimessa dal fondo BIANCA
;   - Campo SOUTH, BallY = 0 -> calcio d'inizio NERO
;   - Campo NORTH, BallY = 3 -> calcio d'inizio BIANCO
;
; In tutti i casi:
;   - sposta palla e giocatore centrale secondo le regole descritte
;   - Var_Game_VirtualPlayerYPos = 255 (virtual sparisce)
;   - Var_Game_BallDirection = BALL_DIRECTION_NONE
;   - Var_Game_GoalkeeperHasBall = NO
;   - chiama VDP_PlayerMatrixRedraw
;
; MODIFICA: AF, BC, DE, HL
; ---------------------------------------------------------------------------
Game_Resume:
    push af
    push bc
    push de
    push hl

    ; ---- palla ferma e nessun portiere con palla ----
    ld   a,BALL_DIRECTION_NONE
    ld   (Var_Game_BallDirection),a

    ld   a,NO
    ld   (Var_Game_GoalkeeperHasBall),a

    ; ---- nascondi virtual player ----
    ;ld   a,255
    ;ld   (Var_Game_VirtualPlayerYPos),a

    ; ---- leggi posizione palla ----
    call Game_GetBallPosition      
    ; salviamo Y in C per i confronti
    ld   c,d                   ; C = Y

    ; ---- leggi direzione campo ----
    ld   a,(Var_Game_ActiveFieldSide)
    cp   FIELD_NORTH_SIDE
    jr   z,.field_north

    ; ===== FIELD_SOUTH_SIDE =====
.field_south:
    ld   a,c                   ; A = BallY
    cp   4
    jr   z,.white_goal_kick    ; rimessa dal fondo BIANCA

    cp   0
    jr   z,.black_kickoff      ; calcio d'inizio NERO

    jr   .resume_done          ; nessun caso riconosciuto

    ; ===== FIELD_NORTH_SIDE =====
.field_north:
    ld   a,c                   ; A = BallY
    cp   0
    jr   z,.black_goal_kick    ; rimessa dal fondo NERA

    cp   3
    jr   z,.white_kickoff      ; calcio d'inizio BIANCO

    jr   .resume_done          ; nessun caso riconosciuto

; --- Rimessa dal fondo BIANCA (campo SOUTH, ballY = 2) ---
.white_goal_kick:
    call Resume_WhiteGoalKick
    jr   .after_case

; --- Rimessa dal fondo NERA (campo NORTH, ballY = 1) ---
.black_goal_kick:
    call Resume_BlackGoalKick
    jr   .after_case

; --- Calcio d'inizio NERO (campo SOUTH, ballY = 0) ---
.black_kickoff:
    call Resume_BlackKickoff
    jr   .after_case

; --- Calcio d'inizio BIANCO (campo NORTH, ballY = 3) ---
.white_kickoff:
    call Resume_WhiteKickoff
    ; fall-through

.after_case:

    ; ridisegna i giocatori (la palla verrà ridisegnata nella nuova posizione)
    call VDP_PlayerMatrixRedraw

.resume_done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ;call Hooks_TickStart
    ret

; ---------------------------------------------------------------------------
; Resume_WhiteGoalKick
;
; Schema atteso:
;   - Palla:    Y=2, X=2
;   - Bianchi:  Y=3, X=1,2,3   (centrale a 3,2)
;
; Azioni:
;   - Palla -> (Y=2, X=1 o 3 a caso)
;   - Giocatore centrale -> Y=1, X=random(0..4)
; ---------------------------------------------------------------------------
Resume_WhiteGoalKick:
    XOR  A
    LD   (Var_Game_FirstKickFrameCounter), A
    LD   A, FIRST_KICK_TYPE_WHITE_BOTTOM_FIELD
    LD   (Var_Game_FirstKickType), A
    LD   D, 2
    LD   E, 2
    CALL Game_SetBallPosition
    CALL VDP_PlayerMatrixRedraw
    RET
.exec:
    CALL  VDP_RemoveVirtualPlayer
    ; --- sposta la palla su colonna 1 o 3 della stessa riga (Y=2) ---
    call Game_GetRandomByte
    and  1
    ld   l,1                ; default X = 1
    jr   z,.ball_pos_ok
    ld   l,3                ; X = 3
.ball_pos_ok:
    ld   h,2                ; Y = 2
    PUSH HL
    POP  DE
    call Game_SetBallPosition

    ; --- trova il giocatore centrale bianco (Y=3, X=2) ---
    ld   d,3                ; Y=3
    ld   e,2                ; X=2
    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    ret  z                  ; se non trovato, esci senza fare altro

    ; qui: B = TEAM, C = ID del giocatore centrale

    ; --- genera nuova X (0..4) e sposta a Y=1 ---
    call Game_GetRandom0_4  ; A = 0..4
    ld   e,a                ; E = newX
    ld   d,1                ; D = newY (1)
    call SetPlayerInfo
    LD   A, YES
    LD   (Var_Hooks_ForceVdpRedraw), A
    LD   A, NO_VALUE
    LD   (Var_Game_FirstKickType), A
    CALL Hooks_TickStart
    call Game_PlayBeep
    JP   VBlankISR.Exit
	ret
; ---------------------------------------------------------------------------
; Resume_BlackGoalKick
;
; Schema atteso:
;   - Palla:   Y=1, X=2
;   - Neri:    Y=1, X=1,2,3   (centrale a 1,2)
;
; Azioni:
;   - Palla -> (Y=1, X=1 o 3 a caso)
;   - Giocatore centrale -> Y=3, X=random(0..4)
; ---------------------------------------------------------------------------
Resume_BlackGoalKick:
    XOR  A
    LD   (Var_Game_FirstKickFrameCounter), A
    LD   A, FIRST_KICK_TYPE_BLACK_BOTTOM_FIELD
    LD   (Var_Game_FirstKickType), A
    LD   D, 1
    LD   E, 2
    CALL Game_SetBallPosition
    CALL VDP_PlayerMatrixRedraw
    ret
.exec:
    CALL  VDP_RemoveVirtualPlayer
        ; --- sposta la palla su colonna 1 o 3 della stessa riga (Y=1) ---
    call Game_GetRandomByte
    and  1
    ld   l,1                ; default X = 1
    jr   z,.ball_pos_ok
    ld   l,3                ; X = 3
.ball_pos_ok:
    ld   h,1                ; Y = 1
    PUSH HL
    POP  DE
    call Game_SetBallPosition

    ; --- trova il giocatore centrale nero (Y=1, X=2) ---
    ld   d,1                ; Y=1
    ld   e,2                ; X=2
    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    ret  z
    
    ; B = TEAM, C = ID del centrale

    ; --- genera nuova X (0..4) e sposta a Y=3 ---
    call Game_GetRandom0_4
    ld   e,a                ; newX
    ld   d,3                ; newY = 3
    call SetPlayerInfo
    LD   A, YES
    LD   (Var_Hooks_ForceVdpRedraw), A
    LD   A, NO_VALUE
    LD   (Var_Game_FirstKickType), A
    CALL Hooks_TickStart
    call Game_PlayBeep
    JP   VBlankISR.Exit
    ret
; ---------------------------------------------------------------------------
; Resume_BlackKickoff
;
; Schema atteso:
;   - Palla:   Y=0, X=2
;   - Neri:    Y=0, X=1,2,3   (centrale a 0,2)
;
; Azioni:
;   - Palla -> (Y=0, X=1 o 3 a caso)
;   - Giocatore centrale -> Y=2, X=random(0..4)
; ---------------------------------------------------------------------------
Resume_BlackKickoff:
    XOR  A
    LD   (Var_Game_FirstKickFrameCounter), A
    LD   A, FIRST_KICK_TYPE_BLACK_HALF_FIELD
    LD   (Var_Game_FirstKickType), A
    RET
.exec:
    CALL  VDP_RemoveVirtualPlayer
    ; --- sposta la palla su colonna 1 o 3 della stessa riga (Y=0) ---
    call Game_GetRandomByte
    and  1
    ld   l,1                ; default X = 1
    jr   z,.ball_pos_ok
    ld   l,3                ; X = 3
.ball_pos_ok:
    ld   h,0                ; Y = 0
    PUSH HL
    POP  DE
    call Game_SetBallPosition

    ; --- trova il giocatore centrale nero (Y=0, X=2) ---
    ld   d,0                ; Y=0
    ld   e,2                ; X=2
    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    ret  z

    ; B = TEAM, C = ID

    ; --- genera nuova X (0..4) e sposta a Y=2 ---
    call Game_GetRandom0_4
    ld   e,a                ; newX
    ld   d,2                ; newY = 2
    call SetPlayerInfo
    LD   A, YES
    LD   (Var_Hooks_ForceVdpRedraw), A
    LD   A, NO_VALUE
    LD   (Var_Game_FirstKickType), A
    CALL Hooks_TickStart
    call Game_PlayBeep
    JP   VBlankISR.Exit
    ret
; ---------------------------------------------------------------------------
; Resume_WhiteKickoff
;
; Schema atteso:
;   - Palla:   Y=3, X=2
;   - Bianchi: Y=4, X=1,2,3   (centrale a 4,2)
;
; Azioni:
;   - Palla -> (Y=3, X=1 o 3 a caso)
;   - Giocatore centrale -> Y=2, X=random(0..4)
; ---------------------------------------------------------------------------
Resume_WhiteKickoff:
    XOR  A
    LD   (Var_Game_FirstKickFrameCounter), A
    LD   A, FIRST_KICK_TYPE_WHITE_HALF_FIELD
    LD   (Var_Game_FirstKickType), A
    RET
.exec:
    CALL  VDP_RemoveVirtualPlayer
    ; --- sposta la palla su colonna 1 o 3 della stessa riga (Y=3) ---
    call Game_GetRandomByte
    and  1
    ld   l,1                ; default X = 1
    jr   z,.ball_pos_ok
    ld   l,3                ; X = 3
.ball_pos_ok:
    ld   h,3                ; Y = 3
    PUSH HL
    POP  DE
    call Game_SetBallPosition

    ; --- trova il giocatore centrale bianco (Y=4, X=2) ---
    ld   d,4                ; Y=4
    ld   e,2                ; X=2
    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    ret  z

    ; B = TEAM, C = ID

    ; --- genera nuova X (0..4) e sposta a Y=2 ---
    call Game_GetRandom0_4
    ld   e,a                ; newX
    ld   d,2                ; newY = 2
    call SetPlayerInfo
    LD   A, YES
    LD   (Var_Hooks_ForceVdpRedraw), A
    LD   A, NO_VALUE
    LD   (Var_Game_FirstKickType), A
    CALL Hooks_TickStart
    call Game_PlayBeep
    JP   VBlankISR.Exit
    ret

; ---------------------------------------------------------------------------
; Game_GetRandomByte
; Restituisce 0..255 utilizzando Utils_GetRandomNumber (0..127)
; MODIFIES: AF, BC
; ---------------------------------------------------------------------------
Game_GetRandomByte:
    CALL Utils_GetRandomNumber     ; A = 0..127
    SLA  A                         ; 0..254 (raddoppio)
    RET
; ---------------------------------------------------------------------------
; Game_GetRandom0_4
; Restituisce A = 0..4
; MODIFIES: AF
; ---------------------------------------------------------------------------
Game_GetRandom0_4:
    PUSH BC
    PUSH DE
    PUSH HL
    CALL Utils_GetRandomNumber     ; A = 0..127

    ; riduci a 0..7 (modulo 8)
    AND  00000111b                 ; 0..7

    CP   5
    JR   C,.ok                     ; 0..4 → ok
    SUB  5                         ; 5,6,7 → 0,1,2
.ok:
    POP  HL
    POP  DE
    POP  BC
    RET

; ---------------------------------------------------------------------------
; Game_GetRandom0_20
; Restituisce A = 0..20
; Usa Utils_GetRandomNumber (0..127)
; MODIFIES: AF
; ---------------------------------------------------------------------------
Game_GetRandom0_20:
    PUSH BC
.loop:
    CALL Utils_GetRandomNumber     ; A = 0..127
    CP   105                       ; 105 = 21 * 5
    JR   NC,.loop                  ; scarta 105..127
    ; A = 0..104
    LD   B,21
    ; A mod 21
.mod:
    SUB  B
    JR   NC,.mod
    ADD  B                         ; ripristina ultimo valido
    POP  BC
    RET





; ---------------------------------------------------------------------------
; Game_GetPlayerIdWithBall
;
; Determina chi possiede la palla (se qualcuno) a seconda della posizione
; della palla e dei giocatori.
;
; OUTPUT:
;   A = TEAM_BLACK / TEAM_WHITE
;       oppure BALL_STATUS_MOVING / BALL_STATUS_FREE / BALL_STATUS_CONTENDED
;   H = ID giocatore che possiede la palla (0..3) oppure 255 se nessuno
;   L = ID eventuale contendente (per ora sempre 255 nei casi definiti)
;
; MODIFIES:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
Game_GetPlayerIdWithBall:
    ; default: nessuno
    ld   h,255
    ld   l,255

    ; --- 1) se la palla è in movimento, nessun possesso -------------------
    ld   a,(Var_Game_BallDirection)
    cp   BALL_DIRECTION_NONE
    jr   z,.check_static
    ld   a,BALL_STATUS_MOVING
    ret

.check_static:
    ; --- 2) HL = X,Y della palla -----------------------------------------
    call  Game_GetBallPosition      
    PUSH  DE                     
    POP   HL                    
    ; azzera i flag temporanei
    xor  a
    ld   (Var_Game_BallTmp_FoundBelow),a
    ld   (Var_Game_BallTmp_FoundAbove),a

    ; salviamo la posizione della palla
    push hl                     ; [SP] = X,Y

    ; ============================================================
    ; Test 1: stessa cella della palla (giocatore nero, se presente)
    ; ============================================================
    ; D = Y, E = X
    ld   d,h
    ld   e,l
    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    jr   z,.no_player_below

    ; trovato giocatore "sotto" (in stessa cella della palla)
    ld   a,1
    ld   (Var_Game_BallTmp_FoundBelow),a
    ld   a,b
    ld   (Var_Game_BallTmp_TeamBelow),a
    ld   a,c
    ld   (Var_Game_BallTmp_IdBelow),a

.no_player_below:

    ; ============================================================
    ; Test 2: riga successiva stessa colonna (giocatore bianco, se presente)
    ; ============================================================
    pop  hl                     ; HL = X,Y (ripristinato)
    push hl                     ; lo risalviamo per sicurezza (anche se poi non lo useremo più)

    ld   a,h                    ; A = Y
    cp   4
    jr   z,.no_player_above     ; se Y=4, non esiste Y+1 nel campo 0..4

    inc  a                      ; Y+1
    ld   d,a                    ; D = Y+1
    ld   e,l                    ; E = X
    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    jr   z,.no_player_above

    ; trovato giocatore "sopra" (in riga successiva)
    ld   a,1
    ld   (Var_Game_BallTmp_FoundAbove),a
    ld   a,b
    ld   (Var_Game_BallTmp_TeamAbove),a
    ld   a,c
    ld   (Var_Game_BallTmp_IdAbove),a

.no_player_above:
    pop  hl                     ; buttiamo via la copia di sicurezza

    ; ============================================================
    ; 3) Valutazione combinazioni
    ; ============================================================

    ; carichiamo flag in A/B solo per facilità
    ld   a,(Var_Game_BallTmp_FoundBelow)
    ld   b,a                     ; B = foundBelow (0/1)
    ld   a,(Var_Game_BallTmp_FoundAbove)
    ld   c,a                     ; C = foundAbove (0/1)

    ; caso: nessuno dei due
    ld   a,b
    or   c
    jr   nz,.not_free

    ; nessun giocatore sotto né sopra
    ld   a,BALL_STATUS_FREE
    ld   h,255
    ld   l,255
    ret

.not_free:
    ; caso: entrambi presenti → palla contesa
    ld   a,b                     ; A = foundBelow
    and  c                       ; A = 1 solo se entrambi sono 1
    jr   z,.single_side

    ; palla contesa tra nero e bianco
    ld   a,BALL_STATUS_CONTENDED
    ld   h,255
    ld   l,255
    ret

.single_side:
    ; se qui: esattamente uno dei due è 1.

    ; se foundBelow = 1 (giocatore nella cella della palla) → nero
    ld   a,b
    or   a
    jr   z,.only_above

    ; --- solo giocatore nella cella della palla (nero) --------------------
    ld   a,(Var_Game_BallTmp_IdBelow)    ; ID
    ld   h,a
    ld   a,(Var_Game_BallTmp_TeamBelow)  ; TEAM (tipicamente TEAM_BLACK)
    
    ld   l,255
    ret

.only_above:
    ; --- solo giocatore nella riga successiva (bianco) --------------------
    ld   a,(Var_Game_BallTmp_IdAbove)    ; ID
    ld   h,a
    ld   a,(Var_Game_BallTmp_TeamAbove)  ; TEAM (tipicamente TEAM_WHITE)
    
    ld   l,255
    ret
; ---------------------------------------------------------------------------
; Game_TryMovePlayerVertically
;
; INPUT:
;   B = TEAM  (TEAM_BLACK / TEAM_WHITE)
;   C = ID    (0..3)
;   A = direzione richiesta:
;       PLAYER_ASKED_DIRECTION_NORTH
;       PLAYER_ASKED_DIRECTION_SOUTH
;
; OUTPUT:
;   A = SUCCESS oppure FAILURE
;
; MODIFIES:
;   AF, BC, DE, HL
; ---------------------------------------------------------------------------
Game_TryMovePlayerVertically:
    ; Salva la direzione richiesta
    push af              ; [SP] = dir


    ; --- i portieri NON possono muoversi verticalmente ---
    ld   a,c
    or   a
    jp   nz, .gtmv_not_goalkeeper

    ; ID=0 → portiere → FALLISCE
    pop  af              ; rimuovi dir dallo stack
    ld   a,FAILURE
    ret

.gtmv_not_goalkeeper:
    ; --- verifica che il giocatore NON abbia la palla ---
    push bc              ; salva TEAM/ID per il confronto
    call Game_GetPlayerIdWithBall
    ; Risultato:
    ;   A = stato/team (TEAM_BLACK/TEAM_WHITE o BALL_STATUS_xxx)
    ;   H = ID del giocatore in possesso (o 255)
    ;   L = ID contendente (o 255)
    pop  bc              ; ripristina B=TEAM, C=ID del giocatore richiesto
    CP   BALL_STATUS_CONTENDED
    JR   NZ, .no_contended_ball

    pop  af              ; rimuovi dir dallo stack
    ld   a,FAILURE
    ret

.no_contended_ball:
    ; Se A è TEAM_BLACK o TEAM_WHITE e (A==B e H==C) → ha la palla
    ld   d,a             ; D = stato/team


    cp   TEAM_BLACK
    jp   z, .gtmv_check_owner_team
    cp   TEAM_WHITE
    jp   nz, .gtmv_no_ball_owned   ; stato non è un team → nessuno in possesso

.gtmv_check_owner_team:
    ; A = TEAM_BLACK o TEAM_WHITE, D = stesso valore
    cp   b
    jp   nz, .gtmv_no_ball_owned   ; altra squadra

    ; stessa squadra, confronta ID
    ld   a,h                       ; H = ID possessore
    cp   c
    jp   nz, .gtmv_no_ball_owned   ; non è il nostro giocatore

    ; --- il giocatore richiesto ha la palla → non può muoversi verticalmente ---
    pop  af                        ; rimuovi dir dallo stack
    ld   a,FAILURE
    ret

.gtmv_no_ball_owned:
    ; --- recupera posizione corrente del giocatore ---
    call Game_GetPlayerInfoById    ; HL = curr (H=Y, L=X)

    push hl
    pop de                        ; DE = curr (D=currY, E=currX)
    CALL CheckBallAtPosition
    CP   YES
    jp   z, .gtmv_fail_pop        ; palla sulla posizione corrente
    ; HL: H = currY, L = currX
    pop  af                        ; A = direzione richiesta
    ld   d,a                       ; D = direzione
    ; H = currY, L = currX, B = TEAM, C = ID

    ; --- controlla metà campo attiva ---
    ld   a,(Var_Game_ActiveFieldSide)
    cp   FIELD_NORTH_SIDE
    jp   z, .gtmv_side_north

    ; --------- FIELD_SOUTH_SIDE ---------------------------------
.gtmv_side_south:
    ld   a,b
    cp   TEAM_WHITE
    jp   z, .gtmv_south_white

    ; ----- TEAM_BLACK, FIELD_SOUTH_SIDE -----
    ld   a,d                      ; direzione
    cp   PLAYER_ASKED_DIRECTION_NORTH
    jp   z, .gtmv_sb_move_up
    cp   PLAYER_ASKED_DIRECTION_SOUTH
    jp   z, .gtmv_sb_move_down
    jp   .gtmv_fail               ; direzione invalida

; Nero, campo SOUTH, move NORTH:
; deve essere su riga 2, target riga 0
.gtmv_sb_move_up:
    ld   a,h                      ; currY
    cp   2
    jp   nz, .gtmv_fail

    ; verifica che in (Y=0, X=L) non ci sia nessun giocatore
    ld   d,0                      ; targetY
    ld   e,l                      ; targetX = currX
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    cp   NO_VALUE
    jp   nz, .gtmv_fail           ; cella occupata

    ; verifica che in (Y=0, X=L) non ci sia la palla
    ;ld   d,0
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_sb_up
    ;jp   .gtmv_fail               ; palla sulla destinazione

.no_ball_sb_up:
    ; conta i compagni sulla riga 0
    push bc
    ld   d,0
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   nc, .gtmv_fail           ; già 2 → non possiamo aggiungerne un terzo

    ; sposta il giocatore a (0, X)
    ld   d,0
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success

; Nero, campo SOUTH, move SOUTH:
; deve essere su riga 0, target riga 2
.gtmv_sb_move_down:
    ld   a,h                      ; currY
    cp   0
    jp   nz, .gtmv_fail

    ld   d,2
    ld   e,l
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    cp   NO_VALUE
    jp   nz, .gtmv_fail

    ;; verifica palla in (2, currX)
    ;ld   d,2
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_sb_down
    ;jp   .gtmv_fail

.no_ball_sb_down:
    ; conta i compagni sulla riga 2
    push bc
    ld   d,2
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   nc, .gtmv_fail

    ld   d,2
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success

; ----- TEAM_WHITE, FIELD_SOUTH_SIDE -----
.gtmv_south_white:
    ld   a,d                      ; direzione
    cp   PLAYER_ASKED_DIRECTION_NORTH
    jp   z, .gtmv_sw_move_up
    cp   PLAYER_ASKED_DIRECTION_SOUTH
    jp   z, .gtmv_sw_move_down
    jp   .gtmv_fail

; Bianco, campo SOUTH, move NORTH:
; deve essere su riga 3, target riga 1
.gtmv_sw_move_up:
    ld   a,h                      ; currY
    cp   3
    jp   nz, .gtmv_fail


    ld   d,1
    ld   e,l
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    cp   NO_VALUE

    jp   nz, .gtmv_fail

    ; verifica palla in (1, currX)
    ;ld   d,1
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_sw_up
    ;jp   .gtmv_fail

.no_ball_sw_up:
    ; conta i compagni sulla riga 1
    push bc
    ld   d,1
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   nc, .gtmv_fail

    ld   d,1
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success

; Bianco, campo SOUTH, move SOUTH:
; deve essere su riga 1, target riga 3
.gtmv_sw_move_down:
    ld   a,h                      ; currY
    cp   1
    jp   nz, .gtmv_fail

    
    ld   d,3
    ld   e,l
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    
    cp   NO_VALUE
    
    jp   nz, .gtmv_fail

    ; verifica palla in (3, currX)
    ;ld   d,3
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_sw_down
    ;jp   .gtmv_fail

.no_ball_sw_down:
    ; conta i compagni sulla riga 3
    push bc
    ld   d,3
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   nc, .gtmv_fail

    ld   d,3
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success


; --------- FIELD_NORTH_SIDE ------------------------------------
.gtmv_side_north:
    ld   a,b
    cp   TEAM_WHITE
    jp   z, .gtmv_north_white

    ; ----- TEAM_BLACK, FIELD_NORTH_SIDE -----
    ld   a,d                      ; direzione
    cp   PLAYER_ASKED_DIRECTION_NORTH
    jp   z, .gtmv_nb_move_up
    cp   PLAYER_ASKED_DIRECTION_SOUTH
    jp   z, .gtmv_nb_move_down
    jp   .gtmv_fail

; Nero, campo NORTH, move NORTH:
; deve essere su riga 3, target riga 1
.gtmv_nb_move_up:
    ld   a,h                      ; currY
    cp   3
    jp   nz, .gtmv_fail


    ld   d,1
    ld   e,l
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    cp   NO_VALUE

    jp   nz, .gtmv_fail

    ; verifica palla in (1, currX)
    ;ld   d,1
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_nb_up
    ;jp   .gtmv_fail

.no_ball_nb_up:
    ; conta i compagni sulla riga 1
    push bc
    ld   d,1
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   z, .gtmv_fail

    ld   d,1
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success

; Nero, campo NORTH, move SOUTH:
; deve essere su riga 1, target riga 3
.gtmv_nb_move_down:
    ld   a,h
    cp   1
    jp   nz, .gtmv_fail

    ld   d,3
    ld   e,l
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    cp   NO_VALUE
    jp   nz, .gtmv_fail

    ; verifica palla in (3, currX)
    ;ld   d,3
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_nb_down
    ;jp   .gtmv_fail

.no_ball_nb_down:
    ; conta i compagni sulla riga 3
    push bc
    ld   d,3
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   nc, .gtmv_fail

    ld   d,3
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success

; ----- TEAM_WHITE, FIELD_NORTH_SIDE -----
.gtmv_north_white:
    ld   a,d                      ; direzione
    cp   PLAYER_ASKED_DIRECTION_NORTH
    jp   z, .gtmv_nw_move_up
    cp   PLAYER_ASKED_DIRECTION_SOUTH
    jp   z, .gtmv_nw_move_down
    jp   .gtmv_fail

; Bianco, campo NORTH, move NORTH:
; deve essere su riga 4, target riga 2
.gtmv_nw_move_up:
    ld   a,h                      ; currY
    cp   4
    jp   nz, .gtmv_fail

    ld   d,2
    ld   e,l
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    cp   NO_VALUE
    jp   nz, .gtmv_fail

    ; verifica palla in (2, currX)
    ;ld   d,2
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_nw_up
    ;jp   .gtmv_fail

.no_ball_nw_up:
    ; conta i compagni sulla riga 2
    push bc
    ld   d,2
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   nc, .gtmv_fail

    ld   d,2
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success

; Bianco, campo NORTH, move SOUTH:
; deve essere su riga 2, target riga 4
.gtmv_nw_move_down:
    ld   a,h                      ; currY
    cp   2
    jp   nz, .gtmv_fail

    ld   d,4
    ld   e,l
    push bc
    push hl
    call Game_GetPlayerInfoByPos
    pop  hl
    pop  bc
    cp   NO_VALUE
    jp   nz, .gtmv_fail

    ; verifica palla in (4, currX)
    ;ld   d,4
    ;ld   e,l
    ;CALL CheckBallAtPosition
    ;CP   NO
    ;jp   z, .no_ball_nw_down
    ;jp   .gtmv_fail

.no_ball_nw_down:
    ; conta i compagni sulla riga 4
    push bc
    ld   d,4
    call Game_CountTeamPlayersOnRow
    pop  bc
    cp   2
    jp   nc, .gtmv_fail

    ld   d,4
    ld   e,l
    ;call SetPlayerInfo
    jp   .gtmv_success


; -------------------------------------------------------------------
.gtmv_success:
    call SetPlayerInfo
    ;CALL VDP_PlayerMatrixRedraw
    LD     A, YES
    LD     (Var_Hooks_ForceVdpRedraw), A
    ld   a,SUCCESS
    ret

.gtmv_fail:
    ld   a,FAILURE
    ret
.gtmv_fail_pop:
    pop  af                        ; rimuovi dir dallo stack
    JR   .gtmv_fail
;---------------------------------------------------------------------------
; Game_CheckBallAtPosition
; Controlla se la palla si trova in (D,E).
; INPUT:
;   D = Y
;   E = X
; OUTPUT:
;   A = YES (1) se la palla è in (D,E), NO (0) altrimenti
; ---------------------------------------------------------------------------
CheckBallAtPosition:
    push hl
    push de
    pop  hl

    call Game_GetBallPosition   
    ld   a, d
    cp   h
    jr   nz, .NotFound 
    ld   a, e
    cp   l
    jr   nz, .NotFound
    LD   a, YES
.Done:
    pop  hl
    
    ret
.NotFound:
    LD   a, NO
    jp   .Done
; ---------------------------------------------------------------------------
; TryShot
; INPUT:
;   B = TEAM (TEAM_BLACK / TEAM_WHITE)
;   C = ID   (giocatore con palla)
;
; OUTPUT:
;   Var_Game_BallDirection impostata
;   Var_Game_BallDiagonalMovCounter:
;       - 255 solo se (ActiveFieldSide=NORTH, TEAM=WHITE, shooterY=2)
;       - 0 in tutti gli altri casi
; ---------------------------------------------------------------------------
Game_TryShot:
    push af
    push bc
    push de
    push hl


    ; Leggi posizione giocatore (H=Y, L=X)
    call Game_GetPlayerInfoById

    ; Default counter=0
    xor  a
    ld   (Var_Game_BallDiagonalMovCounter),a

    ; Se campo NORTH e bianco e Y=2 => counter=255 (caso speciale)
    ld   a,(Var_Game_ActiveFieldSide)
    cp   FIELD_NORTH_SIDE
    jr   nz,.counter_done
    ld   a,b
    cp   TEAM_WHITE
    jr   nz,.counter_done
    ld   a,h
    cp   2
    jr   nz,.counter_done
    ld   a,255
    ld   (Var_Game_BallDiagonalMovCounter),a
.counter_done:

    ; Decide direzione in base a campo/team/riga/colonna
    ld   a,(Var_Game_ActiveFieldSide)
    cp   FIELD_NORTH_SIDE
    jr   z,.field_north
    jp   .field_south

; ==========================
; CAMPO VISIBILE: NORTH
; ==========================
.field_north:
    ld   a,b
    cp   TEAM_BLACK
    jr   z,.north_black
    ; altrimenti TEAM_WHITE
    jr   .north_white

.north_black:
    ; Nero: da qualsiasi riga -> SOUTH / SOUTH_EAST / SOUTH_WEST
    ; con vincolo bordo: X=0 => no SOUTH_WEST, X=4 => no SOUTH_EAST
    call Game_GetRandomByte
    and  00000011b          ; 0..3
    cp   3
    jr   nz,.nb_r_ok
    xor  a                  ; 3 -> 0
.nb_r_ok:
    ; A = 0..2
    ; 0=SOUTH, 1=SOUTH_EAST, 2=SOUTH_WEST (poi validiamo bordi)
    ld   d,a                ; D = scelta

    ld   a,l                ; X
    cp   0
    jr   nz,.nb_not_left
    ; X=0: se scelta = SOUTH_WEST (2) -> forza SOUTH (0) o SOUTH_EAST (1)
    ld   a,d
    cp   2
    jr   nz,.nb_not_left
    ; forza SOUTH_EAST (più "naturale" da sinistra) oppure SOUTH
    ld   d,1
.nb_not_left:
    ld   a,l
    cp   4
    jr   nz,.nb_choose
    ; X=4: se scelta = SOUTH_EAST (1) -> forza SOUTH_WEST (2) o SOUTH
    ld   a,d
    cp   1
    jr   nz,.nb_choose
    ld   d,2
.nb_choose:
    ld   a,d
    or   a
    jp   z,.set_south
    cp   1
    jp   z,.set_se
    ; 2
    jp   .set_sw

.north_white:
    ld   a,h                ; Y
    cp   4
    jr   z,.nw_y4
    cp   2
    jr   z,.nw_y2
    ; Fuori dalle righe previste: niente tiro
    jp   .stop_shot

.nw_y4:
    ; Bianco da riga 4: NORTH / NE / NW
    ; vincolo bordo: X=0 => no NW, X=4 => no NE
    call Game_GetRandomByte
    and  00000011b          ; 0..3
    cp   3
    jr   nz,.nw4_r_ok
    xor  a
.nw4_r_ok:
    ; 0=NORTH, 1=NE, 2=NW
    ld   d,a

    ld   a,l
    cp   0
    jr   nz,.nw4_not_left
    ld   a,d
    cp   2
    jr   nz,.nw4_not_left
    ld   d,1                ; da sinistra, evita NW -> forza NE (o straight, ma NE va bene)
.nw4_not_left:
    ld   a,l
    cp   4
    jr   nz,.nw4_choose
    ld   a,d
    cp   1
    jr   nz,.nw4_choose
    ld   d,2                ; da destra, evita NE -> forza NW
.nw4_choose:
    ld   a,d
    or   a
    jp   z,.set_north
    cp   1
    jp   z,.set_ne
    jp   .set_nw

.nw_y2:
    ; Caso speciale attaccante bianco in riga 2 (campo NORTH)
    ; - se X=1..3 -> NORTH
    ; - se X=0 -> NORTH_EAST
    ; - se X=4 -> NORTH_WEST
    ld   a,l
    cp   0
    jp   z,.set_ne
    cp   4
    jp   z,.set_nw
    jr   .set_north


; ==========================
; CAMPO VISIBILE: SOUTH
; ==========================
.field_south:
    ld   a,b
    cp   TEAM_WHITE
    jr   z,.south_white
    ; altrimenti TEAM_BLACK
    jr   .south_black

.south_white:
    ; Bianco: da qualsiasi riga -> NORTH / NE / NW
    ; vincolo bordo: X=0 => no NW, X=4 => no NE
    call Game_GetRandomByte
    and  00000011b
    cp   3
    jr   nz,.sw_r_ok
    xor  a
.sw_r_ok:
    ; 0=NORTH, 1=NE, 2=NW
    ld   d,a

    ld   a,l
    cp   0
    jr   nz,.sw_not_left
    ld   a,d
    cp   2
    jr   nz,.sw_not_left
    ld   d,1
.sw_not_left:
    ld   a,l
    cp   4
    jr   nz,.sw_choose
    ld   a,d
    cp   1
    jr   nz,.sw_choose
    ld   d,2
.sw_choose:
    ld   a,d
    or   a
    jr   z,.set_north
    cp   1
    jr   z,.set_ne
    jr   .set_nw

.south_black:
    ld   a,h                ; Y
    cp   0
    jr   z,.sb_y0
    cp   2
    jr   z,.sb_y2
    jr   .stop_shot

.sb_y0:
    ; Nero da riga 0: SOUTH / SE / SW
    ; vincolo bordo: X=0 => no SW, X=4 => no SE
    call Game_GetRandomByte
    and  00000011b
    cp   3
    jr   nz,.sb0_r_ok
    xor  a
.sb0_r_ok:
    ; 0=SOUTH, 1=SE, 2=SW
    ld   d,a

    ld   a,l
    cp   0
    jr   nz,.sb0_not_left
    ld   a,d
    cp   2
    jr   nz,.sb0_not_left
    ld   d,1
.sb0_not_left:
    ld   a,l
    cp   4
    jr   nz,.sb0_choose
    ld   a,d
    cp   1
    jr   nz,.sb0_choose
    ld   d,2
.sb0_choose:
    ld   a,d
    or   a
    jr   z,.set_south
    cp   1
    jr   z,.set_se
    jr   .set_sw

.sb_y2:
    ; Nero in riga 2 (campo SOUTH):
    ; - X=1..3 -> SOUTH
    ; - X=0 -> SOUTH_EAST
    ; - X=4 -> SOUTH_WEST
    ld   a,l
    cp   0
    jr   z,.set_se
    cp   4
    jr   z,.set_sw
    jr   .set_south


; ==========================
; SET DIREZIONI
; ==========================
.set_north:
    ld   a,BALL_DIRECTION_NORTH
    jr   .store_dir
.set_south:
    ld   a,BALL_DIRECTION_SOUTH
    jr   .store_dir
.set_ne:
    ld   a,BALL_DIRECTION_NORTH_EAST
    jr   .store_dir
.set_nw:
    ld   a,BALL_DIRECTION_NORTH_WEST
    jr   .store_dir
.set_se:
    ld   a,BALL_DIRECTION_SOUTH_EAST
    jr   .store_dir
.set_sw:
    ld   a,BALL_DIRECTION_SOUTH_WEST
    jr   .store_dir

.store_dir:
    ld   (Var_Game_BallDirection),a
    call Game_PlayBeep
    jr   .done

.stop_shot:
    call Game_StopShot

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret


; ---------------------------------------------------------------------------
; Game_StopShot
; Ferma il tiro: azzera direzione e counter diagonale.
; ---------------------------------------------------------------------------
Game_StopShot:
    ld   a, BALL_DIRECTION_NONE
    ld   (Var_Game_BallDirection),a         ; BALL_DIRECTION_NONE = 0 (assunto)
    ld   (Var_Game_BallDiagonalMovCounter),a
    ret


; ---------------------------------------------------------------------------
; Game_CountTeamPlayersOnRow
; Conta quanti giocatori della squadra B sono sulla riga D (Y = D).
;
; INPUT:
;   B = TEAM  (TEAM_BLACK / TEAM_WHITE)
;   D = Y (riga da controllare)
;
; OUTPUT:
;   A = numero di giocatori (0..4)
;
; MODIFIES:
;   AF, C, DE, HL
; ---------------------------------------------------------------------------
Game_CountTeamPlayersOnRow:
    PUSH BC
    PUSH DE
    PUSH HL
    LD   A, D
    CALL GetAllPlayersOnARow
    LD   A, B
    CP   NO_VALUE
    JR   Z, .NoPlayersFound
    LD   A, C
    CP   NO_VALUE
    JR   Z, .OnePlayerFound
    LD   A, 2
.Done:
    POP  HL
    POP  DE
    POP  BC
    RET
.OnePlayerFound:
    LD   A, 1
    JP   .Done
.NoPlayersFound:
    XOR  A
    JP   .Done

; ---------------------------------------------------------------------------
; MoveGoalKeeper
; INPUT: B: Team
; ---------------------------------------------------------------------------
MoveGoalKeeper:
    PUSH DE
    PUSH HL
    PUSH BC
    DI
    CALL Hooks_TickStop
    LD   C, 0
    CALL Game_GetPlayerInfoById
    LD   A, H
    CP   NO_VALUE
    JR   Z, .done

    ld   a, (Var_Game_MoveTmpDir)
    cp   PLAYER_ASKED_DIRECTION_EAST
    jr   nz, .move_west
    ; --- move east ---
    inc  l
    LD   A, L
    CP   4
    JR   Z, .done
    JP   .set_pos
.move_west:

    ; --- move west ---
    dec  l
    LD   A, L
    CP   0
    JR   Z, .done
.set_pos:
    POP  BC
    PUSH BC
    LD   C, 0
    LD   D, H
    LD   E, L
    CALL SetPlayerInfo
    LD   A, YES
    LD  (Var_Hooks_ForceVdpRedraw), A
.done
    CALL Hooks_TickStart
    POP  BC
    POP  HL
    POP  DE
    RET
; ---------------------------------------------------------------------------
; Game_TryMovePlayerHorizontally
;
; INPUT:
;   B = TEAM  (TEAM_BLACK / TEAM_WHITE)
;   C = ID    (0..3)
;   A = direzione richiesta:
;       PLAYER_ASKED_DIRECTION_EAST
;       PLAYER_ASKED_DIRECTION_WEST
;
; OUTPUT:
;   A = SUCCESS (0) oppure FAILURE (1)
;
; NOTE:
;   - controlla SOLO la colonna adiacente nella direzione richiesta;
;   - se lì c'è un compagno senza palla, prova prima a muovere lui
;     ricorsivamente (stessa direzione);
;   - se la catena non trova spazio o qualcuno ha la palla e blocca,
;     ritorna FAILURE;
;   - se la mossa è possibile:
;       * sposta eventuale palla se:
;           - BALL_STATUS_CONTENDED, oppure
;           - posseduta dal giocatore che stiamo muovendo;
;       * sposta il giocatore di 1 colonna in quella direzione;
;   - limiti orizzontali:
;       * portiere (ID=0): X in [1..3]
;       * altri:            X in [0..4]
; ---------------------------------------------------------------------------
Game_TryMovePlayerHorizontally:

    ; Salva la direzione richiesta (uguale in tutta la catena)
    ld   (Var_Game_MoveTmpDir),a
    


    push hl
    push bc

    LD  A, (Var_Hooks_ForceVdpRedraw)
    CP  YES
    jp   z,.fail_exit

    ld   a, b
    ld   (Var_Game_TmpMoveTeam), a
    ld   a, c
    ld   (Var_Game_TmpMoveId),a

    CALL MoveGoalKeeper
    ; --- 1) Ottieni posizione corrente del giocatore (Y,X) ---
    ; HL = curr (H=Y, L=X), B=TEAM, C=ID, A=ROLE
    POP  BC
    PUSH BC
    call Game_GetPlayerInfoById
    
    ld   a, h
    ld   (Var_Game_TmpMoveRow), a
    ld   a, l
    ld   (Var_Game_TmpMovStartCol), a
    ; Salviamo posizione corrente su stack (frame locale):
    ;   [SP]   = HL (Y,X)
    ;   [SP+2] = BC (TEAM,ID)


    ; Ora:
    ;   HL = pos (H=Y,L=X)
    ;   BC = TEAM/ID corrente
    ;   stack: BC0, HL0  (dove 0 = questo livello di ricorsione)

    ; --- 2) Controllo limite laterale per questo giocatore ---

    ; X attuale in L, ID in C
    ld   a,l              ; A = X
    ld   d,a              ; D = X (copia)

    ld   a,(Var_Game_MoveTmpDir)
    cp   PLAYER_ASKED_DIRECTION_EAST
    jr   nz,.chk_west_limit

    ; ---- direzione EST ----
    ld   a,c              ; ID
    or   a
    jr   nz,.not_gk_east  ; ID != 0 => non portiere
    ; Portiere: limite destro X=3
    ld   a,d
    cp   3
    jp   z,.fail_exit

.not_gk_east:
    ld   a,d
    cp   4                ; X == 4?
    jp   z,.fail_exit     ; bordo destro campo
    jr   .compute_adjacent

.chk_west_limit:
    ; ---- direzione OVEST ----
    ld   a,c
    or   a
    jr   nz,.not_gk_west
    ; Portiere: limite sinistro X=1
    ld   a,d
    cp   1
    jp   z,.fail_exit

.not_gk_west:
    ld   a,d
    or   a                ; X==0?
    jp   z,.fail_exit     ; bordo sinistro campo

    ; --- 3) Calcolo colonna adiacente e controllo occupante ---
.compute_adjacent:
    ld   e,d              ; E = X corrente
    ld   a,(Var_Game_MoveTmpDir)
    cp   PLAYER_ASKED_DIRECTION_EAST
    jr   nz,.adj_west
    inc  e                ; X+1
    LD   A, E
    INC     A
    LD   (Var_Game_TmpMoveCompanionX), A
    jr   .adj_done
.adj_west:
    dec  e                ; X-1
    LD   A, E
    DEC     A
    LD   (Var_Game_TmpMoveCompanionX), A
.adj_done:

    ; Game_GetPlayerInfoByPos: D = Y, E = X
    ld   a,h
    ld   d,a              ; D = Y
    ; E = colonna adiacente

    call Game_GetPlayerInfoByPos
    cp   NO_VALUE
    jr   z,.adjacent_free     ; nessun giocatore -> cella libera
    ld   a, c
    ld   (Var_Game_TmpMoveCompanionId),a
    ; --- 3b) C'è un compagno nella cella adiacente: B=TEAM_occ, C=ID_occ ---
    ; Verifica che non abbia la palla e prova a spostarlo ricorsivamente.

    ; Salviamo B_occ,C_occ su stack
    push bc                   ; [SP] = BC_occ, sotto BC0,HL0

    ; Controlla possesso palla del giocatore adiacente
    call Game_GetPlayerIdWithBall  ; A=TEAM_* o BALL_STATUS_*, H=ID

    ; Ripristiniamo BC_occ
    pop  bc                   ; BC = TEAM_occ,ID_occ

    ; Se A è TEAM_BLACK o TEAM_WHITE e coincide con B_occ,
    ; e H coincide con ID_occ, allora quel giocatore ha la palla -> FAIL.
    ld   a,(Var_Game_MoveTmpDir)   ; A usato dopo, salviamo TEAM occ in D/E
    ld   d,b                   ; D = TEAM_occ
    ld   e,c                   ; E = ID_occ

    ; ATTENZIONE: GetPlayerIdWithBall ha già sovrascritto A,
    ; perciò rileggo dal luogo giusto:
    ;  - Team/Status era in A al RETURN -> lo abbiamo perso, quindi
    ;    rifacciamo la chiamata e subito dopo il confronto.

    ; Rifaccio la chiamata per avere A,H aggiornati
    call Game_GetPlayerIdWithBall   ; A=TEAM_* o BALL_STATUS_*, H=ID

    cp   BALL_STATUS_CONTENDED
    jr   nz,.adj_done_not_contended
    ld   a, (Var_Game_TmpMoveTeam)
.adj_done_not_contended:
    ; Se A non è un TEAM, non è possesso
    cp   TEAM_BLACK
    jr   z,.check_owner_team
    cp   TEAM_WHITE
    jr   nz,.no_owner_companion

.check_owner_team:
    LD   D, A
    LD   A, (Var_Game_TmpMoveTeam)
    cp   d                     ; A == D (TEAM_occ)?
    jr   nz,.no_owner_companion
    ld   a, (Var_Game_TmpMoveCompanionId)
    cp   h                     ; H == ID_occ?
    jp   z,.fail_exit          ; quel compagno ha la palla -> non si spinge

.no_owner_companion:
    ; Possiamo provare a spostare il compagno ricorsivamente
    
    ld a,(Var_Game_TmpMoveCompanionId)
    ld c, a
    ld a, (Var_Game_TmpMoveTeam)
    ld b, a                   
    ld a, (Var_Game_TmpMoveCompanionX)
    ld e, a
    CP  255
    JP  Z, .fail_exit
    CP  5
    JP  Z, .fail_exit
    ld a, (Var_Game_TmpMoveRow)
    ld d, a                   ; D=Y, E=X del compagno
    call SetPlayerInfo
    ld a, (Var_Game_TmpMoveTeam)
    ld b, a  
    ld a,(Var_Game_TmpMoveCompanionId)
    ld c, a
    call Game_ClearSinglePlayerPrevPositions
    ;jr   nz,.fail_exit         ; se il compagno non si può muovere -> FAIL

    ; Se siamo qui, la cella adiacente è diventata libera
.adjacent_free:

    ; --- 4) Cella adiacente libera: decide se spostare anche la palla ---
    ; Rilegge possesso palla DOPO eventuale movimento dei compagni
    

    ; Recupera TEAM/ID e posizione corrente di QUESTO giocatore
    ; (prima di muoverlo) dal frame su stack
    pop  bc                    ; BC0 = TEAM,ID del giocatore chiamante
    pop  hl                    ; HL0 = pos corrente (H=Y, L=X)

    ld   a, (Var_Game_TmpMoveId)
    ld   c, a

    push bc
    call Game_GetPlayerIdWithBall   ; A=status/TEAM, H=ID possessore (o 255)
    pop  bc

   
    ; A e H sono ancora quelli di GetPlayerIdWithBall

    ; Caso 1: palla contesa -> muoviamo palla
    cp   BALL_STATUS_CONTENDED
    jr   z,.move_ball

    ; Caso 2: A è TEAM del giocatore ed H è il suo ID -> possiede palla
    cp   b
    jr   nz,.no_ball_move
    ld   a,h
    cp   c
    jr   nz,.no_ball_move
.move_ball:
    ld   a, (Var_Game_TmpMovStartCol)
    call Game_GetBallPosition      
    cp   e
    jr   nz,.no_ball_move      ; palla non nella stessa colonna -> non muovo palla


    
    ; Sposta la palla di una colonna nella stessa direzione del movimento
    ; (Y invariato, X +/- 1 se dentro 0..4)
    call Game_GetBallPosition       
    LD    A, (Var_Game_TmpMoveTeam)
    CP   TEAM_BLACK
    JR   Z,.mb_ckblack
.mb_ckwhite:
    LD  A,(Var_Game_TmpMoveRow)
    DEC A
    CP  D
    JR  NZ,.no_ball_move      ; fuori campo -> non muovo palla
    JR  .mb_continue
.mb_ckblack:
    LD  A,(Var_Game_TmpMoveRow)
    CP  D
    JR  NZ,.no_ball_move      ; fuori campo -> non muovo palla
.mb_continue:
    ld   a,(Var_Game_MoveTmpDir)
    cp   PLAYER_ASKED_DIRECTION_EAST
    jr   nz,.ball_west

    ; EST
    ld   a,e
    inc  a
    cp   5
    jr   nc,.no_ball_move      ; fuori campo -> non muovo palla
    ld   e,a
    jr   .do_set_ball

.ball_west:
    ; OVEST
    ld   a,e
    or   a
    jr   z,.no_ball_move       ; già a 0 -> non muovo palla
    dec  a
    ld   e,a

.do_set_ball:


    call Game_SetBallPosition

.no_ball_move:
    ; --- 5) Sposta il giocatore orizzontalmente ---
    ; HL contiene ancora la posizione del giocatore (da poco poppata)
    ; Se non fosse più valida, la ricalcoliamo:
    ;   B=TEAM, C=ID sono già corretti.
    LD  A, (Var_Game_TmpMoveId)
    LD  C, A
    ; (riotteniamo posizione nel dubbio)
    call Game_GetPlayerInfoById     ; HL = pos aggiornata (dovrebbe essere la stessa)

    ld   d,h                   ; D = Y (invariato)
    ld   e,l                   ; E = X

    ld   a,(Var_Game_MoveTmpDir)
    cp   PLAYER_ASKED_DIRECTION_EAST
    jr   nz,.player_west
    inc  e
    jr   .do_set_player

.player_west:
    dec  e

.do_set_player:
    ; D=Y, E=newX, B=TEAM, C=ID
    call SetPlayerInfo
    LD     A, YES
    LD     (Var_Hooks_ForceVdpRedraw), A
    ld   a,SUCCESS
    ret

.fail_exit:
    ; Fallimento: svuota il frame locale (BC0,HL0) e ritorna FAILURE
    pop  bc        ; scarta BC0 (TEAM/ID di questo livello)
    pop  hl        ; scarta HL0 (pos)
    ld   a,FAILURE
    ret



; ---------------------------------------------------------------------------
; Black team horizontal move left asked
; INPUT A: Direction
; ---------------------------------------------------------------------------
Game_BlackTeamHorizMoveAsked:
    LD      (Var_Game_MoveTmpDir),A
    
    LD      A, (Var_Game_BallYPosition)
    LD      (Var_Game_TmpAskedMovingRow), A

    LD      A, (Var_Game_BallDirection)
    CP      BALL_DIRECTION_NONE
    JR      Z, .after_row_choice

    CP      BALL_DIRECTION_NORTH
    JR      Z, .north_direction
    CP      BALL_DIRECTION_NORTH_EAST
    JR      Z, .north_direction
    CP      BALL_DIRECTION_NORTH_WEST
    JR      Z, .north_direction
.south_direction:
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_SOUTH_SIDE
    JR      Z, .south_direction_south_side
.south_direction_north_side:
    LD      A, 3
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice
.south_direction_south_side:
    LD      A, 2
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice
.north_direction:
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_SOUTH_SIDE
    JR      Z, .north_direction_south_side
.north_direction_north_side:
    LD      A, 2
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice
.north_direction_south_side:
    LD      A, 0
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice

.after_row_choice:
    LD      A, NO
    LD      (Var_Game_TmpMoveReadRowPlayersFromLeft), A
    LD      A, (Var_Game_MoveTmpDir)
    CP      PLAYER_ASKED_DIRECTION_EAST
    JR      Z, .AfterSort
    LD      A, YES
    LD      (Var_Game_TmpMoveReadRowPlayersFromLeft), A
.AfterSort:
    CALL    Game_GetPlayerIdWithBall
    CP      TEAM_BLACK
    JP      Z,.WithBallPossession
    CP      BALL_STATUS_CONTENDED
    JP      Z,.ContendedBall
    
    LD      A, (Var_Game_TmpAskedMovingRow)
    CALL    GetAllPlayersOnARow
    PUSH    BC
    LD      C, B
    LD      B, TEAM_BLACK
    LD      A, (Var_Game_MoveTmpDir)
    CALL    Game_TryMovePlayerHorizontally
    POP     BC
    LD      A, C
    CP      NO_VALUE
    JR      NZ, .NoBallPossessionSecondPlayer
    JR      .Done
.NoBallPossessionSecondPlayer:
    LD      B, TEAM_BLACK
    LD      A, (Var_Game_MoveTmpDir)
    CALL    Game_TryMovePlayerHorizontally
    JR      .Done


.ContendedBall:
    CALL    Game_GetBallPosition
    CALL    Game_GetPlayerInfoByPos
    LD      A, C
    LD      H, A
.WithBallPossession:
    LD      A, H
    CP      NO_VALUE
    RET     Z
    LD      C, A
    LD      B, TEAM_BLACK
    LD      A, (Var_Game_MoveTmpDir)
    CALL    Game_TryMovePlayerHorizontally
.Done:
    RET
; ---------------------------------------------------------------------------
; White team horizontal move left asked
; INPUT A: Direction
; ---------------------------------------------------------------------------
Game_WhiteTeamHorizMoveAsked:
    LD      (Var_Game_MoveTmpDir),A

    LD      A, (Var_Game_BallYPosition)
    INC     A
    LD      (Var_Game_TmpAskedMovingRow), A

    LD      A, (Var_Game_BallDirection)
    CP      BALL_DIRECTION_NONE
    JR      Z, .after_row_choice

    CP      BALL_DIRECTION_NORTH
    JR      Z, .north_direction
    CP      BALL_DIRECTION_NORTH_EAST
    JR      Z, .north_direction
    CP      BALL_DIRECTION_NORTH_WEST
    JR      Z, .north_direction
.south_direction:
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_SOUTH_SIDE
    JR      Z, .south_direction_south_side
.south_direction_north_side:
    LD      A, 2
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice
.south_direction_south_side:
    LD      A, 3
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice
.north_direction:
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_SOUTH_SIDE
    JR      Z, .north_direction_south_side
.north_direction_north_side:
    LD      A, 2
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice
.north_direction_south_side:
    LD      A, 1
    LD      (Var_Game_TmpAskedMovingRow), A
    JR      .after_row_choice

.after_row_choice:

    LD      A, NO
    LD      (Var_Game_TmpMoveReadRowPlayersFromLeft), A
    LD      A, (Var_Game_MoveTmpDir)
    CP      PLAYER_ASKED_DIRECTION_EAST
    JR      Z, .AfterSort
    LD      A, YES
    LD      (Var_Game_TmpMoveReadRowPlayersFromLeft), A
.AfterSort:
    CALL    Game_GetPlayerIdWithBall
    CP      TEAM_WHITE
    JP      Z,.WithBallPossession
    CP      BALL_STATUS_CONTENDED
    JP      Z,.ContendedBall

    LD      A, (Var_Game_TmpAskedMovingRow)
    CALL    GetAllPlayersOnARow
    PUSH    BC
    LD      C, B
    LD      B, TEAM_WHITE
    LD      A, (Var_Game_MoveTmpDir)
    CALL    Game_TryMovePlayerHorizontally
    POP     BC
    LD      A, C
    CP      NO_VALUE
    JR      NZ, .NoBallPossessionSecondPlayer
    JR      .Done
.NoBallPossessionSecondPlayer:
    LD      B, TEAM_WHITE
    LD      A, (Var_Game_MoveTmpDir)
    CALL    Game_TryMovePlayerHorizontally
    JR      .Done

.ContendedBall:
    CALL    Game_GetBallPosition
    INC     D
    CALL    Game_GetPlayerInfoByPos
    LD      A, C
    LD      H, A
.WithBallPossession:
    LD      A, H
    CP      NO_VALUE
    RET     Z
    LD      C, A
    LD      B, TEAM_WHITE
    LD      A, (Var_Game_MoveTmpDir)
    CALL    Game_TryMovePlayerHorizontally
.Done:
    RET

; -----------------------------------------------------------
; Show game over
;
; INPUT: -
; OUTPUT: -
; MODIFIES:
;   A, HL, BC
; -----------------------------------------------------------
Game_GameOver:
    CALL    Hooks_TickStop
    LD      A, NO
    LD      (Var_Game_MatchInProgress), A
    LD      H, 0
    LD      L, 0
    LD      DE, Var_Utils_NumberToPrint
    CALL    String_NumberToASCII
    LD      HL, Var_Utils_NumberToPrint
    CALL    String_RemoveLeadingZeros
    LD      HL, Var_Utils_NumberToPrint
    LD      D, 1
    LD      E, 23
    CALL    VDP_PrintString 

    LD      HL, TXT_GAME_OVER
    LD      D, 10
    LD      E, 6
    CALL    VDP_PrintString
    EI
.Loop:
    CALL    Utils_ReadKeyboard
    CP      KBD_KEY_SPACE   ; KBD
    JR      NZ, .Loop
    CALL    Menu_Show
    JP      MainLoop

; ---------------------------------------------------------------------------
; Game_CheckStoppedBallOnGoalOrCorner
;
; Esegue controlli SOLO se la palla è ferma (BALL_DIRECTION_NONE).
; Se la palla è sulla riga di fondo/porta del campo attivo:
;   - X=0 o X=4  -> BallIsInCornerArea
;   - X=1..3     -> se portiere sulla stessa cella: BallIsInGoalkeeperHands
;                  altrimenti: BallIsInGoal
;
; Usa:
;   Var_Game_BallDirection
;   Var_Game_ActiveFieldSide
;   Game_GetBallPosition      -> DE (D=Y, E=X)
;   Game_GetPlayerInfoById    -> HL cur (H=Y, L=X)
;
; MODIFIES: AF,BC,DE,HL
; ---------------------------------------------------------------------------
Game_CheckStoppedBallOnGoalOrCorner:
    push af
    push bc
    push de
    push hl

    ; Solo se palla ferma
    ld   a,(Var_Game_BallDirection)
    cp   BALL_DIRECTION_NONE
    jr   nz,.done

;    ; Solo se palla ferma
;    ld   a,(Var_Hooks_BlinkingIsActive)
;    cp   YES
;    jr   z,.done

    ; Leggi posizione palla: D=Y, E=X
    call Game_GetBallPosition

    ; Determina se siamo su riga di fondo/porta del campo attivo
    ld   a,(Var_Game_ActiveFieldSide)
    cp   FIELD_SOUTH_SIDE
    jr   nz,.field_north

; ===== CAMPO SOUTH: fondo/porta è riga 4 =====
.field_south:
    ld   a,d
    cp   4
    jr   nz,.done

    ; Se X=0 o 4 -> corner
    ld   a,e
    or   a
    jr   z,.corner
    cp   4
    jr   z,.corner

    ; X=1..3 -> verifica portiere BIANCO (TEAM_WHITE, ID=0)
    ld   b,TEAM_WHITE
    ld   c,0
    push de                  ; salva palla
    call Game_GetPlayerInfoById   ; HL = cur (H=Y, L=X)
    pop  de

    ld   a,h
    cp   d
    jr   nz,.goal
    ld   a,l
    cp   e
    jr   nz,.goal

    call BallIsInGoalkeeperHands
    jr   .done

.goal:
    call BallIsInGoal
    jr   .done

; ===== CAMPO NORTH: fondo/porta è riga 0 =====
.field_north:
    ld   a,d
    or   a
    jr   nz,.done

    ; Se X=0 o 4 -> corner
    ld   a,e
    or   a
    jr   z,.corner
    cp   4
    jr   z,.corner

    ; X=1..3 -> verifica portiere NERO (TEAM_BLACK, ID=0)
    ld   b,TEAM_BLACK
    ld   c,0
    push de
    call Game_GetPlayerInfoById
    pop  de

    ld   a,h
    cp   d
    jr   nz,.goal2
    ld   a,l
    cp   e
    jr   nz,.goal2

    call BallIsInGoalkeeperHands
    jr   .done

.goal2:
    call BallIsInGoal
    jr   .done

.corner:
    call BallIsInCornerArea

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret

; ---------------------------------------------------------------------------
; Game_GoalCerimony
; ----------------------------------------------------------------------------
Game_GoalCerimony:
    RET
; ---------------------------------------------------------------------------
; BallIsInGoal
; ----------------------------------------------------------------------------
BallIsInGoal:
    CALL    Hooks_UpdateTimeToPlay
    CALL    Hooks_TickStop

    LD      A, TILE_BALL_BOTTOM
    LD      B, A
    LD      A, TILE_FIELD
    LD      C, A
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      NZ, .BlackGoal
    LD      A, TILE_CORNER_BALL
    LD      B, A
    LD      A, (Var_Game_ScoreWhite)
    INC     A
    LD     (Var_Game_ScoreWhite), A
.TileBlinking:
    PUSH    DE
    PUSH    BC
    PUSH    HL
    CALL    VDP_ShowScores
    POP     HL
    POP     BC
    POP     DE
    LD      A, BLINK_TYPE_GOAL
    LD     (Var_Hooks_BlinkingType), A
    CALL    BlinkTileAtPosition
    call    Game_PlayBeepGoalCorner
    RET
.BlackGoal:
    LD      A, (Var_Game_ScoreBlack)
    INC     A
    LD     (Var_Game_ScoreBlack), A
    JR      .TileBlinking
; ---------------------------------------------------------------------------
; BallIsInCornerArea
; ----------------------------------------------------------------------------
BallIsInCornerArea:
    CALL    Hooks_UpdateTimeToPlay
    CALL    Hooks_TickStop
    LD      A, TILE_CORNER_BALL
    LD      B, A
    LD      A, TILE_CORNER_BALL_EMPTY
    LD      C, A
.TileBlinking:
    LD      A, BLINK_TYPE_CORNER
    LD     (Var_Hooks_BlinkingType), A
    CALL    BlinkTileAtPosition
    call    Game_PlayBeepGoalCorner
    RET
; ---------------------------------------------------------------------------
; BallIsInGoalkeeperHands
; ----------------------------------------------------------------------------
BallIsInGoalkeeperHands:
    CALL    Hooks_UpdateTimeToPlay
    CALL    Hooks_TickStop
    LD      A, TILE_WHITE_GOALKEEPER_WITH_BALL
    LD      B, A
    LD      A, TILE_FIELD
    LD      C, A
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      NZ, .TileBlinking
    LD      A, TILE_BLACK_GOALKEEPER_WITH_BALL
    LD      B, A
.TileBlinking:
    LD      A, BLINK_TYPE_GOALKEEPER
    LD     (Var_Hooks_BlinkingType), A
    CALL    BlinkTileAtPosition
    call    Game_PlayBeepGoalCorner
    RET
; ---------------------------------------------------------------------------
; BlinkTileAtPosition
;INPUT: B: tile to show - C: tile to hide
; ----------------------------------------------------------------------------
BlinkTileAtPosition:
    LD     (Var_Hooks_BlinkingType), A
    XOR    A
    LD     (Var_Hooks_BlinkingCounter), A
    LD     (Var_Hooks_BlinkingCounter), A
    LD     A, B
    LD     (Var_Hooks_BlinkingTileToShow), A
    LD     A, C
    LD     (Var_Hooks_BlinkingTileToHide), A
    LD     A, B
    LD     (Var_Hooks_BlinkingActiveTile), A
    LD     A, YES
    LD     (Var_Hooks_BlinkingMustResetFrameCounter), A
    LD     (Var_Hooks_BlinkingIsActive), A
    RET
; ---------------------------------------------------------------------------
; Set visible field side
; ---------------------------------------------------------------------------
Game_SetVisibileFieldSide:
    CALL    Game_GetPlayerIdWithBall
    CP      TEAM_BLACK
    JR      Z, .SetSouthSide
    CP      TEAM_WHITE
    JR      Z, .SetNorthSide
    RET
.SetNorthSide:
    LD      B, A
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    RET     Z
    LD      C, H
    CALL    Game_GetPlayerInfoById
    LD      A, H
    CP      1
    RET     NZ
    LD      A, FIELD_NORTH_SIDE
    LD      (Var_Game_ActiveFieldSide), A
    JR      .Done
.SetSouthSide:
    LD      B, A
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_SOUTH_SIDE
    RET     Z
    LD      C, H
    CALL    Game_GetPlayerInfoById
    LD      A, H
    CP      3
    RET     NZ
    LD      A, FIELD_SOUTH_SIDE
    LD      (Var_Game_ActiveFieldSide), A
.Done:
    CALL    Hooks_TickStop
    CALL    VDP_DrawField
    CALL    Game_PutPlayersToNewFieldSide
    LD      A, NO_VALUE
    LD      (Var_Game_BallYOldPosition), A
    CALL    Hooks_TickStart
    RET
;----------------------------------------------------------------------------
; Game_PutPlayersToNewFieldSide
; Adjust players positions according to the new field side
; ----------------------------------------------------------------------------
Game_PutPlayersToNewFieldSide:
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      NZ, .SouthSide
.NorthSide:
    LD      B, TEAM_BLACK
    LD      C, 1
.NorthSide_BLoop:
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    PUSH    HL
    POP     DE
    LD      A, D
    CP      0
    CALL    Z, .BlackMidlefieldersFromSouthToNorth ; (0 to 3)
    CP      2
    CALL    Z, .BlackStrikersFromSouthToNorth ; (2 to 1)
    LD      A, TEAM_BLACK
    LD      B, A
    CALL    SetPlayerInfo
    POP     BC
    INC     C
    LD      A, C
    CP      4
    JR      Z, .NorthSideWhiteTeam
    JR      .NorthSide_BLoop
.NorthSideWhiteTeam:
    LD      B, TEAM_WHITE
    LD      C, 0
.NorthSide_WLoop:
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    PUSH    HL
    POP     DE
    LD      A, D
    CP      3
    CALL    Z, .WhiteDefendersFromSouthToNorth ; (3 to 2)
    CP      1
    CALL    Z, .WhiteMidlefieldersFromSouthToNorth ; (1 to 4)
    LD      A, TEAM_WHITE
    LD      B, A
    CALL    SetPlayerInfo
    POP     BC
    INC     C
    LD      A, C
    CP      4
    JP      Z, .NorthSideDonePlayers
    JR      .NorthSide_WLoop

.NorthSideDonePlayers:
    LD      B, TEAM_BLACK
    LD      C, 0
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    POP     BC
    LD      D, 0
    LD      A, L
    LD      E, A
    CALL    SetPlayerInfo    

    LD      B, TEAM_WHITE
    LD      C, 0
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    POP     BC
    LD      D, NO_VALUE
    LD      A, L
    LD      E, A
    CALL    SetPlayerInfo  
    CALL    Game_GetBallPosition
    LD      A, 3
    LD      D, A
    CALL    Game_SetBallPosition

    JR      .Done
.SouthSide:
    LD      B, TEAM_BLACK
    LD      C, 1
.SouthSide_BLoop:
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    PUSH    HL
    POP     DE
    LD      A, D
    CP      1
    CALL    Z, .BlackDefendersFromNorthToSouth ; (1 to 2)
    CP      3
    CALL    Z, .BlackMidlefieldersFromNorthToSouth ; (3 to 0)
    LD      A, TEAM_BLACK
    LD      B, A
    CALL    SetPlayerInfo
    POP     BC
    INC     C
    LD      A, C
    CP      4
    JR      Z, .SouthSideWhiteTeam
    JR      .SouthSide_BLoop
.SouthSideWhiteTeam:
    LD      B, TEAM_WHITE
    LD      C, 0
.SouthSide_WLoop:
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    PUSH    HL
    POP     DE
    LD      A, D
    CP      2
    CALL    Z, .WhiteStrikersFromNorthToSouth ; (2 to 3)
    CP      4
    CALL    Z, .WhiteMidlefieldersFromNorthToSouth ; (4 to 1)
    LD      A, TEAM_WHITE
    LD      B, A
    CALL    SetPlayerInfo
    POP     BC
    INC     C
    LD      A, C
    CP      4
    JR      Z, .SouthSideDonePlayers
    JR      .SouthSide_WLoop
.SouthSideDonePlayers:
    LD      B, TEAM_BLACK
    LD      C, 0
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    POP     BC
    LD      D, NO_VALUE
    LD      A, L
    LD      E, A
    CALL    SetPlayerInfo    

    LD      B, TEAM_WHITE
    LD      C, 0
    PUSH    BC
    CALL    Game_GetPlayerInfoById
    POP     BC
    LD      D, 4
    LD      A, L
    LD      E, A
    CALL    SetPlayerInfo  
    CALL    Game_GetBallPosition
    XOR     A
    LD      D, A
    CALL    Game_SetBallPosition
    

.Done:
    CALL    ClearAllPrevPositions
    LD      A, YES
    LD      (Var_Hooks_ForceVdpRedraw), A
    RET

.BlackStrikersFromSouthToNorth:
    LD      D, 1
    RET
.BlackMidlefieldersFromSouthToNorth:
    LD      D, 3
    RET
.WhiteMidlefieldersFromSouthToNorth:
    LD      D, 4
    RET
.WhiteDefendersFromSouthToNorth:
    LD      D, 2
    RET
.BlackDefendersFromNorthToSouth:
    LD      D, 2
    RET
.BlackMidlefieldersFromNorthToSouth:
    LD      D, 0
    RET
.WhiteStrikersFromNorthToSouth:
    LD      D, 3
    RET
.WhiteMidlefieldersFromNorthToSouth:
    LD      D, 1
    RET
    
;---------------------------------------------------------------------------
; Get all players on a row
; INPUT:
;   A = Row
; OUTPUT:
;   B: First player found on that row (ID)
;   C: Second player found on that row (ID) or NO_VALUE
;----------------------------------------------------------------------------
GetAllPlayersOnARow:
    LD   H, NO_VALUE
    LD   L, NO_VALUE

    LD   D, A
    LD   A, (Var_Game_TmpMoveReadRowPlayersFromLeft)
    CP   YES
    JR   NZ, .SearchFromRight
    LD   E, 0
.LoopLeft:
    PUSH  DE
    PUSH  HL
    CALL Game_GetPlayerInfoByPos
    POP   HL
    CP  NO_VALUE
    JR  Z, .NextLeft
    LD  A, H
    CP  NO_VALUE
    JR  NZ, .LoopLeftL
    LD  H, C
    JR  .NextLeft
.LoopLeftL:
    LD  L, C
.NextLeft:
    POP DE
    INC E
    LD  A, L
    CP  NO_VALUE
    JR  NZ, .Done
    LD   A, E
    CP  5
    JR Z,.Done
    JR  .LoopLeft
.SearchFromRight:
    LD   E, 4
.LoopRight:
    PUSH  DE
    PUSH  HL
    CALL Game_GetPlayerInfoByPos
    POP   HL
    CP  NO_VALUE
    JR  Z, .NextRight
    LD  A, H
    CP  NO_VALUE
    JR  NZ, .LoopRightL
    LD  H, C
    JR .NextRight
.LoopRightL:
    LD  L, C
.NextRight:
    POP DE
    DEC E
    LD  A, L
    CP  NO_VALUE
    JR NZ, .Done
    LD   A, E
    CP  255
    JR Z, .Done
    JR  .LoopRight

.Done:
    ld B,H
    ld C,L
    RET
Game_Start:
    CALL    Hooks_InitAICounters
    LD      A, NO
    LD      (Var_Hooks_BlinkingIsActive), A
    LD      A, 1
    LD      (Var_Game_SelectedLevel), A
    XOR     A
    LD      (Var_Utils_NumberToPrint+5),A
    LD      (Var_Hooks_TickCounter),A
    LD      A, TICK_SPEED
    LD      (Var_Hooks_TickSpeed), A
    LD      A, FIELD_NORTH_SIDE
    LD      (Var_Game_ActiveFieldSide), A
    CALL    VDP_DrawField
    CALL    Game_SetWhiteKickoffSchema
    CALL    VDP_PlayerMatrixRedraw
    call    Hooks_TickStop
    CALL    Game_Resume
    LD      A, YES
    LD      (Var_Hooks_GameResumingWaiting), A
    

    ;ld   hl,SND_DATA
    ;ld   de,SND_LEN        ; 1543 per il tuo file
    ;call Sounds_PlayHLDE      ; parte la riproduzione in background


    RET

; ---------------------------------------------------------------------------
; ClearGameFieldForGoalCerimony
; ----------------------------------------------------------------------------
Game_ClearGameFieldForGoalCerimony:
    PUSH    AF
    PUSH    BC
    PUSH    DE
    PUSH    HL
    LD      A,(Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      NZ, .SouthSideClear
.NorthSideClear:
    LD      D, 1
.Loop_North_Rows:
    PUSH    DE
    LD      E, 0
.Loop_North_Cols:
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    INC     E
    LD      A, E
    CP      5
    JR      Z,.Done_North_Rows
    JR      .Loop_North_Cols
.Done_North_Rows:
    POP     DE
    INC     D
    LD      A, D
    CP      5
    JR      Z,.Done
    JR      .Loop_North_Rows

.SouthSideClear:
    LD      D, 0
.Loop_South_Rows:
    PUSH    DE
    LD      E, 0
.Loop_South_Cols:
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    INC     E
    LD      A, E
    CP      5
    JR      Z,.Done_South_Rows
    JR      .Loop_South_Cols
.Done_South_Rows:
    POP     DE
    INC     D
    LD      A, D
    CP      4
    JR      Z,.Done
    JR      .Loop_South_Rows

.Done:
    POP     HL
    POP     DE
    POP     BC
    POP     AF
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos1
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos1:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 0
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 3
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 4
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET

; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos2
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos2:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 0
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 2
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 4
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
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

    LD      D, 17
    LD      E, 10
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 11
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar

    LD      D, 17
    LD      E, 14
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 15
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar

    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos3
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos3:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 1
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 3
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
    LD      E, 13
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 14
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 15
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 16
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar



    LD      D, 17
    LD      E, 6
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 7
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 10
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 11
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar

    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos4
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos4:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 3
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 1
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
    LD      E, 5
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 6
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 7
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 8
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar


    LD      D, 17
    LD      E, 10
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 11
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 14
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 15
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar


    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos5
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos5:
    CALL    Utils_PlayBeepHighLong
    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 0
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 4
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 2
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
    LD      E, 9
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 10
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 11
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 12
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar

    LD      D, 17
    LD      E, 14
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 15
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 18
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 19
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar


    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos6
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos6:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 0
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 2
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 4
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
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

    LD      D, 17
    LD      E, 14
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 15
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 10
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 11
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos7
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos7:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 1
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 3
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
    LD      E, 13
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 14
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 15
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 16
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar



    LD      D, 17
    LD      E, 10
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 11
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 6
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 7
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar


    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos8
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos8:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 3
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 1
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
    LD      E, 5
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 6
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 7
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 8
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar

    LD      D, 17
    LD      E, 10
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 11
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 14
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 15
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar


    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyWhitePlayersPos9
; ----------------------------------------------------------------------------
PutCerimonyWhitePlayersPos9:
    CALL    Utils_PlayBeepTick
    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 0
    PUSH    DE
    LD      A,TILE_WHITE_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 4
    LD      E, 4
    PUSH    DE
    LD      A, TILE_WHITE_PLAYER_NEAR_HALF_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 4
    LD      E, 2
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  

    LD      D, 17
    LD      E, 9
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 10
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 11
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar
    LD      E, 12
    LD      A, TILE_FIELD_LINE_HORIZONTAL
    CALL    VDP_PrintRamChar

    LD      D, 17
    LD      E, 14
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 15
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 18
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_1
    call    VDP_PrintRamChar
    LD      D, 17
    LD      E, 19
    ld      a,TILE_FIELD_LINE_WHITE_PLAYER_2
    call    VDP_PrintRamChar

    POP     DE
    RET










; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos1
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos1:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 0
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 1
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 4
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    RET

; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos2
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos2:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 0
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 2
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 4
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos3
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos3:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 1
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 3
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos4
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos4:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 3
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 1
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos5
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos5:
    CALL    Utils_PlayBeepHighLong
    LD      D, 0
    LD      E, 2
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 0
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 4
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos6
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos6:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 0
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 2
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 4
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos7
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos7:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 1
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 3
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos8
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos8:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 3
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 1
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 3
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 1
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; PutCerimonyBlackPlayersPos9
; ----------------------------------------------------------------------------
PutCerimonyBlackPlayersPos9:
    CALL    Utils_PlayBeepTick
    LD      D, 0
    LD      E, 2
    PUSH    DE
    LD      A,TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 0
    LD      E, 0
    PUSH    DE
    LD      A,TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE

    LD      D, 2
    LD      E, 4
    PUSH    DE
    LD      A, TILE_BLACK_PLAYER

    CALL    VDP_DrawSprite  
    POP     DE
    LD      D, 2
    LD      E, 2
    PUSH    DE
    LD      A, TILE_FIELD

    CALL    VDP_DrawSprite  
    POP     DE
    RET
; ---------------------------------------------------------------------------
; Game_PlayBeep
; ----------------------------------------------------------------------------
Game_PlayBeep:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    RET     NZ
    CALL    Utils_PlayBeep
    RET 
; ---------------------------------------------------------------------------
; Game_PlayBeepGoalCorner
; ----------------------------------------------------------------------------
Game_PlayBeepGoalCorner:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    RET     NZ
    CALL    Utils_PlayBeepGoalCorner
    RET

; ---------------------------------------------------------------------------
; CerimonyRedrawHalfFieldLine
; ----------------------------------------------------------------------------
CerimonyRedrawHalfFieldLine:
    PUSH DE
    LD   A, (Var_Game_ActiveFieldSide)
    CP   FIELD_NORTH_SIDE
    JR   Z, .North   
    LD   D, 7
    JR   .Continue
.North:
    LD   D, 17
.Continue:
    LD   E, 1
.Loop:
    PUSH DE
    LD   A, TILE_FIELD_LINE_HORIZONTAL
    CALL VDP_PrintRamChar
    POP  DE
    INC  E
    LD   A, E
    CP   21
    JR   Z, .Done
    JR   .Loop
.Done:
    POP DE
    RET
; ---------------------------------------------------------------------------
; Game_GoalCelebration_DrawFrame
;
; INPUT:
;   A = tick (8..1)   ; 8 = first move, 1 = last move

;
; MODIFIES: AF,BC,DE,HL
; ---------------------------------------------------------------------------
Game_GoalCelebration_DrawFrame:
    PUSH    HL
    PUSH    DE
    PUSH    BC
    PUSH    AF
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      NZ, .BlackTeam
; ===== WHITE TEAM CELEBRATION =====  
.WhiteTeam:
    POP     AF
    CP      8
    JR      NZ, .White7
    CALL    PutCerimonyWhitePlayersPos1
    JP      .Done
.White7:
    CP      7
    JR      NZ, .White6
    CALL    PutCerimonyWhitePlayersPos2
    JP      .Done
.White6:
    CP      6
    JR      NZ, .White5
    CALL    PutCerimonyWhitePlayersPos3
    JP      .Done
.White5:
    CP      5
    JR      NZ, .White4
    CALL    PutCerimonyWhitePlayersPos4
    JR      .Done
.White4:
    CP      4
    JR      NZ, .White3
    CALL    PutCerimonyWhitePlayersPos5
    JR      .Done
.White3:
    CP      3
    JR      NZ, .White2
    CALL    PutCerimonyWhitePlayersPos6
    JR      .Done
.White2:
    CP      2
    JR      NZ, .White1
    CALL    PutCerimonyWhitePlayersPos7
    JR      .Done
.White1:
    CP      1
    JR      NZ, .White0
    CALL    PutCerimonyWhitePlayersPos8
    JR      .Done
.White0:
    CALL    PutCerimonyWhitePlayersPos9
    JR      .Done
; ===== BLACK TEAM CELEBRATION =====  
.BlackTeam:
    POP     AF
    CP      8
    JR      NZ, .Black7
    CALL    PutCerimonyBlackPlayersPos1
    JR      .Done
.Black7:
    CP      7
    JR      NZ, .Black6
    CALL    PutCerimonyBlackPlayersPos2
    JR      .Done
.Black6:
    CP      6
    JR      NZ, .Black5
    CALL    PutCerimonyBlackPlayersPos3
    JR      .Done
.Black5:
    CP      5
    JR      NZ, .Black4
    CALL    PutCerimonyBlackPlayersPos4
    JR      .Done
.Black4:
    CP      4
    JR      NZ, .Black3
    CALL    PutCerimonyBlackPlayersPos5
    JR      .Done
.Black3:
    CP      3
    JR      NZ, .Black2
    CALL    PutCerimonyBlackPlayersPos6
    JR      .Done
.Black2:
    CP      2
    JR      NZ, .Black1
    CALL    PutCerimonyBlackPlayersPos7
    JR      .Done
.Black1:
    CP      1
    JR      NZ, .Black0
    CALL    PutCerimonyBlackPlayersPos8
    JR      .Done
.Black0:
    CALL    PutCerimonyBlackPlayersPos9

.Done:
    POP     BC
    POP     DE
    POP     HL
    RET
; ----- CONSTANTS ------
