NOTE: the v3.1 toolkit is more encompassing, it's in the directory below (and also as a zip file)
Note: uses Ghidra:
(If on linux, for instance, you need jdk, gdb, blastem and ghidra (which for some reason isn't packaged...))
>apt install -y openjdk-17-jdk gdb-multiarch blastem ;
>wget https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.0.3_build/ghidra_11.0.3_PUBLIC_20240410.zip ;
>sudo unzip ghidra_11.0.3_PUBLIC_20240410.zip -d /opt/
# Sonic Delta 40Mbit (SSF2 Mapper) M68K Dynamic Analysis & Rebuild Toolkit (v2)

This toolkit is specifically tuned for **40Mbit (5MB) Sega Genesis / Mega Drive ROMs using the standard Sega SSF2 mapper (`$A130F3`–`$A130FF`)**, filtering out SRAM toggles on `$A130F1` and removing unused `$220000` watchpoints.

## What Changed in v2
1. **SSF2-Only Watchpoint Filtering (`$A130F3`–`$A130FF`):** Excludes `$A130F1` (used for SRAM save/load toggling) and `$220000` so BlastEm only pauses on true 512KB ROM bank switches.
2. **Dynamic Per-Bank Overlay Window Mapping (`ghidra_auto_bank.py`):** Reads `resolved_switches.json` to map each extended bank (`BANK_08`, `BANK_09`, etc.) into the exact CPU window (`$080000`–`$380000`) observed at runtime instead of assuming a single static window.
3. **Byte-Accurate `vasm` Exporter & Two-Pass Symbol Resolver:** Preserves raw `dc.b` data chunks alongside disassembled M68K instructions and converts local hex branch/jump operands into `loc_XXXXXX` / `dat_XXXXXX` labels.

## Quick Start
1. **Probe static SSF2 references in the binary:**
   ```bash
   python3 probe_mapper.py your_rom.bin
   ```
2. **Capture live SSF2 bank switches in BlastEm:**
   ```bash
   python3 collect_trace.py your_rom.bin
   ```
3. **Run Ghidra headless overlay mapping & export `.asm` banks:**
   Edit `GHIDRA_DIR` and `ROM` in `run_pipeline.sh`, then run:
   ```bash
   ./run_pipeline.sh
   ```
4. **Normalize syntax, assemble 512KB slices with `vasm`, stitch 40Mbit ROM, and verify:**
   ```bash
   cd ~/sonic_delta_vasm_export
   cp /path/to/format_for_vasm.py /path/to/Makefile .
   make && make verify
   ```
