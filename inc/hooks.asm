; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** HOOKS.ASM ***



; Hooks_TickStart
;----------------------------------------------------------------------
Hooks_TickStart:
    PUSH    AF
    LD      A, NO
    LD      (Var_Hooks_TickSuspended), A
    POP     AF
    RET
;----------------------------------------------------------------------
; Hooks_TickStop
;----------------------------------------------------------------------
Hooks_TickStop:
    PUSH    AF
    LD      A, YES
    LD      (Var_Hooks_TickSuspended), A
    POP     AF
    RET

;----------------------------------------------------------------------
; VBlank ISR
; INPUT: -
; OUTPUT: -
; MODIFIES: A, DE, HL, BC
;----------------------------------------------------------------------
VBlankISR:
    PUSH    AF
    PUSH    BC
    PUSH    DE
    PUSH    HL



    LD      A, (Var_Hooks_FrameCounter)
    INC     A
    CP      51
    JR      NZ, .Continue

    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    JR      Z, .Time
    LD      A, (Var_Game_TimeToPlay)
    DEC     A
    LD      (Var_Game_TimeToPlay), A
.Time:
    LD      A, (Var_Hooks_SecondsCounter)
    INC     A
    CP      61
    JR      NZ, .NewMinute
    LD      A, (Var_Hooks_MinutesCounter)
    INC     A
    LD      (Var_Hooks_MinutesCounter), A
    XOR     A           ; Reset the seconds counter
.NewMinute:
    LD      (Var_Hooks_SecondsCounter), A
    XOR     A       ; Reset the frame counter
.Continue:
    LD      (Var_Hooks_FrameCounter), A  
.Done:
    LD      A, (Var_Hooks_GoalCerimonyCounter)
    CP      0
    JR      Z, .AfterGoalCerimony
    CP      NO_VALUE
    JP      Z, .CheckBlinkingRestartAfterGoal
    JP      .ShowGoalCerimony
.AfterGoalCerimony:
    CALL    Utils_PlayBeepHighLong
    LD      A, (Var_Hooks_GameResumingWaiting)
    CP      YES
    JP      Z, .CheckGameResumeWaiting
    LD      A, (Var_Hooks_TickSuspended)
    CP      YES
    JR      Z, .AfterTick
    CALL    AiTick
.AfterTick:
    LD     A, (Var_Hooks_ForceVdpRedraw)
    CP     YES
    JR     NZ, .AfterRedraw
    LD     A, NO
    LD     (Var_Hooks_ForceVdpRedraw), A
    CALL   Game_SetVisibileFieldSide
    CALL   VDP_PlayerMatrixRedraw
.AfterRedraw:
    LD      A, (Var_Game_FirstKickType)
    CP      NO_VALUE
    JR      Z, .AfterFirtsKickCheck
    JP      .CheckFirstKick
.AfterFirtsKickCheck:
    LD      A, (Var_Hooks_BlinkingIsActive)
    CP      YES
    JP      Z, .CheckBlinkingState
.AfterBlinkingCheck:
    CALL   Game_CheckStoppedBallOnGoalOrCorner


    CALL    UpdateMatchTime
.ReadKeyBoard:
    CALL    Utils_ReadKeyboard
    CP      KBD_KEY_SPACE
    JP      Z, .SpaceButtonPressed
    CP      KBD_KEY_LEFT
    JP      Z, .LeftArrowPressed
    CP      KBD_KEY_RIGHT
    JP      Z, .RightArrowPressed
    CP      KBD_KEY_DOWN
    JP      Z, .DownArrowPressed
    CP      KBD_KEY_UP
    JP      Z, .UpArrowPressed
    CP      KBD_KEY_W
    JP      Z, .WKeyPressed
    CP      KBD_KEY_A
    JP      Z, .AKeyPressed
    CP      KBD_KEY_S
    JP      Z, .SKeyPressed
    CP      KBD_KEY_K
    JP      Z, .KKeyPressed
    CP      KBD_KEY_L
    JP      Z, .LKeyPressed
    CP      KBD_KEY_O
    JP      Z, .OKeyPressed
.Exit
    POP    HL
    POP    DE
    POP    BC
    POP    AF
    RETI ;JP     Var_Hooks_Old_HTIMI    ; return to the original code (inside the BIOS)
.WKeyPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    JP      Z, .StartGame
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_1_PLAYER
    JP      Z, .Exit
    JP      .BlackTeamTryShotOrRestart
.UpArrowPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    JP      Z, .WhiteTeamTryShotOrRestart
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_1_PLAYER
    JP      NZ, .Exit
    JP     .LevelUp
    JP      .Exit
.SpaceButtonPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    JP      Z, .StartGame
    JP      .Exit
.OKeyPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    JP      Z, .Exit
.AKeyPressed:
    JP      .WhiteTeamTryShotOrRestart
    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    JP      Z, .Exit
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_1_PLAYER
    JP      Z, .Exit
    JP     .BlackTeamMoveLeft
.SKeyPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    JP      Z, .Exit
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_1_PLAYER
    JP      Z, .Exit
    JP     .BlackTeamMoveRight
.LeftArrowPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    JP      Z, .Exit
    JP     .ChangeGameSelectedMode
    JP      .Exit
.KKeyPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    JP      Z, .WhiteTeamMoveLeft
    JP      .Exit
.DownArrowPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    JP      Z, .Exit
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_1_PLAYER
    JP      NZ, .Exit
    JP     .LevelDown
    JP      .Exit
.RightArrowPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    JP      Z, .Exit
    JP     .ChangeGameSelectedMode
    JP     .Exit
.LKeyPressed:
    LD      A, (Var_Game_MatchInProgress)
    CP      YES
    JP      Z, .WhiteTeamMoveRight
    JP     .Exit
.BlackTeamMoveLeft:    
    LD      A, (Var_Game_FirstKickType)
    CP      NO_VALUE
    JP      NZ, .Exit
    LD      A, PLAYER_ASKED_DIRECTION_WEST
    CALL    Game_BlackTeamHorizMoveAsked
    JP      .Exit
.BlackTeamMoveRight:  
    LD      A, (Var_Game_FirstKickType)
    CP      NO_VALUE
    JP      NZ, .Exit
    LD      A, PLAYER_ASKED_DIRECTION_EAST
    CALL    Game_BlackTeamHorizMoveAsked
    JP      .Exit
.WhiteTeamMoveLeft:
    LD      A, (Var_Game_FirstKickType)
    CP      NO_VALUE
    JP      NZ, .Exit
    LD      A, PLAYER_ASKED_DIRECTION_WEST
    CALL    Game_WhiteTeamHorizMoveAsked
    JP      .Exit
.WhiteTeamMoveRight:
    LD      A, (Var_Game_FirstKickType)
    CP      NO_VALUE
    JP      NZ, .Exit    
    LD      A, PLAYER_ASKED_DIRECTION_EAST
    CALL    Game_WhiteTeamHorizMoveAsked
    JP      .Exit
.BlackTeamTryShotOrRestart:
    LD      A, (Var_Game_FirstKickType)
    CP      NO_VALUE
    JR      Z, .BlackTeamTryShot
    CP      FIRST_KICK_TYPE_BLACK_HALF_FIELD
    JR      Z,.BlackTeamRestartFromHalfField
    CP      FIRST_KICK_TYPE_BLACK_BOTTOM_FIELD
    JP      NZ, .Exit
    LD      A, (Var_Game_SecondsToPlay)
    LD      (Var_Game_TimeToPlay),A
    JP      Resume_BlackGoalKick.exec 
    JP      .Exit
.BlackTeamRestartFromHalfField:
    LD      A, (Var_Game_SecondsToPlay)
    LD      (Var_Game_TimeToPlay),A
    JP      Resume_BlackKickoff.exec 
    JP      .Exit
.BlackTeamTryShot:
    CALL    Game_GetPlayerIdWithBall
    CP      TEAM_BLACK
    JP      NZ, .Exit
    LD      A, TEAM_BLACK
    LD      B, A
    LD      C, H
    CALL    Game_TryShot
    JP      .Exit
.WhiteTeamTryShotOrRestart:
    LD      A, (Var_Game_FirstKickType)
    CP      NO_VALUE
    JR      Z, .WhiteTeamTryShot
    CP      FIRST_KICK_TYPE_WHITE_HALF_FIELD
    JR      Z,.WhiteTeamRestartFromHalfField
    CP      FIRST_KICK_TYPE_WHITE_BOTTOM_FIELD
    JP      NZ, .Exit
    LD      A, (Var_Game_SecondsToPlay)
    LD      (Var_Game_TimeToPlay),A
    JP      Resume_WhiteGoalKick.exec 
    JP      .Exit
.WhiteTeamRestartFromHalfField:
    LD      A, (Var_Game_SecondsToPlay)
    LD      (Var_Game_TimeToPlay),A
    JP      Resume_WhiteKickoff.exec 
    JP      .Exit
.WhiteTeamTryShot:
    CALL    Game_GetPlayerIdWithBall
    CP      TEAM_WHITE
    JP      NZ, .Exit
    LD      A, TEAM_WHITE
    LD      B, A
    LD      C, H
    CALL    Game_TryShot
    JP      .Exit
.CheckFirstKick:
    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    JR      Z, .CheckFirstKickCpuTeam
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_2_PLAYERS
    JP      Z, .ReadKeyBoard
    LD      A,(Var_Game_FirstKickType)
    CP      FIRST_KICK_TYPE_WHITE_HALF_FIELD
    JP      Z, .ReadKeyBoard
.CheckFirstKickCpuTeam:
    LD      A, (Var_Game_FirstKickFrameCounter)
    INC     A
    LD      (Var_Game_FirstKickFrameCounter), A
    CP      BLINK_FRAMES_DURATION
    JP      NZ, .Exit
    LD      A, (Var_Game_SecondsToPlay)
    LD      (Var_Game_TimeToPlay),A
    LD      A, (Var_Game_FirstKickType)
    CP      FIRST_KICK_TYPE_WHITE_HALF_FIELD
    JP      Z, Resume_WhiteKickoff.exec
    CP      FIRST_KICK_TYPE_BLACK_HALF_FIELD
    JP      Z, Resume_BlackKickoff.exec
    CP      FIRST_KICK_TYPE_WHITE_BOTTOM_FIELD
    JP      Z, Resume_WhiteGoalKick.exec
    CP      FIRST_KICK_TYPE_BLACK_BOTTOM_FIELD
    JP      Z, Resume_BlackGoalKick.exec
    JP       .Exit
.ChangeGameSelectedMode:
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_1_PLAYER
    JR      Z, .ChangeGameSelectedModeToGAME_MODE_2_PLAYERS
.ChangeGameSelectedModeToCPU:
    LD      A, GAME_MODE_1_PLAYER
    LD      (Var_Game_SelectedPlayers), A
    CALL    Menu_ShowOptions
    CALL    Utils_PlayBeep
    JP      .Exit
.ChangeGameSelectedModeToGAME_MODE_2_PLAYERS:
    LD      A, GAME_MODE_2_PLAYERS
    LD      (Var_Game_SelectedPlayers), A
    CALL    Menu_ShowOptions
    CALL    Utils_PlayBeep
    JP      .Exit
.LevelDown:
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_2_PLAYERS
    JP      Z, Menu_ShowOptions.Level1
    LD      A, (Var_Game_SelectedLevel)
    CP      1
    JP      Z, .Exit
    DEC     A
    LD      (Var_Game_SelectedLevel), A
    CALL    Menu_ShowOptions.Level1
    CALL    Utils_PlayBeep
    JP      .Exit
.LevelUp:
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_2_PLAYERS
    JP      Z, Menu_ShowOptions.Level1
    LD      A, (Var_Game_SelectedLevel)
    CP      5
    JP      Z, .Exit
    INC     A
    LD      (Var_Game_SelectedLevel), A
    CALL    Menu_ShowOptions.Level1
    CALL    Utils_PlayBeep
    JP      .Exit
.CheckGameResumeWaiting:
    LD      A, (Var_Hooks_FrameCounter)
    CP      BLINK_FRAMES_DURATION
    JP      NZ, .Exit
    LD      A, NO
    LD      (Var_Hooks_GameResumingWaiting), A
    CALL    Game_Resume
    CALL    VDP_PlayerMatrixRedraw
    JP      .Exit
.ShowGoalCerimony:
    LD      A, (Var_Hooks_CerimonySpeedCounter)
    INC     A
    LD      (Var_Hooks_CerimonySpeedCounter), A
    CP      CERIMONY_MOVEMENT_SPEED
    JP      NZ, .Exit
    XOR     A
    LD      (Var_Hooks_CerimonySpeedCounter), A
    LD      A,(Var_Hooks_GoalCerimonyCounter)
    DEC     A
    LD      (Var_Hooks_GoalCerimonyCounter), A
    LD      A, TEAM_WHITE
    LD      B, A
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      Z, .ShowGoalCerimonyTeamSelected
    LD      A, TEAM_BLACK
    LD      B, A
.ShowGoalCerimonyTeamSelected:
    LD      A,(Var_Hooks_GoalCerimonyCounter)
    CALL    Game_GoalCelebration_DrawFrame

    LD      A,(Var_Hooks_GoalCerimonyCounter)
    CP      0
    JP      NZ,.ReadKeyBoard
    LD      A, NO_VALUE
    LD      (Var_Hooks_GoalCerimonyCounter), A
    JP      .ReadKeyBoard
.StartGame:
    LD      A,NO_VALUE
    LD      (Var_Game_FirstKickType), A
    LD      A, NO
    LD      (Var_Hooks_BlinkingIsActive), A
    LD      (Var_Hooks_GameResumingWaiting), A
    CALL    Game_StopShot
    LD      A, NO
    LD      (Var_Hooks_ForceVdpRedraw), A
    LD      A, (Var_Game_SelectedLevel)
    LD      (Var_Game_PlayersSpeed), A 
    LD      A, MATCH_TIME
    LD      (Var_Game_TimeToPlay), A
    CALL    Hooks_UpdateTimeToPlay
    XOR     A
    LD      (Var_Hooks_GoalCerimonyCounter), A
    LD      (Var_Game_BallUpdateTimer), A
    LD      (Var_Game_ScoreWhite), A
    LD      (Var_Game_ScoreBlack), A
    CALL    VDP_ClearMenuSideArea
    LD      A, YES
    LD      (Var_Game_MatchInProgress), A
    CALL    VDP_ShowScores
    CALL    Game_Start
    CALL    UpdateMatchTime
    JP      .Exit
.CheckBlinkingState:
    CALL    Hooks_TickStop
    LD      A, (Var_Hooks_BlinkingMustResetFrameCounter)
    CP      NO
    JP      Z,.CheckBlinkingStateAfterReset
    XOR     A
    LD      (Var_Hooks_FrameCounter), A  
.CheckBlinkingStateAfterReset:
    LD      A, (Var_Hooks_FrameCounter)
    CP      BLINK_FRAMES_DURATION
    JP      Z,.CheckBlinkingStateContinue
    LD      A, NO
    LD      (Var_Hooks_BlinkingMustResetFrameCounter), A
    JP      .Exit
.CheckBlinkingStateContinue:
    LD      A, YES
    LD      (Var_Hooks_BlinkingMustResetFrameCounter), A
    LD      A, (Var_Hooks_BlinkingCounter)
    INC     A
    LD      (Var_Hooks_BlinkingCounter), A
    CP      7
    JR      Z,.CheckBlinkingStateStop
    LD      A, (Var_Hooks_BlinkingTileToShow)
    LD      B, A
    LD      A, (Var_Hooks_BlinkingActiveTile)
    CP      B
    JR      NZ, .CheckBlinkingStateShowTile
    LD      A, (Var_Hooks_BlinkingTileToHide)
    LD      B, A
.CheckBlinkingStateShowTile:
    LD      A, B
    LD      (Var_Hooks_BlinkingActiveTile), A
    CALL    Game_GetBallPosition
    LD      A, (Var_Hooks_BlinkingActiveTile)
    CALL    VDP_DrawSprite
    JP      .ReadKeyBoard
.CheckBlinkingStateStop:
    LD      A, NO
    LD      (Var_Hooks_BlinkingIsActive), A
    LD      A, (Var_Hooks_BlinkingType)
    CP      BLINK_TYPE_GOAL
    JR      Z, .GoalCerimony
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      NZ,.CheckBlinkingRestartAfterNoGoalFromSouth
    CALL    VDP_DrawField
    CALL    SetBlackRestartSchema
    JR     .CheckBlinkingRestartResume
.GoalCerimony:
    XOR   A
    LD    (Var_Hooks_CerimonySpeedCounter), A
    CALL  Game_ClearGameFieldForGoalCerimony
    LD    A, 9
    LD    (Var_Hooks_GoalCerimonyCounter), A
    CALL    CerimonyRedrawHalfFieldLine
    JP    .Exit
.CheckBlinkingRestartAfterNoGoalFromSouth:    
    CALL    VDP_DrawField
    CALL    SetWhiteRestartSchema
    JR     .CheckBlinkingRestartResume
.CheckBlinkingRestartAfterGoal:
    XOR     A
    LD      (Var_Hooks_GoalCerimonyCounter), A
    LD      A, (Var_Game_ActiveFieldSide)
    CP      FIELD_NORTH_SIDE
    JR      Z, .CheckBlinkingRestartAfterGoalFromSouth
    LD      A, FIELD_NORTH_SIDE
    LD      (Var_Game_ActiveFieldSide), A
    CALL    VDP_DrawField
    CALL    Game_SetWhiteKickoffSchema
    JR      .CheckBlinkingRestartResume
.CheckBlinkingRestartAfterGoalFromSouth:
    LD      A, FIELD_SOUTH_SIDE
    LD      (Var_Game_ActiveFieldSide), A
    CALL    VDP_DrawField
    CALL    Game_SetBlackKickoffSchema
.CheckBlinkingRestartResume:    
    CALL   VDP_PlayerMatrixRedraw
    XOR    A
    LD     (Var_Hooks_FrameCounter), A
    LD     A, YES
    LD     (Var_Hooks_GameResumingWaiting), A
    JP     .Exit

UpdateMatchTime:
    LD      A, (Var_Game_MatchInProgress)
    CP      NO
    RET     Z
    PUSH    HL
    PUSH    DE
    PUSH    BC
    LD      A, (Var_Game_TimeToPlay)

    CP      255
    JP      Z,  Game_GameOver
    LD      DE, Var_Utils_NumberToPrint
    LD      H, 0
    LD      L, A
    CALL    String_NumberToASCII
    LD      HL, Var_Utils_NumberToPrint
    CALL    String_RemoveLeadingZeros
    LD      HL, Var_Utils_NumberToPrint
    LD      D, 1
    LD      E, 26
    CALL    VDP_PrintString 
    POP     BC
    POP     DE
    POP     HL 
    RET


;----------------------------------------------------------------------------
; AiTick
;----------------------------------------------------------------------------
AiTick:
    push af
    push bc
    push de
    push hl
 
    ld  a,(Var_Hooks_ForceVdpRedraw)
    cp  YES
    jr  z, .done
    
    call Game_UpdateBallMovement

    ld  a,(Var_Hooks_TickSpeed)
    ld  b, a
    ld  a, (Var_Hooks_TickCounter)
    inc a
    ld  (Var_Hooks_TickCounter), a
    cp  b
    jr  nz, .done

    xor a
    ld  (Var_Hooks_TickCounter), a
    
    ld   a,(Var_Game_PlayersSpeed)
    cp   1
    jr   nc,.speed_ok
    ld   a,1
.speed_ok:
    cp   5
    jr   c,.speed_ok2
    ld   a,5
.speed_ok2:
    ld   b,a
    ld   a,6
    sub  b
    ld   b,a                 ; B = delay (1..5)

    ; --- controlla se siamo in demo (match non in corso) ---
    ld   a,(Var_Game_MatchInProgress)
    cp   NO
    jr   z,.demo_mode

    ; --- partita normale ---
    ld   a,(Var_Game_SelectedPlayers)
    cp   GAME_MODE_1_PLAYER
    jr   z,.one_player_mode
    cp   GAME_MODE_2_PLAYERS
    jr   z,.two_players_mode
    jr   .done               ; modalità sconosciuta? non fare nulla

; ---- DEMO: entrambe le squadre CPU --------------------------------
.demo_mode:
    ; TEAM_BLACK
    ld   a,(Var_Hooks_AiCounterBlack)
    inc  a
    ld   (Var_Hooks_AiCounterBlack),a   ; <-- SALVA SEMPRE DOPO INC
    cp   b
    jr   c,.skip_black_demo
    xor  a
    ld   (Var_Hooks_AiCounterBlack),a   ; reset contatore
    ld   b,TEAM_BLACK
    call AiUpdateTeam
.skip_black_demo:

    ; TEAM_WHITE
    ld   a,(Var_Hooks_AiCounterWhite)
    inc  a
    ld   (Var_Hooks_AiCounterWhite),a   ; <-- SALVA SEMPRE DOPO INC
    cp   b
    jr   c,.skip_white_demo
    xor  a
    ld   (Var_Hooks_AiCounterWhite),a   ; reset contatore
    ld   b,TEAM_WHITE
    call AiUpdateTeam
.skip_white_demo:
    jr   .done

; ---- 1 PLAYER: CPU controlla solo i NERI --------------------------
.one_player_mode:
    ; TEAM_BLACK CPU
    ld   a,(Var_Hooks_AiCounterBlack)
    inc  a
    ld   (Var_Hooks_AiCounterBlack),a   ; <-- SALVA SEMPRE DOPO INC
    cp   b
    jr   c,.skip_black_1p
    xor  a
    ld   (Var_Hooks_AiCounterBlack),a   ; reset contatore
    ld   b,TEAM_BLACK
    call AiUpdateTeam
.skip_black_1p:
    jr   .done

; ---- 2 PLAYERS: nessuna CPU --------------------------------------
.two_players_mode:
    ; niente
    jr   .done

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret


; ---------------------------------------------------------------------------
; AiUpdateTeam
;
; INPUT:
;   B = TEAM (TEAM_BLACK / TEAM_WHITE)
;
; Usa:
;   Game_GetPlayerIdWithBall
;   AiUpdateGoalkeeper
;   AiMoveChaserTowardBall
;   AiBallCarrierDecision
;   AiVerticalAdjustments
;
; Convenzioni Game_GetPlayerIdWithBall:
;   A = stato/team:
;       BALL_STATUS_MOVING
;       BALL_STATUS_FREE
;       BALL_STATUS_CONTENDED
;       TEAM_BLACK / TEAM_WHITE (se una squadra ha il possesso)
;   H = ID giocatore in possesso (o 255 se nessuno)
;   L = ID contendente (o 255 se nessuno)
; ---------------------------------------------------------------------------
AiUpdateTeam:
    push af
    push bc
    push de
    push hl

    ; Salva TEAM di input
    ld   c,b                 ; C = TEAM_ORIG
    PUSH  BC
    ; Chi ha la palla?
    call Game_GetPlayerIdWithBall
    ; A = stato/team, H = ownerID (o 255), L = contenderID (o 255)
    POP   BC


    ld   e,h                 ; E = ownerID (se esiste)
    ld   d,a                 ; D = stato/team
    ; --- caso: palla in movimento ---------------------------------

    cp   BALL_STATUS_MOVING
    jr   nz, .chk_contended

    ; palla che viaggia: portiere si aggiusta un po', niente altro
    ;;call AiUpdateGoalkeeper
    jr   .done

.chk_contended:

    cp   BALL_STATUS_CONTENDED
    jr   nz, .chk_free

    ; palla contesa: per ora ci comportiamo come se fosse “palla libera”

    ;;call AiUpdateGoalkeeper
    call AiMoveChaserTowardBall
    call AiVerticalAdjustments
    jr   .done

.chk_free:

    cp   BALL_STATUS_FREE
    jr   nz, .chk_team_possession

    ;; palla libera
    ;;call AiUpdateGoalkeeper
    call AiMoveChaserTowardBall
    call AiVerticalAdjustments
    jr   .done

; -------------------------------------------------------------------
; Qui A (=D) è o TEAM_BLACK o TEAM_WHITE: una squadra ha il possesso
; -------------------------------------------------------------------
.chk_team_possession:
    ; Se D == TEAM_ORIG -> la nostra squadra ha la palla
    ld   a,d                 ; team che ha la palla
    cp   b                   ; confronta con TEAM_ORIG
    jr   nz, .enemy_has_ball

    ; === noi abbiamo la palla ===
    ; E = ownerID
    ;ld   b,c                 ; B = TEAM_ORIG
    ld   c,e                 ; C = ID portatore

    ; portiere
    ;;call AiUpdateGoalkeeper
    ; decisione portatore (muoversi / tirare / ecc.)
    call AiBallCarrierDecision
    ; opzionale: piccoli aggiustamenti verticali anche dei non portatori
    call AiVerticalAdjustments
    jr   .done

.enemy_has_ball:
    ; === l'altra squadra ha la palla ===
    ;ld   b,c                 ; B = TEAM_ORIG
    ;;call AiUpdateGoalkeeper
    call AiMoveChaserTowardBall
    call AiVerticalAdjustments
    jr   .done

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret


; ---------------------------------------------------------------------------
; AiUpdateGoalkeeper
;
; INPUT:
;   B = TEAM (TEAM_BLACK / TEAM_WHITE)
;
; Logica:
;   - legge posizione palla
;   - targetX:
;       if 1..3 -> ballX
;       else    -> 2
;   - trova portiere (ID=0) con Game_GetPlayerInfoById
;   - con una certa probabilità (dipendente da Var_Game_PlayersSpeed)
;     prova a muovere il portiere orizzontalmente verso targetX.
; ---------------------------------------------------------------------------
AiUpdateGoalkeeper:
    push af
    push bc
    push de
    push hl

    ; salvati il team
    ld   c,b                 ; C = TEAM

    ; posizione palla
    call Game_GetBallPosition ; HL = X,Y  (H=Y, L=X)
    PUSH DE
    POP  HL

    ; targetX = (1..3 ? ballX : 2)
    cp   1
    jr   c,.use_center
    cp   4
    jr   nc,.use_center
    ld   d,e                 ; D = targetX = ballX
    jr   .got_target

.use_center:
    ld   d,2                 ; targetX = 2

.got_target:
    ; prendi posizione portiere (ID=0)
    ld   b,c                 ; B = TEAM
    ld   c,0                 ; ID = 0
    call Game_GetPlayerInfoById
    ; HL = curr (H=Y, L=X)
    ld   a,l                 ; goalieX
    ld   e,a                 ; E = goalieX

    ; se già in colonna giusta → niente
    ld   a,e
    cp   d
    jr   z,.done

    ; probabilità di muoversi dipendente da Var_Game_PlayersSpeed
    push bc
    call Game_GetRandomByte
    pop  bc
    and  00001111b           ; 0..15
    ld   h,a
    ld   a,(Var_Game_PlayersSpeed) ; 1..5
    ; più alto => più facile che H < soglia
    add  a,3                 ; speed 1..5 -> soglia 4..8
    cp   h
    jr   c,.done             ; random >= soglia -> non si muove

    ; decide direzione verso targetX
    ld   a,e                 ; goalieX
    cp   d                   ; targetX
    jr   c,.move_east
    jr   .move_west

.move_east:
    ld   a,PLAYER_ASKED_DIRECTION_EAST
    jr   .do_move

.move_west:
    ld   a,PLAYER_ASKED_DIRECTION_WEST

.do_move:
    ; A = dir, B = TEAM, C = 0 (portiere)
    call Game_TryMovePlayerHorizontally
    ; ignoriamo SUCCESS/FAILURE
.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
;---------------------------------------------------------------------------
; Hooks_InitAICounters
;---------------------------------------------------------------------------
Hooks_InitAICounters:
    xor  a
    ld   (Var_Hooks_AiCounterBlack),a
    ld   (Var_Hooks_AiCounterWhite),a
    ret
; ---------------------------------------------------------------------------
; AiMoveChaserTowardBall
;
; INPUT:
;   B = TEAM (TEAM_BLACK / TEAM_WHITE)
;
; Logica:
;   - calcola ballY/ballX
;   - riga target per cercare un "chaser":
;       * TEAM_BLACK:   stessa riga della palla
;       * TEAM_WHITE:   riga della palla + 1 (se <=4), altrimenti riga palla
;   - Scorre ID=0..3 e memorizza il giocatore di quella riga più vicino
;     in X alla palla.
;   - Con certa probabilità (dipendente da PlayersSpeed) lo muove di
;     una cella a sinistra/destra verso la palla, usando
;     Game_TryMovePlayerHorizontally.
;   - Possibilità di restare fermo: più bassa a velocità alte.
; ---------------------------------------------------------------------------
AiMoveChaserTowardBall:
    
    push af
    push bc
    push de
    push hl

    push bc
    CALL Game_GetPlayerIdWithBall
    pop  bc
    CP   BALL_STATUS_CONTENDED
    JR   NZ,.no_contended_ball

    push    bc

    CALL    Game_GetBallPosition
    pop     bc
    ld      h, d
    ld      a, b
    cp      TEAM_WHITE
    jr      NZ,.contended_team_found
    inc     h
.contended_team_found:
    ld     d, h
    CALL   Game_GetPlayerInfoByPos
    JR     .after_player_to_move_found


    
.no_contended_ball:
    ld   c,b                 ; C = TEAM

    ; ball pos
    call Game_GetBallPosition    ; HL = X,Y
    PUSH DE
    POP  HL

    ; riga su cui cercare chaser
    ld   a,c                 ; TEAM
    cp   TEAM_WHITE
    jr   nz,.use_same_row

    ; TEAM_WHITE: riga ballY+1 se <=4, altrimenti ballY
    ld   a,d
    inc  a
    cp   5
    jr   c,.set_target_row
    ld   a,d
.set_target_row:
    ld   d,a                 ; D = targetRow
    jr   .got_target_row

.use_same_row:
    ; TEAM_BLACK: stessa riga palla
    ; D è già ballY
.got_target_row:

   


    ; cerca il giocatore più vicino in X a ballX sulla riga D
    ld   b,c                 ; B = TEAM
    ld   c,0                 ; ID = 0
    ld   a,255               ; bestID = 255 (none)
    ld   (Var_Hooks_BestDistanceX),a
    ld   (Var_Hooks_BestDistanceId),a


.chaser_loop:
    
    push bc
    push de
    call Game_GetPlayerInfoById   ; HL = pos (H=Y, L=X)
    pop  de
    pop  bc

    ld   a,h                 ; currY
    cp   d
    jr   nz,.next_id         ; non su riga target

    ; su riga target, calcola |X - ballX|
    ld   a,l                 ; currX
    sub  e                   ; X - ballX
    jp   p,.dist_ok
    neg
.dist_ok:
    ; A = distanza
    cp   l                   ; confronta con bestDist (L)
    jr   nc,.next_id         ; se >= bestDist, tieni quello vecchio

    ; nuovo migliore
    ld   (Var_Hooks_BestDistanceX),a                 ; bestDist = A
    ld   a,c
    ld   (Var_Hooks_BestDistanceId),a                 ; bestID = C

.next_id:
    inc  c
    ld   a,c
    cp   4
    jr   nz,.chaser_loop

    ; se bestID=255 -> nessun giocatore su quella riga
    ld   a,(Var_Hooks_BestDistanceId)
    cp   255
    jp   nz,.good_player_found

.after_player_to_move_found:
    ld    a, 1
    ld    (Var_Hooks_BestDistanceId), a
    ld    c, 1
    push  de
    push  bc
    CALL  Game_GetPlayerInfoById
    pop   bc
    pop   de
    ld    a, h
    cp    d
    JR    z, .good_player_found

    ld    a, 2
    ld    (Var_Hooks_BestDistanceId), a
    ld    c, 2
    push  de
    push  bc
    CALL  Game_GetPlayerInfoById
    pop   bc
    pop   de
    ld    a, h
    cp    d
    JR    z, .good_player_found

    ld    a, 3
    ld    (Var_Hooks_BestDistanceId), a
    ld    c, 3
    push  de
    push  bc
    CALL  Game_GetPlayerInfoById
    pop   bc
    pop   de


.good_player_found:
    ; --- decidi se muoverlo o lasciarlo fermo ---
    ; probabilità di muoversi ~ PlayersSpeed / 5
    call Game_GetRandomByte
    and  00000111b           ; 0..7
    ld   d,a                 ; rand

    ld   a,(Var_Game_PlayersSpeed)
    ; speed 1..5 -> soglia 1..5
    cp   d
    jr   c,.done             ; rand > speed -> non si muove (resta fermo)

    push    hl
    push    bc
    CALL    Game_GetPlayerIdWithBall
    pop     bc
    pop     hl
    CP      BALL_STATUS_CONTENDED
    JR      NZ,.after_ball_contended_check          

    CALL    Game_GetBallPosition
    LD      A, B
    CP      TEAM_WHITE
    JR      NZ, .contended_get_player

    INC     D

    ;JR      .done
.contended_get_player:
    ;push    bc
    call    Game_GetPlayerInfoByPos
    ;pop     bc
    jr      .move_chaser


.after_ball_contended_check:
    ; --- NUCLEO PULITO PER LA PARTE FINALE ---
    ; B = TEAM (non toccato), H = bestID, E = ballX
    ld   a, (Var_Hooks_BestDistanceId)
    ld   c,a                 ; C = bestID
    push bc
    call Game_GetPlayerInfoById   ; HL = curr pos
    pop  bc                  ; B=TEAM, C=bestID
.move_chaser:
    push hl
    CALL Game_GetBallPosition
    pop hl
    ld   a,l                 ; currX
    cp   e
    jr   z,.chaser_same_col
    jr   c,.chaser_go_east   ; currX < ballX
    jr   .chaser_go_west     ; currX > ballX

.chaser_go_east:
    ld   a,PLAYER_ASKED_DIRECTION_EAST
    jr   .chaser_do_move

.chaser_go_west:
    ld   a,PLAYER_ASKED_DIRECTION_WEST
    jr   .chaser_do_move

.chaser_same_col:
    ; stessa colonna → 50% move left/right, 50% restare fermo
    push bc
    call Game_GetRandom0_4
    pop  bc
    cp  0
    jr  z,.done              ; 1/4 → fermo
    
    ;ld   a,l
    ;cp   0
    ;jr   z,.chaser_go_east
    ;cp   4
    ;jr   z,.chaser_go_west
;
    ;push bc
    ;call Game_GetRandom0_4
    ;pop  bc
    ;cp  0
    ;jr  z,.chaser_go_west
    cp  1
    jr  z,.chaser_go_west
    cp  3
    jr  z,.chaser_go_west
    jr  .chaser_go_east

.chaser_do_move:
    CALL Hooks_TickStop
    call Game_TryMovePlayerHorizontally
    CALL Hooks_TickStart
    ; ignoriamo SUCCESS/FAILURE

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret

; ---------------------------------------------------------------------------
; AiBallCarrierDecision
;
; INPUT:
;   B = TEAM
;   C = ID del portatore
; ---------------------------------------------------------------------------
AiBallCarrierDecision:
    push af
    push bc
    push de
    push hl

    ; BC in ingresso: B = TEAM, C = ID del portatore
    ld   d,b                 ; salva TEAM
    ld   e,c                 ; salva ID

    ; random 0..7
    CALL  Game_GetRandom0_20
    ld    h,a                 ; H = rand 0..7

    ld   a,(Var_Game_PlayersSpeed)
    SLA A
    SLA A
    ; speed alta -> più probabilità di agire
    cp   h
    jr   c,.do_nothing       ; rand > speed -> sta fermo

    ; altrimenti sceglie azione:
    ;   0..2  -> tiro
    ;   3..4  -> move east
    ;   5..6  -> move west
    ;   7     -> tentativo verticale
    ld   a,h
    cp   2
    jr   c,.try_shot
    cp   5
    jr   c,.move_east
    cp   8
    jr   c,.move_west
    jr   .done

.try_shot:
    ld   b,d                 ; ripristina TEAM
    ld   c,e                 ; ripristina ID
    call Game_TryShot
    jr   .done

.move_east:
    ld   b,d
    ld   c,e
    ld   a,PLAYER_ASKED_DIRECTION_EAST
    call Game_TryMovePlayerHorizontally
    jr   .done

.move_west:
    ld   b,d
    ld   c,e
    ld   a,PLAYER_ASKED_DIRECTION_WEST
    call Game_TryMovePlayerHorizontally
    jr   .done


.do_nothing:
    ; resta fermo

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret


; ---------------------------------------------------------------------------
; AiVerticalAdjustments
;
; INPUT:
;   B = TEAM
; NOTE:
;   - muove solo giocatori ID 1..3 (mai il portiere)
;   - non muove il giocatore che ha la palla
; ---------------------------------------------------------------------------
AiVerticalAdjustments:
    push af
    push bc
    push de
    push hl




    ld   d,b                 ; D = TEAM (salvato)

    ; probabilità di attivare il blocco verticale
    call Game_GetRandom0_20

    cp   15
    jr   nc,.done            ; ~12.5% dei tick

; --- scegli un ID 1..3 ------------------------------------------------
.gen_id:
    call Game_GetRandom0_4   ; 0..4
    cp   1
    jr   c,.done           ; 0 -> scarta
    cp   4
    jr   nc,.done          ; 4 -> scarta (vogliamo 1..3)
    ld   c,a                 ; C = ID (1..3)
    ld   e,c                 ; E = ID salvato

    ; --- verifica che NON sia il possessore della palla ---------------
    ; (Game_GetPlayerIdWithBall distrugge BC, quindi lo salviamo)
    push bc                  ; salva TEAM (B) e ID (C)
    call Game_GetPlayerIdWithBall
    ; A = stato/team, H = ownerID (o 255), L = contendenteID (o 255)
    pop  bc                  ; ripristina B=TEAM, C=ID scelto (1..3)

    ; Se A è TEAM_BLACK / TEAM_WHITE e coincide con B,
    ; e H == C -> questo giocatore ha la palla => NON muoverlo
    cp   TEAM_BLACK
    jr   z,.check_owner
    cp   TEAM_WHITE
    jr   z,.check_owner
    jr   .no_owner           ; palla libera / contesa / in movimento

.check_owner:
    cp   b                   ; team col possesso == nostro team?
    jr   nz,.no_owner
    ld   a,h                 ; ownerID
    cp   c                   ; è proprio il nostro giocatore?
    jr   z,.done             ; sì -> non muovere verticalmente

.no_owner:
    ; --- scegli direzione N/S (random) ------------------------------
    

    call Game_GetRandom0_4
   

 
    CP   1
    JR   z,.move_down
    CP   3
    JR   nc,.move_down
    ld   a,PLAYER_ASKED_DIRECTION_NORTH

.do_move:
    call Game_TryMovePlayerVertically

.done:
    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
.move_down:
    ld   a,PLAYER_ASKED_DIRECTION_SOUTH
    jr   .do_move


; ---------------------------------------------------------------------------
; Game_Ai_MoveHoriz_AwayOrRandom
;
; INPUT:
;   B = TEAM
;   C = ID del giocatore coinvolto nella contesa
;
; Effetto:
;   - Legge posizione di questo giocatore e quella dell'altro (se vuoi
;     puoi passare anche l'altro X in un registro).
;   - Per semplicità:
;       * se X=0 -> prova solo EAST
;       * se X=4 -> prova solo WEST
;       * se X=1 e a sinistra c'è compagno -> forza EAST
;       * se X=3 e a destra   c'è compagno -> forza WEST
;       * altrimenti dir random LEFT/RIGHT.
;   - Chiama Game_TryMovePlayerHorizontally
; ---------------------------------------------------------------------------
Game_Ai_MoveHoriz_AwayOrRandom:
    push af
    push bc
    push de
    push hl

    ; prendi posizione corrente
    call Game_GetPlayerInfoById      ; HL = pos (H=Y, L=X)
    ld   d,h                         ; D = Y
    ld   e,l                         ; E = X

    ; bordi assoluti
    ld   a,e
    cp   0
    jr   z,.force_east
    cp   4
    jr   z,.force_west

    ; colonne 1 o 3 con compagno accanto?
    ;  - se X=1 e a sinistra (0) c'è un compagno → forza east
    ;  - se X=3 e a destra  (4) c'è un compagno → forza west

    cp   1
    jr   nz,.check_x3
    ; X=1: controlla (Y,0)
    push bc
    ld   d,h          ; Y
    ld   e,0
    call Game_GetPlayerInfoByPos
    pop  bc
    cp   NO_VALUE
    jr   nz,.force_east   ; qualcuno lì → forza east
    jr   .rand_dir

.check_x3:
    cp   3
    jr   nz,.rand_dir
    ; X=3: controlla (Y,4)
    push bc
    ld   d,h
    ld   e,4
    call Game_GetPlayerInfoByPos
    pop  bc
    cp   NO_VALUE
    jr   nz,.force_west

.rand_dir:
    ; direzione random
    call Game_GetRandomByte
    and 00000001b
    ld   a,PLAYER_ASKED_DIRECTION_WEST
    jr   z,.do_move
    ld   a,PLAYER_ASKED_DIRECTION_EAST
    jr   .do_move

.force_east:
    ld   a,PLAYER_ASKED_DIRECTION_EAST
    jr   .do_move

.force_west:
    ld   a,PLAYER_ASKED_DIRECTION_WEST

.do_move:
    call Game_TryMovePlayerHorizontally

    pop  hl
    pop  de
    pop  bc
    pop  af
    ret
;---------------------------------------------------------------------------
; Hooks_UpdateTimeToPlay
;---------------------------------------------------------------------------
Hooks_UpdateTimeToPlay:
    LD      A, (Var_Game_TimeToPlay)
    LD      (Var_Game_SecondsToPlay), A
    RET
