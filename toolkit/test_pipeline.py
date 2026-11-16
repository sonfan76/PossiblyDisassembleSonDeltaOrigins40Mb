#!/usr/bin/env python3
import os
import subprocess
from format_for_vasm import process_bank_file

os.makedirs("test_sandbox", exist_ok=True)
asm_path = "test_sandbox/BANK_00.asm"

sample_ghidra_asm = """\torg\t$000000

loc_000000:\tdc.l\t$00FFFE00, $00000200
dat_000008:\tdc.b\t$53, $45, $47, $41, $20, $4D, $45, $47, $41, $20, $44, $52, $49, $56, $45, $20
loc_000200:\tmove.b\t#$01, ($00A130F1).l
loc_000208:\tmove.b\t#$00, ($00A130F1).l
loc_000210:\tmove.b\t#$09, ($00A130FF).l
loc_000218:\tlea\t($00022A,PC), A0
loc_00021C:\tmove.l\t(0x04,A0), D0
loc_000220:\tbeq.s\t$000228
loc_000222:\tjsr\t($00380010).l
loc_000228:\trts
dat_00022A:\tdc.b\t$12, $34, $56, $78, $9A, $BC, $DE, $F0
"""

with open(asm_path, "w") as f:
    f.write(sample_ghidra_asm)

process_bank_file(asm_path)
print(open(asm_path).read())

try:
    res = subprocess.run(
        ["vasmm68k_mot", "-Fbin", "-m68000", "-no-opt", "-spaces", "-o", "test_sandbox/BANK_00.bin", asm_path],
        capture_output=True, text=True
    )
    if res.returncode == 0:
        print(f"[VASM PASS] Compiled cleanly! Output binary size: {os.path.getsize('test_sandbox/BANK_00.bin')} bytes.")
    else:
        print(f"[VASM ERROR]\n{res.stderr}")
except FileNotFoundError:
    print("[INFO] Formatter passed! Install 'vasmm68k_mot' in PATH to execute the binary compile step.")
