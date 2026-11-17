#!/usr/bin/env python3
import json
import struct
import argparse
from pathlib import Path

BANK_SIZE = 0x80000

SSF2_REGS = {
    0x00A130F1: "SSF2_SRAM_CTRL",
    0x00A130F3: "SSF2_BANK_1",
    0x00A130F5: "SSF2_BANK_2",
    0x00A130F7: "SSF2_BANK_3",
    0x00A130F9: "SSF2_BANK_4",
    0x00A130FB: "SSF2_BANK_5",
    0x00A130FD: "SSF2_BANK_6",
    0x00A130FF: "SSF2_BANK_7",
}

NETO_SIGNATURES = [
    b"Neto - Depurador",
    b"Super Depurador",
    b"Mapeador n",
    b"SRAM n",
    b"Sonic Delta Next",
    b"SONIC DELTA 40Mb",
    b"M68K Bank",
    b"neto.baiano",
]

def decode_simple_m68k(rom, offset):
    if offset + 2 > len(rom):
        return "dc.w $0000", 2

    op = struct.unpack(">H", rom[offset : offset + 2])[0]

    if op == 0x13FC and offset + 8 <= len(rom):
        imm = struct.unpack(">H", rom[offset + 2 : offset + 4])[0] & 0xFF
        addr = struct.unpack(">I", rom[offset + 4 : offset + 8])[0]
        reg_name = SSF2_REGS.get(addr, f"${addr:08X}")
        return f"move.b  #${imm:02X}, ({reg_name}).l", 8

    if (op & 0xFFF8) == 0x13C0 and offset + 6 <= len(rom):
        dn = op & 0x0007
        addr = struct.unpack(">I", rom[offset + 2 : offset + 6])[0]
        reg_name = SSF2_REGS.get(addr, f"${addr:08X}")
        return f"move.b  d{dn}, ({reg_name}).l", 6

    if op == 0x4A39 and offset + 6 <= len(rom):
        addr = struct.unpack(">I", rom[offset + 2 : offset + 6])[0]
        reg_name = SSF2_REGS.get(addr, f"${addr:08X}")
        return f"tst.b   ({reg_name}).l", 6

    if op == 0x4EB9 and offset + 6 <= len(rom):
        addr = struct.unpack(">I", rom[offset + 2 : offset + 6])[0]
        return f"jsr     (${addr:08X}).l", 6

    if op == 0x4EF9 and offset + 6 <= len(rom):
        addr = struct.unpack(">I", rom[offset + 2 : offset + 6])[0]
        return f"jmp     (${addr:08X}).l", 6

    if op == 0x4E75:
        return "rts", 2
    if op == 0x4E73:
        return "rte", 2

    return f"dc.w    ${op:04X}", 2

def scan_ssf2_accesses(rom):
    hits = []
    n = len(rom)
    for pos in range(0, n - 4, 2):
        val = struct.unpack(">I", rom[pos : pos + 4])[0]
        if val in SSF2_REGS:
            reg_name = SSF2_REGS[val]
            inst_offset = pos - 2
            if pos >= 4:
                prev2 = struct.unpack(">H", rom[pos - 4 : pos - 2])[0]
                if prev2 == 0x13FC:
                    inst_offset = pos - 4

            disasm, size = decode_simple_m68k(rom, inst_offset)
            hits.append({
                "rom_offset": f"0x{inst_offset:06X}",
                "rom_offset_int": inst_offset,
                "bank": inst_offset // BANK_SIZE,
                "bank_offset": f"0x{inst_offset % BANK_SIZE:05X}",
                "register": f"0x{val:06X}",
                "register_name": reg_name,
                "disassembly": disasm,
                "bytes": rom[inst_offset : inst_offset + size].hex().upper(),
            })
    return hits

def scan_neto_strings(rom):
    found = []
    for sig in NETO_SIGNATURES:
        start = 0
        while True:
            idx = rom.find(sig, start)
            if idx == -1:
                break
            end = idx
            while end < min(len(rom), idx + 64) and 0x20 <= rom[end] <= 0xFF:
                end += 1
            preview = rom[idx:end].decode("latin-1", errors="replace")
            found.append({
                "rom_offset": f"0x{idx:06X}",
                "rom_offset_int": idx,
                "bank": idx // BANK_SIZE,
                "bank_offset": f"0x{idx % BANK_SIZE:05X}",
                "signature": sig.decode("latin-1"),
                "preview": preview,
            })
            start = idx + len(sig)
    found.sort(key=lambda x: x["rom_offset_int"])
    return found

def main():
    parser = argparse.ArgumentParser(description="Locate Neto's SSF2 mapper & debug routines")
    parser.add_argument("--rom", default="Sonic_Delta_Origins_2026.bin", help="Path to 40Mbit ROM")
    parser.add_argument("--json-out", default="neto_custom_hooks.json", help="JSON report output")
    parser.add_argument("--inc-out", default="src/custom_neto/neto_hooks_map.inc", help="ASM include output")
    args = parser.parse_args()

    rom_path = Path(args.rom)
    if not rom_path.exists():
        raise FileNotFoundError(f"ROM not found: {rom_path}")

    rom = rom_path.read_bytes()
    ssf2_hits = scan_ssf2_accesses(rom)
    string_hits = scan_neto_strings(rom)

    report = {
        "rom": str(rom_path),
        "ssf2_access_count": len(ssf2_hits),
        "neto_string_count": len(string_hits),
        "ssf2_accesses": ssf2_hits,
        "neto_strings": string_hits,
    }

    Path(args.json_out).write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")

    inc_path = Path(args.inc_out)
    inc_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "; Auto-generated Map of Neto's Custom SSF2 Mapper & Debug Hooks",
        f"; Source ROM: {rom_path.name}",
        "",
    ]
    for h in ssf2_hits:
        lines.append(
            f"Neto_SSF2_Hook_{h['rom_offset_int']:06X} equ ${h['rom_offset_int']:06X} "
            f"; Bank {h['bank']:02d} @ {h['bank_offset']} -> {h['disassembly']}"
        )
    lines.append("")
    for s in string_hits:
        safe_preview = s["preview"].replace("\n", " ").replace("\r", "")
        lines.append(
            f"Neto_Str_{s['rom_offset_int']:06X}       equ ${s['rom_offset_int']:06X} "
            f"; Bank {s['bank']:02d} @ {s['bank_offset']} -> \"{safe_preview}\""
        )

    inc_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[+] Found {len(ssf2_hits)} SSF2 mapper accesses and {len(string_hits)} Neto string markers.")

if __name__ == "__main__":
    main()
