#!/usr/bin/env python3
import re
import json
import argparse
from pathlib import Path

CONSTANT_FILES = [
    ("s1", "s1disasm-AS/_Constants.asm"),
    ("s1", "s1disasm-AS/_Variables.asm"),
    ("s2", "s2disasm-master/s2.constants.asm"),
    ("s3", "skdisasm-master/s3.constants.asm"),
    ("sk", "skdisasm-master/sk.constants.asm"),
]

DEF_RE = re.compile(
    r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(?:=|equ|EQU)\s*\$([0-9A-Fa-f]{4,8})\b"
)

def normalize_68k_ram_addr(val):
    addr = val & 0x00FFFFFF
    if 0x8000 <= val <= 0xFFFF:
        addr = 0x00FF0000 | val
    return addr

def is_valid_hardware_or_ram(addr):
    return (
        (0x00FF0000 <= addr <= 0x00FFFFFF)
        or (0x00A00000 <= addr <= 0x00A01FFF)
        or (0x00A10000 <= addr <= 0x00C0001F)
    )

def main():
    parser = argparse.ArgumentParser(description="Extract upstream RAM & hardware symbols")
    parser.add_argument("--out", default="upstream_ram_symbols.json", help="Output JSON path")
    args = parser.parse_args()

    symbols_by_addr = {}
    parsed_files = 0

    for prefix, rel_path in CONSTANT_FILES:
        p = Path(rel_path)
        if not p.exists():
            print(f"[!] Skipping missing file: {p}")
            continue

        parsed_files += 1
        text = p.read_text(encoding="utf-8", errors="ignore")
        for line in text.splitlines():
            code_part = line.split(";")[0]
            m = DEF_RE.match(code_part)
            if not m:
                continue
            name = m.group(1)
            raw_val = int(m.group(2), 16)
            addr = normalize_68k_ram_addr(raw_val)
            if not is_valid_hardware_or_ram(addr):
                continue

            addr_key = f"0x{addr:06X}"
            entry = symbols_by_addr.setdefault(addr_key, {"address_int": addr, "names": []})
            tagged_name = f"{prefix}_{name}"
            if tagged_name not in entry["names"]:
                entry["names"].append(tagged_name)

    Path(args.out).write_text(json.dumps(symbols_by_addr, indent=2), encoding="utf-8")
    print(f"[+] Parsed {parsed_files} constant files -> {len(symbols_by_addr)} unique addresses saved to {args.out}")

if __name__ == "__main__":
    main()
