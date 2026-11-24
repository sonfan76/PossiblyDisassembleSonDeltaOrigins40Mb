Note: uses Ghidra:
(If on linux, for instance, you need jdk, gdb, blastem and ghidra (which for some reason isn't packaged...))
>apt install -y openjdk-17-jdk
>apt install -y gdb-multiarch
>apt install -y blastem
>wget https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_11.0.3_build/ghidra_11.0.3_PUBLIC_20240410.zip
>sudo unzip ghidra_11.0.3_PUBLIC_20240410.zip -d /opt/

Updated to v3.1. Make sure to do the blastem tracing as noted first.

Running on Sonic_Delta_Origins_2026.bin

Make sure Sonic_Delta_Origins_2026.bin, s1disasm-AS/, s2disasm-master/, and skdisasm-master/ are in that directory.
    • 3. Run the fast static analysis stages first (make constants neto match) before launching Ghidra so you can immediately see every SSF2 bank switch, Neto debug string, and matched upstream asset/routine across all 10 banks:
      bash
      make constants neto match
      Use code with caution.
    • 4. Run the full 10-step pipeline (make) once you're ready for Ghidra headless disassembly and repository generation.
Once you run make constants neto match on Sonic_Delta_Origins_2026.bin, let me know what numbers it reports or if you want help inspecting neto_custom_hooks.json or upstream_matches.json!





where should I put those sonic 1, 2, 3&k disassemblies, and where should I put the NETO rom? and other files? my directory structure is the following: r00t@devuan:~/Downloads/NTRET/v3$ ls blastem_trace_ssf2.gdb macro_beautifier.py old_split_to_repo.py_old collect_trace.py Makefile run_pipeline.sh extract_neto_custom.py match_upstream.py source_block_swapper.py fix_v3.py med_format_for_vasm.py_med split_to_repo.py format_for_vasm.py med_source_block_swapper.py_med test_v3_pipeline.py genesis_subroutines.asm old_format_for_vasm.py_old trace_ssf2_live.lua ghidra_auto_bank.py old_genesis_subroutines.asm_old xref_enricher.py import_upstream_constants.py old_macro_beautifier.py_old r00t@devuan:~/Downloads/NTRET/v3$
Place the ROM and the three unpacked upstream disassembly folders directly inside your working directory (~/Downloads/NTRET/v3/), right alongside your Python scripts and Makefile. All default paths in Makefile, run_pipeline.sh, import_upstream_constants.py, match_upstream.py, xref_enricher.py, and source_block_swapper.py look in the current working directory.
Exact Directory Layout (~/Downloads/NTRET/v3/)
    • Target ROM (root of v3/):
        ◦ /v3/Sonic_Delta_Origins_2026.bin
    • Upstream Disassembly Folders (subdirectories inside v3/):
        ◦ /v3/s1disasm-AS/ (must contain _Constants.asm, _Variables.asm, artnem/, etc.)
        ◦ /v3/s2disasm-master/ (must contain s2.constants.asm, art/, etc.)
        ◦ /v3/skdisasm-master/ (must contain s3.constants.asm, sk.constants.asm, General/, etc.)
    • Optional Live Trace Log (if you capture one in BlastEm):
        ◦ /v3/trace_banks.txt (generated automatically when you run gdb-multiarch -x blastem_trace_ssf2.gdb inside v3/)
    • Optional Compiled .lst + .bin Pairs (for 68000 code matching):
        ◦ If you also build the upstream disassemblies with AS, drop their .bin and .lst pairs (e.g., s1built.bin + s1built.lst) inside their respective folders (s1disasm-AS/, s2disasm-master/, skdisasm-master/) so match_upstream.py can match compiled 68K routines in addition to binary assets.
Quick Verification Command
Once you place those files in ~/Downloads/NTRET/v3/, run this check from inside v3/ to confirm every expected path resolves before running make:
bash
ls -d Sonic_Delta_Origins_2026.bin s1disasm-AS/_Variables.asm s2disasm-master/s2.constants.asm skdisasm-master/sk.constants.asm

(Note: You can also move or remove your *_old and *_med backup files so the folder stays tidy, though Makefile and run_pipeline.sh will safely ignore them.)
Once you stage Sonic_Delta_Origins_2026.bin and the three disassembly folders in ~/Downloads/NTRET/v3/, let me know when you run make constants neto match so we can inspect the match counts and Neto's custom SSF2 hooks!



