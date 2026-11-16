#!/usr/bin/env python3
import re
import glob
import os

BRANCH_OR_PTR_MNEMONICS = (
    "bra", "bsr", "beq", "bne", "bpl", "bmi", "bcc", "bcs", "bvc", "bvs",
    "bge", "bgt", "ble", "blt", "bhi", "bls", "jmp", "jsr", "lea", "pea",
    "dbra", "dbf", "dbeq", "dbne", "dbpl", "dbmi", "dbcc", "dbcs",
    "dbge", "dbgt", "dble", "dblt", "dbhi", "dbls"
)

def normalize_syntax(inst_part):
    inst_part = re.sub(r"\b0x([0-9a-fA-F]+)\b", r"$\1", inst_part)
    inst_part = re.sub(
        r"\(\s*(-?\$?[0-9a-fA-F]+)\s*,\s*([aAdD][0-7]|sp|SP|pc|PC)\s*\)",
        r"\1(\2)",
        inst_part
    )
    inst_part = re.sub(
        r"\(\s*(-?\$?[0-9a-fA-F]+)\s*,\s*([aAdD][0-7]|sp|SP|pc|PC)\s*,\s*([aAdD][0-7]\.[wlWL])\s*\)",
        r"\1(\2,\3)",
        inst_part
    )
    inst_part = re.sub(r"\b([AD][0-7]|SP|PC)\b", lambda m: m.group(1).lower(), inst_part)
    inst_part = re.sub(r"(\$[0-9a-fA-F]{1,4})\.w\b", r"(\1).w", inst_part)
    inst_part = re.sub(r"(\$[0-9a-fA-F]{5,8})\.l\b", r"(\1).l", inst_part)
    return inst_part

def process_bank_file(path):
    with open(path, "r") as f:
        raw_lines = f.readlines()

    symbol_map = {}
    for line in raw_lines:
        m = re.match(r"^((?:loc|dat)_([0-9a-fA-F]{6})):", line.strip())
        if m:
            symbol_map[int(m.group(2), 16)] = m.group(1)

    out_lines = []
    replaced_count = 0

    for line in raw_lines:
        stripped = line.strip()
        if not stripped or stripped.startswith(";") or stripped.startswith("org"):
            out_lines.append(line)
            continue

        label_part = ""
        inst_part = line
        if ":" in line and not line.lstrip().startswith(";"):
            idx = line.index(":")
            label_part = line[:idx + 1]
            inst_part = line[idx + 1:]

        inst_part = normalize_syntax(inst_part)

        op_match = re.match(r"^\s*([a-z]+)(?:\.[bws])?\s+(.+)$", inst_part, re.IGNORECASE)
        if op_match:
            mnemonic = op_match.group(1).lower()
            operands = op_match.group(2)

            if mnemonic in BRANCH_OR_PTR_MNEMONICS:
                def sub_addr(match):
                    nonlocal replaced_count
                    raw_hex = match.group(1)
                    suffix = match.group(2) or ""
                    target_int = int(raw_hex, 16)
                    if target_int in symbol_map:
                        replaced_count += 1
                        return f"{symbol_map[target_int]}{suffix}"
                    return match.group(0)

                operands = re.sub(
                    r"(?<!#)\$([0-9a-fA-F]{4,8})(\(pc\))?",
                    sub_addr,
                    operands,
                    flags=re.IGNORECASE
                )
                inst_part = re.sub(
                    r"^(\s*[a-z]+(?:\.[bws])?\s+).+$",
                    rf"\g<1>{operands}",
                    inst_part,
                    flags=re.IGNORECASE
                )

        out_lines.append(f"{label_part}{inst_part}")

    with open(path, "w") as f:
        f.writelines(out_lines)

    print(f"[SYMBOLIC OK] {os.path.basename(path)}: {len(symbol_map)} labels indexed, {replaced_count} operands resolved")

def process_all_banks(asm_dir="."):
    asm_files = sorted(glob.glob(os.path.join(asm_dir, "BANK_*.asm")))
    if not asm_files:
        print("[ERROR] No BANK_*.asm files found.")
        return
    for path in asm_files:
        process_bank_file(path)

if __name__ == "__main__":
    process_all_banks(".")
