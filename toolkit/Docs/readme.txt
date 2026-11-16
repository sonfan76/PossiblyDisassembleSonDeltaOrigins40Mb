Documents
---------
From what was surfaced earlier in this conversation, Sonic Delta 40Mb (v0.79) is a multi-game Mega Drive compilation hack built on the SSF2 40Mbit (5MB) mapper ($A130F1–$A130FF) with active SRAM save switching on $A130F1 and a built-in Portuguese exception handler screen (Exceção $41). Because the raw ROM file itself is not attached to the current turn's context, I cannot run a fresh binary scan on it right now, though several architectural details from the previously analyzed metadata are worth keeping in mind as you disassemble and rebuild it:
1. Memory Map & SRAM Hazard ($200000–$3FFFFF)
    • Shared Upper Address Space: In the standard Sega SSF2 mapper, cartridge SRAM is mapped into $200001–$3FFFFF (odd bytes) whenever bit 0 of $A130F1 is set to 1.
    • Why Watch Out During Disassembly: Any routine in the base ROM that loads or saves progress toggles $A130F1 (move.b #1, ($A130F1)), temporarily masking out ROM Banks 4–7 ($200000–$3FFFFF) until move.b #0, ($A130F1) restores ROM access.
    • Code Placement Rule: Never execute M68K instructions directly from $200000–$3FFFFF while SRAM is enabled, or the CPU will fetch open-bus/SRAM garbage and trigger the ROM's built-in Exceção $41 crash screen. Keep SRAM access routines strictly inside the lower 2MB ($000000–$1FFFFF) or in Work RAM ($FF0000–$FFFFFF).

2. Multi-Game Compilation Structure (Sonic 2 Delta / Sonic 3 Delta / Sonic Delta Next)
Because this 40Mbit ROM stitches multiple Sonic builds and engines together into one cartridge:
    • Separate Sound Drivers (Z80): Each sub-game inside a multi-engine compilation typically carries its own Z80 sound driver and SMPS music/DAC sample tables stored in specific 512KB banks. When reassembling or relocating data, keep Z80 driver blocks aligned to their expected bank boundaries so the Z80 bus-request routines ($A11100 / $A11200) do not read wrong bank offsets.
    • Sub-Game Boot / Reset Trampolines: Switching between Sonic 2 Delta, Sonic 3 Delta, and Sonic Delta Next from the main menu usually works by configuring the SSF2 bank slots ($A130F3–$A130FF) for the target engine, clearing Work RAM, and jumping to a secondary entry point rather than executing a hard reset instruction (which would reset the SSF2 mapper latches back to default banks 0–7).
    • Built-In Diagnostic Screen: The author left the M68K Bank 9 test and Exceção $41 exception vectors active in the header ($000008–$0000BF). You can trace those vector pointers directly in Ghidra to see how the author implemented custom text rendering and bank verification.

3. Emulator & Flashcart Compatibility Notes
    • Header Size & Mapper Detection: Emulators like BlastEm, Genesis Plus GX, and flashcarts (Mega EverDrive) detect the 40Mbit SSF2 mapper either from the "SEGA SSF" system string at $000100 or because the ROM size exceeds 4MB (4,194,304 bytes). Make sure your Makefile always pads rebuilt_sonic_delta_40mb.bin to the exact 5,242,880-byte (5MB) boundary so emulators do not fall back to standard flat 4MB mapping.
    • Checksum Bypass vs. Checksum Fix: Many multi-game hacks patch out the boot checksum loop (beq → bra) so edits do not lock up on boot, while still reading $00018E in diagnostic screens. Keeping the checksum updater in your Makefile ensures compatibility either way.
If you'd like to re-upload the ROM binary or paste the output from probe_mapper.py / collect_trace.py, I can inspect the exact vector table, sub-game entry points, and bank allocation table for each of the 10 banks (BANK_00 through BANK_09).

------------

Here are the exact technical findings extracted directly from the ROM header and embedded routines you uploaded:
1. ROM Header & Build Metadata ($000100–$0001FF)
    • Console & Copyright: SEGA GENESIS / (C)SEGA 1994.JUN.
    • Title & Version: SONIC 2 DELTA - SONIC 3 DELTA - SONIC DELTA NEXT / NETO - SONIC DELTA 40Mb - v0.79.
    • Product Serial & Region: GM NETO-001-40 with JUE (Japan, USA, Europe) region flags.

2. Confirmed SSF2 Mapper & SRAM Architecture
    • Standard SSF2 Registers ($A130F1–$A130FF): The embedded bank-switch test routines (M68K Bank 1, M68K Bank 9) sequentially write to odd-byte SSF2 mapper registers $A130F1, $A130F3, $A130F5, $A130F7, $A130F9, $A130FB, $A130FD, and $A130FF.
    • SRAM Toggle on $A130F1: The ROM's built-in technical error screen (Exceção $41: SRAM não disponível) explicitly confirms how $A130F1 toggles SRAM above $200000:
        ◦ move.b #1, ($A130F1) enables SRAM (ativa SRAM).
        ◦ move.b #0, ($A130F1) disables SRAM and restores ROM access (desativa SRAM).
    • Toolkit Alignment: Your v2 toolkit (sonic_delta_m68k_toolkit_v2.zip) already excludes $A130F1 from watchpoints and tracks $A130F3–$A130FF, so it will capture 512KB ROM bank swaps cleanly without stopping on save-game SRAM toggles.

3. Embedded Developer Tools Inside the ROM
Author Neto (neto.baiano@hotmail.com) left a complete suite of interactive 68000 diagnostic tools compiled directly into the binary:
    • Full Exception Handler & Crash Debugger (Neto - Depurador Hex): Catches all standard M68K exceptions (Bus Error, Address Error, Illegal Instruction, Zero Divide, Privilege Violation, Trace, Line 10/15 Emulators, Traps 0–15) plus custom vectors (Mapeador não inicializado and SRAM não disponível). It dumps A0–A7, D0–D7, PC, SR, access mode (Lendo / Gravando), address space, and the faulting instruction word.
    • Live Hex Editor & Memory Viewer (Neto - Super Depurador - Sonic Delta Next): Includes interactive Visualizar (view) and Programador (edit) modes, live region switching (Asia, Américas, Europa), memory usage stats (Memória ocupada), and joypad shortcuts (B -> Ler / C -> Gravar, A+Start -> Sair do depurador).
    • Sub-Game Engine Payloads: Contains intact credit/header blocks for Sonic 3 (GM 00001009-0) and Sonic & Knuckles (GM 00004049-0, NO WAY!, GET BLUE SPHERES !) alongside custom bonus stages (BONUSTAGE) and compression streams.
Since we have the exact ROM header and embedded routines confirmed, would you like to:
    • Run collect_trace.py from v2 on your ROM in BlastEm to map out which SSF2 slots ($A130F3–$A130FF) load each sub-game?
    • Locate the entry point for the hidden Neto - Super Depurador hex editor in Ghidra so you can trigger it on demand?


------------

Here is how to execute both steps right away: running collect_trace.py from your v2 toolkit to map out the SSF2 bank slots across each sub-game, and finding the exact entry point for Neto's hidden Super Depurador in Ghidra.

1. Capture Live SSF2 Slot Mappings (collect_trace.py)
    1. Unzip sonic_delta_m68k_toolkit_v2.zip into the same directory as your ROM file (sonic_delta_origins.bin).
    2. Run the v2 trace collector:
       bash
       python3 collect_trace.py sonic_delta_origins.bin
       Use code with caution.
    3. What to do while BlastEm is open:
        ◦ Let the boot menu load, then launch Sonic 2 Delta, reset/return to the menu, launch Sonic 3 Delta, and finally launch Sonic Delta Next.
        ◦ Close the BlastEm window when finished. collect_trace.py will automatically write resolved_switches.json, showing the exact caller_pc, SSF2 slot ($A130F3–$A130FF), and bank_index used to boot each game engine.

2. Locate Neto - Super Depurador in Ghidra
You can jump straight to the hidden debugger's entry routine inside Ghidra in under a minute:
    1. Search for the Menu Title String:
        ◦ Open the imported ROM in Ghidra CodeBrowser and press S (or go to Search → For Strings...), then click Search.
        ◦ Filter the results list for Super Depurador (or Depurador hexadecimal).
    2. Trace the Cross-Reference (XREF) Back to the Entry Function:
        ◦ Click the Super Depurador string address in the Listing view.
        ◦ Look at the green XREF[1]: tag on the right side of that line (or press Ctrl+Shift+F) and double-click the referencing instruction (typically a lea (Super_Depurador,PC),a0 or pea call).
        ◦ Scroll up to the top of that function (look for the movem.l register-save prologue at the function start) and note its address (for example, $00001A40).
    3. Find What Triggers It (Button Combo or Vector):
        ◦ With your cursor on that function's start address, press Ctrl+Shift+F again to inspect every caller in the ROM.
        ◦ Check whether it is called from the controller polling loop (a cmpi.w or btst checking a specific joypad button combination on Controller 1 or Controller 2) or wired directly to an exception vector at $000008–$0000BF (such as Bus Error $000008 or Trap #0–#15 at $000080–$0000BC).

3. Optional: Force-Boot Super Depurador in BlastEm
Once you have that entry address (say $0000XXXX), you can test launching it immediately in BlastEm without hunting for the secret button code:
    1. Run blastem -d sonic_delta_origins.bin.
    2. At the (blastem) prompt, set a breakpoint right after TMSS initialization (b $000206), run c, and once hit, jump directly into the debugger routine with set $pc=$0000XXXX followed by c.
Once you run collect_trace.py or find the Super Depurador entry address in Ghidra, paste the contents of resolved_switches.json or the disassembly snippet around that function here so we can map out the sub-game bank layout and button trigger!


------------

will this make split disassemblies, like the sonic github repos have?
No, the current toolkit outputs monolithic 512KB bank files (BANK_00.asm through BANK_09.asm) rather than the modular, feature-split directory trees used in Sonic GitHub repositories (like s1disasm or s2disasm).
How Current Toolkit Output Differs from Sonic GitHub Repos
    • Current v2 Toolkit Output: Groups everything strictly by hardware memory boundary. Every routine, art asset, sound sequence, and collision table inside a 512KB SSF2 bank is dumped sequentially into a single flat file (BANK_00.asm, BANK_01.asm, etc.).
    • Sonic GitHub Disassemblies (s1disasm / s2disasm / s3kdisasm): Organize code and assets functionally into small, human-readable .asm and .bin files connected by include and incbin directives (for example, obj/Sonic.asm, levels/GHZ/Layout.bin, sound/music/Mus81.asm, art/nemesis/Ring.bin).

How to Automatically Split Banks into a GitHub-Style Disassembly
You can add a post-export splitter script (split_to_repo.py) on top of your v2 toolkit to transform those flat BANK_XX.asm files into a clean s2disasm-style repository tree:
    1. Function-Level Code Splitting (include):
        ◦ Scan each BANK_XX.asm for subroutine boundaries (rts, rte, jmp, and Ghidra function headers).
        ◦ Extract individual routines or subsystems (such as the exception handler, VDP routines, or object AI loops) into separate files under code/bank_XX/sub_XXXXXX.asm and replace them in the master bank file with include "code/bank_XX/sub_XXXXXX.asm".
    2. Binary Asset Extraction (incbin):
        ◦ Identify contiguous dat_XXXXXX: blocks (compressed Nemesis/Kosinski art tiles, level chunk maps, and SMPS audio data) that exceed a chosen byte threshold (e.g., 64 bytes).
        ◦ Write their raw bytes directly to external .bin files under assets/bank_XX/dat_XXXXXX.bin and replace the thousands of dc.b lines in the .asm file with a single clean incbin "assets/bank_XX/dat_XXXXXX.bin" directive.
    3. Global Symbol & Equate Header (equates.asm):
        ◦ Collect all hardware registers (VDP_data_port, SSF2_bank_7), RAM addresses ($FFFF0000–$FFFFFFFF), and cross-bank entry points into a shared equates.asm header included at the top of the build.

Trade-Offs to Keep in Mind
    • Flat BANK_XX.asm Files: Best for guaranteed 1:1 byte-identical round-trip assembly while you are still mapping unknown pointer tables and discovering where compressed data begins and ends.
    • Modular GitHub-Style Split: Best once you have identified major code and asset boundaries, making it much easier to edit individual game objects, swap binary art assets with external tools (like SonLVL or Clownacy's compressors), and track changes cleanly in Git.
Would you like me to write split_to_repo.py (and update the Makefile) so it automatically splits your exported BANK_XX.asm files into a modular code/ + assets/ directory tree using include and incbin while preserving a 1:1 byte-identical build?
AI responses may include mistakes. Current limitations only allow part of the document to be used for this answer. Learn more



