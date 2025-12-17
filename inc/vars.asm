; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================


        ; Scegli qui la base RAM delle variabili


; -------------------------------------------------------------------
; General variables
; -------------------------------------------------------------------
Var_Sounds_Playing:                         DEFB    0       
Var_Sounds_Ptr:                             DEFW    0       
Var_Sounds_Len:                             DEFW    0       
Var_Utils_OldRnd:                           DEFB    0       
Var_Utils_VblankStopped:                    DEFB    0       
Var_Utils_NumberToPrint:                    DEFS    6,0     
Var_Utils_LastKbdKeyPressed:                DEFB    0       
Var_Utils_KbdKeyPressed:                    DEFB    0   
; -------------------------------------------------------------------
; Game variables
; -------------------------------------------------------------------
Var_Game_ActiveFieldSide:                   DEFB    0
Var_Game_SecondsToPlay:                     DEFB    0
Var_Game_SelectedLevel:                     DEFB    0
Var_Game_BallOwnerTeamOrStatus:             DEFB    0
Var_Game_BallOwnerId:                       DEFB    0
Var_Game_BallTmp_FoundBelow:                DEFB    0
Var_Game_MoveTmpDir:                        DEFB    0
Var_Game_BallUpdateTimer:                   DEFB    0
Var_Game_BallTmp_FoundAbove:                DEFB    0
Var_Game_BallTmp_TeamAbove:                 DEFB    0
Var_Game_BallTmp_TeamBelow:                 DEFB    0
Var_Game_BallTmp_IdBelow:                   DEFB    0
Var_Game_BallTmp_IdAbove:                   DEFB    0
Var_Game_LastWhitePlayerMovedID:            DEFB    0
Var_Game_LastBlackPlayerMovedID:            DEFB    0
Var_Game_ScoreBlack:                        DEFB    0
Var_Game_TmpMoveTeam:                       DEFB    0
Var_Game_TmpMoveId:                         DEFB    0
Var_Game_TmpMoveDir:                        DEFB    0
Var_Game_TmpMoveCompanionId:                DEFB    0
Var_Game_TmpMoveCompanionX:                 DEFB    0
Var_Game_TmpMoveRow:                        DEFB    0
Var_Game_TmpMovStartCol:                    DEFB    0
Var_Game_TmpAskedMovingRow:                 DEFB    0
Var_Game_TmpMoveReadRowPlayersFromLeft:     DEFB    0
Var_Game_TmpNewX:                           DEFB    0
Var_Game_TmpNewY:                           DEFB    0
Var_Game_HumanPlayerSpeed:                  DEFB    0
Var_Game_ScoreWhite:                        DEFB    0
Var_Game_TimeToPlay:                        DEFB    0
Var_Game_TeamWithBall:                      DEFB    0
Var_Game_GoalkeeperHasBall:                 DEFB    0
Var_Game_BallDirection:                     DEFB    0
Var_Game_BallDiagonalMovCounter:            DEFB    0
Var_Game_VirtualPlayerYPos:                 DEFB    0
Var_Game_VirtualPlayerXPos:                 DEFB    0
Var_Game_VirtualPlayerTeam:                 DEFB    0
Var_Game_MatchInProgress:                   DEFB    0
Var_Game_PlayersSpeed:                      DEFB    0
Var_Game_TempTeam:                          DEFB    0
Var_Game_SelectedPlayers:                   DEFB    0
Var_Game_BallXPosition:                     DEFB    0
Var_Game_FirstKickType:                     DEFB    0
Var_Game_FirstKickFrameCounter:             DEFB    0
Var_Game_BeepStep:                          DEFB    0
Var_Game_BallYPosition:                     DEFB    0
Var_Game_BallYOldPosition:                  DEFB    0
Var_Game_BallXOldPosition:                  DEFB    0

; 56 bytes come in MSX: Var_Game_PlayersInfo + 56
Var_Game_PlayersInfo:                       DEFS    56,0

Var_Vdp_HalfFieldHorzLinePos:               DEFB    0

; -------------------------------------------------------------------
; Hooks / counters
; -------------------------------------------------------------------
Var_Hooks_Old_HTIMI:                        DEFS    4,0     ; 4
Var_Hooks_FrameCounter:                     DEFB    0
Var_Hooks_AiCounterBlack:                   DEFB    0
Var_Hooks_BlinkingType:                     DEFB    0
Var_Hooks_BlinkingTileToShow:               DEFB    0
Var_Hooks_BlinkingTileToHide:               DEFB    0
Var_Hooks_BlinkingActiveTile:               DEFB    0
Var_Hooks_BlinkingCounter:                  DEFB    0
Var_Hooks_GameResumingWaiting:              DEFB    0
Var_Hooks_CerimonySpeedCounter:             DEFB    0
Var_Hooks_BlinkingIsActive:                 DEFB    0
Var_Hooks_BlinkingMustResetFrameCounter:    DEFB    0
Var_Hooks_BestDistanceId:                   DEFB    0
Var_Hooks_BestDistanceX:                    DEFB    0
Var_Hooks_ForceVdpRedraw:                   DEFB    0
Var_Hooks_TickSpeed:                        DEFB    0
Var_Hooks_GoalCerimonyCounter:              DEFB    0
Var_Hooks_TickCounter:                      DEFB    0
Var_Hooks_TickSuspended:                    DEFB    0

; commento originale: 5 bytes
Var_Hook_RowOccupancy:                      DEFS    5,0

Var_Hooks_AiCounterWhite:                   DEFB    0
Var_Hooks_SecondsCounter:                   DEFB    0
Var_Hooks_MinutesCounter:                   DEFB    0


