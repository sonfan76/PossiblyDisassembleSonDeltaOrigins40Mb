* ============================================================================
* SEGA GENESIS / MEGA DRIVE M68K HARDWARE & SSF2 BANKING SUBROUTINES
* Assembler: vasm -Fm68k -Fbin
* ============================================================================

SSF2_SLOT0_SRAM equ $A130F1   ; Bit 0: 1=Enable SRAM, 0=ROM Bank 0
SSF2_SLOT1      equ $A130F3   ; $080000-$0FFFFF
SSF2_SLOT2      equ $A130F5   ; $100000-$17FFFF
SSF2_SLOT3      equ $A130F7   ; $180000-$1FFFFF
SSF2_SLOT4      equ $A130F9   ; $200000-$27FFFF
SSF2_SLOT5      equ $A130FB   ; $280000-$2FFFFF
SSF2_SLOT6      equ $A130FD   ; $300000-$37FFFF
SSF2_SLOT7      equ $A130FF   ; $380000-$3FFFFF

* ----------------------------------------------------------------------------
* Map_SSF2_Slot7: Maps 512KB bank index in d0.b into $380000-$3FFFFF
* ----------------------------------------------------------------------------
Map_SSF2_Slot7:
    move.b  d0,(SSF2_SLOT7).l
    rts

* ----------------------------------------------------------------------------
* Enable_SRAM / Disable_SRAM: Standard SSF2 $A130F1 toggle
* ----------------------------------------------------------------------------
Enable_SRAM:
    move.b  #1,(SSF2_SLOT0_SRAM).l
    rts

Disable_SRAM:
    move.b  #0,(SSF2_SLOT0_SRAM).l
    rts
