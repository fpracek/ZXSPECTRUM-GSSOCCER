; ===================================================================
; GS11-Soccer - 2025 Fausto Pracek
; ===================================================================

; *** GSSOCCER.ASM ***

    DEVICE ZXSPECTRUM48
    SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
    
    ORG 0x8000               ; Loader address (0x8000)

    INCLUDE "constants.asm"
    INCLUDE "string.asm"						; Include hooks library
	INCLUDE "hooks.asm"						; Include hooks library
    INCLUDE "vdp.asm"                       ; Include screen library   
    INCLUDE "menu.asm"                      ; Include menu library
    INCLUDE "utils.asm"                     ; Include utilities library
    INCLUDE "game.asm"                      ; Include game library


Begin:
  
8    CALL    Game_InitVariables              ; Initialize the screen
    
    CALL    VDP_ClearScreen

    CALL    VDP_LoadTiles                   ; Load tiles into RAM
    
    CALL    Menu_Show

    
MainLoop:
    EI
    HALT
    DI
    CALL    VBlankISR
    jr      MainLoop
   

 



    
      
  

; VARIABLES RAM AREA
    INCLUDE "tiles.asm"             ; Include tiles definitions
    INCLUDE "vars.asm"              ; Include variables definitions		

    SAVESNA "./out/gssoccer.sna", Begin
END

										

