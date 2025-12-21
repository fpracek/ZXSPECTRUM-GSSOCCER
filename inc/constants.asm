; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** CONSTANTS.ASM ***





PSG_SEL:                                        EQU 0A0h
PSG_WR:                                         EQU 0A1h
PSG_RD:                                         EQU 0A2h
SCR_BASE:                                       EQU 0x4000      ; Base address of the Spectrum screen
ATTR_BASE:                                      EQU 0x5800      ; Start of the attribute area
ROM_CHAR_SET_ADDRESS:                           EQU 0x3D00      ; Start of the ROM character set
RAM_CHAR_SET_ADDRESS:                           EQU 0xB500      ; Start of the RAM character set     

MATCH_TIME:                                     EQU 60  
TICK_SPEED:                                     EQU 5  

TILE_CORNER:                                    EQU 0
TILE_WHITE_PLAYER_WITH_BALL:                    EQU 1
TILE_BLACK_PLAYER_WITH_BACK_BALL:               EQU 2
TILE_CORNER_BALL:                               EQU 3
TILE_CORNER_BALL_EMPTY:                         EQU 4
TILE_REMOVE_WHITE_PLAYER_AND_BALL:              EQU 5
TILE_BALL_TOP:                                  EQU 6
TILE_BALL_TOP_FRONT:                            EQU 7
TILE_BALL_BOTTOM:                               EQU 64
TILE_WHITE_PLAYER_NEAR_HALF_FIELD:              EQU 80
TILE_WHITE_GOALKEEPER:                          EQU 96
TILE_WHITE_GOALKEEPER_WITH_BALL:                EQU 112
TILE_BLACK_GOALKEEPER:                          EQU 128
TILE_BLACK_GOALKEEPER_WITH_BALL:                EQU 144
TILE_WHITE_PLAYER:                              EQU 160
TILE_BLACK_PLAYER:                              EQU 176
TILE_BLACK_PLAYER_WITH_BALL:                    EQU 192
TILE_FIELD_LINE_TOP_LEFT:                       EQU 208
TILE_FIELD_LINE_VERTICAL:                       EQU 209
TILE_FIELD_LINE_HORIZONTAL:                     EQU 210
TILE_FIELD_LINE_TOP_RIGHT:                      EQU 211
TILE_FIELD_LINE_BOTTOM_LEFT:                    EQU 212
TILE_FIELD_LINE_BOTTOM_RIGHT:                   EQU 213
TILE_FIELD:                                     EQU 214
TILE_FIELD_LINE_LEFT_CROSS:                     EQU 215
TILE_FIELD_LINE_RIGHT_CROSS:                    EQU 216
TILE_FIELD_LINE_WHITE_PLAYER_1:                 EQU 217
TILE_FIELD_LINE_WHITE_PLAYER_2:                 EQU 218
TILE_BALL_BOTTOM_LEFT:                          EQU TILE_BALL_BOTTOM + 14   ; 78
TILE_BALL_BOTTOM_RIGHT:                         EQU TILE_BALL_BOTTOM + 15   ; 79
TILE_BALL_TOP_LEFT:                             EQU 221
TILE_BALL_TOP_RIGHT:                            EQU 222
TILE_BALL_FEET_OVERLAY_L:                       EQU 219   ; già esistente (top-left)
TILE_BALL_FEET_OVERLAY_R:                       EQU 220   ; già esistente (top-right)
TILE_BALL_BACK_OVERLAY_L:                       EQU 221   ; nuovo: spalla, parte sinistra
TILE_BALL_BACK_OVERLAY_R:                       EQU 222   ; nuovo: spalla, parte destra
TILE_WHITE_PLAYER_AND_BALL:                     EQU 223



TILE_PLAYERS_COLOR:                             EQU 0x13
TILE_FIELDS_LINES_COLOR:                        EQU 0x13
TILE_BALL_BOTTOM_L:                             EQU TILE_BALL_BOTTOM + 13
TILE_BALL_BOTTOM_R:                             EQU TILE_BALL_BOTTOM + 14

GREEN_CHAR_ATTRIBUTE:                           EQU 0x20  ; Green on black

FIELD_NORTH_SIDE:                               EQU 1
FIELD_SOUTH_SIDE:                               EQU 0
YES:                                            EQU 1
NO:                                             EQU 0
GAME_MODE_2_PLAYERS:                            EQU 2
GAME_MODE_1_PLAYER:                             EQU 1
NO_VALUE:                                       EQU 255
TEAM_WHITE:                                     EQU 1
TEAM_BLACK:                                     EQU 0
ROLE_GOALKEEPER:                                EQU 0
ROLE_DEFENDER:                                  EQU 1
ROLE_MIDFIELDER:                                EQU 2
ROLE_STRIKER:                                   EQU 3

PLAYER_ENTRY_SIZE:                              EQU 7  ; bytes per player entry in Var_Game_PlayersInfo

BALL_DIRECTION_NONE:                            EQU 0
BALL_DIRECTION_NORTH:                           EQU 1
BALL_DIRECTION_NORTH_EAST:                      EQU 2
BALL_DIRECTION_NORTH_WEST:                      EQU 3
BALL_DIRECTION_SOUTH:                           EQU 4
BALL_DIRECTION_SOUTH_EAST:                      EQU 5
BALL_DIRECTION_SOUTH_WEST:                      EQU 6

PLAYER_ASKED_DIRECTION_EAST:                    EQU 1
PLAYER_ASKED_DIRECTION_WEST:                    EQU 2
PLAYER_ASKED_DIRECTION_NORTH:                   EQU 3
PLAYER_ASKED_DIRECTION_SOUTH:                   EQU 4

DEMO_MODE_LEVEL:                                EQU 4

BALL_STATUS_MOVING:                             EQU 100
BALL_STATUS_CONTENDED:                          EQU 101
BALL_STATUS_FREE:                               EQU 102

SUCCESS:                                        EQU 1
FAILURE:                                        EQU 0

VDP_DATA:                                       EQU 098h
VDP_ADDR:                                       EQU 099h

BLINK_TYPE_GOAL:                                EQU 1 
BLINK_TYPE_CORNER:                              EQU 2
BLINK_TYPE_GOALKEEPER:                          EQU 3
BLINK_FRAMES_DURATION:                          EQU 30  

FIRST_KICK_TYPE_WHITE_HALF_FIELD:               EQU 1
FIRST_KICK_TYPE_BLACK_HALF_FIELD:               EQU 2
FIRST_KICK_TYPE_WHITE_BOTTOM_FIELD:             EQU 3
FIRST_KICK_TYPE_BLACK_BOTTOM_FIELD:             EQU 4


CERIMONY_MOVEMENT_SPEED:                        EQU 20

KBD_KEY_NONE:                                   EQU 0
KBD_KEY_SPACE:                                  EQU 32

KBD_KEY_UP:                                     EQU 55
KBD_KEY_DOWN:                                   EQU 54
KBD_KEY_LEFT:                                   EQU 53
KBD_KEY_RIGHT:                                  EQU 56


KBD_KEY_W:                                      EQU 87
KBD_KEY_A:                                      EQU 65
KBD_KEY_S:                                      EQU 83


KBD_KEY_K:                                      EQU 75
KBD_KEY_L:                                      EQU 76
KBD_KEY_O:                                      EQU 79

KEYBOARD_MAP:                                   DEFB #FE,"#","Z","X","C","V"
                                                DEFB #FD,"A","S","D","F","G"
                                                DEFB #FB,"Q","W","E","R","T"
                                                DEFB #F7,"1","2","3","4","5"
                                                DEFB #EF,"0","9","8","7","6"
                                                DEFB #DF,"P","O","I","U","Y"
                                                DEFB #BF,"#","L","K","J","H"
                                                DEFB #7F," ","#","M","N","B"

TXT_GAME_MODE_2_PLAYERS:                        DEFB "<2PLYS>",0
TXT_CPU:                                        DEFB "< CPU >",0
TXT_LEVEL_1:                                    DEFB "^LEV.1",0
TXT_LEVEL_2:                                    DEFB "^LEV.2",0
TXT_LEVEL_3:                                    DEFB "^LEV.3",0
TXT_LEVEL_4:                                    DEFB "^LEV.4",0
TXT_LEVEL_5:                                    DEFB "^LEV.5",0
TXT_LEVEL_NO:                                   DEFB "       ",0
TXT_BTN_PLY1_1:                                 DEFB "PLAYER 1",0
TXT_BTN_PLY1_2:                                 DEFB "O SHOT",0
TXT_BTN_PLY1_3:                                 DEFB "K LEFT",0
TXT_BTN_PLY1_4:                                 DEFB "L RIGHT",0
TXT_BTN_PLY1_5:                                 DEFB "       ",0 ; OR JOY1
TXT_BTN_PLY2_1:                                 DEFB "PLAYER 2",0
TXT_BTN_PLY2_2:                                 DEFB "W SHOT",0
TXT_BTN_PLY2_3:                                 DEFB "A LEFT",0
TXT_BTN_PLY2_4:                                 DEFB "S RIGHT",0
TXT_BTN_PLY2_5:                                 DEFB "       ",0 ; OR JOY2
TXT_SPACE:                                      DEFB " SPACE ",0 ; SPC/FIRE
TXT_START:                                      DEFB "TO START",0
TXT_GSSOCCER:                                   DEFB "GSSOCCER",0
TXT_2025:                                       DEFB "2025",0
TXT_PRACEK:                                     DEFB "F.PRACEK",0
TXT_EMPTY:                                      DEFB "        ",0
TXT_TIME:                                       DEFB "TIME",0
TXT_BLACK_TEAM:                                 DEFB "VISITORS",0
TXT_WHITE_TEAM:                                 DEFB "HOME",0
TXT_GAME_OVER:                                  DEFB "GAME OVER",0