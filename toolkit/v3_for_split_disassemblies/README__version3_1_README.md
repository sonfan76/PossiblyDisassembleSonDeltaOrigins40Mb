[This is an in-progress tooling development                        ]
[NOTE: Read the PDFs for full info] [Sonic_Delta_v3.1_README-3.pdf ]
[                           Sonic_Delta_v3.1_Illustrated_Guide.pdf ]

# Sonic Delta 40Mb Disassembly Pipeline (v3.1)

Automated reverse-engineering and repository-generation pipeline for bank-switched 40Mb (5 MB) Sega Genesis ROM hacks (`GM NETO-001-40` / `Sonic_Delta_Origins_2026.bin`).

This toolchain splits the 5 MB ROM into ten 512 KB SSF2 mapper banks, labels Genesis hardware registers, injects Sonic 1/2/3&K RAM symbols and Neto custom bank-switch hooks in Ghidra, exports clean listings, and compiles a modular, `vasm`-ready assembly repository.

---

## 1. Prerequisites

* **OS:** Linux (tested on Devuan Chimaera / Debian 11+)
* **Python:** Python 3.8+ (standard library only; no `pip` packages required)
* **Java:** OpenJDK 17 (`openjdk-17-jdk`)
* **Ghidra:** Ghidra 11.0.3 extracted to `/opt/ghidra_11.0.3_PUBLIC`
  * *Note:* `run_pipeline.sh` auto-detects `/opt/ghidra_*/support/analyzeHeadless`. If you install Ghidra elsewhere, pass `GHIDRA_HEADLESS=/path/to/support/analyzeHeadless`.
* **Assembler *(Optional)*:** `vasmm68k_mot` (only required if you want to recompile `sonic_delta_disasm_repo` back into a `.bin` ROM).

---

## 2. Directory Setup & Upstream Disassemblies

Place your target ROM (`Sonic_Delta_Origins_2026.bin`) and the three upstream Sonic split disassemblies directly inside the `v3` working directory.

### Copy / Extract Upstream Disassemblies
If you have the archives (`s1disasm-AS.zip`, `s2disasm-master.zip`, `skdisasm-master.zip`), unzip them into `v3/`:
```bash
cd ~/Downloads/NTRET/v3
unzip -q /path/to/s1disasm-AS.zip
unzip -q /path/to/s2disasm-master.zip
unzip -q /path/to/skdisasm-master.zip
```
*(Alternatively, symlink existing folders using `ln -s /path/to/folder <expected_name>`).*

### Expected Folder Layout
Your `v3` directory should look like this before running:
```text
v3/
\u251c\u2500\u2500 Sonic_Delta_Origins_2026.bin   # Target 5 MB (40Mb) ROM
\u251c\u2500\u2500 s1disasm-AS/                   # Must contain _Constants.asm & _Variables.asm
\u251c\u2500\u2500 s2disasm-master/               # Must contain s2.constants.asm
\u251c\u2500\u2500 skdisasm-master/               # Must contain s3.constants.asm & sk.constants.asm
\u251c\u2500\u2500 run_pipeline.sh                # v3.1 master orchestrator
\u251c\u2500\u2500 ghidra_auto_bank.py            # v3.1 Ghidra analyzer + raw_bank_XX.asm exporter
\u251c\u2500\u2500 test_v3_pipeline.py            # Synthetic offline test suite
\u2514\u2500\u2500 ...                            # Post-processing Python scripts
```

---

## 3. Running the Pipeline

### Step 1: Verify the Python Environment
Run the synthetic test suite to confirm all Python post-processors work properly:
```bash
python3 test_v3_pipeline.py
```
Expected output: `[+] ALL V3 PIPELINE TESTS PASSED SUCCESSFULLY!`

### Step 2: Run the Full Disassembly
Make sure `run_pipeline.sh` is executable and launch it:
```bash
chmod +x run_pipeline.sh
./run_pipeline.sh
```
*(If your ROM uses a different filename, pass it as the first argument: `./run_pipeline.sh "Other_Rom_Name.bin"`).*

### Generated Output
* `banks/bank_00.bin` \u2013 `bank_09.bin`: Raw 512 KB ROM bank splits.
* `ghidra_proj/`: Interactive Ghidra database (`SonicDelta_bank_00` through `bank_09`).
* `disasm_banks/`: Raw Ghidra exports (`raw_bank_XX.asm`) and `vasm`-formatted bank files (`bank_XX.asm`).
* `sonic_delta_disasm_repo/`: Final modular disassembly repository with extracted assets, macros, cross-references, and a build `Makefile`.

---

## 4. Caveats & Important Notes

1. **Exact Upstream Folder Names Are Required**
   * `import_upstream_constants.py` and `match_upstream.py` look specifically for `s1disasm-AS`, `s2disasm-master`, and `skdisasm-master`.
   * If any folder is missing or named differently, the pipeline will **not** crash\u2014it will print a warning and skip upstream symbol/asset matching for that game, resulting in more raw unlabeled data blocks.
2. **Asset Matching vs. 68k Code Matching**
   * Out of the box, extracting the three upstream disassemblies enables **100% RAM/constant symbol injection** and **binary asset matching** (Nemesis/Kosinski/Enigma graphics, palettes, level layouts).
   * To also enable **compiled 68k subroutine matching**, build each upstream disassembly once using its included build script so that a compiled `.bin` and `.lst` pair (e.g., `s2built.bin` + `s2built.lst`) exists inside its root folder before running `./run_pipeline.sh`.
3. **Runtime SSF2 Bank-Switch Tracing (`trace_banks.txt`)**
   * Because the 40Mb ROM dynamically swaps 512 KB banks via writes to `$A130F1`\u2013`$A130FF`, static analysis cannot resolve every dynamic bank jump on its own.
   * If you capture a runtime trace log using the included `trace_ssf2_live.lua` (BizHawk/Gens) or `blastem_trace_ssf2.gdb` (BlastEm) and save it as `trace_banks.txt` in `v3/`, `run_pipeline.sh` will automatically parse it into `resolved_switches.json` and annotate the exact switch targets.
4. **Standalone Bank Addresses in Ghidra GUI**
   * Each 512 KB bank is imported into `ghidra_proj/` starting at local offset `0x000000` so Ghidra can analyze all 10 banks cleanly. Cross-bank jump annotations are added after export by `xref_enricher.py` inside `sonic_delta_disasm_repo/`.
5. **Devuan Chimaera / Debian 11 `apt` Mirrors**
   * If installing `openjdk-17-jdk` on an archived Debian 11 / Devuan Chimaera system, ensure `/etc/apt/sources.list` points to `http://devuan.org` with `Acquire::Check-Valid-Until "false";` enabled, as live mirrors return `404 Not Found`.
