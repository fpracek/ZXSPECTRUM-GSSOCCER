; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** MENU.ASM ***

; ------ ROUTINES ------

;------------------------------------------------------------------------
; Show menu
; INPUT: -
; OUTPUT: -
; MODIFY: A, DE, HL, BC
;-------------------------------------------------------------------------
Menu_Show:
    CALL    Hooks_TickStart
    CALL    Hooks_InitAICounters
    LD      A, 2
    LD      (Var_Game_PlayersSpeed), A ; set default players speed to 2
    CALL    Game_Start
    CALL    Menu_ShowOptions
    EI
    RET

;------------------------------------------------------------------------
; Show options menu
; -------------------------------------------------------------------------
Menu_ShowOptions:
    CALL    VDP_ClearMenuSideArea

    LD      HL, TXT_BTN_PLY1_1
    LD      D, 0
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY1_2
    LD      D, 1
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY1_3
    LD      D, 2
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY1_4
    LD      D, 3
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY1_5
    LD      D, 4
    LD      E, 24
    CALL    VDP_PrintString


    LD      HL, TXT_EMPTY
    LD      D, 14
    LD      E, 23
    CALL    VDP_PrintString

 
    LD      HL, TXT_EMPTY
    LD      D, 6
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_EMPTY
    LD      D, 7
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_EMPTY
    LD      D, 8
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_EMPTY
    LD      D, 9
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_EMPTY
    LD      D, 10
    LD      E, 24
    CALL    VDP_PrintString


    LD      HL, TXT_CPU
    LD      D, 13
    LD      E, 23
    CALL    VDP_PrintString

    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_1_PLAYER
    JP      Z, .Level1
    LD      HL, TXT_GAME_MODE_2_PLAYERS
    LD      D, 13
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY2_1
    LD      D, 6
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY2_2
    LD      D, 7
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY2_3
    LD      D, 8
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY2_4
    LD      D, 9
    LD      E, 24
    CALL    VDP_PrintString
    LD      HL, TXT_BTN_PLY2_5
    LD      D, 10
    LD      E, 24
    CALL    VDP_PrintString
    CALL    .Start


.Level1
    LD      HL, TXT_LEVEL_NO
    LD      D, 14
    LD      E, 23
    CALL    VDP_PrintString
    LD      A, (Var_Game_SelectedPlayers)
    CP      GAME_MODE_2_PLAYERS
    JP      Z, .Start

    LD      A, 63
    LD      D, 14
    LD      E, 29
    CALL    VDP_PrintRamChar

    LD      A, (Var_Game_SelectedLevel)
    CP      1
    JP      NZ, .Level2
    LD      HL, TXT_LEVEL_1
    LD      D, 14
    LD      E, 23
    CALL    VDP_PrintString
    JP      .Start
.Level2:
    LD      A, (Var_Game_SelectedLevel)
    CP      2
    JP      NZ, .Level3
    LD      HL, TXT_LEVEL_2
    LD      D, 14
    LD      E, 23
    CALL    VDP_PrintString
    JP      .Start
.Level3:
    LD      A, (Var_Game_SelectedLevel)
    CP      3
    JP      NZ, .Level4
    LD      HL, TXT_LEVEL_3
    LD      D, 14
    LD      E, 23
    CALL    VDP_PrintString
    JP      .Start
.Level4:
    LD      A, (Var_Game_SelectedLevel)
    CP      4
    JP      NZ, .Level5
    LD      HL, TXT_LEVEL_4
    LD      D, 14
    LD      E, 23
    CALL    VDP_PrintString
    JP      .Start
.Level5:
    LD      HL, TXT_LEVEL_5
    LD      D, 14
    LD      E, 23
    CALL    VDP_PrintString
.Start:
    LD      HL, TXT_SPACE
    LD      D, 17
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_START
    LD      D, 18
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_GSSOCCER
    LD      D, 22
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_2025
    LD      D, 21
    LD      E, 23
    CALL    VDP_PrintString
    LD      HL, TXT_PRACEK
    LD      D, 23
    LD      E, 23
    CALL    VDP_PrintString
    RET


