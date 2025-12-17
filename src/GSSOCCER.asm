; ===================================================================
; SAM.PR World - 2025 Fausto Pracek
; ===================================================================

        DEVICE ZXSPECTRUM48
        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        
        ORG 0x8000               ; Loader address (0x8000)


        INCLUDE "constants.asm"
        INCLUDE "vars.asm"
        INCLUDE "hooks.asm"			; Include hooks library
        INCLUDE "tiles.asm"                     ; Include tiles definitions
        INCLUDE "vdp.asm"                       ; Include screen library   
        INCLUDE "menu.asm"                      ; Include menu library
        INCLUDE "utils.asm"                     ; Include utilities library
        INCLUDE "game.asm"                      ; Include game library



    

InitGame:

        
        CALL    Game_InitVariables              ; Initialize the screen
        
        CALL    VDP_ClearScreen

        CALL    VDP_LoadTiles                   ; Load tiles into RAM
        ;CALL    VDP_SetPatternColors            ; Set pattern colors

        LD      A, FIELD_NORTH_SIDE
        LD      (Var_Game_ActiveFieldSide), A
        CALL    VDP_DrawField
        ;LD      D, 4
        ;LD      E, 4
        ;LD      A, TILE_WHITE_PLAYER
        ;CALL    VDP_DrawSprite
        CALL     Game_SetWhiteKickoffSchema
        CALL     VDP_PlayerMatrixRedraw

        CALL    Menu_Show
        CALL    Hooks_Init                      ; Install the VBlank hook
    
MainLoop:
        JR      MainLoop
   

         SAVESNA "./out/gssoccer.sna", InitGame
END



    
											
