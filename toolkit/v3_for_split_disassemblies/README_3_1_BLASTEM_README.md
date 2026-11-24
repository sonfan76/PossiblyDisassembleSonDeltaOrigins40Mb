[This is an in-progress tooling development                        ]
[NOTE: Read the PDFs for full info] [Sonic_Delta_v3.1_README-3.pdf ]
[                           Sonic_Delta_v3.1_Illustrated_Guide.pdf ]

# BlastEm Runtime SSF2 Bank-Switch Tracing Guide (`trace_banks.txt`)

**Goal:** Capture 100% of dynamic SSF2 mapper bank switches (`$A130F1`\u2013`$A130FF`) in `Sonic_Delta_Origins_2026.bin` (`GM NETO-001-40`) using **BlastEm** on Linux so the v3.1 pipeline can resolve every cross-bank jump, music pointer, and level asset into a complete, 100% split **Sonic Standard Libre** disassembly.

---

## 1. Why Runtime Tracing Is Required for 100% Coverage

Static analysis (`extract_neto_custom.py`) catches immediate writes to the SSF2 mapper registers (such as `move.b #4, ($A130F5)`), **but it cannot resolve dynamic register writes** (such as `move.b d0, ($A130F5)` where `d0` is calculated at runtime from a level ID, character selection, or sound test index).

Capturing `trace_banks.txt` records the exact Program Counter (`PC`), the SSF2 register written, and the actual bank index (`0x00`\u2013`0x09`) loaded at runtime.

---

## 2. Prerequisites (Linux)

* **BlastEm:** Native Linux build (`blastem`)
* **Multi-Architecture GDB:** Required to speak Motorola 68000 protocol to BlastEm's debug stub:
  ```bash
  sudo apt update && sudo apt install -y gdb-multiarch
  ```
* **Pipeline Files:** `blastem_trace_ssf2.gdb` and `Sonic_Delta_Origins_2026.bin` inside `~/Downloads/NTRET/v3/`.

---

## 3. Step-by-Step: Capturing `trace_banks.txt`

### Step 1: Launch BlastEm in Debug Stub Mode
Open **Terminal 1**, navigate to your `v3` directory, and start BlastEm with the uppercase `-D` flag:
```bash
cd ~/Downloads/NTRET/v3
blastem -D Sonic_Delta_Origins_2026.bin
```
* *Expected behavior:* The BlastEm window will open and remain black/paused at reset until GDB connects on `localhost:1234`.

### Step 2: Attach GDB with `blastem_trace_ssf2.gdb`
Open **Terminal 2** in the same directory and attach `gdb-multiarch`:
```bash
cd ~/Downloads/NTRET/v3
gdb-multiarch -x blastem_trace_ssf2.gdb
```
* Once GDB connects and issues `continue`, BlastEm will boot the ROM and begin logging every write to `$A130F1`\u2013`$A130FF` into `trace_banks.txt`.
* *(Performance Note: Because GDB memory watchpoints single-step the 68000 CPU over TCP, emulation will run slower than 60 FPS\u2014this is normal).*

---

## 4. Playthrough Checklist (What to Trigger in Neto's ROM)

To achieve **100% bank-switch coverage** across all 10 banks (40Mb / 5 MB), exercise every code path that swaps ROM banks during your trace session:

1. **Boot & Title Sequence**
   * Let the Sega logo, Neto splash screen, and Title Screen load completely.
   * Let the demo attract mode cycle at least once.
2. **Main Game Mode Select / Hub Menu**
   * Enter Neto's custom game/character selector menu and toggle through every available option:
     * **Sonic 1** mode
     * **Sonic 2** mode
     * **Sonic 3 / Sonic & Knuckles** mode
     * **Sonic Delta / Custom** modes & character combinations (Sonic, Tails, Knuckles, Amy, etc.)
3. **Level Select & Zone Transitions (Critical)**
   * Open the **Level Select** menu for each game engine mode.
   * Load **at least one Act from every single Zone** across Sonic 1, Sonic 2, and Sonic 3&K (each zone loads distinct level layout, chunk, art, and object banks).
   * Trigger **Act 1 -> Act 2 transitions** (or signpost end-of-act tally) to capture mid-stage bank reloads.
   * Enter a **Special Stage** (via giant ring or level select) and a **Bonus Stage**.
4. **Sound Test / Music & SFX Bank Swaps**
   * Open the **Sound Test** and play tracks across the full ID range (`$01` through `$FF`)\u2014especially music tracks from Sonic 1, Sonic 2, Sonic 3, S&K, and custom tracks, as the Z80/68k sound driver swaps DAC sample and FM sequence banks dynamically.
5. **SRAM Save / Load Screen**
   * Enter the Save Select screen (triggers `$A130F1` SRAM/ROM bank toggling).
6. **Super / Hyper Transformations**
   * Trigger Super Sonic / Hyper transformation (swaps palette/art/music banks).

---

## 5. Saving `trace_banks.txt` & Running v3.1

### Step 1: Stop the Trace Cleanly
1. Close the BlastEm window (or press `Ctrl+C` in **Terminal 2** and type `quit`).
2. Confirm `trace_banks.txt` was written in your `v3` directory and is non-empty:
   ```bash
   ls -lh ~/Downloads/NTRET/v3/trace_banks.txt
   ```

### Step 2: Verify Upstream Disassemblies Are in Place
Ensure the three upstream Sonic split disassemblies are extracted directly inside `~/Downloads/NTRET/v3/`:
* `s1disasm-AS/`
* `s2disasm-master/`
* `skdisasm-master/`

### Step 3: Run the Full v3.1 Disassembly Pipeline
Run `run_pipeline.sh`\u2014it will automatically detect `trace_banks.txt`, parse it with `collect_trace.py` into `resolved_switches.json`, import all 10 banks into Ghidra, export the raw listings, and build the modular repository:
```bash
cd ~/Downloads/NTRET/v3
chmod +x run_pipeline.sh
./run_pipeline.sh
```

### Final Output
* `resolved_switches.json`: Deduplicated map of every runtime SSF2 bank switch (`PC` -> register -> target bank).
* `ghidra_proj/`: Complete 10-bank Ghidra database annotated with hardware labels, upstream symbols, Neto hooks, and runtime trace hits.
* `sonic_delta_disasm_repo/`: Clean, split, `vasm`-ready **Sonic Standard Libre** base repository.


4. **Neto's Custom Music Player / Jukebox & Sound Tests**
   * Open **Neto's custom Music Player** from the main hub/options menu.
   * Cycle through tracks across **every game category** (Sonic 1, Sonic 2, Sonic 3, S&K, and Custom/Bonus tracks)\u2014Neto's unified jukebox uses a dynamic bank-lookup table to map the upper 40Mb audio/DAC banks into 68k/Z80 space before initializing the sound driver.
   * Let each selected track play for **1\u20132 seconds** so both initial sequence bank swaps and mid-track DAC/PCM sample bank swaps are logged.
   * Also test the classic **in-game Sound Tests** (`$01`\u2013`$FF`) in case they call separate legacy bank-switch wrappers.


